#
# script to delete and recreate new UDRs in the dc1 and dc2 VNets
#
# - deassociate the existing routing table from the dc1-subnet1
# - remove the existing routing table 
# - create a new routing table for the dc1 VNet
# - associated the new routing table to the dc1-subnet
#
# - interation of the same steps for the dc2-subnet1:
# - deassociate the existing routing table from the dc2-subnet1
# - remove the existing routing table used for dc2 VNet 
# - create a new routing table for the dc2 VNet
# - associated the new routing table to the dc2-subnet
#
######################################################
$subscriptionName= "AzureDemo3"                  # name of the Azure subscription
##
$rgName_dc1          = "01-spokes"               # name of the resource group to deploye the dc1 VNet
$location_dc1        = "northeurope"             # Azure location  where is deployed the dc1 VNet
$vnetName_dc1        = "dc1-vnet"                # name of the VNet
$subnet1Name_dc1     = "subnet1"                 # name of the subnet1 in "dc1" VNet
$subnet1Prefix_dc1   = "10.2.10.0/24"            # address space assigned to the subnet1 of "dc1" VNet
$subnet2Name_dc1     = "subnet2"                 # name of the subnet2 in "dc1" VNet
$subnet2Prefix_dc1   = "10.2.11.0/24"            # address space assigned to the subnet2 of "dc1" VNet
$rtName_dc1          = "rt-dc1"                  # name of the routing table associated with subnet1 of "dc1" VNet

##
$rgName_dc2          = "01-spokes"               # name of the resource group to deploye the "dc2" VNets
$location_dc2        = "northeurope"             # Azure location where is deployed the "dc2" VNet
$vnetName_dc2        = "dc2-vnet"                # name of the VNet
$subnet1Name_dc2     = "subnet1"                 # name of the subnet1 in "dc2" VNet
$subnet1Prefix_dc2   = "10.2.20.0/24"            # address space assigned to the subnet1 of "dc2" VNet
$subnet2Name_dc2     = "subnet2"                 # name of the subnet2 in "dc2" VNet
$subnet2Prefix_dc2   = "10.2.21.0/24"            # address space assigned to the subnet2 of "dc2" VNet
$rtName_dc2          = "rt-dc2"                  # name of the routing table associated with subnet1 of "dc2" VNet



########## UDR variables #############################
$rtName_dc1= "rt-dc1"
$rtName_dc2= "rt-dc2"
$nvaIP     = "10.1.10.10"

$rtArray_dc1 = @(
  @{
      name = "to-dc2-subnet1" 
      addressPrefix = "10.2.20.0/24" 
      nextHopType = "VirtualAppliance" 
      nextHopIpAddress =$nvaIP 
   },
  @{
      name = "to-dc2-subnet2" 
      addressPrefix = "10.2.21.0/24" 
      nextHopType = "VirtualAppliance" 
      nextHopIpAddress =$nvaIP 
   },
  @{
      name = "to-site1-subnet1" 
      addressPrefix = "10.3.10.0/24" 
      nextHopType = "VirtualAppliance" 
      nextHopIpAddress =$nvaIP 
   },
  @{
      name = "to-site1-subnet2" 
      addressPrefix = "10.3.11.0/24" 
      nextHopType = "VirtualAppliance" 
      nextHopIpAddress =$nvaIP 
   },
  @{
      name = "to-site2-subnet1" 
      addressPrefix = "10.3.20.0/24" 
      nextHopType = "VirtualAppliance" 
      nextHopIpAddress =$nvaIP 
   },
  @{
      name = "to-site2-subnet2" 
      addressPrefix = "10.3.21.0/24" 
      nextHopType = "VirtualAppliance" 
      nextHopIpAddress =$nvaIP 
   }
)


$rtArray_dc2 = @(
  @{
      name = "to-dc1-subnet1" 
      addressPrefix = "10.2.10.0/24" 
      nextHopType = "VirtualAppliance" 
      nextHopIpAddress =$nvaIP 
   },
  @{
      name = "to-dc1-subnet2" 
      addressPrefix = "10.2.11.0/24" 
      nextHopType = "VirtualAppliance" 
      nextHopIpAddress =$nvaIP 
   },
  @{
      name = "to-site1-subnet1" 
      addressPrefix = "10.3.10.0/24" 
      nextHopType = "VirtualAppliance" 
      nextHopIpAddress =$nvaIP 
   },
  @{
      name = "to-site1-subnet2" 
      addressPrefix = "10.3.11.0/24" 
      nextHopType = "VirtualAppliance" 
      nextHopIpAddress =$nvaIP 
   },
  @{
      name = "to-site2-subnet1" 
      addressPrefix = "10.3.20.0/24" 
      nextHopType = "VirtualAppliance" 
      nextHopIpAddress =$nvaIP 
   },
  @{
      name = "to-site2-subnet2" 
      addressPrefix = "10.3.21.0/24" 
      nextHopType = "VirtualAppliance" 
      nextHopIpAddress =$nvaIP 
   }
)
######################################################

########## UDR Function ##############################
function changeUDR {
      Param
      (
       [Parameter(Mandatory=$true)] [System.String]$rgName,                     # name of the resource group where are deployed the VNet and routing table
       [Parameter(Mandatory=$true)] [System.String]$location,                   # name of the azure location where are deployed the VNet and routing table
       [Parameter(Mandatory=$true)] [System.String]$vnetName,                   # name of the VNet
       [Parameter(Mandatory=$true)] [System.String]$subnet1Name,                # name of the subnet1 
       [Parameter(Mandatory=$true)] [System.String]$subnet1Prefix,              # address space assigned to the subnet1
       [Parameter(Mandatory=$true)] [System.String]$subnet2Name,                # name of the subnet2
       [Parameter(Mandatory=$true)] [System.String]$subnet2Prefix,              # address space assigned to the subnet2
       [Parameter(Mandatory=$true)] [System.String]$rtName,                     # name of the existing routing table
       [Parameter(Mandatory=$true)] [System.Object]$rtArray,                    # name of the first entry of the new routing table
       [Parameter(Mandatory=$true)] [System.String]$nvaIP                       # IP address of the NVA

      )

## Create Resource Group
try {     
    Get-AzResourceGroup -Name $rgName -Location $location -ErrorAction Stop
} catch {
    Write-Host "RG: "$rgName " doesn't exists... reference the right resource group and run again" -foregroundcolor Yellow -backgroundcolor Black
    Exit
}  

try{
  $vnet =get-azVirtualNetwork -Name $VNetName -ResourceGroupName $rgName -ErrorAction Stop
} catch {
    Write-Host "VNet: "$VNetName " doesn't exists... reference the write VNet and run again" -foregroundcolor Yellow -backgroundcolor Black
    Exit
}

 #  deassociated the routing table from the vnet
  write-host "deassociate the routing table from the VNet:"$VNetName "-subnet:"$vnet.Subnets[1].Name -ForegroundColor Cyan 
  write-host "deassociate the routing table from the VNet:"$VNetName "-subnet:"$vnet.Subnets[0].Name -ForegroundColor Cyan 
  $vnet.Subnets[0].RouteTable=$null
  $vnet.Subnets[1].RouteTable=$null
  Set-AzVirtualNetwork -VirtualNetwork $vnet

try {
  write-host "getting the routing table: "$rtName -ForegroundColor Cyan
  $rt =Get-AzRouteTable -ResourceGroupName $rgName -Name $rtName -ErrorAction Stop | Out-Null
  write-host "removing the routing table: "$rtName -ForegroundColor Cyan
  Remove-AzRouteTable -ResourceGroupName $rgName -Name $rtName -Force 
} catch {
  write-host "routing table: "$rtName " doesn't exist"
}

Start-Sleep -Seconds 10

try {

  write-host "Create the routing table: "$rtName -foregroundcolor Yellow -backgroundcolor Black

    ## Create a route table
   $rt = New-AzRouteTable `
     -Name $rtName `
     -ResourceGroupName $rgName `
     -location $location

    $rt=Get-AzRouteTable -ResourceGroupName $rgName -Name $rtName

    ## Add route entries to the routing table
    foreach ($rtElement in $rtArray)
    {
    
      Add-AzRouteConfig `
        -Name $rtElement.name `
        -AddressPrefix $rtElement.addressPrefix `
        -NextHopType $rtElement.nextHopType `
        -NextHopIpAddress $rtElement.nextHopIpAddress`
        -RouteTable $rt 
    }
    Set-AzRouteTable -RouteTable $rt 
    $vnet=Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgName 
    Set-AzVirtualNetworkSubnetConfig `
      -VirtualNetwork $vnet `
      -Name $subnet1Name `
      -AddressPrefix $subnet1Prefix `
      -RouteTable $rt 
    Set-AzVirtualNetwork -VirtualNetwork $vnet
} catch {
  write-host "error to create the routing table: "$rtName -ForegroundColor Cyan
  Exit
} ### end try

} ### end function



# Select the Azure subscription
$subscr=Get-AzSubscription -SubscriptionName $subscriptionName
Select-AzSubscription -SubscriptionId $subscr.Id 


changeUDR -rgName $rgName_dc1 `
       -location $location_dc1 `
       -vnetName $vnetName_dc1 `
       -subnet1Name $subnet1Name_dc1 `
       -subnet1Prefix $subnet1Prefix_dc1 `
       -subnet2Name $subnet2Name_dc1 `
       -subnet2Prefix $subnet2Prefix_dc1 `
       -rtName $rtName_dc1 `
       -rtArray $rtArray_dc1 `
       -nvaIP $nvaIP



changeUDR -rgName $rgName_dc2 `
       -location $location_dc2 `
       -vnetName $vnetName_dc2 `
       -subnet1Name $subnet1Name_dc2 `
       -subnet1Prefix $subnet1Prefix_dc2 `
       -subnet2Name $subnet2Name_dc2 `
       -subnet2Prefix $subnet2Prefix_dc2 `
       -rtName $rtName_dc2 `
       -rtArray $rtArray_dc2 `
       -nvaIP $nvaIP 
