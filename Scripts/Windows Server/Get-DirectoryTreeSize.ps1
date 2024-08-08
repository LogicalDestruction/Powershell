<#
.SYNOPSIS
    Script that will gather the sizes of directories akin to a TreeSize Graphical report.  Its primary purpose is to help Admins find areas of the disk that
    are being consumed by large files or a large group of files that consume a large amount of space.  Examples of this would be log files that are not 
    getting flushed or large files like ISOs or backups.  Size values are returned in KB, MB, or GB.

    It will color code Lines in color based on % of Parent
    The heading will be Green
    The Path will alway be Cyan
    Items above 75% will be Red
    Items above 50% will be darkyellow
    Items above 25% will be yellow
    Evething else will be White.

.NOTES
    Name: Get-DirectoryTreeSize
    Author: Robert Stacks
    Version: 1.11
    DateCreated: 07-23-2024
    Updated: 08-07-2024
    URL: https://github.com/LogicalDistruction/Powershell/blob/main/Scripts/Windows%20Server/Get-DirectoryTreeSize.ps1

.PARAMETER Path
    The -path Parameter will default to the current path or else accept the -path as the input.
    IE: C:\Get-DirectoryTreeSize -path C:\somedirectory will return directories in the C:\somedirectory path.  See the example output below.

.PARAMETER Files
    The -Files Parameter will expand the Files in the directory, by default they are combined into a single [Count Files] line with the Sum of their total Sizes
    IE: C:\Get-DirectoryTreeSize -path C:\somedirectory -File

.PARAMETER Sortby
    The -Sortby will accept Alpha or Size as parameters.  Default is to sort by Size but if you want to sort the output by Directory Name or 
    File Name you have that option.
    IE: C:\Get-DirectoryTreeSize -path C:\somedirectory -Sort Alpha

.PARAMETER SizeLimitGB
    The -SizeLimitGB Parameter will limit the items returned by the Size limit in GB specified.
    IE: C:\Get-DirectoryTreeSize -path C:\somedirectory -SizeLimitGB 10  # Would only return directories or files that are larger than 10GB.

.EXAMPLE
    C:\Get-DirectoryTreeSize -path C:\Users\username\Downloads

    Sample Output

    Type       Name                                               % of Parent       Size   LastModified
    ----       ----                                               -----------       ----   ------------
    Path       C:\Users\username\Downloads\                             100.0%   14.8 GB     2024-08-01
    Directory  ISOs                                                     75.0%    11.1 GB     2024-07-25
    Directory  DokuWikiStick                                             1.2%   175.1 MB     2024-07-19
    Directory  TestEmpty                                                 0.0%     0.0 KB     2024-07-30
    Files      [ 21 Files]                                              23.7%     3.5 GB     2024-08-01

#>

# Function to write headers with specific formatting used in the main function
function Write-Header
{
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
        [double]$TotalSizeBytes
    )

    if ($TotalSizeBytes -lt 1MB) {
        $size = "{0:N1} KB" -f ($TotalSizeBytes / 1KB)
    }
    elseif ($TotalSizeBytes -lt 1GB) {
        $size = "{0:N1} MB" -f ($TotalSizeBytes / 1MB)
    }
    else {
        $size = "{0:N1} GB" -f ($TotalSizeBytes / 1GB)
    }

    return $size
}

# Function to create formatted output table
function Format-OutputTable 
{
    param (
        [Parameter(Position = 0, Mandatory = $false)]
        [array]$OutputList,

        [Parameter(Position = 1, Mandatory = $false)]
        [double]$AllItemsSize,

        [Parameter(Position = 2, Mandatory = $false)]
        [double]$SizeLimitbyGB = 0
    )

    # Convert SizeLimitbyGB to bytes to test with
    $SizeLimitbyBytes = $SizeLimitbyGB * 1GB

    # Determine the maximum lengths of each column
    $maxTypeLength = ($OutputList | Measure-Object -Property Type -Maximum).Maximum.Length
    $maxNameLength = ($OutputList | Measure-Object -Property Name -Maximum).Maximum.Length
    $maxSizeLength = ($OutputList | Measure-Object -Property Size -Maximum).Maximum.Length
    $maxLastModifiedLength = ($OutputList | Measure-Object -Property LastModified -Maximum).Maximum.Length
    

    # Set minimum widths
    $typeWidth = [math]::Max($maxTypeLength, 10)
    $nameWidth = [math]::Max($maxNameLength, 50)
    $PercentOfParentWidth = 11
    $sizeWidth = [math]::Max($maxSizeLength, 10)
    $lastModifiedWidth = [math]::Max($maxLastModifiedLength, 14)

    # Width Count test
    # $TotalColumnWidth = $typeWidth + $nameWidth + $PercentOfParentWidth + $sizeWidth + $lastModifiedWidth
    
    
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

    # Function to get color based on percentage
    function Get-ColorByPercentage {
        param (
            [double]$Percentage
        )
        if ($Percentage -ge 75) 
        {
            return "Red"
        } 
        elseif ($Percentage -ge 50) 
        {
            return "darkyellow"
        } 
        elseif ($Percentage -ge 25) 
        {
            return "Yellow"
        } 
        else 
        {
            return "White"
        }
    }

    # Print headers
    Write-Host ("{0,-$typeWidth} {1,-$nameWidth} {2,$PercentOfParentWidth} {3,$sizeWidth} {4,$lastModifiedWidth}" -f "Type", "Name", "% of Parent", "Size", "LastModified") -ForegroundColor Green
    Write-Host ("{0,-$typeWidth} {1,-$nameWidth} {2,$PercentOfParentWidth} {3,$sizeWidth} {4,$lastModifiedWidth}" -f "----", "----", "-----------", "----", "------------") -ForegroundColor Green
    
    foreach ($item in $OutputList) {
        # Convert the Item.Size which is stored as a number with a bit of text KB,MB,GB back into Bytes to do some math.
        if($item.size -like "*KB"){
            $SizeofItem = (([double]($item.size -replace '[^\d\.]',''))* 1kb)
        }
        elseif($item.size -like "*MB"){
            $SizeofItem = (([double]($item.size -replace '[^\d\.]',''))* 1MB)
        }
        elseif($item.size -like "*GB"){
            $SizeofItem = (([double]($item.size -replace '[^\d\.]',''))* 1GB)
        }
        
        # Filter out Items smaller than the specified size limit passed to the -SizeLimitbyGB parameter
        if ($SizeofITem -ge $SizeLimitbyBytes -or $item.Type -eq "Path")
        {
        # Truncate Names if needed
        $truncatedName = Get-TruncateString -String $item.Name -MaxLength $nameWidth

        # Figure out the PercentOfParent space wise a item is consuming and return it as a Percentage.
        $PercentOfParent = if($item.type -eq "Path"){"100%"}elseif ($AllItemsSize -ne 0) {"{0:N2}%" -f (($SizeofItem/$AllItemsSize)*100)} else {
            "0.0%"}
        
        # Figure out the color to return based on the PercentOfParent and the Get-ColorByPercentage function defined above
        $color = if($item.type -eq "Path") {"Cyan"} else { Get-ColorByPercentage ([double]$PercentOfParent.Replace("%", "")) }

        # Print each item and include % of Parent
        Write-Host ("{0,-$typeWidth} {1,-$nameWidth} {2,$PercentOfParentWidth} {3,$sizeWidth} {4,$lastModifiedWidth}" -f $item.Type, $truncatedName, $PercentofParent, $item.Size, $item.LastModified) -ForegroundColor $color
        }
    }
}   
    
###### Main Function ######
function Get-DirectoryTreeSize 
{
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory=$false)]
        [string] $Path =((Get-Location).path),
    
        [ValidateSet("Alpha", "Size")]
        [string] $SortBy = "Size",

        [switch] $Files,
        
        [switch] $Headers,

        [double]$SizeLimitbyGB = 0
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
                            
                        } 
                        $AllItemsSize+=$FileSizeBytes
                        $SumAllFilesSizes+=$FileSizeBytes
                        $FileList.Add($outputObject)
                    } 
                } catch {
                    # Capture errors while processing items
                    $ErrorList.Add($_)
                } 
            } 
        } catch {
            # Capture any errors from Get-ChildItem
            $ErrorList.Add($_)
        }

        # Capture permission errors from Get-ChildItem
        foreach ($error in $Errors) {
            $ErrorList.Add($error)
        } 
    } 

    END {
        # Determine the total Size of the Path passed to the funciton
        $Pathsize = Get-CalculateUnit $AllItemsSize

        #Create a Object to contain the final Path details to put at the top of the Output later
        $outputObject = [pscustomobject]@{
            Type = "Path"
            Name = $Path
            Size = $PathSize
            LastModified =(Get-Item $Path).LastWriteTime.ToString("yyyy-MM-dd")

        }
        $TotalPathSize.add($outputObject)

        # Determine the SumAllFilesSizes a unit size based on size
        $Size = Get-CalculateUnit $SumAllFilesSizes
        
        #Create a object for the Sum of all Files to display.
        $outputObject = [pscustomobject]@{
            Type = "Files"
            Name = "[ " + $FileList.Count + " Files]"
            Size = $Size
            LastModified = (Get-Date).ToString("yyyy-MM-dd")
    
        }
        $FileSumList.add($outputObject)

        # Sort the Lists based on SortBy Parameter, default is by Size / Descending
        if ($SortBy -eq "Size")
        {
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
        } 
        elseif ($SortBy -eq "Alpha")
        {
            $DirectoryList = $DirectoryList | Sort-Object Type, Name
            $FileList = $FileList | Sort-Object Type, Name
        }

        if ($Headers)
        {
            Write-Header "Path" -Color Green
            Format-OutputTable  -OutputList $outputList -AllItemsSize $AllItemsSize -SizeLimitbyGB $SizeLimitbyGB

            Write-Header "Directories" -Color Green
            if ($DirectoryList.Count -gt 0) 
            {
                Format-OutputTable  -OutputList $outputList -AllItemsSize $AllItemsSize -SizeLimitbyGB $SizeLimitbyGB
            } 
            else 
            {
                Write-Host "No directories found." -ForegroundColor Yellow
            }

            Write-Header "Files" -Color Green
            if ($Files)
            {
                if ($FileList.Count -gt 0) 
                {
                    Format-OutputTable  -OutputList $outputList -AllItemsSize $AllItemsSize -SizeLimitbyGB $SizeLimitbyGB
                }
                else 
                {
                    Write-Host "No files found." -ForegroundColor Yellow
                }
            }
            else 
            {
                Format-OutputTable  -OutputList $outputList -AllItemsSize $AllItemsSize -SizeLimitbyGB $SizeLimitbyGB
            }
            
            if ($ErrorList.Count -gt 0) 
            {
                Write-Header "Errors" -Color Red
                # Select only the ErrorRecord property from each error
                $ErrorList | ForEach-Object {
                    [pscustomobject]@{ErrorRecord = $_.Exception.Message}
                } | Format-Table -AutoSize
            }
        } #end if
        else {
            if ($Files)
            {
            #Output with Files if Parameter is used.
            $outputList = $TotalPathSize + $DirectoryList + $FileList
            Format-OutputTable -OutputList $outputList -AllItemsSize $AllItemsSize -SizeLimitbyGB $SizeLimitbyGB
            }
            else
            {
            # Output with a Sum entry for files by default
            $outputList = $TotalPathSize + $DirectoryList + $FileSumList
            Format-OutputTable -OutputList $outputList -AllItemsSize $AllItemsSize -SizeLimitbyGB $SizeLimitbyGB
            }
            # Output errors last
            if ($ErrorList.Count -gt 0) 
            {
                Write-Output "Errors encountered:"
                $ErrorList | ForEach-Object {[pscustomobject]@{ErrorRecord = $_.Exception.Message}
                } | Format-Table -AutoSize
            }
        }
    }
}

