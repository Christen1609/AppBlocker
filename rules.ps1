# Shows the trading rules in rules.txt. cTrader stays locked until "I've read the rules" is clicked.
# block.ps1 starts this when the day's hours begin.
. (Join-Path $PSScriptRoot 'schedule.ps1')

# One window at a time. A second copy waits here, then exits if the first one was clicked.
$mutex = New-Object System.Threading.Mutex($false, 'Local\AppBlockerRules')
try { $null = $mutex.WaitOne() } catch [System.Threading.AbandonedMutexException] {}

# Only run while the hours are on. A window left open past 8pm, or started by hand earlier,
# must not save a click that would unlock a later day without showing the rules.
$now = Get-Date
if (-not (Test-RulesDue $now) -or (Test-RulesRead $now)) { exit }

# UTF8 so quotes and dashes in rules.txt show properly. A missing or empty file shows a message, so it can't lock you out.
function Get-RulesText {
    $text = ''
    try { $text = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'rules.txt') -Raw -Encoding UTF8 -ErrorAction Stop } catch {}
    $text = "$text".Trim()
    if (-not $text) { return 'rules.txt is missing or empty. Click the button to unlock cTrader.' }
    return $text
}
$rulesText = Get-RulesText
$headingText = 'Read your rules, then click the button to unlock cTrader.'

# Set once the window may close: after a saved click, or once the hours have ended.
$script:canClose = $false

try {
    $ErrorActionPreference = 'Stop'
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()
    # block.ps1 starts this hidden, and Windows applies that to the first window shown, so show it again.
    # 4 = show without taking focus from whatever is being typed in. TopMost keeps it in view.
    Add-Type -Namespace AppBlocker -Name Window -MemberDefinition '
        [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'

    $form = New-Object System.Windows.Forms.Form -Property @{
        Text            = 'Trading Rules'
        TopMost         = $true
        StartPosition   = 'CenterScreen'
        FormBorderStyle = 'FixedDialog'
        ControlBox      = $false
        AutoSize        = $true
        AutoSizeMode    = 'GrowAndShrink'
        Padding         = New-Object System.Windows.Forms.Padding(24)
        Font            = New-Object System.Drawing.Font('Segoe UI', 11)
    }
    $panel = New-Object System.Windows.Forms.FlowLayoutPanel -Property @{
        FlowDirection = 'TopDown'
        AutoSize      = $true
        AutoSizeMode  = 'GrowAndShrink'
    }
    $heading = New-Object System.Windows.Forms.Label -Property @{
        Text        = $headingText
        AutoSize    = $true
        MaximumSize = New-Object System.Drawing.Size(600, 0)
        Font        = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
        Margin      = New-Object System.Windows.Forms.Padding(0, 0, 0, 16)
    }
    # The rules sit in a box that scrolls if they are too tall for the screen, so the button is always in view.
    $rulesBox = New-Object System.Windows.Forms.Panel -Property @{
        AutoScroll = $true
        Margin     = New-Object System.Windows.Forms.Padding(0)
    }
    $rules = New-Object System.Windows.Forms.Label -Property @{
        Text        = $rulesText
        AutoSize    = $true
        MaximumSize = New-Object System.Drawing.Size(600, 0)
        Location    = New-Object System.Drawing.Point(0, 0)
    }
    $button = New-Object System.Windows.Forms.Button -Property @{
        Text     = "I've read the rules"
        AutoSize = $true
        Padding  = New-Object System.Windows.Forms.Padding(12, 6, 12, 6)
        Margin   = New-Object System.Windows.Forms.Padding(0, 24, 0, 0)
    }
    # Shown only if the click couldn't be saved.
    $note = New-Object System.Windows.Forms.Label -Property @{
        Text      = "Couldn't save. Click the button again."
        AutoSize  = $true
        ForeColor = [System.Drawing.Color]::Firebrick
        Margin    = New-Object System.Windows.Forms.Padding(0, 12, 0, 0)
        Visible   = $false
    }

    # Mouse only, so a stray Space or Enter typed into another app can't unlock cTrader.
    $button.Add_MouseClick({
        $now = Get-Date
        if (-not (Test-RulesDue $now)) {
            # Hours ended while the window was open: close without saving.
            $script:canClose = $true
            $form.Close()
        }
        elseif (Set-RulesRead $now) {
            $script:canClose = $true
            $form.Close()
        }
        else { $note.Visible = $true }
    })
    # Only the button (or the end of the hours) closes the window: the X and Alt+F4 do nothing before then.
    $form.Add_FormClosing({
        if ($_.CloseReason -eq 'UserClosing' -and -not $script:canClose) { $_.Cancel = $true }
    })
    # Closes the window without saving once the hours end, so an old window can't unlock a later day.
    $timer = New-Object System.Windows.Forms.Timer -Property @{ Interval = 2000 }
    $timer.Add_Tick({
        if (-not (Test-RulesDue (Get-Date))) {
            $timer.Stop()
            $script:canClose = $true
            $form.Close()
        }
    })
    $form.Add_Shown({ $null = [AppBlocker.Window]::ShowWindow($form.Handle, 4) })

    $rulesBox.Controls.Add($rules)
    $panel.Controls.AddRange(@($heading, $rulesBox, $button, $note))
    $form.Controls.Add($panel)

    # Cap the rules box so heading + rules + button + window frame fit on the screen.
    # If the rules are taller than that, the box scrolls and is a scroll bar wider.
    $wrap = New-Object System.Drawing.Size(600, 0)
    $textSize = $rules.GetPreferredSize($wrap)
    $screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height
    $frame = [System.Windows.Forms.SystemInformation]::CaptionHeight + 2 * [System.Windows.Forms.SystemInformation]::FixedFrameBorderSize.Height
    $others = $form.Padding.Vertical + $heading.GetPreferredSize($wrap).Height + $heading.Margin.Vertical `
        + $button.PreferredSize.Height + $button.Margin.Vertical + $note.PreferredSize.Height + $note.Margin.Vertical
    $room = [Math]::Max(80, $screenHeight - $frame - $others - 24)
    $boxWidth = $textSize.Width
    $boxHeight = $textSize.Height
    if ($textSize.Height -gt $room) {
        $boxHeight = $room
        $boxWidth += [System.Windows.Forms.SystemInformation]::VerticalScrollBarWidth
    }
    $rulesBox.Size = New-Object System.Drawing.Size($boxWidth, $boxHeight)

    $timer.Start()
    [void]$form.ShowDialog()
}
catch {
    # The window couldn't open. Show the rules in a plain popup instead, so cTrader can't stay locked with no button.
    # The popup closes itself when the hours end. Clicking OK counts as read, but only while the hours are still on.
    $secondsLeft = Get-SecondsLeft (Get-Date)
    if ($secondsLeft -ge 1) {
        $shell = New-Object -ComObject WScript.Shell
        # 64 = information icon, 4096 = stay on top. Returns 1 for OK, -1 if it timed out.
        $answer = $shell.Popup("Read your rules, then click OK to unlock cTrader.`n`n$rulesText", $secondsLeft, 'Trading Rules', 64 + 4096)
        $now = Get-Date
        if ($answer -eq 1 -and (Test-RulesDue $now)) { $null = Set-RulesRead $now }
    }
}
