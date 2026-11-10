# Starts the blocker now and at every Windows sign-in.
$script = Join-Path $PSScriptRoot 'block.ps1'
$command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`""

Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'AppBlocker' -Value $command
Start-Process powershell.exe -WindowStyle Hidden -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$script`""

# Desktop icon for the kill switch, with the shortcut key Ctrl+Alt+K.
. (Join-Path $PSScriptRoot 'shortcut.ps1')
New-KillShortcut

Write-Output 'App Blocker is on. Kill switch: the "Kill cTrader" desktop icon or Ctrl+Alt+K.'
