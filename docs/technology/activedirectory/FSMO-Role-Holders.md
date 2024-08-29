# Flexible Single Master Operations Roles

There are five special roles that are assigned to Domain Controllers called Flexible Single Master Operations (FSMO). There are two of these roles that are Forest-wide (Schema Master and Domain Naming Master) and three that exist in each domain within the Forest (PDC Emulator, Infrastructure Master, and RID Master)

> [!IMPORTANT]
> In a multi domain environment the Infrastructure Master should not be a Global Catalog.

## FSMO Role and Global Catalog Locations

| **Host Name** | **FSMO Roles** | **GC** | **Hardware Type** | **Domain/Site** |
|--------------|---------------------------|--------|--------------|----------|
| MCGC-PTRX-01 | PDCE | Yes | Virtual | MC/TRX |
| MCGC-PTRX-02 | RID Master | Yes | Virtual | MC/TRX |
| MCDC-PTRX-03 | Infrastructure Master | Yes | Virtual | MC/TRX |
| MCGC-PATKSN-01 | Standby PDCE | Yes | Virtual | MC/FTA |
| MCGC-PATKSN-02 | Standby RID Master | Yes | Virtual | MC/FTA |
| MCDC-PATKSN-03 | Standby Infrastructure Master | Yes | Virtual | MC/FTA |
| MCGC-PAZR-01 | Emergency PDCE, emergency RID Master | Yes | Virtual | MC/AZR |
| MCDC-PAZR-02 | Emergency Infrastructure Master | No | Virtual | MC/AZR |

| **Host Name**  | **FSMO Roles**                         | **GC** | **Hardware Type** | **Domain/Site** |
|----------------|----------------------------------------|--------|-------------------|-----------------|
| MCGC-TTRX-01   | PDCE                                   | Yes    | Virtual           | MCT/TRX         |
| MCGC-TTRX-02   | RID Master                             | Yes    | Virtual           | MCT/TRX         |
| MCGC-TTRX-03   | Infrastructure Master                  | Yes    | Virtual           | MCT/TRX         |
| MCGC-TATKSN-01 | Standby PDCE                           | Yes    | Virtual           | MCT/FTA         |
| MCGC-TATKSN-02 | Standby RID Master                     | Yes    | Virtual           | MCT/FTA         |
| MCGC-TATKSN-03 | Standby Infrastructure Master          | Yes    | Virtual           | MCT/FTA         |
| MCGC-TAZR-01   | Emergency PDCE, emergency RID Master   | Yes    | Virtual           | MCT/AZR         |
| MCGC-TAZR-02   | Emergency Infrastructure Master        | No     | Virtual           | MCT/AZR         |

> [!NOTE]
> In a Single Forest/Single Domain configuration all Domain Controllers, OMDC and non-OMDC, should be Global Catalogs
