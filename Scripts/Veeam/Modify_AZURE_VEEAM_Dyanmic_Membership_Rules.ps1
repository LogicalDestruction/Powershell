<#
.SYNOPSIS
    Script that looks for Groups that end with -VEEAM-M365Backups
	 -West Fraser has a standard to label the groups used by VEEAM with TLA-VEEAM-M365Backups
	 -These groups are tied to site specific backup jobs in VEEAM M365
	Grabs the 1st three characters of the group name dynamically
	Replaces the entire membership rule with a standardized rule for consistancy
	Ensures user.physicalDeliveryOfficename matches the location prefix
	 - This ensures the Veeam backup jobs tied to these groups only backups the users at that physical location
	Tries to handle errors gracefully and stops the script from running if you don't have permissions or haven't activated your PIM role

.NOTES
    Name: Modify_AZURE_VEEAM_Dynamic_Membership_Rules.ps1
    Author: Robert Stacks
    DateCreated: 03-07-25
#>
############ User Variables #############

# Define the search pattern for group names
$SearchPattern = "*-VEEAM-M365Backup"

# Define the new Dynamic Membership Rule
# Note: (user.physicalDeliveryOfficeName -eq "$LocationCode") must be the 1st line and $LocationCode will be defined in the loop in the script below.
#       If you need to update the rules modify the rules after this statement.
$NewRuleTemplate = @"
(user.physicalDeliveryOfficeName -eq "{0}")
-and (user.displayName -notmatch "Template") 
-and (user.mail -notContains "Template")
-and (user.displayName -notmatch "Test")
-and (user.mail -notContains "Test")
-and (user.mail -notContains "Meeting")
-and (user.mail -notContains "Phone")
-and (user.mail -notContains "ScaleWiz")
-and (user.mail -notContains "floor")
-and (user.mail -notContains "migration")
-and (user.mail -notContains "Phone")
-and (user.proxyAddresses -any (_ -startsWith "SMTP:"))
-and (user.accountEnabled -eq true)
-and (user.userType -ne "Guest") 
-and (user.mailNickName -notmatch "Room") 
-and (user.displayName -notmatch "Vehicle") 
-and (user.mailNickName -notmatch "Resource") 
-and (user.jobTitle -notmatch "Room") 
-and (user.department -notmatch "Conference")
"@

############## Script ###################
# Install and import Microsoft Graph module if not already installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Groups)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}
Write-Host "Importing Microsoft.Graph"
#Import-Module Microsoft.Graph

# Connect to Microsoft Graph (Ensure you have the required permissions maybe...) 
Write-Host "Checking Permissions"
try {
    Connect-MgGraph -Scopes "Group.ReadWrite.All" -ErrorAction Stop
} catch {
    Write-Host "ERROR: Failed to connect to Microsoft Graph. Exiting script. Check your permissions or Activate Role in PIM" -ForegroundColor Red
    exit
}

# Get all groups, filter by name containing "-VEEAM-M365Backup", and sort by DisplayName
$Groups = Get-MgGroup -All | Where-Object { $_.DisplayName -like $SearchPattern } | Sort-Object DisplayName

if ($Groups) {
    foreach ($Group in $Groups) {
        Write-Host "Processing Group: $($Group.DisplayName)"

        # Extract the first three letters as the location code
        $LocationCode = $Group.DisplayName.Substring(0, 3)
		
		$NewRule = $NewRuleTemplate -f $LocationCode

        # Update the group's membership rule (overwriting existing rule)
		# Note: $NewRule is defined in User Variables
        Update-MgGroup -GroupId $Group.Id -MembershipRule $NewRule -MembershipRuleProcessingState "On"

        Write-Host "Updated Group: $($Group.DisplayName) with rule for $LocationCode"
    }
} else {
    Write-Host "No groups found containing '$SearchPattern' in their name."
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph
