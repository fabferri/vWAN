<properties
pageTitle= 'Manual configuration of site-to-site VPN in Azure Virtual WAN by powershell'
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

## Site-to-site VPN with Azure Virtual WAN by Azure powershell

The article discusses a list of powershell scripts to create an Azure Virtual WAN with multiple sites. An overview of network configuration is shown below.

[![1]][1]


The topology is based on:
* an Azure virtual WAN
* a single virtual hub **hub1-vnet**
* three sites **site1, site2,site3** deployed in Azure through VNets. Each site has a Cisco CSR to establish a site-to-site VPN with the **hub1-vnet**


The sequence of scripts to create the deployment is described in the table:

| powershell script | Description                    |
| :---------------- | :----------------------------- |
|  **step01.ps1**   | - Create a Resource Group<br>- Create a Virtual WAN<br>- Create a Virtual Hub in the Virtual WAN<br>- Create a VPN Gateway in the Virtual Hub  |
|  **step02.ps1**   | - Create three remote sites<br> - Each site is created in a specific Resource Group<br> - In each site is deployed a VNet with two subnets: subnet1 and subnet2<br> - In each site is deployed a Cisco CSR with two NICs: one NIC connected to the subnet1 and one NIC connected to subnet2<br> - In each site is created one CentOS VM attached to subnet2 (internal subnet)<br>- Create a NSG to accept incoming SSH connections to the VNet<br> - Associate the NSG to the subnet2<br> -associate a UDR in subnet2 to force the traffic with destinations 10.0.0.0/8 through the CSR|
|  **step03.ps1**   | - Create a list of vpn sites<br>- Create the connections hub-vpn sites  |
|  **step04.ps1**   | - Create an Azure storage account used  to store the configuration of Virtual WAN.<br> - Create a storage container access policy<br>- Create Storage Access Signature (SAS) with access policy<br>- store the virtual WAN config in the Azure storage account<br>- Get the configuration of Virtual WAN from the storage account via REST API<br>- Compose the configuration of Cisco CSRs to setup the site VPNs<br>- Write the  Cisco CSR configurations in test file in script local folder (**csr1-config.txt**, **csr2-config.txt**, **csr3-config.txt**)|
|  **step05.txt**   |- By Azure management portal remove the Address space "192.168.255.0/24" associated with the vpn sites.<br> Use the URL to the Azure preview features: https://aka.ms/azurevirtualwanpreviewfeatures|


A network diagram with more information is shown below:

[![2]][2]


Notes
* The powershell scripts **step01.ps1, step02.ps1** can run simultaneously because do not have dependency.
* The powershell scripts can be easily changed to support a larger number of sites.

The article walks through two different cases:
* CASE1: all the sites advertise via BGP different networks with different ASN
* CASE2: all the sites advertise via BGP different networks, but two sites, site2 and site3, have the same ASN

In following paragraphs, the network diagrams associated with scripts.

### <a name="vWAN"></a>1. CASE1: all sites have different networks and different ASNs
This is the most common scenario, with all the sites with different ASNs

[![3]][3]


The steps of Virtual WAN creation are visualized below.

#### <a name="vWAN"></a>1.1 STEP1: create vWAN with hub and VPN gateway

[![4]][4]


#### <a name="vWAN"></a>1.2 STEP2: create sites
The script step02.ps1 creates three sites in sequence, as reported in the diagram:

[![5]][5]


#### <a name="vWAN"></a>1.3 STEP3: Create sites and connections in virtual WAN

[![6]][6]


#### <a name="vWAN"></a>1.4 STEP4: generate the configuration for the Cisco CSRs

[![7]][7]


By default BGP will advertise all prefixes to EBGP (External BGP) neighbors. To avoid the each site readvertise to the hub the network prefixes learnt from the hub-gateway, it can be used a filter-list with the AS PATH access-list.


```console
csr1(config)# ip as-path access-list 5 permit ^$

csr1(config-router-af)# neighbor 10.0.0.6 filter-list 5 out
csr1(config-router-af)# neighbor 10.0.0.7 filter-list 5 out
```
Same filter can be defined and applied to the csr2 and csr3.


#### <a name="vWAN"></a>8. Network flows
The diagram below shown the allowed communication flow between the three sites:

[![8]][8]


### <a name="vWAN"></a>2. CASE2: two sites have different networks and same ASNs
The network diagram shows below depicts the case with Site2 and Site3 with different networks and the same ASN.

[![9]][9]




The configuration is different from previous case, because csr2 and csr3 have now the same ASN.

```console
csr2(config-router)# bgp 65012
csr2(config-router-af)#
csr2(config-router-af)# neighbor 10.0.0.6 send-community
csr2(config-router-af)# neighbor 10.0.0.6 route-map SetCommunity out
csr2(config-router-af)# neighbor 10.0.0.7 send-community
csr2(config-router-af)# neighbor 10.0.0.7 route-map SetCommunity out
!
csr2(config)# access-list 101 10 permit ip 10.1.20.0 0.0.0.255 any
csr2(config)# access-list 101 20 permit ip 10.1.21.0 0.0.0.255 any
!
!the community value displays in AA:NN format
ip bgp-community new-format
route-map SetCommunity permit 20
  match ip address 101
  set community 65012:20
```
Similar configuration for csr3, with different BGP community 65012:30:

```console
csr3(config-router)# bgp 65012
csr3(config-router-af)# neighbor 10.0.0.6 send-community
csr3(config-router-af)# neighbor 10.0.0.6 route-map SetCommunity out
csr3(config-router-af)# neighbor 10.0.0.7 send-community
csr3(config-router-af)# neighbor 10.0.0.7 route-map SetCommunity out
csr3(config)#!
csr3(config)# access-list 101 10 permit ip 10.1.30.0 0.0.0.255 any
csr3(config)# access-list 101 20 permit ip 10.1.31.0 0.0.0.255 any
csr3(config)# !
csr3(config)# !the community value displays in AA:NN format
csr3(config)# ip bgp-community new-format
csr3(config)#route-map SetCommunity permit 20
csr3(config-map)#  match ip address 101
csr3(config-map)#  set community 65012:30
```

The BGP routing table in csr1 receives the networks 10.1.20.0/24,10.1.21.0/24,10.1.30.0/24,10.1.31.0/24 from the same ASN 65012, but the routes are coming from diffent sites, site2 and site3:

```console
csr1#show ip bgp
BGP table version is 110, local router ID is 172.16.0.10
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
              r RIB-failure, S Stale, m multipath, b backup-path, f RT-Filter,
              x best-external, a additional-path, c RIB-compressed,
              t secondary path,
Origin codes: i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

     Network          Next Hop            Metric LocPrf Weight Path
 *>   10.0.0.0/24      10.0.0.6                               0 65515 i
 *m                    10.0.0.7                               0 65515 i
 *>   10.1.10.0/24     0.0.0.0                  0         32768 i
 *>   10.1.11.0/24     0.0.0.0                  0         32768 i
 *m   10.1.20.0/24     10.0.0.7                               0 65515 65012 i
 *>                    10.0.0.6                               0 65515 65012 i
 *m   10.1.21.0/24     10.0.0.7                               0 65515 65012 i
 *>                    10.0.0.6                               0 65515 65012 i
 *m   10.1.30.0/24     10.0.0.6                               0 65515 65012 i
 *>                    10.0.0.7                               0 65515 65012 i
 *m   10.1.31.0/24     10.0.0.6                               0 65515 65012 i
 *>                    10.0.0.7                               0 65515 65012 i
 r>   172.16.0.10/32   10.0.0.6                               0 65515 i
 rm                    10.0.0.7                               0 65515 i
 *m   172.16.0.20/32   10.0.0.6                               0 65515 i
 *>                    10.0.0.7                               0 65515 i
 *m   172.16.0.30/32   10.0.0.6                               0 65515 i
 *>                    10.0.0.7                               0 65515 i
```

To check the BGP communities associated with the networks 10.1.20.0/24 and 10.2.30.0/24:

```console
csr1#show bgp 10.1.20.0/24
BGP routing table entry for 10.1.20.0/24, version 97
Paths: (2 available, best #2, table default)
Multipath: eiBGP
  Not advertised to any peer
  Refresh Epoch 1
  65515 65012, (received & used)
    10.0.0.7 from 10.0.0.7 (10.0.0.7)
      Origin IGP, localpref 100, valid, external, multipath(oldest)
      Community: 65012:20
      rx pathid: 0, tx pathid: 0
  Refresh Epoch 1
  65515 65012, (received & used)
    10.0.0.6 from 10.0.0.6 (10.0.0.6)
      Origin IGP, localpref 100, valid, external, multipath, best
      Community: 65012:20
      rx pathid: 0, tx pathid: 0x0


csr1#show bgp 10.1.30.0/24
BGP routing table entry for 10.1.30.0/24, version 109
Paths: (2 available, best #2, table default)
Multipath: eiBGP
  Not advertised to any peer
  Refresh Epoch 1
  65515 65012, (received & used)
    10.0.0.6 from 10.0.0.6 (10.0.0.6)
      Origin IGP, localpref 100, valid, external, multipath(oldest)
      Community: 65012:30
      rx pathid: 0, tx pathid: 0
  Refresh Epoch 1
  65515 65012, (received & used)
    10.0.0.7 from 10.0.0.7 (10.0.0.7)
      Origin IGP, localpref 100, valid, external, multipath, best
      Community: 65012:30
      rx pathid: 0, tx pathid: 0x0
```

eBGP has no split horizon and uses AS-path to detect loops. A BGP router that encounters its own AS in the AS-path of an incoming eBGP update, silently ignores the information.
The AS-path attribute is then the primary means of detecting routing information loops in eBGP session.
Since AS-path is modified only on eBGP sessions, this loop preventing mechanism can only be used in between different ASNs, not within them.
The loop prevention mechanism in csr2 determines a rejection of prefixes advertised from csr3, because it can see its own AS in the AS_PATH attribute.

```console
csr2#show ip bgp
BGP table version is 97, local router ID is 172.16.0.20
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
              r RIB-failure, S Stale, m multipath, b backup-path, f RT-Filter,
              x best-external, a additional-path, c RIB-compressed,
              t secondary path,
Origin codes: i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

     Network          Next Hop            Metric LocPrf Weight Path
 *>   10.0.0.0/24      10.0.0.6                               0 65515 i
 *m                    10.0.0.7                               0 65515 i
 *>   10.1.10.0/24     10.0.0.6                               0 65515 65011 i
 *m                    10.0.0.7                               0 65515 65011 i
 *>   10.1.11.0/24     10.0.0.6                               0 65515 65011 i
 *m                    10.0.0.7                               0 65515 65011 i
 *>   10.1.20.0/24     0.0.0.0                  0         32768 i
 *>   10.1.21.0/24     0.0.0.0                  0         32768 i
 *>   172.16.0.10/32   10.0.0.6                               0 65515 i
 *m                    10.0.0.7                               0 65515 i
 r>   172.16.0.20/32   10.0.0.6                               0 65515 i
 rm                    10.0.0.7                               0 65515 i
 *m   172.16.0.30/32   10.0.0.6                               0 65515 i
 *>                    10.0.0.7                               0 65515 i
csr2#

```

The same behaviour happens in csr3, discarding the advertisments 10.1.20.0/24,10.1.21.0/24 received from the csr2.
The standard eBGP behaviour can be changed, by overriding the loop prevention mechanism of eBGP by "allowas-in":

```console
csr2(config-router)# bgp 65012
csr2(config-router)# address-family ipv4
csr2(config-router-af)#neighbor 10.0.0.6 allowas-in 1
csr2(config-router-af)#neighbor 10.0.0.7 allowas-in 1
```

In the command:
**neighbor ip-address allowas-in *[number]*** 
*[number]*: specifies the number of times to allow the advertisement of all prefixes containing duplicate ASNs

In the bgp table of csr2 is now installed the network prefixes 10.1.30.0/24, 10.1.31.0/24 advertised from csr3:

```console
csr2#show ip bgp
BGP table version is 113, local router ID is 172.16.0.20
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
              r RIB-failure, S Stale, m multipath, b backup-path, f RT-Filter,
              x best-external, a additional-path, c RIB-compressed,
              t secondary path,
Origin codes: i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

     Network          Next Hop            Metric LocPrf Weight Path
 *>   10.0.0.0/24      10.0.0.6                               0 65515 i
 *m                    10.0.0.7                               0 65515 i
 *>   10.1.10.0/24     10.0.0.6                               0 65515 65011 i
 *m                    10.0.0.7                               0 65515 65011 i
 *>   10.1.11.0/24     10.0.0.6                               0 65515 65011 i
 *m                    10.0.0.7                               0 65515 65011 i
 *>   10.1.20.0/24     0.0.0.0                  0         32768 i
 *>   10.1.21.0/24     0.0.0.0                  0         32768 i
 *m   10.1.30.0/24     10.0.0.7                               0 65515 65012 i
 *>                    10.0.0.6                               0 65515 65012 i
 *m   10.1.31.0/24     10.0.0.7                               0 65515 65012 i
 *>                    10.0.0.6                               0 65515 65012 i
 *>   172.16.0.10/32   10.0.0.6                               0 65515 i
 *m                    10.0.0.7                               0 65515 i
 r>   172.16.0.20/32   10.0.0.6                               0 65515 i
 rm                    10.0.0.7                               0 65515 i
 *m   172.16.0.30/32   10.0.0.6                               0 65515 i
 *>                    10.0.0.7                               0 65515 i
```


In csr3 the mechanism of loop prevention is still set to default. Let's see how the crs3 rejected networks 10.1.20.0/24, 10.1.21.0/24 advertised from csr2:

```console
! set the level of logging:  5  (notification)
csr3(config)#logging monitor 5
! display debug command output and system error messages for the current vty session
csr3#terminal monitor
csr2# debug bgp ipv4 unicast event
csr2# debug bgp ipv4 unicast update

To trigger the event, reset the bgp session csr3-vpng gateway:
csr3#clear ip bgp *
```

```console
*May 29 21:53:44.387: BGP(0): 10.0.0.6 rcv UPDATE w/ attr: nexthop 10.0.0.6, origin inde, originator 0.0.0.0, merged path 65515 65012, AS_PATH , community 65012:20, extended community , SSA attribute
*May 29 21:53:44.387: BGP(0): 10.0.0.6 rcv UPDATE about 10.1.20.0/24 -- DENIED due to: AS-PATH contains our own AS;
*May 29 21:53:44.387: BGP(0): 10.0.0.6 rcv UPDATE about 10.1.21.0/24 -- DENIED due to: AS-PATH contains our own AS;
...
*May 29 21:53:45.190: BGP(0): 10.0.0.7 rcv UPDATE w/ attr: nexthop 10.0.0.7, origin ibu, originator 0.0.0.0, merged path 65515 65012, AS_PATH , community 65012:20, extended community , SSA attribute
*May 29 21:53:45.190: BGP(0): 10.0.0.7 rcv UPDATE about 10.1.20.0/24 -- DENIED due to: AS-PATH contains our own AS;
*May 29 21:53:45.190: BGP(0): 10.0.0.7 rcv UPDATE about 10.1.21.0/24 -- DENIED due to: AS-PATH contains our own AS;
```


To disable the logging in the vty session:
```console
csr3# undebug all
```

### <a name="vWAN"></a>3. Notes

#### <a name="vWAN"></a>3.1 SSH sessions
When you start an SSH session to the CSR 1000v, ensure that you do not configure the terminal VTY timeout
as infinite—do not configure: **exec-timeout 0 0**. Use a non-zero value for the timeout; for example,
exec-timeout 4 0 (this command specifies a timeout of four minutes and zero seconds).
The reason why the exec-timeout 0 0 command causes an issue is as follows:
Azure enforces a timeout for the console idle period of between 4 and 30 minutes. When the idle timer expires,
Azure disconnects the SSH session. However, the session is not cleared from the point of view of the CSR
1000v, as the timeout was set to infinite (by the exec-timeout 0 0 configuration command). The disconnection
causes a terminal session to be orphaned. The session in the CSR 1000v remains open indefinitely. If you try
to establish a new SSH session, a new virtual terminal session is used. If this pattern continues to occur, the
number of allowed simultaneous terminal sessions is reached and no new sessions can be established.
In addition to configuring the exec-timeout command correctly, it is also a good practice to delete idle virtual
terminal sessions using the commands that are shown in the following example:

```
csr# show users
Line User Host(s) Idle Location
2 vty 0 cisco idle 00:07:40 128.107.241.177
* 3 vty 1 cisco idle 00:00:00 128.107.241.177
csr# clear line 2
```

If the workarounds in the preceding scenarios are ineffective, as a last resort, you can restart the Cisco CSR
1000v in the Azure portal.

In powershel script **step02.ps1**, the Azure public public IP associated with the Cisco CSR is created with an idle-timeout of 20 minutes:

```
New-AzPublicIpAddress -IdleTimeoutInMinutes 20
```
the idle-timout of Azue public IP specifies how many minutes to keep a TCP connection remains open without relying on clients to send keep-alive messages. The idle-timeout associated with Azure public IP is set to longer interval compare with the Cisco terminal VTY timeout:
```
line vty 0 4
 exec-timeout 15 0
```
to avoid orphan sessions on vty.
The value of 15 min guaratees SSH session remains open enough to configure the device.



<!--Image References-->

[1]: ./media/network-overview.png "network overview"
[2]: ./media/network-diagram.png "network diagram"
[3]: ./media/case1.png "case1"
[4]: ./media/step1.png "network diagram step1"
[5]: ./media/step2.png "network diagram step2"
[6]: ./media/step3.png "network diagram step3"
[7]: ./media/step4.png "network diagram step4"
[8]: ./media/sites-communication.png "communication between sites"
[9]: ./media/case2.png  "case2"

<!--Link References-->

