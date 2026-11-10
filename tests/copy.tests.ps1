# The test copy must never be able to close the real cTrader or clash with the real blocker.
. (Join-Path $PSScriptRoot 'helpers.ps1')

$good = New-TestCopy
Assert (-not (Get-Content (Join-Path $good 'schedule.ps1') -Raw).Contains("'*ctrader*'")) 'normal copy has no cTrader pattern'

# A source whose pattern line no longer matches the replace exactly.
$source = New-TestFolder
Set-Content (Join-Path $source 'schedule.ps1') "`$Blocked = @('*ctrader*', '*other*')"
Set-Content (Join-Path $source 'block.ps1') "New-Object System.Threading.Mutex(`$false, 'Local\AppBlocker')"
Set-Content (Join-Path $source 'rules.txt') 'x'
$threw = $false
try { $null = New-TestCopy $source } catch { $threw = $true }
Assert $threw 'copy refuses a source it cannot make safe'

Set-Content (Join-Path $source 'schedule.ps1') "`$Blocked = @('*ctrader*')"
Set-Content (Join-Path $source 'block.ps1') "New-Object System.Threading.Mutex(`$false, 'Local\AppBlockerX')"
$threw = $false
try { $null = New-TestCopy $source } catch { $threw = $true }
Assert $threw 'copy refuses a source whose mutex name it cannot change'
Complete-Tests
