# App Blocker

Closes the cTrader desktop app outside set hours on Windows, unless trades are open.

| Day | cTrader can open |
|---|---|
| Mon-Thu | 5:30pm to 8pm |
| Friday | Not at all |
| Sat-Sun | All day |

Times follow the PC's clock, so daylight saving is handled automatically.

At 5:30pm Monday to Thursday a **Trading Rules** window shows your rules. cTrader stays locked until you click **I've read the rules** with the mouse. The window can't be closed any other way, and it closes itself at 8pm. If it can't open, a plain popup shows the rules and OK counts as read. If it keeps failing, the rules are skipped for that day so a bug can't lock you out.

## How it works

1. `block.ps1` runs hidden in the background and checks every 2 seconds.
2. Outside your hours, it closes cTrader unless your trades are still open.
3. The `AppBlockerPositions` cBot tells it about open trades by writing the count to a file every 30 seconds.
4. When your hours start, it shows the rules in `rules.txt` and keeps cTrader closed until you click the button. You only need to click once a day. If the PC is asleep or off at 5:30pm, the rules show as soon as it's back on, before 8pm.

## Setup

1. During your hours, double-click `AppBlockerPositions.algo` to add the cBot to cTrader.
2. In cTrader, start the cBot **locally**, not in the cloud, on every account you trade.
3. Turn the blocker on.

## Turn on and off

Run these from this folder.

```powershell
# On: starts now and at every Windows sign-in
powershell -ExecutionPolicy Bypass -File .\install.ps1

# Off
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

## Change the hours

Edit `schedule.ps1`, then turn the blocker off and on again.

- Hours use a 24-hour clock, and `17.5` means 5:30pm.
- `0, 0` blocks a whole day.
- `0, 24` opens a whole day.

## Change your rules

Edit `rules.txt`. No restart needed: the window reads it each time. A long list scrolls inside the window.

## Files

| File | Purpose |
|---|---|
| `block.ps1` | Main script that closes cTrader |
| `schedule.ps1` | Your allowed hours |
| `trades.ps1` | Reads the cBot's reports |
| `rules.txt` | Your trading rules |
| `rules.ps1` | Shows the rules window and its unlock button (or a plain popup if the window can't open) |
| `install.ps1` | Turns the blocker on |
| `uninstall.ps1` | Turns the blocker off, and closes the rules window if it's open |
| `AppBlockerPositions.algo` | The cBot, ready to install |
| `cBot\` | The cBot's source code |
| `blocked.log` | Created on the first block. Lists each time cTrader was closed. |

## Limits

- The cTrader web and mobile apps aren't blocked.
- Changing the PC's clock or time zone gets around the schedule.
- You can turn it off yourself, so it adds friction rather than a hard lock.
- Any open trade keeps cTrader open outside your hours, and before you click the rules button. Pending orders don't count.
- If the cBot isn't running, cTrader closes even with trades open.
- If the rules window fails 3 times in a day, the rules are skipped until tomorrow.
