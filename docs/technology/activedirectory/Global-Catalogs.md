# Global Catalog Services

Created: 2022-08-23 14:33:59 -0500

Modified: 2022-08-23 14:34:06 -0500

---

## Global Catalog

The global catalog is a distributed data repository that contains a searchable, partial representation of every object in every domain in a multi-domain ActiveDirectory Domain Services (ADDS) forest. The global catalog is stored on domain controllers that have been designated as global catalog servers and is distributed through multimaster replication. Searches that are directed to the global catalog are faster because they do not involve referrals to different domain controllers.

In addition to configuration and schema directory partition replicas, every domain controller in a forest stores a full, writable replica of a single domain directory partition. Therefore, a domain controller can locate only the objects in its domain. Locating an object in a different domain would require the user or application to provide the domain of the requested object.

The global catalog provides the ability to locate objects from any domain without having to know the domain name. A global catalog server is a domain controller that, in addition to its full, writable domain directory partition replica, also stores a partial, read-only replica of all other domain directory partitions in the forest. The additional domain directory partitions are partial because only a limited set of attributes is included for each object. By including only the attributes that are most used for searching, every object in every domain in even the largest forest can be represented in the database of a single global catalog server.

What Is the Global Catalog?[http://technet.microsoft.com/en-us/library/cc728188(v=WS.10).aspx](http://technet.microsoft.com/en-us/library/cc728188%28v=WS.10%29.aspx)

### Single Forest, Single Domain

All Domain Controllers are configured as Global Catalogs

### Single Forest, Multiple Domain

- All Domain Controllers are Global Catalogs except forprimaryInfrastructure Master andsecondary standbyand emergency standby Infrastructure Master
