###########################################
##
## - Create site1-vnet 
## - Create Cisco CSR in site1-vnet
## - Create a VM in subnet2
## - Set a UDR to force the traffic to the CSR interface connected to the subnet2
##
##  .\scriptName -adminUsername YOUR_USERNAME -adminPassword YOUR_PASSWORD
##
## Note
##  To run the script you need to accept the terms. Run one time in the target Azure subscription:
##  Get-AzMarketplaceTerms  -Publisher "cisco" -Product "cisco-csr-1000v"  -Name "csr-azure-byol" | Set-AzMarketplaceTerms -Accept
##   
## 
################# Input parameters #################
[CmdletBinding()]
param (
    [Parameter(Mandatory=$True, ValueFromPipeline=$false, HelpMessage='username administrator VMs', Position=0)]
    [string]$adminUsername,
 
    [Parameter(Mandatory = $true, HelpMessage='password administrator VMs', Position=1)]
    [string]$adminPassword
    )

###################### Variables ######################
$subscrName         = "AzDev"               # "Windows Azure MSDN - Visual Studio Ultimate"
$rgName             = "RG-site1"
$location           = "westeurope"    
$vnetName           = "site1-vnet"
$vnetPrefix         = @("10.1.10.0/24","10.1.11.0/24")
$subnet1Prefix      = "10.1.10.0/24"
$subnet2Prefix      = "10.1.11.0/24"
$subnet1Name        = "subnet1"   
$subnet2Name        = "subnet2"
##
$csr_adminName      = $adminUsername
$csr_adminPwd       = $adminPassword
$csr_Name           = "csr1"
$csr_publicIPName   = $csr_Name + "-pubIP"
$csr_nic1Name       = $csr_Name + "-NIC0"
$csr_nic2Name       = $csr_Name + "-NIC1"
$csr_privateIP1     = "10.1.10.5"
$csr_privateIP2     = "10.1.11.5"
$csr_publisherName  = "cisco"            
$csr_offerName      = "cisco-csr-1000v"  
$csr_skuName        = "csr-azure-byol"   
$csr_version        = "latest"
$csr_Size           = "Standard_B2ms"
##
$vmadminName        = $adminUsername
$vmadminPwd         = $adminPassword
$vm_Name            = "site1-vm"
$vm_publicIPName    = $vm_Name+"-pubIP"
$vm_nicName         = $vm_Name+"-NIC"
$vm_privateIP       = "10.1.11.10"
$vm_publicIPName    = $vm_Name + "-pubIP"
$vm_publisherName   = "openlogic"
$vm_offerName       = "CentOS"
$vm_skuName         = "7.5"
$vm_version         = "latest"
$vm_Size            = "Standard_B1s"
##
$nsgName            = "nsg"
$rtName             = "rt-csr"
#
#
################################################################
######################### MAIN #################################

$vmcsr = ConvertTo-SecureString -String $csr_adminPwd -AsPlainText -Force
$csr_creds = New-Object System.Management.Automation.PSCredential( $csr_adminName, $vmcsr);

$vmpwd = ConvertTo-SecureString -String $vmadminPwd -AsPlainText -Force
$vm_creds = New-Object System.Management.Automation.PSCredential( $vmadminName, $vmpwd);

## Select the Azure subscription
$subscr=Get-AzSubscription -SubscriptionName $subscrName
Select-AzSubscription -SubscriptionId $subscr.Id 

## check the resource group
try {     
    $rg=Get-AzResourceGroup -Name $rgName -Location $location -ErrorAction Stop     
    Write-Host 'RG already exists... skipping' -foregroundcolor Green -backgroundcolor Black
} catch {     
    $rg = New-AzResourceGroup -Name $rgName -Location $location  -Force
}


################# Create VNet
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

################# Create Cisco CSR ###################################################
####### Create a Public IP Address
try {
 $csr_publicIP = Get-AzPublicIpAddress  -Name $csr_publicIPName -ResourceGroupName $rgName -ErrorAction Stop
 } catch {
 $csr_publicIP = New-AzPublicIpAddress `
           -Name $csr_publicIPName `
           -ResourceGroupName $rgName `
           -Location $location `
           -AllocationMethod Static `
           -Force
}

write-host -foreground Yellow "CSR- Public IP Address:" $csr_publicIP.Name

$vnet = Get-AzVirtualNetwork -ResourceGroupName $rgName -Name $vnetName
$subnet1Id=$vnet.Subnets[0].Id
$subnet2Id=$vnet.Subnets[1].Id



####### Create a NIC and attach it to the subnet
try {
  $csr_nic1 = get-AzNetworkInterface `
                -Name $csr_nic1Name `
                -ResourceGroupName $rgName `
                -Location $location -ErrorAction Stop
} catch {
  $csr_nic1 = New-AzNetworkInterface `
                -Name $csr_nic1Name `
                -ResourceGroupName $rgName `
                -Location $location  `
                -SubnetId $subnet1Id `
                -PublicIpAddressId $csr_publicIP.Id `
                -PrivateIpAddress $csr_privateIP1 `
                -EnableIPForwarding `
                -Force -Verbose 
}
write-host -foreground Yellow "csr-NIC1         :" $csr_nic1.Name "has been created."

try {
$csr_nic2 = Get-AzNetworkInterface `
                -Name $csr_nic2Name `
                -ResourceGroupName $rgName `
                -Location $location -ErrorAction Stop
} catch {
$csr_nic2 = New-AzNetworkInterface `
                -Name $csr_nic2Name `
                -ResourceGroupName $rgName `
                -Location $location `
                -SubnetId $subnet2Id `
                -PrivateIpAddress $csr_privateIP2 `
                -EnableIPForwarding `
                -Force -Verbose 
}
write-host -foreground Yellow "csr-NIC2         :" $csr_nic2.Name "has been created."
##################################################################



try {
  $csr = Get-AzVM -Name $csr_Name -ResourceGroupName $rgName -ErrorAction Stop
  write-host -foreground Yellow "csr:" $csr_vm.Name "already exists... skipping" -foregroundcolor Green -backgroundcolor Black
} catch {
  $csr_Config = New-AzVMConfig       `
                       -VMName $csr_Name  `
                       -VMSize $csr_Size  `
                       -Verbose

   # set a plan in Azure marketplace
  Set-AzVMPlan -VM $csr_Config -Publisher $csr_publisherName -Product $csr_offerName -Name $csr_skuName

  $csr_Config = Set-AzVMOperatingSystem    `
                       -VM $csr_Config          `
                       -Linux                 `
                       -ComputerName $csr_Name  `
                       -Credential $csr_creds     `
                       -Verbose

  # set the name of the OS disk
  $csr_diskName=$csr_Name+"-osDisk"
  $csr_Config = Set-AzVMOSDisk -VM  $csr_Config -CreateOption FromImage -Name $csr_diskName -Linux 

  $csr_Config = Set-AzVMSourceImage `
                       -VM $csr_Config `
                       -PublisherName $csr_publisherName `
                       -Offer $csr_offerName `
                       -Skus $csr_skuName `
                       -Version $csr_version -Verbose 

  $csr_Config = Add-AzVMNetworkInterface `
                       -VM $csr_Config `
                       -Id $csr_nic1.Id `
                       -Primary 

  $csr_Config = Add-AzVMNetworkInterface `
                       -VM $csr_Config `
                       -Id $csr_nic2.Id `
  #                     -Primary

  $csr_Config = Set-AzVMBootDiagnostics -VM $csr_Config -Disable -Verbose 

  $csr=New-AzVM -VM $csr_Config `
            -ResourceGroupName $rgName `
            -Location $location `
            -verbose

}

####################################################################


####################################################################
################# Create VM ########################################
####### Create a Public IP Address of the VM
try {
 $vm_publicIP = Get-AzPublicIpAddress  -Name $vm_publicIPName -ResourceGroupName $rgName -ErrorAction Stop
 } catch {
 $vm_publicIP = New-AzPublicIpAddress `
           -Name $vm_publicIPName `
           -ResourceGroupName $rgName `
           -Location $location `
           -AllocationMethod Dynamic `
           -Force
}

write-host -foreground Yellow "VM- Public IP Address:" $vm_publicIP.Name

$vnet = Get-AzVirtualNetwork -ResourceGroupName $rgName -Name $vnetName
$subnet1Id=$vnet.Subnets[0].Id
$subnet2Id=$vnet.Subnets[1].Id

####### Create a NIC for the VM
try {
  $vm_nic = get-AzNetworkInterface `
                -Name $vm_nicName `
                -ResourceGroupName $rgName `
                -Location $location -ErrorAction Stop
} catch {
  $vm_nic = New-AzNetworkInterface `
                -Name $vm_nicName `
                -ResourceGroupName $rgName `
                -Location $location  `
                -SubnetId $subnet2Id `
                -PublicIpAddressId $vm_publicIP.Id `
                -PrivateIpAddress $vm_privateIP `
                -Force -Verbose 
}
write-host -foreground Yellow "vm-NIC          :" $vm_nic1.Name "has been created."


try {
  $vm = Get-AzVM -Name $vm_Name -ResourceGroupName $rgName -ErrorAction Stop
  write-host -foreground Yellow "vm:" $vm.Name "already exists... skipping" -foregroundcolor Green -backgroundcolor Black
} catch {
  $vm_Config = New-AzVMConfig `
                       -VMName $vm_Name `
                       -VMSize $vm_Size `
                       -Verbose

  $vm_Config = Set-AzVMOperatingSystem `
                       -VM $vm_Config `
                       -Linux `
                       -ComputerName $vm_Name `
                       -Credential $vm_creds `
                       -Verbose

  # set the name of the OS disk
  $vm_diskName=$vm_Name+"-osDisk"
  $vm_Config = Set-AzVMOSDisk -VM  $vm_Config -CreateOption FromImage -Name $vm_diskName -Linux 

  $vm_Config = Set-AzVMSourceImage `
                       -VM $vm_Config `
                       -PublisherName $vm_publisherName `
                       -Offer $vm_offerName `
                       -Skus $vm_skuName `
                       -Version $vm_version -Verbose 

  $vm_Config = Add-AzVMNetworkInterface `
                       -VM $vm_Config `
                       -Id $vm_nic.Id `
                       -Primary 

  $vm_Config = Set-AzVMBootDiagnostics -VM $vm_Config -Disable -Verbose 

  $vm=New-AzVM -VM $vm_Config `
            -ResourceGroupName $rgName `
            -Location $location `
            -verbose
}

# create the nsg
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
$vnet = Get-AzVirtualNetwork -ResourceGroupName $rgName -Name $vnetName -WarningAction SilentlyContinue
$subnet1 = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnet1Name
$subnet2 = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnet2Name
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $rgName -Name $nsgName
#
# $subnet1.NetworkSecurityGroup = $nsg
$subnet2.NetworkSecurityGroup = $nsg
Set-AzVirtualNetwork -VirtualNetwork $vnet

# create the static route

Try {$rt = Get-AzRouteTable -Name $rtName -ResourceGroupName $rgName -ErrorAction Stop
     Write-Host "  $rtName route table exists, skipping"}
Catch {
   $rt = New-AzRouteTable -Name $rtName -ResourceGroupName $rgName -location $location
   $rt = Get-AzRouteTable -ResourceGroupName $rgName -Name $rtName | `
                Add-AzRouteConfig -Name "remoteNetworks" -AddressPrefix "10.0.0.0/8" -NextHopType "VirtualAppliance" -NextHopIpAddress $csr_privateIP2 
   Set-AzRouteTable -RouteTable $rt 
   }

# set the route table to the subnet2
try {
$vnet = Get-AzVirtualNetwork -ResourceGroupName $rgName -Name $vnetName -WarningAction SilentlyContinue
$subnet2 = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnet2Name
$subnet2.RouteTable= $rt
Set-AzVirtualNetwork -VirtualNetwork $vnet
} catch {
       Write-Warning 'Assigning route tables to subnet failed. Please review the script'
       Return
}