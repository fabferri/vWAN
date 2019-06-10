<properties
pageTitle= 'HOWTO configure Azure Virtual WAN with site-to-site VPN, spoke VNets and VNet in peering by powershell'
description= "Manual configuration of Azure Virtual WAN by powershell"
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
   ms.date="06/06/2019"
   ms.author="fabferri" />

## Azure Virtual WAN configuration with site-to-site VPN, spoke VNets and VNets in peering

The article walks through a list of powershell scripts to create an Azure Virtual WAN with site-to-site VPN and spoke VNets connected to the hub with few VNets in peering. The network diagram is shown below.

[![1]][1]


The topology is based on:
* an Azure virtual WAN
* a single virtual hub **hub1-vnet**
* two sites **site1, site2** deployed in Azure through VNets. Each site has a Cisco CSR to establish a site-to-site VPN with the **hub1-vnet**
* two spoke VNets named **transit** and **Spoke2** connected to the hub VNet
* two VNets connected with VNet peering to the **transit** VNet


The sequence of scripts to create the deployment is described in the table:

| powershell script | Description                    |
| :---------------- | :----------------------------- |
|  **step01.ps1**   | - Create a Resource Group<br>- Create a Virtual WAN<br>- Create a Virtual Hub in the Virtual WAN<br>- Create a VPN Gateway in the Virtual Hub  |
|  **step02.ps1**   | - Create two remote sites<br> - Each site is created in a specific Resource Group<br> - In each site is deployed a VNet with two subnets: subnet1 and subnet2<br> - In each site is deployed a Cisco CSR with two NICs: one NIC connected to the subnet1 and one NIC connected to subnet2<br> - In each site is created one CentOS VM attached to subnet2 (internal subnet)<br>- Create a NSG to accept incoming SSH connections to the VNet<br> - Associate the NSG to the subnet2<br> -create a UDR for the site<br> -associate the UDR in subnet2 to force the traffic with destinations 10.0.0.0/8 through the CSR|
|  **step03.ps1**   | - Create a list of vpn sites: vpn site1,vpn site2<br>- Create the connections hub-vpn sites:[hub,site1],[hub,site2] |
|  **step04.ps1**   | - Create an Azure storage account used  to store the configuration of Virtual WAN.<br> - Create a storage container access policy<br>- Create Storage Access Signature (SAS) with access policy<br>- store the virtual WAN config in the Azure storage account<br>- Get the configuration of Virtual WAN from the storage account via REST API<br>- Compose the configuration of Cisco CSRs to setup the site VPNs<br>- Write the  Cisco CSR configurations in files in local script folder (**csr1-config.txt**, **csr2-config.txt**)|
|  **step05.txt**   |- By Azure management portal remove the Address space "192.168.255.0/24" associated with the vpn sites.<br> Use the URL to the Azure preview features: https://aka.ms/azurevirtualwanpreviewfeatures|
| **step06.ps1**  | <br>- Create a Resource Group<br>- Create a transit-vnet with subnet1 and subnet2<br>- Create a spoke2-vnet with subnet1 and subnet2<br>- transit-vnet: Create a VM attached to subnet1<br>- spoke2-vnet: Create a VM attached to subnet1<br>- Create a NSG<br>- Associate the NSG to the subnets in transit-vnet<br>- Associate the NSG to the subnets in spoke2-vnet |
| **Step07.ps1**  | - Create a connection between virtual hub and transit-vnet<br> - Create a connection between virtual hub and spoke2-vnet|
| **z-change-RT-dc-VNets.ps1**| OPTIONAL SCRIPT<br>-script to delete and recreate new UDRs in the dc1 and dc2 VNets with more sspecific routes|
|**z-change-RT-hub.ps1**| OPTIONAL SCRIPT<br>-remove an existing routing table associated with the hub<br>-create a new routing table with more specific networks to reach out the dc1 and dc2 VNets<br>- make the association of new routing table with the hub|

A network diagram with more information is shown below:

[![2]][2]


>Notes
>* The powershell scripts **step01.ps1, step02.ps1** can run simultaneously because do not have dependency.
>* The powershell scripts can be easily changed to support a larger number of sites and spoke VNets.


### <a name="vWAN"></a>1.UDRs applied to the VNets
Communication between dc1, dc2 VNets with the sites requires the presence of UDRs in the hub VNet and in the subnets of dc1 and dc2 VNets.
In general, there are two different ways to write the UDRs:
1. reference in the entries of the UDR the major destination networks. the case is discussed in the paragraph 1.1
2. reference the specific destination networks. The approach with more specific networks (more network prefixes match) requires a larger number of entries in the routing table. The case is described in the paragraph 1.2

#### <a name="vWAN"></a>1.1 UDRs with major networks

The dc1 and dc2 are two VNets in peering with the transit VNet; their address space belongs to the major network 10.2.X.X
The major network 10.2.0.0/16 provides the path to all the destination VNets with address space in the range 10.2.X.X.
The UDR in the hub can be set as:

| Destination  | NextHopType     | nextHopIP|
| :----------- | :-------------- |----------|
| 10.2.0.0/16  |VirtualAppliance |10.1.10.10|

dc1 and dc2 VNets are connected in peering only with transit VNet. Those VNets can communicated with other VNets only by transit through the NVA 10.1.10.10 in transit VNet. Then the UDR applied to dc1 and dc2 VNets:

| Destination  | NextHopType     | nextHopIP|
| :----------- | :-------------- |----------|
| 10.0.0.0/8   |VirtualAppliance |10.1.10.10|

The diagram below provides an overall view of UDRs applied to the VNets:

[![3]][3]

### <a name="vWAN"></a>1.2 UDRs with specific destination networks

The UDR associated with hub can be set with more specific destination networks:

| Destination  | NextHopType     | nextHopIP|
| :----------- | :-------------- |----------|
|10.2.10.0/24  |VirtualAppliance |10.1.10.10|
|10.2.11.0/24  |VirtualAppliance |10.1.10.10|
|10.2.20.0/24  |VirtualAppliance |10.1.10.10|
|10.2.21.0/24  |VirtualAppliance |10.1.10.10|


The UDR associated with dc1-VNet has the following UDR entries:

| Destination  | NextHopType     | nextHopIP|
| :----------- | :-------------- |----------|
|10.2.20.0/24  |VirtualAppliance |10.1.10.10|
|10.2.21.0/24  |VirtualAppliance |10.1.10.10|
|10.3.10.0/24  |VirtualAppliance |10.1.10.10|
|10.3.11.0/24  |VirtualAppliance |10.1.10.10|
|10.3.20.0/24  |VirtualAppliance |10.1.10.10|
|10.3.21.0/24  |VirtualAppliance |10.1.10.10|

The UDR associated with subnets dc2-VNet has the UDR entries:

| Destination  | NextHopType     | nextHopIP|
| :----------- | :-------------- |----------|
|10.2.10.0/24  |VirtualAppliance |10.1.10.10|
|10.2.11.0/24  |VirtualAppliance |10.1.10.10|
|10.3.10.0/24  |VirtualAppliance |10.1.10.10|
|10.3.11.0/24  |VirtualAppliance |10.1.10.10|
|10.3.20.0/24  |VirtualAppliance |10.1.10.10|
|10.3.21.0/24  |VirtualAppliance |10.1.10.10|

> **The vWAN  does not support VNets communicating transitively through the hub. For this reason the UDRs do not include the entry to reach out the Spoke2 VNets.**

[![4]][4]


### <a name="vWAN"></a>2. Configuration of static route in site1 and site2

The VPN gateway in the virtual hub advertises via BGP, to the site1 and site2, the address space of the hub 10.0.0.0/24 and the networks prefixes (10.1.20.0/24, 10.1.21.0/24) associated with spoke2 and the address space (10.1.10.0/24,10.1.11.0/24) of transit VNets:

```console
csr1#show ip bgp
BGP table version is 14, local router ID is 172.16.0.10
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
              r RIB-failure, S Stale, m multipath, b backup-path, f RT-Filter,
              x best-external, a additional-path, c RIB-compressed,
              t secondary path,
Origin codes: i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

     Network          Next Hop            Metric LocPrf Weight Path
 *m   10.0.0.0/24      10.0.0.7                               0 65515 i
 *>                    10.0.0.6                               0 65515 i
 *m   10.1.10.0/24     10.0.0.7                               0 65515 i
 *>                    10.0.0.6                               0 65515 i
 *m   10.1.11.0/24     10.0.0.7                               0 65515 i
 *>                    10.0.0.6                               0 65515 i
 *m   10.1.20.0/24     10.0.0.7                               0 65515 i
 *>                    10.0.0.6                               0 65515 i
 *m   10.1.21.0/24     10.0.0.7                               0 65515 i
 *>                    10.0.0.6                               0 65515 i
 *>   10.3.10.0/24     0.0.0.0                  0         32768 i
 *>   10.3.11.0/24     0.0.0.0                  0         32768 i
 *m   10.3.20.0/24     10.0.0.7                               0 65515 65012 i
 *>                    10.0.0.6                               0 65515 65012 i
 *m   10.3.21.0/24     10.0.0.7                               0 65515 65012 i
 *>                    10.0.0.6                               0 65515 65012 i
 rm   172.16.0.10/32   10.0.0.7                               0 65515 i
 r>                    10.0.0.6                               0 65515 i
 *>   172.16.0.20/32   10.0.0.6                               0 65515 i
 *m                    10.0.0.7                               0 65515 i
csr1#

```
The VPN device in site1 and site2 do not know the networks associated with dc1 and dc2. Some static entries need to be added to the csr1 and csr2 to establish the communication with dc1 and dc2.
There are two ways to write the static routes in csr1 and csr2: by major destination networks or by more specific destination networks.


#### <a name="vWAN"></a>2.1 Static routing table in csr1 and csr2 with major destination networks

Static routes to be added to csr1 (site1) and csr2 (site2):

```console
ip route 10.2.0.0 255.255.0.0 Tunnel0
ip route 10.2.0.0 255.255.0.0 Tunnel1
```

#### <a name="vWAN"></a>2.2 Static routing table in csr1 and csr2 with specific destination networks

Static routes to be added to csr1 (site1) and csr2 (site2):

```console
ip route 10.2.10.0 255.255.255.0 Tunnel0
ip route 10.2.11.0 255.255.255.0 Tunnel0
ip route 10.2.20.0 255.255.255.0 Tunnel0
ip route 10.2.21.0 255.255.255.0 Tunnel0

ip route 10.2.10.0 255.255.255.0 Tunnel1
ip route 10.2.11.0 255.255.255.0 Tunnel1
ip route 10.2.20.0 255.255.255.0 Tunnel1
ip route 10.2.21.0 255.255.255.0 Tunnel1
```

The routing table of csr1 with specific destination network is shown below:

```console
csr1#show ip route static
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
       a - application route
       + - replicated route, % - next hop override, p - overrides from PfR

Gateway of last resort is 10.3.10.1 to network 0.0.0.0

S*    0.0.0.0/0 [1/0] via 10.3.10.1
      10.0.0.0/8 is variably subnetted, 17 subnets, 2 masks
S        10.0.0.6/32 is directly connected, Tunnel1
S        10.0.0.7/32 is directly connected, Tunnel0
S        10.2.10.0/24 is directly connected, Tunnel0
                      is directly connected, Tunnel1
S        10.2.11.0/24 is directly connected, Tunnel0
                      is directly connected, Tunnel1
S        10.2.20.0/24 is directly connected, Tunnel0
                      is directly connected, Tunnel1
S        10.2.21.0/24 is directly connected, Tunnel0
                      is directly connected, Tunnel1
      168.63.0.0/32 is subnetted, 1 subnets
S        168.63.129.16 [254/0] via 10.3.10.1
      169.254.0.0/32 is subnetted, 1 subnets
S        169.254.169.254 [254/0] via 10.3.10.1
```

### <a name="vWAN"></a>3.Communication flows

[![5]][5]

In the assumption the previous steps are completed:
* the NVA in transit VNet works as ip forwarder,
* the UDR is applied to the hub,
* the UDRs are applied to dc1 and dc2 VNets,
* the static routes are added to the csr1 and csr2 to reach out the network 10.2.0.0/16

the list of allow communication flows are:
- site1-vnet **<->** spoke2-vnet: allowed
- site2-vnet **<->** spoke2-vnet: allowed
- site1-vnet **<->** transit-vnet: allowed
- site2-vnet **<->** transit-vnet: allowed
- site1-vnet **<->** dc1-vnet: allowed
- site1-vnet **<->** dc2-vnet: allowed
- site2-vnet **<->** dc1-vnet: allowed
- site2-vnet **<->** dc2-vnet: allowed
- dc1-vnet **<->** dc2-vnet: allowed
- transit-vnet **<->** spoke2-vnet: not supported
- dc1-vnet **<->** spoke2-vnet: not supported
- dc2-vnet **<->** spoke2-vnet: not supported

### <a name="vWAN"></a>4. Notes
#### <a name="vWAN"></a>4.1 remove the routing table applied in the virtual hub
To remove the UDR applied to the hub:

```powershell
# getting the virtual hub
$vhub=Get-AzVirtualHub -ResourceGroupName $rgName -Name $hubName
# create an empty route table
$routeTable=New-Object -TypeName Microsoft.Azure.Commands.Network.Models.PSVirtualHubRouteTable
# update the virtual hub with empty routing table
Update-AzVirtualHub -ResourceGroupName $rgName -Name $hubName -RouteTable $routeTable
```

#### <a name="vWAN"></a>4.2 timout on SSH sessions in CSR
The SSH session allocates a VTY terminal session. The terminal VTY timemout on Cisco CSRs are set to 15 minutes:
```
line vty 0 4
 exec-timeout 15 0
```
To avoid terminal session to be orphaned, the CSR is deployed with an Azure public IP with higher idle timeout (20 minutes):

```
New-AzPublicIpAddress -IdleTimeoutInMinutes 20
```
the idle-timeout of Azure public IP specifies how many minutes to keep a TCP connection remains open without relying on clients to send keep-alive messages.



<!--Image References-->

[1]: ./media/network-overview.png "network overview"
[2]: ./media/network-diagram.png "network diagram"
[3]: ./media/udr-major-networks.png "UDRs with major networks"
[4]: ./media/udr-specific-networks.png "UDRs with specific networks"
[5]: ./media/communication-flows.png "communication flows"


<!--Link References-->

