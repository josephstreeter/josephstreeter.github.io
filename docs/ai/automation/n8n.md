---
title: "n8n - AI Workflow Automation"
description: "Comprehensive guide to using n8n for AI-powered workflow automation"
author: "Joseph Streeter"
ms.date: "2025-12-31"
ms.topic: "guide"
keywords: ["n8n", "workflow automation", "open source", "self-hosted", "ai integration"]
uid: docs.ai.automation.n8n
---

## Overview

n8n (pronounced "nodemation") is a powerful open-source workflow automation platform that has emerged as one of the leading tools for AI-powered automation. Unlike traditional automation tools, n8n provides a visual, node-based interface that makes complex workflows accessible to both technical and non-technical users.

This comprehensive guide explores how to leverage n8n for AI automation, from basic setup to advanced AI agent implementations. Whether you're looking to automate simple tasks or build sophisticated AI-powered workflows, n8n provides the flexibility and power you need.

## What is n8n?

### Description

n8n is a free and open-source workflow automation tool that allows you to connect different services and automate tasks through visual workflows. Built on Node.js, n8n provides a web-based interface where you can create workflows by connecting nodes that represent different services, functions, or data transformations.

Key characteristics:

- **Visual workflow builder**: Drag-and-drop interface for creating automation
- **Extensible architecture**: Support for custom nodes and integrations
- **Self-hosted by default**: Full control over your data and workflows
- **Fair-code licensed**: Source-available with sustainable licensing model
- **API-first design**: Everything accessible via REST API

### Key Features

n8n stands out in the automation landscape with several distinctive features:

#### Fair-Code Licensing

- Source code is publicly available for inspection and modification
- Free for personal and small-scale commercial use
- Sustainable business model that ensures long-term development
- No vendor lock-in concerns

#### Self-Hosted Control

- Complete data sovereignty - your workflows and data never leave your infrastructure
- Customizable deployment options (Docker, npm, cloud providers)
- No limits on workflow executions or data processing
- Integration with existing security and compliance frameworks

#### Extensible Platform

- 400+ built-in integrations with popular services
- Custom node development using TypeScript/JavaScript
- Community marketplace for additional nodes
- Plugin architecture for extending functionality

#### AI-First Approach

- Native integration with major AI platforms (OpenAI, Anthropic, Google, etc.)
- Built-in support for LangChain workflows
- Vector database integrations for RAG implementations
- Agent-based automation patterns

### Use Cases

n8n excels in numerous automation scenarios, particularly those involving AI:

#### Business Process Automation

- **Customer support**: Automated ticket routing, response generation, sentiment analysis
- **Lead qualification**: Scoring leads using AI, automatic follow-up sequences
- **Content moderation**: AI-powered content review and approval workflows
- **Invoice processing**: OCR extraction, validation, and payment routing

#### Data Processing and Analysis

- **ETL pipelines**: Extract, transform, and load data between systems
- **Report generation**: Automated dashboard updates and report distribution
- **Data enrichment**: Enhance datasets with AI-generated insights
- **Quality assurance**: Automated data validation and cleansing

#### AI-Powered Workflows

- **Content generation**: Automated blog posts, social media content, product descriptions
- **Document processing**: AI-powered document analysis and summarization
- **Research automation**: Gathering and synthesizing information from multiple sources
- **Personalization engines**: Dynamic content customization based on user behavior

#### DevOps and IT Operations

- **CI/CD automation**: Deployment pipelines with quality checks
- **Monitoring and alerting**: Intelligent incident response and escalation
- **Security automation**: Threat detection and response workflows
- **Infrastructure management**: Automated provisioning and scaling

## Installation

Getting started with n8n is straightforward, with multiple deployment options to suit different needs and technical requirements.

### Cloud Hosting

n8n Cloud provides the fastest way to get started with n8n without managing infrastructure.

#### n8n Cloud Setup

1. Visit [n8n.cloud](https://n8n.cloud) and create an account
2. Choose your pricing plan (free tier available with limitations)
3. Access your instance immediately through the web interface
4. Connect your first services and start building workflows

**Pros:**

- Instant setup with zero configuration
- Automatic updates and maintenance
- Built-in security and compliance
- Collaborative features for teams

**Cons:**

- Data stored on n8n's servers
- Limited customization options
- Usage-based pricing can scale up
- Dependency on n8n's infrastructure

### Self-Hosted Docker

Docker deployment is the most popular self-hosted option, providing excellent control and scalability.

#### Basic Docker Setup

```bash
# Pull the n8n image
docker pull n8n

# Run n8n with persistent data
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8n

# Access n8n at http://localhost:5678
```

#### Production Docker Compose

Create a `docker-compose.yml` for production deployment:

```yaml
version: '3.8'
services:
  n8n:
    image: n8nio/n8n
    restart: always
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=your-secure-password
      - N8N_HOST=your-domain.com
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://your-domain.com/
      - GENERIC_TIMEZONE=America/New_York
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      - postgres
    
  postgres:
    image: postgres:13
    restart: always
    environment:
      POSTGRES_DB: n8n
      POSTGRES_USER: n8n
      POSTGRES_PASSWORD: your-db-password
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  n8n_data:
  postgres_data:
```

Run with: `docker-compose up -d`

### Self-Hosted npm

For Node.js environments, npm installation provides maximum flexibility.

#### Prerequisites

```bash
# Ensure Node.js 16+ is installed
node --version  # Should be 16.x or higher
npm --version   # Should be 8.x or higher
```

#### Installation Steps

```bash
# Install n8n globally
npm install n8n -g

# Start n8n
n8n start

# Or run with custom settings
N8N_BASIC_AUTH_ACTIVE=true \
N8N_BASIC_AUTH_USER=admin \
N8N_BASIC_AUTH_PASSWORD=secure-password \
n8n start
```

#### Production Configuration

Create a `.env` file for production settings:

```bash
# .env file
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your-secure-password
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=https
WEBHOOK_URL=https://your-domain.com/
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=localhost
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=your-db-password
```

### Desktop Application

n8n Desktop provides a local development environment with enhanced debugging capabilities.

#### Installation

1. Download from [n8n.io/desktop](https://n8n.io/desktop)
2. Install the application for your operating system
3. Launch and start building workflows locally
4. Export workflows for deployment to other environments

**Best for:**

- Workflow development and testing
- Learning n8n without server setup
- Offline workflow creation
- Integration with local development tools

## Getting Started

Once n8n is installed, understanding the core concepts and interface is crucial for building effective workflows.

### First Workflow

Let's create a simple workflow that demonstrates n8n's capabilities:

#### Example: Automated Content Generation

This workflow will:

1. Trigger daily at 9 AM
2. Fetch trending topics from a news API
3. Generate social media content using AI
4. Post to Twitter and save to a database

**Step-by-Step Creation:**

1. **Add a Cron Trigger**
   - Drag a "Cron" node to the canvas
   - Set expression: `0 9 * * *` (daily at 9 AM)
   - This will start your workflow automatically

2. **Fetch Trending Topics**
   - Add an "HTTP Request" node
   - Connect it to the Cron trigger
   - Configure:
     - URL: `https://newsapi.org/v2/top-headlines`
     - Method: GET
     - Headers: `X-API-Key: your-api-key`
     - Query Parameters: `country=us&pageSize=5`

3. **Process the Data**
   - Add a "Function" node
   - Extract article titles and descriptions:

   ```javascript
   const articles = $input.first().json.articles;
   const topics = articles.map(article => ({
     title: article.title,
     description: article.description,
     url: article.url
   }));
   return topics.map(topic => ({ json: topic }));
   ```

4. **Generate Content with AI**
   - Add an "OpenAI" node
   - Configure for chat completion:

   ```text
   Model: gpt-4
   Messages: [
     {
       "role": "system",
       "content": "Create engaging social media content based on news topics"
     },
     {
       "role": "user", 
       "content": "Create a tweet about: {{ $json.title }}"
     }
   ]
   ```

5. **Post to Social Media**
   - Add a "Twitter" node
   - Connect your Twitter credentials
   - Post the generated content

### Interface Overview

The n8n interface consists of several key areas that work together to provide a seamless workflow building experience:

#### Canvas Area

- **Primary workspace** where you build workflows by adding and connecting nodes
- **Zoom controls** for navigating large workflows
- **Grid system** helps align nodes visually
- **Connection lines** show data flow between nodes
- **Execution indicators** show the path data takes during execution

#### Node Panel

- **Searchable catalog** of all available nodes
- **Categories** organize nodes by function (triggers, actions, AI, etc.)
- **Favorites** section for frequently used nodes
- **Recently used** nodes for quick access
- **Custom nodes** appear here when installed

#### Settings Panel

- **Workflow settings** including name, description, and tags
- **Execution settings** for error handling and timeouts
- **Variable management** for workflow-level data
- **Sharing options** for collaboration

#### Execution Panel

- **Execution history** shows past workflow runs
- **Real-time monitoring** of active executions
- **Error details** for debugging failed runs
- **Performance metrics** for optimization

### Basic Concepts

Understanding these fundamental concepts is essential for effective n8n usage:

#### Nodes

Nodes are the building blocks of n8n workflows. Each node performs a specific function:

- **Input**: Receives data from previous nodes
- **Processing**: Transforms, analyzes, or acts on the data
- **Output**: Sends processed data to subsequent nodes

```javascript
// Example node data structure
{
  "json": {
    "name": "John Doe",
    "email": "john@example.com",
    "score": 85
  },
  "binary": {} // For file data
}
```

#### Connections

Connections define how data flows through your workflow:

- **Sequential flow**: Data moves from one node to the next
- **Parallel processing**: Multiple nodes can process the same data
- **Conditional routing**: Different paths based on data content
- **Merge points**: Combine data from multiple sources

#### Executions

An execution is a single run of your workflow:

- **Manual execution**: Triggered by clicking "Execute Workflow"
- **Automatic execution**: Started by trigger nodes (webhook, cron, etc.)
- **Test execution**: Run with sample data for development
- **Production execution**: Live runs with real data

Each execution maintains:

- **Execution ID**: Unique identifier for tracking
- **Start/end time**: Performance monitoring
- **Node outputs**: Data at each step
- **Error information**: For debugging failures

#### Data Flow

Data in n8n flows as JSON objects between nodes:

```javascript
// Example data flow
[
  {
    "json": {
      "user_id": 123,
      "name": "Alice",
      "department": "Engineering"
    }
  },
  {
    "json": {
      "user_id": 124,
      "name": "Bob", 
      "department": "Sales"
    }
  }
]
```

**Key principles:**

- Each item in the array represents one data record
- Multiple items enable batch processing
- Nodes can split, merge, or transform the data array
- Binary data (files, images) is handled separately

## Core Features

n8n's power comes from its comprehensive feature set designed to handle complex automation scenarios while remaining accessible to users of all skill levels.

### Visual Workflow Builder

The drag-and-drop interface is n8n's signature feature, making complex automation accessible without coding knowledge.

#### Canvas Features

- **Infinite canvas** with smooth zooming and panning
- **Smart connection system** that suggests compatible nodes
- **Visual execution path** showing data flow during runs
- **Node previews** displaying data at each step
- **Undo/redo functionality** for safe experimentation

#### Node Management

- **Copy/paste nodes** between workflows
- **Node grouping** for organization
- **Annotations and comments** for documentation
- **Color coding** for visual organization
- **Bulk operations** for efficiency

#### Workflow Templates

```javascript
// Example workflow JSON export
{
  "name": "AI Content Pipeline",
  "nodes": [
    {
      "parameters": {
        "rule": {
          "interval": [{"field": "hours", "value": 24}]
        }
      },
      "name": "Every 24 hours",
      "type": "n8n-nodes-base.cron",
      "position": [240, 300]
    }
    // ... additional nodes
  ],
  "connections": {
    "Every 24 hours": {
      "main": [["Fetch Articles"]]
    }
  }
}
```

### 400+ Integrations

n8n's extensive library of built-in nodes covers most popular services and platforms.

#### Popular Categories

**Communication & Collaboration:**

- Slack, Microsoft Teams, Discord
- Gmail, Outlook, SendGrid
- Zoom, Google Meet
- Notion, Airtable, Monday.com

**AI & Machine Learning:**

- OpenAI (GPT-4, DALL-E, Whisper)
- Anthropic Claude
- Google AI (Gemini, Vertex AI)
- Hugging Face
- LangChain integration

**Data & Analytics:**

- Google Sheets, Excel Online
- PostgreSQL, MySQL, MongoDB
- Elasticsearch, Redis
- Google Analytics, Mixpanel

**E-commerce & CRM:**

- Shopify, WooCommerce
- Salesforce, HubSpot
- Stripe, PayPal
- Mailchimp, ConvertKit

#### Custom Integration Example

```javascript
// HTTP Request node for custom API
{
  "parameters": {
    "url": "https://api.custom-service.com/v1/data",
    "authentication": "predefinedCredentialType",
    "nodeCredentialType": "customServiceApi",
    "options": {
      "headers": {
        "Content-Type": "application/json"
      }
    }
  }
}
```

### Custom Code

When built-in nodes aren't sufficient, n8n provides powerful code execution capabilities.

#### JavaScript Function Node

```javascript
// Transform and enrich data
const items = $input.all();
const enrichedItems = [];

for (const item of items) {
  const data = item.json;
  
  // Calculate customer score
  const score = calculateCustomerScore(data);
  
  // Add timestamp
  const enriched = {
    ...data,
    score: score,
    processed_at: new Date().toISOString(),
    category: categorizeCustomer(score)
  };
  
  enrichedItems.push({ json: enriched });
}

return enrichedItems;

function calculateCustomerScore(customer) {
  // Custom scoring logic
  return (customer.purchases * 10) + 
         (customer.engagement * 5) + 
         (customer.loyalty_years * 15);
}

function categorizeCustomer(score) {
  if (score >= 100) return 'VIP';
  if (score >= 50) return 'Premium';
  return 'Standard';
}
```

#### Python Code Node

```python
import pandas as pd
import numpy as np
from datetime import datetime

# Get input data
items = $input.all()
df = pd.DataFrame([item['json'] for item in items])

# Perform data analysis
df['score_normalized'] = (df['score'] - df['score'].min()) / (df['score'].max() - df['score'].min())
df['percentile'] = df['score'].rank(pct=True)

# Statistical analysis
summary = {
    'total_customers': len(df),
    'average_score': df['score'].mean(),
    'top_10_percent': df[df['percentile'] >= 0.9]['customer_id'].tolist(),
    'analysis_date': datetime.now().isoformat()
}

# Return processed data
return [{'json': summary}] + [{'json': row} for _, row in df.iterrows()]
```

### Error Workflows

Robust error handling is crucial for production automation systems.

#### Error Workflow Configuration

```javascript
// Workflow with error handling
{
  "settings": {
    "errorWorkflow": "error-handler-workflow-id",
    "saveDataErrorExecution": "all",
    "saveDataSuccessExecution": "all"
  },
  "nodes": [
    {
      "name": "Try Process Payment",
      "type": "n8n-nodes-base.function",
      "continueOnFail": true,
      "parameters": {
        "functionCode": `
          try {
            // Payment processing logic
            return processPayment($json);
          } catch (error) {
            throw new Error('Payment failed: ' + error.message);
          }
        `
      }
    }
  ]
}
```

#### Error Handling Patterns

1. **Try-Catch Pattern**: Handle errors within nodes
2. **Error Workflows**: Dedicated workflows for error processing
3. **Retry Logic**: Automatic retries with backoff
4. **Circuit Breaker**: Prevent cascade failures
5. **Dead Letter Queue**: Store failed items for manual review

### Scheduling

Flexible scheduling options enable automation at any cadence.

#### Cron Expressions

```javascript
// Common cron patterns
{
  "every_hour": "0 * * * *",
  "every_day_9am": "0 9 * * *", 
  "every_monday_morning": "0 9 * * 1",
  "every_15_minutes": "*/15 * * * *",
  "first_of_month": "0 9 1 * *",
  "weekdays_only": "0 9 * * 1-5"
}
```

#### Interval Scheduling

```javascript
// Interval trigger configuration
{
  "parameters": {
    "rule": {
      "interval": [
        {"field": "seconds", "value": 30},  // Every 30 seconds
        {"field": "minutes", "value": 5},   // Every 5 minutes
        {"field": "hours", "value": 2}      // Every 2 hours
      ]
    }
  }
}
```

#### Advanced Scheduling Features

- **Timezone support**: Schedule workflows in specific timezones
- **Holiday calendars**: Skip execution on holidays
- **Dynamic scheduling**: Calculate next execution based on data
- **Conditional triggers**: Only trigger if certain conditions are met

## AI Integration

n8n excels at AI integration, providing native support for major AI platforms and frameworks. This makes it an ideal platform for building AI-powered automation workflows.

### OpenAI Integration

n8n provides comprehensive OpenAI integration through dedicated nodes.

#### Chat Completions with GPT-4

```javascript
// GPT-4 conversation node configuration
{
  "parameters": {
    "model": "gpt-4-turbo",
    "messages": {
      "messageType": "multipleMessages",
      "messages": [
        {
          "role": "system",
          "content": "You are a helpful customer service assistant. Analyze customer inquiries and provide appropriate responses."
        },
        {
          "role": "user", 
          "content": "Customer message: {{ $json.customer_message }}\nCustomer history: {{ $json.customer_history }}"
        }
      ]
    },
    "options": {
      "temperature": 0.7,
      "maxTokens": 500,
      "topP": 1,
      "frequencyPenalty": 0,
      "presencePenalty": 0
    }
  }
}
```

#### DALL-E Image Generation

```javascript
// Image generation workflow
{
  "parameters": {
    "model": "dall-e-3",
    "prompt": "{{ $json.image_description }}",
    "options": {
      "size": "1024x1024",
      "quality": "standard",
      "style": "vivid"
    }
  }
}
```

#### Whisper Speech-to-Text

```javascript
// Audio transcription setup
{
  "parameters": {
    "model": "whisper-1",
    "binaryPropertyName": "audio_file",
    "options": {
      "language": "en",
      "prompt": "This is a customer service call",
      "responseFormat": "json",
      "temperature": 0
    }
  }
}
```

### Anthropic Claude

Integration with Claude provides access to Anthropic's advanced AI capabilities.

#### Claude Integration Example

```javascript
// Claude workflow configuration
{
  "parameters": {
    "model": "claude-3-opus-20240229",
    "messages": [
      {
        "role": "user",
        "content": "Analyze this document and extract key insights: {{ $json.document_text }}"
      }
    ],
    "maxTokens": 1000,
    "temperature": 0.3
  }
}
```

#### Advanced Claude Usage

```javascript
// Multi-turn conversation with Claude
const conversationHistory = $json.conversation || [];
const newMessage = $json.user_input;

const messages = [
  {
    role: "system",
    content: "You are an expert business analyst. Provide detailed, actionable insights."
  },
  ...conversationHistory,
  {
    role: "user", 
    content: newMessage
  }
];

// Update conversation history for next interaction
return [{
  json: {
    ...$json,
    conversation: messages,
    response: response.content[0].text
  }
}];
```

### Local LLM Support

n8n can connect to self-hosted language models for privacy-sensitive applications.

#### Ollama Integration

```javascript
// Local LLM configuration
{
  "parameters": {
    "baseURL": "http://localhost:11434/v1",
    "model": "llama2:13b",
    "messages": [
      {
        "role": "user",
        "content": "{{ $json.prompt }}"
      }
    ]
  }
}
```

#### Custom Local API

```javascript
// Custom model endpoint
{
  "parameters": {
    "url": "http://your-local-server:8080/generate",
    "method": "POST",
    "body": {
      "prompt": "{{ $json.input_text }}",
      "max_tokens": 500,
      "temperature": 0.7,
      "model": "your-custom-model"
    },
    "headers": {
      "Content-Type": "application/json",
      "Authorization": "Bearer {{ $credentials.localLLM.token }}"
    }
  }
}
```

### Embedding Models

Generate embeddings for semantic search and RAG implementations.

#### OpenAI Embeddings

```javascript
// Text embedding configuration
{
  "parameters": {
    "model": "text-embedding-3-large",
    "input": "{{ $json.text_content }}",
    "options": {
      "dimensions": 1536
    }
  }
}
```

#### Batch Embedding Processing

```javascript
// Process multiple texts for embeddings
const items = $input.all();
const batchSize = 100; // OpenAI batch limit
const batches = [];

for (let i = 0; i < items.length; i += batchSize) {
  const batch = items.slice(i, i + batchSize);
  const texts = batch.map(item => item.json.content);
  
  // Create embedding request
  batches.push({
    json: {
      texts: texts,
      batch_index: Math.floor(i / batchSize),
      original_items: batch
    }
  });
}

return batches;
```

### AI Agents

Build autonomous agents that can plan, execute, and adapt their actions.

#### Simple Agent Pattern

```javascript
// Basic agent workflow
{
  "name": "Research Agent",
  "description": "Autonomous research and summarization agent",
  "nodes": [
    {
      "name": "Agent Controller",
      "type": "n8n-nodes-base.function",
      "parameters": {
        "functionCode": `
          const task = $json.task;
          const context = $json.context || {};
          
          // Agent decision logic
          const nextAction = decideNextAction(task, context);
          
          return [{
            json: {
              action: nextAction.action,
              parameters: nextAction.parameters,
              task: task,
              context: context
            }
          }];
          
          function decideNextAction(task, context) {
            if (!context.research_completed) {
              return {
                action: "search_web",
                parameters: { query: task.query }
              };
            } else if (!context.summary_created) {
              return {
                action: "summarize",
                parameters: { content: context.research_results }
              };
            } else {
              return {
                action: "complete",
                parameters: { result: context.summary }
              };
            }
          }
        `
      }
    }
  ]
}
```

#### Advanced Agent with Tools

```javascript
// Agent with tool selection
const availableTools = [
  {
    name: "web_search",
    description: "Search the web for information",
    parameters: { query: "string" }
  },
  {
    name: "calculator", 
    description: "Perform mathematical calculations",
    parameters: { expression: "string" }
  },
  {
    name: "send_email",
    description: "Send email to specified recipient", 
    parameters: { to: "string", subject: "string", body: "string" }
  }
];

// Let AI choose appropriate tool
const toolSelectionPrompt = `
Given the task: "${$json.task}"
Available tools: ${JSON.stringify(availableTools, null, 2)}

Choose the most appropriate tool and provide parameters.
Respond in JSON format: {"tool": "tool_name", "parameters": {...}}
`;

// This would connect to an LLM node for tool selection
```

#### Multi-Agent Coordination

```javascript
// Agent coordination workflow
{
  "agents": {
    "researcher": {
      "role": "Gather information from various sources",
      "capabilities": ["web_search", "document_analysis"]
    },
    "analyzer": {
      "role": "Analyze and synthesize information", 
      "capabilities": ["data_analysis", "pattern_recognition"]
    },
    "writer": {
      "role": "Create final report or output",
      "capabilities": ["content_generation", "formatting"]
    }
  },
  "coordination_logic": `
    1. Researcher gathers raw information
    2. Analyzer processes and identifies key insights  
    3. Writer creates final deliverable
    4. All agents can request clarification from coordinator
  `
}
```

## Node Types

n8n organizes its extensive node library into categories based on functionality, making it easier to find the right tool for each task.

### Trigger Nodes

Trigger nodes start workflow executions and determine when your automation runs.

#### Time-based Triggers

```javascript
// Cron trigger for scheduled execution
{
  "parameters": {
    "rule": {
      "interval": [
        {"field": "cronExpression", "value": "0 9 * * 1-5"} // Weekdays at 9 AM
      ]
    }
  }
}

// Interval trigger for regular execution
{
  "parameters": {
    "rule": {
      "interval": [
        {"field": "minutes", "value": 15} // Every 15 minutes
      ]
    }
  }
}
```

#### Event-based Triggers

- **Webhook**: HTTP endpoints for external system integration
- **Email Trigger**: Monitor IMAP mailboxes for new messages
- **File Trigger**: Watch directories for file changes
- **Database Trigger**: Monitor database changes
- **SQS Trigger**: Process Amazon SQS messages

#### Service-specific Triggers

```javascript
// Slack trigger for new messages
{
  "parameters": {
    "event": "message",
    "channel": "#general"
  }
}

// Gmail trigger for new emails
{
  "parameters": {
    "event": "messageReceived",
    "filters": {
      "from": "important@company.com"
    }
  }
}
```

### Action Nodes

Action nodes perform operations on external services or systems.

#### Data Operations

- **HTTP Request**: Call REST APIs and webhooks
- **Database**: Execute SQL queries (PostgreSQL, MySQL, etc.)
- **File Operations**: Read, write, move files
- **FTP/SFTP**: File transfer operations

#### Communication Actions

```javascript
// Send Slack message
{
  "parameters": {
    "channel": "#alerts",
    "text": "Alert: {{ $json.alert_message }}",
    "attachments": [
      {
        "color": "danger",
        "title": "System Alert",
        "fields": [
          {
            "title": "Severity",
            "value": "{{ $json.severity }}",
            "short": true
          }
        ]
      }
    ]
  }
}

// Send email via SendGrid
{
  "parameters": {
    "fromEmail": "noreply@company.com",
    "toEmail": "{{ $json.recipient }}",
    "subject": "Weekly Report - {{ $now.format('YYYY-MM-DD') }}",
    "text": "{{ $json.report_content }}"
  }
}
```

### Logic Nodes

Logic nodes control workflow execution flow and data routing.

#### IF Node

```javascript
// Conditional routing based on data
{
  "parameters": {
    "conditions": {
      "string": [
        {
          "value1": "{{ $json.status }}",
          "operation": "equal",
          "value2": "active"
        }
      ],
      "number": [
        {
          "value1": "{{ $json.score }}",
          "operation": "larger",
          "value2": 80
        }
      ]
    },
    "combineOperation": "all" // "all" or "any"
  }
}
```

#### Switch Node

```javascript
// Multi-way branching
{
  "parameters": {
    "dataType": "string",
    "value1": "{{ $json.category }}",
    "rules": {
      "values": [
        {
          "value": "urgent",
          "output": 0
        },
        {
          "value": "normal", 
          "output": 1
        },
        {
          "value": "low",
          "output": 2
        }
      ]
    }
  }
}
```

#### Merge Node

```javascript
// Combine data from multiple sources
{
  "parameters": {
    "mode": "append", // "append", "pass-through", "wait"
    "joinBy": "index" // How to combine items
  }
}
```

### Transform Nodes

Transform nodes modify, filter, and restructure data as it flows through workflows.

#### Set Node

```javascript
// Add or modify fields
{
  "parameters": {
    "values": {
      "string": [
        {
          "name": "full_name",
          "value": "{{ $json.first_name }} {{ $json.last_name }}"
        },
        {
          "name": "processed_date",
          "value": "{{ $now }}"
        }
      ],
      "number": [
        {
          "name": "total_score",
          "value": "{{ $json.base_score * $json.multiplier }}"
        }
      ]
    }
  }
}
```

#### Filter Node

```javascript
// Filter items based on conditions
{
  "parameters": {
    "conditions": {
      "string": [
        {
          "value1": "{{ $json.status }}",
          "operation": "notEqual",
          "value2": "deleted"
        }
      ]
    }
  }
}
```

#### Sort Node

```javascript
// Sort data by specified fields
{
  "parameters": {
    "sortFieldsUi": {
      "sortField": [
        {
          "fieldName": "created_date",
          "order": "descending"
        },
        {
          "fieldName": "priority", 
          "order": "ascending"
        }
      ]
    }
  }
}
```

### Function Nodes

Function nodes provide maximum flexibility through custom code execution.

#### JavaScript Function

```javascript
// Advanced data transformation
const items = $input.all();
const processed = [];

// Group items by category
const grouped = items.reduce((acc, item) => {
  const category = item.json.category;
  if (!acc[category]) {
    acc[category] = [];
  }
  acc[category].push(item.json);
  return acc;
}, {});

// Calculate statistics for each group
for (const [category, items] of Object.entries(grouped)) {
  const stats = {
    category: category,
    count: items.length,
    total_value: items.reduce((sum, item) => sum + (item.value || 0), 0),
    average_value: items.reduce((sum, item) => sum + (item.value || 0), 0) / items.length,
    max_value: Math.max(...items.map(item => item.value || 0)),
    min_value: Math.min(...items.map(item => item.value || 0))
  };
  
  processed.push({ json: stats });
}

return processed;
```

#### Python Function

```python
import json
import numpy as np
from datetime import datetime, timedelta

# Get input data
input_data = [item['json'] for item in $input.all()]

# Perform complex analysis
values = [item['value'] for item in input_data]
array = np.array(values)

# Statistical analysis
result = {
    'analysis': {
        'mean': float(np.mean(array)),
        'std': float(np.std(array)),
        'median': float(np.median(array)),
        'percentiles': {
            '25th': float(np.percentile(array, 25)),
            '75th': float(np.percentile(array, 75)),
            '90th': float(np.percentile(array, 90))
        }
    },
    'outliers': [],
    'analysis_date': datetime.now().isoformat()
}

# Detect outliers (values beyond 2 standard deviations)
threshold = 2 * np.std(array)
mean_val = np.mean(array)

for i, value in enumerate(values):
    if abs(value - mean_val) > threshold:
        result['outliers'].append({
            'index': i,
            'value': value,
            'deviation': abs(value - mean_val)
        })

return [{'json': result}]
```

## AI-Specific Nodes

n8n provides specialized nodes for AI operations, making it easy to integrate artificial intelligence into your workflows.

### Chat Completions

Chat completion nodes enable conversational AI integration with various language models.

#### OpenAI Chat Model

```javascript
// Multi-turn conversation with memory
{
  "parameters": {
    "model": "gpt-4-turbo",
    "messages": {
      "messageType": "multipleMessages",
      "messages": [
        {
          "role": "system",
          "content": "You are a helpful customer service agent for an e-commerce platform. Always be polite and provide accurate information based on the customer data provided."
        },
        {
          "role": "user",
          "content": "Previous conversation: {{ $json.conversation_history }}\n\nCustomer: {{ $json.customer_message }}\nCustomer ID: {{ $json.customer_id }}\nOrder History: {{ $json.order_history }}"
        }
      ]
    },
    "options": {
      "temperature": 0.7,
      "maxTokens": 1000,
      "presencePenalty": 0.1,
      "frequencyPenalty": 0.1
    }
  }
}
```

#### Claude Chat Integration

```javascript
// Document analysis with Claude
{
  "parameters": {
    "model": "claude-3-opus-20240229",
    "messages": [
      {
        "role": "user",
        "content": "Please analyze this contract and extract key terms:\n\n{{ $json.contract_text }}\n\nProvide a structured summary including:\n- Parties involved\n- Key obligations\n- Deadlines\n- Financial terms\n- Risks or concerns"
      }
    ],
    "maxTokens": 2000,
    "temperature": 0.1
  }
}
```

### Text Embedding

Embedding nodes convert text into vector representations for semantic search and RAG systems.

#### OpenAI Embeddings

```javascript
// Generate embeddings for document chunks
{
  "parameters": {
    "model": "text-embedding-3-large",
    "input": "{{ $json.text_chunk }}",
    "options": {
      "dimensions": 1536
    }
  }
}
```

#### Batch Embedding Processing

```javascript
// Process multiple documents efficiently
const documents = $input.all();
const embeddings = [];

for (const doc of documents) {
  const chunks = splitIntoChunks(doc.json.content, 512);
  
  for (let i = 0; i < chunks.length; i++) {
    embeddings.push({
      json: {
        document_id: doc.json.id,
        chunk_index: i,
        text: chunks[i],
        metadata: {
          title: doc.json.title,
          author: doc.json.author,
          created_date: doc.json.created_date
        }
      }
    });
  }
}

function splitIntoChunks(text, chunkSize) {
  const words = text.split(' ');
  const chunks = [];
  
  for (let i = 0; i < words.length; i += chunkSize) {
    chunks.push(words.slice(i, i + chunkSize).join(' '));
  }
  
  return chunks;
}

return embeddings;
```

### Vector Store

Vector store nodes manage embeddings for similarity search and retrieval.

#### Pinecone Integration

```javascript
// Store embeddings in Pinecone
{
  "parameters": {
    "operation": "upsert",
    "vectors": [
      {
        "id": "{{ $json.document_id }}_{{ $json.chunk_index }}",
        "values": "{{ $json.embedding }}",
        "metadata": {
          "title": "{{ $json.metadata.title }}",
          "content": "{{ $json.text }}",
          "timestamp": "{{ $now }}"
        }
      }
    ]
  }
}
```

#### Similarity Search

```javascript
// Query vector database for similar content
{
  "parameters": {
    "operation": "query",
    "vector": "{{ $json.query_embedding }}",
    "topK": 5,
    "includeMetadata": true,
    "filter": {
      "timestamp": {
        "$gte": "{{ $json.date_filter }}"
      }
    }
  }
}
```

### Chain Nodes

Chain nodes implement LangChain patterns for complex AI workflows.

#### RAG Chain Implementation

```javascript
// Retrieval-Augmented Generation chain
{
  "name": "RAG Pipeline",
  "description": "Complete RAG implementation with retrieval and generation",
  "chain_config": {
    "retriever": {
      "type": "vector_store",
      "vector_store": "pinecone",
      "search_kwargs": {
        "k": 5,
        "score_threshold": 0.7
      }
    },
    "llm": {
      "type": "openai",
      "model": "gpt-4-turbo",
      "temperature": 0.1
    },
    "prompt_template": "Use the following context to answer the question. If the answer is not in the context, say so.\n\nContext: {context}\n\nQuestion: {question}\n\nAnswer:"
  }
}
```

#### Conversation Chain

```javascript
// Conversational chain with memory
{
  "parameters": {
    "chainType": "conversation",
    "memory": {
      "type": "buffer_window",
      "k": 10 // Remember last 10 exchanges
    },
    "llm": {
      "model": "gpt-4",
      "temperature": 0.7
    },
    "prompt": "You are a helpful AI assistant. Use the conversation history to provide contextual responses."
  }
}
```

### Agent Nodes

Agent nodes create autonomous AI systems that can plan and execute multi-step tasks.

#### Tool-Using Agent

```javascript
// Agent with access to multiple tools
{
  "parameters": {
    "agentType": "openai-functions",
    "llm": {
      "model": "gpt-4-turbo",
      "temperature": 0
    },
    "tools": [
      {
        "name": "calculator",
        "description": "Perform mathematical calculations",
        "function": {
          "name": "calculate",
          "parameters": {
            "type": "object",
            "properties": {
              "expression": {
                "type": "string",
                "description": "Mathematical expression to evaluate"
              }
            },
            "required": ["expression"]
          }
        }
      },
      {
        "name": "web_search",
        "description": "Search the internet for information",
        "function": {
          "name": "search_web",
          "parameters": {
            "type": "object", 
            "properties": {
              "query": {
                "type": "string",
                "description": "Search query"
              }
            },
            "required": ["query"]
          }
        }
      }
    ],
    "systemMessage": "You are a helpful research assistant. Use the available tools to find information and perform calculations as needed."
  }
}
```

#### Multi-Agent Workflow

```javascript
// Coordinated multi-agent system
{
  "agents": {
    "researcher": {
      "role": "Information Gatherer",
      "tools": ["web_search", "document_reader"],
      "prompt": "You specialize in gathering comprehensive information on given topics."
    },
    "analyzer": {
      "role": "Data Analyst", 
      "tools": ["calculator", "data_processor"],
      "prompt": "You analyze data and extract insights from research findings."
    },
    "writer": {
      "role": "Content Creator",
      "tools": ["document_generator", "formatter"],
      "prompt": "You create well-structured reports and presentations."
    }
  },
  "workflow": [
    {
      "step": 1,
      "agent": "researcher",
      "task": "Gather information on: {{ $json.research_topic }}"
    },
    {
      "step": 2,
      "agent": "analyzer",
      "task": "Analyze the research findings and identify key insights"
    },
    {
      "step": 3,
      "agent": "writer",
      "task": "Create a comprehensive report based on the analysis"
    }
  ]
}
```

## Workflow Patterns

Understanding common workflow patterns helps you design efficient and maintainable automation systems.

### Simple Automation

Basic workflows that perform single tasks or simple sequences.

#### Email Alert System

```json
{
  "name": "Server Monitoring Alert",
  "nodes": [
    {
      "name": "Check Every 5 Minutes",
      "type": "n8n-nodes-base.cron",
      "parameters": {
        "rule": {
          "interval": [{"field": "minutes", "value": 5}]
        }
      }
    },
    {
      "name": "Check Server Status",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "https://api.server-monitor.com/status",
        "method": "GET"
      }
    },
    {
      "name": "Check If Down",
      "type": "n8n-nodes-base.if",
      "parameters": {
        "conditions": {
          "string": [{
            "value1": "={{ $json.status }}",
            "operation": "equal",
            "value2": "down"
          }]
        }
      }
    },
    {
      "name": "Send Alert",
      "type": "n8n-nodes-base.emailSend",
      "parameters": {
        "toEmail": "admin@company.com",
        "subject": "🚨 Server Alert: {{ $json.server_name }} is Down",
        "text": "Server {{ $json.server_name }} has been detected as down at {{ $now }}\n\nStatus: {{ $json.status }}\nLast Check: {{ $json.last_check }}"
      }
    }
  ],
  "connections": {
    "Check Every 5 Minutes": {"main": [["Check Server Status"]]},
    "Check Server Status": {"main": [["Check If Down"]]},
    "Check If Down": {"main": [["Send Alert"]]}
  }
}
```

### Data Processing Pipeline

ETL (Extract, Transform, Load) workflows for data integration and processing.

#### Customer Data Synchronization

```javascript
// Extract phase
const extractNode = {
  name: "Extract Customer Data",
  type: "n8n-nodes-base.postgres",
  parameters: {
    operation: "executeQuery",
    query: `
      SELECT customer_id, first_name, last_name, email, 
             created_date, last_purchase_date, total_spent
      FROM customers 
      WHERE updated_at > $1
      ORDER BY updated_at DESC
    `,
    values: ["{{ $json.last_sync_date }}"]
  }
};

// Transform phase
const transformFunction = `
const customers = $input.all();
const transformed = [];

for (const customer of customers) {
  const data = customer.json;
  
  // Data cleaning and transformation
  const cleanCustomer = {
    id: data.customer_id,
    fullName: (data.first_name + ' ' + data.last_name).trim(),
    email: data.email.toLowerCase(),
    registrationDate: new Date(data.created_date).toISOString(),
    lastPurchase: data.last_purchase_date ? new Date(data.last_purchase_date).toISOString() : null,
    lifetime_value: parseFloat(data.total_spent) || 0,
    
    // Calculated fields
    customerSegment: calculateSegment(data.total_spent, data.last_purchase_date),
    daysSinceLastPurchase: data.last_purchase_date ? 
      Math.floor((new Date() - new Date(data.last_purchase_date)) / (1000 * 60 * 60 * 24)) : null,
    
    // Metadata
    syncDate: new Date().toISOString(),
    source: 'postgresql'
  };
  
  transformed.push({ json: cleanCustomer });
}

function calculateSegment(totalSpent, lastPurchaseDate) {
  const spent = parseFloat(totalSpent) || 0;
  const daysSince = lastPurchaseDate ? 
    Math.floor((new Date() - new Date(lastPurchaseDate)) / (1000 * 60 * 60 * 24)) : 999;
  
  if (spent > 1000 && daysSince < 30) return 'VIP Active';
  if (spent > 1000) return 'VIP';
  if (spent > 500 && daysSince < 90) return 'Premium Active';
  if (spent > 500) return 'Premium';
  if (daysSince > 365) return 'Inactive';
  return 'Standard';
}

return transformed;
`;

// Load phase - multiple destinations
const loadToDataWarehouse = {
  name: "Load to Data Warehouse",
  type: "n8n-nodes-base.postgres",
  parameters: {
    operation: "upsert",
    table: "customer_profiles",
    columns: "id, full_name, email, registration_date, last_purchase, lifetime_value, customer_segment, days_since_purchase, sync_date"
  }
};

const loadToCRM = {
  name: "Sync to CRM",
  type: "n8n-nodes-base.hubspot",
  parameters: {
    resource: "contact",
    operation: "upsert",
    properties: {
      email: "{{ $json.email }}",
      firstname: "{{ $json.fullName.split(' ')[0] }}",
      lastname: "{{ $json.fullName.split(' ')[1] }}",
      customer_segment: "{{ $json.customerSegment }}",
      lifetime_value: "{{ $json.lifetime_value }}"
    }
  }
};
```

### AI Agent Workflow

Autonomous agent patterns that can adapt their behavior based on context.

#### Research and Analysis Agent

```javascript
{
  "name": "Autonomous Research Agent",
  "description": "Agent that researches topics and creates comprehensive reports",
  "workflow": {
    "agent_controller": {
      "type": "function",
      "code": `
        const task = $json.research_task;
        const context = $json.context || { phase: 'planning', data: {} };
        
        // Agent state machine
        switch(context.phase) {
          case 'planning':
            return planResearch(task);
          case 'searching':
            return executeSearch(task, context);
          case 'analyzing':
            return analyzeFindings(context);
          case 'writing':
            return generateReport(context);
          default:
            return completeTask(context);
        }
        
        function planResearch(task) {
          const searchQueries = generateSearchQueries(task.topic, task.scope);
          return [{
            json: {
              phase: 'searching',
              action: 'web_search',
              queries: searchQueries,
              task: task,
              context: { ...context, queries_planned: searchQueries.length }
            }
          }];
        }
        
        function executeSearch(task, context) {
          if (context.searches_completed < context.queries_planned) {
            return [{
              json: {
                phase: 'searching',
                action: 'search_web',
                query: context.queries[context.searches_completed],
                context: context
              }
            }];
          } else {
            return [{
              json: {
                phase: 'analyzing',
                action: 'analyze_data',
                data: context.search_results,
                context: context
              }
            }];
          }
        }
      `
    },
    "web_searcher": {
      "type": "http_request",
      "parameters": {
        "url": "https://api.search-engine.com/search",
        "method": "GET",
        "qs": {
          "q": "{{ $json.query }}",
          "num": 10
        }
      }
    },
    "ai_analyzer": {
      "type": "openai",
      "parameters": {
        "model": "gpt-4-turbo",
        "messages": [{
          "role": "system",
          "content": "You are a research analyst. Analyze the provided search results and extract key insights, themes, and important information."
        }, {
          "role": "user",
          "content": "Research data: {{ $json.search_results }}\n\nProvide analysis with key findings, themes, and insights."
        }]
      }
    }
  }
}
```

### Multi-Step AI Processing

Complex AI chains that process data through multiple AI models and transformations.

#### Content Enhancement Pipeline

```javascript
{
  "name": "AI Content Enhancement Pipeline",
  "description": "Multi-stage content processing with different AI models",
  "stages": {
    "stage_1_extraction": {
      "name": "Content Extraction",
      "ai_model": "gpt-4",
      "prompt": "Extract the main topics, key points, and important details from this content: {{ $json.raw_content }}",
      "output_format": "structured_json"
    },
    "stage_2_analysis": {
      "name": "Sentiment and Tone Analysis", 
      "ai_model": "claude-3-opus",
      "prompt": "Analyze the sentiment, tone, and emotional content of this extracted information: {{ $json.extracted_content }}",
      "parallel_processing": true
    },
    "stage_3_enhancement": {
      "name": "Content Improvement",
      "ai_model": "gpt-4-turbo",
      "prompt": "Based on the analysis, suggest improvements for clarity, engagement, and effectiveness: {{ $json.analysis_results }}",
      "temperature": 0.3
    },
    "stage_4_generation": {
      "name": "Enhanced Content Creation",
      "ai_model": "claude-3-sonnet",
      "prompt": "Create improved content based on the suggestions: {{ $json.improvement_suggestions }}",
      "max_tokens": 2000
    }
  }
}
```

### RAG Implementation

Retrieval-Augmented Generation for knowledge-based AI responses.

#### Complete RAG Workflow

```javascript
{
  "name": "RAG Knowledge System",
  "description": "Complete RAG implementation with document processing and query handling",
  "document_ingestion": {
    "chunking_strategy": {
      "type": "semantic",
      "chunk_size": 512,
      "overlap": 50,
      "separators": ["\n\n", "\n", ".", "!", "?"]
    },
    "embedding_pipeline": {
      "model": "text-embedding-3-large",
      "dimensions": 1536,
      "batch_size": 100
    },
    "storage": {
      "vector_db": "pinecone",
      "index_name": "knowledge-base",
      "metadata_fields": ["title", "author", "date", "category", "source"]
    }
  },
  "query_pipeline": {
    "retrieval": {
      "similarity_threshold": 0.7,
      "max_results": 5,
      "reranking": true
    },
    "generation": {
      "model": "gpt-4-turbo",
      "system_prompt": "You are a knowledgeable assistant. Use only the provided context to answer questions. If the answer isn't in the context, say so clearly.",
      "context_template": "Context:\n{context}\n\nQuestion: {question}\n\nAnswer:",
      "max_tokens": 1000,
      "temperature": 0.1
    }
  },
  "workflow_function": `
    async function processQuery(query, userId) {
      // 1. Generate query embedding
      const queryEmbedding = await generateEmbedding(query);
      
      // 2. Retrieve relevant documents
      const retrievedDocs = await vectorSearch(queryEmbedding, {
        threshold: 0.7,
        limit: 5,
        filter: { user_access: userId }
      });
      
      // 3. Prepare context
      const context = retrievedDocs.map(doc => 
        doc.metadata.title + ': ' + doc.content
      ).join('\n\n');
      
      // 4. Generate response
      const response = await generateResponse({
        context: context,
        question: query,
        conversation_history: getConversationHistory(userId)
      });
      
      // 5. Store interaction
      await storeInteraction({
        user_id: userId,
        query: query,
        response: response,
        sources: retrievedDocs.map(doc => doc.metadata),
        timestamp: new Date()
      });
      
      return {
        answer: response,
        sources: retrievedDocs.map(doc => ({
          title: doc.metadata.title,
          snippet: doc.content.substring(0, 200) + '...',
          relevance_score: doc.score
        }))
      };
    }
  `
}
```

## Data Management

Effective data management is crucial for building robust and maintainable workflows in n8n.

### Variables

n8n provides multiple types of variables for storing and accessing data across workflow executions.

#### Environment Variables

```bash
# Set in environment or .env file
API_KEY=your-secret-key
DATABASE_URL=postgresql://user:pass@host:5432/db
OPENAI_API_KEY=sk-...
WEBHOOK_SECRET=webhook-secret-key
```

#### Workflow Variables

```javascript
// Access in nodes using expressions
{
  "api_endpoint": "{{ $env.API_ENDPOINT }}",
  "max_retries": "{{ $env.MAX_RETRIES || 3 }}",
  "timeout_seconds": "{{ parseInt($env.TIMEOUT_SECONDS) || 30 }}"
}
```

#### Global Variables

```javascript
// Set global variables in Function nodes
$globalVars.set('last_processed_date', new Date().toISOString());
$globalVars.set('processing_stats', {
  total_processed: 1250,
  errors: 3,
  success_rate: 0.998
});

// Access global variables
const lastProcessed = $globalVars.get('last_processed_date');
const stats = $globalVars.get('processing_stats');

// Update counters
const currentCount = $globalVars.get('processed_count') || 0;
$globalVars.set('processed_count', currentCount + 1);
```

### Expressions

Dynamic value generation using n8n's expression system.

#### Basic Expressions

```javascript
// String manipulation
"{{ $json.first_name.toUpperCase() }}"
"{{ $json.email.toLowerCase() }}"
"{{ $json.full_name.trim().replace(' ', '_') }}"

// Date operations
"{{ $now.format('YYYY-MM-DD') }}"  // Today's date
"{{ $now.minus({days: 7}).format('YYYY-MM-DD') }}"  // Week ago
"{{ DateTime.fromISO($json.created_date).plus({months: 1}).toISO() }}"  // Add month

// Mathematical operations
"{{ $json.price * 1.1 }}"  // Add 10%
"{{ Math.round($json.score * 100) / 100 }}"  // Round to 2 decimals
"{{ Math.max(...$json.values) }}"  // Maximum value

// Conditional expressions
"{{ $json.age >= 18 ? 'adult' : 'minor' }}"
"{{ $json.status === 'active' ? $json.email : null }}"
```

#### Advanced Expressions

```javascript
// Array operations
"{{ $json.items.filter(item => item.price > 100) }}"
"{{ $json.products.map(p => p.name).join(', ') }}"
"{{ $json.scores.reduce((sum, score) => sum + score, 0) / $json.scores.length }}"

// Object manipulation
"{{ Object.keys($json.data).length }}"
"{{ Object.entries($json.metadata).map(([k,v]) => k + ': ' + v) }}"

// Complex data transformation
`{{
  $json.customers.map(customer => ({
    id: customer.customer_id,
    name: customer.first_name + ' ' + customer.last_name,
    segment: customer.total_spent > 1000 ? 'premium' : 'standard',
    last_contact: DateTime.fromISO(customer.last_contact).toRelative()
  }))
}}`
```

### Data Transformation

Transforming and manipulating JSON data as it flows through workflows.

#### Set Node Transformations

```javascript
// Complex data restructuring in Set node
{
  "parameters": {
    "values": {
      "string": [
        {
          "name": "customer_key",
          "value": "{{ $json.company_name.toLowerCase().replace(/[^a-z0-9]/g, '_') }}"
        },
        {
          "name": "formatted_address",
          "value": "{{ $json.street }}, {{ $json.city }}, {{ $json.state }} {{ $json.zip }}"
        }
      ],
      "number": [
        {
          "name": "annual_value",
          "value": "{{ $json.monthly_value * 12 }}"
        },
        {
          "name": "risk_score",
          "value": "{{ Math.min(100, Math.max(0, ($json.late_payments * 10) + ($json.disputes * 5))) }}"
        }
      ],
      "object": [
        {
          "name": "contact_info",
          "value": {
            "primary": {
              "email": "{{ $json.email }}",
              "phone": "{{ $json.phone }}"
            },
            "secondary": {
              "email": "{{ $json.alt_email }}",
              "phone": "{{ $json.alt_phone }}"
            }
          }
        }
      ]
    }
  }
}
```

#### Function Node Data Processing

```javascript
// Advanced data transformation in Function node
const items = $input.all();
const processedData = [];

// Group and aggregate data
const groupedByCategory = items.reduce((groups, item) => {
  const category = item.json.category;
  if (!groups[category]) {
    groups[category] = {
      category: category,
      items: [],
      total_value: 0,
      count: 0
    };
  }
  
  groups[category].items.push(item.json);
  groups[category].total_value += item.json.value || 0;
  groups[category].count++;
  
  return groups;
}, {});

// Create summary statistics
for (const [category, data] of Object.entries(groupedByCategory)) {
  const avgValue = data.total_value / data.count;
  const maxValue = Math.max(...data.items.map(item => item.value || 0));
  const minValue = Math.min(...data.items.map(item => item.value || 0));
  
  processedData.push({
    json: {
      category: category,
      summary: {
        count: data.count,
        total_value: data.total_value,
        average_value: Math.round(avgValue * 100) / 100,
        max_value: maxValue,
        min_value: minValue,
        value_range: maxValue - minValue
      },
      items: data.items,
      processed_at: new Date().toISOString()
    }
  });
}

// Sort by total value descending
processedData.sort((a, b) => b.json.summary.total_value - a.json.summary.total_value);

return processedData;
```

### Credentials

Secure management of API keys, passwords, and other sensitive information.

#### Credential Types

```javascript
// API Key credentials
{
  "name": "OpenAI API",
  "type": "openAiApi",
  "data": {
    "apiKey": "sk-your-openai-key"
  }
}

// OAuth2 credentials  
{
  "name": "Google Sheets",
  "type": "googleSheetsOAuth2Api",
  "data": {
    "clientId": "your-client-id",
    "clientSecret": "your-client-secret",
    "accessToken": "generated-access-token",
    "refreshToken": "generated-refresh-token"
  }
}

// Database credentials
{
  "name": "Production Database",
  "type": "postgres",
  "data": {
    "host": "db.company.com",
    "port": 5432,
    "database": "production",
    "username": "app_user",
    "password": "secure-password",
    "ssl": true
  }
}
```

#### Using Credentials in Workflows

```javascript
// Access credentials in HTTP Request nodes
{
  "parameters": {
    "url": "https://api.service.com/data",
    "authentication": "predefinedCredentialType",
    "nodeCredentialType": "customApiCredentials",
    "headers": {
      "Authorization": "Bearer {{ $credentials.customApi.token }}",
      "X-API-Version": "2023-10-01"
    }
  }
}

// Database connections
{
  "parameters": {
    "operation": "executeQuery",
    "query": "SELECT * FROM users WHERE created_date > $1",
    "values": ["{{ $json.start_date }}"],
    "credentials": "productionDatabase"
  }
}
```

#### Credential Security Best Practices

1. **Environment-based Configuration**

```bash
# Use different credentials per environment
N8N_ENCRYPTION_KEY=your-32-character-encryption-key
DB_PASSWORD_PROD=prod-password
DB_PASSWORD_DEV=dev-password
API_KEY_PROD=prod-api-key
API_KEY_DEV=dev-api-key
```

1. **Credential Rotation**

```javascript
// Automated credential rotation workflow
{
  "name": "Credential Rotation",
  "schedule": "0 2 1 * *", // First day of month at 2 AM
  "steps": [
    {
      "name": "Generate New API Key",
      "action": "create_new_key"
    },
    {
      "name": "Update Credential Store", 
      "action": "update_credentials"
    },
    {
      "name": "Test New Credentials",
      "action": "validate_access"
    },
    {
      "name": "Revoke Old Key",
      "action": "deactivate_old_key"
    }
  ]
}
```

1. **Access Logging**

```javascript
// Log credential usage for security monitoring
const credentialUsage = {
  credential_name: "{{ $credentials.name }}",
  workflow_id: "{{ $workflow.id }}",
  node_name: "{{ $node.name }}",
  execution_id: "{{ $execution.id }}",
  timestamp: new Date().toISOString(),
  user_id: "{{ $workflow.userId }}",
  success: true
};

// Send to security monitoring system
fetch('https://security.company.com/api/credential-usage', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(credentialUsage)
});
```

## Advanced Features

n8n's advanced features enable sophisticated automation scenarios and enterprise-grade deployments.

### Sub-Workflows

Reusable workflow components that can be called from multiple parent workflows.

#### Creating Sub-Workflows

```javascript
// Sub-workflow for customer validation
{
  "name": "Customer Validation Sub-Workflow",
  "nodes": [
    {
      "name": "Validate Email",
      "type": "n8n-nodes-base.function",
      "parameters": {
        "functionCode": `
          const email = $json.email;
          const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
          
          return [{
            json: {
              email: email,
              is_valid_email: emailRegex.test(email),
              validation_date: new Date().toISOString()
            }
          }];
        `
      }
    },
    {
      "name": "Check Existing Customer",
      "type": "n8n-nodes-base.postgres",
      "parameters": {
        "operation": "executeQuery",
        "query": "SELECT customer_id FROM customers WHERE email = $1",
        "values": ["{{ $json.email }}"]
      }
    },
    {
      "name": "Return Validation Result",
      "type": "n8n-nodes-base.set",
      "parameters": {
        "values": {
          "boolean": [
            {
              "name": "is_new_customer",
              "value": "{{ $json.length === 0 }}"
            },
            {
              "name": "is_valid", 
              "value": "{{ $json.is_valid_email && $json.is_new_customer }}"
            }
          ]
        }
      }
    }
  ]
}

// Using sub-workflow in parent workflow
{
  "name": "Customer Registration",
  "nodes": [
    {
      "name": "Validate Customer",
      "type": "n8n-nodes-base.executeWorkflow",
      "parameters": {
        "workflowId": "customer-validation-workflow-id",
        "waitForExecution": true
      }
    }
  ]
}
```

### Webhooks

HTTP endpoints for external system integration and real-time triggers.

#### Webhook Configuration

```javascript
// Webhook trigger setup
{
  "parameters": {
    "httpMethod": "POST",
    "path": "customer-updates",
    "authentication": "headerAuth",
    "options": {
      "allowedOrigins": "https://app.company.com",
      "rawBody": false
    }
  }
}

// Webhook response formatting
{
  "name": "Format Webhook Response",
  "type": "n8n-nodes-base.respondToWebhook",
  "parameters": {
    "options": {
      "responseCode": 200,
      "responseHeaders": {
        "Content-Type": "application/json",
        "X-Processing-Time": "{{ $json.processing_time }}ms"
      }
    },
    "respondWith": "json",
    "responseBody": {
      "success": true,
      "message": "Customer data processed successfully",
      "customer_id": "{{ $json.customer_id }}",
      "processed_at": "{{ $now }}"
    }
  }
}
```

#### Webhook Security

```javascript
// Webhook signature validation
{
  "name": "Validate Webhook Signature",
  "type": "n8n-nodes-base.function",
  "parameters": {
    "functionCode": `
      const crypto = require('crypto');
      
      const payload = JSON.stringify($json);
      const signature = $node.context.headers['x-webhook-signature'];
      const secret = $credentials.webhookSecret.secret;
      
      const expectedSignature = crypto
        .createHmac('sha256', secret)
        .update(payload)
        .digest('hex');
      
      if (signature !== expectedSignature) {
        throw new Error('Invalid webhook signature');
      }
      
      return [{ json: $json }];
    `
  }
}
```

### API Integration

Building robust API connections with advanced features.

#### RESTful API Client

```javascript
// Advanced HTTP request with retry logic
{
  "name": "Resilient API Call",
  "type": "n8n-nodes-base.function",
  "parameters": {
    "functionCode": `
      const maxRetries = 3;
      const baseDelay = 1000;
      
      async function makeApiCall(url, options, attempt = 1) {
        try {
          const response = await fetch(url, options);
          
          if (!response.ok) {
            if (response.status >= 500 && attempt <= maxRetries) {
              const delay = baseDelay * Math.pow(2, attempt - 1);
              await new Promise(resolve => setTimeout(resolve, delay));
              return makeApiCall(url, options, attempt + 1);
            }
            throw new Error('API request failed: ' + response.status);
          }
          
          return await response.json();
        } catch (error) {
          if (attempt <= maxRetries) {
            const delay = baseDelay * Math.pow(2, attempt - 1);
            await new Promise(resolve => setTimeout(resolve, delay));
            return makeApiCall(url, options, attempt + 1);
          }
          throw error;
        }
      }
      
      const result = await makeApiCall($json.api_url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + $credentials.api.token
        },
        body: JSON.stringify($json.payload)
      });
      
      return [{ json: result }];
    `
  }
}
```

### Database Operations

Advanced database integration patterns.

#### Transaction Handling

```javascript
// Database transaction workflow
{
  "name": "Process Order Transaction",
  "type": "n8n-nodes-base.function",
  "parameters": {
    "functionCode": `
      const { Client } = require('pg');
      const client = new Client($credentials.database);
      
      try {
        await client.connect();
        await client.query('BEGIN');
        
        // Insert order
        const orderResult = await client.query(
          'INSERT INTO orders (customer_id, total, status) VALUES ($1, $2, $3) RETURNING order_id',
          [$json.customer_id, $json.total, 'pending']
        );
        const orderId = orderResult.rows[0].order_id;
        
        // Insert order items
        for (const item of $json.items) {
          await client.query(
            'INSERT INTO order_items (order_id, product_id, quantity, price) VALUES ($1, $2, $3, $4)',
            [orderId, item.product_id, item.quantity, item.price]
          );
        }
        
        // Update inventory
        for (const item of $json.items) {
          const inventoryResult = await client.query(
            'UPDATE products SET stock_quantity = stock_quantity - $1 WHERE product_id = $2 AND stock_quantity >= $1 RETURNING stock_quantity',
            [item.quantity, item.product_id]
          );
          
          if (inventoryResult.rows.length === 0) {
            throw new Error('Insufficient inventory for product: ' + item.product_id);
          }
        }
        
        await client.query('COMMIT');
        
        return [{
          json: {
            success: true,
            order_id: orderId,
            message: 'Order processed successfully'
          }
        }];
        
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      } finally {
        await client.end();
      }
    `
  }
}
```

### File Processing

Advanced file handling and processing capabilities.

#### Batch File Processing

```javascript
// Process multiple files with AI analysis
{
  "name": "Batch Document Processor",
  "type": "n8n-nodes-base.function",
  "parameters": {
    "functionCode": `
      const fs = require('fs');
      const path = require('path');
      const pdf = require('pdf-parse');
      
      const processedFiles = [];
      const inputDirectory = $json.input_directory;
      const files = fs.readdirSync(inputDirectory);
      
      for (const filename of files) {
        if (!filename.toLowerCase().endsWith('.pdf')) continue;
        
        const filePath = path.join(inputDirectory, filename);
        const buffer = fs.readFileSync(filePath);
        
        try {
          // Extract text from PDF
          const data = await pdf(buffer);
          const text = data.text;
          
          // Prepare for AI processing
          processedFiles.push({
            json: {
              filename: filename,
              filepath: filePath,
              text_content: text,
              page_count: data.numpages,
              file_size: buffer.length,
              processed_at: new Date().toISOString(),
              ready_for_ai: true
            }
          });
        } catch (error) {
          processedFiles.push({
            json: {
              filename: filename,
              error: error.message,
              processed_at: new Date().toISOString(),
              ready_for_ai: false
            }
          });
        }
      }
      
      return processedFiles;
    `
  }
}
```

## LangChain Integration

### LangChain Nodes

Using LangChain.

### Memory Systems

Conversation memory.

### Tools and Chains

Building complex chains.

### Vector Stores

Connecting to vector DBs.

## Development

### Custom Nodes

Creating extensions.

### Community Nodes

Installing third-party nodes.

### Testing Workflows

Debugging and testing.

### Version Control

Git integration.

## Deployment

### Production Setup

Deploying to production.

### Scaling

Handling high volumes.

### Monitoring

Tracking executions.

### Backup and Recovery

Data protection.

## Security

### Authentication

Securing access.

### Credential Management

Protecting secrets.

### Network Security

Firewall configuration.

## Best Practices

Following these best practices ensures your n8n workflows are maintainable, scalable, and reliable.

### Workflow Design

Structure workflows for clarity, maintainability, and performance.

#### Design Principles

1. **Single Responsibility**: Each workflow should have one clear purpose
2. **Modularity**: Break complex processes into sub-workflows
3. **Error Handling**: Always include error handling and recovery paths
4. **Documentation**: Use comments and descriptive node names
5. **Testing**: Test workflows thoroughly before production deployment

#### Workflow Structure Example

```javascript
{
  "name": "Customer Onboarding Pipeline",
  "description": "Complete customer onboarding with validation, setup, and notifications",
  "tags": ["customer", "onboarding", "production"],
  "structure": {
    "input_validation": {
      "nodes": ["Webhook", "Validate Input", "Check Duplicates"],
      "purpose": "Ensure data quality and prevent duplicates"
    },
    "data_processing": {
      "nodes": ["Transform Data", "Generate ID", "Set Defaults"],
      "purpose": "Prepare customer data for storage"
    },
    "external_integrations": {
      "nodes": ["Create CRM Record", "Setup Email", "Provision Access"],
      "purpose": "Integrate with external systems"
    },
    "notifications": {
      "nodes": ["Send Welcome Email", "Notify Sales Team", "Log Activity"],
      "purpose": "Communicate successful onboarding"
    },
    "error_handling": {
      "nodes": ["Error Handler", "Send Alert", "Log Error"],
      "purpose": "Handle and report failures gracefully"
    }
  }
}
```

### Performance Optimization

Optimize workflows for speed and resource efficiency.

#### Optimization Strategies

1. **Minimize HTTP Requests**: Batch API calls when possible
2. **Use Efficient Data Structures**: Avoid nested loops in large datasets
3. **Implement Caching**: Cache frequently accessed data
4. **Parallel Processing**: Use parallel branches for independent operations
5. **Database Optimization**: Use indexed queries and connection pooling

```javascript
// Efficient batch processing
{
  "name": "Optimized Batch Processor",
  "type": "n8n-nodes-base.function",
  "parameters": {
    "functionCode": `
      const items = $input.all();
      const batchSize = 100;
      const batches = [];
      
      // Create batches for parallel processing
      for (let i = 0; i < items.length; i += batchSize) {
        const batch = items.slice(i, i + batchSize);
        batches.push({
          json: {
            batch_id: Math.floor(i / batchSize) + 1,
            items: batch.map(item => item.json),
            size: batch.length
          }
        });
      }
      
      return batches;
    `
  }
}
```

### Error Handling

Build robust error handling into every workflow.

#### Error Handling Patterns

```javascript
// Comprehensive error handling workflow
{
  "name": "Robust Error Handler",
  "nodes": [
    {
      "name": "Try Operation",
      "type": "n8n-nodes-base.function",
      "continueOnFail": true,
      "parameters": {
        "functionCode": `
          try {
            const result = performRiskyOperation($json);
            return [{
              json: {
                success: true,
                result: result,
                operation_id: $json.operation_id
              }
            }];
          } catch (error) {
            return [{
              json: {
                success: false,
                error: error.message,
                error_code: error.code || 'UNKNOWN',
                operation_id: $json.operation_id,
                timestamp: new Date().toISOString(),
                retry_count: $json.retry_count || 0
              }
            }];
          }
        `
      }
    },
    {
      "name": "Check If Retry Needed",
      "type": "n8n-nodes-base.if",
      "parameters": {
        "conditions": {
          "boolean": [
            {"value1": "={{ $json.success }}", "operation": "equal", "value2": false}
          ],
          "number": [
            {"value1": "={{ $json.retry_count }}", "operation": "smaller", "value2": 3}
          ]
        },
        "combineOperation": "all"
      }
    },
    {
      "name": "Schedule Retry",
      "type": "n8n-nodes-base.wait",
      "parameters": {
        "amount": "{{ Math.pow(2, $json.retry_count) * 1000 }}", // Exponential backoff
        "unit": "milliseconds"
      }
    }
  ]
}
```

### Workflow Documentation

Maintain comprehensive documentation for all workflows.

#### Documentation Template

```markdown
# Workflow: Customer Data Sync

## Purpose
Synchronize customer data between CRM and email marketing platform daily.

## Trigger
- **Type**: Cron
- **Schedule**: Daily at 2:00 AM UTC
- **Timezone**: UTC

## Dependencies
- CRM API access
- Email platform credentials
- PostgreSQL database connection

## Data Flow
1. Extract updated customers from CRM (last 24 hours)
2. Transform data to email platform format
3. Update email platform contacts
4. Log sync results to database

## Error Handling
- API failures: 3 retries with exponential backoff
- Data validation errors: Skip record and log
- Critical failures: Send alert to admin team

## Monitoring
- Success/failure rates tracked in dashboard
- Performance metrics logged
- Daily summary report sent to operations team

## Maintenance
- Review and update monthly
- Test in staging before production changes
- Document all modifications
```

## Use Case Examples

Real-world examples demonstrating n8n's capabilities across different industries and use cases.

### Customer Support Bot

Automated customer support system with AI integration.

```javascript
{
  "name": "AI Customer Support System",
  "description": "Automated support ticket processing with AI analysis and routing",
  "workflow": {
    "trigger": {
      "type": "webhook",
      "path": "support-ticket",
      "method": "POST"
    },
    "processing_steps": [
      {
        "name": "Extract Ticket Data",
        "function": `
          const ticket = {
            id: generateTicketId(),
            customer_email: $json.email,
            subject: $json.subject,
            message: $json.message,
            priority: 'medium',
            status: 'new',
            created_at: new Date().toISOString()
          };
          
          return [{ json: ticket }];
        `
      },
      {
        "name": "AI Sentiment Analysis",
        "ai_model": "gpt-4",
        "prompt": "Analyze the sentiment and urgency of this support ticket. Classify as: positive/neutral/negative and low/medium/high priority.\n\nTicket: {{ $json.subject }} - {{ $json.message }}",
        "output_parsing": "json"
      },
      {
        "name": "AI Response Generation",
        "ai_model": "gpt-4-turbo",
        "prompt": `You are a helpful customer support agent. Generate an appropriate response to this ticket:
        
        Customer: {{ $json.customer_email }}
        Subject: {{ $json.subject }}
        Message: {{ $json.message }}
        Sentiment: {{ $json.sentiment }}
        Priority: {{ $json.priority }}
        
        Provide a professional, empathetic response that addresses the customer's concern.`
      },
      {
        "name": "Route Based on Priority",
        "routing_logic": {
          "high": "immediate_escalation",
          "medium": "auto_response_with_tracking",
          "low": "auto_resolution_attempt"
        }
      },
      {
        "name": "Send Response",
        "email_config": {
          "to": "{{ $json.customer_email }}",
          "subject": "Re: {{ $json.subject }} [Ticket #{{ $json.id }}]",
          "body": "{{ $json.ai_response }}",
          "signature": "Customer Support Team"
        }
      }
    ]
  }
}
```

### Content Generation Pipeline

Automated content creation and distribution system.

```javascript
{
  "name": "AI Content Generation Pipeline",
  "description": "Daily content creation for multiple channels",
  "schedule": "0 8 * * *", // Daily at 8 AM
  "pipeline_stages": {
    "research": {
      "web_scraping": {
        "sources": [
          "https://news.ycombinator.com",
          "https://www.reddit.com/r/technology",
          "https://techcrunch.com"
        ],
        "extraction_rules": {
          "headlines": "h1, h2, .title",
          "summaries": ".summary, .excerpt",
          "links": "a[href]"
        }
      },
      "trend_analysis": {
        "ai_model": "gpt-4",
        "prompt": "Analyze these trending topics and identify the top 5 most interesting technology stories for our audience:\n{{ $json.scraped_content }}"
      }
    },
    "content_creation": {
      "blog_posts": {
        "ai_model": "claude-3-opus",
        "prompt": "Write a 800-word blog post about: {{ $json.selected_topic }}. Include practical insights and actionable takeaways.",
        "style": "professional, informative, engaging"
      },
      "social_media": {
        "twitter": {
          "ai_model": "gpt-4",
          "prompt": "Create 3 engaging tweets about: {{ $json.blog_topic }}. Include relevant hashtags. Keep under 280 characters each."
        },
        "linkedin": {
          "ai_model": "claude-3-sonnet", 
          "prompt": "Write a professional LinkedIn post about: {{ $json.blog_topic }}. Focus on industry insights and professional value."
        }
      }
    },
    "publication": {
      "wordpress_publish": {
        "title": "{{ $json.blog_title }}",
        "content": "{{ $json.blog_content }}",
        "categories": "{{ $json.suggested_categories }}",
        "status": "draft" // Review before publishing
      },
      "social_scheduling": {
        "twitter": {
          "schedule_time": "{{ $now.plus({hours: 2}) }}",
          "content": "{{ $json.twitter_posts }}"
        },
        "linkedin": {
          "schedule_time": "{{ $now.plus({hours: 4}) }}",
          "content": "{{ $json.linkedin_post }}"
        }
      }
    }
  }
}
```

### Data Analysis Workflow

Automated business intelligence and reporting system.

```javascript
{
  "name": "Business Intelligence Pipeline",
  "description": "Daily business metrics analysis and reporting",
  "data_sources": {
    "sales_db": {
      "query": `
        SELECT 
          DATE_TRUNC('day', created_at) as date,
          COUNT(*) as orders,
          SUM(total_amount) as revenue,
          AVG(total_amount) as avg_order_value,
          COUNT(DISTINCT customer_id) as unique_customers
        FROM orders 
        WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
        GROUP BY DATE_TRUNC('day', created_at)
        ORDER BY date DESC
      `
    },
    "website_analytics": {
      "api_endpoint": "https://analytics.google.com/v4/reports:batchGet",
      "metrics": ["sessions", "pageviews", "bounceRate", "avgSessionDuration"],
      "dimensions": ["date", "source", "medium"]
    },
    "support_tickets": {
      "query": `
        SELECT 
          DATE_TRUNC('day', created_at) as date,
          COUNT(*) as total_tickets,
          COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved,
          AVG(EXTRACT(EPOCH FROM (resolved_at - created_at))/3600) as avg_resolution_hours
        FROM support_tickets
        WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
        GROUP BY DATE_TRUNC('day', created_at)
      `
    }
  },
  "analysis": {
    "trend_analysis": {
      "ai_model": "gpt-4-turbo",
      "prompt": `Analyze this business data and provide insights:
      
      Sales Data: {{ $json.sales_data }}
      Website Analytics: {{ $json.analytics_data }}
      Support Metrics: {{ $json.support_data }}
      
      Identify trends, anomalies, and actionable insights. Provide specific recommendations.`
    },
    "forecasting": {
      "ai_model": "claude-3-opus",
      "prompt": "Based on the historical data, provide a 7-day forecast for key metrics. Include confidence intervals and assumptions."
    }
  },
  "reporting": {
    "executive_dashboard": {
      "charts": [
        {"type": "line", "data": "revenue_trend", "title": "Daily Revenue"},
        {"type": "bar", "data": "customer_acquisition", "title": "New Customers"},
        {"type": "pie", "data": "traffic_sources", "title": "Traffic Sources"}
      ],
      "kpis": [
        {"metric": "total_revenue", "change": "{{ $json.revenue_change_percent }}%"},
        {"metric": "avg_order_value", "change": "{{ $json.aov_change_percent }}%"},
        {"metric": "customer_satisfaction", "value": "{{ $json.csat_score }}"}
      ]
    },
    "distribution": {
      "email_recipients": ["ceo@company.com", "ops@company.com"],
      "slack_channel": "#business-intelligence",
      "schedule": "daily at 9 AM"
    }
  }
}
```

### Lead Qualification

Automated sales lead processing and qualification system.

```javascript
{
  "name": "AI Lead Qualification System",
  "description": "Intelligent lead scoring and routing",
  "lead_processing": {
    "data_enrichment": {
      "company_lookup": {
        "api": "clearbit",
        "enrich_fields": ["company_size", "industry", "revenue", "location", "technologies"]
      },
      "email_verification": {
        "service": "zerobounce",
        "check_deliverability": true
      }
    },
    "ai_scoring": {
      "model": "gpt-4-turbo",
      "scoring_criteria": {
        "company_fit": {
          "weight": 0.3,
          "factors": ["industry_match", "company_size", "revenue_range", "technology_stack"]
        },
        "intent_signals": {
          "weight": 0.4,
          "factors": ["form_completion", "content_engagement", "demo_request", "pricing_page_views"]
        },
        "contact_quality": {
          "weight": 0.3,
          "factors": ["job_title_relevance", "decision_maker_level", "email_deliverability"]
        }
      },
      "prompt": `
        Analyze this lead and provide a qualification score (0-100) and reasoning:
        
        Contact Info: {{ $json.contact_data }}
        Company Data: {{ $json.company_data }}
        Behavioral Data: {{ $json.behavior_data }}
        
        Consider our ideal customer profile and scoring criteria. Provide:
        1. Overall score (0-100)
        2. Individual category scores
        3. Key positive/negative factors
        4. Recommended next steps
      `
    },
    "routing_logic": {
      "hot_leads": {
        "criteria": "score >= 80",
        "action": "immediate_sales_assignment",
        "sla": "15_minutes"
      },
      "warm_leads": {
        "criteria": "score >= 60 && score < 80", 
        "action": "nurture_sequence",
        "followup": "24_hours"
      },
      "cold_leads": {
        "criteria": "score < 60",
        "action": "marketing_automation",
        "reevaluate": "30_days"
      }
    },
    "personalization": {
      "email_templates": {
        "ai_model": "claude-3-sonnet",
        "prompt": "Create a personalized outreach email for this lead based on their profile and company information. Be specific and relevant.",
        "tone": "professional, helpful, not salesy"
      },
      "meeting_agenda": {
        "ai_model": "gpt-4",
        "prompt": "Create a meeting agenda tailored to this prospect's industry, company size, and likely pain points."
      }
    }
  }
}
```

## Troubleshooting

Common issues and their solutions when working with n8n workflows.

### Common Issues

Frequently encountered problems and their resolutions.

#### Workflow Execution Failures

**Issue**: Workflows failing randomly or under load

```javascript
// Solution: Implement retry logic and better error handling
{
  "name": "Resilient Node",
  "type": "n8n-nodes-base.function",
  "continueOnFail": true,
  "retryOnFail": true,
  "maxTries": 3,
  "waitBetweenTries": 2000,
  "parameters": {
    "functionCode": `
      try {
        const result = await performOperation($json);
        return [{ json: { success: true, data: result } }];
      } catch (error) {
        // Log error details
        console.error('Operation failed:', error.message);
        
        // Return error information for downstream handling
        return [{
          json: {
            success: false,
            error: error.message,
            timestamp: new Date().toISOString(),
            input_data: $json
          }
        }];
      }
    `
  }
}
```

#### Memory Issues with Large Datasets

**Issue**: Workflows running out of memory when processing large amounts of data

```javascript
// Solution: Stream processing and chunking
{
  "name": "Memory-Efficient Processor",
  "type": "n8n-nodes-base.function",
  "parameters": {
    "functionCode": `
      const chunkSize = 1000;
      const totalItems = $input.all().length;
      const chunks = Math.ceil(totalItems / chunkSize);
      
      // Process in smaller chunks to avoid memory issues
      const results = [];
      
      for (let i = 0; i < chunks; i++) {
        const start = i * chunkSize;
        const end = Math.min(start + chunkSize, totalItems);
        const chunk = $input.all().slice(start, end);
        
        // Process chunk
        const processedChunk = await processChunk(chunk);
        results.push(...processedChunk);
        
        // Optional: Add delay to prevent overwhelming APIs
        if (i < chunks - 1) {
          await new Promise(resolve => setTimeout(resolve, 100));
        }
      }
      
      return results;
      
      async function processChunk(items) {
        return items.map(item => ({
          json: {
            ...item.json,
            processed: true,
            chunk_id: i
          }
        }));
      }
    `
  }
}
```

#### API Rate Limit Issues

**Issue**: External API calls failing due to rate limits

```javascript
// Solution: Rate limiting and exponential backoff
{
  "name": "Rate-Limited API Client",
  "type": "n8n-nodes-base.function",
  "parameters": {
    "functionCode": `
      const rateLimiter = {
        requests: 0,
        resetTime: Date.now() + 60000, // Reset every minute
        maxRequests: 100 // 100 requests per minute
      };
      
      async function makeApiCall(url, options) {
        // Check rate limit
        if (Date.now() > rateLimiter.resetTime) {
          rateLimiter.requests = 0;
          rateLimiter.resetTime = Date.now() + 60000;
        }
        
        if (rateLimiter.requests >= rateLimiter.maxRequests) {
          const waitTime = rateLimiter.resetTime - Date.now();
          await new Promise(resolve => setTimeout(resolve, waitTime));
          rateLimiter.requests = 0;
          rateLimiter.resetTime = Date.now() + 60000;
        }
        
        rateLimiter.requests++;
        
        try {
          const response = await fetch(url, options);
          
          if (response.status === 429) {
            // Rate limited, wait and retry
            const retryAfter = response.headers.get('Retry-After') || 60;
            await new Promise(resolve => setTimeout(resolve, retryAfter * 1000));
            return makeApiCall(url, options);
          }
          
          return await response.json();
        } catch (error) {
          throw new Error('API call failed: ' + error.message);
        }
      }
      
      const result = await makeApiCall($json.api_url, {
        method: 'GET',
        headers: {
          'Authorization': 'Bearer ' + $credentials.api.token
        }
      });
      
      return [{ json: result }];
    `
  }
}
```

### Error Messages

Understanding and resolving common error messages.

#### "Cannot read property of undefined"

```javascript
// Problem: Accessing undefined object properties
// ❌ This will fail if customer is undefined
const email = $json.customer.email;

// ✅ Safe property access
const email = $json.customer?.email || null;
const email = ($json.customer && $json.customer.email) || null;
```

#### "Invalid JSON" Errors

```javascript
// Problem: Malformed JSON in HTTP requests
// ✅ Validate JSON before sending
{
  "name": "Safe JSON Handler",
  "type": "n8n-nodes-base.function",
  "parameters": {
    "functionCode": `
      function isValidJSON(str) {
        try {
          JSON.parse(str);
          return true;
        } catch (e) {
          return false;
        }
      }
      
      const payload = $json.payload;
      
      if (typeof payload === 'string' && !isValidJSON(payload)) {
        throw new Error('Invalid JSON payload: ' + payload);
      }
      
      const safePayload = typeof payload === 'object' ? 
        JSON.stringify(payload) : payload;
      
      return [{ json: { payload: safePayload } }];
    `
  }
}
```

#### "Workflow execution timed out"

```javascript
// Problem: Long-running operations
// ✅ Solution: Break into smaller operations or increase timeout
{
  "settings": {
    "executionTimeout": 300, // 5 minutes
    "maxExecutionTimeout": 3600 // 1 hour maximum
  },
  "async_processing": {
    "name": "Long Running Task",
    "type": "n8n-nodes-base.function",
    "parameters": {
      "functionCode": `
        // For very long operations, use webhooks for async processing
        const taskId = generateUniqueId();
        
        // Start long-running task in background
        fetch('https://your-service.com/long-task', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            task_id: taskId,
            callback_url: 'https://your-n8n.com/webhook/task-complete',
            data: $json
          })
        });
        
        // Return immediately with task ID
        return [{
          json: {
            status: 'processing',
            task_id: taskId,
            message: 'Task started, will callback when complete'
          }
        }];
      `
    }
  }
}
```

### Performance Issues

Optimization techniques for slow workflows.

#### Database Query Optimization

```sql
-- ❌ Slow query without indexes
SELECT * FROM orders WHERE customer_email = 'user@example.com' AND order_date > '2024-01-01';

-- ✅ Optimized with indexes and specific columns
CREATE INDEX idx_orders_customer_email ON orders(customer_email);
CREATE INDEX idx_orders_date ON orders(order_date);

SELECT order_id, total_amount, order_date 
FROM orders 
WHERE customer_email = $1 AND order_date > $2
LIMIT 100;
```

#### Workflow Optimization

```javascript
// ❌ Sequential processing (slow)
{
  "workflow": {
    "step1": "Process Item 1",
    "step2": "Process Item 2", 
    "step3": "Process Item 3"
  }
}

// ✅ Parallel processing (fast)
{
  "workflow": {
    "split": "Split items into parallel branches",
    "parallel_processing": {
      "branch1": "Process batch 1",
      "branch2": "Process batch 2",
      "branch3": "Process batch 3"
    },
    "merge": "Combine results"
  }
}
```

## Resources

Comprehensive resources for learning and mastering n8n.

### Official Documentation

Essential resources from the n8n team.

- **[n8n Documentation](https://docs.n8n.io/)**: Complete official documentation
- **[Node Reference](https://docs.n8n.io/integrations/)**: Detailed node documentation
- **[API Documentation](https://docs.n8n.io/api/)**: REST API reference
- **[Self-Hosting Guide](https://docs.n8n.io/hosting/)**: Deployment and hosting instructions
- **[Security Best Practices](https://docs.n8n.io/security/)**: Security guidelines and recommendations

### Community

Active community resources and support channels.

#### Forums and Discussion

- **[n8n Community Forum](https://community.n8n.io/)**: Official community forum
- **[Discord Server](https://discord.gg/n8n)**: Real-time chat and support
- **[Reddit Community](https://reddit.com/r/n8n)**: Community discussions and tips
- **[GitHub Discussions](https://github.com/n8n-io/n8n/discussions)**: Development discussions

#### Learning Resources

- **[n8n Academy](https://academy.n8n.io/)**: Free courses and tutorials
- **[YouTube Channel](https://youtube.com/@n8n-io)**: Video tutorials and demos
- **[Blog](https://n8n.io/blog/)**: Use cases, tutorials, and updates
- **[Workflow Templates](https://n8n.io/workflows/)**: Pre-built workflow templates

### Templates

Ready-to-use workflow templates for common scenarios.

#### Business Process Templates

- **Lead Management**: CRM integration and lead scoring
- **Customer Onboarding**: Automated welcome sequences
- **Invoice Processing**: OCR and payment automation
- **Inventory Management**: Stock monitoring and reordering

#### AI and Data Templates

- **Content Generation**: Automated blog and social media content
- **Document Analysis**: AI-powered document processing
- **Customer Support**: Automated ticket routing and responses
- **Data Synchronization**: Multi-system data sync workflows

#### Integration Templates

- **E-commerce**: Shopify, WooCommerce, Stripe integrations
- **Marketing**: Mailchimp, HubSpot, Google Analytics workflows
- **Development**: GitHub, GitLab, CI/CD pipeline automation
- **Communication**: Slack, Teams, Discord notification systems

### Learning Path

Structured approach to mastering n8n.

#### Beginner (Weeks 1-2)

1. **Setup and Basics**
   - Install n8n (cloud or self-hosted)
   - Create first simple workflow
   - Understand nodes and connections
   - Learn basic expressions and variables

2. **Core Concepts**
   - Triggers and scheduling
   - Data transformation with Set and Function nodes
   - Error handling basics
   - Credential management

#### Intermediate (Weeks 3-6)

1. **Advanced Workflows**
   - Complex data processing patterns
   - API integrations and webhooks
   - Database operations
   - Sub-workflows and modularity

2. **AI Integration**
   - OpenAI and Claude integrations
   - Embedding generation and vector search
   - LangChain workflows
   - RAG implementations

#### Advanced (Weeks 7-12)

1. **Production Deployment**
   - Performance optimization
   - Monitoring and alerting
   - Security hardening
   - Scaling strategies

2. **Custom Development**
   - Custom node development
   - Community node installation
   - Advanced JavaScript/Python usage
   - Workflow testing and CI/CD

### Additional Tools and Services

Complementary tools that work well with n8n.

#### Development Tools

- **Postman**: API testing and development
- **Insomnia**: REST client for API testing
- **Git**: Version control for workflow backups
- **Docker**: Containerization and deployment

#### Monitoring and Observability

- **Grafana**: Workflow performance dashboards
- **Prometheus**: Metrics collection
- **Sentry**: Error tracking and monitoring
- **Uptime Robot**: Uptime monitoring

#### AI and Data Platforms

- **OpenAI**: GPT models and AI services
- **Anthropic**: Claude AI models
- **Pinecone**: Vector database for AI applications
- **Supabase**: Open-source Firebase alternative

By following this comprehensive guide, you'll be well-equipped to leverage n8n's full potential for AI-powered workflow automation. Start with simple workflows and gradually build complexity as you become more comfortable with the platform's capabilities.
