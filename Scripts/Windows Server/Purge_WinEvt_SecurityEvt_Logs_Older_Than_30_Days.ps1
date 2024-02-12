##########################################
# Author: Robert Stacks
# Date: 6/19/2023
#
# Last Updated by: Robert Stacks
# Last Update Date: 6/20/2023
#
# Purpose of Script: Purge Windows Security Event Archive files older than 30 days.
#                    Windows Events by default are located in C:\Windows\System32\winevt\Logs
#                    Security Events are Archived as "Archive-Security-Year-Month-Day-Hour-Minutes-Seconds-milliseconds.evtx"
#                    Event times are recorded in GMT standard time regardless of timezone configured.
#   
#                    Script was created to prevent the C: Drive from filling up.                  
###############################################################################################

########################################## Variables ###########################################
#These can be updated if needed without touching all parts of the script.
################################################################################################

#Delete local files older than x days add a minus "-" in front of this value.  IE 1 day back is -1.
#Note: Configured for 30 days as default.
$DeleteOlderThanDays = -30

#Windows Event File Path, default is C:\WINDOWS\System32\winevt\Logs
$EventArchivePath = "C:\Windows\System32\winevt\Logs"

########################################## Main Script ##########################################
#Get a list of files in the Path listed above and only select those files with the name Archive-Security in them and
#and only those older than the variable listed above then remove anything that matches those conditions.
Get-ChildItem -Path $EventArchivePath | Where-Object {($_.Name -like "Archive-Security*.*") -and ($_.LastWriteTime -lt (Get-Date).AddDays($DeleteOlderThanDays))} | Remove-Item
