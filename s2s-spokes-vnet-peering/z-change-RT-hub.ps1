#
# -remove an existing routing table associated with the hub
# -create a new routing table associated with the hub
#
################ Variables #######################################
$subscriptionName= "AzureDemo3"        # name of the Azure subscription
$rgName          = "01-vWAN"           # name of the resoure group for the Virtual WAN
$location        = "northeurope"       # location of the hub
$vWANName        = "wan1"              # name Virtual Wan
$hubName         = "hub1-vnet"         # name of the Virtual Hub
$vHub1Prefix     = "10.0.0.0/24"       # address prefix of the Virtual Hub
$vpnGtwHubName   = "hub1-gtw"          # name VPN Gateway in the Virtual Hub
$nvaIP           = "10.1.10.10"        # IP address of the NVA in transit VNet
#$majorNetSpokes  = "10.2.0.0/16"

$dc1_subnet1     = "10.2.10.0/24"
$dc1_subnet2     = "10.2.11.0/24"
$dc2_subnet1     = "10.2.20.0/24"
$dc2_subnet2     = "10.2.21.0/24"

###################################################################
#
# Select the Azure subscription
$subscr=Get-AzSubscription -SubscriptionName $subscriptionName
Select-AzSubscription -SubscriptionId $subscr.Id 

##### remove the routing table in the hub
$runTime=Measure-Command {
try
{
  $vhub=Get-AzVirtualHub -ResourceGroupName $rgName -Name $hubName -ErrorAction Stop
} catch {
  write-host 'wrong reference to the hub: '$hubName ' Reference the right hub and run again.'
  Exit
}
   $routesHub = $vhub.RouteTable.Routes 
    if (@($routesHub).Count -ne 0){
       write-host ""
       write-host  "Removing routing table from the hub: "$hubName -ForegroundColor Yellow -BackgroundColor Black
       # create an empty route table
       $routeTable=New-Object  -TypeName Microsoft.Azure.Commands.Network.Models.PSVirtualHubRouteTable
       Update-AzVirtualHub -ResourceGroupName $rgName -Name $hubName -RouteTable $routeTable

       # check the number of route entries
       $vhub=Get-AzVirtualHub -ResourceGroupName $rgName -Name $hubName 
       $routesHub = $vhub.RouteTable.Routes
       write-host "Number of route entries applied to the Virtual hub:"@($routesHub).Count -ForegroundColor Yellow -BackgroundColor Black
    } else {
       Write-Host 'route table associate with Virtual hub:'$vhub.Name' already empty' -foregroundcolor Yellow -backgroundcolor Black
    } ### end if

} ### end Measure-Command



$runTime=Measure-Command {
try
{
  $vhub=Get-AzVirtualHub -ResourceGroupName $rgName -Name $hubName -ErrorAction Stop
} catch {
  write-host 'wrong reference to the hub: '$hubName ' Reference the right hub and run again.'
  Exit
}
   write-host "Create a new route table for the Virtual hub:"$hubName -ForegroundColor Yellow -BackgroundColor Black
   #create a new route entry in memory
   $route1 = New-AzVirtualHubRoute -AddressPrefix @($dc1_subnet1, $dc1_subnet2, $dc2_subnet1, $dc2_subnet2) -NextHopIpAddress $nvaIP
   $routeTable = New-AzVirtualHubRouteTable -Route @($route1)

   write-host "Apply the route table to the Virtual hub:"$hubName -ForegroundColor Yellow -BackgroundColor Black
   Update-AzVirtualHub -ResourceGroupName $rgName -Name $hubName -RouteTable $routeTable

   # check the number of route entries
   $vhub=Get-AzVirtualHub -ResourceGroupName $rgName -Name $hubName 
   $routesHub = $vhub.RouteTable.Routes
 
    # check the number of route entries
    $vhub=Get-AzVirtualHub -ResourceGroupName $rgName -Name $hubName 
    write-host "`n`n"
    write-host "Number of routes applied to the Virtual hub.....: "@($routesHub).Count -ForegroundColor Cyan
    write-host "Address Prefixes in Virtual hub routing table...: "$vhub.RouteTable.Routes.AddressPRefixes -ForegroundColor Cyan
    write-host "Next hop IP address in Virtual hub routing table: "$vhub.RouteTable.Routes.NextHopIpAddress -ForegroundColor Cyan
} ### end Measure-Command

write-host -ForegroundColor Yellow "create new routing table - runtime: "$runTime.ToString()