# Add Veeam VB365 PowerShell Snap-in
Add-PSSnapin Veeam.Archiver.PowerShell -ErrorAction SilentlyContinue

# Timestamped output
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$exportPath = "C:\Scripts\Veeam\Backup_Job_Config\VBOJobDetails_$timestamp.json"

# Gather all job info
$jobDetails = foreach ($job in Get-VBOJob) {
    $backupItems = Get-VBOBackupItem -Job $job

    $protectedItems = foreach ($item in $backupItems) {
        [PSCustomObject]@{
            Type            = $item.Type
            MembersIncluded = $item.Members
            Mailbox         = $item.Mailbox
            OneDrive        = $item.OneDrive
            ArchiveMailbox  = $item.ArchiveMailbox
            Site            = $item.Site
            GroupMailbox    = $item.GroupMailbox
            GroupSite       = $item.GroupSite
        }
    }

    $schedule = $job.SchedulePolicy
    $dailyTime = if ($schedule.DailyTime) { "$($schedule.DailyTime.Hours):$($schedule.DailyTime.Minutes)" } else { "N/A" }

    [PSCustomObject]@{
        Name            = $job.Name
        Repository      = $job.Repository.Name
        Enabled         = $job.IsEnabled
        ScheduleType    = $schedule.Type
        DailyStartTime  = $dailyTime
        RetryEnabled    = $schedule.RetryEnabled
        RetryCount      = $schedule.RetryNumber
        RetryInterval   = "$($schedule.RetryWaitInterval) mins"
        ProtectedItems  = $protectedItems
    }
}

# Export to JSON
$jobDetails | ConvertTo-Json -Depth 6 | Out-File -FilePath $exportPath -Encoding UTF8

Write-Output "Export complete: $exportPath"
