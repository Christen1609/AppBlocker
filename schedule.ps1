# Hours the blocked apps may run, in this PC's local time (24-hour clock, 17.5 = 5:30pm).
# The start time is included, the end time is not. Use 0, 0 to block a day and 0, 24 to open it.
$Schedule = @{
    Monday    = 17.5, 20
    Tuesday   = 17.5, 20
    Wednesday = 17.5, 20
    Thursday  = 17.5, 20
    Friday    = 0, 0
    Saturday  = 0, 24
    Sunday    = 0, 24
}

function Test-Allowed([datetime]$Time) {
    $start, $end = $Schedule["$($Time.DayOfWeek)"]
    $hour = $Time.TimeOfDay.TotalHours
    return $hour -ge $start -and $hour -lt $end
}

# Days that show the rules when the hours begin. Sat-Sun are open all day, so they don't need them.
$RulesDays = 'Monday', 'Tuesday', 'Wednesday', 'Thursday'

# True while the hours are on for a day in $RulesDays, so the rules show when cTrader unlocks.
function Test-RulesDue([datetime]$Time) {
    return ($RulesDays -contains "$($Time.DayOfWeek)") -and (Test-Allowed $Time)
}

# Whole seconds until today's hours end (0 or less once they have).
function Get-SecondsLeft([datetime]$Time) {
    $start, $end = $Schedule["$($Time.DayOfWeek)"]
    return [int][Math]::Ceiling($end * 3600 - $Time.TimeOfDay.TotalSeconds)
}

# Holds the date "I've read the rules" was last clicked. Kept outside OneDrive so a sync lock can't hide a click.
$RulesReadFile = Join-Path $env:LOCALAPPDATA 'AppBlocker\rules-read.txt'

function Test-RulesRead([datetime]$Time) {
    $read = Get-Content -LiteralPath $RulesReadFile -ErrorAction SilentlyContinue
    return "$read".Trim() -eq $Time.ToString('yyyy-MM-dd')
}

# Saves the click as $Time's date. Pass the same $Time you used to check the hours, so both use one day.
# Returns $false if the file couldn't be written (for example, if it is locked).
function Set-RulesRead([datetime]$Time) {
    try {
        $null = New-Item -ItemType Directory -Force -Path (Split-Path $RulesReadFile) -ErrorAction Stop
        Set-Content -LiteralPath $RulesReadFile -Value $Time.ToString('yyyy-MM-dd') -ErrorAction Stop
        return $true
    }
    catch { return $false }
}

# Name patterns of the apps to close. Add more here.
$Blocked = @('*ctrader*')

# Kill switch: one press locks the blocked apps for 12 hours, whatever the schedule says.
# The end time is kept in UTC, so a daylight saving change doesn't move it. Outside OneDrive, like the rules file.
$KillHours = 12
$KillFile = Join-Path $env:LOCALAPPDATA 'AppBlocker\kill-until.txt'

# The lock's end time in local time, or $null if there's no lock file or it can't be read.
function Get-KillUntil {
    $text = "$(Get-Content -LiteralPath $KillFile -ErrorAction SilentlyContinue)".Trim()
    $until = [datetime]::MinValue
    $styles = [Globalization.DateTimeStyles]::RoundtripKind
    if (-not [datetime]::TryParse($text, [Globalization.CultureInfo]::InvariantCulture, $styles, [ref]$until)) { return $null }
    return $until.ToLocalTime()
}

function Test-KillOn([datetime]$Time) {
    $until = Get-KillUntil
    return ($null -ne $until) -and $Time.ToUniversalTime() -lt $until.ToUniversalTime()
}

# Locks until 12 hours after $Time. A lock can only get longer, never shorter.
# Returns the end time in local time, or $null if the file couldn't be written.
function Set-KillSwitch([datetime]$Time) {
    $until = $Time.ToUniversalTime().AddHours($KillHours)
    $current = Get-KillUntil
    if ($current -and $current.ToUniversalTime() -gt $until) { $until = $current.ToUniversalTime() }
    try {
        $null = New-Item -ItemType Directory -Force -Path (Split-Path $KillFile) -ErrorAction Stop
        Set-Content -LiteralPath $KillFile -Value $until.ToString('o') -ErrorAction Stop
        return $until.ToLocalTime()
    }
    catch { return $null }
}
