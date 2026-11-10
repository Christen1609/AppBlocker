# Runs every *.tests.ps1 file in its own PowerShell and reports the total.
$failed = @()
foreach ($file in Get-ChildItem -Path $PSScriptRoot -Filter '*.tests.ps1' | Sort-Object Name) {
    Write-Output $file.Name
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $file.FullName
    if ($LASTEXITCODE -ne 0) { $failed += $file.Name }
}
if ($failed) { Write-Output "FAILED: $($failed -join ', ')"; exit 1 }
Write-Output 'ALL PASSED'
