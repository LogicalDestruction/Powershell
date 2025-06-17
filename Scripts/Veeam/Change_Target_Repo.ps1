<#
.SYNOPSIS
    Script for "Veeam for Microsoft 365" to retarget a large number of backup jobs using a specific source repositiory to another one.
	I had to do this for a support call to fix a broken repository.

.NOTES
    Name: Change_Target_Repo.ps1
    Author: Robert Stacks
    DateCreated: 05-14-2025
    URL: 
#>

##### Variables you need to set #####
# Set source and target repository names
$sourceRepoName = "sourceRepoName"
$targetRepoName = "targetRepoName"

# Load the Veeam Backup for Microsoft 365 PowerShell module 
Add-PSSnapin Veeam.Archiver.PowerShell -ErrorAction SilentlyContinue

# Get the target repository object
$targetRepo = Get-VBORepository | Where-Object { $_.Name -eq $targetRepoName }
if (-not $targetRepo) {
    Write-Error "Target repository '$targetRepoName' not found!"
    return
}

# Get all backup jobs using the source repository
$jobsToUpdate = Get-VBOJob | Where-Object { $_.Repository.Name -eq $sourceRepoName }

# If no jobs found, exit
if (-not $jobsToUpdate) {
    Write-Output "No jobs found using repository '$sourceRepoName'."
    return
}

# Loop through and update each job
foreach ($job in $jobsToUpdate) {
    Write-Output "Updating job: $($job.Name)"

    # Update the repository
    Set-VBOJob -Job $job -Repository $targetRepo

    Write-Output " -> Repository updated to '$($targetRepo.Name)'"
}

Write-Output "Completed updating repositories for applicable jobs."
