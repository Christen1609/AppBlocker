# Kill switch: closes cTrader now and keeps it locked for 12 hours, whatever the schedule says.
# Started by the "Kill cTrader" desktop icon (Ctrl+Alt+K). There's no undo.
. (Join-Path $PSScriptRoot 'schedule.ps1')

$until = Set-KillSwitch (Get-Date)
# Close straight away, so it works even if the blocker isn't running. block.ps1 keeps it closed after this.
Get-Process -Name $Blocked -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

$shell = New-Object -ComObject WScript.Shell
# 4096 = stay on top. 64 = information icon, 16 = error icon.
if ($until) {
    $when = $until.ToString('dddd d MMM, h:mm tt')
    Add-Content -Path (Join-Path $PSScriptRoot 'blocked.log') -Value "$(Get-Date -Format s)  kill switch on until $($until.ToString('s'))"
    $null = $shell.Popup("cTrader is locked until $when.", 10, 'App Blocker', 64 + 4096)
}
else {
    $null = $shell.Popup("The kill switch couldn't save the lock. cTrader was closed, but may open again.", 0, 'App Blocker', 16 + 4096)
}
