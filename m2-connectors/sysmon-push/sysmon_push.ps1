$ErrorActionPreference = "Stop"
$logName = "Microsoft-Windows-Sysmon/Operational"
$logstashHost = "127.0.0.1"
$logstashPort = 5000

Write-Host "Reading recent Sysmon Event ID 1 events..."

$events = Get-WinEvent `
    -FilterHashtable @{
        LogName = $logName
        Id      = 1
    } `
    -MaxEvents 10

$client = New-Object System.Net.Sockets.TcpClient
$client.Connect($logstashHost, $logstashPort)

$stream = $client.GetStream()
$writer = New-Object System.IO.StreamWriter(
    $stream,
    [Text.UTF8Encoding]::new($false)
)

$writer.NewLine = "`n"

foreach ($event in $events) {

    $payload = [PSCustomObject]@{
        timestamp   = $event.TimeCreated.ToUniversalTime().ToString("o")
        event_id    = $event.Id
        provider    = $event.ProviderName
        computer    = $event.MachineName
        record_id   = $event.RecordId
        source_type = "sysmon"
        raw_xml     = $event.ToXml()
    } | ConvertTo-Json -Compress

    $writer.WriteLine($payload)

    Write-Host "Sent Sysmon event record $($event.RecordId)"
}

$writer.Flush()
$writer.Dispose()
$stream.Dispose()
$client.Close()

Write-Host "Sysmon events pushed to Logstash successfully."