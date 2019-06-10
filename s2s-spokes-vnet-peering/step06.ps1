###########################################
# - Create a Resource Group
# - Create a transit-vnet with subnet1 and subnet2
# - Create a spoke2-vnet with subnet1 and subnet2
# - transit-vnet: Create a VM attached to subnet1
# - spoke2-vnet: Create a VM attached to subnet1
# - Create a NSG
# - Associate the NSG to the subnets in transit-vnet
# - Associate the NSG to the subnets in spoke2-vnet 
#
###########################################
##   Run the script by command:
##  .\scriptName -adminUsername YOUR_USERNAME -adminPassword YOUR_PASSWORD
##
################# Input parameters ########
[CmdletBinding()]
param (
    [Parameter(Mandatory=$True, ValueFromPipeline=$false, HelpMessage='username administrator VMs', Position=0)]
    [string]$adminUsername,
 
    [Parameter(Mandatory = $true, HelpMessage='password administrator VMs')]
    [string]$adminPassword
    )


########################### Variables ###################################################
$subscriptionName= "AzureDemo3"                           # name of the Azure subscription
$rgName          = "01-spokes"                            # name of the resource group to deploye the spoke VNets
$location        = "northeurope"                          # Azure location 
#  
$VNetArray = @(
  @{
     rgName         = $rgName                             # name of resource group name where is deployed the "transit" VNet
     location       = "northeurope"                       # location of the "transit" VNet
     vnetName       = "transit-vnet"                      # name of the "transit" VNet
     vnetPrefix     = @("10.1.10.0/24","10.1.11.0/24")    # address space of the VNet
     subnet1Name    = "subnet1"                           # name of the subnet1
     subnet1Prexif  = "10.1.10.0/24"                      # address space of the subnet1 
     subnet2Name    = "subnet2"                           # name of the subnet2 
     subnet2Prexif  = "10.1.11.0/24"                      # address space of subnet2
     nsgName        = "nsg"+"transit"                     # network security group associated with the VNet
     rtName         = $null                               # routing table associated with the VNet
   },
  @{
     rgName         = $rgName                             # name of resource group name where is deployed the "spoke2" VNet
     location       = "northeurope"                       # location of the "spoke2" VNet
     vnetName       = "spoke2-vnet"                       # name of the spoke2 VNet
     vnetPrefix     = @("10.1.20.0/24","10.1.21.0/24")    # address space of the second spoke VNet
     subnet1Name    = "subnet1"                           # name of the subnet1 in spoke2 VNet
     subnet1Prexif  = "10.1.20.0/24"                      # address space assigned to the subnet1 of spoke2 VNet
     subnet2Name    = "subnet2"
     subnet2Prexif  = "10.1.21.0/24"
     nsgName        = "nsg"+"spoke2"
     rtName         = $null
   },
  @{
     rgName         = $rgName                             # name of resource group name where is deployed the "dc1" VNet
     location       = "northeurope"                       # location of the "dc1" VNet
     vnetName       = "dc1-vnet"                          # name of the "dc1" VNet
     vnetPrefix     = @("10.2.10.0/24","10.2.11.0/24")    # address space of the second spoke VNet
     subnet1Name    = "subnet1"                           # name of the subnet1 in "dc1" VNet
     subnet1Prexif  = "10.2.10.0/24"                      # address space assigned to the subnet1 of "dc1" VNet
     subnet2Name    = "subnet2"
     subnet2Prexif  = "10.2.11.0/24"
     nsgName        = "nsg"+"dc1"
     rtName         = "rt-dc1"
   },
  @{
     rgName         = $rgName                             # name of the resource group name
     location       = "northeurope"
     vnetName       = "dc2-vnet"                          # name of the spoke2 VNet
     vnetPrefix     = @("10.2.20.0/24","10.2.21.0/24")    # address space of the second spoke VNet
     subnet1Name    = "subnet1"                           # name of the subnet1 in spoke2 VNet
     subnet1Prexif  = "10.2.20.0/24"                      # address space assigned to the subnet1 of spoke2 VNet
     subnet2Name    = "subnet2"
     subnet2Prexif  = "10.2.21.0/24"
     nsgName        = "nsg"+"dc2"
     rtName         = "rt-dc2"
   }
)


$VNetPeeringArray = @(
  @{
       peeringName     = "transit-dc1"
       rg1Name         = $rgName  
       location1       = "northeurope"        # location of the "transit" VNet
       vnet1Name       = "transit-vnet"       # name of the "transit" VNet
       rg2Name         = $rgName  
       location2       = "northeurope"        # location of the "transit" VNet
       vnet2Name       = "dc1-vnet"           # name of the "transit" VNet
  },
 @{
       peeringName     = "dc1-transit"
       rg1Name         = $rgName  
       location1       = "northeurope"        # location of the "transit" VNet
       vnet1Name       = "dc1-vnet"           # name of the "transit" VNet
       rg2Name         = $rgName  
       location2       = "northeurope"        # location of the "transit" VNet
       vnet2Name       = "transit-vnet"       # name of the "transit" VNet
  },
  @{
       peeringName     = "transit-dc2"
       rg1Name         = $rgName  
       location1       = "northeurope"        # location of the "transit" VNet
       vnet1Name       = "transit-vnet"       # name of the "transit" VNet
       rg2Name         = $rgName  
       location2       = "northeurope"        # location of the "transit" VNet
       vnet2Name       = "dc2-vnet"           # name of the "transit" VNet
  },
 @{
       peeringName     = "dc2-transit"
       rg1Name         = $rgName  
       location1       = "northeurope"        # location of the "transit" VNet
       vnet1Name       = "dc2-vnet"           # name of the "transit" VNet
       rg2Name         = $rgName  
       location2       = "northeurope"        # location of the "transit" VNet
       vnet2Name       = "transit-vnet"       # name of the "transit" VNet
  }
)

$vmArrayName= @(
  @{
        rgName      = $rgName                 # name of the resource group where is deployed the VNet
        vmName      = "transit-vm1"           # name of the VM attached to the subnet1 of the "transit" VNet
        nicName     = "transit-vm1"+"-nic"    # name of the NIC
        publicIPName= "transit-vm1"+"-pubIP"  # name of the public IP asociated with the NIC of the VM
        privateIP   = "10.1.10.10"            # private IP assigned to VM attached to the subnet1 of the "transit" VNet
        vnetName    = "transit-vnet"          # name of the VNet where is created the VM
        subnetName  = "subnet1"               # name of the subnet where is attached the NIC
        enableForwarding=$true                # IP fowarding enabled/disabled in the NIC
       
   },
  @{
        rgName      = $rgName        
        vmName      = "spoke2-vm1" 
        nicName     = "spoke2-vm1"+"-nic"
        publicIPName= "spoke2-vm1"+"-pubIP"
        privateIP   = "10.1.20.10"
        vnetName    = "spoke2-vnet"  
        subnetName  = "subnet1"
        enableForwarding=$false
   },
  @{
        rgName      = $rgName
        vmName      = "dc1-vm1" 
        nicName     = "dc1-vm1"+"-nic"
        publicIPName= "dc1-vm1"+"-pubIP"
        privateIP   = "10.2.10.10"
        vnetName    = "dc1-vnet"  
        subnetName  = "subnet1"
        enableForwarding=$false
   },
  @{
        rgName      = $rgName
        vmName      = "dc2-vm1" 
        nicName     = "dc2-vm1"+"-nic"
        publicIPName= "dc2-vm1"+"-pubIP"
        privateIP   = "10.2.20.10"
        vnetName    = "dc2-vnet"  
        subnetName  = "subnet1"
        enableForwarding=$false
   }
)

######## common VMs variables
$adminName       = $adminUsername                     # administrator username of the VMs
$adminPwd        = $adminPassword                     # administrator password of the VMs
$publisherName   = "openlogic"                        # publisher of linux VMs
$offerName       = "CentOS"                           # linux VM distro
$skuName         = "7.5"                              # linux VM version
$version         = "latest"                           # latest image available
$vmSize          = "Standard_B1ls"                    # size of the VM:  "Standard_B1ls","Standard_B1s"
$nsgName         = "nsgVNets"                         # name of the network security group asociated with the subnets
#
#
####################################### UDR VARIABLES ###################################
$rtName_dc1= "rt-dc1"
$rtName_dc2= "rt-dc2"
$nvaIP     = "10.1.10.10"

$rtArray_dc1 = @(
  @{
      name = "to-private-networks" 
      addressPrefix = "10.0.0.0/8" 
      nextHopType = "VirtualAppliance" 
      nextHopIpAddress =$nvaIP 
   }
)

$rtArray_dc2 = @(
  @{
      name = "to-private-networks" 
      addressPrefix = "10.0.0.0/8" 
      nextHopType = "VirtualAppliance" 
      nextHopIpAddress =$nvaIP 
   }
)
#########################################################################################
#
########## FUNCTIONs ########################################
function CreateVNet{
      Param
      (  [Parameter(Mandatory=$true)] [System.String]$rgName,
         [Parameter(Mandatory=$true)] [System.String]$location,
         [Parameter(Mandatory=$true)] [System.String]$vnetName,
         [Parameter(Mandatory=$true)] [System.Object]$vnetPrefix,
         [Parameter(Mandatory=$true)] [System.String]$subnet1Name,
         [Parameter(Mandatory=$true)] [System.String]$subnet1Prefix,
         [Parameter(Mandatory=$true)] [System.String]$subnet2Name,
         [Parameter(Mandatory=$true)] [System.String]$subnet2Prefix
         )


try {
    $vnet = Get-AzVirtualNetwork -ResourceGroupName $rgName -Name $vnetName -ErrorAction Stop -WarningAction SilentlyContinue
    Write-Host 'VNet '$vnetName' already exists... skipping' -foregroundcolor Green -backgroundcolor Black
} catch {  
    $vnet = New-AzVirtualNetwork -Name $vnetName  `
                                  -ResourceGroupName $rgName `
                                  -Location $location  `
                                  -AddressPrefix $vnetPrefix `
                                  -Verbose -Force -WarningAction SilentlyContinue
    $subnet1 = Add-AzVirtualNetworkSubnetConfig -Name $subnet1Name -AddressPrefix $subnet1Prefix -VirtualNetwork $vnet -WarningAction SilentlyContinue
    $subnet2 = Add-AzVirtualNetworkSubnetConfig -Name $subnet2Name -AddressPrefix $subnet2Prefix -VirtualNetwork $vnet -WarningAction SilentlyContinue
    Set-AzVirtualNetwork -VirtualNetwork $vnet -WarningAction SilentlyContinue
}

write-host -ForegroundColor Yellow "VNet              : " $vnet.Name
write-host -ForegroundColor Yellow "VNet Address Space: " $vnet.AddressSpace.AddressPrefixes  
for($i=0;$i-le $vnet.Subnets.Count-1;$i++)
{
     $subnet=Get-AzVirtualNetworkSubnetConfig -Name $vnet.Subnets[$i].Name -VirtualNetwork $vnet -WarningAction SilentlyContinue
     write-host -ForegroundColor Yellow "SubNet Name       : " $subnet.Name
     write-host -ForegroundColor Yellow "SubNet Prefix     : " $subnet.AddressPrefix  
 
}

} ### end function CreateVNet
#
#
function createAzVM {
      Param
      (  [Parameter(Mandatory=$true)] [System.String]$rgName,
         [Parameter(Mandatory=$true)] [System.String]$location,
         [Parameter(Mandatory=$true)] [System.String]$vmName,
         [Parameter(Mandatory=$true)] [System.String]$vmSize,
         [Parameter(Mandatory=$true)] [System.Management.Automation.PSCredential]$creds,
         [Parameter(Mandatory=$true)] [Microsoft.Azure.Commands.Network.Models.PSTopLevelResource]$vnet,
         [Parameter(Mandatory=$true)] [System.Object]$subnetId,
         [Parameter(Mandatory=$true)] [System.String]$nicName,
         [Parameter(Mandatory=$true)] [System.String]$publicIPName,
         [Parameter(Mandatory=$true)] [System.String]$privateIP,
         [Parameter(Mandatory=$true)] [Boolean]$enableForwarding
         )

####### Create a Public IP Address
$publicIP = New-AzPublicIpAddress `
           -Name $publicIPName `
           -ResourceGroupName $rgName `
           -Location $location `
           -AllocationMethod Dynamic `
           -Force

$publicIP = Get-AzPublicIpAddress  -Name $publicIPName -ResourceGroupName $rgName
write-host -foreground Yellow "Allocate a Public IP Address:" $publicIP.Name

####### Create a NIC -Attach each NIC to related Subnet
if ($enableForwarding)
{

$nic = New-AzNetworkInterface `
                -Name $nicName `
                -ResourceGroupName $rgName `
                -Location $location `
                -SubnetId $subnetId `
                -PublicIpAddressId $publicIP.Id `
                -PrivateIpAddress $privateIP `
                -EnableIPForwarding `
                -Force -Verbose 
} else {
$nic = New-AzNetworkInterface `
                -Name $nicName `
                -ResourceGroupName $rgName `
                -Location $location `
                -SubnetId $subnetId `
                -PublicIpAddressId $publicIP.Id `
                -PrivateIpAddress $privateIP `
                -Force -Verbose 
}

write-host -foreground Yellow "NIC              :" $nic.Name "has been created."

#######

try {
  $vm = Get-AzVM -Name $vmName -ResourceGroupName $rgName -ErrorAction Stop
  write-host -foreground Yellow "VM:" $vm.Name "already exists... skipping" -foregroundcolor Green -backgroundcolor Black
} catch {
  $vmConfig = New-AzVMConfig `
                       -VMName $vmName `
                       -VMSize $vmSize `
                       -Verbose

  $vmConfig = Set-AzVMOperatingSystem `
                       -VM $vmConfig  `
                       -Linux `
                       -ComputerName $vmName `
                       -Credential $creds `
                       -Verbose

  # set the name of the OS disk
  $diskName=$vmName+"-osDisk"
  $vmConfig = Set-AzVMOSDisk -VM  $vmConfig -CreateOption FromImage -Name $diskName -Linux 

  $vmConfig = Set-AzVMSourceImage `
                       -VM $vmConfig `
                       -PublisherName $script:publisherName `
                       -Offer $script:offerName `
                       -Skus $script:skuName `
                       -Version $script:version -Verbose 

  $vmConfig = Add-AzVMNetworkInterface `
                       -VM $vmConfig `
                       -Id $nic.Id `
                       -Primary 

  $vmConfig = Set-AzVMBootDiagnostics -VM $vmConfig -Disable -Verbose 

  New-AzVM -VM $vmConfig `
            -ResourceGroupName $rgName `
            -Location $location `
            -verbose
}



} # end function createAzVM()



######################### MAIN #################################
$pwd = ConvertTo-SecureString -String $adminPwd -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential( $adminName, $pwd);

# Select the Azure subscription
$subscr=Get-AzSubscription -SubscriptionName $subscriptionName
Select-AzSubscription -SubscriptionId $subscr.Id 


try {     
    Get-AzResourceGroup -Name $rgName -Location $location -ErrorAction Stop     
    Write-Host 'RG already exists... skipping' -foregroundcolor Green -backgroundcolor Black
} catch {     
    $rg = New-AzResourceGroup -Name $rgName -Location $location  -Force
}


for ($i=0; $i -lt $VNetArray.Length; $i++)
{
CreateVNet -rgName $VNetArray[$i].rgName `
           -location $VNetArray[$i].location `
           -vnetName $VNetArray[$i].vnetName `
           -vnetPrefix $VNetArray[$i].vnetPrefix `
           -subnet1Name $VNetArray[$i].subnet1Name `
           -subnet1Prefix $VNetArray[$i].subnet1Prexif `
           -subnet2Name $VNetArray[$i].subnet2Name `
           -subnet2Prefix $VNetArray[$i].subnet2Prexif 
}



#create an emty array
$vmArray = @( )

for ($i=0; $i -lt $vmArrayName.Length; $i++)
{
  $vnet = Get-AzVirtualNetwork -ResourceGroupName $vmArrayName[$i].rgName -Name $vmArrayName[$i].vnetName
  $subnetId=(Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $vmArrayName[$i].subnetName).Id
  $vmArray +=([pscustomobject]@{ vmName=$vmArrayName[$i].vmName; nicName=$vmArrayName[$i].nicName; publicIPName=$vmArrayName[$i].publicIPName; privateIP=$vmArrayName[$i].privateIP; vnet=$vnet; subnetId=$subnetId;enableForwarding=$vmArrayName[$i].enableForwarding})
}

<#
Write-Host -ForegroundColor Yellow "----------------------------------------------------"
for ($i=0; $i -lt $vmArray.Length; $i++)
{
   
   Write-Host -ForegroundColor Cyan $vmArray[$i].vmName
   Write-Host -ForegroundColor Cyan $vmArray[$i].nicName
   Write-Host -ForegroundColor Cyan $vmArray[$i].publicIPName
   Write-Host -ForegroundColor Cyan $vmArray[$i].privateIP 
   Write-Host -ForegroundColor Cyan $vmArray[$i].vnet 
   Write-Host -ForegroundColor Cyan $vmArray[$i].subnetId
   Write-Host -ForegroundColor Cyan $vmArray[$i].enableForwarding
   Write-Host -ForegroundColor Yellow "----------------------------------------------------"
}
#>

for ($i=0; $i -lt $vmArray.Length; $i++)
{
$runTime=Measure-Command {

try {
   Get-AzVM -ResourceGroupName $rgName -Name $vmArray[$i].vmName -ErrorAction Stop | Out-Null
   Write-Host 'VM:'$vmArray[$i].vmName' exists, skipping' -ForegroundColor Yellow -BackgroundColor Black
} catch { 
  createAzVM -rgName $rgName `
           -location $location `
           -vmname $vmArray[$i].vmName `
           -vmSize $vmSize `
           -creds $creds `
           -vnet $vmArray[$i].vnet `
           -subnetId $vmArray[$i].subnetId `
           -nicName $vmArray[$i].nicName  `
           -publicIPName $vmArray[$i].publicIPName `
           -privateIP $vmArray[$i].privateIP `
           -enableForwarding  $vmArray[$i].enableForwarding
} ### end try/catch

} ### end Measure-Command

write-host -ForegroundColor Yellow $vmArray[$i].vmName" - runtime: "$runTime.ToString()"`n"
} ### end for loop


for ($i=0; $i -lt $VNetArray.Length; $i++)
{

try {
  $nsg=get-AzNetworkSecurityGroup -ResourceGroupName $VNetArray[$i].rgName -Location $VNetArray[$i].location -Name $VNetArray[$i].nsgName -ErrorAction Stop
  Write-Host 'NSG: '$VNetArray[$i].nsgName' already exists... skipping' -foregroundcolor  Green -backgroundcolor Black
}catch {
  # Create an inbound network security group rule for port 22
  $nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name nsgSSH-rule  -Protocol Tcp `
    -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 22 -Access Allow

  $nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name nsgRDP-rule  -Protocol Tcp `
    -Direction Inbound -Priority 1010 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 3389 -Access Allow

  # Create a network security group
  $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $VNetArray[$i].rgName -Location $VNetArray[$i].location `
       -Name $nsgName -SecurityRules $nsgRuleSSH,$nsgRuleRDP -Force
}
## associated NSG to a subnets
$vnet = Get-AzVirtualNetwork -ResourceGroupName $VNetArray[$i].rgName -Name $VNetArray[$i].vnetName -WarningAction SilentlyContinue
$subnet1 = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $VNetArray[$i].subnet1Name
$subnet2 = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $VNetArray[$i].subnet2Name
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $rgName -Name $nsgName
# Network security group nsgVNets cannot be attached to firewall subnet AzureFirewallSubnet. Use firewall rules instead.
$subnet1.NetworkSecurityGroup = $nsg
$subnet2.NetworkSecurityGroup = $nsg
Set-AzVirtualNetwork -VirtualNetwork $vnet

}

#### Create VNet peering
for ($i=0; $i -lt $VNetPeeringArray.Length; $i++)
{

try {
  $vnet1 = Get-AzVirtualNetwork -ResourceGroupName $VNetPeeringArray[$i].rg1Name -Name $VNetPeeringArray[$i].vnet1Name -ErrorAction Stop
  
}catch {
   Write-Host 'VNet: '$VNetPeeringArray[$i].vnet1Name' does not exists...' -foregroundcolor  Green -backgroundcolor Black
   Exit
}
try {
  $vnet2 = Get-AzVirtualNetwork -ResourceGroupName $VNetPeeringArray[$i].rg2Name -Name $VNetPeeringArray[$i].vnet2Name -ErrorAction Stop
  
}catch {
   Write-Host 'VNet: '$VNetPeeringArray[$i].vnet2Name' does not exists...' -foregroundcolor  Green -backgroundcolor Black
   Exit
}
try {
   Get-AzVirtualNetworkPeering `
        -ResourceGroupName $VNetPeeringArray[$i].rg1Name `
        -Name $VNetPeeringArray[$i].peeringName `
        -VirtualNetworkName $VNetPeeringArray[$i].vnet1Name -ErrorAction Stop
   Write-Host 'VNet peering: '$VNetPeeringArray[$i].peeringName' already exist...skipping' -foregroundcolor Green -backgroundcolor Black
}catch {
   Add-AzVirtualNetworkPeering `
        -Name $VNetPeeringArray[$i].peeringName `
        -VirtualNetwork $vnet1 `
        -RemoteVirtualNetworkId $vnet2.Id -AllowForwardedTraffic 
   Write-Host 'Create VNet peering: '$VNetPeeringArray[$i].peeringName -foregroundcolor  Green -backgroundcolor Black
}

} ### end for



## Create routing tables 
try {
  $rt=Get-AzRouteTable -ResourceGroupName $rgName -Name $rtName_dc1 -ErrorAction Stop 
  Write-Host 'route table: '$rtName_dc1' already exist...skipping' -foregroundcolor Green -backgroundcolor Black
} catch {
    ## Create a route table
   $rt_dc1 = New-AzRouteTable `
     -Name $rtName_dc1 `
     -ResourceGroupName $rgName `
     -location $location

    $rt_dc1=Get-AzRouteTable -ResourceGroupName $rgName -Name $rtName_dc1

    ## Add route entries to the routing table
    foreach ($rtArray in $rtArray_dc1)
    {
      Add-AzRouteConfig `
        -Name $rtArray.name `
        -AddressPrefix $rtArray.addressPrefix `
        -NextHopType $rtArray.nextHopType `
        -NextHopIpAddress $rtArray.nextHopIpAddress`
        -RouteTable $rt_dc1 
    }
    Set-AzRouteTable -RouteTable $rt_dc1 
}

try {
  $rt=Get-AzRouteTable -ResourceGroupName $rgName -Name $rtName_dc2 -ErrorAction Stop 
  Write-Host 'route table: '$rtName_dc2' already exists...skipping' -foregroundcolor Green -backgroundcolor Black
} catch {
    ## Create a route table
   $rt_dc2 = New-AzRouteTable `
     -Name $rtName_dc2 `
     -ResourceGroupName $rgName `
     -location $location

    ## Add route entries to the routing table
    foreach ($rtArray in $rtArray_dc2)
    {
       Add-AzRouteConfig `
        -Name $rtArray.name `
        -AddressPrefix $rtArray.addressPrefix `
        -NextHopType $rtArray.nextHopType `
        -NextHopIpAddress $rtArray.nextHopIpAddress -RouteTable $rt_dc2
    }
    Set-AzRouteTable -RouteTable $rt_dc2 
}

## Associated to the routing tables to the subnets
foreach ($item in "dc1-vnet","dc2-vnet")
{
   # find out the index of array with VNet name specificed in the array
   $i=$VNetArray.vnetName.IndexOf($item)
   if ($i -ne -1)
   {
      $vnet = Get-AzVirtualNetwork -ResourceGroupName $VNetArray[$i].rgName -Name $VNetArray[$i].vnetName
      $subnet=Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $VNetArray[$i].subnet1Name
      $rt=$null
      $rt=Get-AzRouteTable -Name $VNetArray[$i].rtName -ResourceGroupName $rgName
      If ($null -eq $subnet.RouteTable) {
           $subnet.RouteTable=$rt  
           Set-AzVirtualNetwork -VirtualNetwork $vnet
      } Else {
          Write-Host -ForegroundColor Cyan 'route table: '$VNetArray[$i].rtName' is already assigned to vnet:'$vnet.Name'-subnet:'$subnet.Name', skipping'
      }
   }

} ### end loop
