###########################################
#  
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
##
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

### Variables
$subscriptionName= "Windows Azure MSDN - Visual Studio Ultimate"
$rgName          = "RG-spokes"
$location        = "westcentralus"    
$vnet1Name       = "spoke1-vnet"
$vnet1Prefix     = @("10.0.10.0/24","10.0.11.0/24")
$subnet11Name    = "subnet1"
$subnet11Prexif  = "10.0.10.0/24"
$subnet12Name    = "subnet2"
$subnet12Prexif  = "10.0.11.0/24"
#
$vnet2Name       = "spoke2-vnet"
$vnet2Prefix     = @("10.0.20.0/24","10.0.21.0/24")
$subnet21Name    = "subnet1"
$subnet21Prexif  = "10.0.20.0/24"
$subnet22Name    = "subnet2"
$subnet22Prexif  = "10.0.21.0/24"
#
## VMs
$vmName11        = "spoke1-vm1"
$vmName12        = "spoke1-vm2"
$vmName21        = "spoke2-vm1"
$vmName22        = "spoke2-vm2"
$privIP_vm11     = "10.0.10.10"
$privIP_vm12     = "10.0.11.10"
$privIP_vm21     = "10.0.20.10"
$privIP_vm22     = "10.0.21.10"
#
$adminName       = $adminUsername
$adminPwd        = $adminPassword
$publisherName   = "openlogic"
$offerName       = "CentOS"
$skuName         = "7.5"
$version         = "latest"
$vmSize          = "Standard_B1s"    # "Standard_DS1_v2"
$nsgName         = "nsgVNets"
#
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
    $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnetName -ErrorAction Stop -WarningAction SilentlyContinue
    Write-Host 'VNet '$vnetName' already exists... skipping' -foregroundcolor Green -backgroundcolor Black
} catch {  
    $vnet = New-AzureRmVirtualNetwork -Name $vnetName          `
                                  -ResourceGroupName $rgName   `
                                  -Location $location          `
                                  -AddressPrefix $vnetPrefix   `
                                  -Verbose -Force -WarningAction SilentlyContinue
    $subnet1 = Add-AzureRmVirtualNetworkSubnetConfig -Name $subnet1Name -AddressPrefix $subnet1Prefix -VirtualNetwork $vnet -WarningAction SilentlyContinue
    $subnet2 = Add-AzureRmVirtualNetworkSubnetConfig -Name $subnet2Name -AddressPrefix $subnet2Prefix -VirtualNetwork $vnet -WarningAction SilentlyContinue
    Set-AzureRmVirtualNetwork -VirtualNetwork $vnet -WarningAction SilentlyContinue
}

write-host -ForegroundColor Yellow "VNet              : " $vnet.Name
write-host -ForegroundColor Yellow "VNet Address Space: " $vnet.AddressSpace.AddressPrefixes  
for($i=0;$i-le $vnet.Subnets.Count-1;$i++)
{
     $subnet=Get-AzureRmVirtualNetworkSubnetConfig -Name $vnet.Subnets[$i].Name -VirtualNetwork $vnet -WarningAction SilentlyContinue
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
$publicIP = New-AzureRmPublicIpAddress   `
           -Name $publicIPName          `
           -ResourceGroupName $rgName    `
           -Location $location           `
           -AllocationMethod Dynamic     `
           -Force

$publicIP = Get-AzureRmPublicIpAddress  -Name $publicIPName -ResourceGroupName $rgName
write-host -foreground Yellow "Allocate a Public IP Address:" $publicIP.Name


#######
####### Create a NIC -Attach each NIC to related Subnet
if ($enableForwarding)
{

$nic = New-AzureRmNetworkInterface `
                -Name $nicName `
                -ResourceGroupName $rgName `
                -Location $location  `
                -SubnetId $subnetId  `
                -PublicIpAddressId $publicIP.Id `
                -PrivateIpAddress $privateIP `
                -EnableIPForwarding `
                -Force -Verbose 
} else {
$nic = New-AzureRmNetworkInterface `
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
  $vm = Get-AzureRmVM -Name $vmName -ResourceGroupName $rgName -ErrorAction Stop
  write-host -foreground Yellow "VM:" $vm.Name "already exists... skipping" -foregroundcolor Green -backgroundcolor Black
} catch {
  $vmConfig = New-AzureRmVMConfig `
                       -VMName $vmName `
                       -VMSize $vmSize `
                       -Verbose

  $vmConfig = Set-AzureRmVMOperatingSystem `
                       -VM $vmConfig  `
                       -Linux `
                       -ComputerName $vmName `
                       -Credential $creds `
                       -Verbose

  # set the name of the OS disk
  $diskName=$vmName+"-osDisk"
  $vmConfig = Set-AzureRmVMOSDisk -VM  $vmConfig -CreateOption FromImage -Name $diskName -Linux 

  $vmConfig = Set-AzureRmVMSourceImage `
                       -VM $vmConfig  `
                       -PublisherName $script:publisherName `
                       -Offer $script:offerName `
                       -Skus $script:skuName `
                       -Version $script:version -Verbose 

  $vmConfig = Add-AzureRmVMNetworkInterface `
                       -VM $vmConfig `
                       -Id $nic.Id `
                       -Primary 

  $vmConfig = Set-AzureRmVMBootDiagnostics -VM $vmConfig -Disable -Verbose 

  New-AzureRmVM -VM $vmConfig `
            -ResourceGroupName $rgName `
            -Location $location `
            -verbose
}

} # end function createAzVM()



######################### MAIN #################################
$pwd = ConvertTo-SecureString -String $adminPwd -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential( $adminName, $pwd);

# Select the Azure subscription
$subscr=Get-AzureRmSubscription -SubscriptionName $subscriptionName
Select-AzureRmSubscription -SubscriptionId $subscr.Id 


try {     
    Get-AzureRmResourceGroup -Name $rgName -Location $location -ErrorAction Stop     
    Write-Host 'RG already exists... skipping' -foregroundcolor Green -backgroundcolor Black
} catch {     
    $rg = New-AzureRmResourceGroup -Name $rgName -Location $location  -Force
}


## Create VNet
$VNetArray = @( 
              [pscustomobject]@{ rgName=$rgName; location=$location; vnetName=$vnet1Name; vnetPrefix=$vnet1Prefix; subnet1Name=$subnet11Name; subnet1Prefix=$subnet11Prexif;subnet2Name=$subnet12Name; subnet2Prefix=$subnet12Prexif},
              [pscustomobject]@{ rgName=$rgName; location=$location; vnetName=$vnet2Name; vnetPrefix=$vnet2Prefix; subnet1Name=$subnet21Name; subnet1Prefix=$subnet21Prexif;subnet2Name=$subnet22Name; subnet2Prefix=$subnet22Prexif}
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
$vnet1 = Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnet1Name -WarningAction SilentlyContinue
$vnet2 = Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnet2Name -WarningAction SilentlyContinue

$vmArray = @( 
        [pscustomobject]@{ vmName=$vmName11; nicName=$vmName11+"-nic"; publicIPName=$vmName11+"-pubIP"; privateIP=$privIP_vm11; vnet=$vnet1; subnetId=$vnet1.Subnets[0].Id;enableForwarding=$false}, 
        [pscustomobject]@{ vmName=$vmName12; nicName=$vmName12+"-nic"; publicIPName=$vmName12+"-pubIP"; privateIP=$privIP_vm12; vnet=$vnet1; subnetId=$vnet1.Subnets[1].Id;enableForwarding=$false}, 
        [pscustomobject]@{ vmName=$vmName21; nicName=$vmName21+"-nic"; publicIPName=$vmName21+"-pubIP"; privateIP=$privIP_vm21; vnet=$vnet2; subnetId=$vnet2.Subnets[0].Id;enableForwarding=$false},
        [pscustomobject]@{ vmName=$vmName22; nicName=$vmName22+"-nic"; publicIPName=$vmName22+"-pubIP"; privateIP=$privIP_vm22; vnet=$vnet2; subnetId=$vnet2.Subnets[1].Id;enableForwarding=$false}
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
  $nsg=get-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Location $location -Name $nsgName -ErrorAction Stop
  Write-Host 'NSG: '$nsgName' already exists... skipping' -foregroundcolor  Green -backgroundcolor Black
}catch {
  # Create an inbound network security group rule for port 22
  $nsgRuleSSH = New-AzureRmNetworkSecurityRuleConfig -Name nsgSSH-rule  -Protocol Tcp `
    -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 22 -Access Allow

  $nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name nsgRDP-rule  -Protocol Tcp `
    -Direction Inbound -Priority 1010 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 3389 -Access Allow

  # Create a network security group
  $nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Location $location `
       -Name $nsgName -SecurityRules $nsgRuleSSH,$nsgRuleRDP -Tag $tag -Force
}
## associated NSG to a subnets
$vnet1 = Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnet1Name -WarningAction SilentlyContinue
$subnet11 = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet1 -Name $subnet11Name
$subnet12 = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet1 -Name $subnet12Name
$nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Name $nsgName
# Network security group nsgVNets cannot be attached to firewall subnet AzureFirewallSubnet. Use firewall rules instead.
$subnet11.NetworkSecurityGroup = $nsg
$subnet12.NetworkSecurityGroup = $nsg
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet1
#
#
$vnet2 = Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnet2Name -WarningAction SilentlyContinue
$subnet21 = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet2 -Name $subnet21Name
$subnet22 = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet2 -Name $subnet22Name
$nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Name $nsgName
$subnet21.NetworkSecurityGroup = $nsg
$subnet22.NetworkSecurityGroup = $nsg
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet2





