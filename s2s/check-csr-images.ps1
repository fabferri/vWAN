##### List of Azure powershell commands to find out the publisher, offer, SKU and images in Azure marketplace
##### 
##### Getting all the publishers in a specific region
$locName="westeurope"
Get-AzVMImagePublisher -Location $locName | Select PublisherName


##### Getting Cisco Offer
$pubName="cisco"
Get-AzVMImageOffer -Location $locName -PublisherName $pubName | Select Offer

##### Getting SKUs, Offer, PublisherName
$offerName="cisco-csr-1000v"
Get-AzVMImageSku -Location $locName -PublisherName $pubName -Offer $offerName 



##### Getting the last sku
$locName="westeurope"
$pubName="cisco"
$offerName="cisco-csr-1000v"
$skuName ="16_12-byol"
Get-AzVMImage -Location $locName -PublisherName $pubName -Offer $offerName -Skus $skuName

##### Getting the version
Get-AzVMImage -Location $locName -PublisherName $pubName -Offer $offerName -Sku $skuName | Select Version