###########################################
#  
# - Create a connection between virtual hub and spoke1-vnet
# - Create a connection between virtual hub and spoke2-vnet
# - Create a connection between virtual hub and spoke3-vnet
# Reference:
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/get-Azvirtualhubvnetconnection
#
##########################################
#
#
################ Variables
$subscriptionName= "AzDev"               # name of the Azure subscription
$rgName          = "rg-vwan1"            # name of the resoure group where is deployed the Virtual WAN
$location        = "eastus"              # location of the Virtual hub
$vWANName        = "wan1"                # name Virtual Wan
$hubName         = "hub1-vnet"           # name of the Virtual Hub
$vHub1Prefix     = "10.0.0.0/24"         # address prefix of the Virtual Hub
#
$rgNameVNet1     = "rg-vwan1-spokes"     # Resource Group where is deployed the Spoke1 VNet
$rgNameVNet2     = "rg-vwan1-spokes"     # Resource Group where is deployed the Spoke2 VNet
$rgNameVNet3     = "rg-vwan1-spokes"     # Resource Group where is deployed the Spoke2 VNet
$vnet1Name       = "spoke1-vnet"         # name of spoke1 VNet
$vnet2Name       = "spoke2-vnet"         # name of spoke2 VNet
$vnet3Name       = "spoke3-vnet"         # name of spoke2 VNet
$vHubConnection1 = "conn-vnet1"          # name of connection between the virtual hub and the spoke1 VNet
$vHubConnection2 = "conn-vnet2"          # name of connection between the virtual hub and the spoke2 VNet
$vHubConnection3 = "conn-vnet3"          # name of connection between the virtual hub and the spoke3 VNet
################
#
# Select the Azure subscription
$subscr=Get-AzSubscription -SubscriptionName $subscriptionName
Select-AzSubscription -SubscriptionId $subscr.Id 

## check Resource Group
try {     
    Get-AzResourceGroup -Name $rgName -Location $location -ErrorAction Stop     
    Write-Host 'RG.........: '$rgName'' -foregroundcolor Green -backgroundcolor Black
} catch {     
    Write-Host 'select the right resource group and run again the script' -foregroundcolor Green -backgroundcolor Black
   Exit
}


## check Virtual WAN
try {
  $virtualWan=Get-AzVirtualWan -ResourceGroupName $rgName -Name $vWANName -ErrorAction Stop
  Write-Host 'Virtual WAN: '$vWANName'' -foregroundcolor  Green -backgroundcolor Black
} catch {
     Write-Host 'select the right Virtual WAN and run again the script' -foregroundcolor Green -backgroundcolor Black
     Exit
}

## check Virtual Hub
try {
   $vhub=Get-AzVirtualHub -ResourceGroupName $rgName -Name $hubName  -ErrorAction Stop 
   Write-Host 'Virtual Hub: '$hubName'' -foregroundcolor  Green -backgroundcolor Black
} catch {
     Write-Host 'select the right Virtual Hub and run again the script' -foregroundcolor Green -backgroundcolor Black
     Exit
}


# Get the existing vnets
try {
    $vnet1 = Get-AzVirtualNetwork -ResourceGroupName $rgNameVNet1 -Name $vnet1Name -ErrorAction Stop -WarningAction SilentlyContinue
    Write-Host 'vnet.......: '$vnet1Name'' -foregroundcolor  Green -backgroundcolor Black
} catch {  
     Write-Host 'select the right vnet and run the script again' -foregroundcolor  Green -backgroundcolor Black
     Exit
}
try {
    $vnet2 = Get-AzVirtualNetwork -ResourceGroupName $rgNameVNet2 -Name $vnet2Name -ErrorAction Stop -WarningAction SilentlyContinue
    Write-Host 'vnet.......: '$vnet2Name'' -foregroundcolor  Green -backgroundcolor Black
} catch {  
     Write-Host 'select the right vnet and run the script again'  -backgroundcolor Black
     Exit
}
try {
    $vnet3 = Get-AzVirtualNetwork -ResourceGroupName $rgNameVNet3 -Name $vnet3Name -ErrorAction Stop -WarningAction SilentlyContinue
    Write-Host 'vnet.......: '$vnet3Name'' -foregroundcolor  Green -backgroundcolor Black
} catch {  
     Write-Host 'select the right vnet and run the script again'  -backgroundcolor Black
     Exit
}

$runTime=Measure-Command {
try {
  $conn=Get-AzVirtualHubVnetConnection -ResourceGroupName $rgName -Name $vHubConnection1 -ParentResourceName $hubName -ErrorAction Stop 
  Write-Host 'Connection between vHub: '$hubName' to vnet:'$vnet1Name' already exists... skipping' -foregroundcolor  Green -backgroundcolor Black
} catch {
   $vnet1 = Get-AzVirtualNetwork -ResourceGroupName $rgNameVNet1 -Name $vnet1Name -WarningAction SilentlyContinue
   #Create am Virtual Network Connection between the Virtual Hub and the remote VNet.
   $conn=New-AzVirtualHubVnetConnection -ResourceGroupName $rgName -VirtualHubName $vhub.Name -Name $vHubConnection1 -RemoteVirtualNetworkId $vnet1.Id -Verbose
   Write-Host 'Connection.: '$vHubConnection1'' -foregroundcolor  Green -backgroundcolor Black
}

try {
  $conn=Get-AzVirtualHubVnetConnection -ResourceGroupName $rgName -Name $vHubConnection2 -ParentResourceName $hubName -ErrorAction Stop 
  Write-Host 'Connection between vHub: '$hubName' to vnet:'$vnet2Name' already exists... skipping' -foregroundcolor  Green -backgroundcolor Black
} catch {
   $vnet2 = Get-AzVirtualNetwork -ResourceGroupName $rgNameVNet2 -Name $vnet2Name -WarningAction SilentlyContinue
   #Create am Virtual Network Connection between the Virtual Hub and the remote VNet.
   $conn=New-AzVirtualHubVnetConnection -ResourceGroupName $rgName -VirtualHubName $vhub.Name -Name $vHubConnection2 -RemoteVirtualNetworkId $vnet2.Id -Verbose
   Write-Host 'Connection.: '$vHubConnection2'' -foregroundcolor  Green -backgroundcolor Black
}

try {
  $conn=Get-AzVirtualHubVnetConnection -ResourceGroupName $rgName -Name $vHubConnection3 -ParentResourceName $hubName -ErrorAction Stop 
  Write-Host 'Connection between vHub: '$hubName' to vnet:'$vnet3Name' already exists... skipping' -foregroundcolor  Green -backgroundcolor Black
} catch {
   $vnet2 = Get-AzVirtualNetwork -ResourceGroupName $rgNameVNet3 -Name $vnet3Name -WarningAction SilentlyContinue
   #Create am Virtual Network Connection between the Virtual Hub and the remote VNet.
   $conn=New-AzVirtualHubVnetConnection -ResourceGroupName $rgName -VirtualHubName $vhub.Name -Name $vHubConnection3 -RemoteVirtualNetworkId $vnet3.Id -Verbose
   Write-Host 'Connection.: '$vHubConnection3'' -foregroundcolor  Green -backgroundcolor Black
}

}
write-host -ForegroundColor Yellow "runtime: "$runTime.ToString()