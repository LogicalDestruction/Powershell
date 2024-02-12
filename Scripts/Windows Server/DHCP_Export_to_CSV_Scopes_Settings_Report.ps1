<############################################################################################
.DESCRIPTION
	This script checks AD and gets a list of all DHCP Servers then exports the scopes 
	to a CSV file. You can then import this file into Excel for review.
	Tested and used to review 4000+ DHCP Scopes
.NOTES
	Author: Robert Stacks
	Last Updated: 1-3-2024
############################################################################################>

#############################################################################################
# Variables
#############################################################################################

#File we will write to for the Csv
$OutputfileLocalPath = "C:\Scripts\DHCP_Scope_Settings_Report\"
$OutputfileName = "DHCP_Scope_Settings.csv"

#List of DHCP Options we are interested in reviewing.
$dhcpoptionids = 3,6,15  

## Uncomment one of the following  ##
#Get List of DHCP Servers in Active Directory Dynamically
#$DHCP_Servers = Get-DhcpServerInDC | ForEach-Object {$_.DnsName} | Sort-Object -Property DnsName 

#Testing one server
#$DHCP_Servers = "SVR-DHCP-01"

#############################################################################################
# Main Script
#############################################################################################

#Combine Outputfile info into one Variables
$Outputfile = $OutputfileLocalPath + $OutputfileName

#Create Header for CSV Export
$newcsv = {} | Select "DHCP_Server", "ScopeID","Scope_Name","Scope_SubnetMask","Scope_StartRange","Scope_EndRange","Scope_LeaseDuration","Scope_Option","Scope_Option_Name","Scope_Option_Value" | Export-Csv $Outputfile -NoTypeInformation
$Report = Import-Csv $Outputfile

# Going through the DHCP servers that were returned one at a time to pull statistics
Foreach ($DHCP_Server in $DHCP_Servers)
{ 
    # Getting all the dhcp scopes on a server
	$DHCP_Scopes = Get-DhcpServerv4Scope –ComputerName $DHCP_Server 
    
	# Going through the scopes on a DHCP Server and getting the Scope Options
	Foreach ($DHCP_Scope in $DHCP_Scopes)
	{ 
        #Get Scope Option Values
		$DHCP_Scope_Options=Get-DHCPServerv4OptionValue -ComputerName $DHCP_Server -ScopeId $DHCP_Scope.ScopeId -OptionID $dhcpoptionids
		
		$Report.DHCP_Server = $DHCP_Server
		$Report.ScopeID = $DHCP_Scope.ScopeID
		$Report.Scope_Name = $DHCP_Scope.Name
		$Report.Scope_SubnetMask = $DHCP_Scope.SubnetMask
		$Report.Scope_StartRange = $DHCP_Scope.StartRange
		$Report.Scope_EndRange = $DHCP_Scope.EndRange
		$Report.Scope_LeaseDuration = $DHCP_Scope.LeaseDuration
		$Report.Scope_Option = $DHCP_Scope_Options.OptionId -join ';'
		$Report.Scope_Option_Name = $DHCP_Scope_Options.Name -join ';'
		$Report.Scope_Option_Value = $DHCP_Scope_Options.Value -join ';'
	
		#Export Data to CSV
		$Report | Export-Csv $Outputfile -Append -NoTypeInformation
		
	}
		
	
	
		
}


