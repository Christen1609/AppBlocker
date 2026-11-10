# App Blocker

Personal Windows tool that stops the owner opening the cTrader desktop app outside set hours. They built it for self-control while trading. They asked for short, plain explanations.

**Never put trading account names or numbers in this repo.**

Last updated: 2026-11-10.

## Rules it enforces

Times follow the laptop's Windows clock (Adelaide time zone, automatic daylight saving on), so no change is needed when daylight saving starts or ends.

| Day | cTrader can open |
|---|---|
| Mon-Thu | 5:30pm to 8pm |
| Friday | Not at all |
| Sat-Sun | All day |

Outside those hours cTrader is closed within about 2 seconds, **unless trades are open**. If trades are open it stays open, and it closes within about 30 seconds of the last trade closing.

At 5:30pm Mon-Thu a window titled **Trading Rules** shows the owner's rules from `rules.txt`, and cTrader stays closed (unless trades are open) until **I've read the rules** is clicked with the mouse. The click is saved as today's date in `%LOCALAPPDATA%\AppBlocker\rules-read.txt`, so it's needed once a day and survives restarts. The window can't be closed any other way, and reopens if it's killed. If the PC was off or asleep at 5:30 it shows when it's back on, before 8pm. Days open from midnight (Sat-Sun) don't need it.

**Kill switch:** the **Kill cTrader** desktop icon (or **Ctrl+Alt+K**) closes cTrader at once and locks it for 12 hours, whatever the hours or open trades say. There's no confirmation and no undo. Pressing again restarts the 12 hours (a lock only gets longer). It works outside the hours too, so a morning press cancels that evening. During a lock the Trading Rules window doesn't show, and an open one closes. If the lock ends while the hours are on, the rules show as normal. The end time is saved in UTC in `%LOCALAPPDATA%\AppBlocker\kill-until.txt`, so it survives restarts and daylight saving changes. The press and each block are logged in `blocked.log`.

The window only exists while the day's hours are on. If it's still open at 8pm it closes itself without saving, so an old click can't unlock a later day. If it can't open at all, a plain popup shows the same rules and clicking OK counts as read. If the window fails 3 times in a day (it closes within 15 seconds without a click), the rules are skipped for the rest of that day, a line goes in `blocked.log`, and a popup says so.

## Current state

- **Blocker: on.** It runs hidden and starts at every Windows sign-in through the `AppBlocker` value in `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`.
- **Real app confirmed blocked:** `blocked.log` shows the real `cTrader` process closed twice on 2026-10-30.
- **cBot: installed and running locally since 2026-10-31.** One account is reporting every 30 seconds and the blocker reads it. If the cBot isn't running, cTrader closes outside hours even with trades open.
- **Git:** branch `main`, pushed to the public GitHub repo `Christen1609/AppBlocker` (remote `origin`).
- **Trading Rules window and unlock button: on since 2026-11-02.** Tested end to end with a fake app, but not yet seen at a real 5:30pm.
- **Review fixes (2026-11-03): running.** The blocker was restarted with them at 8:15am, after the tests were re-run and passed.
- **Kill switch: built and tested 2026-11-10,** merged to `main` and running. Not yet pressed for real.
- **Ultrareview:** failed from the home folder because that git repo covers the whole home directory. It should work from this folder with `/code-review ultra`, but hasn't been run yet.

## Next steps

1. Start the cBot locally (not in the cloud) on any other account being traded, during allowed hours. It only sees the account it runs on.
2. Check whether the cBot restarts by itself when cTrader reopens. Sources disagree, and this hasn't been tested.
3. Confirm the report shows a number above 0 with a real open trade. Reports are in `%USERPROFILE%\OneDrive\Documents\cAlgo\Data\cBots\AppBlockerPositions`.
4. Confirm the Trading Rules window appears at 5:30pm on a weekday and the button unlocks cTrader.
5. Check the **Kill cTrader** icon is on the desktop and that Ctrl+Alt+K works while cTrader is in front.

## Files

| File | Language | Purpose |
|---|---|---|
| `block.ps1` | PowerShell | Main loop. Checks every 2 seconds and closes blocked apps. |
| `schedule.ps1` | PowerShell | Allowed hours table, the `$Blocked` and `$RulesDays` lists, `Test-Allowed`, `Test-RulesDue`, `Test-RulesRead`, `Set-RulesRead`, and the kill switch's `Get-KillUntil`, `Test-KillOn` and `Set-KillSwitch`. |
| `killswitch.ps1` | PowerShell | The kill switch. Saves the 12-hour lock, closes cTrader and shows when the lock ends. |
| `shortcut.ps1` | PowerShell | `New-KillShortcut`, which makes the **Kill cTrader** desktop icon with Ctrl+Alt+K. |
| `tests\` | PowerShell | Automated tests. They use scratch copies, a fake app and their own `LOCALAPPDATA`, so the real blocker, lock and cTrader are never touched. |
| `trades.ps1` | PowerShell | Reads cBot reports: `Test-TradesOpen`, `Test-Reporting`, `Test-JustOpened`. |
| `rules.txt` | Text | The owner's trading rules, shown in the popup. |
| `rules.ps1` | PowerShell | Shows `rules.txt` in an always-on-top window with the **I've read the rules** button, and saves the click. Falls back to a plain popup if the window can't open. |
| `install.ps1` | PowerShell | Starts the blocker, adds it to sign-in and makes the **Kill cTrader** desktop icon. |
| `uninstall.ps1` | PowerShell | Stops the blocker and any open rules window, removes it from sign-in and deletes the desktop icon. An active lock stays saved. |
| `cBot\AppBlockerPositions.cs` | C# | Writes the open position count to a file every 30 seconds. |
| `cBot\AppBlockerPositions.csproj` | XML | .NET 6 build settings. |
| `AppBlockerPositions.algo` | Binary | Compiled cBot to install in cTrader. Rebuild it after changing the `.cs` file. |
| `blocked.log` | Text | One line per block, marked `(rules not read)` when the button hadn't been clicked. Ignored by git. |

## Commands

Run from this folder.

```powershell
# Turn on
powershell -ExecutionPolicy Bypass -File .\install.ps1

# Turn off
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1

# Run the tests (about 2 minutes; on Mon-Thu a test Trading Rules window flashes up)
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1
```

**After editing any `.ps1` file,** run uninstall then install. The watcher loads the scripts only when it starts, so it keeps the old rules until restarted.

**To change hours,** edit `schedule.ps1`. Hours use a 24-hour clock, `17.5` means 5:30pm, `0, 0` blocks a day and `0, 24` opens it.

**To change the rules,** edit `rules.txt`. No restart needed.

**To block more apps,** add name patterns to `$Blocked` in `schedule.ps1`.

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
- **Rules window runs in its own process:** a window that waits for a click would pause the loop, so cTrader wouldn't close at 8pm. A mutex keeps it to one window.
- **Click saved to a file outside OneDrive:** a sync lock could hide the click and close cTrader by mistake. A file also survives blocker restarts.
- **Unlocks on mouse click only:** in testing, a window that took focus with the button selected could be clicked by a Space or Enter meant for another app. It also opens without taking focus.
- **`ShowWindow` call in `rules.ps1`:** `block.ps1` starts it hidden, and Windows applies that to the process's first window, so the form stays invisible without it.
- **The window only runs and saves while the hours are on:** it exits at start if they aren't, and a timer closes it without saving once they end. A click on a window left open overnight, or one started by hand early, would otherwise unlock a later day without showing the rules.
- **Rules sit in a scroll box with a capped height:** a long `rules.txt` can't push the button off a small screen. Short lists show with no scroll bar.
- **Fallback popup if the window can't open:** a hidden failure would leave cTrader locked with no button. The popup closes when the hours end.
- **Quick failures are counted and slowed:** a rules window that dies within 15 seconds without a click waits 30 seconds before the next try, and after 3 the rules are skipped for the day. A broken `rules.ps1` can't lock the owner out all evening or launch thousands of PowerShell processes. A window the owner kills after 15 seconds is relaunched straight away.
- **`Set-RulesRead` owns the date and the write:** the caller passes the same time it used to check the hours, so a click at 23:59:59 can't write one day and check another. Closing depends on a flag set by a successful save, not on re-reading the file. If the save fails, the window says so.
- **`block.ps1` stops re-reading the click file once it has seen today's click.**
- **`rules.txt` is read as UTF-8:** Windows PowerShell 5.1 otherwise garbles curly quotes and dashes. A missing or empty file shows a message and still lets the button unlock.
- **Block popups use the stay-on-top flag:** otherwise they open behind the always-on-top rules window.
- **Open trades beat the rules lock:** if trades are open at 5:30, cTrader stays open before the button is clicked.
- **Kill switch is a file, not a message to the blocker:** it works if the blocker is down and survives restarts. `killswitch.ps1` also closes cTrader itself, so it's instant.
- **Kill switch beats open trades:** the owner only presses it when out of trades, and a stale report mustn't keep cTrader open.
- **Lock stored in UTC:** 12 real hours, even across a daylight saving change.
- **`uninstall.ps1` keeps the lock file:** turning the blocker off and on can't clear a lock.
- **`$Blocked` lives in `schedule.ps1`:** both `block.ps1` and `killswitch.ps1` need it.
- **The cBot's class and project are both `AppBlockerPositions` with no spaces:** cTrader names the data folder after the cBot, and `trades.ps1` looks for that name.

## Known limits

- The cTrader web and mobile apps aren't blocked.
- Changing the laptop's clock or time zone gets around the schedule.
- The owner can run `uninstall.ps1` or kill the process, so this adds friction rather than a hard lock.
- Any open trade keeps cTrader open outside hours. Pending orders don't count as trades.
- Writing today's date into `rules-read.txt` gets around the rules button. Deleting `kill-until.txt` ends a kill switch lock.
- Ctrl+Alt+K only works while the icon is on the Desktop (Windows ignores shortcut keys on other shortcuts), and another app could claim the same keys.
- If the rules window fails 3 times, the rules are skipped for that day. That is on purpose, so a bug can't lock the owner out.
- The fallback popup has no mouse-only rule: Enter or Space on OK counts as read. A very long `rules.txt` may not fit in it.
- If the cBot isn't running, cTrader closes even with trades open. A popup warns about this during allowed hours, once cTrader has been open for 3 minutes.
- When cTrader closes, positions and stop-loss or take-profit orders stay with the broker, but cBots running on the PC stop.

## Testing so far

On 2026-11-10, `tests\run.ps1` passed (38 checks). Lock timing: on until exactly 12 hours, a second press extends, an earlier press can't shorten, a bad or missing file means no lock, a failed save is reported, and it's 12 real hours across the October 2027 daylight saving change. The kill switch closes a fake app and logs. End to end with a test blocker: the lock closes the app even with a fresh open-trade report, an expired lock lets it run, no rules window shows during a lock, an open one is closed without counting as a failure, and the rules show straight away when the lock ends. The desktop icon runs `killswitch.ps1` hidden with Ctrl+Alt+K. The test copy refuses to run if it still matches the real cTrader or uses the real mutex.

On 2026-11-03, on copies in a scratch folder (real blocker untouched), with a fake app: schedule edge cases passed again. The end-to-end run passed (window shows, can't be closed, Space doesn't unlock, app closed and logged before the click, mouse click unlocks, app stays open, window doesn't return). A window left open past the end of the hours closed itself and saved nothing, and `rules.ps1` run outside the hours exited at once. A 40-line `rules.txt` fitted the screen with a scroll bar and the button still worked. With the window forced to fail, the fallback popup showed the rules and OK saved the read. With a `rules.ps1` that exits at once, it was launched 3 times in 100 seconds (about 30 seconds apart), then the rules were skipped, a line went in the log and the app was allowed. Curly quotes and dashes showed correctly, a missing or empty `rules.txt` showed a message, and a failed save showed "Couldn't save" then worked on retry. The `uninstall.ps1` filter stopped a test blocker and its rules window and left the real blocker alone. Not yet seen at a real 5:30pm.

On 2026-11-02 the 5:30pm start and rules timing passed edge tests (5:29:59pm, 5:30pm, 8pm, Friday, weekend), and the popup was confirmed to show all 8 rules and stay open. After the unlock button was added, an end-to-end test with a fake app confirmed: the window opens, the X can't close it, the app is closed until the button is clicked, Space doesn't unlock it, a real mouse click does, and the window doesn't come back that day. Earlier: tested with a fake `ctrader-test.exe` and fake report files, and all passed: schedule edges, the April and October 2027 daylight saving changes, and trade-aware closing. On 2026-10-31 the real cBot ran locally in cTrader: the report folder path was confirmed, the file updated every 30 seconds, and `Test-Reporting` returned true. It hasn't yet been tested with a real open trade or across a cTrader restart.
