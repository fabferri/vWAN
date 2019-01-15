###########################################
#  
# - Create a connection between virtual hub and spoke1-vnet
# - Create a connection between virtual hub and spoke2-vnet
#
# Reference:
#   https://docs.microsoft.com/en-us/powershell/module/azurerm.network/get-azurermvirtualhubvnetconnection
#
##########################################
#
#
################ Variables
$subscriptionName= "Windows Azure MSDN - Visual Studio Ultimate"
$rgName          = "RG-vWAN101"          # name of the resoure group where is deployed the Virtual WAN
$location        = "westcentralus"       # location of the Virtual hub
$vWANName        = "wan1"                # name Virtual Wan
$hubName         = "hub1-vnet"           # name of the Virtual Hub
$vHub1Prefix     = "10.0.0.0/24"         # address prefix of the Virtual Hub
$vpnGtwHubName   = "hub1-gtw"            # name VPN Gateway in the Virtual Hub
#
$rgNameVNet1     = "RG-spokes"           # Resouece Group where is deployed the Spoke1 VNet
$rgNameVNet2     = "RG-spokes"           # Resouece Group where is deployed the Spoke2 VNet
$vnet1Name       = "spoke1-vnet"         # name of spoke1 VNet
$vnet2Name       = "spoke2-vnet"         # name of spoke2 VNet
$vHubConnection1 = "conn-vnet1"          # name of connection between the virtual hub and the spoke1 VNet
$vHubConnection2 = "conn-vnet2"          # name of connection between the virtual hub and the spoke1 VNet
################
#
# Select the Azure subscription
$subscr=Get-AzureRmSubscription -SubscriptionName $subscriptionName
Select-AzureRmSubscription -SubscriptionId $subscr.Id 

## check Resource Group
try {     
    Get-AzureRmResourceGroup -Name $rgName -Location $location -ErrorAction Stop     
    Write-Host 'RG.........: '$rgName'' -foregroundcolor Green -backgroundcolor Black
} catch {     
    Write-Host 'select the right resource group and run again the script' -foregroundcolor Green -backgroundcolor Black
   Exit
}


## check Virtual WAN
try {
  $virtualWan=Get-AzureRmVirtualWan -ResourceGroupName $rgName -Name $vWANName -ErrorAction Stop
  Write-Host 'Virtual WAN: '$vWANName'' -foregroundcolor  Green -backgroundcolor Black
} catch {
     Write-Host 'select the right Virtual WAN and run again the script' -foregroundcolor Green -backgroundcolor Black
     Exit
}

## check Virtual Hub
try {
   $vhub=Get-AzureRmVirtualHub -ResourceGroupName $rgName -Name $hubName  -ErrorAction Stop 
   Write-Host 'Virtual Hub: '$hubName'' -foregroundcolor  Green -backgroundcolor Black
} catch {
     Write-Host 'select the right Virtual Hub and run again the script' -foregroundcolor Green -backgroundcolor Black
     Exit
}


# Get the existing vnets
try {
    $vnet1 = Get-AzureRmVirtualNetwork -ResourceGroupName $rgNameVNet1 -Name $vnet1Name -ErrorAction Stop -WarningAction SilentlyContinue
    Write-Host 'vnet.......: '$vnet1Name'' -foregroundcolor  Green -backgroundcolor Black
} catch {  
     Write-Host 'select the right vnet and run the script again' -foregroundcolor  Green -backgroundcolor Black
     Exit
}
try {
    $vnet2 = Get-AzureRmVirtualNetwork -ResourceGroupName $rgNameVNet2 -Name $vnet2Name -ErrorAction Stop -WarningAction SilentlyContinue
    Write-Host 'vnet.......: '$vnet2Name'' -foregroundcolor  Green -backgroundcolor Black
} catch {  
     Write-Host 'select the right vnet and run the script again'  -backgroundcolor Black
     Exit
}

$runTime=Measure-Command {
try {
  $conn=Get-AzureRmVirtualHubVnetConnection -ResourceGroupName $rgName -Name $vHubConnection1 -ParentResourceName $hubName -ErrorAction Stop 
  Write-Host 'Connection between vHub: '$hubName' to vnet:'$vnet1Name' already exists... skipping' -foregroundcolor  Green -backgroundcolor Black
} catch {
   $vnet1 = Get-AzureRmVirtualNetwork -ResourceGroupName $rgNameVNet1 -Name $vnet1Name -WarningAction SilentlyContinue
   #Create am Virtual Network Connection between the Virtual Hub and the remote VNet.
   $conn=New-AzureRmVirtualHubVnetConnection -ResourceGroupName $rgName -VirtualHubName $vhub.Name -Name $vHubConnection1 -RemoteVirtualNetworkId $vnet1.Id -Verbose
   Write-Host 'Connection.: '$vHubConnection1'' -foregroundcolor  Green -backgroundcolor Black
}

try {
  $conn=Get-AzureRmVirtualHubVnetConnection -ResourceGroupName $rgName -Name $vHubConnection2 -ParentResourceName $hubName -ErrorAction Stop 
  Write-Host 'Connection between vHub: '$hubName' to vnet:'$vnet2Name' already exists... skipping' -foregroundcolor  Green -backgroundcolor Black
} catch {
   $vnet2 = Get-AzureRmVirtualNetwork -ResourceGroupName $rgNameVNet2 -Name $vnet2Name -WarningAction SilentlyContinue
   #Create am Virtual Network Connection between the Virtual Hub and the remote VNet.
   $conn=New-AzureRmVirtualHubVnetConnection -ResourceGroupName $rgName -VirtualHubName $vhub.Name -Name $vHubConnection2 -RemoteVirtualNetworkId $vnet2.Id -Verbose
   Write-Host 'Connection.: '$vHubConnection2'' -foregroundcolor  Green -backgroundcolor Black
}

}
write-host -ForegroundColor Yellow "runtime: "$runTime.ToString()