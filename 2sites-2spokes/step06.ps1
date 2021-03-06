﻿###########################################
#  
# - Create the vpn site1
# - Create the vpn site2
# - Create the connection hub-vpn site1
# - Create the connection hub-vpn site2
#
# Reference:
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/get-Azvirtualwan
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/remove-Azvirtualwan
#
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/new-Azvirtualhub
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/update-Azvirtualhub
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/remove-Azvirtualhub
#
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/remove-Azvirtualhubvnetconnection
#
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/new-Azvpngateway
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/get-Azvirtualwanvpnconfiguration
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/Update-AzVpnSite
##########################################
#
#
################ Variables
$subscriptionName    = "AzDev"               #"Windows Azure MSDN - Visual Studio Ultimate"
$rgName              = "RG-vWAN101"       # name of the resoure group where is deployed the vWAN
$location            = "northeurope"      # location of the hub
$vWANName            = "wan1"             # name Virtual Wan
$hubName             = "hub1-vnet"        # name of the Virtual Hub
$vHub1Prefix         = "10.0.0.0/24"      # address prefix of the Virtual Hub
$vpnGtwHubName       = "hub1-gtw"         # name VPN Gateway in the Virtual Hub
#
$bgpRemoteAsnSite1   = 65010              # remote ASN vpn site1
$bgpPeerIPSite1      = "172.16.0.10"      # remote IP address of BGP peer of the vpn site1
$vpnSite1Name        = "site1"            # name of vpn site1
$vpnConnection1Name  = "conn-site1"       # name of vpn connection to the site1
#
$bgpRemoteAsnSite2   = 65020              # remote ASN vpn site1
$bgpPeerIPSite2      = "172.16.0.20"      # remote IP address of BGP peer of the vpn site2
$vpnSite2Name        = "site2"            # name of vpn site2
$vpnConnection2Name  = "conn-site2"       # name of vpn connection to the site1
#
$vpnSharedSecret        = "secret!101!"
$vpnSiteAddressSpaces   = New-Object string[] 1
$vpnSiteAddressSpaces[0]= "192.168.255.0/24"
#
$rgName_csr1         = "RG-site1"       # resouce Group where it has been deployed the site1
$rgName_csr2         = "RG-site2"       # resouce Group where it has been deployed the site1
$csr1_Name           = "csr1"           # name Cisco CSR in site1
$csr2_Name           = "csr2"           # name Cisco CSR in site2


################
#
# Select the Azure subscription
$subscr=Get-AzSubscription -SubscriptionName $subscriptionName
Select-AzSubscription -SubscriptionId $subscr.Id 

# compose the name of public IP associated with Cisco CSR 
$csr1_publicIPName   = $csr1_Name + "-pubIP"
$csr2_publicIPName   = $csr2_Name + "-pubIP"

# Assign the public IP of Cisco CSRs to the remote peer of WAN vpn site
$ipRemotePeerSite1=(Get-AzPublicIpAddress  -ResourceGroupName $rgName_csr1 -Name $csr1_publicIPName).IpAddress
$ipRemotePeerSite2=(Get-AzPublicIpAddress  -ResourceGroupName $rgName_csr2 -Name $csr2_publicIPName).IpAddress

write-host -ForegroundColor Cyan "`n============= Public IPs of csr1 and csr2 ============="
write-host -ForegroundColor Yellow -BackgroundColor Black "csr1 -public IP:"$ipRemotePeerSite1
write-host -ForegroundColor Yellow -BackgroundColor Black "csr2 -public IP:"$ipRemotePeerSite2

## get Resource Group
try {     
    Get-AzResourceGroup -Name $rgName -Location $location -ErrorAction Stop     
    Write-Host 'Resource Group vWAN....: '$rgName'' -foregroundcolor Green -backgroundcolor Black
} catch {     
    Write-Host 'select the right resource group and run again the script' -foregroundcolor Yellow -backgroundcolor Black
   Exit
}


## get Virtual WAN
try {
  $virtualWan=Get-AzVirtualWan -ResourceGroupName $rgName -Name $vWANName -ErrorAction Stop
  Write-Host 'Virtual WAN name.......: '$vWANName'' -foregroundcolor Green -backgroundcolor Black
} catch {
     Write-Host 'select the right Virtual WAN and run again the script' -foregroundcolor Yellow -backgroundcolor Black
     Exit
}

## get Virtual Hub
try {
   $vhub=Get-AzVirtualHub -ResourceGroupName $rgName -Name $hubName  -ErrorAction Stop 
   Write-Host 'Virtual Hub name.......: '$hubName'' -foregroundcolor Green -backgroundcolor Black
  
} catch {
     Write-Host 'select the right Virtual Hub and run again the script'  -foregroundcolor Yellow -backgroundcolor Black
     Exit
}


# get VPN Gateway in the Virtual Hub. 
# The VpnGateway will be in the same location as the referenced VirtualHub.
try {
   $vpnHub=Get-AzVpnGateway -ResourceGroupName $rgName -Name $vpnGtwHubName  -ErrorAction Stop
   Write-Host 'Virtual Hub VPN Gateway: '$vpnGtwHubName'' -foregroundcolor Green -backgroundcolor Black
} catch
{
     Write-Host 'select the right vpngateway in the hub and run again the script'  -foregroundcolor Yellow -backgroundcolor Black
     Exit
}

##  New-AzVpnSite: it creates a new Azure VpnSite resource. 
##                    This is an RM representation of customer branches that are uploaded to Azure for S2S connectivity with a virtual hub.
## -AddressSpace     : (optional parameter) the address prefixes of the virtual network. due to a bug you need to specify the address space also with BGP
## -BgpPeeringAddress: (optional parameter) the BGP Peering Address for this VpnSite.

try {
  $vpnSite1=Get-AzVpnSite -ResourceGroupName $rgName -Name $vpnSite1Name  -ErrorAction Stop 
  Write-Host ''
  Write-Host 'Virtual WAN site: '$vpnSite1Name' already exists... skipping' -foregroundcolor Yellow -backgroundcolor Black
} catch {
  $vpnSite1=New-AzVpnSite -ResourceGroupName $rgName -Name $vpnSite1Name -Location $location `
                             -AddressSpace $vpnSiteAddressSpaces `
                             -VirtualWanResourceGroupName $rgName `
                             -VirtualWanName $vWANName -IpAddress $ipRemotePeerSite1 -BgpAsn $bgpRemoteAsnSite1 -BgpPeeringAddress $bgpPeerIPSite1 -BgpPeeringWeight 0 -Verbose
} Finally {
  Write-Host 'VPN site1-Name: '$vpnSite1.Name -foregroundcolor Yellow -backgroundcolor Black
  Write-Host '   VPN site1-pub IP address: '$vpnSite1.IpAddress -foregroundcolor Yellow -backgroundcolor Black
  Write-Host '   VPN site1-BGP ASN: '$vpnSite1.BgpSettings.Asn -foregroundcolor Yellow -backgroundcolor Black
  Write-Host '   VPN site1-BGP peer: '$vpnSite1.BgpSettings.BgpPeeringAddress -foregroundcolor Yellow -backgroundcolor Black
}

try {
  $vpnSite2=Get-AzVpnSite -ResourceGroupName $rgName -Name $vpnSite2Name  -ErrorAction Stop 
  Write-Host ''
  Write-Host 'Virtual WAN vpn site: '$vpnSite2Name' already exists... skipping' -foregroundcolor Yellow -backgroundcolor Black
} catch {
  $vpnSite2=New-AzVpnSite -ResourceGroupName $rgName -Name $vpnSite2Name -Location $location `
                             -AddressSpace $vpnSiteAddressSpaces `
                             -VirtualWanResourceGroupName $rgName `
                             -VirtualWanName $vWANName -IpAddress $ipRemotePeerSite2 -BgpAsn $bgpRemoteAsnSite2 -BgpPeeringAddress $bgpPeerIPSite2 -BgpPeeringWeight 0 -Verbose
} Finally {
  Write-Host 'VPN site2-Name: '$vpnSite2.Name -foregroundcolor Yellow -backgroundcolor Black
  Write-Host '   VPN site2-pub IP address: '$vpnSite2.IpAddress -foregroundcolor Yellow -backgroundcolor Black
  Write-Host '   VPN site2-BGP ASN: '$vpnSite2.BgpSettings.Asn -foregroundcolor Yellow -backgroundcolor Black
  Write-Host '   VPN site2-BGP peer: '$vpnSite2.BgpSettings.BgpPeeringAddress -foregroundcolor Yellow -backgroundcolor Black
}

# Once the VPNG gateway in the hub has been created, it is connected to the VpnSite using the command: New-AzVpnConnection
# 
#  -ConnectionBandwidthInMbps: The bandwith that needs to be handled by this connection in Mbps.
#  -SharedKey                : The shared key required to set this connection up.
try {
  $vpnConn1=Get-AzVpnConnection -ResourceGroupName $rgName -ParentResourceName $vpnGtwHubName -Name $vpnConnection1Name -ErrorAction Stop
} catch {
  $sharedKey = ConvertTo-SecureString -String $vpnSharedSecret -AsPlainText -Force
  $vpnConn1=New-AzVpnConnection -ResourceGroupName $rgName -ParentResourceName $vpnGtwHubName -Name $vpnConnection1Name -VpnSite $vpnSite1 -SharedKey $sharedKey -EnableBgp -VpnConnectionProtocolType IKEv2 -ConnectionBandwidthInMbps 10 -Verbose
} Finally {
  Write-Host ''
  Write-Host 'VPN connection1-Name: '$vpnConn1.Name -foregroundcolor Cyan -backgroundcolor Black
  Write-Host '   VPN connection1-VPN protocol  : '$vpnConn1.VpnConnectionProtocolType -foregroundcolor Cyan -backgroundcolor Black
  Write-Host '   VPN connection1-VPN shared key: '$vpnConn1.SharedKey -foregroundcolor Cyan -backgroundcolor Black
  Write-Host '   VPN connection1-BGP enabled   : '$vpnConn1.EnableBgp -foregroundcolor Cyan -backgroundcolor Black
}

try {
  $vpnConn2=Get-AzVpnConnection -ResourceGroupName $rgName -ParentResourceName $vpnGtwHubName -Name $vpnConnection2Name -ErrorAction Stop
} catch {
  $sharedKey = ConvertTo-SecureString -String $vpnSharedSecret -AsPlainText -Force
  $vpnConn2=New-AzVpnConnection -ResourceGroupName $rgName -ParentResourceName $vpnGtwHubName -Name $vpnConnection2Name -VpnSite $vpnSite2 -SharedKey $sharedKey -EnableBgp -VpnConnectionProtocolType IKEv2 -ConnectionBandwidthInMbps 10 -Verbose
} finally{
  Write-Host ''
  Write-Host 'VPN connection2-Name: '$vpnConn2.Name -foregroundcolor Cyan -backgroundcolor Black
  Write-Host '   VPN connection2-VPN protocol  : '$vpnConn2.VpnConnectionProtocolType -foregroundcolor Cyan -backgroundcolor Black
  Write-Host '   VPN connection2-VPN shared key: '$vpnConn2.SharedKey -foregroundcolor Cyan -backgroundcolor Black
  Write-Host '   VPN connection2-BGP enabled   : '$vpnConn2.EnableBgp -foregroundcolor Cyan -backgroundcolor Black
}
