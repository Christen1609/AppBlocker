. (Join-Path $PSScriptRoot 'helpers.ps1')
$env:LOCALAPPDATA = New-TestFolder
. (Join-Path $PSScriptRoot '..\schedule.ps1')

$press = Get-Date '2026-11-10T18:00:00'
Assert ($KillFile -like "$env:LOCALAPPDATA*") 'lock file lives under LOCALAPPDATA'
Assert ($null -eq (Get-KillUntil)) 'no file means no lock'
Assert (-not (Test-KillOn $press)) 'no file means kill switch off'

$until = Set-KillSwitch $press
Assert ($until -eq $press.AddHours(12)) 'press returns 12 hours later'
Assert (Test-KillOn $press) 'on straight after the press'
Assert (Test-KillOn $press.AddHours(11.99)) 'still on just before 12 hours'
Assert (-not (Test-KillOn $press.AddHours(12))) 'off at 12 hours'
Assert ((Get-KillUntil) -eq $press.AddHours(12)) 'Get-KillUntil reads the end time back'

$second = Set-KillSwitch $press.AddHours(2)
Assert ($second -eq $press.AddHours(14)) 'second press restarts the 12 hours'
$earlier = Set-KillSwitch $press.AddHours(-5)
Assert ($earlier -eq $press.AddHours(14)) 'an earlier press cannot shorten the lock'
Assert ((Get-KillUntil) -eq $press.AddHours(14)) 'file keeps the longer lock'

Set-Content -LiteralPath $KillFile -Value 'not a date'
Assert ($null -eq (Get-KillUntil)) 'garbage file means no lock'
Assert ((Set-KillSwitch $press) -eq $press.AddHours(12)) 'press over a garbage file still locks'

# Daylight saving: Adelaide moves forward at 2am on 2027-10-03. 12 real hours from 8pm the night before is 9am, not 8am.
$adelaide = [TimeZoneInfo]::FindSystemTimeZoneById('Cen. Australia Standard Time')
if ([TimeZoneInfo]::Local.Id -eq $adelaide.Id) {
    $env:LOCALAPPDATA = New-TestFolder; $KillFile = Join-Path $env:LOCALAPPDATA 'AppBlocker\kill-until.txt'
    $night = Get-Date '2027-10-02T20:00:00'
    Assert ((Set-KillSwitch $night) -eq (Get-Date '2027-10-03T09:00:00')) '12 real hours across the daylight saving change'
}

Assert ($Blocked -contains '*ctrader*') '$Blocked lives in schedule.ps1'

# A path that can't be written: a file where the folder should be.
$blocker = Join-Path (New-TestFolder) 'AppBlocker'
Set-Content -LiteralPath $blocker -Value 'x'
$KillFile = Join-Path $blocker 'kill-until.txt'
Assert ($null -eq (Set-KillSwitch $press)) 'failed write returns null'

Complete-Tests
