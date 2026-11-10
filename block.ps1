# Closes blocked apps outside the hours in schedule.ps1, unless trades are open.
# While the kill switch is on (killswitch.ps1), they close whatever the hours or trades.
# On days whose hours start partway through (Mon-Thu), they also stay closed until "I've read the rules" is clicked.
# The apps it closes are listed in $Blocked in schedule.ps1.
$PollSeconds = 2
$LogFile = Join-Path $PSScriptRoot 'blocked.log'
$RulesScript = Join-Path $PSScriptRoot 'rules.ps1'
. (Join-Path $PSScriptRoot 'schedule.ps1')
. (Join-Path $PSScriptRoot 'trades.ps1')

# Only one copy of the watcher should run at a time.
$mutex = New-Object System.Threading.Mutex($false, 'Local\AppBlocker')
if (-not $mutex.WaitOne(0)) { exit }

$shell = New-Object -ComObject WScript.Shell
# 48 = warning icon, 4096 = stay on top, so popups show above the always-on-top rules window.
$PopupFlags = 48 + 4096
# A rules window that closes this soon after it opened, without a click, counts as failed (a bug, not the owner).
$RulesFailSeconds = 15
$RulesRetrySeconds = 30
$RulesMaxFailures = 3
$warned = $false
$rulesWindow = $null
$rulesStarted = $null
$rulesRetryAfter = [datetime]::MinValue
# Per-day rules state. It starts over when the date changes.
$stateDay = ''
$readSeen = $false
$rulesFailures = 0
$rulesGaveUp = $false
while ($true) {
    # Keeps Get-Date in step with the Windows clock if the time zone changes while this runs.
    [TimeZoneInfo]::ClearCachedData()
    $now = Get-Date
    $today = $now.ToString('yyyy-MM-dd')
    if ($today -ne $stateDay) {
        $stateDay = $today
        $readSeen = $false
        $rulesFailures = 0
        $rulesGaveUp = $false
    }
    $rulesDue = Test-RulesDue $now
    # Once today's click is seen, stop re-reading the file for the rest of the day.
    if ($rulesDue -and -not $readSeen) { $readSeen = Test-RulesRead $now }
    $killOn = Test-KillOn $now
    $rulesNeeded = $rulesDue -and -not $readSeen -and -not $rulesGaveUp -and -not $killOn

    # No rules window during a lock. One that's open closes, and isn't counted as a failure.
    if ($killOn -and $rulesWindow) {
        if (-not $rulesWindow.HasExited) { $rulesWindow | Stop-Process -Force -ErrorAction SilentlyContinue }
        $rulesWindow = $null
    }

    # A window that died quickly without a click is a failure. Wait before trying again, and give up after a few.
    if ($rulesWindow -and $rulesWindow.HasExited) {
        $ranSeconds = ($rulesWindow.ExitTime - $rulesStarted).TotalSeconds
        $rulesWindow = $null
        if ($rulesNeeded -and $ranSeconds -lt $RulesFailSeconds -and -not (Test-RulesRead $now)) {
            $rulesFailures++
            $rulesRetryAfter = $now.AddSeconds($RulesRetrySeconds)
            if ($rulesFailures -ge $RulesMaxFailures) {
                $rulesGaveUp = $true
                $rulesNeeded = $false
                Add-Content -Path $LogFile -Value "$(Get-Date -Format s)  rules window failed $rulesFailures times, rules not required for the rest of today"
                $null = $shell.Popup("The rules window couldn't open. cTrader is unlocked for today.", 8, 'App Blocker', $PopupFlags)
            }
        }
    }
    # Shows the rules until the button is clicked. Its own process, so the window doesn't pause this loop.
    if ($rulesNeeded -and -not $rulesWindow -and $now -ge $rulesRetryAfter) {
        $rulesStarted = Get-Date
        $rulesWindow = Start-Process powershell.exe -WindowStyle Hidden -PassThru -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$RulesScript`""
    }
    $apps = Get-Process -Name $Blocked -ErrorAction SilentlyContinue
    if (-not $apps) {
        $warned = $false
    }
    elseif (-not $killOn -and (Test-Allowed $now) -and -not $rulesNeeded) {
        if (-not $warned -and -not (Test-JustOpened $apps) -and -not (Test-Reporting)) {
            $warned = $true
            $null = $shell.Popup('Start AppBlockerPositions in cTrader, or it will close when your hours end, even with trades open.', 10, 'App Blocker', $PopupFlags)
        }
    }
    elseif ($killOn -or -not (Test-TradesOpen $apps)) {
        $apps | Stop-Process -Force -ErrorAction SilentlyContinue
        $names = ($apps.Name | Sort-Object -Unique) -join ', '
        if ($killOn) {
            $logNote = ' (kill switch)'
            $until = Get-KillUntil
            $message = if ($until) { "Kill switch on until $($until.ToString('dddd d MMM, h:mm tt'))." } else { "Kill switch on: $names closed." }
        }
        elseif ($rulesNeeded) {
            $logNote = ' (rules not read)'
            $message = "Click `"I've read the rules`" to unlock $names."
        }
        else {
            $logNote = ''
            $message = "Blocked outside your hours: $names"
        }
        Add-Content -Path $LogFile -Value "$(Get-Date -Format s)  blocked $names$logNote"
        $null = $shell.Popup($message, 3, 'App Blocker', $PopupFlags)
    }
    Start-Sleep -Seconds $PollSeconds
}
