# Stops the blocker and removes it from Windows sign-in.
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'AppBlocker' -ErrorAction SilentlyContinue

Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object { $_.CommandLine -like '*AppBlocker\block.ps1*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

Write-Output 'App Blocker is off.'
