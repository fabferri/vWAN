###########################################
# 
#
# - Create a resource Group
# - Create a Virtual WAN
# - Create a Virtual Hub
# - Create a VPN Gateway in the Virtual Hub
#
# Reference:
#   https://docs.microsoft.com/en-us/powershell/module/azurerm.network/get-azurermvirtualwan
#   https://docs.microsoft.com/en-us/powershell/module/azurerm.network/new-azurermvirtualwan
#   https://docs.microsoft.com/en-us/powershell/module/azurerm.network/get-azurermvirtualhub
#   https://docs.microsoft.com/en-us/powershell/module/azurerm.network/new-azurermvirtualhub
#   https://docs.microsoft.com/en-us/powershell/module/azurerm.network/update-azurermvirtualhub
#
#   https://docs.microsoft.com/en-us/powershell/module/azurerm.network/remove-azurermvirtualwan
#   https://docs.microsoft.com/en-us/powershell/module/azurerm.network/remove-azurermvirtualhubvnetconnection
#   https://docs.microsoft.com/en-us/powershell/module/azurerm.network/remove-azurermvirtualhub
# 
# New-AzureRmVpnGateway                   https://docs.microsoft.com/en-us/powershell/module/azurerm.network/new-azurermvpngateway
# Get-AzureRmVirtualWanVpnConfiguration   https://docs.microsoft.com/en-us/powershell/module/azurerm.network/get-azurermvirtualwanvpnconfiguration
# Update-AzureRmVpnSite                   https://docs.microsoft.com/en-us/powershell/module/azurerm.network/Update-AzureRmVpnSite
#
#
# check out the deployment:  https://aka.ms/azurecortex
##########################################
#
#
################ Variables
$subscriptionName= "Windows Azure MSDN - Visual Studio Ultimate"
$rgName          = "RG-vWAN101"          # name of the resoure group
$location        = "westcentralus"       # location of the hub
$vWANName        = "wan1"                # name Virtual Wan
$hubName         = "hub1-vnet"           # name of the Virtual Hub
$vHub1Prefix     = "10.0.0.0/24"         # address prefix of the Virtual Hub
$vpnGtwHubName   = "hub1-gtw"            # name VPN Gateway in the Virtual Hub
################
#
# Select the Azure subscription
$subscr=Get-AzureRmSubscription -SubscriptionName $subscriptionName
Select-AzureRmSubscription -SubscriptionId $subscr.Id 

## Create Resource Group
try {     
    Get-AzureRmResourceGroup -Name $rgName -Location $location -ErrorAction Stop     
    Write-Host 'RG already exists... skipping' -foregroundcolor Green -backgroundcolor Black
} catch {     
    $rg = New-AzureRmResourceGroup -Name $rgName -Location $location  -Force
}


## Create Virtual WAN
try {
  $virtualWan=Get-AzureRmVirtualWan -ResourceGroupName $rgName -Name $vWANName -ErrorAction Stop
  Write-Host 'Virtual WAN '$vWANName' already exists... skipping' -foregroundcolor  Green -backgroundcolor Black
} catch {
  # Creates an Azure Virtual WAN
  $virtualWan = New-AzureRmVirtualWan -ResourceGroupName $rgName -Name $vWANName -Location $location -AllowBranchToBranchTraffic -AllowVnetToVnetTraffic -Verbose
}

## Create Virtual Hub
try {
   $vhub=Get-AzureRmVirtualHub -ResourceGroupName $rgName -Name $hubName  -ErrorAction Stop 
   Write-Host 'Virtual Hub: '$hubName' already exists... skipping' -foregroundcolor  Green -backgroundcolor Black
} catch {
   # Creates an Azure Virtual Hub
   $vhub=New-AzureRmVirtualHub -VirtualWanId $virtualWan.Id -ResourceGroupName $rgName -Name $hubName -AddressPrefix $vHub1Prefix -Location $location
}


# New-AzureRmVpnGateway creates a scalable VPN Gateway in the Virtual Hub. 
# This is a connectivity for site-to-site connections inside the VirtualHub.
# This gateway resizes and scales based on the scale unit specified in this or the Set-AzureRmVpnGateway cmdlet.
# A connection is set up from a branch/Site known as VPNSite to the scalable gateway. Each connection comprises of 2 Active-Active tunnels.
# The VpnGateway will be in the same location as the referenced VirtualHub.
try {
   Get-AzureRmVpnGateway -ResourceGroupName $rgName -Name $vpnGtwHubName  -ErrorAction Stop
   Write-Host 'Virtual Hub VPN Gateway: '$vpnGtwHubName' already exists... skipping' -foregroundcolor  Green -backgroundcolor Black
} catch
{
   # VpnGatewayScaleUnit 1 -> 500Mbps
   New-AzureRmVpnGateway -ResourceGroupName $rgName -Name $vpnGtwHubName -VpnGatewayScaleUnit 1 -VirtualHubId $vhub.Id 
}


