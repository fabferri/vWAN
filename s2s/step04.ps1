###########################################
# 
# - Create an Azure storage account. It will be used in the next step to store the configuration of Virtual WAN. 
# - Create a storage container access policy
# - Create Storage Access Signature (SAS) with storage policy associated with the container
# - store the configuration of Virtual WAN in the storage blob
# - get the configuration of Virtual WAN from the storage account via REST
# - parse the configuration of Virtual WAN 
# - create the configuration of CSR of different sites
# - write the configuration of Cisco CSRs in the local folder in text files
# Note: the storage account can be deployed in any Azure region; it doesn't need to be in the same Azure region of vHub
#
# Reference:
#   https://docs.microsoft.com/en-us/powershell/module/azure.storage/new-azurestoragecontainersastoken
#
##################################################################
$subscriptionName   = "AzDev"              #"Windows Azure MSDN - Visual Studio Ultimate"
$rgName             = "RG-vWAN101"         # name of the resource group where is deployed the storage account
$vWANName           = "wan1"               # name of the Virtual Wan
$location           = "northeurope"        # name of the Azure region
$storageAccountType = "Standard_LRS"       # type of storage account
$containerName      = "vwan101"            # name of the storage container
$storagePolicyName  = "storage-policy"     # name of the storage policy

##################################################################

$siteArray = @(
  @{
       vpnSiteName = "site1"
       ip_Tunnel0="172.16.0.1"                     ### ip address of the tunnel0 interface of CSR
       mask_Tunnel0="255.255.255.255"              ### subnet mask tunnel0
       ip_Tunnel1="172.16.0.2"                     ### ip address of the tunnel1 interface of CSR
       mask_Tunnel1=" "+"255.255.255.255"          ### subnet mask tunnel1
       priv_externalNetw="10.1.10.0"               ### private network prefix assigned to the external network interface of the Cisco CSR
       mask_externalNetw="255.255.255.0"           ### mask of private network assigned to the external network interface of the Cisco CSR
       priv_externalGateway="10.1.10.1"            ### defautl gateway of the subnet attached to the external interface of Cisco CSR
       priv_internalNetw="10.1.11.0"               ### private network prefix assigned to the internal network interface of the Cisco CSR
       mask_internalNetw="255.255.255.0"           ### mask of private network assigned to the internal network interface of the Cisco CSR
       fileName="csr1-config.txt"
   },
  @{
       vpnSiteName = "site2"
       ip_Tunnel0="172.16.0.3"                     ### ip address of the tunnel0 interface of CSR
       mask_Tunnel0="255.255.255.255"              ### subnet mask tunnel0
       ip_Tunnel1="172.16.0.4"                     ### ip address of the tunnel1 interface of CSR
       mask_Tunnel1="255.255.255.255"              ### subnet mask tunnel1
       priv_externalNetw="10.1.20.0"               ### private network prefix assigned to the external network interface of the Cisco CSR
       mask_externalNetw="255.255.255.0"           ### mask of private network assigned to the external network interface of the Cisco CSR
       priv_externalGateway="10.1.20.1"            ### defautl gateway of the subnet attached to the external interface of Cisco CSR
       priv_internalNetw="10.1.21.0"               ### private network prefix assigned to the internal network interface of the Cisco CSR
       mask_internalNetw="255.255.255.0"           ### mask of private network assigned to the internal network interface of the Cisco CSR
       fileName="csr2-config.txt"
   },
  @{
       vpnSiteName = "site3"
       ip_Tunnel0="172.16.0.5"                     ### ip address of the tunnel0 interface of CSR
       mask_Tunnel0="255.255.255.255"              ### subnet mask tunnel0
       ip_Tunnel1="172.16.0.6"                     ### ip address of the tunnel1 interface of CSR
       mask_Tunnel1="255.255.255.255"              ### subnet mask tunnel1
       priv_externalNetw="10.1.30.0"               ### private network prefix assigned to the external network interface of the Cisco CSR
       mask_externalNetw="255.255.255.0"           ### mask of private network assigned to the external network interface of the Cisco CSR
       priv_externalGateway="10.1.20.1"            ### defautl gateway of the subnet attached to the external interface of Cisco CSR
       priv_internalNetw="10.1.31.0"               ### private network prefix assigned to the internal network interface of the Cisco CSR
       mask_internalNetw="255.255.255.0"           ### mask of private network assigned to the internal network interface of the Cisco CSR
       fileName="csr3-config.txt"
   }
)

$pathFiles      = Split-Path -Parent $PSCommandPath

# Select the Azure subscription
$subscr=Get-AzSubscription -SubscriptionName $subscriptionName
Select-AzSubscription -SubscriptionId $subscr.Id 


## get Virtual WAN
try {
  $virtualWan=Get-AzVirtualWan -ResourceGroupName $rgName -Name $vWANName -ErrorAction Stop
  Write-Host 'Virtual WAN name.......: '$vWANName'' -foregroundcolor Yellow -backgroundcolor Black
} catch {
     Write-Host 'select the right Virtual WAN and run again the script' -foregroundcolor Yellow -backgroundcolor Black
     Exit
}

$vpnSites = New-Object Microsoft.Azure.Commands.Network.Models.PSVpnSite[] $siteArray.length
for ($i=0; $i -lt $siteArray.length; $i++){
  # get the site
  try {
    $vpnSiteName=$siteArray[$i].vpnSiteName
    $vpnSites[$i]=Get-AzVpnSite -ResourceGroupName $rgName -Name $vpnSiteName  -ErrorAction Stop 
    Write-Host 'Virtual WAN vpn site: '$vpnSiteName'' -foregroundcolor Yellow -backgroundcolor Black
  } catch {
       Write-Host 'select the right Virtual WAN vpn site: '$vpnSiteName' and run again the script'  -foregroundcolor Yellow -backgroundcolor Black
       Exit
  }
}



# print out the configuration of the vpn sites
for($i=0; $i -lt $siteArray.length; $i++)
{
write-host "configuration site"
write-host -ForegroundColor Cyan "......VPN site name: "$vpnSites[$i].name 
write-host -ForegroundColor Cyan ".........remote ASN: "$vpnSites[$i].BgpSettings.Asn
write-host -ForegroundColor Cyan ".....IP remote peer: "$vpnSites[$i].IpAddress
write-host "`n"
}

#generate a unique name for the storage account
$tail=([guid]::NewGuid().tostring()).replace("-","").Substring(0,10)
$storageAccountName = "storgacc"+ $tail

# checking the resource group where is deployed the storage account
try {     
    Get-AzResourceGroup -Name $rgName -Location $location -ErrorAction Stop  
    Write-Host 'RG already exists... skipping' -foregroundcolor Yellow -backgroundcolor Black
} catch {     
    $rg = New-AzResourceGroup -Name $rgName -Location $location  -Force
}

$s=Get-AzStorageAccount -ResourceGroupName $rgName

# check if $s has $null as value
if (!$s) { 
   # create a new storage account
   try { 
       $storageAccount =Get-AzStorageAccount -ResourceGroupName $rgName  $storageAccountName -ErrorAction Stop 
        Write-Host 'Storage account'$storageAccount.StorageAccountName 'already exists... skipping' -foregroundcolor Yellow -backgroundcolor Black
   } 
   catch{
       # Create a new storage account.
       $storageAccount =New-AzStorageAccount -ResourceGroupName $rgName $storageAccountName -Location $Location -Type $storageAccountType -Kind BlobStorage -AccessTier Hot 
       Write-Host 'Create the storage account: '$storageAccount.StorageAccountName  -foregroundcolor Yellow -backgroundcolor Black
   }
} 
else {
  $storageAccount = $s[0]
}

#get the storage context
$ctx=$storageAccount.Context

#check if it exists a storage container in the storage account 
try { 
   $container=Get-AzStorageContainer -Name $containerName -Context $ctx -ErrorAction Stop
   Write-Host 'Get the storage countainer: '$containerName  -foregroundcolor Yellow -backgroundcolor Black 
} catch {
  # create a container
  $container=New-AzStorageContainer -Name $containerName  -Context $ctx 
  Write-Host 'Create a new storage container: '$containerName  -foregroundcolor Yellow -backgroundcolor Black
}
#
#

try { 
  write-host "acquire access policy: "$accessPolicy$storagePolicyName -ForegroundColor Cyan
  $accessPolicy=Get-AzStorageContainerStoredAccessPolicy -Container $containerName -Policy $storagePolicyName -Context $ctx -ErrorAction Stop
  write-host "storage access policy: "$accessPolicy -ForegroundColor Cyan
} catch {
 # Create Storage Access Policy
 $expiryTime = (Get-Date).AddYears(1)
 # There are 4 levels of permissions that can be used: read (r), Write (w), list (l) and delete (d)
 $containerAccessPolicy=New-AzStorageContainerStoredAccessPolicy -Container $containerName -Policy $storagePolicyName -Permission rwdl -ExpiryTime $expiryTime -Context $ctx
 Write-Host 'Associate the access policy to the storage container '$containerAccessPolicy  -foregroundcolor Yellow -backgroundcolor Black
}


$storageResourceURI=$container.CloudBlobContainer.Uri.AbsoluteUri

#Create Storage Access Signature (SAS) with storage policy
$sasToken = New-AzStorageContainerSASToken -Name $containerName -Policy $storagePolicyName -Context $ctx


# define the name of storage blob to store the vWAN configuration
$blobName ="vwanconfig"
$sasURI=$storageResourceURI +"/"+ $blobName + $sasToken

write-host "storage container - URI......: "$storageResourceURI
write-host "storage container - SAS token: "$sasToken -foregroundcolor Yellow -backgroundcolor Black
write-host "new blob          - SAS URI..: "$sasURI -foregroundcolor Yellow -backgroundcolor Black


write-host -ForegroundColor Green "`nwriting vpn sites configuration in the storage blob" 
Get-AzVirtualWanVpnConfiguration -VirtualWan $virtualWan -StorageSasUrl $sasURI -VpnSite $vpnSites

### get the configuration of vWAN via REST API,from the storage account 
### When working with REST interfaces with PowerShell it�s pretty common to get JSON responses that have information that is returned as arrays of PSCustomObjects
$vWANConfig = Invoke-RestMethod  -Method Get -Uri $sasURI 


for ($j=0;$j -lt $vWANConfig.vpnSiteConfiguration.Count; $j++ ) {
    write-host "VPN site configuration:"
    write-host "   VPN config name        : "$vWANConfig[$j].vpnSiteConfiguration.Name -ForegroundColor Green -BackgroundColor Black
    write-host "   VPN config bgp         : "$vWANConfig[$j].vpnSiteConfiguration.BgpSetting -ForegroundColor Green -BackgroundColor Black
    write-host "   VPN config bgp-ASN     : "$vWANConfig[$j].vpnSiteConfiguration.BgpSetting.Asn -ForegroundColor Green -BackgroundColor Black
    write-host "   VPN config bgp-peering : "$vWANConfig[$j].vpnSiteConfiguration.BgpSetting.BgpPeeringAddress -ForegroundColor Green -BackgroundColor Black
    write-host "   VPN IP Addres          : "$vWANConfig[$j].vpnSiteConfiguration.IPAddress -ForegroundColor Green -BackgroundColor Black

}
write-host "-----------------" -ForegroundColor cyan


for ($j=0;$j -lt $vWANConfig.vpnSiteConnections.Count; $j++) {
 
    $nameVPNSite=$vWANConfig.vpnSiteConfiguration[$j].Name
     write-host "   VPN Site name: "$nameVPNSite -ForegroundColor cyan -BackgroundColor Black
    $vwanIpInstance0=$vWANConfig.vpnSiteConnections[$j].gatewayConfiguration.IpAddresses.Instance0
    $vwanIpInstance1=$vWANConfig.vpnSiteConnections[$j].gatewayConfiguration.IpAddresses.Instance1
    $vwanBGPInstance0=$vWANConfig.vpnSiteConnections[$j].gatewayConfiguration.BgpSetting.BgpPeeringAddresses.Instance0
    $vwanBGPInstance1=$vWANConfig.vpnSiteConnections[$j].gatewayConfiguration.BgpSetting.BgpPeeringAddresses.Instance1
    $vwanASN=$vWANConfig.vpnSiteConnections[$j].gatewayConfiguration.BgpSetting.Asn
    write-host "   vWAN VPN ASN......................: "$vwanASN -ForegroundColor Yellow -BackgroundColor Black
    write-host "   vWAN VPN Gateway-pub IP Instance0.: "$vwanIpInstance0 -ForegroundColor Yellow -BackgroundColor Black
    write-host "   vWAN VPN Gateway-pub IP Instance1.: "$vwanIpInstance1 -ForegroundColor Yellow -BackgroundColor Black
    write-host "   vWAN VPN Gateway-pub BGP Instance0: "$vwanBGPInstance0 -ForegroundColor Yellow -BackgroundColor Black
    write-host "   vWAN VPN Gateway-pub BGP Instance1: "$vwanBGPInstance1 -ForegroundColor Yellow -BackgroundColor Black
    
}


###############################################
######## write the vWAN configuration in a file

# get the key of storage account
#$key=(Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $storageAccountName).Value[0]
#write-host "key storage account: "$key -ForegroundColor Cyan


#$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $key
$blobs = Get-AzStorageBlob -Container $containerName -Context $ctx 

$fileConfig   = "$pathFiles\vWANConfig.json"
foreach ($blob in $blobs)  
{   
   Get-AzStorageBlobContent -Container $containerName -Blob $blob.Name -Destination $fileConfig -Context $ctx -Force
}  


function generate_csrConfig{
 Param(
     [Parameter(Mandatory=$true)] [System.object]$localASN,             ### BGP ASN assigned to the remote site 
     [Parameter(Mandatory=$true)] [System.String]$ip_loopback,          ### ip address lookback interface without mask
     [Parameter(Mandatory=$true)] [System.String]$mask_loopback,        ### sunet mask lookback interface 
     [Parameter(Mandatory=$true)] [System.object]$remoteASN,            ### BGP ASN assigned to the VPN gateway in the vWAN hub
     [Parameter(Mandatory=$true)] [System.String]$pubIP_RemoteGtw0,     ### public ip address-instance0 of the VPN Gateway in the vWAN hub 
     [Parameter(Mandatory=$true)] [System.String]$pubIP_RemoteGtw1,     ### public ip address-instance0 of the VPN Gateway in the vWAN hub 
     [Parameter(Mandatory=$true)] [System.String]$remotePeerBGP0,       ### BGP peer-instance0 of VPN Gateway in the vWAN hub
     [Parameter(Mandatory=$true)] [System.String]$remotePeerBGP1,       ### BGP peer-instance1 of VPN Gateway in the vWAN hub
     [Parameter(Mandatory=$true)] [System.String]$PSK,                  ### VPN site-so-site shared secret
     [Parameter(Mandatory=$true)] [System.String]$ip_Tunnel0,           ### ip address of the tunnel0 interface of CSR
     [Parameter(Mandatory=$true)] [System.String]$mask_Tunnel0,         ### subnetmask of the tunnel0 interface of CSR
     [Parameter(Mandatory=$true)] [System.String]$ip_Tunnel1,           ### ip address of the tunnel1 interface of CSR
     [Parameter(Mandatory=$true)] [System.String]$mask_Tunnel1,         ### subnetmask of the tunnel0 interface of CSR
     [Parameter(Mandatory=$true)] [System.String]$priv_externalNetw,    ### private network prefix assigned to the external network interface of the Cisco CSR
     [Parameter(Mandatory=$true)] [System.String]$mask_externalNetw,    ### mask of private network assigned to the external network interface of the Cisco CSR
     [Parameter(Mandatory=$true)] [System.String]$priv_externalGateway, ### defautl gateway of the subnet attached to the external interface of Cisco CSR
     [Parameter(Mandatory=$true)] [System.String]$priv_internalNetw,    ### private network prefix assigned to the internal network interface of the Cisco CSR
     [Parameter(Mandatory=$true)] [System.String]$mask_internalNetw,    ### mask of private network assigned to the internal network interface of the Cisco CSR
     [Parameter(Mandatory=$true)] [System.String]$fileName
    )

write-host "remote site1-BGP ASN......................: "$localASN -ForegroundColor Cyan
write-host "remote site1-ip address lookback interface: "$ip_loopback$mask_loopback -ForegroundColor Cyan
write-host "vWAN VPN Gateway-BGP ASN..................: "$remoteASN -ForegroundColor Cyan
write-host "vWAN public ip address-instance0..........: "$pubIP_RemoteGtw0 -ForegroundColor Cyan
write-host "vWAN public ip address-instance1..........: "$pubIP_RemoteGtw1 -ForegroundColor Cyan
write-host "vWAN VPN Gateway, BGP peer-instance0......: "$remotePeerBGP0 -ForegroundColor Cyan
write-host "vWAN VPN Gateway, BGP peer-instance1......: "$remotePeerBGP1 -ForegroundColor Cyan
write-host "vWAN VPN Gateway, sharedSecret............: "$PSK -ForegroundColor Cyan


write-host "CSR-ip address of the tunnel0 interface...: "$ip_Tunnel0$mask_Tunnel0 -ForegroundColor Green
write-host "CSR-ip address of the tunnel1 interface...: "$ip_Tunnel1$mask_Tunnel1 -ForegroundColor Green
write-host "CSR-external network interface............:  $priv_externalNetw $mask_externalNetw" -ForegroundColor Green
write-host "CSR-default gateway external interface....:  $priv_externalGateway" -ForegroundColor Green
write-host "CSR-internal network interface............:  $priv_internalNetw $mask_internalNetw" -ForegroundColor Green
write-host "CSR-configuration file....................: "$fileName

     

### compose the configuration of Cisco CSR
$CSRConfig = @"
interface GigabitEthernet2
 ip address dhcp
 no shut
!
interface Loopback0
 ip address $ip_loopback $mask_loopback
 no shut
!
crypto ikev2 proposal az-PROPOSAL
 encryption aes-cbc-256 aes-cbc-128 3des
 integrity sha1
 group 2
!
crypto ikev2 policy az-POLICY
 proposal az-PROPOSAL
!
crypto ikev2 keyring key-peer1
 peer azvpn1
  address $pubIP_RemoteGtw0
  pre-shared-key $PSK
!
!
crypto ikev2 keyring key-peer2
 peer azvpn2
  address $pubIP_RemoteGtw1
  pre-shared-key secret!101!
 !
crypto ikev2 profile az-PROFILE1
 match address local interface GigabitEthernet1
 match identity remote address $pubIP_RemoteGtw0 255.255.255.255
 authentication remote pre-share
 authentication local pre-share
 keyring local key-peer1
!
crypto ikev2 profile az-PROFILE2
 match address local interface GigabitEthernet1
 match identity remote address $pubIP_RemoteGtw1 255.255.255.255
 authentication remote pre-share
 authentication local pre-share
 keyring local key-peer2
!
crypto ipsec transform-set az-IPSEC-PROPOSAL-SET esp-aes 256 esp-sha-hmac
 mode tunnel
!
crypto ipsec profile az-VTI1
 set transform-set az-IPSEC-PROPOSAL-SET
 set ikev2-profile az-PROFILE1
!
crypto ipsec profile az-VTI2
 set transform-set az-IPSEC-PROPOSAL-SET
 set ikev2-profile az-PROFILE2
!
interface Tunnel0
 ip address $ip_Tunnel0 $mask_Tunnel0
 ip tcp adjust-mss 1350
 tunnel source GigabitEthernet1
 tunnel mode ipsec ipv4
 tunnel destination $pubIP_RemoteGtw0
 tunnel protection ipsec profile az-VTI1
!
interface Tunnel1
 ip address $ip_Tunnel1 $mask_Tunnel1
 ip tcp adjust-mss 1350
 tunnel source GigabitEthernet1
 tunnel mode ipsec ipv4
 tunnel destination $pubIP_RemoteGtw1
 tunnel protection ipsec profile az-VTI2
!
router bgp $localASN
 bgp router-id interface Loopback0
 bgp log-neighbor-changes
 neighbor $remotePeerBGP0 remote-as $remoteASN
 neighbor $remotePeerBGP0 ebgp-multihop 5
 neighbor $remotePeerBGP0 update-source Loopback0
 neighbor $remotePeerBGP1 remote-as $remoteASN
 neighbor $remotePeerBGP1 ebgp-multihop 5
 neighbor $remotePeerBGP1 update-source Loopback0
 !
 address-family ipv4
  network $priv_internalNetw mask $mask_internalNetw
  network $priv_externalNetw mask $mask_externalNetw
  neighbor $remotePeerBGP0 activate
  neighbor $remotePeerBGP0 next-hop-self
  neighbor $remotePeerBGP0 soft-reconfiguration inbound
  neighbor $remotePeerBGP1 activate
  neighbor $remotePeerBGP1 next-hop-self
  neighbor $remotePeerBGP1 soft-reconfiguration inbound
  maximum-paths eibgp 2
 exit-address-family
!
crypto ikev2 dpd 10 2 on-demand
!
! route set by ARM template
ip route 0.0.0.0 0.0.0.0 $priv_externalGateway
!
!
ip route $remotePeerBGP0 255.255.255.255 Tunnel0
ip route $remotePeerBGP1 255.255.255.255 Tunnel1

line vty 0 4
 exec-timeout 15 0
exit

"@

#write the content of the CSR config in a file
$pathFiles = Split-Path -Parent $PSCommandPath
Set-Content -Path "$pathFiles\$fileName" -Value $CSRConfig 

} ####### END FUNCTION


For ($i=0; $i -lt $siteArray.Length; $i++)
{
       Write-Host ""
       write-host "-----------------------site"$siteArray[$i].vpnSiteName -ForegroundColor Cyan
       $index=$vWANConfig.vpnSiteConfiguration.Name.indexof($siteArray[$i].vpnSiteName)
         
       $localASN=$vWANConfig.vpnSiteConfiguration[$index].BgpSetting.Asn                                                    ### BGP ASN assigned to the remote site 
       $ip_loopback=$vWANConfig.vpnSiteConfiguration[$index].BgpSetting.BgpPeeringAddress                                   ### ip address lookback interface 
       $mask_loopback= "255.255.255.255"                                                                                    ### subnet mask lookback interface

       $remoteASN=$vWANConfig.vpnSiteConnections[$index].gatewayConfiguration.BgpSetting.Asn                                ### BGP ASN assigned to the VPN gateway in the vWAN hub
       $pubIP_RemoteGtw0=$vWANConfig.vpnSiteConnections[$index].gatewayConfiguration.IpAddresses.Instance0                  ### public ip address-instance0 of the VPN Gateway in the vWAN hub 
       $pubIP_RemoteGtw1=$vWANConfig.vpnSiteConnections[$index].gatewayConfiguration.IpAddresses.Instance1                  ### public ip address-instance0 of the VPN Gateway in the vWAN hub 
       $remotePeerBGP0=$vWANConfig.vpnSiteConnections[$index].gatewayConfiguration.BgpSetting.BgpPeeringAddresses.Instance0 ### BGP peer-instance0 of VPN Gateway in the vWAN hub
       $remotePeerBGP1=$vWANConfig.vpnSiteConnections[$index].gatewayConfiguration.BgpSetting.BgpPeeringAddresses.Instance1 ### BGP peer-instance1 of VPN Gateway in the vWAN hub
       $PSK=$vWANConfig.vpnSiteConnections[$index].connectionConfiguration.PSK

       $ip_Tunnel0=$siteArray[$i].ip_Tunnel0                       ### ip address of the tunnel0 interface of CSR
       $mask_Tunnel0=$siteArray[$i].mask_Tunnel0                   ### subnet mask tunnel0
       $ip_Tunnel1=$siteArray[$i].ip_Tunnel1                       ### ip address of the tunnel1 interface of CSR
       $mask_Tunnel1=$siteArray[$i].mask_Tunnel1                   ### subnet mask tunnel1
       $priv_externalNetw=$siteArray[$i].priv_externalNetw         ### private network prefix assigned to the external network interface of the Cisco CSR
       $mask_externalNetw=$siteArray[$i].mask_externalNetw         ### mask of private network assigned to the external network interface of the Cisco CSR
       $priv_externalGateway=$siteArray[$i].priv_externalGateway   ### defautl gateway of the subnet attached to the external interface of Cisco CSR
       $priv_internalNetw=$siteArray[$i].priv_internalNetw         ### private network prefix assigned to the internal network interface of the Cisco CSR
       $mask_internalNetw=$siteArray[$i].mask_internalNetw         ### mask of private network assigned to the internal network interface of the Cisco CSR
       $fileName=$siteArray[$i].fileName
   
   generate_csrConfig `
   -localASN $localASN `
   -ip_loopback $ip_loopback `
   -mask_loopback $mask_loopback `
   -remoteASN $remoteASN `
   -pubIP_RemoteGtw0 $pubIP_RemoteGtw0 `
   -pubIP_RemoteGtw1 $pubIP_RemoteGtw1 `
   -remotePeerBGP0 $remotePeerBGP0 `
   -remotePeerBGP1 $remotePeerBGP1 `
   -PSK $PSK `
   -ip_Tunnel0 $ip_Tunnel0 `
   -mask_Tunnel0 $mask_Tunnel0 `
   -ip_Tunnel1 $ip_Tunnel1 `
   -mask_Tunnel1 $mask_Tunnel1 `
   -priv_externalNetw $priv_externalNetw `
   -mask_externalNetw $mask_externalNetw `
   -priv_externalGateway $priv_externalGateway `
   -priv_internalNetw $priv_internalNetw `
   -mask_internalNetw $mask_internalNetw `
   -fileName $fileName
}
