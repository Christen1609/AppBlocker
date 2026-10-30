# Closes blocked apps outside the hours in schedule.ps1, unless trades are open.
# Add more name patterns to $Blocked.
$Blocked = @('*ctrader*')
$PollSeconds = 2
$LogFile = Join-Path $PSScriptRoot 'blocked.log'
. (Join-Path $PSScriptRoot 'schedule.ps1')
. (Join-Path $PSScriptRoot 'trades.ps1')

# Only one copy of the watcher should run at a time.
$mutex = New-Object System.Threading.Mutex($false, 'Local\AppBlocker')
if (-not $mutex.WaitOne(0)) { exit }

$shell = New-Object -ComObject WScript.Shell
$warned = $false
while ($true) {
    # Keeps Get-Date in step with the Windows clock if the time zone changes while this runs.
    [TimeZoneInfo]::ClearCachedData()
    $apps = Get-Process -Name $Blocked -ErrorAction SilentlyContinue
    if (-not $apps) {
        $warned = $false
    }
    elseif (Test-Allowed (Get-Date)) {
        if (-not $warned -and -not (Test-JustOpened $apps) -and -not (Test-Reporting)) {
            $warned = $true
            $null = $shell.Popup('Start AppBlockerPositions in cTrader, or it will close when your hours end, even with trades open.', 10, 'App Blocker', 48)
        }
    }
    elseif (-not (Test-TradesOpen $apps)) {
        $apps | Stop-Process -Force -ErrorAction SilentlyContinue
        $names = ($apps.Name | Sort-Object -Unique) -join ', '
        Add-Content -Path $LogFile -Value "$(Get-Date -Format s)  blocked $names"
        $null = $shell.Popup("Blocked outside your hours: $names", 3, 'App Blocker', 48)
    }
    Start-Sleep -Seconds $PollSeconds
}
