---
title: "Make (Integromat) - AI Workflow Automation"
description: "Guide to using Make for building AI-powered automations and integrations"
author: "Joseph Streeter"
ms.date: "2025-12-31"
ms.topic: "guide"
keywords: ["make", "integromat", "workflow automation", "visual builder", "ai integration"]
uid: docs.ai.automation.make
---

## Overview

Make (formerly Integromat) is a powerful visual workflow automation platform that enables users to connect applications, services, and APIs without writing code. With its intuitive drag-and-drop interface and extensive library of integrations, Make has become a leading choice for building AI-powered automations, from simple chatbot responses to complex multi-step data processing pipelines.

This guide focuses specifically on leveraging Make for AI workflows, including integrating with OpenAI, Anthropic, custom AI models, and building sophisticated automation scenarios that combine AI capabilities with business processes.

### Why Make for AI Automation?

- **Visual Development**: Build complex AI workflows without programming
- **Extensive Integrations**: 1,500+ pre-built connectors including OpenAI, Google AI, and major platforms
- **Real-time Processing**: Trigger AI actions based on events, webhooks, or schedules
- **Advanced Logic**: Implement branching, loops, error handling, and conditional execution
- **Cost-Effective**: Free tier available, pay-per-operation pricing scales with usage
- **Enterprise Ready**: Team collaboration, version control, and security features

## What is Make?

### Description

Make is a visual integration platform (iPaaS) that allows you to design, build, and automate workflows—called "scenarios"—that connect different applications and services. Originally launched as Integromat in 2016, the platform rebranded to Make in 2021 and has since expanded to over 1,500 integrations.

Unlike traditional automation tools that follow simple if-this-then-that logic, Make provides:

- **Visual scenario builder** with drag-and-drop interface
- **Real-time data processing** and transformation
- **Complex routing and conditional logic** for sophisticated workflows
- **Built-in error handling and retry mechanisms**
- **Data storage** for stateful automations
- **HTTP/API modules** for connecting any web service

### Key Features

#### Visual Interface

**Scenario Editor:**

- Drag-and-drop modules onto canvas
- Visual connections between modules show data flow
- Real-time execution preview with data inspection
- Color-coded routes for branching logic
- Zoom and pan for large complex scenarios

**Module Configuration:**

- Form-based settings for each module
- Dynamic field mapping with autocomplete
- Built-in functions for data transformation
- Test execution to verify module behavior

#### Extensive Integrations

**1,500+ Pre-built Apps:**

- **AI Services**: OpenAI, Anthropic Claude, Google AI, Hugging Face
- **Communication**: Slack, Discord, Microsoft Teams, Gmail, Twilio
- **CRM**: Salesforce, HubSpot, Pipedrive, Zoho
- **Databases**: PostgreSQL, MySQL, MongoDB, Airtable, Google Sheets
- **E-commerce**: Shopify, WooCommerce, Stripe
- **Productivity**: Google Workspace, Microsoft 365, Notion, Asana
- **Social Media**: Twitter, Facebook, LinkedIn, Instagram
- **Storage**: Google Drive, Dropbox, OneDrive, AWS S3

**Custom Integrations:**

- HTTP/REST API modules for any web service
- GraphQL support for modern APIs
- SOAP connectors for legacy systems
- FTP/SFTP for file transfers
- Database connectors (SQL, NoSQL)

#### Scenarios (Workflows)

**Scenario Components:**

- **Triggers**: Start scenarios based on events, schedules, or webhooks
- **Actions**: Perform operations (create, update, delete, search)
- **Routers**: Branch execution based on conditions
- **Filters**: Control which data passes through
- **Iterators**: Process arrays and collections
- **Aggregators**: Combine multiple items into one

**Execution Modes:**

- **Scheduled**: Run at specific intervals (every 15 minutes, hourly, daily)
- **Instant**: Triggered by webhooks or real-time events
- **On-demand**: Manual execution for testing or ad-hoc runs

### Pricing

**Free Tier:**

- 1,000 operations per month
- 2 active scenarios
- 15-minute execution interval
- 5 MB data transfer per execution
- 100 MB data storage
- Perfect for testing and small personal projects

**Core Plan ($9/month):**

- 10,000 operations per month
- Unlimited active scenarios
- 1-minute execution interval
- 10 MB data transfer per execution
- 1 GB data storage
- Operations packs available (10k for $9)

**Pro Plan ($16/month):**

- 10,000 operations per month
- Priority execution queue
- Custom apps and functions
- Full-text search in execution history
- Advanced error handling
- Operations packs available (10k for $14)

**Teams Plan ($29/month):**

- 10,000 operations per month
- Team collaboration features
- User role management
- Scenario templates sharing
- Priority support
- Operations packs available (10k for $13)

**Enterprise Plan (Custom):**

- Dedicated infrastructure
- SLA guarantees
- Custom integrations
- On-premises deployment options
- Advanced security and compliance

**Operation Counting:**

- 1 operation = 1 module execution
- Example: Trigger (1 op) + OpenAI call (1 op) + Send email (1 op) = 3 operations per scenario run
- Failed modules still count as operations
- Transfers between modules within same scenario are free

## Getting Started

### Account Setup

#### Creating Your Account

1. **Sign Up**: Visit [make.com](https://www.make.com) and click "Get started free"
2. **Choose Method**: Sign up with email, Google, or Microsoft account
3. **Verify Email**: Confirm your email address
4. **Select Region**: Choose data center location (US, EU, etc.) for data residency
5. **Complete Profile**: Add organization name and use case

#### Initial Configuration

**Organization Setup:**

```markdown
- Organization Name: Your company or personal identifier
- Default Timezone: Sets schedule defaults
- Date Format: MM/DD/YYYY or DD/MM/YYYY
- Number Format: Decimal and thousands separators
```

**API Token Generation:**

- Navigate to Profile > API > Create Token
- Used for programmatic scenario management
- Keep secure—provides full account access

### Dashboard Overview

#### Main Interface Components

**Left Sidebar:**

- **Scenarios**: List of all your workflows
- **Templates**: Pre-built scenario templates
- **Connections**: Saved authentication credentials
- **Data Structures**: Reusable data schemas
- **Data Stores**: Persistent key-value storage
- **Webhooks**: Incoming webhook URLs
- **Keys**: API keys and tokens
- **Teams**: Team management (paid plans)
- **Organizations**: Multi-org switching

**Scenarios Dashboard:**

```markdown
Columns:
- Status: Active (green), Inactive (gray), Error (red)
- Name: Scenario identifier
- Schedule: Execution interval or "On-demand"
- Last Run: Timestamp of most recent execution
- Operations: Total operations consumed
- Actions: Edit, Clone, Delete, View History
```

**Quick Filters:**

- Active/Inactive scenarios
- Scheduled vs Webhook-triggered
- Search by name or description
- Sort by created date, last run, operations

#### Execution History

**Viewing Run Details:**

- Click any scenario > History tab
- See all executions with timestamps
- Filter by Success, Warning, Error status
- Inspect input/output data for each module
- Revert or reprocess failed executions

**History Data Structure:**

```json
{
  "executionId": "550e8400-e29b-41d4-a716-446655440000",
  "scenarioId": 123,
  "status": "success",
  "startTime": "2026-01-04T10:30:00Z",
  "duration": 2.3,
  "operations": 5,
  "dataTransferred": "1.2 MB",
  "modules": [
    {
      "id": 1,
      "name": "OpenAI > Create Completion",
      "status": "success",
      "duration": 1.8,
      "input": {...},
      "output": {...}
    }
  ]
}
```

### First Scenario

#### Building a Simple AI Summarizer

**Objective**: Create a scenario that monitors Gmail for new emails and uses OpenAI to generate summaries.

##### Step 1: Create New Scenario

1. Click "Create a new scenario" button
2. Search for "Gmail" in the app search
3. Select "Gmail > Watch Emails" module

##### Step 2: Configure Gmail Trigger

```markdown
Connection: Click "Add" > Authenticate with Google
Folder: INBOX
Criteria: All emails
Max Results: 10
Schedule: Every 15 minutes
```

##### Step 3: Add Filter (Optional)

- Click the wrench icon between modules
- Add condition: "Subject contains 'Report'"
- This ensures only report emails are processed

##### Step 4: Add OpenAI Module

1. Click the + button after Gmail module
2. Search for "OpenAI"
3. Select "OpenAI > Create Completion"

##### Step 5: Configure OpenAI

```markdown
Connection: Add OpenAI API key (from platform.openai.com)
Model: gpt-4-turbo
Messages:
  - Role: system
    Content: "You are a helpful assistant that summarizes emails concisely."
  - Role: user
    Content: "Summarize this email in 3 bullet points:\n\n{{1.Text Content}}"
Max Tokens: 500
Temperature: 0.3
```

##### Step 6: Send Summary to Slack

1. Add Slack > Send Message module
2. Configure:

```markdown
Connection: Authenticate with Slack workspace
Channel: #email-summaries
Text:
  Email from: {{1.From}}
  Subject: {{1.Subject}}
  
  Summary:
  {{2.choices[].message.content}}
```

##### Step 7: Test Scenario

1. Click "Run once" button
2. Watch execution in real-time
3. Verify each module shows success
4. Check Slack channel for summary

##### Step 8: Activate

1. Click "Scheduling" toggle to ON
2. Scenario will run every 15 minutes automatically
3. Monitor from Execution History

**Complete Scenario Flow:**

```text
[Gmail: Watch Emails]
        ↓
[Filter: Subject contains "Report"]
        ↓
[OpenAI: Create Completion]
        ↓
[Slack: Send Message]
```

**Expected Operations per Run:**

- Gmail Watch: 1 operation
- OpenAI Call: 1 operation per email (max 10)
- Slack Message: 1 operation per email (max 10)
- Total: 1-21 operations per execution

## Core Concepts

### Scenarios

#### What are Scenarios?

Scenarios are complete workflows in Make that define a sequence of operations to automate a process. Each scenario consists of modules connected in a specific order, representing the flow of data and actions.

**Scenario Lifecycle:**

```text
Created → Testing → Active → Monitoring → Maintenance → Archived
```

**Scenario Types:**

1. **Linear Scenarios**: Simple sequential execution (A → B → C)
2. **Branching Scenarios**: Multiple paths based on conditions (A → B or C)
3. **Iterative Scenarios**: Process arrays of data (A → [B1, B2, B3...] → C)
4. **Aggregating Scenarios**: Collect multiple items (A → [B1, B2, B3] → Aggregate → C)

#### Scenario Settings

**General Settings:**

```json
{
  "name": "AI Email Summarizer",
  "description": "Summarizes incoming emails using GPT-4",
  "folder": "AI Automations",
  "tags": ["ai", "email", "openai"],
  "scheduling": {
    "enabled": true,
    "interval": 15,
    "unit": "minutes"
  },
  "maxCycles": 1,
  "sequential": false,
  "autoCommit": true
}
```

**Advanced Options:**

- **Sequential Processing**: Process items one at a time (slower but safer)
- **Max Number of Cycles**: Limit how many times a scenario can run per execution
- **Auto-commit**: Automatically save data stores after each execution
- **Allow Storing Incomplete Executions**: Keep partial results on errors

### Modules

#### Module Categories

**App Modules:**

- Pre-built integrations with specific apps
- Example: "Gmail > Send Email", "OpenAI > Create Completion"
- Automatically handle authentication and API details

**Universal Modules:**

- **HTTP**: Make custom API requests to any service
- **JSON**: Parse and manipulate JSON data
- **XML**: Work with XML documents
- **Text Parser**: Extract data from text using regex
- **Tools**: Utility functions (sleep, set variable, compose)

**Flow Control Modules:**

- **Router**: Split execution into multiple paths
- **Iterator**: Loop through array items
- **Aggregator**: Combine multiple items
- **Filter**: Conditionally allow data through
- **Error Handler**: Catch and handle errors

#### Module Configuration

**Connection Setup:**

```markdown
1. Select module type
2. Click "Add" next to Connection field
3. Choose authentication method:
   - OAuth 2.0 (most common)
   - API Key
   - Basic Auth
   - Custom authentication
4. Follow provider-specific auth flow
5. Connection saved for reuse
```

**Field Mapping:**

- **Static Values**: Type directly into fields
- **Dynamic Values**: Map from previous modules using `{{module.field}}`
- **Functions**: Use built-in functions like `{{formatDate()}}`, `{{upper()}}`, `{{length()}}`
- **Formulas**: Combine multiple values: `{{1.firstName}} {{1.lastName}}`

**Example OpenAI Module Configuration:**

```markdown
Model: gpt-4-turbo
Prompt: Analyze this text: {{1.content}}
Max Tokens: 1000
Temperature: {{if(1.type = "creative", 0.8, 0.2)}}
Response Format: json_object
```

### Routes

#### Understanding Routes

Routes allow scenarios to branch into multiple paths, enabling complex decision-making logic. Each route can have filters that determine if it should execute.

**Router Module:**

```text
          [Route 1: Priority emails] → OpenAI Urgent → Slack Alert
         ↗
[Trigger]
         ↘
          [Route 2: Regular emails] → OpenAI Summary → Email Digest
```

**Route Configuration:**

```json
{
  "routes": [
    {
      "name": "Priority",
      "filter": "{{1.priority}} = high",
      "modules": ["OpenAI", "Slack"]
    },
    {
      "name": "Regular",
      "filter": "{{1.priority}} != high",
      "modules": ["OpenAI", "Email"]
    },
    {
      "name": "Fallback",
      "filter": null,
      "modules": ["Log"]
    }
  ]
}
```

**Route Best Practices:**

- Always include a fallback route without filter (executes if no other route matches)
- Name routes descriptively: "High Priority", "Errors", "Weekend Handling"
- Keep route logic simple—complex conditions should use separate filter modules
- Test each route independently during development

### Filters

#### Filter Operators

**Comparison Operators:**

- **Equals**: `{{value}} = "target"`
- **Not Equals**: `{{value}} != "target"`
- **Greater Than**: `{{number}} > 100`
- **Less Than**: `{{number}} < 50`
- **Contains**: `{{text}} contains "keyword"`
- **Matches Pattern**: `{{email}} matches pattern ".*@company\.com"`

**Logical Operators:**

- **AND**: Multiple conditions must be true
- **OR**: Any condition must be true
- **NOT**: Invert condition

**Advanced Filters:**

```markdown
Complex Example:
  ({{1.type}} = "email" AND {{1.priority}} = "high")
  OR
  ({{1.from}} contains "@executive")
  OR
  ({{1.subject}} matches pattern "URGENT.*")
```

#### Filter Use Cases for AI Workflows

**Content Quality Filtering:**

```markdown
# Only process high-quality content
Filter: {{length(1.content)}} > 100 AND {{1.language}} = "en"
```

**Cost Optimization:**

```markdown
# Avoid expensive AI calls for duplicates
Filter: {{1.isDuplicate}} = false AND {{1.alreadyProcessed}} = false
```

**Error Handling:**

```markdown
# Route failed items to retry logic
Filter: {{1.status}} = "error" AND {{1.retryCount}} < 3
```

### Connections

#### Managing Connections

**Connection Types:**

1. **OAuth 2.0 Connections**
   - Most modern APIs (Google, Microsoft, OpenAI)
   - Automatic token refresh
   - Permission scope management

2. **API Key Connections**
   - Simple authentication with key/secret
   - Manual key rotation required
   - Common for AI services (OpenAI, Anthropic)

3. **Basic Auth Connections**
   - Username and password
   - Less secure, avoid when possible

4. **Custom Connections**
   - Flexible for unique authentication schemes
   - Can implement custom headers, tokens, signing

**Connection Best Practices:**

```markdown
## Security
- Use separate connections for dev/staging/production
- Regularly rotate API keys (quarterly)
- Set up connection monitoring alerts
- Use service accounts, not personal accounts
- Apply principle of least privilege (minimal permissions)

## Organization
- Name connections clearly: "OpenAI - Production", "Gmail - Support"
- Document connection purpose in description
- Share connections only with team members who need them
- Regular audit of unused connections
```

**OpenAI Connection Setup:**

```markdown
1. Go to platform.openai.com/api-keys
2. Create new secret key
3. Copy key (shown only once)
4. In Make: OpenAI module > Add Connection
5. Paste API key
6. Name: "OpenAI - Production GPT-4"
7. Test connection
8. Save
```

**Connection Reuse:**

- Connections can be shared across multiple scenarios
- Updates to connection apply to all using scenarios
- Can duplicate connections for different environments
- Monitor connection usage in Connection dashboard

## AI Integration

### OpenAI Module

#### Available OpenAI Actions

Make provides native OpenAI integration with the following modules:

**Chat Completions (GPT-4, GPT-3.5):**

```json
{
  "module": "OpenAI > Create a Completion",
  "config": {
    "model": "gpt-4-turbo",
    "messages": [
      {
        "role": "system",
        "content": "You are a helpful assistant specializing in {{domain}}."
      },
      {
        "role": "user",
        "content": "{{userInput}}"
      }
    ],
    "maxTokens": 1000,
    "temperature": 0.7,
    "topP": 1,
    "responseFormat": "text"
  }
}
```

**Structured Output (JSON Mode):**

```json
{
  "model": "gpt-4-turbo",
  "messages": [
    {
      "role": "system",
      "content": "Extract structured data as JSON."
    },
    {
      "role": "user",
      "content": "Extract name, email, company from: {{text}}"
    }
  ],
  "responseFormat": {"type": "json_object"},
  "temperature": 0.2
}
```

**Image Generation (DALL-E):**

```json
{
  "module": "OpenAI > Create an Image",
  "prompt": "{{imageDescription}}",
  "model": "dall-e-3",
  "size": "1024x1024",
  "quality": "hd",
  "style": "vivid"
}
```

**Embeddings:**

```json
{
  "module": "OpenAI > Create an Embedding",
  "model": "text-embedding-3-large",
  "input": "{{textToEmbed}}",
  "dimensions": 1536
}
```

**Speech-to-Text (Whisper):**

```json
{
  "module": "OpenAI > Create a Transcription",
  "file": "{{audioFile}}",
  "model": "whisper-1",
  "language": "en",
  "responseFormat": "json"
}
```

#### Advanced OpenAI Techniques

**Function Calling:**

```json
{
  "model": "gpt-4-turbo",
  "messages": [{"role": "user", "content": "What's the weather in Boston?"}],
  "tools": [
    {
      "type": "function",
      "function": {
        "name": "get_weather",
        "description": "Get current weather",
        "parameters": {
          "type": "object",
          "properties": {
            "location": {"type": "string"},
            "unit": {"type": "string", "enum": ["celsius", "fahrenheit"]}
          },
          "required": ["location"]
        }
      }
    }
  ],
  "toolChoice": "auto"
}
```

**Stream Handling:**

- Make doesn't natively support streaming
- For long responses, increase timeout settings
- Consider using HTTP module with custom streaming logic

**Token Optimization:**

```markdown
## Cost Saving Strategies
1. Truncate long inputs to token limits
2. Use GPT-3.5 for simple tasks (20x cheaper)
3. Cache common prompts in data stores
4. Batch multiple requests when possible
5. Set appropriate max_tokens limits
```

### Custom AI APIs

#### Anthropic Claude Integration

**Using HTTP Module:**

```json
{
  "url": "https://api.anthropic.com/v1/messages",
  "method": "POST",
  "headers": [
    {"name": "x-api-key", "value": "{{anthropicKey}}"},
    {"name": "anthropic-version", "value": "2023-06-01"},
    {"name": "content-type", "value": "application/json"}
  ],
  "body": {
    "model": "claude-3-opus-20240229",
    "max_tokens": 1024,
    "messages": [
      {"role": "user", "content": "{{prompt}}"}
    ]
  },
  "parseResponse": true,
  "timeout": 30
}
```

**Extracting Response:**

```markdown
Claude Response Path: {{body.content[].text}}
Usage: {{body.usage.input_tokens}} input, {{body.usage.output_tokens}} output
```

#### Google AI (Gemini) Integration

```json
{
  "url": "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent",
  "method": "POST",
  "headers": [
    {"name": "Content-Type", "value": "application/json"}
  ],
  "queryString": [
    {"name": "key", "value": "{{googleAIKey}}"}
  ],
  "body": {
    "contents": [
      {
        "parts": [
          {"text": "{{prompt}}"}
        ]
      }
    ],
    "generationConfig": {
      "temperature": 0.7,
      "maxOutputTokens": 1000
    }
  }
}
```

#### Hugging Face Models

**Text Generation:**

```json
{
  "url": "https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.2",
  "method": "POST",
  "headers": [
    {"name": "Authorization", "value": "Bearer {{hfToken}}"}
  ],
  "body": {
    "inputs": "{{prompt}}",
    "parameters": {
      "max_new_tokens": 500,
      "temperature": 0.7,
      "top_p": 0.95
    }
  }
}
```

**Image Classification:**

```json
{
  "url": "https://api-inference.huggingface.co/models/google/vit-base-patch16-224",
  "method": "POST",
  "headers": [
    {"name": "Authorization", "value": "Bearer {{hfToken}}"}
  ],
  "body": {"inputs": "{{base64Image}}"}
}
```

### HTTP Requests for AI Endpoints

#### Best Practices

**Error Handling:**

```json
{
  "errorHandler": {
    "type": "resume",
    "retries": 3,
    "interval": 5,
    "backoff": "exponential"
  },
  "statusCodeHandling": {
    "429": "retry_after_delay",
    "500": "retry",
    "401": "fail_immediately"
  }
}
```

**Rate Limiting:**

```markdown
## Strategies
1. Add Sleep modules between calls (Tools > Sleep)
2. Use Data Store to track API call timestamps
3. Implement token bucket algorithm
4. Set max operations per scenario run
5. Distribute calls across multiple scenarios
```

**Timeout Configuration:**

```markdown
AI Service Recommended Timeouts:
- OpenAI GPT-4: 60 seconds
- Anthropic Claude: 45 seconds
- Google Gemini: 30 seconds
- Hugging Face: 120 seconds (cold starts)
- Custom fine-tuned: 90+ seconds
```

### Data Processing for AI

#### Preparing Input Data

**Text Cleaning:**

```javascript
// Use Tools > Set Variable with formula
const cleanText = (text) => {
  return text
    .trim()
    .replace(/\s+/g, ' ')  // Normalize whitespace
    .replace(/[^\x20-\x7E]/g, '')  // Remove non-ASCII
    .substring(0, 10000);  // Truncate to limit
};

cleanText({{1.rawContent}})
```

**JSON Structure for AI:**

```json
{
  "preparedPrompt": {
    "system": "You are analyzing customer feedback.",
    "context": {
      "customerName": "{{1.name}}",
      "purchaseDate": "{{formatDate(1.date, 'YYYY-MM-DD')}}",
      "productCategory": "{{1.category}}"
    },
    "task": "Analyze sentiment and extract key concerns from this feedback",
    "feedback": "{{cleanText(1.comment)}}"
  }
}
```

**Token Counting (Estimation):**

```javascript
// Rough estimate: 1 token ≈ 4 characters for English
const estimateTokens = (text) => {
  return Math.ceil(text.length / 4);
};

// Check before sending to AI
if (estimateTokens({{1.content}}) > 8000) {
  // Truncate or split into chunks
}
```

#### Parsing AI Output

**Extracting from JSON Response:**

```markdown
OpenAI Response: {{2.choices[1].message.content}}
Anthropic Response: {{2.content[1].text}}
Google Gemini: {{2.candidates[1].content.parts[1].text}}
```

**Handling Markdown Output:**

```javascript
// Extract code blocks
const extractCode = (markdown) => {
  const match = markdown.match(/```(?:javascript|python)?\n([\s\S]*?)\n```/);
  return match ? match[1] : '';
};
```

**JSON Parsing:**

```markdown
## If AI returns JSON as text
1. Add JSON > Parse JSON module
2. Input: {{aiResponse.content}}
3. Access parsed data: {{parsedJSON.fieldName}}
```

## Module Types

### Trigger Modules

#### Types of Triggers

**Polling Triggers:**

- **Schedule-Based**: Run at fixed intervals (15 min, 1 hour, daily)
- **Watch Triggers**: Monitor for new/updated items
- Examples: Gmail Watch Emails, Google Sheets Watch Rows, Database Watch Records

**Instant Triggers:**

- **Webhooks**: Real-time HTTP callbacks
- **Event-Based**: Triggered by external events
- Examples: Shopify New Order, Stripe Payment Success, Custom Webhook

#### Trigger Configuration

**Polling Settings:**

```json
{
  "schedule": {
    "interval": 15,
    "unit": "minutes",
    "startDate": "2026-01-04T00:00:00Z",
    "timezone": "America/New_York"
  },
  "maxResults": 10,
  "deduplication": true
}
```

**Webhook Setup:**

```markdown
1. Add Webhooks > Custom Webhook module
2. Copy webhook URL: https://hook.make.com/abc123xyz
3. Configure external service to send events to this URL
4. Determine webhook data structure
5. Run once to capture sample payload
6. Map fields to subsequent modules
```

### Action Modules

Action modules perform operations on external services.

**Common Actions:**

- **Create**: Add new records (Create Contact, Send Email, Upload File)
- **Update**: Modify existing records (Update Row, Patch Document)
- **Delete**: Remove records (Delete File, Remove User)
- **Get**: Retrieve specific items (Get User Info, Download File)

**Action Configuration Example:**

```json
{
  "module": "Airtable > Create a Record",
  "connection": "{{airtableConnection}}",
  "base": "appXXXXXXXXXXXXXX",
  "table": "AI Processed Items",
  "fields": {
    "Input Text": "{{1.originalContent}}",
    "AI Summary": "{{2.choices[1].message.content}}",
    "Processed Date": "{{now}}",
    "Token Count": "{{2.usage.total_tokens}}",
    "Status": "Complete"
  }
}
```

### Search Modules

Search modules find existing records based on criteria.

**Search Use Cases:**

```markdown
## Check for Duplicates
Search > If not found > Create
If found > Update

## Enrich Data
Get partial info > Search full record > Merge data

## Conditional Processing
Search for existing > Process only if status = "pending"
```

**Search Configuration:**

```json
{
  "module": "Google Sheets > Search Rows",
  "spreadsheet": "{{spreadsheetId}}",
  "sheet": "Customers",
  "filter": {
    "column": "Email",
    "operator": "equals",
    "value": "{{1.customerEmail}}"
  },
  "maxResults": 1
}
```

### Iterator Modules

Iterators loop through arrays, processing each item separately.

**When to Use Iterators:**

- Processing multiple files from a list
- Sending individual AI requests for array items
- Creating separate database records

**Iterator Example:**

```text
[Get Array of Documents]
        ↓
    [Iterator]
        ↓
[For each document:]
    ↓
[OpenAI: Analyze Document]
    ↓
[Save Analysis Result]
```

**Configuration:**

```json
{
  "module": "Iterator",
  "array": "{{1.documents}}",
  "batchSize": 5
}
```

### Aggregator Modules

Aggregators combine multiple items into one.

**Aggregator Types:**

- **Text Aggregator**: Combine text with delimiters
- **Table Aggregator**: Create tables/CSV
- **Array Aggregator**: Build JSON arrays
- **Numeric Aggregator**: Sum, average, count

**Example: Batch AI Processing:**

```text
[Watch New Support Tickets] (returns 50 tickets)
        ↓
    [Iterator] (process individually)
        ↓
[OpenAI: Categorize Each Ticket]
        ↓
[Array Aggregator] (collect all results)
        ↓
[Create Summary Report] (single operation with all data)
```

**Array Aggregator Config:**

```json
{
  "module": "Array Aggregator",
  "sourceModule": 3,
  "aggregateFields": [
    {
      "name": "ticketId",
      "value": "{{3.id}}"
    },
    {
      "name": "category",
      "value": "{{4.aiCategory}}"
    },
    {
      "name": "priority",
      "value": "{{4.aiPriority}}"
    }
  ]
}

## Data Flow

### Data Mapping

Connecting fields.

### Data Transformation

Formatting data.

### Variables

Storing values.

### Functions

Built-in functions.

## AI Use Cases

### Content Generation

#### Automated Blog Post Creation

**Scenario Flow:**

```text
[Google Sheets: Watch New Rows] (topic requests)
        ↓
[OpenAI: Generate Outline]
        ↓
[Iterator: Process Each Section]
        ↓
[OpenAI: Write Section Content]
        ↓
[Array Aggregator: Combine Sections]
        ↓
[OpenAI: Create SEO Meta Description]
        ↓
[WordPress: Create Draft Post]
        ↓
[Slack: Notify Team]
```

**Implementation:**

```json
{
  "outlinePrompt": {
    "system": "You are an expert content strategist.",
    "user": "Create a detailed outline with 5 sections for a blog post about: {{1.topic}}. Target audience: {{1.audience}}. Goal: {{1.goal}}. Return as JSON array with title and key points for each section."
  },
  "sectionPrompt": {
    "system": "You are a professional content writer.",
    "user": "Write 300-400 words for this section:\\nTitle: {{iterator.title}}\\nKey Points: {{iterator.keyPoints}}\\nTone: {{1.tone}}\\nInclude examples and actionable advice."
  }
}
```

#### Social Media Content Calendar

**Auto-Generate Posts:**

```json
{
  "scenario": "Weekly Social Media Generation",
  "schedule": "Every Monday at 9 AM",
  "flow": [
    "Get trending topics from Google Trends",
    "OpenAI: Generate 7 post ideas",
    "For each idea: OpenAI: Write post + generate hashtags",
    "DALL-E: Create accompanying image",
    "Upload to Airtable content calendar",
    "Schedule posts in Buffer/Hootsuite"
  ]
}
```

### Customer Support Automation

#### AI-Powered Ticket Routing

**Scenario:**

```text
[Zendesk: Watch New Tickets]
        ↓
[OpenAI: Analyze + Categorize]
    {
      "category": "technical|billing|product",
      "priority": "high|medium|low",
      "sentiment": "positive|neutral|negative",
      "suggestedResponse": "..."
    }
        ↓
    [Router]
   /    |    \\
[High] [Med] [Low]
  ↓     ↓     ↓
[Different Assignment Rules]
```

**AI Analysis Prompt:**

```json
{
  "system": "You are a customer support classifier. Analyze tickets and return structured JSON.",
  "user": "Analyze this support ticket:\\n\\nSubject: {{1.subject}}\\nMessage: {{1.message}}\\nCustomer Tier: {{1.customerTier}}\\n\\nReturn JSON with: category, priority, sentiment, and a brief suggested response.",
  "response_format": {"type": "json_object"}
}
```

#### Auto-Response Generation

```json
{
  "knowledgeBaseRetrieval": {
    "search": "Pinecone vector search with {{ticket.embedding}}",
    "topK": 3,
    "relevantDocs": "{{pincone.matches}}"
  },
  "responseGeneration": {
    "system": "You are a helpful customer support agent. Use the knowledge base articles to answer.",
    "context": "Relevant articles:\\n{{relevantDocs}}",
    "user": "Customer question: {{ticket.message}}\\n\\nWrite a helpful, empathetic response.",
    "humanReview": true
  }
}
```

### Data Analysis and Insights

#### Automated Report Generation

**Weekly Analytics Scenario:**

```text
[Schedule: Every Friday 5 PM]
        ↓
[PostgreSQL: Query Weekly Data]
        ↓
[OpenAI: Analyze Trends]
        ↓
[OpenAI: Generate Executive Summary]
        ↓
[Create Charts (Google Charts API)]
        ↓
[Combine into PDF Report]
        ↓
[Email to Stakeholders]
```

**Analysis Prompt:**

```json
{
  "prompt": "Analyze this week's metrics and provide insights:\\n\\nNew Users: {{1.newUsers}} ({{1.userGrowth}}%)\\nRevenue: ${{1.revenue}} ({{1.revenueGrowth}}%)\\nChurn: {{1.churnRate}}%\\nTop Features: {{1.topFeatures}}\\n\\nProvide:\\n1. Key highlights\\n2. Areas of concern\\n3. Actionable recommendations\\n4. Comparison to last week",
  "format": "structured_report"
}
```

### Image Generation Workflows

#### Product Mockup Generator

```text
[Airtable: New Product Entry]
        ↓
[OpenAI: Generate DALL-E Prompt]
    (Enhance description with style, lighting, composition)
        ↓
[DALL-E 3: Generate Image]
        ↓
[Cloudinary: Upload + Optimize]
        ↓
[Update Airtable with Image URL]
        ↓
[Notify Design Team in Slack]
```

**Prompt Enhancement:**

```json
{
  "systemPrompt": "You are an expert at creating DALL-E prompts for product photography.",
  "userPrompt": "Create a detailed DALL-E prompt for product photography based on this:\\nProduct: {{1.productName}}\\nCategory: {{1.category}}\\nStyle: {{1.preferredStyle}}\\nUse case: {{1.useCase}}\\n\\nInclude: professional studio lighting, composition, camera angle, mood.",
  "temperature": 0.8
}
```

### Translation and Localization

#### Multi-Language Content Pipeline

```text
[WordPress: New Blog Post Published]
        ↓
[Extract Text Content]
        ↓
    [Iterator: Target Languages]
        ↓
[OpenAI: Translate with Context]
    (Consider cultural nuances, idioms, SEO)
        ↓
[Create Localized Version]
        ↓
[Update Translation Memory Database]
```

**Context-Aware Translation:**

```json
{
  "prompt": "Translate this {{1.contentType}} from {{1.sourceLanguage}} to {{targetLanguage}}:\\n\\n{{1.content}}\\n\\nContext:\\n- Audience: {{1.targetAudience}}\\n- Tone: {{1.tone}}\\n- Industry: {{1.industry}}\\n\\nMaintain formatting, adapt cultural references, optimize for local SEO. Return only the translated text.",
  "model": "gpt-4-turbo",
  "temperature": 0.3
}

## Advanced Features

### Webhooks

#### Creating Custom Webhooks

**Setup Process:**

1. Add "Webhooks > Custom Webhook" as first module
2. Copy generated URL: `https://hook.us1.make.com/abc123xyz`
3. Configure webhook in external service
4. Optionally add webhook validation

**Webhook Security:**

```json
{
  "validation": {
    "method": "HMAC_SHA256",
    "secret": "{{webhookSecret}}",
    "headerName": "X-Signature",
    "validateBeforeProcessing": true
  },
  "ipWhitelist": [
    "192.168.1.0/24",
    "10.0.0.0/8"
  ]
}
```

**Webhook Response:**

```json
{
  "status": 200,
  "body": {
    "status": "received",
    "id": "{{execution.id}}",
    "message": "Processing started"
  },
  "headers": [
    {"name": "Content-Type", "value": "application/json"}
  ]
}
```

### Data Stores

#### Using Data Stores for State Management

**Use Cases:**

- Caching AI responses to avoid duplicate processing
- Tracking processed items for deduplication
- Storing conversation context for chatbots
- Rate limiting API calls

**Create Data Store:**

```markdown
1. Go to Data Stores section
2. Click "Add data store"
3. Name: "AI Response Cache"
4. Add data structure (optional):
   - Key: text (unique)
   - Value: text
   - Timestamp: date
   - ExpiresAt: date
```

**Using in Scenarios:**

```json
{
  "checkCache": {
    "module": "Data Store > Search Records",
    "dataStore": "AI Response Cache",
    "filter": "key = {{hash(1.userPrompt)}}"
  },
  "ifCacheHit": {
    "use": "{{cacheRecord.value}}",
    "skip": "OpenAI module"
  },
  "ifCacheMiss": {
    "callOpenAI": true,
    "saveToCache": {
      "key": "{{hash(1.userPrompt)}}",
      "value": "{{aiResponse.content}}",
      "timestamp": "{{now}}",
      "expiresAt": "{{addDays(now, 7)}}"
    }
  }
}
```

**Cache Cleanup:**

```json
{
  "scenario": "Daily Cache Cleanup",
  "schedule": "Daily at 2 AM",
  "flow": "Search expired records > Delete records"
}
```

### Error Handling Strategies

#### Error Handler Module

**Types of Error Handlers:**

- **Resume**: Continue execution after error
- **Rollback**: Undo previous actions
- **Commit**: Save partial results
- **Ignore**: Continue without handling
- **Break**: Stop scenario execution

**Implementation:**

```text
[OpenAI: Generate Content]
    ↓ (if error)
[Error Handler: Resume]
    ↓
[Check Error Type]
    ↓ (if rate limit)
[Sleep 60 seconds]
    ↓
[Retry OpenAI]
    ↓ (if other error)
[Log to Error Database]
    ↓
[Send Alert to Slack]
```

**Error Handler Configuration:**

```json
{
  "errorHandler": {
    "directives": ["resume"],
    "maxRetries": 3,
    "retryInterval": 300,
    "exponentialBackoff": true,
    "onFinalFailure": {
      "action": "log_and_alert",
      "destination": "error_logs_table"
    }
  }
}
```

#### Common Error Patterns

**Rate Limit Handling:**

```json
{
  "errorCheck": "{{contains(error.message, 'rate_limit_exceeded')}}",
  "action": {
    "sleep": "{{error.retryAfter || 60}}",
    "retry": true,
    "incrementCounter": true
  }
}
```

**Token Limit Errors:**

```json
{
  "errorCheck": "{{contains(error.message, 'maximum context length')}}",
  "action": {
    "truncateInput": true,
    "maxLength": 8000,
    "retryWithShorterInput": true
  }
}
```

**Authentication Errors:**

```json
{
  "errorCheck": "{{error.statusCode = 401}}",
  "action": {
    "refreshConnection": true,
    "notifyAdmin": true,
    "pauseScenario": true
  }
}
```

### Scheduling Options

#### Schedule Types

**Fixed Intervals:**

```json
{
  "interval": 15,
  "unit": "minutes",
  "options": ["minutes", "hours", "days", "weeks", "months"]
}
```

**Cron Expression:**

```markdown
## Advanced Scheduling
0 9 * * 1-5    # Weekdays at 9 AM
0 */4 * * *    # Every 4 hours
0 0 1 * *      # First day of month
0 12 * * 0     # Sundays at noon
```

**Time Windows:**

```json
{
  "schedule": {
    "interval": 1,
    "unit": "hour",
    "restrictions": {
      "days": ["monday", "tuesday", "wednesday", "thursday", "friday"],
      "hours": {"start": 9, "end": 18},
      "timezone": "America/New_York"
    }
  }
}
```

### Routers and Complex Logic

#### Multi-Path Routing

```text
                [High Priority + VIP]
               /
              /  [High Priority + Regular]
[Classifier] ----
              \\  [Medium/Low Priority]
               \\
                [Spam/Invalid]
```

**Router Configuration:**

```json
{
  "routes": [
    {
      "name": "Urgent VIP",
      "filter": "{{1.priority}} = high AND {{1.customerTier}} = vip",
      "modules": ["Immediate AI Response", "SMS Alert", "Escalate"]
    },
    {
      "name": "Urgent Standard",
      "filter": "{{1.priority}} = high",
      "modules": ["AI Response", "Email Alert"]
    },
    {
      "name": "Standard",
      "filter": "{{1.priority}} != high",
      "modules": ["Queue for AI Batch Processing"]
    },
    {
      "name": "Invalid",
      "filter": null,
      "modules": ["Log", "Archive"]
    }
  ]
}
```

## Best Practices for AI Scenarios

### Scenario Design Principles

#### Modular Design

```markdown
## Instead of one massive scenario:
✗ Single 50-module mega-scenario

## Use multiple connected scenarios:
✓ Scenario 1: Data Collection → Store in Data Store
✓ Scenario 2: Read from Data Store → AI Processing → Store Results
✓ Scenario 3: Read Results → Distribution

Benefits:
- Easier debugging
- Independent testing
- Better error isolation
- Parallel processing
- Cleaner maintenance
```

#### Idempotency

```json
{
  "principle": "Same input = Same output",
  "implementation": {
    "checkDuplicate": "Search data store for existing result",
    "useCache": "Return cached result if exists",
    "avoidDuplicateActions": "Use unique identifiers for all created records"
  }
}
```

### Error Handling Best Practices

**Multi-Layer Error Handling:**

```text
Layer 1: Module-level error handlers
Layer 2: Route-level fallbacks
Layer 3: Scenario-level error logging
Layer 4: Monitoring and alerting
```

**Error Notification Strategy:**

```json
{
  "criticalErrors": {
    "channel": "PagerDuty",
    "response": "Immediate",
    "examples": ["Authentication failure", "Database connection lost"]
  },
  "highErrors": {
    "channel": "Slack #alerts",
    "response": "Within 1 hour",
    "examples": ["AI API errors", "Rate limit exceeded"]
  },
  "mediumErrors": {
    "channel": "Email digest",
    "response": "Daily summary",
    "examples": ["Single record failures", "Expected exceptions"]
  }
}
```

### Cost Management Strategies

#### Operation Optimization

**Batch Processing:**

```markdown
## Instead of:
✗ Process 100 items individually = 500 operations
  (Trigger + Search + AI + Update + Notify) × 100

## Use:
✓ Collect 100 items → Aggregate → Single AI call with batch = 105 operations
  (Trigger × 100) + Aggregate + AI + Update + Notify
```

**Conditional Execution:**

```json
{
  "costSaving": {
    "filterEarly": "Apply filters before expensive modules",
    "cacheResults": "Store and reuse AI responses",
    "batchRequests": "Combine multiple requests when possible",
    "useWebhooks": "Instant triggers instead of frequent polling",
    "rightSizeModels": "Use GPT-3.5 when GPT-4 isn't needed"
  }
}
```

#### Monitoring Costs

```markdown
## Track Operations
1. View scenario statistics
2. Identify high-operation scenarios
3. Optimize top consumers
4. Set operation budgets per scenario
5. Use Make's usage dashboard

## Example Analysis:
Scenario: Customer Email Responder
- Runs: 1000/month
- Operations per run: 8
- Total: 8,000 ops
- Cost: ~$9 (with Core plan)
- Optimization: Reduce to 5 ops = Save $4/month
```

### Performance Optimization

#### Execution Speed

**Parallel Execution:**

```text
## Sequential (Slow):
[A] → [B] → [C] → [D] = 4 + 3 + 2 + 3 = 12 seconds

## Parallel (Fast):
     [B (3s)]
    /
[A] 
    \\
     [C (2s)]    → [D (3s)] = 4 + 3 + 3 = 10 seconds
```

**Reduce Timeout:**

```json
{
  "httpModule": {
    "timeout": 30,
    "note": "Don't use default 300s if API typically responds in 5s"
  }
}
```

**Lazy Loading:**

```markdown
## Don't fetch all data upfront
✓ Fetch only what's needed for current execution
✓ Use pagination with appropriate limits
✓ Filter data at source (database query) not in Make
```

## Security

### API Key Management

**Best Practices:**

```markdown
## Key Rotation
- Rotate API keys quarterly
- Use separate keys for dev/staging/prod
- Document key ownership and purpose

## Access Control
- Use service accounts, not personal accounts
- Apply least privilege principle
- Audit connection usage regularly

## Key Storage
- Never hardcode keys in scenario descriptions
- Use Make's secure connection storage
- Consider external secret managers for enterprise
```

### Data Privacy

#### Sensitive Data Handling

```json
{
  "dataMinimization": "Only process necessary fields",
  "encryption": "Use HTTPS for all API calls",
  "logging": {
    "excludeFields": ["ssn", "creditCard", "password"],
    "maskPII": true,
    "retentionPeriod": "30 days"
  },
  "compliance": {
    "gdpr": "Implement data deletion scenarios",
    "hipaa": "Use BAA-compliant endpoints",
    "pci": "Avoid processing payment data"
  }
}
```

#### AI Data Privacy

```markdown
## Considerations for AI APIs:
1. Check vendor data retention policies
   - OpenAI: Default 30 days (opt-out available)
   - Anthropic: Not used for training by default
   - Google: Review terms by model

2. Anonymize data before AI processing
   - Remove names, emails, phone numbers
   - Replace with placeholders: [NAME], [EMAIL]
   - De-identify medical/legal information

3. Use enterprise AI tiers for compliance
   - Azure OpenAI (data stays in your tenant)
   - AWS Bedrock (private deployments)
   - Self-hosted models for maximum control
```

### Compliance Considerations

**Audit Logging:**

```json
{
  "logAllExecutions": true,
  "includedData": {
    "timestamp": true,
    "user": true,
    "inputData": "masked",
    "outputData": "masked",
    "apiCalls": true,
    "errors": true
  },
  "retentionPeriod": "7 years",
  "exportFormat": "JSON",
  "compliance": ["SOC 2", "GDPR", "HIPAA"]
}
```

## Resources

### Official Documentation

- [Make Help Center](https://www.make.com/en/help): Comprehensive documentation
- [API Documentation](https://www.make.com/en/api-documentation): Programmatic access
- [Academy](https://www.make.com/en/academy): Video tutorials and courses
- [Templates](https://www.make.com/en/templates): Pre-built scenarios

### Community Resources

- [Make Community Forum](https://community.make.com/): User discussions
- [Discord Server](https://discord.gg/make): Real-time support
- [YouTube Channel](https://www.youtube.com/c/Make): Official tutorials
- [Blog](https://www.make.com/en/blog): Use cases and updates

### Learning Path

**Beginner:**

1. Complete "Getting Started" tutorial (30 min)
2. Build 5 simple scenarios using templates
3. Learn data mapping and functions
4. Understand error handling basics

**Intermediate:**

1. Create custom HTTP integrations
2. Implement complex routing logic
3. Use data stores and variables
4. Build AI-powered automations

**Advanced:**

1. Design multi-scenario architectures
2. Implement custom error handling strategies
3. Optimize for cost and performance
4. Build team collaboration workflows

### AI-Specific Resources

- [OpenAI Platform Docs](https://platform.openai.com/docs): API reference
- [Anthropic Documentation](https://docs.anthropic.com/): Claude API
- [Hugging Face Inference API](https://huggingface.co/inference-api): Model endpoints
- [LangChain Documentation](https://docs.langchain.com/): Advanced AI patterns

---

## Summary

Make (Integromat) is a powerful visual automation platform ideal for building AI-powered workflows without code. Key takeaways:

- **Visual Development**: Drag-and-drop interface for complex scenarios
- **Extensive Integrations**: 1,500+ apps including OpenAI, Anthropic, Google AI
- **Flexible Pricing**: Free tier for testing, scalable plans for production
- **AI Use Cases**: Content generation, customer support, data analysis, translation
- **Best Practices**: Modular design, robust error handling, cost optimization
- **Security**: API key management, data privacy, compliance considerations

Start small with templates, iterate based on results, and scale as you gain confidence. The combination of Make's visual workflow builder and modern AI capabilities enables powerful automations accessible to technical and non-technical users alike.
