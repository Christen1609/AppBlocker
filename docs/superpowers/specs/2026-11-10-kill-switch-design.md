# Kill switch design

## Why
After a losing trade inside the allowed hours, the owner wants to stop overtrading. One press closes cTrader and keeps it shut for 12 hours, then the normal schedule takes over again.

## Decisions (owner accepted the recommended answers, 2026-11-10)
1. During a lock cTrader closes even if a trade looks open. The owner won't press it mid-trade.
2. The press is a desktop icon **Kill cTrader** with the shortcut key **Ctrl+Alt+K**.
3. No confirmation. One press locks.
4. The lock lasts a flat 12 hours from the press. Measured in real elapsed time (stored as UTC), so a daylight saving change doesn't shorten or stretch it.
5. Pressing again while locked restarts the 12 hours. A lock can only get longer.
6. Pressing outside the hours still works (for example, a morning press cancels that evening).
7. The Trading Rules window doesn't show during a lock, and an open one is closed. If the lock ends while the hours are on, the rules show as normal.
8. The lock is saved in `%LOCALAPPDATA%\AppBlocker\kill-until.txt`, so it survives reboots, sleep and blocker restarts.
9. Pressing shows "cTrader locked until <time>" and adds a line to `blocked.log`. While locked, each block says "Kill switch on until <time>".

## Non-goals
- No way to undo a lock from the app.
- No change to the normal hours, rules or trade logic outside a lock.

## Approach
The lock is a file holding the end time. `killswitch.ps1` writes it and closes cTrader at once, so it works even if the blocker isn't running. `block.ps1` reads it every 2 seconds and treats a lock as "closed, no exceptions". The alternative of sending a message to the running blocker was dropped: it fails if the blocker is down and doesn't survive restarts.
