# Kusto Query Language

## Azure Log Analyitics Workspaces

Bad Actor Huning - This query takes a list of known bad actors and searches for other sign-ins from the same IP addresses.

```text
let UPNs = dynamic(['hmitchell2@domain.com',
'rrueth@domain.com',
'ebendel@domain.com',
'nmarzette@domain.com',
'againes4@domain.com',
'apage5@domain.com',
'thazelwood@domain.com',
'whelms@domain.com',
'lmalaluan@domain.com']);
let KBAs = SigninLogs
| where TimeGenerated > ago(3d)
| where UserPrincipalName  in (UPNs)
| extend city_ = tostring(LocationDetails.city)
| extend countryOrRegion_ = tostring(LocationDetails.countryOrRegion)
| extend state_ = tostring(LocationDetails.state)
| extend browser_ = tostring(DeviceDetail.browser)
| extend operatingSystem_ = tostring(DeviceDetail.operatingSystem)
| project
    TimeGenerated,
   UserDisplayName,
    UserPrincipalName,
    IPAddress,
    AppDisplayName,
    countryOrRegion_,
    state_,
    city_,
    ResultDescription;
let IPs = KBAs | distinct  IPAddress;
let PBAs = SigninLogs
| where TimeGenerated > ago(3d)
| where IPAddress in (IPs)
| where UserPrincipalName !in (UPNs)
| extend city_ = tostring(LocationDetails.city)
| extend countryOrRegion_ = tostring(LocationDetails.countryOrRegion)
| extend state_ = tostring(LocationDetails.state)
| project
    TimeGenerated,
   UserDisplayName,
    UserPrincipalName,
    IPAddress,
    AppDisplayName,
    countryOrRegion_,
    state_,
    city_,
    ResultDescription;
    KBAs | union PBAs
```

Output:

|TimeGenerated [UTC] | UserDisplayName | UserPrincipalName | IPAddress | AppDisplayName | countryOrOrigin_ | state_ | city_ | ResultDescription |
|--------------------|-----------------|-------------------|-----------|----------------|------------------|--------|-------|-------------------|
| 8/31/2024, 9:34:27.381 PM | againes4 | ```againes4@domain.com``` | 99.52.120.123 | AddName | US | Wisconsin | Racine | Invalid username or password or Invalid on-premise username or password. |
| 8/31/2024, 9:34:38.052 PM | againes4 | ```againes4@domain.com``` | 99.52.120.123 | AddName | US | Wisconsin | Racine | Invalid username or password or Invalid on-premise username or password. |
| 8/31/2024, 9:35:48.617 PM | GAINES, ALYSHA | ```againes4@domain.com``` | 99.52.120.123 | AddName | US | Wisconsin |Racine | |
| 9/1/2024, 4:14:59.822 AM | whelms | ```whelms@domain.com``` | 99.52.120.123 | AddName | US | Wisconsin | Racine | Invalid username or password or Invalid on-premise username or password. |
| 9/1/2024, 4:15:55.997 AM | whelms | ```whelms@domain.com``` | 99.52.120.123 | AddName | US | Wisconsin | Racine | |
| 9/1/2024, 4:38:23.540 AM | thazelwood | ```thazelwood@domain.com``` | 99.52.120.123 | AddName | US | Wisconsin | Racine | Invalid username or password or Invalid on-premise username or password. |
| 9/1/2024, 4:44:31.101 AM | thazelwood | ```thazelwood@domain.com``` | 99.52.120.123 | AddName | US | Wisconsin | Racine | |
| 8/31/2024, 3:40:36.456 PM | hmitchell2 | ```hmitchell2@domain.com``` | 2600:1702:e60:3850:85cf:cd6d:cb5e:a669 | AddName | US | Wisconsin | Milwaukee | |

### Threat Hunting

All Sign-ins from IPs used by known bad actors

```text
let IPAddresses = SigninLogs
| where TimeGenerated > ago(30d)
| where UserPrincipalName in ("user1@domain.com",
"user2@domain.com",
"user3@domain.com",
"user4@domain.com")
| distinct IPAddress;
SigninLogs
| where TimeGenerated > ago(30d)
| where IPAddress in (IPAddresses)
| project TimeGenerated, UserPrincipalName, IPAddress, AppDisplayName, LocationDetails, ResultDescription
| order by UserPrincipalName
| distinct UserPrincipalName
```

## Defender Advanced Threat Hunting

### Email Activity

All messages sent to ```edu-noreply@github.com```

```text
EmailEvents
| where SenderMailFromAddress endswith "edu-noreply@github.com"
| project Timestamp, SenderFromAddress, SenderMailFromAddress, RecipientEmailAddress, Subject
| distinct RecipientEmailAddress
```

Users sending more than 700 messages in one day

```text
EmailEvents
| where EmailDirection == "Outbound"
| where SenderFromAddress !startswith "mailer"
| project Timestamp, SenderFromAddress, SenderMailFromAddress, RecipientEmailAddress, Subject
| summarize count_ = count() by bin(Timestamp, 1d), SenderFromAddress
| where count_ >= 700
```

Number of messages sent by a user

```text
EmailEvents
| where RecipientEmailAddress == "salewis1@domain.com"
| summarize count_ = count() by SenderMailFromAddress
| order by count_
```

Messages sent by a list of users

```text
EmailEvents
| where RecipientEmailAddress in ("user1@domain.com",
"user2@domain.com",
"user3@domain.com",
"user4@domain.com")
| project Timestamp, SenderMailFromAddress, RecipientEmailAddress, Subject, LatestDeliveryLocation, LatestDeliveryAction
```

All Spam and Phishing Messages sent to a list of users

```text
EmailEvents
| where RecipientEmailAddress in ("user1@domain.com",
"user2@domain.com",
"user3@domain.com",
"user4@domain.com")
| where ThreatTypes == @"Phish, Spam"
```

### Authentication

AiTM Attack Authentication

```text
let OfficeHomeSessionIds = 
AADSignInEventsBeta
| where Timestamp > ago(1d)
| where ErrorCode == 0
| where ApplicationId == "4765445b-32c6-49b0-83e6-1d93765276ca" //OfficeHome application 
| where ClientAppUsed == "Browser" 
| where LogonType has "interactiveUser" 
| summarize arg_min(Timestamp, Country) by SessionId;
AADSignInEventsBeta
| where Timestamp > ago(1d)
| where ApplicationId != "4765445b-32c6-49b0-83e6-1d93765276ca"
| where ClientAppUsed == "Browser" 
| project OtherTimestamp = Timestamp, Application, ApplicationId, AccountObjectId, AccountDisplayName, OtherCountry = Country, SessionId
| join OfficeHomeSessionIds on SessionId
| where OtherTimestamp > Timestamp and OtherCountry != Country
```
