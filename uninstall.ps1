# Stops the blocker (and any open rules window) and removes it from Windows sign-in.
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'AppBlocker' -ErrorAction SilentlyContinue

function Stop-Script([string]$Pattern) {
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
        Where-Object { $_.CommandLine -like $Pattern } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
}

# The watcher first, so it can't open the rules window again.
Stop-Script '*AppBlocker\block.ps1*'
Stop-Script '*AppBlocker\rules.ps1*'

Write-Output 'App Blocker is off.'
