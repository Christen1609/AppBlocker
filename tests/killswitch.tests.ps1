. (Join-Path $PSScriptRoot 'helpers.ps1')
$dir = New-TestCopy
$appData = New-TestFolder
$killFile = Join-Path $appData 'AppBlocker\kill-until.txt'

Stop-FakeApp
$null = Start-FakeApp $dir
Assert (Wait-Until { Get-FakeApp } 5) 'fake app is running'

$pressed = Get-Date
$null = Start-TestScript $dir 'killswitch.ps1' $appData
Assert (Wait-Until { -not (Get-FakeApp) } 5) 'kill switch closes the app'
Assert (Wait-Until { Test-Path $killFile } 5) 'kill switch writes the lock file'

$until = [datetime]::Parse((Get-Content $killFile), [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind).ToLocalTime()
$hours = ($until - $pressed).TotalHours
Assert ($hours -gt 11.99 -and $hours -lt 12.01) "lock ends 12 hours after the press ($until)"

$log = Get-Content (Join-Path $dir 'blocked.log') -ErrorAction SilentlyContinue
Assert ("$log" -like '*kill switch on until*') 'press is logged'

Stop-FakeApp
Complete-Tests
