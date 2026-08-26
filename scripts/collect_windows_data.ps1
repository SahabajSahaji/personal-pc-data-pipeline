

$ProjectPath = "\\wsl$\Ubuntu\home\sahabaj\personal-pc-data-pipeline"
$DataFile = "$ProjectPath\data\system_metrics.csv"
$StateFile = "$ProjectPath\data\network_state.json"

#Date and Time

$Date = Get-Date -Format "yyyy-MM-dd"
$Time = Get-Date -Format "HH:mm:ss"

#Windows Uptime

$BootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$Uptime = (Get-Date) - $BootTime

$UptimeFormatted = "{0:00}:{1:00}:{2:00}" -f `
    [int]$Uptime.TotalHours,
    $Uptime.Minutes,
    $Uptime.Seconds

#CPU Usage

$CPU = (Get-CimInstance Win32_Processor |
    Measure-Object -Property LoadPercentage -Average).Average

$CPU = [math]::Round($CPU, 2)

#Memory Usage

$OS = Get-CimInstance Win32_OperatingSystem

$TotalMemory = $OS.TotalVisibleMemorySize
$FreeMemory = $OS.FreePhysicalMemory

$MemoryUsage = (($TotalMemory - $FreeMemory) / $TotalMemory) * 100
$MemoryUsage = [math]::Round($MemoryUsage, 2)

#Disk Usage


$Disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"

$DiskSizeGB = $Disk.Size / 1GB
$DiskFreeGB = $Disk.FreeSpace / 1GB

$DiskUsage = (($Disk.Size - $Disk.FreeSpace) / $Disk.Size) * 100

$DiskUsage = [math]::Round($DiskUsage, 2)
$DiskFreeGB = [math]::Round($DiskFreeGB, 2)

#Network Interface



$NetworkAdapters = Get-NetAdapterStatistics |
    Where-Object {
        $_.ReceivedBytes -gt 0 -or $_.SentBytes -gt 0
    }

$CurrentDownloadBytes = ($NetworkAdapters |
    Measure-Object -Property ReceivedBytes -Sum).Sum

$CurrentUploadBytes = ($NetworkAdapters |
    Measure-Object -Property SentBytes -Sum).Sum

#Previous Netwrok Counters

$PreviousDownloadBytes = 0
$PreviousUploadBytes = 0

if (Test-Path $StateFile) {

    $PreviousState = Get-Content $StateFile | ConvertFrom-Json

    $PreviousDownloadBytes = $PreviousState.download_bytes
    $PreviousUploadBytes = $PreviousState.upload_bytes
}

#Calculate Network Usage


$DownloadDifference =
    $CurrentDownloadBytes - $PreviousDownloadBytes

$UploadDifference =
    $CurrentUploadBytes - $PreviousUploadBytes

# Handle counter reset
if ($DownloadDifference -lt 0) {
    $DownloadDifference = 0
}

if ($UploadDifference -lt 0) {
    $UploadDifference = 0
}

$DownloadMB = [math]::Round(
    $DownloadDifference / 1MB,
    2
)

$UploadMB = [math]::Round(
    $UploadDifference / 1MB,
    2
)

#Save Current Network Counters

$NetworkState = @{
    download_bytes = $CurrentDownloadBytes
    upload_bytes   = $CurrentUploadBytes
}

$NetworkState |
    ConvertTo-Json |
    Set-Content $StateFile

#Network Speed Measurement



$Before = Get-NetAdapterStatistics |
    Where-Object {
        $_.ReceivedBytes -gt 0 -or $_.SentBytes -gt 0
    }

$BeforeDownload = ($Before |
    Measure-Object -Property ReceivedBytes -Sum).Sum

$BeforeUpload = ($Before |
    Measure-Object -Property SentBytes -Sum).Sum

Start-Sleep -Seconds 2

$After = Get-NetAdapterStatistics |
    Where-Object {
        $_.ReceivedBytes -gt 0 -or $_.SentBytes -gt 0
    }

$AfterDownload = ($After |
    Measure-Object -Property ReceivedBytes -Sum).Sum

$AfterUpload = ($After |
    Measure-Object -Property SentBytes -Sum).Sum

$DownloadSpeedMbps =
    (($AfterDownload - $BeforeDownload) * 8) / 2 / 1MB

$UploadSpeedMbps =
    (($AfterUpload - $BeforeUpload) * 8) / 2 / 1MB

$DownloadSpeedMbps =
    [math]::Round($DownloadSpeedMbps, 2)

$UploadSpeedMbps =
    [math]::Round($UploadSpeedMbps, 2)


#Create CSV Row



$Row = [PSCustomObject]@{

    date                  = $Date
    time                  = $Time
    windows_uptime        = $UptimeFormatted
    cpu_usage             = $CPU
    memory_usage          = $MemoryUsage
    disk_usage            = $DiskUsage
    disk_free             = $DiskFreeGB
    network_download_mb   = $DownloadMB
    network_upload_mb     = $UploadMB
    download_speed        = $DownloadSpeedMbps
    upload_speed          = $UploadSpeedMbps
}

#Append to CSV

$Row |
    Export-Csv `
        -Path $DataFile `
        -NoTypeInformation `
        -Append
