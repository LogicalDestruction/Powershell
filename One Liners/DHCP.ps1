<# Various Quick commands to get stuff done using DHCP #>
# Stand alone Powershell 2 Lines, export dhcpServer settings. 
$hostname=hostname
export-DhcpServer -Computername $hostname -File "%UserProfile%\Desktop\$hostname.xml"

#Export DHCP Server settings with Leaseas Example
export-DhcpServer -Computername "servername" -File "%UserProfile%\Desktop\dhcpexport-servername.xml"  -Leases

#Import DHCP Server Settings Example, note you have to define the Backup Path
Import-DhcpServer -Computername "servername" -File "%UserProfile%\Desktop\dhcpexport-servername.xml" -BackupPath "C:\dhcpbackup\" -Leases -ScopeOverwrite -Force

=== Authorize a DHCP Server in AD ===
# Note: This should add the server to ADSI under: ADSI > Connect via Configuration > Then "Configuration, CN=Configuration, CN=Services, CN=NetServices"
#       and if the server isn't listed it might act odd when trying to connect to a DHCP Server using MMC remotely.
add-dhcpserverindc -dnsname "servername" -IPAddress x.x.x.x

