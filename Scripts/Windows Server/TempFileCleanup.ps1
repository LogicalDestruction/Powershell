<################################################################################################
.SYNOPSIS
    A very simple script to clean up temp files
.Description
    This script cleans up a typical temp directories found on a Windows Server
    C:\Windows\Temp\*
    C:\Windows\Prefetch\*
    C:\Users\*\Appdata\Local\Temp\*
    C:\Users\*\AppData\Roaming\Microsoft\Windows\Recent Items\*

    Can be used once manually or added to a task schedule job to run as often as needed.

    Also note it doesn't check to see if a file is in use, if it is, Windows will not delete it.
.NOTES
    Author: Robert Stacks
    Date: 7/13/2023
    Last Update: 7/13/2023
################################################################################################>

$tempfolders = @("C:\Windows\Temp\*", "C:\Windows\Prefetch\*", "C:\Users\*\Appdata\Local\Temp\*","C:\Users\*\AppData\Roaming\Microsoft\Windows\Recent Items\*")

Get-ChildItem -File -Recurse -ErrorAction SilentlyContinue -Path $tempfolders | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-10))} | Remove-Item -force -Recurse

