# Closes blocked apps outside the hours in schedule.ps1, unless trades are open.
# On days whose hours start partway through (Mon-Thu), they also stay closed until "I've read the rules" is clicked.
# Add more name patterns to $Blocked.
$Blocked = @('*ctrader*')
$PollSeconds = 2
$LogFile = Join-Path $PSScriptRoot 'blocked.log'
$RulesScript = Join-Path $PSScriptRoot 'rules.ps1'
. (Join-Path $PSScriptRoot 'schedule.ps1')
. (Join-Path $PSScriptRoot 'trades.ps1')

# Only one copy of the watcher should run at a time.
$mutex = New-Object System.Threading.Mutex($false, 'Local\AppBlocker')
if (-not $mutex.WaitOne(0)) { exit }

$shell = New-Object -ComObject WScript.Shell
$warned = $false
$rulesWindow = $null
while ($true) {
    # Keeps Get-Date in step with the Windows clock if the time zone changes while this runs.
    [TimeZoneInfo]::ClearCachedData()
    $now = Get-Date
    $rulesNeeded = (Test-RulesDue $now) -and -not (Test-RulesRead $now)
    # Shows the rules until the button is clicked. Its own process, so the window doesn't pause this loop.
    if ($rulesNeeded -and (-not $rulesWindow -or $rulesWindow.HasExited)) {
        $rulesWindow = Start-Process powershell.exe -WindowStyle Hidden -PassThru -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$RulesScript`""
    }
    $apps = Get-Process -Name $Blocked -ErrorAction SilentlyContinue
    if (-not $apps) {
        $warned = $false
    }
    elseif ((Test-Allowed $now) -and -not $rulesNeeded) {
        if (-not $warned -and -not (Test-JustOpened $apps) -and -not (Test-Reporting)) {
            $warned = $true
            $null = $shell.Popup('Start AppBlockerPositions in cTrader, or it will close when your hours end, even with trades open.', 10, 'App Blocker', 48)
        }
    }
    elseif (-not (Test-TradesOpen $apps)) {
        $apps | Stop-Process -Force -ErrorAction SilentlyContinue
        $names = ($apps.Name | Sort-Object -Unique) -join ', '
        if ($rulesNeeded) {
            Add-Content -Path $LogFile -Value "$(Get-Date -Format s)  blocked $names (rules not read)"
            $null = $shell.Popup("Click `"I've read the rules`" to unlock $names.", 3, 'App Blocker', 48)
        }
        else {
            Add-Content -Path $LogFile -Value "$(Get-Date -Format s)  blocked $names"
            $null = $shell.Popup("Blocked outside your hours: $names", 3, 'App Blocker', 48)
        }
    }
    Start-Sleep -Seconds $PollSeconds
}
