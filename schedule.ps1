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
