# Tiny test helpers. Each test file dot-sources this.
$script:Failures = 0
$script:Passes = 0
function Assert([bool]$Condition, [string]$Name) {
    if ($Condition) { $script:Passes++; Write-Output "  pass  $Name" }
    else { $script:Failures++; Write-Output "  FAIL  $Name" }
}
# A fresh folder used as LOCALAPPDATA, so tests never touch the real lock or rules files.
function New-TestFolder {
    $dir = Join-Path ([IO.Path]::GetTempPath()) ("appblocker-test-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    $null = New-Item -ItemType Directory -Path $dir
    return $dir
}
function Complete-Tests {
    Write-Output "  $script:Passes passed, $script:Failures failed"
    exit [int]($script:Failures -gt 0)
}

# Copies the scripts to a scratch folder with a fake app name and test-only mutex names,
# so a test blocker never closes the real cTrader or clashes with the real blocker.
function New-TestCopy {
    $dir = New-TestFolder
    foreach ($file in Get-ChildItem -Path (Join-Path $PSScriptRoot '..') -Filter '*.ps1') {
        $text = Get-Content -LiteralPath $file.FullName -Raw
        $text = $text.Replace("@('*ctrader*')", "@('*kstest*')")
        $text = $text.Replace("'Local\AppBlocker'", "'Local\AppBlockerTest'").Replace("'Local\AppBlockerRules'", "'Local\AppBlockerTestRules'")
        Set-Content -LiteralPath (Join-Path $dir $file.Name) -Value $text
    }
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot '..\rules.txt') -Destination $dir
    return $dir
}
# Starts a hidden process whose name matches the test copy's $Blocked.
function Start-FakeApp([string]$Dir) {
    $exe = Join-Path $Dir 'fakeapp-kstest.exe'
    if (-not (Test-Path $exe)) { Copy-Item "$env:WINDIR\System32\PING.EXE" $exe }
    return Start-Process $exe -ArgumentList '-n', '600', '127.0.0.1' -WindowStyle Hidden -PassThru
}
function Get-FakeApp { Get-Process -Name '*kstest*' -ErrorAction SilentlyContinue }
function Stop-FakeApp { Get-FakeApp | Stop-Process -Force -ErrorAction SilentlyContinue }
# Waits up to $Seconds for $Condition to become true.
function Wait-Until([scriptblock]$Condition, [int]$Seconds) {
    $end = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $end) { if (& $Condition) { return $true }; Start-Sleep -Milliseconds 250 }
    return [bool](& $Condition)
}
# Runs a script from the test copy with its own LOCALAPPDATA, without waiting for it.
function Start-TestScript([string]$Dir, [string]$Name, [string]$AppData) {
    $old = $env:LOCALAPPDATA
    $env:LOCALAPPDATA = $AppData
    try { Start-Process powershell.exe -WindowStyle Hidden -PassThru -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$(Join-Path $Dir $Name)`"" }
    finally { $env:LOCALAPPDATA = $old }
}
