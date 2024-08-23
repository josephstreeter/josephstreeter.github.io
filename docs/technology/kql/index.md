# Kusto Query Language

## Azure Log Analyitics Workspaces

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
| where RecipientEmailAddress == "salewis1@madisoncollege.edu"
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
