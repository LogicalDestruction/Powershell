<#
.SYNOPSIS
    Script for "Veeam for Microsoft 365" to try and Generate a summary report of errors or warnings from all Veeam Jobs.
    You can highlight Keywords you might be interested in.  For a period of time I was working with Support on immutable errors so you see those in the script below as an example.
	
	There is also a loop in the Script
	    foreach ($log in $logEntries) {
        if ()
		In this loop we try to filter out some of the more noisy alerts that we might not care about.   However, you might want to remove this filter if you are looking for a specific error.  
		Just be aware its there.  In the example below I removed filters for immutable related errors.
		
	Another good use case for this script is looking for falures related to virus alerts set to Veeam by Microsoft's API.  I commented out a keyword highlight below.  
	You would have to adjust the script to make this work.
		
.NOTES
    Name: Change_Target_Repo.ps1
    Author: Robert Stacks
    DateCreated: 05-14-2025
    URL: 
#>

############ User Variables #############

# List of keywords to highlight (case-insensitive)
# Can be one or many use ,"searchpattern", "searchpattern"
$highlightKeywords = @("immutable", "immutability ") 
#$highlightKeywords = @("Item may have a virus reported by the virus scanner plug-in")

############## Script ###################

# Escape and combine into a single regex pattern
$escapedPattern = ($highlightKeywords | ForEach-Object { [Regex]::Escape($_) }) -join "|"
$highlightRegex = "(?i)$escapedPattern"


# HTML style for highlighted keyword
$highlightStyle = '<span style="color:red; font-weight:bold;">$&</span>'

$lastNight = (Get-Date).AddDays(-1).Date
$today = (Get-Date).Date

# Get all job sessions that ran last night with errors or warnings
# Filter for last night
# Group by session by JobName
# Sort each group by CreationTime
# Take only the first (earliest) Session from each group
$lastNightSessions = Get-VBOJobSession |
    Where-Object {
        $_.CreationTime -ge $lastNight -and
        $_.CreationTime -lt (Get-Date).Date -and
        $_.Status -ne 'Success'
    } |
    Group-Object JobName |
    ForEach-Object {
        $_.Group | Sort-Object CreationTime | Select-Object -First 1
    }


# Initialize the HTML content array
$htmlSections = @()

# Filter and format logs per job session
foreach ($session in $lastNightSessions) {
    $jobName = $session.JobName
    $logEntries = $session.Log

    $jobLogLines = @()

    foreach ($log in $logEntries) {
        if (
			$log.title -match 'error|warning' -and
			$log.title -notmatch 'OneDrive was not found' -and 
			$log.title -notmatch 'does not have a valid Microsoft 365 license' -and 
			$log.title -notmatch 'Item may have a virus reported by the virus scanner plug-in' -and
			#$log.title -notmatch 'Blob Immutability' -and
			#$log.title -notmatch 'Cannot apply immutability' -and
			$log.title -notmatch 'Unable to send email notification' -and
			$log.title -notmatch 'Nothing to process' -and
			$log.title -notmatch 'Your license limit' -and
			$log.title -notmatch 'Exchange account was not found' -and
			$log.title -notmatch 'Personal site was not found' -and
			$log.title -notmatch 'Item has been changed during the backup' -and
			$log.title -notmatch 'A task was canceled' -and
			$log.title -notmatch 'objects failed' -and
			$log.title -notmatch 'Unable to read data from the transport connection' -and
			$log.title -notmatch 'Failed to load web fields' -and
			$log.title -notmatch 'Job failed at' -and
			$log.title -notmatch 'Job finished.*at'
		   )
		   {	
			# Combine and sanitize
			$rawLine = "{0} {1}" -f $log.title, $log.description

			# Escape HTML characters
			$escapedLine = [System.Web.HttpUtility]::HtmlEncode($rawLine)

			# Highlight all keywords in one pass
			$highlightStyle = '<span style="color:red; font-weight:bold;">$&</span>'
			$highlightedLine = $escapedLine -replace $highlightRegex, $highlightStyle

			# Add to output
			$jobLogLines += $highlightedLine
		   }
    }

    if ($jobLogLines.Count -gt 0) {
        # Add only jobs with filtered log lines
        $htmlBlock = "<b>$jobName</b><br>" + ($jobLogLines -join "<br>") + "<br><br>"
        $htmlSections += $htmlBlock
    }
}

# Only write to file if there is relevant content
if ($htmlSections.Count -gt 0) {
    $htmlContent = $htmlSections -join "`n"
    $timestamp = (Get-Date).ToString("MM-dd-yy-HHmmss")
    $Filename = "Errors_$timestamp.html"
    $htmlFilePath = "C:\scripts\Veeam\Report\$Filename"

    $htmlContent | Set-Content -Path $htmlFilePath -Encoding UTF8
    Write-Host "Report saved to $htmlFilePath"
} else {
    Write-Host "No relevant warnings or errors found. No report generated."
}
