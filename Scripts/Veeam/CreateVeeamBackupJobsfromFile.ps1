<#
.SYNOPSIS
    Script Script for "Veeam for Microsoft 365" that uses a list to create backups jobs in Veeam.  One for Email, Onedrive, and Sharepoint/Teams.
	Also creates a copy job of the primary backup.
	Input file is simply a list of TLAs line by line.

.NOTES
    Name: CreateVeeamBackupJobsfromCSV.ps1
    Author: Robert Stacks
    DateCreated: 02-17-25
#>
############ User Variables #############
$Organization = "org.onmicrosoft.com" 
$BackupStorageTarget = "Primary Backup Storage Object Name"
$BackupCopyStorageTarget = "Primary Backup Storage Object Name"
$Inputfile = "c:\temp\inputTLA.txt"
$ScheduleBackupTime = "22:00:00"  

# Note: You may want to rename the follow Variables below, however they need to be in the loop to work correctly.
# $AzureGroupName= $TLA + "-VEEAM-M365Backup"
# $OneDName = $TLA + "-Onedrive"
#  $SiteName = $TLA + "-Sharepoint-Teams"

############## Script ###################

### Loop through TLAs and Create Jobs ###
$TLAs = Get-Content $Inputfile
foreach($TLA in $TLAs)
{
 #Create variables based on TLA Name to be used by other commands.
 $AzureGroupName= $TLA + "-VEEAM-M365Backup"
 #Backup Job names
 $OneDName = $TLA + "-Onedrive"
 $SiteName = $TLA + "-Sharepoint-Teams"
 
 ### Create Backup Jobs ###
  #Define Org for Add Job command
  $org = Get-VBOOrganization -Name $Organization

  #Define Storage to be used by Job command
  $repository = Get-VBORepository -Name $BackupStorageTarget

  #Define Azure Group to backup
  $group=get-vboorganizationgroup -Organization $org -DisplayName $AzureGroupName

  #Define the things you want to backup in the Job Commands, one for each type of backup job
  # $Mailitems = New-VBOBackupItem -Group $group -Mailbox -ArchiveMailbox
   $OneDitems = New-VBOBackupItem -Group $group -Onedrive
   $SiteItems = New-VBOBackupItem -Group $group -Sites

  #Define the Schedule in the backup jobs, using the same one for all sites
  $daily = New-VBOJobSchedulePolicy -Type Daily -DailyType Everyday -DailyTime $ScheduleBackupTime -RetryEnabled -RetryNumber 3 -RetryWaitInterval 10

  #Create backup jobs using the values defined above, one for each job type ie. Email, OneDrive, and Sites (SharePoint and Teams)
  # Add-VBOJob -Name $EmailName -Organization $org -Repository $repository -SelectedItems $Mailitems -SchedulePolicy $daily
  Add-VBOJob -Name $OneDName -Organization $org -Repository $repository -SelectedItems $OneDitems -SchedulePolicy $daily
  Add-VBOJob -Name $SiteName -Organization $org -Repository $repository -SelectedItems $SiteItems -SchedulePolicy $daily

 ### Create Backup Copy Jobs ###
  #Get Jobs created above
  # $Emailjob = Get-VBOJob -Name $EmailName
  $OneDjob = Get-VBOJob -Name $OneDName
  $Sitejob = Get-VBOJob -Name $SiteName

  #Set Repo for Copy jobs
  $CopyJobRepo = Get-VBORepository -Name $BackupCopyStorageTarget

  #Create Copy jobs for each job created above - Defaults to schedule Immediately so we don't define that.
  # Add-VBOCopyJob -Repository $CopyJobRepo -BackupJob $Emailjob
  Add-VBOCopyJob -Repository $CopyJobRepo -BackupJob $OneDjob
  Add-VBOCopyJob -Repository $CopyJobRepo -BackupJob $Sitejob
}