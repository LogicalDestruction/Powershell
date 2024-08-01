    <#
    .SYNOPSIS
        Script that will gather the sizes of directories akin to a TreeSize Graphical report.  Its primary purpose is to help Admins find areas of the disk that
        are being consumed by large files or a large group of files that consume a large amount of space.  Examples of this would be log files that are not 
        getting flushed or large files like ISOs or backups.  

    .NOTES
        Name: Get-DirectoryTreeSize
        Author: Robert Stacks
        Version: 0.11
        DateCreated: 7-23-2024
        DateModified: 7-30-2024
    
    .PARAMETER Path
        The path Parameter will default to the current path or else accept the path as the input with or without the -Path parameter.

    .PARAMETER Sortby
        Using this parameter the function will sort the returned results by Type(Directory and File Name.  Directories will come first), MB, or GB.  Default is by MB if not selected
    
    .PARAMETER Ascending
        This is the reverse of the standard Sortby option which is in Descending order.  Might be useful in some situations.
    
    .EXAMPLE
        
    #>

    # Function to write headers with specific formatting used in the main function
    function Write-Header {
        param (
            [string]$HeaderText,
            [ConsoleColor]$Color
        )
        Write-Host ""
        Write-Host ("======================= {0} =======================" -f $HeaderText) -ForegroundColor $Color
        Write-Host ""
    } #End function Write-Header

    # FUnction to determine the best Unit Size to display
    function Get-CalculateUnit {
        param (
            [Parameter(Position = 0,Mandatory=$true)]
            [long]$TotalSizeBytes
        )
    
        if ($TotalSizeBytes -lt 1MB) {
            $size = "{0,15:N1} KB" -f ($TotalSizeBytes / 1KB)
        }
        elseif ($TotalSizeBytes -lt 1GB) {
            $size = "{0,15:N1} MB" -f ($TotalSizeBytes / 1MB)
        }
        else {
            $size = "{0,15:N1} GB" -f ($TotalSizeBytes / 1GB)
        }
    
        return $size
    }

    # Function to create formatted output table
function Format-OutputTable {
    param (
        [Parameter(Position = 0, Mandatory = $false)]
        [array]$OutputList,

        [Parameter(Position = 2, Mandatory = $false)]
        [Long]$AllItemsSize
    )

    # Determine the maximum lengths of each column
    $maxTypeLength = ($OutputList | Measure-Object -Property Type -Maximum).Maximum.Length
    $maxNameLength = ($OutputList | Measure-Object -Property Name -Maximum).Maximum.Length
    $maxSizeLength = ($OutputList | Measure-Object -Property Size -Maximum).Maximum.Length
    $maxLastModifiedLength = ($OutputList | Measure-Object -Property LastModified -Maximum).Maximum.Length
    

    # Set minimum widths
    $typeWidth = [math]::Max($maxTypeLength, 10)
    $nameWidth = [math]::Max($maxNameLength, 50)
    $sizeWidth = [math]::Max($maxSizeLength, 20)
    $lastModifiedWidth = [math]::Max($maxLastModifiedLength, 10)
    $PercentOfParentWidth = 10

    # Function to truncate strings that exceed the maximum width
    function Get-TruncateString {
        param (
            [string]$String,
            [int]$MaxLength
        )
        if ($String.Length -gt $MaxLength) {
            return $String.Substring(0, $MaxLength - 3) + "..."
        }
        return $String
    }

    # Print headers
    Write-Host ("{0,-$typeWidth} {1,-$nameWidth} {2,$sizeWidth} {3,-$lastModifiedWidth} {4,$PercentOfParentWidth}" -f "Type", "Name", "Size", "LastModified", "% of Parent") -ForegroundColor Green
    Write-Host ("{0,-$typeWidth} {1,-$nameWidth} {2,$sizeWidth} {3,-$lastModifiedWidth} {4,$PercentOfParentWidth}" -f "----", "----", "----", "------------", "-----------") -ForegroundColor Green

    
    foreach ($item in $OutputList) {
        #Truncate Names if needed
        $truncatedName = Get-TruncateString -String $item.Name -MaxLength $nameWidth
        
        #Convert the Item.Size which is stored as a number with a bit of text KB,MB,GB back into Bytes to do some math.
        if($item.size -like "*KB"){
            $SizeofItem = (([double]($item.size -replace '[^\d\.]',''))* 1kb)
        }
        elseif($item.size -like "*MB"){
            $SizeofItem = (([double]($item.size -replace '[^\d\.]',''))*1MB)
        }
        elseif($item.size -like "*GB"){
            $SizeofItem = (([double]($item.size -replace '[^\d\.]',''))*1GB)
        }
        
        #Figure out the PercentOfParent space wise a item is consuming and return it as a Percentage.
                   
        $PercentOfParent = if ($AllItemsSize -ne 0) {"{0,10:N1}%" -f (($SizeofItem/$AllItemsSize)*100)} else {
            "0.0%"
        }
 
        # Print each item and include % of Parent
        Write-Host ("{0,-$typeWidth} {1,-$nameWidth} {2,$sizeWidth} {3,-$lastModifiedWidth} {4,$PercentOfParentWidth}" -f $item.Type, $truncatedName, $item.Size, $item.LastModified, $PercentofParent)
    }

}
    
    # Main Function
    function Get-DirectoryTreeSize {
        [CmdletBinding()]
        param(
            [Parameter(Position = 0, Mandatory=$false)]
            [string] $Path =((Get-Location).path),
        
            [ValidateSet("Alpha", "Size")]
            [string] $SortBy = "Size",

            [switch] $Files,
            
            [switch] $Headers
        )
    
        BEGIN {
            # Adding a trailing slash at the end of $Path to make it consistent.
            if (-not $Path.EndsWith('\')) {
                $Path = "$Path\"
            } #End If

            #Initialize Variables 
            $AllItemsSize = 0
            $SumAllFilesSizes = 0
            $TotalPathSize = New-Object System.Collections.Generic.List[PSObject]
            $DirectoryList = New-Object System.Collections.Generic.List[PSObject]
            $FileList = New-Object System.Collections.Generic.List[PSObject]
            $FileSumList = New-Object System.Collections.Generic.List[PSObject]
            $ErrorList = New-Object System.Collections.Generic.List[PSObject]
            
        } #End Begin
    
        PROCESS {
            try {
                # Get all items(directories and files) in the specified $Path
                $items = Get-ChildItem -Path $Path -ErrorVariable Errors -ErrorAction SilentlyContinue -Force

                foreach ($item in $items) {
                    try {
                        if ($item.PSIsContainer) {
                            # Calculate total size of files in the directory
                            $TotalSizeBytes = (Get-ChildItem -Path $item.FullName -File -Recurse -Force -ErrorAction SilentlyContinue| Measure-Object -Property Length -Sum).Sum
                            $size = Get-CalculateUnit $TotalSizeBytes
                                                
                            # Format output in columns for directories
                            $outputObject = [pscustomobject]@{
                                Type = "Directory"
                                Name = $item.Name
                                Size = $size
                                LastModified =$item.LastWriteTime.ToString("yyyy-MM-dd")
                                
                            } #End OutputObject
                            $AllItemsSize+=$TotalSizeBytes
                            $DirectoryList.Add($outputObject)
                        } # End If
                        else {
                            # Calculate the size of the file
                            $FileSizeBytes = $item.Length
                            $size = Get-CalculateUnit $FileSizeBytes
                            
                            $outputObject = [pscustomobject]@{
                                Type = "File"
                                Name = $item.Name
                                Size = $size
                                LastModified =$item.LastWriteTime.ToString("yyyy-MM-dd")
                                
                            } # End Else
                            $AllItemsSize+=$FileSizeBytes
                            $SumAllFilesSizes+=$FileSizeBytes
                            $FileList.Add($outputObject)
                        } #End Else
                    } catch {
                        # Capture errors while processing items
                        $ErrorList.Add($_)
                    } # End Catch
                } # end foreach
            } catch {
                # Capture any errors from Get-ChildItem
                $ErrorList.Add($_)
            } # End catch
    
            # Capture permission errors from Get-ChildItem
            foreach ($error in $Errors) {
                $ErrorList.Add($error)
            } #End foreach
        } # End Process
    
        END {
            # Determine the total Size of the Path passed to the funciton
            $Pathsize = Get-CalculateUnit $AllItemsSize

            #Create a Object to contain the final Path details to put at the top of the Output later
            $outputObject = [pscustomobject]@{
                Type = "Path"
                Name = $Path
                Size = $PathSize
                LastModified =(Get-Item $Path).LastWriteTime.ToString("yyyy-MM-dd")

            } #End outputObject
            $TotalPathSize.add($outputObject)

            # Determine the SumAllFilesSizes a unit size based on size
            $Size = Get-CalculateUnit $SumAllFilesSizes
            
            #Create a object for the Sum of all Files to display.
            $outputObject = [pscustomobject]@{
                Type = "Files"
                Name = "[ " + $FileList.Count + " Files]"
                Size = $Size
                LastModified = (Get-Date).ToString("yyyy-MM-dd")
        
            } #End outputObject
            $FileSumList.add($outputObject)

            # Sort the Lists based on SortBy Parameter, default is by Size / Descending
            if ($SortBy -eq "Size"){
                $DirectoryList = $DirectoryList | Sort-Object { 
                    if ($_.Size -like "*KB") { [double]($_.Size -replace '[^\d\.]', '') }
                    elseif ($_.Size -like "*MB") { [double]($_.Size -replace '[^\d\.]', '') * 1024 }
                    else { [double]($_.Size -replace '[^\d\.]', '') * 1024 * 1024 }
                } -Descending
                $FileList = $FileList | Sort-Object { 
                    if ($_.Size -like "*KB") { [double]($_.Size -replace '[^\d\.]', '') }
                    elseif ($_.Size -like "*MB") { [double]($_.Size -replace '[^\d\.]', '') * 1024 }
                    else { [double]($_.Size -replace '[^\d\.]', '') * 1024 * 1024 }
                } -Descending
            } elseif ($SortBy -eq "Alpha") {
                $DirectoryList = $DirectoryList | Sort-Object Type, Name
                $FileList = $FileList | Sort-Object Type, Name
            } #End if SortBy -eq "Size"
    
            if ($Headers) {
                Write-Header "Path" -Color Green
                Format-OutputTable $TotalPathSize $AllItemsSize

                Write-Header "Directories" -Color Green
                if ($DirectoryList.Count -gt 0) {
                    Format-OutputTable $DirectoryList $AllItemsSize
                } #end if
                else {
                    Write-Host "No directories found." -ForegroundColor Yellow
                } #end else
    
                Write-Header "Files" -Color Green
                if ($Files){
                    if ($FileList.Count -gt 0) {
                        Format-OutputTable $FileList $AllItemsSize
                    } #end if
                    else {
                        Write-Host "No files found." -ForegroundColor Yellow
                    } #end else
                }
                else {
                    Format-OutputTable $FileSumList $AllItemsSize
                }
                
                if ($ErrorList.Count -gt 0) {
                    Write-Header "Errors" -Color Red
                    # Select only the ErrorRecord property from each error
                    $ErrorList | ForEach-Object {
                        [pscustomobject]@{
                            ErrorRecord = $_.Exception.Message
                        } #end pscustomobject
                    } | Format-Table -AutoSize
                } #end if
            } #end if
            else {
                if ($Files){
                #Output with Files if Parameter is used.
                $outputList = $TotalPathSize + $DirectoryList + $FileList
                Format-OutputTable $outputList $AllItemsSize
                }
                else {
                # Output with a Sum entry for files by default
                $outputList = $TotalPathSize + $DirectoryList + $FileSumList
                Format-OutputTable $outputList $AllItemsSize
                }
                # Output errors last
                if ($ErrorList.Count -gt 0) {
                    Write-Output "Errors encountered:"
                    $ErrorList | ForEach-Object {
                        [pscustomobject]@{
                            ErrorRecord = $_.Exception.Message
                        } #End pscustomobject
                    } | Format-Table -AutoSize
                } #End IF
            } #End Else
        } #End (Process) End{}
    } #End of function Get-DirectoryTreeSize {}

