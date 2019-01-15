<properties
pageTitle= 'Configuration of Azure Virtual WAN by powershell'
description= "Cnfiguration of Azure Virtual WAN by powershell"
documentationcenter: na
services=""
documentationCenter="na"
authors="fabferri"
manager=""
editor=""/>

<tags
   ms.service="configuration-Example-Azure"
   ms.devlang="na"
   ms.topic="article"
   ms.tgt_pltfrm="na"
   ms.workload="na"
   ms.date="14/01/2019"
   ms.author="fabferri" />

## Example of manual deployment of Azure Virtual WAN by powershell

The article reports a list of powershell scripts to create an Azure Virtual WAN. An overview of network configuration is reported below.

[![1]][1]

The topology is based on:
* a virtual WAN named **wan1**
* a single virtual hub **hub1-vnet**
* two spoke VNets, **spoke1-vnet** and **spoke2-vnet**, connected to the **hub1-vnet**. spoke1 and spoke2 VNets are in the same region of the virtual hub
* two VPN sites, **site1** and **site2**, deployed in different regions from the virtual hub. Each remote site has a Cisco CSR to establish the IPsec tunnel with the virtual hub.



| powershell script | Description                    |
| :---------------- | :----------------------------- |
|  **step01.ps1**   | - Create a Resource Group<br>- Create a Virtual WAN<br>- Create a Virtual Hub<br>- Create a VPN Gateway in the Virtual Hub   |
|  **step02.ps1**   | - Create a Resource Group<br>- Create a spoke1-vnet with subnet1 and subnet2<br> - Create a spoke2-vnet with subnet1 and subnet2<br> - spoke1-vnet: Create a VM attached to subnet1<br> - spoke1-vnet: Create a VM attached to subnet2<br> - spoke2-vnet: Create a VM attached to subnet1<br> - spoke2-vnet: Create a VM attached to subnet2<br> - create a NSG<br> - Associate the NSG to the subnets in spoke1-vnet<br> - Associate the NSG to the subnets in spoke1-vnet|
|  **step03.ps1**   | - Create site1-vnet<br>- Create Cisco CSR in site1-vnet<br>- Create a VM in subnet2<br>- Set a UDR to force the traffic to the CSR interface connected to the subnet2 |
|  **step04.ps1**   | - Create site2-vnet<br>- create Cisco CSR in site2-vnet<br>- create a VM in subnet2<br>- set a UDR to force the traffic to the CSR interface connected to the subnet2 |
|  **step05.ps1**   | - Create the vpn site1<br>- Create the vpn site2<br>- Create the connection hub-vpn site1<br>- Create the connection hub-vpn site2 |
|  **step06.ps1**   | BGP is enabled on site 1 and site2 then the Address space are not required.<br> By Azure management portal remove the address space "192.168.255.0/24" associated with the two sites (site1 and site2). |
|  **step07.ps1**   | - Create a connection between virtual hub and spoke1-vnet<br>- Create a connection between virtual hub and spoke2-vnet  |
|  **step08.ps1**   | - Create an Azure storage account. It will be used in the next step to store the configuration of Virtual WAN.<br> - Create a storage container access policy<br>- Create Storage Access Signature (SAS) with access policy<br>- Write, in the local folder in textfile, the storage SAS URI useful for the next step |
|  **step09.ps1**   |- Get the config of vpn site1 and vpn site2<br>- store the virtual WAN config in the Azure storage account |
|  **step10.ps1**   | - From the local file get the name of the storage account<br>- pickup the configuration of Virtual WAN from storage account to the local file named "vWANConfig.json"  |
| ** step11**  | - Login in the cisco csr1 and run the script **step11-csr1-config.txt**<b>- Login in the cisco csr2 and run the script **step11-csr1-config.txt** |

A network diagram with more information is shown below:
[![2]][2]

The script **step01.ps1, step02.ps1, step03.ps1** can simultaneosly because do not have dependency.
In following chapters a list of diagrams related to the specific deployment after running the related script. 

#### <a name="vWAN"></a>1. STEP1: create vWAN with hub,and gateway
[![3]][3]

#### <a name="vWAN"></a>2. STEP2: create spoke VNets
[![4]][4]

#### <a name="vWAN"></a>3. STEP3: create site1
[![5]][5]

#### <a name="vWAN"></a>4. STEP4: create site2
[![6]][6]

#### <a name="vWAN"></a>5. STEP5: Create site and connection in virtual hub
[![7]][7]

#### <a name="vWAN"></a>6. STEP7: create connection between spoke VNets and virtual hub
[![8]][8]

#### <a name="vWAN"></a>7. STEP8: store the configuration in the storage blob
[![9]][9]

#### <a name="vWAN"></a>8. Network diagram with details on site vpn
[![10]][10]



<!--Image References-->

[1]: ./media/network-overview.png "network overview"
[2]: ./media/network-diagram.png "network diagram"
[3]: ./media/step1.png "network diagram step1"
[4]: ./media/step2.png "network diagram step2"
[5]: ./media/step3.png "network diagram step3"
[6]: ./media/step4.png "network diagram step4"
[7]: ./media/step5.png "network diagram step5"
[8]: ./media/step7.png "network diagram step7"
[9]: ./media/step8.png "network diagram step8"
[10]: ./media/site-vpn-details.png "network diagram step8"

<!--Link References-->

