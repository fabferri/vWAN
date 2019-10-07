##################################################################
#  
# - Create a list of vpn sites
# - Create the connections hub-vpn sites
# https://aka.ms/azurevirtualwanpreviewfeatures
##################################################################
################ Variables
$subscriptionName    = "AzDev"            # Name of the Azure subscription
$rgName              = "RG-vWAN101"       # name of the resoure group where is deployed the vWAN
$location            = "northeurope"      # location of the hub
$vWANName            = "wan1"             # name Virtual Wan
$hubName             = "hub1-vnet"        # name of the Virtual Hub
$vHub1Prefix         = "10.0.0.0/24"      # address prefix of the Virtual Hub
$vpnGtwHubName       = "hub1-gtw"         # name VPN Gateway in the Virtual Hub

$csr1_Name           = "csr1"             # name Cisco CSR in site1
$csr2_Name           = "csr2"             # name Cisco CSR in site2
$csr3_Name           = "csr3"             # name Cisco CSR in site3

$vpnSiteAddressSpaces   = New-Object string[] 1
$vpnSiteAddressSpaces[0]= "192.168.255.0/24"

$vpnSiteArray = @(
  @{
     rgName_csr         = "RG-site1"              # name of the resource group where is deployed the site
     vpnSharedSecret    = "secret!101!"           # shared secred associated with the connection
     csr_publicIPName   = $csr1_Name + "-pubIP"   # name of the public IP of the Cisco CSR
     bgpRemoteAsnSite   = 65011                   # remote ASN vpn site1
     bgpPeerIPSite      = "172.16.0.10"           # remote IP address of BGP peer of the vpn site1
     vpnSiteName        = "site1"                 # name of vpn site1
     vpnConnectionName  = "conn-site1"            # name of vpn connection to the site1
   },
   @{
     rgName_csr         = "RG-site2"              # name of the resource group where is deployed the site
     vpnSharedSecret    = "secret!101!"           # shared secred associated with the connection
     csr_publicIPName   = $csr2_Name + "-pubIP"   # name of the public IP of the Cisco CSR
     bgpRemoteAsnSite   = 65012                   # remote ASN vpn site1
     bgpPeerIPSite      = "172.16.0.20"           # remote IP address of BGP peer of the vpn site2
     vpnSiteName        = "site2"                 # name of vpn site2
     vpnConnectionName  = "conn-site2"            # name of vpn connection to the site1
   },
   @{
     rgName_csr         = "RG-site3"              # name of the resource group where is deployed the site
     vpnSharedSecret    = "secret!101!"           # shared secred associated with the connection
     csr_publicIPName   = $csr3_Name + "-pubIP"   # name of the public IP of the Cisco CSR
     bgpRemoteAsnSite   = 65013                   # remote ASN vpn site1
     bgpPeerIPSite      = "172.16.0.30"           # remote IP address of BGP peer of the vpn site2
     vpnSiteName        = "site3"                 # name of vpn site2
     vpnConnectionName  = "conn-site3"            # name of vpn connection to the site1
   }
)




################
#
# Select the Azure subscription
$subscr=Get-AzSubscription -SubscriptionName $subscriptionName
Select-AzSubscription -SubscriptionId $subscr.Id 


## get Resource Group
try {     
    Get-AzResourceGroup -Name $rgName -Location $location -ErrorAction Stop     
    Write-Host 'Resource Group vWAN....: '$rgName'' -foregroundcolor Green -backgroundcolor Black
} catch {     
    Write-Host 'select the right resource group of the VWAN and run the script again' -foregroundcolor Yellow -backgroundcolor Black
   Exit
}

## get Virtual WAN
try {
  $virtualWan=Get-AzVirtualWan -ResourceGroupName $rgName -Name $vWANName -ErrorAction Stop
  Write-Host 'Virtual WAN name.......: '$vWANName'' -foregroundcolor Green -backgroundcolor Black
} catch {
     Write-Host 'select the right Virtual WAN and run the script again' -foregroundcolor Yellow -backgroundcolor Black
     Exit
}

## get Virtual Hub
try {
   $vhub=Get-AzVirtualHub -ResourceGroupName $rgName -Name $hubName  -ErrorAction Stop 
   Write-Host 'Virtual Hub name.......: '$hubName'' -foregroundcolor Green -backgroundcolor Black
  
} catch {
     Write-Host 'select the right Virtual Hub and run the script again'  -foregroundcolor Yellow -backgroundcolor Black
     Exit
}


# get VPN Gateway in the Virtual Hub. 
# The VpnGateway will be in the same location as the referenced VirtualHub.
try {
   $vpnHub=Get-AzVpnGateway -ResourceGroupName $rgName -Name $vpnGtwHubName  -ErrorAction Stop
   Write-Host 'Virtual Hub VPN Gateway: '$vpnGtwHubName'' -foregroundcolor Green -backgroundcolor Black
} catch
{
     Write-Host 'select the right vpngateway in the hub and run the script again'  -foregroundcolor Yellow -backgroundcolor Black
     Exit
}

$vpnSites = New-Object Microsoft.Azure.Commands.Network.Models.PSVpnSite[] $vpnSiteArray.length
$ipRemotePeerSite =New-Object System.String[] $vpnSiteArray.length
$vpnConn=New-Object Microsoft.Azure.Commands.Network.Models.PSVpnConnection[] $vpnSiteArray.length

For ($i=0; $i -lt $vpnSiteArray.Length; $i++) {

# Assign the public IP of Cisco CSRs to the remote peer of WAN vpn site
$ipRemotePeerSite[$i]=(Get-AzPublicIpAddress  -ResourceGroupName $vpnSiteArray[$i].rgName_csr -Name $vpnSiteArray[$i].csr_publicIPName).IpAddress

write-host -ForegroundColor Cyan "`n============= Public IPs of remote cisco csr ============="
write-host -ForegroundColor Yellow -BackgroundColor Black "csr -public IP:"$ipRemotePeerSite[$i]

try {
  ##  New-AzVpnSite: it creates a new Azure VpnSite resource. 
  ##                 This is an ARM representation of customer branches that are uploaded to Azure for S2S connectivity with a virtual hub.
  ## -AddressSpace     : (optional parameter) the address prefixes of the virtual network. Due to a implementation you need to specify the address space also with BGP
  ## -BgpPeeringAddress: (optional parameter) the BGP Peering Address for this VpnSite.
  $vpnSites[$i]=Get-AzVpnSite -ResourceGroupName $rgName -Name $vpnSiteArray[$i].vpnSiteName  -ErrorAction Stop 
  Write-Host ''
  Write-Host 'Virtual WAN site: '$vpnSite1Name' already exists... skipping' -foregroundcolor Yellow -backgroundcolor Black
} catch {
  $vpnSites[$i]=New-AzVpnSite -ResourceGroupName $rgName -Name $vpnSiteArray[$i].vpnSiteName -Location $location `
                             -AddressSpace $vpnSiteAddressSpaces `
                             -VirtualWanResourceGroupName $rgName `
                             -VirtualWanName $vWANName `
                             -IpAddress $ipRemotePeerSite[$i] `
                             -BgpAsn $vpnSiteArray[$i].bgpRemoteAsnSite `
                             -BgpPeeringAddress $vpnSiteArray[$i].bgpPeerIPSite `
                             -BgpPeeringWeight 0 -Verbose
  
} Finally {
  Write-Host 'VPN site1-Name: '$vpnSites[$i].Name -foregroundcolor Yellow -backgroundcolor Black
  Write-Host '   VPN site1-pub IP address: '$vpnSites[$i].IpAddress -foregroundcolor Yellow -backgroundcolor Black
  Write-Host '   VPN site1-BGP ASN: '$vpnSites[$i].BgpSettings.Asn -foregroundcolor Yellow -backgroundcolor Black
  Write-Host '   VPN site1-BGP peer: '$vpnSites[$i].BgpSettings.BgpPeeringAddress -foregroundcolor Yellow -backgroundcolor Black
}

try {
   # Once the VPNG gateway in the hub has been created, it is connected to the VpnSite using the command: New-AzVpnConnection
   #  -ConnectionBandwidthInMbps: The bandwith that needs to be handled by this connection in Mbps.
   #  -SharedKey                : The shared key required to set this connection up.
  $vpnConn[$i]=Get-AzVpnConnection -ResourceGroupName $rgName -ParentResourceName $vpnGtwHubName -Name $vpnSiteArray[$i].vpnConnectionName -ErrorAction Stop
} catch {
  $sharedKey = ConvertTo-SecureString -String $vpnSiteArray[$i].vpnSharedSecret -AsPlainText -Force
  $vpnConn[$i]=New-AzVpnConnection -ResourceGroupName $rgName -ParentResourceName $vpnGtwHubName -Name $vpnSiteArray[$i].vpnConnectionName -VpnSite $vpnSites[$i] -SharedKey $sharedKey -EnableBgp -VpnConnectionProtocolType IKEv2 -ConnectionBandwidthInMbps 10 -Verbose
} Finally {
  Write-Host ''
  Write-Host 'VPN connection1-Name: '$vpnConn[$i].Name -foregroundcolor Cyan -backgroundcolor Black
  Write-Host '   VPN connection1-VPN protocol  : '$vpnConn[$i].VpnConnectionProtocolType -foregroundcolor Cyan -backgroundcolor Black
  Write-Host '   VPN connection1-VPN shared key: '$vpnConn[$i].SharedKey -foregroundcolor Cyan -backgroundcolor Black
  Write-Host '   VPN connection1-BGP enabled   : '$vpnConn[$i].EnableBgp -foregroundcolor Cyan -backgroundcolor Black
}

} ### End for loop
