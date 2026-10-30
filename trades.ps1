# Reads the reports from the AppBlockerPositions cBot: one file per account, holding its open position count.
$ReportDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'cAlgo\Data\cBots\AppBlockerPositions'
$FreshSeconds = 90
$StartupSeconds = 180

function Get-Reports {
    Get-ChildItem -LiteralPath $ReportDir -Filter 'positions-*.txt' -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        [pscustomobject]@{
            Fresh = $_.LastWriteTime -gt (Get-Date).AddSeconds(-$FreshSeconds)
            # Anything but a clean 0 counts as open, so a half-written file never closes the app.
            Open  = "$(Get-Content -LiteralPath $_.FullName -ErrorAction SilentlyContinue)" -ne '0'
        }
    }
}

function Test-JustOpened($Apps) {
    $opened = $Apps.StartTime | Sort-Object | Select-Object -First 1
    return $opened -gt (Get-Date).AddSeconds(-$StartupSeconds)
}

function Test-Reporting {
    return [bool](Get-Reports | Where-Object { $_.Fresh })
}

function Test-TradesOpen($Apps) {
    $reports = @(Get-Reports)
    if ($reports | Where-Object { $_.Fresh -and $_.Open }) { return $true }
    # The cBot needs time to report after cTrader opens, so trust its last report until then.
    return [bool]((Test-JustOpened $Apps) -and ($reports | Where-Object { $_.Open }))
}
