# PowerShell AI Coding Standards v0.01

## Document Note
This is a document intended to refine code written by OpenAI\ChatGPt specifically so it is more traditional System Admin like and not dev ops either. 
This is a test \ draft \ experiment

## Purpose
This document defines the preferred PowerShell style for scripts written for system administration, infrastructure operations, reporting, verification, and remediation tasks.
The goal is to produce PowerShell that is practical, readable, easy to troubleshoot, and easy for a systems administrator to manually update later.
These standards favor maintainability and operational clarity over compactness, cleverness, or software-developer-style abstraction.

## Primary Style Goal
Write PowerShell for a systems administrator, not for a software developer.

Scripts should be:

* Easy to read
* Easy to modify
* Easy to troubleshoot
* Safe to run in production
* Clear about what they are doing
* Practical for day-to-day infrastructure work

Avoid writing code that is technically impressive but difficult for an administrator to follow later.

## General Rules

* Prefer simple, readable code over compact or clever code.
* Avoid unnecessary abstraction.
* Avoid over-engineering.
* Avoid deeply nested logic when simpler step-by-step logic would work.
* Avoid building frameworks unless specifically requested.
* Avoid creating many small helper functions unless they improve readability.
* Use clear variable names.
* Use full cmdlet names instead of aliases.
* Use named parameters.
* Use comments to explain intent, not every obvious line.
* Prefer code that can be copied, reviewed, and modified by a sysadmin.

## Script Structure

Use this general structure for full scripts:
1. Comment-based help
2. User-configurable variables or defaults
3. Setup section
4. Helper functions, if needed
5. Main logic
6. Output/reporting
7. Summary
8. Cleanup/disconnect

Example section headers:

```powershell
#------------------------------------------------------------
# User Configurable Variables
#------------------------------------------------------------

#------------------------------------------------------------
# Setup
#------------------------------------------------------------

#------------------------------------------------------------
# Main Logic
#------------------------------------------------------------

#------------------------------------------------------------
# Summary
#------------------------------------------------------------

#------------------------------------------------------------
# Cleanup
#------------------------------------------------------------
```
## Comment-Based Help

Full scripts should include comment-based help at the top.

Use this basic format:

```powershell
<#
.SYNOPSIS
Short description of what the script does.

.DESCRIPTION
Longer explanation of the script purpose and what systems it touches.

.PARAMETER ExampleParameter
Describe the parameter.

.EXAMPLE
.\Example-Script.ps1 -ServerName server01

.NOTES
Created: yyyy-mm-dd
Updated: yyyy-mm-dd
Update: Describe what changed ie
v01 - change 1
v02 - change 2 
#>
```
Comment-based help does not need to be excessive. Keep it useful.

## Variables

Use clear variable names but also avoid using Environment Variables, Automatic Variables, and Preference Variables unless they are being updated by the script.

Prefer:

```powershell
$VCenterServer
$OutputPath
$Credential
$FailedServers
```

Avoid:

```powershell
$vc
$out
$cred1
$x
```

Short variable names are acceptable only in very small, obvious loops.

## Formatting

Use readable formatting.

Prefer this:

```powershell
$vmHosts = Get-VMHost -Server $vCenterServer | Sort-Object -Property Name
```
Avoid dense one-liners for operational scripts.

Use splatting when a command has several parameters.

Example:

```powershell
$connectParams = @{
    Server      = $VCenterServer
    Credential  = $Credential
    ErrorAction = 'Stop'
}

Connect-VIServer @connectParams
```

## Cmdlets and Aliases

Use full cmdlet names.

Prefer:

```powershell
Get-ChildItem
Where-Object
ForEach-Object
Select-Object
```

Avoid aliases in scripts:

```powershell
gci
where
%
select
```

Aliases are acceptable at an interactive prompt, but not in reusable scripts.

## Output

Prefer structured output first, then formatting later.

Use `[PSCustomObject]` for result data.

Example:

```powershell
[PSCustomObject]@{
    ServerName = $ServerName
    Status     = 'Pass'
    Detail     = 'Service is running'
}
```

Avoid making the only useful output `Write-Host`.

`Write-Host` may be used for human-readable progress messages, headings, warnings, or summaries, but important results should be stored in objects when practical.

## Reports

For CSV reports, use `Export-Csv`.

Prefer:

```powershell
$results | Export-Csv -Path $OutputPath -NoTypeInformation
```

Avoid manually building CSV text unless there is a specific reason.

For HTML reports, build the data as objects first, then convert or format it.

For plain text reports, use `Set-Content` and `Add-Content`.

Avoid using `>>` for larger scripts unless it is a quick one-off.

## Error Handling

Use `try/catch/finally` around external systems, remote calls, authentication, or anything likely to fail.

Examples include:

* vCenter connections
* Veeam server connections
* WSUS connections
* Active Directory queries
* Remote PowerShell sessions
* File writes
* REST API calls

Example:

```powershell
try {
    Connect-VIServer -Server $VCenterServer -Credential $Credential -ErrorAction Stop
}
catch {
    Write-Error "Failed to connect to vCenter server $VCenterServer. $($_.Exception.Message)"
}
finally {
    Disconnect-VIServer -Server $VCenterServer -Confirm:$false -ErrorAction SilentlyContinue
}
```

Use `-ErrorAction Stop` when you need a terminating error for `try/catch`.

## Logging
For Logging, console output will be enough for testing something when it breaks.

Error handling will happen in the reports as requested.

No need for Excessive Transcript logging unless asked for specifically.

Avoid excessive logging that makes the output hard to read.

## Progress and Console Messages

Console output should help the operator understand what the script is doing.

Good examples:

```powershell
Write-Host "Connecting to vCenter: $VCenterServer"
Write-Host "Collecting VMHost inventory..."
Write-Host "Exporting report to $OutputPath"
```

Avoid misleading progress messages.

If the script is testing a port, say that.
If the script is collecting inventory, say that.
If the script is applying a change, say that clearly.

## Options: Initalize, Verify, and Remediation
Unless asked don't include Verification and Remediation.

If asked to include: 
Verification and remediation should be clearly separated.

Use modes such as:

```powershell
[ValidateSet('Verify','Remediate')]
[string]$Mode = 'Verify'
```

Scripts should default to verification when practical.

Destructive or production-changing actions must require confirmation, support `-WhatIf`, or both.

Examples of production-changing actions:

* Restarting services
* Rebooting servers
* Changing DNS records
* Modifying Active Directory users or groups
* Creating or deleting VMs
* Changing ESXi host configuration
* Removing snapshots
* Deleting files
* Changing firewall rules

When remediation is included, show what will be changed before changing it.

Order of operations is important and should be maintained.  

 * If Initalize order sets NTP, then Joins domain, then sets permissions. 
 * Verify and Remediate should also follow the same pattern.
 * If asked to change the order of Initalize \ Verify \ Remediate suggestion doing the same for the others sections.

## Credentials

Prompt for credentials when needed.

Do not hardcode passwords, tokens, API keys, or secrets.  Unless asked to do so for a specific use case.

Do not store secrets in scripts.

Use secure credential storage only when specifically required and documented.

Example:

```powershell
$Credential = Get-Credential -Message 'Enter credentials'
```

Alterantively we might use creds saved in a pwfile
```powershell
$usernamee = "domain\username"
$pwfile = "c:\pathtofile.txt"
```

## Configuration

Avoid hardcoding environment-specific values throughout the script.

Prefer a clear user-configurable section near the top, or use parameters.

Acceptable for simple scripts:

```powershell
$VCenterServers = @(
    'vcenter01.domain.com',
    'vcenter02.domain.com'
)

$OutputPath = 'C:\Reports\Inventory.csv'
```

Better for reusable scripts:

```powershell
param(
    [string[]]$VCenterServers,
    [string]$OutputPath
)
```

## Functions

Use functions when they make the script easier to read or reduce repeated logic that exceds reuse more than 2 times. (rare)

Do not create functions just for the sake of creating functions.

Avoid turning simple scripts into complex modules unless specifically requested.

A function should have a clear purpose.

Avoid excessive function nesting or overly generic helper functions that make the script harder to follow.

## Data Flow

Prefer this general pattern:

```text
Collect data
Store data as objects
Analyze/filter data
Display summary
Export report
```

Avoid mixing collection, formatting, and export logic all in the same line when it makes the script harder to maintain.

## External Modules

When a script requires a module, state it clearly near the top.

Example:

```powershell
# Requires VMware PowerCLI
Import-Module VMware.PowerCLI -ErrorAction Stop
```

If the module may not be installed, check for it and show a useful error.

Example:

```powershell
if (-not (Get-Module -ListAvailable -Name VMware.PowerCLI)) {
    throw 'VMware PowerCLI is not installed. Install it before running this script.'
}
```

## PowerShell Version

Write for Windows PowerShell 5.1 unless PowerShell 7 is specifically requested.

If PowerShell 7 is required, state that clearly in the script notes.

Be careful with syntax or cmdlets that only work in PowerShell 7.

## Compatibility

For enterprise Windows environments, assume scripts may run on:

* Windows Server
* Admin workstations
* Scheduled task hosts
* Jump boxes

Avoid unnecessary dependencies.

Avoid using features that make a script harder to run in a locked-down environment unless they are required.

## Risky Patterns to Avoid

Avoid these patterns unless specifically requested:

```powershell
Invoke-Expression
iex
```

Avoid downloading and executing remote code.

Avoid destructive one-liners.

Avoid overly broad changes such as:

```powershell
Get-ADUser -Filter * | Disable-ADAccount
```

Avoid silently continuing after important failures.

Avoid hiding errors that the operator needs to see.

## Preferred Script Behavior

A good operational script should generally:

* Say what it is about to do
* Connect to required systems
* Collect data
* Show useful progress
* Produce structured results
* Show a readable summary
* Export results if requested
* Disconnect or clean up sessions
* Clearly report failures

## Summary Format

Where practical, include a simple summary.

Example:

```powershell
Write-Host ''
Write-Host '============================================================'
Write-Host 'Summary'
Write-Host '============================================================'
Write-Host "Total Checked : $($results.Count)"
Write-Host "Passed        : $($results | Where-Object { $_.Status -eq 'Pass' } | Measure-Object | Select-Object -ExpandProperty Count)"
Write-Host "Failed        : $($results | Where-Object { $_.Status -eq 'Fail' } | Measure-Object | Select-Object -ExpandProperty Count)"
```

For larger scripts, store pass/fail counts in variables before displaying them.

## AI Code Generation Guidance

When generating PowerShell from this standard:

* Keep the script readable.
* Do not over-engineer the solution.
* Do not create a large framework unless requested.
* Avoid software-developer-style patterns when simple admin scripting is enough.
* Prefer straightforward logic that can be manually edited later.
* Use functions only where they improve readability.
* Use objects for important results.
* Include safety checks for production-changing actions.
* Assume the reader is an experienced systems administrator, not a full-time software developer.
* When unsure, choose the simpler implementation.
