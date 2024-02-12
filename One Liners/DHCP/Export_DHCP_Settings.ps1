<# Export DHCP Settings #>
# Stand alone Powershell 2 Lines, export dhcpServer settings.  Don't have to worry about hostname
$hostname=hostname
export-DhcpServer -Computername $hostname -File "%UserProfile%\Desktop\$hostname.xml"
