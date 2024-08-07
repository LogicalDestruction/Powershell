<#
.SYNOPSIS
    Script Gathers some Hardware data from VMware drops it into a text file and formats it in such a way it can easily be copy pasted into a 
    dokuwiki site/page.

    There are 3 ways to format the output, List, Table, or CSV.  The List and Tables are built for Dokuwiki formating but the CSV can be imported into Excel.

    Dokuwiki URL: https://www.dokuwiki.org/dokuwiki

    Dokuwiki site is assumed to have the "color Plugin" installed on the site
    URL: https://www.dokuwiki.org/plugin:color

.NOTES
    Name: VMware_HW_Inventory.ps1
    Author: Robert Stacks
    DateCreated: 08-02-2024
    URL: https://github.com/LogicalDestruction/Powershell/blob/main/Scripts/VMware/VMware_HW_Inventory.ps1
#>

############ User Variables #############
# Define a output file
$Outfile = "C:\temp\VMware_HardWare_Inventory.txt"

# Define a list of vcenters to connect to seprated by a comma
$vcenterServers = @(
    "vcenter1",
    "vcenter2"
)

# Outputformat can = LIST or TABLE
#$Outputformat = "LIST"
$Outputformat = "TABLE"
#$Outputformat = "CSV"

#########################################

############### Variables ###############

# Make sure the Output file is empty.
Clear-Content -Path $Outfile
# Get the date and format for use in reporting
$formateddate = (get-date).ToString("MMMM dd, yyyy")

#########################################

################## Main #################

# Ensure the VMware.PowerCLI module is imported
Import-Module VMware.PowerCLI

# Prompt for credentials only once
$credential = Get-Credential

# Function to format bytes into GB
function Format-Size {
    param (
        [Parameter(Mandatory=$true)]
        [double]$Bytes
    )

    $TB = 1TB
    $GB = 1GB

    if($Bytes -gt 1TB){
        return "{0:N0} TB" -f ($Bytes / $TB)
    }
    else{
        return "{0:N0} GB" -f ($Bytes / $GB)
    }
}

Write-Output "====== ESXi Host Hardware Report from vCenter ======" >> $Outfile
Write-Output "===== Last Reported: $formateddate =====" >> $Outfile

#For Each vCenter connect and fetch the HW Data
foreach ($vcenterServer in $vcenterServers)
{
    #Bit of context on the console to let the user know its working
    Write-Host "Connecting to vCenter: $vcenterServer"
    Connect-VIServer -Server $vcenterServer -Credential $credential
    Write-Host " "
    Write-Host "Generating Report for $vCenterServer"
    
# Get data centers
$dataCenters = Get-Datacenter | Sort-Object -Property Name
Write-Output "===== $vcenterServer =====" >> $Outfile

#If we are formating the output for a table in dokuwiki we create a table header before the Cluster looping
if($Outputformat -eq "TABLE")
{
    Write-Output "^Data Center ^Cluster ^ESXi Host Name ^ESXi Ver ^OS Build # ^HW Model ^Processor ^  # Procs  ^  # VMs  ^  Total / Used RAM ^  % Used RAM  ^  Total / Used Storage ^  % Used Storage  ^" >> $Outfile
}
if($Outputformat -eq "CSV")
{
    Write-Output "Data Center,Cluster,ESXi Host Name,ESXi Ver,OS Build #,Manufacture,HW Model,Processor,# Procs,# VMs,Total RAM,Used RAM,% Used RAM,Total Storage,Used Storage,% Used Storage" >> $Outfile
}

foreach ($dc in $dataCenters) {
    #Write-Output "==== $($dc.Name) ====" >> $Outfile
    $clusters = Get-Cluster -Location $dc
    
    # Loop through each cluster and get the physical hosts in each one.
    foreach ($cluster in $clusters) 
    {

        #If we are formating output for a List we build a header for Cluster for each list.
        if($Outputformat -eq "LIST")
        {
            Write-Output "  * **<color #6DB33F>Cluster: $($cluster.Name) </color>**" >> $Outfile
        }
        
        #Get a list of physical hosts in the Cluster
        $SVRs = Get-VMHost -Location $cluster
        
        #Loops through the hosts and get some details about each one to report on
        foreach ($SVR in $SVRs) 
        {
            $hypervisor = $SVR.Version
            $hypervisorbuild = $SVR.Build
            $model = $SVR.Model
            $MFR = $SVR.Manufacturer
            $NumCPU = $SVR.NumCpu
            $processorType = $SVR.ProcessorType
            $totalRAM = $SVR.MemoryTotalMB
            $usedRAM = $SVR.MemoryUsageMB
            $percentUsedRAM = [math]::Round(($usedRAM / $totalRAM) * 100, 2)
            $datastores = Get-Datastore -VMHost $SVR
            $totalStorage = 0
            $usedStorage = 0
                                    
            # Efficiently get the VM count for this specific host
            $VMsOnHost = Get-VM | Where-Object { $_.VMHost -eq $SVR }
            $VMCount = $VMsOnHost.Count
            
            foreach ($ds in $datastores) {
                $totalStorage += $ds.CapacityMB
                $usedStorage += $ds.CapacityMB - $ds.FreeSpaceMB
            }
            
            $percentUsedStorage = [math]::Round(($usedStorage / $totalStorage) * 100, 2)

            # If CPU has HyperThreadingActive doulbe the number for the CPU count to match what is in the GUI
            if($SVR.HyperthreadingActive)
            {
                $NumCPU = $NumCPU * 2
            }
            

            if($Outputformat -eq "LIST")
            {
                Write-Output "    * **<color #0095D3>ESXi Host: $($SVR.Name)</color>**" >> $Outfile
                Write-Output "      * **Hypervisor:**  VMware ESXi, $hypervisor, $hypervisorbuild" >> $Outfile
                Write-Output "      * **Model:** $MFR $model" >> $Outfile
                Write-Output "      * **Processor Type:** $processorType" >> $Outfile
                Write-Output "      * **Logical Processors:** $NumCPU" >> $Outfile
                Write-Output "      * **Virtual Machines:** $VMCount" >> $Outfile
                Write-Output "      * **RAM:** $(Format-Size ($totalRAM * 1MB)) Total \ $(Format-Size ($usedRAM * 1MB)) Used ($percentUsedRAM%)" >> $Outfile
                Write-Output "      * **Storage:** $(Format-Size ($totalStorage * 1MB)) Total \ $(Format-Size ($usedStorage * 1MB)) Used ($percentUsedStorage%)" >> $Outfile
            }
            if($Outputformat -eq "TABLE")
            {
                Write-Output "|$($dc.Name) |$($cluster.Name) |$($SVR.Name) |$hypervisor |$hypervisorbuild |$MFR $model |$processorType |  $NumCPU  |  $VMCount  |  $(Format-Size ($totalRAM * 1MB)) / $(Format-Size ($usedRAM * 1MB))|  $percentUsedRAM%  |  $(Format-Size ($totalStorage * 1MB)) / $(Format-Size ($usedStorage * 1MB))|  $percentUsedStorage%  |" >> $Outfile
            } 
            if($Outputformat -eq "CSV")
            {
                Write-Output "$($dc.Name),$($cluster.Name),$($SVR.Name),$hypervisor,$hypervisorbuild,$MFR,$model,$processorType,$NumCPU,$VMCount,$(Format-Size ($totalRAM * 1MB)),$(Format-Size ($usedRAM * 1MB)),$percentUsedRAM%,$(Format-Size ($totalStorage * 1MB)),$(Format-Size ($usedStorage * 1MB)),$percentUsedStorage%" >> $Outfile
            }

        }
    }
}

# Disconnect from vCenter
Disconnect-VIServer -Server $vcenterServer -Confirm:$false

}