### Show Last boot time ###
systeminfo | find "System Boot Time"

## Get a list of Optional AD Tools installed on local machine. ##
Get-WindowsCapability -Name RSAT* -Online | Select-Object -Property DisplayName, State
