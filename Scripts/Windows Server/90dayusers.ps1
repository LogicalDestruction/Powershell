<#
	Very short script to get a list of users that haven't logged in over the past 90 days.
	Useful if you want ot audit AD or disable users older than x number of days.
#>

$InactiveDays = 90
$Days = (Get-Date).Adddays(-($InactiveDays))

Get-ADUser -Filter {LastLogonTimeStamp -lt $Days -and enabled -eq $true} -Properties LastLogonTimeStamp |select-object Name,@{Name="Date"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('MM-dd-yyyy')}} | export-csv C:\~\Desktop\inactive_Users.csv -notypeinformation