# App Blocker

Closes the cTrader desktop app outside set hours on Windows, unless trades are open.

| Day | cTrader can open |
|---|---|
| Mon-Thu | 5:30pm to 8pm |
| Friday | Not at all |
| Sat-Sun | All day |

Times follow the PC's clock, so daylight saving is handled automatically.

At 5:30pm Monday to Thursday, as cTrader unlocks, a **Trading Rules** popup shows your rules. It stays until you click OK.

## How it works

1. `block.ps1` runs hidden in the background and checks every 2 seconds.
2. Outside your hours, it closes cTrader unless your trades are still open.
3. The `AppBlockerPositions` cBot tells it about open trades by writing the count to a file every 30 seconds.
4. When your hours start, it shows the rules in `rules.txt`. If the PC is asleep or off at 5:30pm, they show as soon as it's back on, before 8pm.

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

Edit `rules.txt`. No restart needed: the popup reads it each time.

## Files

| File | Purpose |
|---|---|
| `block.ps1` | Main script that closes cTrader |
| `schedule.ps1` | Your allowed hours |
| `trades.ps1` | Reads the cBot's reports |
| `rules.txt` | Your trading rules |
| `rules.ps1` | Shows the rules popup |
| `install.ps1` | Turns the blocker on |
| `uninstall.ps1` | Turns the blocker off |
| `AppBlockerPositions.algo` | The cBot, ready to install |
| `cBot\` | The cBot's source code |
| `blocked.log` | Created on the first block. Lists each time cTrader was closed. |

## Limits

- The cTrader web and mobile apps aren't blocked.
- Changing the PC's clock or time zone gets around the schedule.
- You can turn it off yourself, so it adds friction rather than a hard lock.
- Any open trade keeps cTrader open outside your hours. Pending orders don't count.
- If the cBot isn't running, cTrader closes even with trades open.
