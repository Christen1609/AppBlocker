# Starts the blocker now and at every Windows sign-in.
$script = Join-Path $PSScriptRoot 'block.ps1'
$command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`""

Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'AppBlocker' -Value $command
Start-Process powershell.exe -WindowStyle Hidden -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$script`""

Write-Output 'App Blocker is on.'
