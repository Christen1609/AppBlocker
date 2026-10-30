# Hours the blocked apps may run, in this PC's local time (24-hour clock, 17.5 = 5:30pm).
# The start time is included, the end time is not. Use 0, 0 to block a day and 0, 24 to open it.
$Schedule = @{
    Monday    = 17, 20
    Tuesday   = 17, 20
    Wednesday = 17, 20
    Thursday  = 17, 20
    Friday    = 0, 0
    Saturday  = 0, 24
    Sunday    = 0, 24
}

function Test-Allowed([datetime]$Time) {
    $start, $end = $Schedule["$($Time.DayOfWeek)"]
    $hour = $Time.TimeOfDay.TotalHours
    return $hour -ge $start -and $hour -lt $end
}
