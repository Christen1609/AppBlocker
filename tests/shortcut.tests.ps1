. (Join-Path $PSScriptRoot 'helpers.ps1')
. (Join-Path $PSScriptRoot '..\shortcut.ps1')
$dir = New-TestFolder
$path = Join-Path $dir 'Kill cTrader.lnk'
$script = (Resolve-Path (Join-Path $PSScriptRoot '..\killswitch.ps1')).Path

New-KillShortcut $path
Assert (Test-Path $path) 'shortcut is created'
$link = (New-Object -ComObject WScript.Shell).CreateShortcut($path)
Assert ($link.TargetPath -like '*powershell.exe') 'runs PowerShell'
Assert ($link.Arguments -like "*-WindowStyle Hidden*-File `"$script`"*") 'runs killswitch.ps1 hidden'
Assert ($link.Hotkey -eq 'Alt+Ctrl+K') "shortcut key is Ctrl+Alt+K ($($link.Hotkey))"
Complete-Tests
