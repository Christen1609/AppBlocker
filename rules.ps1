# Shows the trading rules in rules.txt. block.ps1 starts this when cTrader unlocks.
$rules = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'rules.txt') -Raw
$shell = New-Object -ComObject WScript.Shell
# 0 = stays until OK is clicked, 64 = information icon, 4096 = on top of other windows.
$null = $shell.Popup($rules, 0, 'Trading Rules', 64 + 4096)
