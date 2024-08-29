# Sites and Subnets

Created: 2019-05-12 21:50:37 -0500

Modified: 2019-05-13 11:49:48 -0500

---

## Sites

The enterprise will consist mainly of three Active Directory sites with additional sites created as needed for remote locations with poor or unrealizable bandwidth and cloud provided data centers.

The primary site will encompass the entire enterprise. The largest subnets possible are linked to this site as it will act as a catch-all for all smaller subnets that are not defined in other sites.

A second site is created and has all subnets associated with the secondary data center in Ft Atkinson linked to it.

An additional site will be provisioned for Active Directory infrastructure located in the Microsoft Azure cloud environment.

| **Site Name** | **Site Description** | **Subnets** |
|------------|-------------------------|------------------------------------|
| ATK | Fort Atkinson | All IP Subnets associated with Fort Atkinson |
| TRX | Enterprise | 10.0.0.0/8 |
| AZR | Microsoft Azure Datacenter | 10.103.0.0/16 |

## Site Links

Site connectors will be created in a "Hub and Spoke" manner for all sites. A single connection will be created from each spoke site to the hub site. Leaf sites will only be used where physical connectivity routes through the spoke site to the hub site.

All site connectors should use IP transport instead of SMTP.

Site connectors will be named for the two sites that are being connected using the site codes that are created for each and separated by a dash (```<hub site code>``` - ```<spoke site code>```). The site connector's description field will include the long name of the two sites that are being connected separated by a dash. Site cost will be assigned in such a manner that all spoke sites prefer the hub site over another spoke site. The replication interval will be set in such a way that end-to-end replication will generally take no more than six hours.

All inter and intra site links will be created by the Knowledge Consistency Checker (KCC) to make sure that a Domain Controller can find a replication partner. The use of manual site links could result in the isolation of domain controllers from the rest of the network.The creation of manual site links is not recommended by Microsoft and will not be used.

| **Site Link Name** | **Site Link Description** | **Type** | **Cost** | **Replication Interval** | **Change Notify Enabled** |
|------------|----------------|--------|--------|---------------|----------------|
| TRX-ATK | Truax to Ft Atkinson | IP | 100 | 15 Min | True |
| TRX-AZR | Truax to MS Azure | IP | 100 | 15 Min | False |
