###############################################################################################
# Author: Robert Stacks
# Date: 7/6/2023
#
# Last Updated by: Robert Stacks
# Last Update Date: 7/6/2023
#
# Purpose of Script: Get a list of Local AD users that have a experation date set in AD.  Check to see if those accounts are disabled in Azure.
#                    Note: AZure AD does not have an Experation attribute you only have the option to disable accounts.  This has been a open issues for more than six years in Azure.
#                    See: https://feedback.azure.com/d365community/idea/5d44d790-c525-ec11-b6e6-000d3a4f0789
#
# Note: Uses the newer Microsoft Graph Powershell module which works with rest api.  IE Connect-MgGraph or other Get-Mg* commands.
#       If you modified this code and see an error around Connect-MsGraph or Get-Ms* commands your using the older unsupported Powershell cmdlets.
#
# Note2: A great write up around this issue can be found here: https://www.undocumented-features.com/2023/01/25/working-around-accounts-that-expire-with-aad-connect/ 
#        and here https://www.undocumented-features.com/2017/09/15/use-aad-connect-to-disable-accounts-with-expired-on-premises-passwords/
#
# Update Notes: 
###############################################################################################

########################################## Variables ##########################################
#Variables in this section can be updated to match the needs of your local envrionment.
###############################################################################################

$AzureTenantID = ""
$AzureAPPID = ""
$CertThumb = ""

#Local Path, and File Name where we will drop off the data from this script. Default for testing is your desktop.
$OutputfileLocalPath = "C:~\Desktop"
$OutputfileName = "$($TodaysDate)-LocalADUserExperation_vs_Azure_AuditReportName.csv"

######################################## End Variables ########################################
######################### Basic Health Check for the Powershell Script ########################

#Test to see if MSGraph Module is installed if not install it.
if (Get-Module -ListAvailable -Name Microsoft.Graph){
    #Do nothing
}
else {
    install-module Microsoft.Graph
}

#Need to check if ActiveDirectory tools are installed and if not install them....
#Add-WindowsCapability -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0 -Online

####################################### End Health Check ######################################
######################################### Main Script #########################################

#Connect MSGraph to our Tenant ID
Connect-MgGraph -TenantId $AzureTenantID -AppID $AzureAPPID  -CertificateThumbprint $CertThumb

#Output the file to path\name variables set above
$Outputfile = $OutputfileLocalPath + $OutputfileName

#Create CSV file headers
$newcsv = {} | Select "User_Name", "User_PrincipalName", "User_Description", "User_AccountExpirationDate", "User_AzureAD_Enabled" | Export-Csv $Outputfile -NoTypeInformation
$AuditReport = Import-Csv $Outputfile

#Get a list of expired local AD accounts compare that to Azure AD accounts, then retrun a list of active Azure AD accounts where the local AD account has been expired.
#$LocalADUsers = Get-ADUser "lansfordj_ric" -properties AccountExpirationDate | Where-Object{$_.AccountExpirationDate -lt (Get-Date) -and $_.AccountExpirationDate -ne $null -and $_.Enabled -eq $True} | select-object Name, userPrincipalName, AccountExpirationDate 
$LocalADUsers = Get-ADUser -Filter * -properties Name, userPrincipalName, Description, AccountExpirationDate | Where-Object{$_.AccountExpirationDate -lt (Get-Date) -and $_.AccountExpirationDate -ne $null -and $_.Enabled -eq $True} 

#Compare each user from local AD user list against their Azure AD User and see if they are enabled. If so write their Name, UserPrincipalName, and AccountExpirationDate to a file for review.  Also get a count of users reviewed for reporting purposes.
Foreach ($User in $LocalADUsers){
 
    #Check the value AccountEnabled for each user to see if the user is enabled
    $test=Get-MGUser -userid $User.UserPrincipalName -Property AccountEnabled | foreach{$_.AccountEnabled}
    
    #Set values about the user to write to the report.
    $AuditReport.User_Name = $User.Name
    $AuditReport.User_PrincipalName = $User.userPrincipalName
    $AuditReport.User_Description = $User.Description
    $AuditReport.User_AccountExpirationDate = $User.AccountExpirationDate
    
    #If the user is enabled we will write the data to a file for reporting purposes else report its not enabled.
    If($test -eq $Null){
     $AuditReport.User_AzureAD_Enabled = "No Azure Account Present"
    } elseif($test){
     $AuditReport.User_AzureAD_Enabled = "Enabled"
    } else{
     $AuditReport.User_AzureAD_Enabled = "Disabled"
    }
    
    #Export Data to CSV
    $AuditReport | Export-Csv $Outputfile -Append -NoTypeInformation   
        
    
}

####################################### End Main Script #######################################
###############################################################################################