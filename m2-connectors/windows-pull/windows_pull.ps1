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
    Write-Host "Sending events to Logstash..."

    $client = New-Object System.Net.Sockets.TcpClient
    $client.Connect("127.0.0.1", 5000)

    $stream = $client.GetStream()
    $writer = New-Object System.IO.StreamWriter(
        $stream,
        [Text.UTF8Encoding]::new($false)
    )

    $writer.NewLine = "`n"

    Get-Content $outputFile | ForEach-Object {
        $writer.WriteLine($_)
    }

    $writer.Flush()
    $writer.Dispose()
    $stream.Dispose()
    $client.Close()

    Write-Host "Sent to Logstash successfully."
}