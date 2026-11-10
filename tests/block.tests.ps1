# End to end: a test copy of block.ps1 with every day open, a fake app and fake trade reports.
. (Join-Path $PSScriptRoot 'helpers.ps1')
$dir = New-TestCopy
$appData = New-TestFolder
$reports = New-TestFolder
$state = Join-Path $appData 'AppBlocker'
$null = New-Item -ItemType Directory -Path $state
$killFile = Join-Path $state 'kill-until.txt'
$readFile = Join-Path $state 'rules-read.txt'

$schedule = Join-Path $dir 'schedule.ps1'
(Get-Content $schedule -Raw) -replace '= (17\.5, 20|0, 0)', '= 0, 24' | Set-Content $schedule
$trades = Join-Path $dir 'trades.ps1'
(Get-Content $trades -Raw).Replace("Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'cAlgo\Data\cBots\AppBlockerPositions'", "'$reports'") | Set-Content $trades

function Set-Lock([datetime]$Until) { Set-Content $killFile $Until.ToUniversalTime().ToString('o') }
function Get-RulesWindow {
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -like "*$dir\rules.ps1*" }
}
function Stop-TestProcesses {
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -like "*$dir*" } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Stop-FakeApp
}
$isRulesDay = (Get-Date).DayOfWeek -in 'Monday', 'Tuesday', 'Wednesday', 'Thursday'

try {
    Stop-FakeApp
    Set-Content $readFile (Get-Date).ToString('yyyy-MM-dd')
    $null = Start-TestScript $dir 'block.ps1' $appData

    # 1. Allowed hours, no lock: the app stays open.
    $null = Start-FakeApp $dir
    Start-Sleep -Seconds 6
    Assert ([bool](Get-FakeApp)) 'no lock: app stays open in allowed hours'

    # 2. Lock on with a fresh open-trade report: the app still closes.
    Set-Content (Join-Path $reports 'positions-1.txt') '1'
    Set-Lock (Get-Date).AddHours(12)
    Assert (Wait-Until { -not (Get-FakeApp) } 6) 'lock closes the app even with trades open'
    $null = Start-FakeApp $dir
    Assert (Wait-Until { -not (Get-FakeApp) } 8) 'lock closes it again when reopened'
    Assert ("$(Get-Content (Join-Path $dir 'blocked.log'))" -like '*(kill switch)*') 'block is logged as kill switch'

    # 3. Lock over: back to normal.
    Remove-Item (Join-Path $reports 'positions-1.txt')
    Set-Lock (Get-Date).AddMinutes(-1)
    Start-Sleep -Seconds 4
    $null = Start-FakeApp $dir
    Start-Sleep -Seconds 6
    Assert ([bool](Get-FakeApp)) 'expired lock: app stays open'
    Stop-FakeApp

    if ($isRulesDay) {
        # 4. Rules not read yet and lock on: no rules window. A fresh blocker, since the first one has seen today's click.
        Stop-TestProcesses
        Remove-Item $readFile
        Set-Lock (Get-Date).AddHours(12)
        $null = Start-TestScript $dir 'block.ps1' $appData
        Start-Sleep -Seconds 6
        Assert (-not (Get-RulesWindow)) 'no rules window during a lock'

        # 5. Lock ends: the rules window shows.
        Set-Lock (Get-Date).AddMinutes(-1)
        Assert (Wait-Until { Get-RulesWindow } 8) 'rules window shows once the lock ends'

        # 6. Lock pressed while the rules window is open: it closes, and it isn't counted as a failure.
        Set-Lock (Get-Date).AddHours(12)
        Assert (Wait-Until { -not (Get-RulesWindow) } 8) 'lock closes an open rules window'
        Set-Lock (Get-Date).AddMinutes(-1)
        Assert (Wait-Until { Get-RulesWindow } 8) 'rules window returns at once after the lock (no failure wait)'
        Assert ("$(Get-Content (Join-Path $dir 'blocked.log'))" -notlike '*rules window failed*') 'closed rules window not counted as a failure'
    }
    else { Write-Output '  skip  rules window checks (not a rules day)' }
}
finally { Stop-TestProcesses }
Complete-Tests
