###########################################
# 
# - from the local file get the name of the storage account 
# - pickup the configuration of Virtual WAN from storage account to the local file named "vWANConfig.json"
#
###########################################
# 
$subscriptionName  = "Windows Azure MSDN - Visual Studio Ultimate"
$rgName            = "RG-storage"
$containerName     = "vwan101"

# Select the Azure subscription
$subscr=Get-AzureRmSubscription -SubscriptionName $subscriptionName
Select-AzureRmSubscription -SubscriptionId $subscr.Id 


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

$start=$sasURI.IndexOf(".")
$str=$sasURI.Substring(0,$start)
$start=2 + $str.IndexOf("//")
$storageAccountName=$str.Substring($start)
write-host $storageAccountName

$key=(Get-AzureRmStorageAccountKey -ResourceGroupName $rgName -AccountName $storageAccountName).Value[0]
write-host $key


$ctx = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $key
$blobs = Get-AzureStorageBlob -Container $containerName -Context $ctx 

$fileConfig   = "$pathFiles\vWANConfig.json"
foreach ($blob in $blobs)  
{   
   Get-AzureStorageBlobContent -Container $containerName -Blob $blob.Name -Destination $fileConfig -Context $ctx -Force
}  
