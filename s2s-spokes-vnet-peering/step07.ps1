##################################################################
#  
# - Create a connection between virtual hub and transit-vnet
# - Create a connection between virtual hub and transit-vnet
#
# Reference:
#   https://docs.microsoft.com/en-us/powershell/module/Az.network/get-Azvirtualhubvnetconnection
#
##################################################################
################ Variables #######################################
$subscriptionName= "AzureDemo3"          # name of the Azure subscription
$rgName          = "01-vWAN"             # name of the resoure group where is deployed the Virtual WAN
$location        = "northeurope"         # location of the resoruce group - Virtual hub
$vWANName        = "wan1"                # name Virtual Wan
$hubName         = "hub1-vnet"           # name of the Virtual Hub
#
$ConnectionArray = @(
  @{
      rgNameVNet     = "01-spokes"       # Resource Group where is deployed the "transit" VNet
      vnetName       = "transit-vnet"    # name of "transit" VNet
      hubName        = $hubName          # name of Virual WAN hub
      connectionName = "conn-transit"    # name of connection between the "transit" VNet and Virtual WAN hub 
   },
  @{
      rgNameVNet     = "01-spokes"       # Resource Group where is deployed the "spoke2" VNet
      vnetName       = "spoke2-vnet"     # name of "spoke2" VNet
      hubName        = $hubName          # name of Virual WAN hub
      connectionName = "conn-spoke2"     # name of connection between the "spoke2" VNet and Virtual WAN hub 
   }
)
##################################################################
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


### check Virtual WAN
try {
  $virtualWan=Get-AzVirtualWan -ResourceGroupName $rgName -Name $vWANName -ErrorAction Stop
  Write-Host 'Virtual WAN: '$vWANName'' -foregroundcolor  Yellow -backgroundcolor Black
} catch {
     Write-Host 'select the right Virtual WAN and run again the script' -foregroundcolor Green -backgroundcolor Black
     Exit
}

### check Virtual Hub
try {
   $vhub=Get-AzVirtualHub -ResourceGroupName $rgName -Name $hubName  -ErrorAction Stop 
   Write-Host 'Virtual Hub: '$hubName'' -foregroundcolor  Yellow -backgroundcolor Black
} catch {
     Write-Host 'select the right Virtual Hub and run again the script' -foregroundcolor Green -backgroundcolor Black
     Exit
}


$runTime=Measure-Command {

for ($i=0; $i -lt $ConnectionArray.Length; $i++)
{
# Get the existing vnets
try {
    $vnet = Get-AzVirtualNetwork -ResourceGroupName $ConnectionArray[$i].rgNameVNet `
                -Name $ConnectionArray[$i].vnetName -ErrorAction Stop -WarningAction SilentlyContinue
    Write-Host 'vnet.......: '$ConnectionArray[$i].vnetName'' -foregroundcolor  Green -backgroundcolor Black
} catch {  
     Write-Host 'select the right vnet and run the script again' -foregroundcolor  Green -backgroundcolor Black
     Exit
}


try {
  $conn=Get-AzVirtualHubVnetConnection -ResourceGroupName $rgName `
               -Name $ConnectionArray[$i].connectionName `
               -ParentResourceName $ConnectionArray[$i].hubName -ErrorAction Stop 
  Write-Host 'Connection between vHub: '$ConnectionArray[$i].hubName' to vnet:'$ConnectionArray[$i].vnetName' already exists... skipping' -foregroundcolor  Green -backgroundcolor Black
} catch {
   $vnet = Get-AzVirtualNetwork -ResourceGroupName $ConnectionArray[$i].rgNameVNet -Name $ConnectionArray[$i].vnetName -WarningAction SilentlyContinue
   #Create a Virtual Network Connection between the Virtual Hub and the remote VNet.
   $conn=New-AzVirtualHubVnetConnection -ResourceGroupName $rgName `
                -VirtualHubName $vhub.Name `
                -Name $ConnectionArray[$i].ConnectionName `
                -RemoteVirtualNetworkId $vnet.Id -Verbose
   Write-Host 'Connection.: '$ConnectionArray[$i].ConnectionName'' -foregroundcolor  Green -backgroundcolor Black
}

} ### end for

} ### end Measure-Command
write-host -ForegroundColor Yellow "runtime: "$runTime.ToString()


