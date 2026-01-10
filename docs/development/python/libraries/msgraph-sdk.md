---
title: Microsoft Graph SDK - Unified API for Microsoft 365 Services
description: Comprehensive guide to Microsoft Graph SDK for Python, providing unified access to Microsoft 365 data including users, groups, mail, calendar, files, and teams with built-in authentication
---

The Microsoft Graph SDK for Python provides a type-safe, efficient way to access Microsoft 365 services through the Microsoft Graph API. It offers a unified programming model to interact with data from Azure Active Directory, Office 365, Windows, and Enterprise Mobility + Security.

## Overview

Microsoft Graph SDK simplifies interaction with Microsoft's cloud services by providing a consistent, strongly-typed API that abstracts the complexity of REST calls, authentication, and request batching. Built on modern Python standards, it enables developers to build powerful applications that leverage the Microsoft 365 ecosystem.

### The Problem Microsoft Graph SDK Solves

Traditional Microsoft 365 integration faced numerous challenges:

- **API Fragmentation**: Different APIs for Exchange, SharePoint, OneDrive, Teams
- **Authentication Complexity**: Multiple authentication flows and token management
- **Request Management**: Manual handling of pagination, throttling, and batching
- **Type Safety**: No compile-time validation of API calls
- **Version Management**: Tracking breaking changes across service updates
- **Error Handling**: Inconsistent error responses across services

### The Microsoft Graph SDK Solution

The SDK addresses these challenges through:

- **Unified API**: Single endpoint for all Microsoft 365 services
- **Integrated Authentication**: Built-in Azure Identity support
- **Automatic Pagination**: Transparent handling of large result sets
- **Type-Safe Models**: Strongly-typed request builders and response models
- **Request Batching**: Efficient bulk operations
- **Resilience**: Built-in retry logic and throttling management
- **Service Client Pattern**: Fluent, discoverable API design

## Installation

### Core Package

Install the Microsoft Graph SDK and authentication library:

```bash
# Install Graph SDK
pip install msgraph-sdk

# Install Azure Identity for authentication
pip install azure-identity

# Install both together
pip install msgraph-sdk azure-identity
```

### Using UV (Recommended)

For faster installation:

```bash
# Install with UV
uv pip install msgraph-sdk azure-identity

# Create project environment
uv venv
uv pip install msgraph-sdk azure-identity
```

### Optional Dependencies

Additional packages for specific scenarios:

```bash
# For working with large files
pip install msgraph-sdk[files]

# Development dependencies
pip install msgraph-sdk[dev]
```

### Beta API Support

Access preview features with the beta SDK:

```bash
# Install beta version (preview features)
pip install msgraph-sdk-beta

# Note: Beta APIs may change without notice
```

### Verify Installation

```bash
# Check version
python -c "import msgraph; print(msgraph.__version__)"

# Verify imports
python -c "from msgraph import GraphServiceClient; print('Success')"
```

### System Requirements

- **Python**: 3.8 or higher (3.11+ recommended)
- **Operating Systems**: Linux, macOS, Windows
- **Dependencies**: msgraph-core, azure-core, azure-identity, requests

## Core Concepts

### Graph Service Client

The central object for all Microsoft Graph operations:

```python
from msgraph import GraphServiceClient
from azure.identity import DefaultAzureCredential

# Create client
credential = DefaultAzureCredential()
client = GraphServiceClient(credentials=credential)

# Access resources through fluent API
users = await client.users.get()
```

### Request Builders

Fluent API for constructing requests:

```python
# Build request with filters and selections
users = await client.users.get(
    query_parameters={
        '$filter': "startswith(displayName,'John')",
        '$select': 'displayName,mail,userPrincipalName',
        '$top': 10
    }
)
```

### Permissions and Scopes

Microsoft Graph uses OAuth 2.0 scopes for authorization:

- **Delegated permissions**: User context (user signed in)
- **Application permissions**: App-only context (no user)

Common scopes:

- `User.Read`: Read user profile
- `User.ReadWrite.All`: Read and write all users
- `Mail.Send`: Send mail as user
- `Files.ReadWrite.All`: Read and write all files

## Authentication

### Using DefaultAzureCredential (Recommended)

Simplest authentication for most scenarios:

```python
from msgraph import GraphServiceClient
from azure.identity import DefaultAzureCredential

# Create credential
credential = DefaultAzureCredential()

# Create Graph client
scopes = ['https://graph.microsoft.com/.default']
client = GraphServiceClient(credentials=credential, scopes=scopes)

# Use client
user = await client.me.get()
print(f"Signed in as: {user.display_name}")
```

### Interactive Browser Authentication

For desktop applications and local development:

```python
from msgraph import GraphServiceClient
from azure.identity import InteractiveBrowserCredential

# Interactive authentication
credential = InteractiveBrowserCredential(
    client_id="your-client-id",
    tenant_id="your-tenant-id"
)

# Delegated permissions scope
scopes = ['User.Read', 'Mail.Read', 'Calendars.ReadWrite']
client = GraphServiceClient(credentials=credential, scopes=scopes)

# Browser opens for sign-in
user = await client.me.get()
```

### Client Credentials (Application Permissions)

For background services and automation:

```python
from msgraph import GraphServiceClient
from azure.identity import ClientSecretCredential

# Service principal authentication
credential = ClientSecretCredential(
    tenant_id="your-tenant-id",
    client_id="your-client-id",
    client_secret="your-client-secret"
)

# Application permissions
scopes = ['https://graph.microsoft.com/.default']
client = GraphServiceClient(credentials=credential, scopes=scopes)

# Access all users (requires admin consent)
users = await client.users.get()
```

### On-Behalf-Of Flow

For web APIs calling Microsoft Graph:

```python
from msgraph import GraphServiceClient
from azure.identity import OnBehalfOfCredential

# Exchange user token for Graph token
credential = OnBehalfOfCredential(
    tenant_id="your-tenant-id",
    client_id="your-client-id",
    client_secret="your-client-secret",
    user_assertion=user_access_token  # From incoming request
)

scopes = ['https://graph.microsoft.com/.default']
client = GraphServiceClient(credentials=credential, scopes=scopes)

# Act on behalf of user
user = await client.me.get()
```

### Device Code Flow

For devices without browsers:

```python
from msgraph import GraphServiceClient
from azure.identity import DeviceCodeCredential

def device_code_callback(device_code):
    print(f"Visit {device_code.verification_uri}")
    print(f"Enter code: {device_code.user_code}")

credential = DeviceCodeCredential(
    client_id="your-client-id",
    tenant_id="your-tenant-id",
    prompt_callback=device_code_callback
)

scopes = ['User.Read', 'Mail.Read']
client = GraphServiceClient(credentials=credential, scopes=scopes)

# User completes authentication on another device
user = await client.me.get()
```

### Managed Identity (Azure Resources)

For Azure-hosted applications:

```python
from msgraph import GraphServiceClient
from azure.identity import ManagedIdentityCredential

# Use system-assigned managed identity
credential = ManagedIdentityCredential()

scopes = ['https://graph.microsoft.com/.default']
client = GraphServiceClient(credentials=credential, scopes=scopes)

# Secure access without storing credentials
users = await client.users.get()
```

### Certificate-Based Authentication

More secure than client secrets:

```python
from msgraph import GraphServiceClient
from azure.identity import ClientCertificateCredential

credential = ClientCertificateCredential(
    tenant_id="your-tenant-id",
    client_id="your-client-id",
    certificate_path="/path/to/certificate.pem"
)

scopes = ['https://graph.microsoft.com/.default']
client = GraphServiceClient(credentials=credential, scopes=scopes)

users = await client.users.get()
```

## Common Operations

### Working with Users

#### Get Current User

```python
from msgraph import GraphServiceClient
from azure.identity import DefaultAzureCredential

credential = DefaultAzureCredential()
client = GraphServiceClient(credentials=credential)

# Get signed-in user profile
user = await client.me.get()

print(f"Display Name: {user.display_name}")
print(f"Email: {user.mail}")
print(f"Job Title: {user.job_title}")
print(f"Office Location: {user.office_location}")
```

#### List All Users

```python
# Get all users (requires User.Read.All)
users_response = await client.users.get()

for user in users_response.value:
    print(f"{user.display_name} - {user.user_principal_name}")

# With pagination
all_users = []
page_iterator = users_response

while page_iterator:
    all_users.extend(page_iterator.value)
    if page_iterator.odata_next_link:
        page_iterator = await client.users.with_url(
            page_iterator.odata_next_link
        ).get()
    else:
        break

print(f"Total users: {len(all_users)}")
```

#### Filter and Search Users

```python
from msgraph.generated.users.users_request_builder import UsersRequestBuilder

# Filter users by department
query_params = UsersRequestBuilder.UsersRequestBuilderGetQueryParameters(
    filter="department eq 'Engineering'",
    select=['displayName', 'mail', 'department'],
    top=25,
    orderby=['displayName']
)

request_config = UsersRequestBuilder.UsersRequestBuilderGetRequestConfiguration(
    query_parameters=query_params
)

users = await client.users.get(request_configuration=request_config)

for user in users.value:
    print(f"{user.display_name} - {user.department}")

# Search users (requires ConsistencyLevel header)
from msgraph.generated.models.o_data_errors.o_data_error import ODataError

try:
    query_params = UsersRequestBuilder.UsersRequestBuilderGetQueryParameters(
        search='"displayName:John"',
        select=['displayName', 'mail'],
        orderby=['displayName']
    )
    
    request_config = UsersRequestBuilder.UsersRequestBuilderGetRequestConfiguration(
        query_parameters=query_params,
        headers={'ConsistencyLevel': 'eventual'}
    )
    
    users = await client.users.get(request_configuration=request_config)
    
    for user in users.value:
        print(user.display_name)
except ODataError as error:
    print(f"Error: {error.error.message}")
```

#### Get Specific User

```python
# By user principal name or ID
user = await client.users.by_user_id('john@contoso.com').get()

print(f"Display Name: {user.display_name}")
print(f"Department: {user.department}")
print(f"Manager: {user.manager.display_name if user.manager else 'None'}")

# Get user's manager
manager = await client.users.by_user_id('john@contoso.com').manager.get()
print(f"Manager: {manager.display_name}")

# Get user's direct reports
reports = await client.users.by_user_id('john@contoso.com').direct_reports.get()
for report in reports.value:
    print(f"Direct Report: {report.display_name}")
```

#### Create User

```python
from msgraph.generated.models.user import User
from msgraph.generated.models.password_profile import PasswordProfile

# Create new user
new_user = User()
new_user.account_enabled = True
new_user.display_name = "John Doe"
new_user.mail_nickname = "johnd"
new_user.user_principal_name = "johnd@contoso.com"

# Set password
password_profile = PasswordProfile()
password_profile.force_change_password_next_sign_in = True
password_profile.password = "Temporary123!"
new_user.password_profile = password_profile

# Additional properties
new_user.given_name = "John"
new_user.surname = "Doe"
new_user.job_title = "Software Engineer"
new_user.department = "Engineering"
new_user.office_location = "Building 1"

# Create user
created_user = await client.users.post(new_user)
print(f"Created user: {created_user.id}")
```

#### Update User

```python
from msgraph.generated.models.user import User

# Update user properties
user_update = User()
user_update.job_title = "Senior Software Engineer"
user_update.department = "Engineering"
user_update.office_location = "Building 2"
user_update.mobile_phone = "+1 (555) 123-4567"

await client.users.by_user_id('johnd@contoso.com').patch(user_update)
print("User updated successfully")
```

#### Delete User

```python
# Delete user
await client.users.by_user_id('johnd@contoso.com').delete()
print("User deleted")

# Restore deleted user (within 30 days)
deleted_user = await client.directory.deleted_items.by_directory_object_id(
    user_id
).restore.post()
```

### Working with Groups

#### List Groups

```python
# Get all groups
groups = await client.groups.get()

for group in groups.value:
    print(f"{group.display_name} - {group.mail}")

# Filter groups by type
query_params = {
    '$filter': "groupTypes/any(c:c eq 'Unified')",  # Microsoft 365 groups
    '$select': 'displayName,mail,description'
}

groups = await client.groups.get(query_parameters=query_params)
```

#### Create Group

```python
from msgraph.generated.models.group import Group

# Create Microsoft 365 group
new_group = Group()
new_group.display_name = "Engineering Team"
new_group.mail_nickname = "engineering"
new_group.description = "Engineering department collaboration"
new_group.group_types = ["Unified"]  # Microsoft 365 group
new_group.mail_enabled = True
new_group.security_enabled = False

created_group = await client.groups.post(new_group)
print(f"Created group: {created_group.id}")

# Create security group
security_group = Group()
security_group.display_name = "IT Security Team"
security_group.mail_nickname = "itsecurity"
security_group.mail_enabled = False
security_group.security_enabled = True

created_security = await client.groups.post(security_group)
```

#### Manage Group Members

```python
# Get group members
members = await client.groups.by_group_id(group_id).members.get()

for member in members.value:
    print(f"Member: {member.display_name}")

# Add member to group
from msgraph.generated.models.reference_create import ReferenceCreate

member_ref = ReferenceCreate()
member_ref.odata_id = f"https://graph.microsoft.com/v1.0/users/{user_id}"

await client.groups.by_group_id(group_id).members.ref.post(member_ref)
print("Member added to group")

# Remove member from group
await client.groups.by_group_id(group_id).members.by_directory_object_id(
    user_id
).ref.delete()
print("Member removed from group")

# Get group owners
owners = await client.groups.by_group_id(group_id).owners.get()

for owner in owners.value:
    print(f"Owner: {owner.display_name}")

# Add owner
owner_ref = ReferenceCreate()
owner_ref.odata_id = f"https://graph.microsoft.com/v1.0/users/{user_id}"

await client.groups.by_group_id(group_id).owners.ref.post(owner_ref)
```

#### Check Group Membership

```python
# Check if user is member of group
is_member = await client.groups.by_group_id(group_id).members.by_directory_object_id(
    user_id
).get()

if is_member:
    print("User is a member")

# Get user's group memberships
user_groups = await client.users.by_user_id(user_id).member_of.get()

for group in user_groups.value:
    print(f"Member of: {group.display_name}")

# Check transitive group memberships
from msgraph.generated.users.item.check_member_groups.check_member_groups_post_request_body import CheckMemberGroupsPostRequestBody

request_body = CheckMemberGroupsPostRequestBody()
request_body.group_ids = [group_id1, group_id2, group_id3]

result = await client.users.by_user_id(user_id).check_member_groups.post(
    request_body
)

print(f"User is member of these groups: {result.value}")
```

### Working with Mail

#### Send Email

```python
from msgraph.generated.models.message import Message
from msgraph.generated.models.item_body import ItemBody
from msgraph.generated.models.body_type import BodyType
from msgraph.generated.models.recipient import Recipient
from msgraph.generated.models.email_address import EmailAddress

# Create message
message = Message()
message.subject = "Project Status Update"

# Body
body = ItemBody()
body.content_type = BodyType.Html
body.content = """
<html>
<body>
<h1>Project Status</h1>
<p>The project is progressing well.</p>
<ul>
  <li>Phase 1: Complete</li>
  <li>Phase 2: In Progress</li>
</ul>
</body>
</html>
"""
message.body = body

# Recipients
to_recipient = Recipient()
to_address = EmailAddress()
to_address.address = "recipient@contoso.com"
to_recipient.email_address = to_address
message.to_recipients = [to_recipient]

# CC recipients
cc_recipient = Recipient()
cc_address = EmailAddress()
cc_address.address = "manager@contoso.com"
cc_recipient.email_address = cc_address
message.cc_recipients = [cc_recipient]

# Send email
await client.me.send_mail.post(body={'message': message})
print("Email sent successfully")
```

#### Send Email with Attachments

```python
from msgraph.generated.models.file_attachment import FileAttachment
import base64

# Create message
message = Message()
message.subject = "Report with Attachment"

body = ItemBody()
body.content_type = BodyType.Text
body.content = "Please find the attached report."
message.body = body

to_recipient = Recipient()
to_address = EmailAddress()
to_address.address = "recipient@contoso.com"
to_recipient.email_address = to_address
message.to_recipients = [to_recipient]

# Add attachment
attachment = FileAttachment()
attachment.name = "report.pdf"
attachment.content_type = "application/pdf"

# Read file and encode as base64
with open("report.pdf", "rb") as file:
    attachment.content_bytes = base64.b64encode(file.read()).decode()

message.attachments = [attachment]

# Send email
await client.me.send_mail.post(body={'message': message})
print("Email with attachment sent")
```

#### Read Emails

```python
# Get inbox messages
messages = await client.me.messages.get()

for message in messages.value:
    print(f"Subject: {message.subject}")
    print(f"From: {message.from_.email_address.address}")
    print(f"Received: {message.received_date_time}")
    print("---")

# Filter unread messages
query_params = {
    '$filter': 'isRead eq false',
    '$select': 'subject,from,receivedDateTime',
    '$top': 10,
    '$orderby': 'receivedDateTime desc'
}

unread_messages = await client.me.messages.get(query_parameters=query_params)

# Get specific folder messages
inbox_messages = await client.me.mail_folders.by_mail_folder_id(
    'inbox'
).messages.get()

# Search messages
query_params = {
    '$search': '"subject:project status"',
    '$select': 'subject,from,receivedDateTime'
}

search_results = await client.me.messages.get(query_parameters=query_params)
```

#### Manage Email Folders

```python
# List mail folders
folders = await client.me.mail_folders.get()

for folder in folders.value:
    print(f"{folder.display_name} - {folder.unread_item_count} unread")

# Create folder
from msgraph.generated.models.mail_folder import MailFolder

new_folder = MailFolder()
new_folder.display_name = "Project Archive"

created_folder = await client.me.mail_folders.post(new_folder)
print(f"Created folder: {created_folder.id}")

# Move message to folder
await client.me.messages.by_message_id(message_id).move.post(
    body={'destination_id': folder_id}
)

# Delete folder
await client.me.mail_folders.by_mail_folder_id(folder_id).delete()
```

#### Reply to Email

```python
from msgraph.generated.users.item.messages.item.reply.reply_post_request_body import ReplyPostRequestBody

# Reply to message
reply_body = ReplyPostRequestBody()

message = Message()
body = ItemBody()
body.content_type = BodyType.Html
body.content = "<p>Thank you for your email. I'll review this today.</p>"
message.body = body

reply_body.message = message
reply_body.comment = "Thanks!"

await client.me.messages.by_message_id(message_id).reply.post(reply_body)
print("Reply sent")

# Reply all
await client.me.messages.by_message_id(message_id).reply_all.post(reply_body)

# Forward message
from msgraph.generated.users.item.messages.item.forward.forward_post_request_body import ForwardPostRequestBody

forward_body = ForwardPostRequestBody()
forward_body.comment = "FYI"

to_recipient = Recipient()
to_address = EmailAddress()
to_address.address = "colleague@contoso.com"
to_recipient.email_address = to_address
forward_body.to_recipients = [to_recipient]

await client.me.messages.by_message_id(message_id).forward.post(forward_body)
```

### Working with Calendar

#### Get Calendar Events

```python
# Get all calendar events
events = await client.me.calendar.events.get()

for event in events.value:
    print(f"Subject: {event.subject}")
    print(f"Start: {event.start.date_time}")
    print(f"End: {event.end.date_time}")
    print("---")

# Get events for specific date range
from datetime import datetime, timedelta

start_date = datetime.now()
end_date = start_date + timedelta(days=7)

query_params = {
    '$filter': f"start/dateTime ge '{start_date.isoformat()}' and end/dateTime le '{end_date.isoformat()}'",
    '$select': 'subject,start,end,location,attendees',
    '$orderby': 'start/dateTime'
}

events = await client.me.calendar.events.get(query_parameters=query_params)

# Get calendar view (better for date ranges)
from msgraph.generated.users.item.calendar.calendar_view.calendar_view_request_builder import CalendarViewRequestBuilder

query_params = CalendarViewRequestBuilder.CalendarViewRequestBuilderGetQueryParameters(
    start_date_time=start_date.isoformat(),
    end_date_time=end_date.isoformat(),
    select=['subject', 'start', 'end', 'organizer']
)

request_config = CalendarViewRequestBuilder.CalendarViewRequestBuilderGetRequestConfiguration(
    query_parameters=query_params
)

calendar_view = await client.me.calendar.calendar_view.get(
    request_configuration=request_config
)
```

#### Create Calendar Event

```python
from msgraph.generated.models.event import Event
from msgraph.generated.models.date_time_time_zone import DateTimeTimeZone
from msgraph.generated.models.location import Location
from msgraph.generated.models.attendee import Attendee
from msgraph.generated.models.email_address import EmailAddress
from msgraph.generated.models.attendee_type import AttendeeType

# Create event
event = Event()
event.subject = "Team Meeting"

body = ItemBody()
body.content_type = BodyType.Html
body.content = "<p>Discuss project status and next steps</p>"
event.body = body

# Start time
start = DateTimeTimeZone()
start.date_time = "2024-02-15T10:00:00"
start.time_zone = "Pacific Standard Time"
event.start = start

# End time
end = DateTimeTimeZone()
end.date_time = "2024-02-15T11:00:00"
end.time_zone = "Pacific Standard Time"
event.end = end

# Location
location = Location()
location.display_name = "Conference Room A"
event.location = location

# Attendees
attendee = Attendee()
email_address = EmailAddress()
email_address.address = "attendee@contoso.com"
email_address.name = "John Doe"
attendee.email_address = email_address
attendee.type = AttendeeType.Required
event.attendees = [attendee]

# Create event
created_event = await client.me.calendar.events.post(event)
print(f"Event created: {created_event.id}")

# Create recurring event
from msgraph.generated.models.patterned_recurrence import PatternedRecurrence
from msgraph.generated.models.recurrence_pattern import RecurrencePattern
from msgraph.generated.models.recurrence_pattern_type import RecurrencePatternType
from msgraph.generated.models.recurrence_range import RecurrenceRange
from msgraph.generated.models.recurrence_range_type import RecurrenceRangeType

event = Event()
event.subject = "Weekly Team Standup"

# Set recurrence
recurrence = PatternedRecurrence()

pattern = RecurrencePattern()
pattern.type = RecurrencePatternType.Weekly
pattern.interval = 1
pattern.days_of_week = ["Monday", "Wednesday", "Friday"]
recurrence.pattern = pattern

range = RecurrenceRange()
range.type = RecurrenceRangeType.EndDate
range.start_date = "2024-02-01"
range.end_date = "2024-12-31"
recurrence.range = range

event.recurrence = recurrence

created_recurring = await client.me.calendar.events.post(event)
```

#### Update Calendar Event

```python
# Update event
event_update = Event()
event_update.subject = "Updated: Team Meeting"

location = Location()
location.display_name = "Conference Room B"
event_update.location = location

await client.me.calendar.events.by_event_id(event_id).patch(event_update)
print("Event updated")

# Accept meeting invitation
await client.me.events.by_event_id(event_id).accept.post(
    body={'comment': 'I will attend', 'send_response': True}
)

# Decline meeting
await client.me.events.by_event_id(event_id).decline.post(
    body={'comment': 'Unable to attend', 'send_response': True}
)

# Tentatively accept
await client.me.events.by_event_id(event_id).tentatively_accept.post(
    body={'comment': 'Tentatively accepted', 'send_response': True}
)
```

#### Delete Calendar Event

```python
# Delete single event
await client.me.calendar.events.by_event_id(event_id).delete()

# Cancel meeting (sends cancellation to attendees)
await client.me.events.by_event_id(event_id).cancel.post(
    body={'comment': 'Meeting cancelled due to conflicts'}
)
```

### Working with Files (OneDrive/SharePoint)

#### List Files and Folders

```python
# List files in root of OneDrive
drive_items = await client.me.drive.root.children.get()

for item in drive_items.value:
    if item.folder:
        print(f"Folder: {item.name}")
    elif item.file:
        print(f"File: {item.name} - {item.size} bytes")

# List files in specific folder
folder_items = await client.me.drive.items.by_drive_item_id(
    folder_id
).children.get()

# Search for files
query_params = {
    '$search': 'project report'
}

search_results = await client.me.drive.root.search(
    q='project report'
).get()

for item in search_results.value:
    print(f"Found: {item.name} at {item.parent_reference.path}")

# Get recently used files
recent_items = await client.me.drive.recent.get()
```

#### Download Files

```python
# Download file content
content = await client.me.drive.items.by_drive_item_id(file_id).content.get()

# Save to local file
with open("downloaded_file.pdf", "wb") as f:
    f.write(content)

print("File downloaded")

# Download with progress tracking
import aiohttp

download_url = f"https://graph.microsoft.com/v1.0/me/drive/items/{file_id}/content"
headers = {"Authorization": f"Bearer {access_token}"}

async with aiohttp.ClientSession() as session:
    async with session.get(download_url, headers=headers) as response:
        total_size = int(response.headers.get('content-length', 0))
        downloaded = 0
        
        with open("large_file.zip", "wb") as f:
            async for chunk in response.content.iter_chunked(1024 * 1024):
                f.write(chunk)
                downloaded += len(chunk)
                progress = (downloaded / total_size) * 100
                print(f"Downloaded: {progress:.1f}%")
```

#### Upload Files

```python
# Small file upload (< 4MB)
with open("document.pdf", "rb") as f:
    file_content = f.read()

uploaded_item = await client.me.drive.root.items_with_path(
    "documents/document.pdf"
).content.put(file_content)

print(f"File uploaded: {uploaded_item.id}")

# Large file upload with upload session (> 4MB)
from msgraph.generated.models.upload_session import UploadSession

# Create upload session
upload_session = await client.me.drive.items.by_drive_item_id(
    folder_id
).items_with_path("large_video.mp4").create_upload_session.post()

# Upload in chunks
chunk_size = 320 * 1024 * 10  # 3.2 MB chunks

with open("large_video.mp4", "rb") as f:
    file_size = os.path.getsize("large_video.mp4")
    position = 0
    
    while position < file_size:
        chunk = f.read(chunk_size)
        chunk_end = min(position + len(chunk), file_size)
        
        headers = {
            "Content-Range": f"bytes {position}-{chunk_end-1}/{file_size}",
            "Content-Length": str(len(chunk))
        }
        
        # Upload chunk
        async with aiohttp.ClientSession() as session:
            async with session.put(
                upload_session.upload_url,
                data=chunk,
                headers=headers
            ) as response:
                if response.status in [200, 201]:
                    print(f"Upload complete")
                    break
                elif response.status == 202:
                    position += len(chunk)
                    progress = (position / file_size) * 100
                    print(f"Uploaded: {progress:.1f}%")
```

#### Manage Files and Folders

```python
from msgraph.generated.models.drive_item import DriveItem
from msgraph.generated.models.folder import Folder

# Create folder
folder = DriveItem()
folder.name = "Project Files"
folder.folder = Folder()

created_folder = await client.me.drive.root.children.post(folder)
print(f"Folder created: {created_folder.id}")

# Copy file
from msgraph.generated.models.item_reference import ItemReference

copy_request = DriveItem()
parent_reference = ItemReference()
parent_reference.id = destination_folder_id
copy_request.parent_reference = parent_reference
copy_request.name = "Copy of document.pdf"

copy_operation = await client.me.drive.items.by_drive_item_id(
    file_id
).copy.post(copy_request)

# Move file
move_request = DriveItem()
parent_reference = ItemReference()
parent_reference.id = destination_folder_id
move_request.parent_reference = parent_reference

moved_item = await client.me.drive.items.by_drive_item_id(
    file_id
).patch(move_request)

# Rename file
rename_request = DriveItem()
rename_request.name = "new_name.pdf"

renamed_item = await client.me.drive.items.by_drive_item_id(
    file_id
).patch(rename_request)

# Delete file
await client.me.drive.items.by_drive_item_id(file_id).delete()
```

#### Share Files

```python
from msgraph.generated.models.permission import Permission
from msgraph.generated.models.drive_recipient import DriveRecipient

# Create sharing link
share_request = {
    'type': 'view',  # or 'edit'
    'scope': 'anonymous'  # or 'organization'
}

permission = await client.me.drive.items.by_drive_item_id(
    file_id
).create_link.post(share_request)

print(f"Sharing link: {permission.link.web_url}")

# Grant permissions to specific user
from msgraph.generated.users.item.drive.items.item.invite.invite_post_request_body import InvitePostRequestBody

invite_body = InvitePostRequestBody()

recipient = DriveRecipient()
recipient.email = "user@contoso.com"
invite_body.recipients = [recipient]

invite_body.message = "Please review this document"
invite_body.require_sign_in = True
invite_body.send_invitation = True
invite_body.roles = ["write"]

invitation = await client.me.drive.items.by_drive_item_id(
    file_id
).invite.post(invite_body)

# List permissions
permissions = await client.me.drive.items.by_drive_item_id(
    file_id
).permissions.get()

for perm in permissions.value:
    print(f"Permission ID: {perm.id}")
    if perm.granted_to_identities_v2:
        for identity in perm.granted_to_identities_v2:
            print(f"  User: {identity.user.email}")

# Remove permission
await client.me.drive.items.by_drive_item_id(
    file_id
).permissions.by_permission_id(permission_id).delete()
```

### Working with Microsoft Teams

#### List Teams

```python
# Get user's joined teams
teams = await client.me.joined_teams.get()

for team in teams.value:
    print(f"Team: {team.display_name}")
    print(f"Description: {team.description}")

# Get all teams in organization (requires admin)
all_teams = await client.teams.get()
```

#### Get Team Channels

```python
# List channels
channels = await client.teams.by_team_id(team_id).channels.get()

for channel in channels.value:
    print(f"Channel: {channel.display_name}")
    print(f"Type: {channel.membership_type}")

# Get primary channel
primary_channel = await client.teams.by_team_id(
    team_id
).primary_channel.get()

print(f"Primary channel: {primary_channel.display_name}")
```

#### Create Channel

```python
from msgraph.generated.models.channel import Channel
from msgraph.generated.models.channel_membership_type import ChannelMembershipType

# Create standard channel
channel = Channel()
channel.display_name = "Project Updates"
channel.description = "Channel for project status updates"
channel.membership_type = ChannelMembershipType.Standard

created_channel = await client.teams.by_team_id(team_id).channels.post(channel)
print(f"Channel created: {created_channel.id}")

# Create private channel
private_channel = Channel()
private_channel.display_name = "Leadership Team"
private_channel.description = "Private channel for leadership discussions"
private_channel.membership_type = ChannelMembershipType.Private

created_private = await client.teams.by_team_id(team_id).channels.post(
    private_channel
)
```

#### Post Messages to Channel

```python
from msgraph.generated.models.chat_message import ChatMessage
from msgraph.generated.models.item_body import ItemBody
from msgraph.generated.models.body_type import BodyType

# Post message to channel
message = ChatMessage()

body = ItemBody()
body.content_type = BodyType.Html
body.content = """
<h1>Project Milestone Achieved!</h1>
<p>We've successfully completed Phase 1 of the project.</p>
<ul>
  <li>All requirements met</li>
  <li>Testing completed</li>
  <li>Ready for deployment</li>
</ul>
"""
message.body = body

posted_message = await client.teams.by_team_id(team_id).channels.by_channel_id(
    channel_id
).messages.post(message)

print(f"Message posted: {posted_message.id}")

# Reply to message
reply = ChatMessage()
reply_body = ItemBody()
reply_body.content_type = BodyType.Text
reply_body.content = "Great work team!"
reply.body = reply_body

reply_message = await client.teams.by_team_id(team_id).channels.by_channel_id(
    channel_id
).messages.by_chat_message_id(message_id).replies.post(reply)

# Post message with @mention
mention_message = ChatMessage()
mention_body = ItemBody()
mention_body.content_type = BodyType.Html
mention_body.content = '<at id="0">John</at> Can you review this?'
mention_message.body = mention_body

from msgraph.generated.models.chat_message_mention import ChatMessageMention
from msgraph.generated.models.chat_message_mentioned_identity_set import ChatMessageMentionedIdentitySet
from msgraph.generated.models.identity import Identity

mention = ChatMessageMention()
mention.id = 0

identity_set = ChatMessageMentionedIdentitySet()
identity = Identity()
identity.display_name = "John Doe"
identity.id = user_id
identity_set.user = identity

mention.mentioned = identity_set
mention_message.mentions = [mention]

posted = await client.teams.by_team_id(team_id).channels.by_channel_id(
    channel_id
).messages.post(mention_message)
```

#### Manage Team Members

```python
from msgraph.generated.models.aad_user_conversation_member import AadUserConversationMember

# List team members
members = await client.teams.by_team_id(team_id).members.get()

for member in members.value:
    print(f"Member: {member.display_name}")
    print(f"Roles: {member.roles}")

# Add member to team
member = AadUserConversationMember()
member.odata_type = "#microsoft.graph.aadUserConversationMember"
member.roles = ["member"]  # or ["owner"]

from msgraph.generated.models.identity_set import IdentitySet
from msgraph.generated.models.identity import Identity

identity_set = IdentitySet()
identity = Identity()
identity.id = user_id
identity_set.user = identity
member.user = identity_set

added_member = await client.teams.by_team_id(team_id).members.post(member)
print(f"Member added: {added_member.id}")

# Update member role
from msgraph.generated.models.conversation_member import ConversationMember

member_update = ConversationMember()
member_update.roles = ["owner"]

await client.teams.by_team_id(team_id).members.by_conversation_member_id(
    member_id
).patch(member_update)

# Remove member
await client.teams.by_team_id(team_id).members.by_conversation_member_id(
    member_id
).delete()
```

#### Access Team Files

```python
# Get team's default document library
drive = await client.teams.by_team_id(team_id).drive.get()
print(f"Team drive: {drive.id}")

# List files in team's root folder
team_files = await client.teams.by_team_id(team_id).drive.root.children.get()

for item in team_files.value:
    print(f"File: {item.name}")

# Access channel files folder
channel_folder = await client.teams.by_team_id(team_id).channels.by_channel_id(
    channel_id
).files_folder.get()

channel_files = await client.drives.by_drive_id(
    channel_folder.parent_reference.drive_id
).items.by_drive_item_id(channel_folder.id).children.get()
```

## Advanced Features

### Batch Requests

Batch requests allow you to combine multiple operations into a single HTTP request, reducing network overhead and improving performance.

```python
from msgraph.generated.models.batch_request import BatchRequest
from msgraph.generated.models.batch_request_item import BatchRequestItem

# Create batch request
batch = BatchRequest()

# Add multiple requests
request1 = BatchRequestItem()
request1.id = "1"
request1.method = "GET"
request1.url = "/me"

request2 = BatchRequestItem()
request2.id = "2"
request2.method = "GET"
request2.url = "/me/messages?$top=5"

request3 = BatchRequestItem()
request3.id = "3"
request3.method = "GET"
request3.url = "/me/events?$top=5"

batch.requests = [request1, request2, request3]

# Send batch request
batch_response = await client.batch.post(batch)

# Process responses
for response in batch_response.responses:
    print(f"Request {response.id}: Status {response.status}")
    if response.status == 200:
        print(f"Body: {response.body}")
```

### Change Notifications (Webhooks)

Subscribe to change notifications to receive real-time updates when resources change.

```python
from msgraph.generated.models.subscription import Subscription
from datetime import datetime, timedelta

# Create subscription
subscription = Subscription()
subscription.change_type = "created,updated"
subscription.notification_url = "https://yourapp.com/api/notifications"
subscription.resource = "me/messages"
subscription.expiration_date_time = (datetime.now() + timedelta(hours=1)).isoformat()
subscription.client_state = "secretClientValue"

created_subscription = await client.subscriptions.post(subscription)
print(f"Subscription created: {created_subscription.id}")

# Renew subscription
subscription_update = Subscription()
subscription_update.expiration_date_time = (
    datetime.now() + timedelta(hours=1)
).isoformat()

await client.subscriptions.by_subscription_id(
    subscription_id
).patch(subscription_update)

# Delete subscription
await client.subscriptions.by_subscription_id(subscription_id).delete()

# List active subscriptions
subscriptions = await client.subscriptions.get()

for sub in subscriptions.value:
    print(f"Subscription: {sub.id} - Expires: {sub.expiration_date_time}")
```

### Delta Queries

Delta queries allow you to track changes to resources without fetching the entire dataset.

```python
# Initial delta query for users
delta_response = await client.users.delta.get()

users = delta_response.value
delta_link = delta_response.odata_delta_link

print(f"Initial sync: {len(users)} users")

# Store delta link for future queries

# Later, get only changes
if delta_link:
    changes_response = await client.users.delta.with_url(delta_link).get()
    
    for user in changes_response.value:
        if hasattr(user, 'removed'):
            print(f"User deleted: {user.id}")
        else:
            print(f"User created/updated: {user.display_name}")
    
    # Update delta link
    delta_link = changes_response.odata_delta_link

# Delta query for messages
message_delta = await client.me.messages.delta.get()

for message in message_delta.value:
    print(f"Message: {message.subject}")

next_delta_link = message_delta.odata_delta_link
```

### Large File Upload

For files larger than 4MB, use the upload session API with chunked uploads.

```python
import os
import math

async def upload_large_file(client, file_path, destination_path):
    file_size = os.path.getsize(file_path)
    chunk_size = 320 * 1024 * 10  # 3.2 MB
    
    # Create upload session
    upload_session = await client.me.drive.root.items_with_path(
        destination_path
    ).create_upload_session.post()
    
    upload_url = upload_session.upload_url
    
    # Upload chunks
    with open(file_path, 'rb') as f:
        chunk_count = math.ceil(file_size / chunk_size)
        
        for i in range(chunk_count):
            chunk_start = i * chunk_size
            chunk_end = min(chunk_start + chunk_size, file_size)
            
            # Read chunk
            f.seek(chunk_start)
            chunk_data = f.read(chunk_end - chunk_start)
            
            # Upload chunk
            headers = {
                'Content-Length': str(len(chunk_data)),
                'Content-Range': f'bytes {chunk_start}-{chunk_end-1}/{file_size}'
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.put(
                    upload_url,
                    data=chunk_data,
                    headers=headers
                ) as response:
                    if response.status in [200, 201]:
                        result = await response.json()
                        print(f"Upload complete: {result}")
                        return result
                    elif response.status == 202:
                        progress = ((chunk_end / file_size) * 100)
                        print(f"Progress: {progress:.1f}%")
                    else:
                        error = await response.text()
                        raise Exception(f"Upload failed: {error}")

# Usage
await upload_large_file(
    client,
    "/path/to/large/file.zip",
    "documents/large_file.zip"
)
```

### Pagination Handling

Handle large result sets efficiently with pagination.

```python
# Manual pagination
async def get_all_users(client):
    all_users = []
    
    # Get first page
    users_response = await client.users.get()
    all_users.extend(users_response.value)
    
    # Continue with next pages
    while users_response.odata_next_link:
        users_response = await client.users.with_url(
            users_response.odata_next_link
        ).get()
        all_users.extend(users_response.value)
    
    return all_users

# Usage
all_users = await get_all_users(client)
print(f"Total users: {len(all_users)}")

# Page iterator helper
async def iterate_pages(client, initial_response):
    current_page = initial_response
    
    while current_page:
        for item in current_page.value:
            yield item
        
        if current_page.odata_next_link:
            current_page = await client.users.with_url(
                current_page.odata_next_link
            ).get()
        else:
            break

# Usage
users_response = await client.users.get()

async for user in iterate_pages(client, users_response):
    print(user.display_name)
```

### Error Handling and Retries

Implement robust error handling with exponential backoff for rate limiting.

```python
from msgraph.generated.models.o_data_errors.o_data_error import ODataError
import asyncio
from typing import TypeVar, Callable

T = TypeVar('T')

async def retry_with_backoff(
    operation: Callable,
    max_retries: int = 3,
    initial_delay: float = 1.0
) -> T:
    delay = initial_delay
    
    for attempt in range(max_retries):
        try:
            return await operation()
        except ODataError as error:
            if error.response_status_code == 429:  # Too Many Requests
                retry_after = error.response_headers.get('Retry-After', delay)
                print(f"Rate limited. Retrying after {retry_after}s...")
                await asyncio.sleep(float(retry_after))
                delay *= 2  # Exponential backoff
            elif error.response_status_code >= 500:  # Server errors
                if attempt < max_retries - 1:
                    print(f"Server error. Retrying in {delay}s...")
                    await asyncio.sleep(delay)
                    delay *= 2
                else:
                    raise
            else:
                raise
        except Exception as e:
            if attempt < max_retries - 1:
                print(f"Error: {e}. Retrying in {delay}s...")
                await asyncio.sleep(delay)
                delay *= 2
            else:
                raise
    
    raise Exception(f"Operation failed after {max_retries} attempts")

# Usage
async def get_user_operation():
    return await client.users.by_user_id(user_id).get()

try:
    user = await retry_with_backoff(get_user_operation)
except ODataError as error:
    print(f"Graph API Error: {error.error.code} - {error.error.message}")
except Exception as e:
    print(f"Unexpected error: {e}")
```

### Custom Headers and Middleware

Add custom headers or middleware for advanced scenarios.

```python
from kiota_abstractions.request_information import RequestInformation
from kiota_abstractions.request_option import RequestOption

# Custom request option
class CustomHeaderOption(RequestOption):
    def __init__(self, header_name: str, header_value: str):
        self.header_name = header_name
        self.header_value = header_value

# Add custom header to request
from msgraph.generated.users.users_request_builder import UsersRequestBuilder

request_config = UsersRequestBuilder.UsersRequestBuilderGetRequestConfiguration()
request_config.headers = {
    'CustomHeader': 'CustomValue',
    'ConsistencyLevel': 'eventual'
}

users = await client.users.get(request_configuration=request_config)

# Prefer specific response format
request_config.headers = {
    'Prefer': 'outlook.timezone="Pacific Standard Time"'
}

events = await client.me.events.get(request_configuration=request_config)
```

## Best Practices

### Credential Management

```python
# Use DefaultAzureCredential for production
from azure.identity import DefaultAzureCredential

credential = DefaultAzureCredential()
client = GraphServiceClient(credentials=credential)

# Never hardcode credentials
# ❌ Bad
client_secret = "my_secret_value"

# ✅ Good - use environment variables
import os
client_secret = os.getenv('AZURE_CLIENT_SECRET')

# ✅ Better - use Azure Key Vault
from azure.keyvault.secrets import SecretClient

vault_url = "https://myvault.vault.azure.net"
key_vault_client = SecretClient(vault_url=vault_url, credential=credential)

client_secret = key_vault_client.get_secret("graph-api-secret").value
```

### Permission Selection

```python
# Request minimal permissions required
# Instead of User.ReadWrite.All, use User.Read if only reading

# Application permissions for background services
scopes = ['.default']  # Uses permissions granted during app registration

# Delegated permissions for user context
scopes = [
    'User.Read',
    'Mail.Send',
    'Calendars.ReadWrite'
]

# Check permissions before operations
try:
    user = await client.me.get()
except ODataError as error:
    if error.response_status_code == 403:
        print("Insufficient permissions. Required: User.Read")
```

### Performance Optimization

```python
# Use $select to request only needed properties
query_params = {
    '$select': 'displayName,mail,department',
    '$top': 100
}

users = await client.users.get(query_parameters=query_params)

# Use $expand to get related resources in one call
query_params = {
    '$expand': 'manager,directReports'
}

user = await client.users.by_user_id(user_id).get(
    query_parameters=query_params
)

# Batch related requests
batch = BatchRequest()
# Add multiple requests to batch
batch_response = await client.batch.post(batch)

# Cache frequently accessed data
from datetime import timedelta
import redis

redis_client = redis.Redis()

def get_cached_user(user_id: str):
    cached = redis_client.get(f"user:{user_id}")
    if cached:
        return json.loads(cached)
    
    user = await client.users.by_user_id(user_id).get()
    redis_client.setex(
        f"user:{user_id}",
        timedelta(hours=1),
        json.dumps(user)
    )
    return user
```

### Rate Limiting Handling

```python
# Monitor rate limit headers
response_headers = {
    'RateLimit-Remaining': '100',
    'RateLimit-Reset': '1234567890'
}

# Implement throttling
import time

class ThrottledClient:
    def __init__(self, client, requests_per_second=10):
        self.client = client
        self.min_interval = 1.0 / requests_per_second
        self.last_request_time = 0
    
    async def throttled_request(self, operation):
        current_time = time.time()
        time_since_last = current_time - self.last_request_time
        
        if time_since_last < self.min_interval:
            await asyncio.sleep(self.min_interval - time_since_last)
        
        result = await operation()
        self.last_request_time = time.time()
        return result

# Usage
throttled = ThrottledClient(client, requests_per_second=5)

users = await throttled.throttled_request(
    lambda: client.users.get()
)
```

### Logging and Debugging

```python
import logging

# Enable SDK logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger('msgraph')
logger.setLevel(logging.DEBUG)

# Log all requests
class LoggingMiddleware:
    async def send(self, request, next_middleware):
        logger.info(f"Request: {request.method} {request.url}")
        logger.debug(f"Headers: {request.headers}")
        
        response = await next_middleware.send(request)
        
        logger.info(f"Response: {response.status_code}")
        logger.debug(f"Response Headers: {response.headers}")
        
        return response

# Use verbose error messages
try:
    user = await client.users.by_user_id(user_id).get()
except ODataError as error:
    logger.error(f"Graph API Error:")
    logger.error(f"  Code: {error.error.code}")
    logger.error(f"  Message: {error.error.message}")
    logger.error(f"  Status: {error.response_status_code}")
    logger.error(f"  Request ID: {error.response_headers.get('request-id')}")
    logger.error(f"  Date: {error.response_headers.get('date')}")
```

### Testing Strategies

```python
# Use mocking for unit tests
from unittest.mock import Mock, AsyncMock
import pytest

@pytest.mark.asyncio
async def test_get_user():
    # Mock GraphServiceClient
    mock_client = Mock()
    mock_client.users.by_user_id.return_value.get = AsyncMock(
        return_value=Mock(
            display_name="John Doe",
            mail="john@contoso.com"
        )
    )
    
    # Test your code
    user = await mock_client.users.by_user_id("123").get()
    assert user.display_name == "John Doe"

# Integration testing with test tenant
async def test_with_test_tenant():
    # Use separate test tenant/app registration
    credential = ClientSecretCredential(
        tenant_id=os.getenv('TEST_TENANT_ID'),
        client_id=os.getenv('TEST_CLIENT_ID'),
        client_secret=os.getenv('TEST_CLIENT_SECRET')
    )
    
    client = GraphServiceClient(credentials=credential, scopes=scopes)
    
    # Run integration tests
    test_user = await client.users.by_user_id('testuser@test.com').get()
    assert test_user is not None
```

## Troubleshooting

### Common Errors

#### 401 Unauthorized

```text
Error: Authentication failed
Solution: Verify credentials and token acquisition
```

```python
# Check token
try:
    token = await credential.get_token('https://graph.microsoft.com/.default')
    print(f"Token acquired: {token.token[:20]}...")
except Exception as e:
    print(f"Token acquisition failed: {e}")

# Verify app registration
# - Check client ID and tenant ID
# - Verify client secret hasn't expired
# - Confirm API permissions granted and admin consented
```

#### 403 Forbidden

```text
Error: Insufficient privileges
Solution: Grant required permissions in Azure AD
```

```python
# Required permissions not granted
# 1. Go to Azure Portal → App Registrations
# 2. Select your application
# 3. API Permissions → Add permission
# 4. Select Microsoft Graph → Application/Delegated
# 5. Search and select required permissions
# 6. Grant admin consent

# Check current token permissions
import jwt

token = await credential.get_token('https://graph.microsoft.com/.default')
decoded = jwt.decode(token.token, options={"verify_signature": False})
print(f"Roles: {decoded.get('roles')}")
print(f"Scopes: {decoded.get('scp')}")
```

#### 429 Too Many Requests

```text
Error: Rate limit exceeded
Solution: Implement retry logic with exponential backoff
```

```python
# See retry_with_backoff function in Advanced Features section

# Monitor throttling
if error.response_status_code == 429:
    retry_after = error.response_headers.get('Retry-After')
    print(f"Throttled. Retry after {retry_after} seconds")
    await asyncio.sleep(int(retry_after))
```

#### 404 Not Found

```text
Error: Resource not found
Solution: Verify resource ID and user permissions
```

```python
try:
    user = await client.users.by_user_id('invalid@contoso.com').get()
except ODataError as error:
    if error.response_status_code == 404:
        print("User not found. Check:")
        print("- User principal name is correct")
        print("- User exists in tenant")
        print("- You have permission to read the user")
```

### Permission Issues

```python
# Verify required vs granted permissions
required_permissions = ['User.Read', 'Mail.Send']

try:
    # Attempt operation
    await client.me.send_mail.post(message)
except ODataError as error:
    if error.response_status_code == 403:
        print("Permission issue. Required permissions:")
        for perm in required_permissions:
            print(f"- {perm}")
        print("\nGrant these permissions in Azure Portal")
```

### Token Issues

```python
# Token expiration
from azure.core.credentials import AccessToken
from datetime import datetime

async def get_valid_token(credential):
    token = await credential.get_token('https://graph.microsoft.com/.default')
    
    # Check if token is about to expire
    expires_on = datetime.fromtimestamp(token.expires_on)
    now = datetime.now()
    
    time_until_expiry = (expires_on - now).total_seconds()
    
    if time_until_expiry < 300:  # Less than 5 minutes
        print("Token expiring soon, refreshing...")
        token = await credential.get_token(
            'https://graph.microsoft.com/.default'
        )
    
    return token

# Token caching issues
# DefaultAzureCredential caches tokens automatically
# For manual caching:
from azure.identity import TokenCachePersistenceOptions

cache_options = TokenCachePersistenceOptions()
credential = DefaultAzureCredential(cache_persistence_options=cache_options)
```

### Network and Proxy Issues

```python
# Configure proxy
import os

os.environ['HTTP_PROXY'] = 'http://proxy.company.com:8080'
os.environ['HTTPS_PROXY'] = 'http://proxy.company.com:8080'

# Trust custom certificates
import certifi

os.environ['REQUESTS_CA_BUNDLE'] = '/path/to/ca-bundle.crt'

# Connection timeout issues
import aiohttp

timeout = aiohttp.ClientTimeout(total=30)  # 30 second timeout

# Retry on network errors
from aiohttp import ClientConnectorError

try:
    users = await client.users.get()
except ClientConnectorError as e:
    print(f"Network error: {e}")
    print("Check:")
    print("- Internet connectivity")
    print("- Firewall rules")
    print("- Proxy configuration")
    print("- DNS resolution")
```

### Debug Mode

```python
# Enable detailed logging
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# HTTP request/response logging
import http.client as http_client

http_client.HTTPConnection.debuglevel = 1

logging.getLogger("requests.packages.urllib3").setLevel(logging.DEBUG)
logging.getLogger("requests.packages.urllib3").propagate = True

# Inspect request details
try:
    user = await client.users.by_user_id(user_id).get()
except Exception as e:
    print(f"Error type: {type(e)}")
    print(f"Error message: {str(e)}")
    if hasattr(e, '__dict__'):
        print(f"Error details: {e.__dict__}")
```

## Resources

- [Official Microsoft Graph SDK Documentation](https://learn.microsoft.com/en-us/graph/sdks/sdks-overview)
- [Microsoft Graph SDK Python GitHub](https://github.com/microsoftgraph/msgraph-sdk-python)
- [Microsoft Graph REST API Reference](https://learn.microsoft.com/en-us/graph/api/overview)
- [Microsoft Graph Explorer](https://developer.microsoft.com/en-us/graph/graph-explorer)
- [PyPI Package](https://pypi.org/project/msgraph-sdk/)
- [Azure Identity Python Documentation](https://learn.microsoft.com/en-us/python/api/azure-identity/azure.identity)
- [Microsoft Graph Permissions Reference](https://learn.microsoft.com/en-us/graph/permissions-reference)
- [Microsoft Graph Best Practices](https://learn.microsoft.com/en-us/graph/best-practices-concept)
- [Microsoft Graph Changelog](https://learn.microsoft.com/en-us/graph/changelog)
- [Microsoft Graph Samples](https://github.com/microsoftgraph/msgraph-samples-dashboard)
