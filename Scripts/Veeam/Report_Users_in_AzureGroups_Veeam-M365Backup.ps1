# Install and import the Microsoft Graph module if not installed
if (-not (Get-Module -Name Microsoft.Graph -ListAvailable)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph

# Connect to Microsoft Graph with necessary permissions
Connect-MgGraph -Scopes "Group.Read.All", "User.Read.All"

# Get all groups and filter in PowerShell
$AllGroups = Get-MgGroup -All
$FilteredGroups = $AllGroups | Where-Object { $_.DisplayName -match "-Veeam-M365Backup$" }

# Initialize an array to store user details
$UserList = @()

# Loop through each group and retrieve members
foreach ($Group in $FilteredGroups) {
    $GroupMembers = Get-MgGroupMember -GroupId $Group.Id -All | ForEach-Object {
        Get-MgUser -UserId $_.Id | Select-Object GivenName, Surname, UserPrincipalName
    }

    # Add members to list
    $UserList += $GroupMembers
}

# Remove duplicates and sort by first name
# $UserList = $UserList | Sort-Object GivenName -Unique

# Export to CSV
$CsvPath = "$env:USERPROFILE\Desktop\VeeamBackupUsers.csv"
$UserList | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8

Write-Host "CSV exported to: $CsvPath"
