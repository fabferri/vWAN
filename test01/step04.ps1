###
### Reference:
###  https://docs.microsoft.com/sl-si/powershell/module/az.network/new-azvirtualhubroute?view=azps-3.1.0
###  https://docs.microsoft.com/sl-si/powershell/module/az.network/add-azvirtualhubroute?view=azps-3.1.0
###
$subscriptionName= "AzDev"               # name of the Azure subscription
$rgName          = "rg-vwan1"            # name of the resoure group
$location        = "eastus"              # location of the hub
$vWANName        = "wan1"                # name Virtual Wan
$hubName         = "hub1-vnet"           # name of the Virtual Hub

$vHubConnection1 = "conn-vnet1"          # name of connection between the virtual hub and the spoke1 VNet
$vHubConnection2 = "conn-vnet2"          # name of connection between the virtual hub and the spoke2 VNet
$vHubConnection3 = "conn-vnet3"          # name of connection between the virtual hub and the spoke3 VNet
$routeTableName  = "RT01"                # name of the routing table
#
# Select the Azure subscription
$subscr=Get-AzSubscription -SubscriptionName $subscriptionName
Select-AzSubscription -SubscriptionId $subscr.Id 

## Check Resource Group
try {     
    Get-AzResourceGroup -Name $rgName -Location $location -ErrorAction Stop     
    Write-Host "RG         : $rgName found!" -foregroundcolor Green -backgroundcolor Black
} catch {     
    $rg = New-AzResourceGroup -Name $rgName -Location $location  -Force
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


try {
  $conn=Get-AzVirtualHubVnetConnection -ResourceGroupName $rgName -Name $vHubConnection1 -ParentResourceName $hubName -ErrorAction Stop 
  Write-Host 'Connection between vHub: '$hubName' to vnet:'$vnet1Name' found - OK' -foregroundcolor  Green -backgroundcolor Black
} catch {
   Write-Host 'Connection.: '$vHubConnection1' not found' -foregroundcolor  Green -backgroundcolor Black
   Exit
}

try {
  $conn=Get-AzVirtualHubVnetConnection -ResourceGroupName $rgName -Name $vHubConnection2 -ParentResourceName $hubName -ErrorAction Stop 
  Write-Host 'Connection between vHub: '$hubName' to vnet:'$vnet2Name' found - OK' -foregroundcolor  Green -backgroundcolor Black
} catch {

   Write-Host 'Connection.: '$vHubConnection2' not found' -foregroundcolor  Green -backgroundcolor Black
   Exit
}

try {
  $conn=Get-AzVirtualHubVnetConnection -ResourceGroupName $rgName -Name $vHubConnection3 -ParentResourceName $hubName -ErrorAction Stop 
  Write-Host 'Connection between vHub: '$hubName' to vnet:'$vnet3Name' found - OK' -foregroundcolor  Green -backgroundcolor Black
} catch {
   Write-Host 'Connection.: '$vHubConnection3' not found' -foregroundcolor  Green -backgroundcolor Black
   Exit
}


$route1 = Add-AzVirtualHubRoute -DestinationType "CIDR" -Destination @("10.0.10.0/24", "10.0.20.0/24") -NextHopType "IPAddress"  -NextHop @("10.0.30.10")
$routeTable1 = Add-AzVirtualHubRouteTable -Route @($route1) -Connection @("All_Vnets") -Name $routeTableName 
Set-AzVirtualHub -VirtualHub $vhub -RouteTable @($routeTable1)

Exit

# Get-AzVirtualHubRouteTable -ResourceGroupName $rgName -HubName $hubName -Name $routeTableName 
# Remove-AzVirtualHubRouteTable -ResourceGroupName $rgName -HubName $hubName -Name $routeTableName 


### Creates an Azure Virtual Hub Route Table object, composed of multiple routes
#$route1 = New-AzVirtualHubRoute -AddressPrefix @("10.0.10.0/24", "10.0.20.0/20") -NextHopIpAddress "10.0.30.10"
#$routeTable1 = New-AzVirtualHubRouteTable -Route @($route1)



 