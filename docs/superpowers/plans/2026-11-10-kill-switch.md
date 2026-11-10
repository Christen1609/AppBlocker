# Kill switch plan

Spec: docs/superpowers/specs/2026-11-10-kill-switch-design.md
Test command: powershell -NoProfile -ExecutionPolicy Bypass -File tests\run.ps1

## Global constraints
Windows PowerShell 5.1, no admin. Tests must not touch the real blocker, the real lock file or the real cTrader: they use their own LOCALAPPDATA, a fake app name and a different mutex.

### Task 1: Lock functions in schedule.ps1
`$KillFile`, `$KillHours = 12`, `Get-KillUntil` (local [datetime] or $null), `Test-KillOn($Time)`, `Set-KillSwitch($Time)` (writes max(existing, Time+12h) in UTC, returns the end time or $null on failure). Move `$Blocked` here so killswitch.ps1 can use it.
Tests (tests/schedule.tests.ps1): no file = off; set = on now, on at +11:59, off at +12h; second press extends; earlier press can't shorten; garbage file = off; unwritable path returns $null.

### Task 2: killswitch.ps1
Sets the lock, closes `$Blocked` apps, logs, shows popup (10s timeout).
Test (tests/killswitch.tests.ps1): with a fake app running, it closes it within 2s, writes the lock file and a log line.

### Task 3: block.ps1 obeys the lock
During a lock: close apps even with fresh open-trade reports, message "Kill switch on until", log "(kill switch)", no rules window, close an open rules window without counting it as a failure. After the lock ends, normal behaviour.
Test (tests/block.tests.ps1): end to end with a scratch copy.

### Task 4: Desktop icon
`shortcut.ps1` with `New-KillShortcut($Path)`; install.ps1 creates it on the Desktop, uninstall.ps1 removes it.
Test: shortcut created in scratch points at killswitch.ps1 with hotkey Ctrl+Alt+K.

### Task 5: Docs
CLAUDE.md and README.
