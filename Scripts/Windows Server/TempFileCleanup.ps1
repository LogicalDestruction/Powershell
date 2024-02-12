###############################################################################################
# Author: Robert Stacks
# Date: 7/13/2023
# Last Update Date: 7/13/2023
#
# Purpose of Script: 
#                    To clean up typical temp directories found on a Windows Server
#                    You might consider using task scheduler to run this once a month, 
#                    or once a day or whatever your needs may be.
###############################################################################################

$tempfolders = @("C:\Windows\Temp\*", "C:\Windows\Prefetch\*", "C:\Users\*\Appdata\Local\Temp\*","C:\Users\*\AppData\Roaming\Microsoft\Windows\Recent Items\*")

Get-ChildItem -File -Recurse -ErrorAction SilentlyContinue -Path $tempfolders | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-10))} | Remove-Item -force -Recurse
