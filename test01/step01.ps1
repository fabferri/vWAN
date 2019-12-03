###########################################
# 
# Setup list:
# - Create a resource Group
# - Create a Virtual WAN
# - Create a Virtual Hub
# - Create a VPN Gateway in the Virtual Hub
#
###########################################
# Reference:
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/get-Azvirtualwan
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/new-Azvirtualwan
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/get-Azvirtualhub
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/new-Azvirtualhub
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/update-Azvirtualhub
#
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/remove-Azvirtualwan
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/remove-Azvirtualhubvnetconnection
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/remove-Azvirtualhub
# 
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/new-Azvpngateway
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/get-Azvirtualwanvpnconfiguration
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/Update-AzVpnSite
#
# check out the deployment:  https://aka.ms/azurecortex
##########################################
#
#
################ Variables
$subscriptionName= "AzDev"               # name of the Azure subscription
$rgName          = "rg-vwan1"            # name of the resoure group
$location        = "eastus"              # location of the hub
$vWANName        = "wan1"                # name Virtual Wan
$hubName         = "hub1-vnet"           # name of the Virtual Hub
$vHub1Prefix     = "10.0.0.0/24"         # address prefix of the Virtual Hub
$vpnGtwHubName   = "hub1-gtw"            # name VPN Gateway in the Virtual Hub
################
#
# Select the Azure subscription
$subscr=Get-AzSubscription -SubscriptionName $subscriptionName
Select-AzSubscription -SubscriptionId $subscr.Id 

## Create Resource Group
try {     
    Get-AzResourceGroup -Name $rgName -Location $location -ErrorAction Stop     
    Write-Host 'RG '$rgName' already exists... skipping' -foregroundcolor Green -backgroundcolor Black
} catch {     
    $rg = New-AzResourceGroup -Name $rgName -Location $location  -Force
}


## Create Virtual WAN
try {
  $virtualWan=Get-AzVirtualWan -ResourceGroupName $rgName -Name $vWANName -ErrorAction Stop
  Write-Host 'Virtual WAN '$vWANName' already exists... skipping' -foregroundcolor  Green -backgroundcolor Black
} catch {
  # Creates an Azure Virtual WAN
  $virtualWan = New-AzVirtualWan -ResourceGroupName $rgName -Name $vWANName -Location $location -AllowBranchToBranchTraffic -AllowVnetToVnetTraffic -Verbose
}

## Create Virtual Hub
try {
   $vhub=Get-AzVirtualHub -ResourceGroupName $rgName -Name $hubName 
   if ([string]::IsNullOrEmpty($vhub))
   {
      # Creates an Azure Virtual Hub
      $vhub=New-AzVirtualHub -VirtualWanId $virtualWan.Id -ResourceGroupName $rgName -Name $hubName -AddressPrefix $vHub1Prefix -Location $location
   } else
   {
      Write-Host 'Virtual Hub: '$hubName' already exists... skipping' -foregroundcolor  Green -backgroundcolor Black
   }
} catch {
   Write-Host 'error in create Virtual Hub: '$hubName'' -foregroundcolor  Green -backgroundcolor Black
}
Exit

# New-AzVpnGateway creates a scalable VPN Gateway in the Virtual Hub. 
# This is a connectivity for site-to-site connections and point-to-site inside the VirtualHub.
# This gateway resizes and scales based on the scale unit specified in this or the Set-AzVpnGateway cmdlet.
# The VpnGateway will be in the same location as the referenced VirtualHub.
try {
   Get-AzVpnGateway -ResourceGroupName $rgName -Name $vpnGtwHubName  -ErrorAction Stop
   Write-Host 'Virtual Hub VPN Gateway: '$vpnGtwHubName' already exists... skipping' -foregroundcolor  Green -backgroundcolor Black
} catch
{
   # VpnGatewayScaleUnit 1 -> 500Mbps
   New-AzVpnGateway -ResourceGroupName $rgName -Name $vpnGtwHubName -VpnGatewayScaleUnit 1 -VirtualHubId $vhub.Id 
}


