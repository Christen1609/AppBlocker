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
