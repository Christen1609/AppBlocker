# The kill switch's desktop icon. Windows only honours a shortcut key on icons on the Desktop or in the Start menu.
$KillShortcutPath = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Kill cTrader.lnk'

function New-KillShortcut([string]$Path = $KillShortcutPath) {
    $script = Join-Path $PSScriptRoot 'killswitch.ps1'
    $link = (New-Object -ComObject WScript.Shell).CreateShortcut($Path)
    $link.TargetPath = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
    $link.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`""
    $link.WorkingDirectory = $PSScriptRoot
    $link.Hotkey = 'Ctrl+Alt+K'
    $link.WindowStyle = 7
    # A power-button icon from Windows itself.
    $link.IconLocation = "$env:WINDIR\System32\shell32.dll,27"
    $link.Description = 'Close cTrader and lock it for 12 hours'
    $link.Save()
}
