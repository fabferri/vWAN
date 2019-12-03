###########################################
# - Create a Resource Group
# - Create a spoke1-vnet with subnet1 and subnet2
# - Create a spoke2-vnet with subnet1 and subnet2
# - spoke1-vnet: Create a VM attached to subnet1
# - spoke1-vnet: Create a VM attached to subnet2
# - spoke2-vnet: Create a VM attached to subnet1
# - spoke2-vnet: Create a VM attached to subnet2
# - Create a NSG
# - Associate the NSG to the subnets in spoke1-vnet
# - Associate the NSG to the subnets in spoke1-vnet 
#
###########################################
##   Run the script by command:
##  .\scriptName -adminUsername YOUR_USERNAME -adminPassword YOUR_PASSWORD
##
################# Input parameters ########
### Variables
$subscriptionName= "AzDev"                             # name of the Azure subscription
$rgName          = "rg-vwan1-spokes"                   # name of the resource group to deploye the spoke VNets
$location        = "eastus"                            # Azure location of spoke VNets
#  
$vnet1Name       = "spoke1-vnet"                       # name of the spoke1 VNet
$vnet1Prefix     = @("10.0.10.0/24","10.0.11.0/24")    # address space of the first spoke VNet
$subnet11Name    = "subnet1"                           # name of the subnet1 in spoke1 VNet
$subnet11Prexif  = "10.0.10.0/24"                      # address prefix assigned to the subnet1 of spoke1 VNet
$subnet12Name    = "subnet2"                           # name of the subnet2 in spoke1 VNet
$subnet12Prexif  = "10.0.11.0/24"                      # address prefix assigned to the subnet1 of spoke1 VNet
#
$vnet2Name       = "spoke2-vnet"                       # name of the spoke2 VNet
$vnet2Prefix     = @("10.0.20.0/24","10.0.21.0/24")    # address space of the second spoke VNet
$subnet21Name    = "subnet1"                           # name of the subnet1 in spoke2 VNet
$subnet21Prexif  = "10.0.20.0/24"                      # address prefix assigned to the subnet1 of spoke2 VNet
$subnet22Name    = "subnet2"                           # name of the subnet2 in spoke2 VNet
$subnet22Prexif  = "10.0.21.0/24"                      # address prefix assigned to the subnet2 of spoke2 VNet
#
$vnet3Name       = "spoke3-vnet"                       # name of the spoke3 VNet
$vnet3Prefix     = @("10.0.30.0/24","10.0.31.0/24")    # address space of the second spoke VNet
$subnet31Name    = "subnet1"                           # name of the subnet1 in spoke3 VNet
$subnet31Prexif  = "10.0.30.0/24"                      # address space assigned to the subnet1 of spoke2 VNet
$subnet32Name    = "subnet2"                           # name of the subnet2 in spoke3 VNet
$subnet32Prexif  = "10.0.31.0/24"                      # address prefix assigned to the subnet2 of spoke3 VNet
## VMs
$vmName11        = "spoke1-vm1"                       # name of the VM attached to the subnet1 of the spoke1 VNet
$vmName21        = "spoke2-vm1"                       # name of the VM attached to the subnet1 of the spoke2 VNet
$vmName31        = "spoke3-vm1"                       # name of the VM attached to the subnet2 of the spoke2 VNet
$privIP_vm11     = "10.0.10.10"                       # private IP assigned to VM attached to the subnet1 of the spoke1 VNet
$privIP_vm21     = "10.0.20.10"                       # private IP assigned to VM attached to the subnet1 of the spoke2 VNet
$privIP_vm31     = "10.0.30.10"                       # private IP assigned to VM attached to the subnet2 of the spoke2 VNet
#

$publisherName   = "openlogic"                        # publisher of linux VMs
$offerName       = "CentOS"                           # linux VM distro
$skuName         = "7.6"                              # linux VM version
$version         = "latest"
$vmSize          = "Standard_B1ls"                    # size of the VM
$nsgName         = "nsg1"                             # name of the network security group asociated with the subnets
#
#

### getting administrator username and administrator password from init.txt file
$pathFiles      = Split-Path -Parent $PSCommandPath
If (Test-Path -Path $pathFiles\init.txt) {
        Get-Content $pathFiles\init.txt | Foreach-Object{
        $var = $_.Split('=')
        Try {New-Variable -Name $var[0].Trim() -Value $var[1].Trim() -ErrorAction Stop}
        Catch {Set-Variable -Name $var[0].Trim() -Value $var[1].Trim()}}}
Else {Write-Warning "init.txt file not found, please change to the directory where these scripts reside ($pathFiles) and ensure this file is present.";Return}
$adminName       = $adminUsername                     # administrator username of the VMs
$adminPwd        = $adminPassword                     # administrator password of the VMs



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
    $vnet = New-AzVirtualNetwork -Name $vnetName          `
                                  -ResourceGroupName $rgName   `
                                  -Location $location          `
                                  -AddressPrefix $vnetPrefix   `
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

} #end function CreateVNet
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
$publicIP = New-AzPublicIpAddress   `
           -Name $publicIPName          `
           -ResourceGroupName $rgName    `
           -Location $location           `
           -AllocationMethod Dynamic     `
           -Force

$publicIP = Get-AzPublicIpAddress  -Name $publicIPName -ResourceGroupName $rgName
write-host -foreground Yellow "Allocate a Public IP Address:" $publicIP.Name


#######
####### Create a NIC -Attach each NIC to related Subnet
if ($enableForwarding)
{

$nic = New-AzNetworkInterface `
                -Name $nicName `
                -ResourceGroupName $rgName `
                -Location $location  `
                -SubnetId $subnetId  `
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

write-host -foreground Yellow "NIC            :" $nic.Name "has been created."

##################################################################



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
                       -VM $vmConfig  `
                       -PublisherName $script:publisherName `
                       -Offer $script:offerName `
                       -Skus $script:skuName `
                       -Version $script:version -Verbose 

  $vmConfig = Add-AzVMNetworkInterface `
                       -VM $vmConfig `
                       -Id $nic.Id `
                       -Primary 

  $vmConfig = Set-AzVMBootDiagnostic -VM $vmConfig -Disable -Verbose 

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


## Create VNet
$VNetArray = @( 
              [pscustomobject]@{ rgName=$rgName; location=$location; vnetName=$vnet1Name; vnetPrefix=$vnet1Prefix; subnet1Name=$subnet11Name; subnet1Prefix=$subnet11Prexif;subnet2Name=$subnet12Name; subnet2Prefix=$subnet12Prexif},
              [pscustomobject]@{ rgName=$rgName; location=$location; vnetName=$vnet2Name; vnetPrefix=$vnet2Prefix; subnet1Name=$subnet21Name; subnet1Prefix=$subnet21Prexif;subnet2Name=$subnet22Name; subnet2Prefix=$subnet22Prexif},
              [pscustomobject]@{ rgName=$rgName; location=$location; vnetName=$vnet3Name; vnetPrefix=$vnet3Prefix; subnet1Name=$subnet31Name; subnet1Prefix=$subnet31Prexif;subnet2Name=$subnet32Name; subnet2Prefix=$subnet32Prexif}
              )

for ($i=0; $i -lt $VNetArray.Length; $i++)
{
CreateVNet -rgName $VNetArray[$i].rgName `
           -location $VNetArray[$i].location `
           -vnetName $VNetArray[$i].vnetName `
           -vnetPrefix $VNetArray[$i].vnetPrefix `
           -subnet1Name $VNetArray[$i].subnet1Name `
           -subnet1Prefix $VNetArray[$i].subnet1Prefix `
           -subnet2Name $VNetArray[$i].subnet2Name `
           -subnet2Prefix $VNetArray[$i].subnet2Prefix 
}




## Create VMs
$vnet1 = Get-AzVirtualNetwork -ResourceGroupName $rgName -Name $vnet1Name -WarningAction SilentlyContinue
$vnet2 = Get-AzVirtualNetwork -ResourceGroupName $rgName -Name $vnet2Name -WarningAction SilentlyContinue
$vnet3 = Get-AzVirtualNetwork -ResourceGroupName $rgName -Name $vnet3Name -WarningAction SilentlyContinue

$vmArray = @( 
        [pscustomobject]@{ vmName=$vmName11; nicName=$vmName11+"-nic"; publicIPName=$vmName11+"-pubIP"; privateIP=$privIP_vm11; vnet=$vnet1; subnetId=$vnet1.Subnets[0].Id;enableForwarding=$false}, 
        [pscustomobject]@{ vmName=$vmName21; nicName=$vmName21+"-nic"; publicIPName=$vmName21+"-pubIP"; privateIP=$privIP_vm21; vnet=$vnet2; subnetId=$vnet2.Subnets[0].Id;enableForwarding=$false},
        [pscustomobject]@{ vmName=$vmName31; nicName=$vmName31+"-nic"; publicIPName=$vmName31+"-pubIP"; privateIP=$privIP_vm31; vnet=$vnet3; subnetId=$vnet3.Subnets[0].Id;enableForwarding=$false}
             )



for ($i=0; $i -lt $vmArray.Length; $i++)
{
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
}

try {
  $nsg=get-AzNetworkSecurityGroup -ResourceGroupName $rgName -Location $location -Name $nsgName -ErrorAction Stop
  Write-Host 'NSG: '$nsgName' already exists... skipping' -foregroundcolor  Green -backgroundcolor Black
}catch {
  # Create an inbound network security group rule for port 22
  $nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name nsgSSH-rule  -Protocol Tcp `
    -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 22 -Access Allow

  $nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name nsgRDP-rule  -Protocol Tcp `
    -Direction Inbound -Priority 1010 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 3389 -Access Allow

  # Create a network security group
  $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $rgName -Location $location `
       -Name $nsgName -SecurityRules $nsgRuleSSH,$nsgRuleRDP -Tag $tag -Force
}
## associated NSG to a subnets
$vnet1 = Get-AzVirtualNetwork -ResourceGroupName $rgName -Name $vnet1Name -WarningAction SilentlyContinue
$subnet11 = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet1 -Name $subnet11Name
$subnet12 = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet1 -Name $subnet12Name
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $rgName -Name $nsgName
# Network security group attached to the subnets.
$subnet11.NetworkSecurityGroup = $nsg
$subnet12.NetworkSecurityGroup = $nsg
Set-AzVirtualNetwork -VirtualNetwork $vnet1
#
#
$vnet2 = Get-AzVirtualNetwork -ResourceGroupName $rgName -Name $vnet2Name -WarningAction SilentlyContinue
$subnet21 = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet2 -Name $subnet21Name
$subnet22 = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet2 -Name $subnet22Name
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $rgName -Name $nsgName
$subnet21.NetworkSecurityGroup = $nsg
$subnet22.NetworkSecurityGroup = $nsg
Set-AzVirtualNetwork -VirtualNetwork $vnet2
#
#
$vnet3 = Get-AzVirtualNetwork -ResourceGroupName $rgName -Name $vnet3Name -WarningAction SilentlyContinue
$subnet31 = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet3 -Name $subnet31Name
$subnet32 = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet3 -Name $subnet32Name
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $rgName -Name $nsgName
$subnet31.NetworkSecurityGroup = $nsg
$subnet32.NetworkSecurityGroup = $nsg
Set-AzVirtualNetwork -VirtualNetwork $vnet3





