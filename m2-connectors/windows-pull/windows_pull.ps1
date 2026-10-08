$dropFolder = Join-Path $PSScriptRoot "drop"
$outputFolder = Join-Path $PSScriptRoot "output"

New-Item -ItemType Directory -Force -Path $outputFolder | Out-Null

$files = Get-ChildItem -Path $dropFolder -Filter "*.evtx"

foreach ($file in $files) {

    Write-Host "Reading $($file.Name)..."

    $outputFile = Join-Path $outputFolder ($file.BaseName + ".ndjson")

    Get-WinEvent -Path $file.FullName |
    ForEach-Object {

        [PSCustomObject]@{
            timestamp = $_.TimeCreated.ToUniversalTime().ToString("o")
            event_id  = $_.Id
            provider  = $_.ProviderName
            computer  = $_.MachineName
            record_id = $_.RecordId
            raw_xml   = $_.ToXml()
        } | ConvertTo-Json -Compress

    } | Set-Content -Path $outputFile -Encoding UTF8

    Write-Host "Created: $outputFile"
}