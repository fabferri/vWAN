##################################################################
##
##  Create multiple sites. 
##  - create a resouece group to deploy the site
##  - azure VNet with to two subnets 
##  - create Cisco CSR with two NICs: one in subnet1 and one in subnet2
##  - create a VM in subnet2
##  - set NSG to accept SSH connections
##  - ascoicate the NSG to the subnet2
##  - set a UDR in subnet2 to force the traffic with destination 10.0.0.0/8 to transit through the CSR
##
##  run the script bu command:
##  .\scriptName -adminUsername YOUR_USERNAME -adminPassword YOUR_PASSWORD
##
## Note
##  the script create Cisco CSR; to run the script you need to accept the terms license for the NVA. 
##  Run one time in the target Azure subscription the following command:
##  Get-AzMarketplaceTerms  -Publisher "cisco" -Product "cisco-csr-1000v"  -Name "csr-azure-byol" | Set-AzMarketplaceTerms -Accept
##   
## 
################# Input parameters ################################
[CmdletBinding()]
param (
    [Parameter(Mandatory=$True, ValueFromPipeline=$false, HelpMessage='username administrator VMs', Position=0)]
    [string]$adminUsername,
 
    [Parameter(Mandatory = $true, HelpMessage='password administrator VMs', Position=1)]
    [string]$adminPassword
    )

###################### Variables ######################
$subscrName= "AzDev"           # Name Azure subscription
$csr1_Name= "csr1"             # name of Cisco CSR in site1
$csr2_Name= "csr2"             # name of Cisco CSR in site2
$csr3_Name= "csr3"             # name of Cisco CSR in site3
$vm1_Name = "site1-vm"         # name of Cisco CSR in site1
$vm2_Name = "site2-vm"         # name of Cisco CSR in site2
$vm3_Name = "site3-vm"         # name of Cisco CSR in site3

# define list of sites in array of hash
# the array use the variable defined above.
#
$siteArray = @(
  @{
       rgName             = "RG-site1"
       location           = "westeurope"    
       vnetName           = "site1-vnet"
       vnetPrefix         = @("10.1.10.0/24","10.1.11.0/24")
       subnet1Prefix      = "10.1.10.0/24"
       subnet2Prefix      = "10.1.11.0/24"
       subnet1Name        = "subnet1"   
       subnet2Name        = "subnet2"
       csr_adminName      = $adminUsername
       csr_adminPwd       = $adminPassword
       csr_Name           = $csr1_Name
       csr_publicIPName   = $csr1_Name + "-pubIP"
       csr_nic1Name       = $csr1_Name + "-NIC0"
       csr_nic2Name       = $csr1_Name + "-NIC1"
       csr_privateIP1     = "10.1.10.5"
       csr_privateIP2     = "10.1.11.5"
       csr_publisherName  = "cisco"            
       csr_offerName      = "cisco-csr-1000v"  
       csr_skuName        = "csr-azure-byol"   
       csr_version        = "latest"
       csr_Size           = "Standard_B2ms"
       vmadminName        = $adminUsername
       vmadminPwd         = $adminPassword
       vm_Name            = $vm1_Name
       vm_publicIPName    = $vm1_Name+"-pubIP"
       vm_nicName         = $vm1_Name+"-NIC"
       vm_privateIP       = "10.1.11.10"
       vm_publisherName   = "openlogic"
       vm_offerName       = "CentOS"
       vm_skuName         = "7.5"
       vm_version         = "latest"
       vm_Size            = "Standard_B1s"
       nsgName            = "nsg"
       rtName             = "rt-csr"
   },
  @{
       rgName             = "RG-site2"
       location           = "westeurope"    
       vnetName           = "site2-vnet"
       vnetPrefix         = @("10.1.20.0/24","10.1.21.0/24")
       subnet1Prefix      = "10.1.20.0/24"
       subnet2Prefix      = "10.1.21.0/24"
       subnet1Name        = "subnet1"   
       subnet2Name        = "subnet2"
       csr_adminName      = $adminUsername
       csr_adminPwd       = $adminPassword
       csr_Name           = $csr2_Name
       csr_publicIPName   = $csr2_Name + "-pubIP"
       csr_nic1Name       = $csr2_Name + "-NIC0"
       csr_nic2Name       = $csr2_Name + "-NIC1"
       csr_privateIP1     = "10.1.20.5"
       csr_privateIP2     = "10.1.21.5"
       csr_publisherName  = "cisco"            
       csr_offerName      = "cisco-csr-1000v"  
       csr_skuName        = "csr-azure-byol"   
       csr_version        = "latest"
       csr_Size           = "Standard_B2ms"
       vmadminName        = $adminUsername
       vmadminPwd         = $adminPassword
       vm_Name            = $vm2_Name
       vm_publicIPName    = $vm2_Name+"-pubIP"
       vm_nicName         = $vm2_Name+"-NIC"
       vm_privateIP       = "10.1.21.10"
       vm_publisherName   = "openlogic"
       vm_offerName       = "CentOS"
       vm_skuName         = "7.5"
       vm_version         = "latest"
       vm_Size            = "Standard_B1s"
       nsgName            = "nsg"
       rtName             = "rt-csr"
   },
   @{
       rgName             = "RG-site3"
       location           = "westeurope"    
       vnetName           = "site3-vnet"
       vnetPrefix         = @("10.1.30.0/24","10.1.31.0/24")
       subnet1Prefix      = "10.1.30.0/24"
       subnet2Prefix      = "10.1.31.0/24"
       subnet1Name        = "subnet1"   
       subnet2Name        = "subnet2"
       csr_adminName      = $adminUsername
       csr_adminPwd       = $adminPassword
       csr_Name           = $csr3_Name
       csr_publicIPName   = $csr3_Name + "-pubIP"
       csr_nic1Name       = $csr3_Name + "-NIC0"
       csr_nic2Name       = $csr3_Name + "-NIC1"
       csr_privateIP1     = "10.1.30.5"
       csr_privateIP2     = "10.1.31.5"
       csr_publisherName  = "cisco"            
       csr_offerName      = "cisco-csr-1000v"  
       csr_skuName        = "csr-azure-byol"   
       csr_version        = "latest"
       csr_Size           = "Standard_B2ms"
       vmadminName        = $adminUsername
       vmadminPwd         = $adminPassword
       vm_Name            = $vm3_Name
       vm_publicIPName    = $vm3_Name+"-pubIP"
       vm_nicName         = $vm3_Name+"-NIC"
       vm_privateIP       = "10.1.31.10"
       vm_publisherName   = "openlogic"
       vm_offerName       = "CentOS"
       vm_skuName         = "7.5"
       vm_version         = "latest"
       vm_Size            = "Standard_B1s"
       nsgName            = "nsg"
       rtName             = "rt-csr"
   }
)

#
#
################################################################
######################### MAIN #################################
## Select the Azure subscription
$subscr=Get-AzSubscription -SubscriptionName $subscrName
Select-AzSubscription -SubscriptionId $subscr.Id 



function CreateAllSite{
Param(
    [Parameter(Mandatory=$true)] [System.String]$rgName,
    [Parameter(Mandatory=$true)] [System.String]$location,
    [Parameter(Mandatory=$true)] [System.String]$vnetName,
    [Parameter(Mandatory=$true)] [System.String[]]$vnetPrefix,
    [Parameter(Mandatory=$true)] [System.String]$subnet1Prefix,
    [Parameter(Mandatory=$true)] [System.String]$subnet2Prefix,
    [Parameter(Mandatory=$true)] [System.String]$subnet1Name,
    [Parameter(Mandatory=$true)] [System.String]$subnet2Name,
    [Parameter(Mandatory=$true)] [System.String]$csr_adminName,
    [Parameter(Mandatory=$true)] [System.String]$csr_adminPwd,
    [Parameter(Mandatory=$true)] [System.String]$csr_Name,
    [Parameter(Mandatory=$true)] [System.String]$csr_publicIPName,
    [Parameter(Mandatory=$true)] [System.String]$csr_nic1Name,
    [Parameter(Mandatory=$true)] [System.String]$csr_nic2Name,
    [Parameter(Mandatory=$true)] [System.String]$csr_privateIP1,
    [Parameter(Mandatory=$true)] [System.String]$csr_privateIP2,
    [Parameter(Mandatory=$true)] [System.String]$csr_publisherName,
    [Parameter(Mandatory=$true)] [System.String]$csr_offerName,
    [Parameter(Mandatory=$true)] [System.String]$csr_skuName,
    [Parameter(Mandatory=$true)] [System.String]$csr_version,
    [Parameter(Mandatory=$true)] [System.String]$csr_Size,
    [Parameter(Mandatory=$true)] [System.String]$vmadminName,
    [Parameter(Mandatory=$true)] [System.String]$vmadminPwd,
    [Parameter(Mandatory=$true)] [System.String]$vm_Name,
    [Parameter(Mandatory=$true)] [System.String]$vm_publicIPName,
    [Parameter(Mandatory=$true)] [System.String]$vm_nicName,
    [Parameter(Mandatory=$true)] [System.String]$vm_privateIP,
    [Parameter(Mandatory=$true)] [System.String]$vm_publisherName,
    [Parameter(Mandatory=$true)] [System.String]$vm_offerName,
    [Parameter(Mandatory=$true)] [System.String]$vm_skuName,
    [Parameter(Mandatory=$true)] [System.String]$vm_version,
    [Parameter(Mandatory=$true)] [System.String]$vm_Size,
    [Parameter(Mandatory=$true)] [System.String]$nsgName,
    [Parameter(Mandatory=$true)] [System.String]$rtName
)


$vmcsr = ConvertTo-SecureString -String $csr_adminPwd -AsPlainText -Force
$csr_creds = New-Object System.Management.Automation.PSCredential( $csr_adminName, $vmcsr);

$vmpwd = ConvertTo-SecureString -String $vmadminPwd -AsPlainText -Force
$vm_creds = New-Object System.Management.Automation.PSCredential( $vmadminName, $vmpwd);

## check the resource group
try {     
    Get-AzResourceGroup -Name $rgName -Location $location -ErrorAction Stop     
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
 $csr_publicIP.IdleTimeoutInMinutes = 20
 Set-AzPublicIpAddress -PublicIpAddress $csr_publicIP
 } catch {
 $csr_publicIP = New-AzPublicIpAddress `
           -Name $csr_publicIPName `
           -ResourceGroupName $rgName `
           -Location $location `
           -AllocationMethod Static `
           -IdleTimeoutInMinutes 20 `
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

try {$rt = Get-AzRouteTable -Name $rtName -ResourceGroupName $rgName -ErrorAction Stop
     Write-Host "  $rtName route table exists, skipping"}
catch {
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

} ###End of function

### loop to create the sites specified in siteArray
For ($i=0; $i -lt $siteArray.Length; $i++) {
CreateAllSite `
   -rgName $siteArray[$i].rgName `
    -location $siteArray[$i].location `
    -vnetName $siteArray[$i].vnetName `
    -vnetPrefix $siteArray[$i].vnetPrefix `
    -subnet1Prefix $siteArray[$i].subnet1Prefix `
    -subnet2Prefix $siteArray[$i].subnet2Prefix `
    -subnet1Name $siteArray[$i].subnet1Name `
    -subnet2Name $siteArray[$i].subnet2Name `
    -csr_adminName $siteArray[$i].csr_adminName `
    -csr_adminPwd $siteArray[$i].csr_adminPwd `
    -csr_Name $siteArray[$i].csr_Name `
    -csr_publicIPName $siteArray[$i].csr_publicIPName `
    -csr_nic1Name $siteArray[$i].csr_nic1Name `
    -csr_nic2Name $siteArray[$i].csr_nic2Name `
    -csr_privateIP1 $siteArray[$i].csr_privateIP1 `
    -csr_privateIP2 $siteArray[$i].csr_privateIP2 `
    -csr_publisherName $siteArray[$i].csr_publisherName `
    -csr_offerName $siteArray[$i].csr_offerName `
    -csr_skuName $siteArray[$i].csr_skuName `
    -csr_version $siteArray[$i].csr_version `
    -csr_Size $siteArray[$i].csr_Size `
    -vmadminName $siteArray[$i].vmadminName `
    -vmadminPwd $siteArray[$i].vmadminPwd `
    -vm_Name $siteArray[$i].vm_Name `
    -vm_publicIPName $siteArray[$i].vm_publicIPName `
    -vm_nicName $siteArray[$i].vm_nicName `
    -vm_privateIP $siteArray[$i].vm_privateIP `
    -vm_publisherName $siteArray[$i].vm_publisherName `
    -vm_offerName $siteArray[$i].vm_offerName `
    -vm_skuName $siteArray[$i].vm_skuName `
    -vm_version $siteArray[$i].vm_version `
    -vm_Size $siteArray[$i].vm_Size `
    -nsgName $siteArray[$i].nsgName `
    -rtName $siteArray[$i].rtName
}