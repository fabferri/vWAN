##################################################################
# 
# Setup list:
# - Create a resource Group for Azure Virtual WAN
# - Create an Azure Virtual WAN
# - Create a Virtual Hub in Virtual WAN
# - Create a VPN Gateway in the Virtual Hub
#
##################################################################
################ Variables #######################################
$subscriptionName= "AzureDemo3"        # name of the Azure subscription
$rgName          = "01-vWAN"           # name of the resoure group for the Virtual WAN
$location        = "northeurope"       # location of the hub
$vWANName        = "wan1"              # name Virtual Wan
$hubName         = "hub1-vnet"         # name of the Virtual Hub
$vHub1Prefix     = "10.0.0.0/24"       # address prefix of the Virtual Hub
$vpnGtwHubName   = "hub1-gtw"          # name VPN Gateway in the Virtual Hub
$nvaIP           = "10.1.10.10"        # IP address of the NVA in transit VNet
$majorDCNetwork  = "10.2.0.0/16"
###################################################################
#
# Select the Azure subscription
$subscr=Get-AzSubscription -SubscriptionName $subscriptionName
Select-AzSubscription -SubscriptionId $subscr.Id 

## Create Resource Group
try {     
    Get-AzResourceGroup -Name $rgName -Location $location -ErrorAction Stop     
    Write-Host 'RG: '$rgName ' already exists... skipping' -foregroundcolor Yellow -backgroundcolor Black
} catch {     
    $rg = New-AzResourceGroup -Name $rgName -Location $location  -Force
}

$runTime=Measure-Command {

## Create Virtual WAN
try {
  $virtualWan=Get-AzVirtualWan -ResourceGroupName $rgName -Name $vWANName -ErrorAction Stop
  Write-Host 'Virtual WAN: '$vWANName' already exists... skipping' -foregroundcolor Yellow -backgroundcolor Black
} catch {
  # Creates an Azure Virtual WAN
  $virtualWan = New-AzVirtualWan -ResourceGroupName $rgName -Name $vWANName -Location $location -AllowBranchToBranchTraffic -AllowVnetToVnetTraffic -Verbose
}

## Create Virtual Hub
try {
   $vhub=Get-AzVirtualHub -ResourceGroupName $rgName -Name $hubName 
   if ([string]::IsNullOrEmpty($vhub))
   {
      Write-Host 'Creating Hub VPN Gateway: '$vpnGtwHubName -foregroundcolor Yellow -backgroundcolor Black
      # Creates an Azure Virtual Hub
      $vhub=New-AzVirtualHub -VirtualWanId $virtualWan.Id -ResourceGroupName $rgName -Name $hubName -AddressPrefix $vHub1Prefix -Location $location
   } else
   {
      Write-Host 'Virtual Hub: '$hubName' already exists... skipping' -foregroundcolor Yellow -backgroundcolor Black
   }
} catch {
   Write-Host 'error in create Virtual Hub: '$hubName'' -foregroundcolor  Yellow -backgroundcolor Black
}

# New-AzVpnGateway creates a scalable VPN Gateway in the Virtual Hub. 
# This is a connectivity for site-to-site connections and point-to-site inside the VirtualHub.
# The gateway resizes and scales based on the scale unit specified in this or the Set-AzVpnGateway cmdlet.
# The VpnGateway will be in the same location as the referenced VirtualHub.
try {
   Get-AzVpnGateway -ResourceGroupName $rgName -Name $vpnGtwHubName  -ErrorAction Stop
   Write-Host 'Virtual Hub-VPN Gateway: '$vpnGtwHubName' already exists... skipping' -foregroundcolor Yellow -backgroundcolor Black
} catch
{
   Write-Host 'Creating Hub VPN Gateway: '$vpnGtwHubName -foregroundcolor Yellow -backgroundcolor Black
   # VpnGatewayScaleUnit 1 -> 500Mbps
   New-AzVpnGateway -ResourceGroupName $rgName -Name $vpnGtwHubName -VpnGatewayScaleUnit 1 -VirtualHubId $vhub.Id 
}

} ### end Measure-Command
write-host -ForegroundColor Yellow "runtime: "$runTime.ToString()


################## UDR in the Virtual Hub ###############################
$runTime=Measure-Command {
$vhub=Get-AzVirtualHub -ResourceGroupName $rgName -Name $hubName -ErrorAction Stop

   $routesHub = $vhub.RouteTable.Routes 
    if (@($routesHub).Count -eq 0){
       write-host "Create the routing table for the Virtual hub: "$vhub.Name
       # create routes for the Virtual Hub
       # $route1: routes to the dc1-vnet and route to dc2-vnet
       $route1 = New-AzVirtualHubRoute -AddressPrefix @($majorDCNetwork) -NextHopIpAddress $nvaIP
       $routeTable = New-AzVirtualHubRouteTable -Route @($route1)

       # update the the Virtual Hub to commit the routes
       Update-AzVirtualHub -ResourceGroupName $rgName -Name $hubName -RouteTable $routeTable
       #Update-AzVirtualHub -ResourceId $vhub.Id -RouteTable $routeTable
       

       # check the number of route entries
       $vhub=Get-AzVirtualHub -ResourceGroupName $rgName -Name $hubName 

    } else {
       Write-Host 'route table already present in Virtual hub:'$vhub.Name -foregroundcolor Yellow -backgroundcolor Black
       Write-Host $routesHub -ForegroundColor Cyan
       Write-Host 'skip creation of route table in Virtual hub:'$vhub.Name -foregroundcolor Yellow -backgroundcolor Black
    } ### end if
       
    write-host "`n`nNumber of route entries applied to the Virtual hub:"@($routesHub).Count -ForegroundColor Cyan
    write-host "Address Prefixes in routing table: "$vhub.RouteTable.Routes.AddressPRefixes -ForegroundColor Cyan
    write-host "Next hop IP address: "$vhub.RouteTable.Routes.NextHopIpAddress -ForegroundColor Cyan

} ### end Measure-Command
write-host -ForegroundColor Yellow "`nruntime: "$runTime.ToString()