###########################################
#  
# - Get the config of vpn site1 and vpn site2
# - store the virtual WAN config in the Azure storage account
#
#
# Reference:
#   https://docs.microsoft.com/en-us/powershell/module/azurerm.network/get-azurermvpnsite
#   https://docs.microsoft.com/en-us/powershell/module/azurerm.network/get-azurermvirtualwanvpnconfiguration
##########################################
#
#
################ Variables
$subscriptionName= "Windows Azure MSDN - Visual Studio Ultimate"
$rgName          = "RG-vWAN101"          # name of the resoure group
$location        = "westcentralus"       # location of the hub
$vWANName        = "wan1"                # name Virtual Wan
#
$vpnSite1Name    = "site1"
$vpnSite2Name    = "site2"


################
$fileName       = "sasURI.txt"      # do not change this name. it works in synch with previous script.
$pathFiles      = Split-Path -Parent $PSCommandPath
$fileFullPath   = "$pathFiles\$fileName"
if  (Test-Path  ($fileFullPath)) {
  write-host -ForegroundColor Cyan "Reading file with storage SAS URI:"
  $sasURI=Get-Content -Path "$pathFiles\$fileName"
  write-host -ForegroundColor Yellow -BackgroundColor Black $sasURI
} else {
  write-host -ForegroundColor Cyan "file with SAS URI doesn't exist"
  Exit
}

#
# Select the Azure subscription
$subscr=Get-AzureRmSubscription -SubscriptionName $subscriptionName
Select-AzureRmSubscription -SubscriptionId $subscr.Id 


## get Resource Group
try {     
    Get-AzureRmResourceGroup -Name $rgName -Location $location -ErrorAction Stop     
    Write-Host 'Resource Group vWAN....: '$rgName'' -foregroundcolor Yellow -backgroundcolor Black
} catch {     
    Write-Host 'select the right resource group and run again the script' -foregroundcolor Yellow -backgroundcolor Black
   Exit
}

## get Virtual WAN
try {
  $virtualWan=Get-AzureRmVirtualWan -ResourceGroupName $rgName -Name $vWANName -ErrorAction Stop
  Write-Host 'Virtual WAN name.......: '$vWANName'' -foregroundcolor Yellow -backgroundcolor Black
} catch {
     Write-Host 'select the right Virtual WAN and run again the script' -foregroundcolor Yellow -backgroundcolor Black
     Exit
}


try {
  $vpnSite1=Get-AzureRmVpnSite -ResourceGroupName $rgName -Name $vpnSite1Name  -ErrorAction Stop 
  Write-Host 'Virtual WAN vpn site: '$vpnSite1Name'' -foregroundcolor Yellow -backgroundcolor Black
} catch {
     Write-Host 'select the right Virtual WAN vpn site: '$vpnSite1Name' and run again the script'  -foregroundcolor Yellow -backgroundcolor Black
     Exit
}

try {
  $vpnSite2=Get-AzureRmVpnSite -ResourceGroupName $rgName -Name $vpnSite2Name  -ErrorAction Stop 
  Write-Host 'Virtual WAN vpn site: '$vpnSite2Name'' -foregroundcolor Yellow -backgroundcolor Black
} catch {
     Write-Host 'select the right Virtual WAN vpn site: '$vpnSite2Name' and run again the script'  -foregroundcolor Yellow -backgroundcolor Black
     Exit
}

$vpnSitesForConfig = New-Object Microsoft.Azure.Commands.Network.Models.PSVpnSite[] 2
$vpnSitesForConfig[0] = $vpnSite1
$vpnSitesForConfig[1] = $vpnSite2

# print out the configuration of the vpn sites
for($i=0; $i -lt $vpnSitesForConfig.Length; $i++)
{
write-host "configuration site"
write-host -ForegroundColor Cyan "......vpn site name: "$vpnSitesForConfig[$i].name 
write-host -ForegroundColor Cyan ".........remote ASN: "$vpnSitesForConfig[$i].BgpSettings.Asn
write-host -ForegroundColor Cyan ".....IP remote peer: "$vpnSitesForConfig[$i].IpAddress
write-host -ForegroundColor Cyan ".....remote network: "$vpnSitesForConfig[$i].AddressSpace
write-host "`n"
}

write-host -ForegroundColor Green "`nwriting vpn sites configuration in the storage blob" 
Get-AzureRmVirtualWanVpnConfiguration -VirtualWan $virtualWan -StorageSasUrl $sasURI -VpnSite $vpnSitesForConfig

