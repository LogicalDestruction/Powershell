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
2. Param block
3. User-configurable variables or defaults
4. Setup section
5. Helper functions, if needed
6. Main logic
7. Output/reporting
8. Summary
9. Cleanup/disconnect

Example section headers:

```powershell
#------------------------------------------------------------
# Parameters
#------------------------------------------------------------

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

