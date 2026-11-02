# App Blocker

Personal Windows tool that stops the owner opening the cTrader desktop app outside set hours. They built it for self-control while trading. They asked for short, plain explanations.

**Never put trading account names or numbers in this repo.**

Last updated: 2026-11-02.

## Rules it enforces

Times follow the laptop's Windows clock (Adelaide time zone, automatic daylight saving on), so no change is needed when daylight saving starts or ends.

| Day | cTrader can open |
|---|---|
| Mon-Thu | 5:30pm to 8pm |
| Friday | Not at all |
| Sat-Sun | All day |

Outside those hours cTrader is closed within about 2 seconds, **unless trades are open**. If trades are open it stays open, and it closes within about 30 seconds of the last trade closing.

At 5:30pm Mon-Thu, as cTrader unlocks, a popup titled **Trading Rules** shows the owner's rules from `rules.txt`. It shows once a day, stays until OK is clicked, and shows late (before 8pm) if the PC was off or asleep at 5:30. Days open from midnight (Sat-Sun) don't get it.

## Current state

- **Blocker: on.** It runs hidden and starts at every Windows sign-in through the `AppBlocker` value in `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`.
- **Real app confirmed blocked:** `blocked.log` shows the real `cTrader` process closed twice on 2026-10-30.
- **cBot: installed and running locally since 2026-10-31.** One account is reporting every 30 seconds and the blocker reads it. If the cBot isn't running, cTrader closes outside hours even with trades open.
- **Git:** branch `main`, pushed to the public GitHub repo `Christen1609/AppBlocker` (remote `origin`).
- **Trading Rules popup: on since 2026-11-02.** Tested by launching it directly; not yet seen firing at 5:30pm.
- **Ultrareview:** failed from the home folder because that git repo covers the whole home directory. It should work from this folder with `/code-review ultra`, but hasn't been run yet.

## Next steps

1. Start the cBot locally (not in the cloud) on any other account being traded, during allowed hours. It only sees the account it runs on.
2. Check whether the cBot restarts by itself when cTrader reopens. Sources disagree, and this hasn't been tested.
3. Confirm the report shows a number above 0 with a real open trade. Reports are in `%USERPROFILE%\OneDrive\Documents\cAlgo\Data\cBots\AppBlockerPositions`.
4. Confirm the Trading Rules popup appears at 5:30pm on a weekday.

## Files

| File | Language | Purpose |
|---|---|---|
| `block.ps1` | PowerShell | Main loop. Checks every 2 seconds and closes blocked apps. |
| `schedule.ps1` | PowerShell | Allowed hours table, `Test-Allowed` and `Test-RulesDue`. |
| `trades.ps1` | PowerShell | Reads cBot reports: `Test-TradesOpen`, `Test-Reporting`, `Test-JustOpened`. |
| `rules.txt` | Text | The owner's trading rules, shown in the popup. |
| `rules.ps1` | PowerShell | Shows `rules.txt` in a popup that stays on top until OK. |
| `install.ps1` | PowerShell | Starts the blocker and adds it to sign-in. |
| `uninstall.ps1` | PowerShell | Stops the blocker and removes it from sign-in. |
| `cBot\AppBlockerPositions.cs` | C# | Writes the open position count to a file every 30 seconds. |
| `cBot\AppBlockerPositions.csproj` | XML | .NET 6 build settings. |
| `AppBlockerPositions.algo` | Binary | Compiled cBot to install in cTrader. Rebuild it after changing the `.cs` file. |
| `blocked.log` | Text | One line per block. Ignored by git. |

## Commands

Run from this folder.

```powershell
# Turn on
powershell -ExecutionPolicy Bypass -File .\install.ps1

# Turn off
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

**After editing any `.ps1` file,** run uninstall then install. The watcher loads the scripts only when it starts, so it keeps the old rules until restarted.

**To change hours,** edit `schedule.ps1`. Hours use a 24-hour clock, `17.5` means 5:30pm, `0, 0` blocks a day and `0, 24` opens it.

**To change the rules,** edit `rules.txt`. No restart needed.

**To block more apps,** add name patterns to `$Blocked` in `block.ps1`.

**To rebuild the cBot,** copy `cBot\*` to a temp folder so `bin` and `obj` stay out of OneDrive, run `dotnet build AppBlockerPositions.csproj -c Release`, then copy the `.algo` it produces back to this folder. The build also drops a copy in `Documents\cAlgo\Sources\Robots`, named after the temp folder's parent. Delete that copy: an instance started from it would write reports to the wrong folder.

## Why it's built this way

- **PowerShell watcher:** the PC runs Windows 10 Home with no AppLocker, and the terminal isn't elevated, so this needs no admin rights.
- **Name match `*ctrader*`:** the install has several versioned exes under `%LOCALAPPDATA%\Spotware\cTrader\<hash>\`, and names change on update.
- **Run key, not Task Scheduler:** logon-triggered tasks usually need admin rights.
- **cBot for trade detection:** an outside script can't see positions. The cBot uses `AccessRights.None`, so it can only write inside its own data folder.
- **One report file per account:** the owner has accounts with several brokers.
- **Any report other than a clean `0` counts as open:** a half-written file can't close the app by accident.
- **Reports count as fresh for 90 seconds:** the cBot writes every 30, so a couple of missed writes are tolerated. The folder is in OneDrive, which can lock files briefly, so the write is wrapped in `try`/`catch`.
- **3-minute startup window:** if the last report showed trades, a newly opened cTrader gets time for the cBot to report. It's measured from the oldest process, so helper processes don't extend it.
- **`System.IO.File` is written in full:** plain `File` clashes with `cAlgo.API.File`.
- **Rules popup runs in its own process:** a popup that waits for OK would pause the loop, so cTrader wouldn't close at 8pm.
- **Rules shown once per day, tracked in memory:** restarting the blocker during allowed hours shows them again, which is harmless.
- **The cBot's class and project are both `AppBlockerPositions` with no spaces:** cTrader names the data folder after the cBot, and `trades.ps1` looks for that name.

## Known limits

- The cTrader web and mobile apps aren't blocked.
- Changing the laptop's clock or time zone gets around the schedule.
- The owner can run `uninstall.ps1` or kill the process, so this adds friction rather than a hard lock.
- Any open trade keeps cTrader open outside hours. Pending orders don't count as trades.
- If the cBot isn't running, cTrader closes even with trades open. A popup warns about this during allowed hours, once cTrader has been open for 3 minutes.
- When cTrader closes, positions and stop-loss or take-profit orders stay with the broker, but cBots running on the PC stop.

## Testing so far

On 2026-11-02 the 5:30pm start and rules timing passed edge tests (5:29:59pm, 5:30pm, 8pm, Friday, weekend), and the popup was confirmed to show all 8 rules and stay open. Earlier: tested with a fake `ctrader-test.exe` and fake report files, and all passed: schedule edges, the April and October 2027 daylight saving changes, and trade-aware closing. On 2026-10-31 the real cBot ran locally in cTrader: the report folder path was confirmed, the file updated every 30 seconds, and `Test-Reporting` returned true. It hasn't yet been tested with a real open trade or across a cTrader restart.
