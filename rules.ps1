# Shows the trading rules in rules.txt. cTrader stays locked until "I've read the rules" is clicked.
# block.ps1 starts this when the day's hours begin.
. (Join-Path $PSScriptRoot 'schedule.ps1')

# One window at a time. A second copy waits here, then exits if the first one was clicked.
$mutex = New-Object System.Threading.Mutex($false, 'Local\AppBlockerRules')
try { $null = $mutex.WaitOne() } catch [System.Threading.AbandonedMutexException] {}
if (Test-RulesRead (Get-Date)) { exit }

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

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
    Text        = 'Read your rules, then click the button to unlock cTrader.'
    AutoSize    = $true
    MaximumSize = New-Object System.Drawing.Size(600, 0)
    Font        = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
    Margin      = New-Object System.Windows.Forms.Padding(0, 0, 0, 16)
}
$rules = New-Object System.Windows.Forms.Label -Property @{
    Text        = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'rules.txt') -Raw).Trim()
    AutoSize    = $true
    MaximumSize = New-Object System.Drawing.Size(600, 0)
}
$button = New-Object System.Windows.Forms.Button -Property @{
    Text     = "I've read the rules"
    AutoSize = $true
    Padding  = New-Object System.Windows.Forms.Padding(12, 6, 12, 6)
    Margin   = New-Object System.Windows.Forms.Padding(0, 24, 0, 0)
}
# Mouse only, so a stray Space or Enter typed into another app can't unlock cTrader.
$button.Add_MouseClick({
    $null = New-Item -ItemType Directory -Force -Path (Split-Path $RulesReadFile)
    Set-Content -LiteralPath $RulesReadFile -Value (Get-Date -Format 'yyyy-MM-dd')
    $form.Close()
})
# Only the button closes the window: the X and Alt+F4 do nothing until it's clicked.
$form.Add_FormClosing({
    if ($_.CloseReason -eq 'UserClosing' -and -not (Test-RulesRead (Get-Date))) { $_.Cancel = $true }
})
# block.ps1 starts this hidden, and Windows applies that to the first window shown, so show it again.
# 4 = show without taking focus from whatever is being typed in. TopMost keeps it in view.
Add-Type -Namespace AppBlocker -Name Window -MemberDefinition '
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'
$form.Add_Shown({ $null = [AppBlocker.Window]::ShowWindow($form.Handle, 4) })
$panel.Controls.AddRange(@($heading, $rules, $button))
$form.Controls.Add($panel)
[void]$form.ShowDialog()
