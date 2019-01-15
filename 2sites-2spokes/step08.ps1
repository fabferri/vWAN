###########################################
# 
# - Create an Azure storage account. It will be used in the next step to store the configuration of Virtual WAN. 
# - Create a storage container access policy
# - Create Storage Access Signature (SAS) with storage policy associated with the container
# - Write, in the local folder in textfile, the storage SAS URI useful for the next step
# 
# Note: the storage account can be deployed in any Azure region; it doens't need to be in the same Azure region of vHub
#
# Reference:
#   https://docs.microsoft.com/en-us/powershell/module/azure.storage/new-azurestoragecontainersastoken
#
##########################################
$subscriptionName   = "Windows Azure MSDN - Visual Studio Ultimate"
$rgName             = "RG-storage"         # name of the resource group where is deployed the storage account
$location           = "eastus"             # name of the Azure region
$storageAccountType = "Standard_LRS"       # type of storage account
$containerName      = "vwan101"            # name of the storage container
$storagePolicyName  = “storage-policy”     # name of the storage policy

$pathFiles      = Split-Path -Parent $PSCommandPath

# Select the Azure subscription
$subscr=Get-AzureRmSubscription -SubscriptionName $subscriptionName
Select-AzureRmSubscription -SubscriptionId $subscr.Id 

#generate a unique name for the storage account
$tail=([guid]::NewGuid().tostring()).replace("-","").Substring(0,10)
$storageAccountName = "storgacc"+ $tail


try {     
    Get-AzureRmResourceGroup -Name $rgName -Location $location -ErrorAction Stop  
    Write-Host 'RG already exists... skipping' -foregroundcolor Yellow -backgroundcolor Black
} catch {     
    $rg = New-AzureRmResourceGroup -Name $rgName -Location $location  -Force
}

try { 
   $storageAccount =Get-AzureRmStorageAccount -ResourceGroupName $rgName –StorageAccountName $storageAccountName -ErrorAction Stop 
} catch{
   # Create a new storage account.
   $storageAccount =New-AzureRmStorageAccount -ResourceGroupName $rgName –StorageAccountName $storageAccountName -Location $Location -Type $storageAccountType

}
$ctx=$storageAccount.Context


try { 
   $container=Get-AzureStorageContainer -Name $containerName -Context $ctx -ErrorAction Stop
} catch {
  # create a container
  $container=New-AzureStorageContainer -Name $containerName  -Context $ctx 
}
#
#

try { 
Get-AzureStorageContainerStoredAccessPolicy -Container $containerName -Policy $storagePolicyName -Context $ctx -ErrorAction Stop
} catch {
 # Create Storage Access Policy
 $expiryTime = (Get-Date).AddYears(1)
 # There are 4 levels of permissions that can be used: read (r), Write (w), list (l) and delete (d)
 New-AzureStorageContainerStoredAccessPolicy -Container $containerName -Policy $storagePolicyName -Permission rwdl -ExpiryTime $expiryTime -Context $ctx
}


$storageResourceURI=$container.CloudBlobContainer.Uri.AbsoluteUri

#Create Storage Access Signature (SAS) with storage policy
$sasToken = New-AzureStorageContainerSASToken -Name $containerName -Policy $storagePolicyName -Context $ctx

# compose the nume of blob
$time=(Get-Date -format yyyyMMddHHmmss).ToString()
$blobName =$time+ "config"
$sasURI=$storageResourceURI +"/"+ $blobName + $sasToken

write-host "storage container - URI......: "$storageResourceURI
write-host "storage container - SAS token: "$sasToken -foregroundcolor Yellow -backgroundcolor Black
write-host "new blob          - SAS URI..: "$sasURI -foregroundcolor Yellow -backgroundcolor Black



$fileName="sasURI.txt"
#New-Item -ItemType "file" -Path $pathFiles -Name $fileName -Value "storage container - SAS URI: `n$sasURI" -Force
#Add-Content -Path "$pathFiles\$fileName" -Value "SAS URI to be used to store vWAN configuration: `n$sasURI"
Set-Content -Path "$pathFiles\$fileName" -Value $sasURI

Exit

# only for testing purpose:
# copy a file in storage blob
$ctxSasToken = New-AzureStorageContext -StorageAccountName $storageAccountName -SasToken $sasToken
set-azurestorageblobcontent -File "$pathFiles\image1.jpg" -Container $containerName -Context $ctxSasToken -Force
