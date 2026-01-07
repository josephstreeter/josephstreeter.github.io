# Flowise

## Overview

Flowise is an open-source, low-code tool for building customized LLM orchestration flows and AI agents using a visual interface. Built on LangChainJS, it provides an intuitive way to create, test, and deploy AI applications.

## What is Flowise?

Flowise enables developers and non-developers alike to build LLM applications through a drag-and-drop interface. It simplifies the complexity of LangChain while providing flexibility and customization options.

## Key Features

- **Visual Workflow Builder**: Intuitive drag-and-drop interface
- **LangChainJS Integration**: Built on LangChain for JavaScript/TypeScript
- **Extensive Components**: Pre-built nodes for common AI operations
- **API Generation**: Automatic REST API creation for flows
- **Embeddable Widgets**: Ready-to-use chat widgets
- **Self-Hosted**: Full control over data and deployment
- **Open Source**: Free and community-driven

## Installation

### Quick Start with Docker

```bash
docker run -d \
  --name flowise \
  -p 3000:3000 \
  flowiseai/flowise
```

Access at `http://localhost:3000`

### NPM Installation

```bash
npm install -g flowise
npx flowise start
```

### Using Docker Compose

```yaml
version: '3.1'

services:
  flowise:
    image: flowiseai/flowise
    restart: always
    ports:
      - "3000:3000"
    volumes:
      - ~/.flowise:/root/.flowise
    environment:
      - FLOWISE_USERNAME=admin
      - FLOWISE_PASSWORD=your-password
```

### From Source

```bash
git clone https://github.com/FlowiseAI/Flowise.git
cd Flowise
npm install
npm run build
npm start
```

## Getting Started

### Prerequisites

- Node.js 18 or higher (for local installation)
- Docker (for containerized deployment)
- API keys for LLM providers
- Basic understanding of AI concepts

### First Steps

1. **Launch Flowise**: Open web interface
2. **Explore Marketplace**: Browse pre-built chatflow templates
3. **Create Chatflow**: Start new project
4. **Add Nodes**: Drag components onto canvas
5. **Configure Settings**: Set up API keys and parameters
6. **Connect Nodes**: Link components together
7. **Test**: Use built-in chat interface
8. **Deploy**: Generate API endpoint

## Core Components

### Chat Models

- **ChatOpenAI**: OpenAI GPT models
- **ChatAnthropic**: Claude models
- **ChatGoogleGenerativeAI**: Gemini models
- **ChatOllama**: Local open-source models
- **Azure OpenAI**: Microsoft Azure-hosted OpenAI

### LLM Models

- **OpenAI**: Legacy completion models
- **HuggingFace**: Open-source models
- **Cohere**: Cohere language models
- **Custom LLM**: Integrate any model via API

### Embeddings

- **OpenAI Embeddings**: text-embedding-ada-002
- **HuggingFace Embeddings**: Open-source embeddings
- **Cohere Embeddings**: Cohere's embedding models
- **Azure OpenAI Embeddings**: Azure-hosted embeddings

### Vector Stores

- **Pinecone**: Cloud vector database
- **Chroma**: Local vector storage
- **Qdrant**: High-performance vector search
- **Weaviate**: Open-source vector database
- **Supabase**: PostgreSQL with pgvector
- **Milvus**: Scalable vector database

### Document Loaders

- **PDF File**: Extract text from PDF documents
- **Text File**: Load plain text files
- **CSV File**: Process CSV data
- **JSON File**: Parse JSON data
- **Web Scraper**: Extract content from websites
- **API Loader**: Fetch data from APIs

### Text Splitters

- **Recursive Character**: Split by characters recursively
- **Token Splitter**: Split based on token count
- **Markdown Splitter**: Preserve markdown structure
- **Code Splitter**: Language-aware code splitting

### Memory

- **Buffer Memory**: Store recent messages
- **Buffer Window Memory**: Fixed-size message buffer
- **Conversation Summary**: Maintain summary
- **Zep Memory**: Persistent conversation storage
- **Redis-backed Memory**: Scalable memory solution

### Chains

- **LLM Chain**: Basic prompt → LLM → output
- **Retrieval QA Chain**: RAG implementation
- **Conversational Retrieval Chain**: RAG with memory
- **API Chain**: Call external APIs
- **SQL Database Chain**: Query databases
- **OpenAPI Chain**: Interact with OpenAPI specs

### Agents

- **OpenAI Functions Agent**: Uses function calling
- **Conversational Agent**: Chat-optimized agent
- **React Agent**: Reasoning and acting agent
- **Tool Calling Agent**: Multi-tool orchestration
- **CSV Agent**: Analyze CSV files
- **SQL Agent**: Query SQL databases

### Tools

- **Calculator**: Mathematical operations
- **Web Browser**: Browse and extract web content
- **Search API**: Search engines (Google, Bing, SerpAPI)
- **Wikipedia**: Query Wikipedia
- **Wolfram Alpha**: Computational knowledge
- **Custom Tool**: Create your own tools

## Building Chatflows

### Simple Chatbot

**Components**:

1. Chat Model (ChatOpenAI)
2. Buffer Memory
3. Conversation Chain

**Step-by-Step Implementation**:

1. **Add Chat Model Node**:
   - Drag "ChatOpenAI" onto canvas
   - Configure settings:
     - Model: gpt-3.5-turbo (or gpt-4 for complex tasks)
     - Temperature: 0.7 (balanced creativity/consistency)
     - Max Tokens: 500
   - Add API key in credentials

2. **Add Memory Node**:
   - Drag "Buffer Memory" node
   - Configuration:
     - Memory Key: "chat_history"
     - Session ID: Auto-generated or custom
     - Return Messages: true

3. **Add Conversation Chain**:
   - Drag "Conversation Chain" node
   - Connect Chat Model to chain
   - Connect Memory to chain
   - Set system message (optional)

4. **Configure System Message**:

   ```text
   You are a helpful AI assistant. Provide clear, concise, and accurate responses.
   Always be polite and professional. If you don't know something, say so honestly.
   ```

5. **Test**: Use built-in chat interface to verify functionality

**Result**: Basic conversational AI with context awareness

### Document Q&A (RAG)

**Components**:

1. Document Loader
2. Text Splitter
3. Embeddings
4. Vector Store
5. Retrieval QA Chain
6. Chat Model

**Detailed Implementation**:

#### Phase 1: Document Processing

##### Step 1: Document Loader

- Select appropriate loader:
  - PDF File: For PDF documents
  - Text File: For .txt files
  - Web Scraper: For web content
  - API Loader: For external data
- Upload or specify document source

##### Step 2: Text Splitter

- Use "Recursive Character Text Splitter"
- Configuration:
  - Chunk Size: 1000 characters
  - Chunk Overlap: 200 characters
  - Separators: `["\n\n", "\n", ". ", " ", ""]`

```javascript
// Example configuration
{
  "chunkSize": 1000,
  "chunkOverlap": 200,
  "separators": ["\n\n", "\n", ". ", " ", ""]
}
```

##### Step 3: Embeddings

- Select embedding model:
  - OpenAI Embeddings (text-embedding-ada-002): High quality
  - HuggingFace Embeddings: Free, open-source
  - Cohere Embeddings: Alternative paid option

##### Step 4: Vector Store

- Choose vector database:
  - **Pinecone**: Best for production, scalable
  - **Chroma**: Good for local development
  - **Qdrant**: High performance, self-hosted
  - **Supabase**: PostgreSQL with pgvector

**Pinecone Configuration**:

```javascript
{
  "environment": "us-west1-gcp",
  "index": "flowise-docs",
  "namespace": "default"
}
```

#### Phase 2: Query Pipeline

##### Step 5: Retrieval QA Chain

- Add "Conversational Retrieval QA Chain"
- Configuration:
  - Chain Type: "stuff" (for small docs) or "map_reduce" (for large)
  - Return Source Documents: true
  - Top K: 4 (number of chunks to retrieve)

##### Step 6: Chat Model

- Add ChatOpenAI or preferred model
- Settings:
  - Model: gpt-3.5-turbo-16k (for larger context)
  - Temperature: 0.2 (more factual)

**Custom Prompt Template**:

```text
Use the following context to answer the question. If you cannot answer based on the context, say "I don't have enough information in the provided documents."

Context:
{context}

Question: {question}

Answer:
```

**Flow Diagram**:

```text
User Query →
  Embed Query →
  Search Vector Store (retrieve top 4 chunks) →
  Construct Prompt with Context →
  LLM Generation →
  Response with Citations
```

**Testing**:

- Upload test documents
- Ask questions about document content
- Verify sources are cited
- Check accuracy of responses

### Agent with Tools

**Components**:

1. Chat Model
2. Search Tool (SerpAPI or DuckDuckGo)
3. Calculator Tool
4. Agent Executor
5. Buffer Memory

**Implementation Steps**:

1. **Add Chat Model**:
   - Use ChatOpenAI with function calling
   - Model: gpt-3.5-turbo or gpt-4

2. **Configure Tools**:

   **Search Tool**:

   ```javascript
   {
     "toolName": "search",
     "description": "Search the internet for current information",
     "provider": "serpapi" // or "duckduckgo"
   }
   ```

   **Calculator Tool**:

   ```javascript
   {
     "toolName": "calculator",
     "description": "Perform mathematical calculations"
   }
   ```

3. **Add Agent Node**:
   - Use "OpenAI Functions Agent" or "React Agent"
   - Connect tools to agent
   - Connect memory for context

4. **Agent Prompt**:

   ```text
   You are a helpful assistant with access to tools.
   
   Available tools:
   - search: Search the internet for current information
   - calculator: Perform mathematical calculations
   
   Think step by step:
   1. Understand the user's question
   2. Determine which tool(s) to use
   3. Use the tool(s) to gather information
   4. Synthesize a comprehensive answer
   
   Always cite your sources when using search results.
   ```

**Capability**: Reasoning agent that can search and calculate

**Example Interactions**:

```text
User: "What is the current stock price of Apple multiplied by 100?"

Agent Process:
1. Use search tool → Find AAPL stock price ($180)
2. Use calculator tool → Calculate 180 * 100 = 18000
3. Respond → "The current Apple stock price is approximately $180, 
              so multiplied by 100 equals $18,000."
```

### API Integration Chatbot

**Components**:

1. Chat Model
2. API Chain
3. Custom Tool
4. Memory

**Implementation**:

#### Step 1: Create Custom API Tool

```javascript
// Custom tool for API integration
const customApiTool = {
  name: "customer_lookup",
  description: "Look up customer information by ID or email",
  schema: {
    type: "object",
    properties: {
      query: {
        type: "string",
        description: "Customer ID or email to look up"
      }
    },
    required: ["query"]
  },
  func: async (input) => {
    const response = await fetch(`https://api.yourcompany.com/customers/search`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.API_KEY}`
      },
      body: JSON.stringify({ query: input.query })
    });
    
    if (!response.ok) {
      return `Error: Unable to fetch customer information`;
    }
    
    const data = await response.json();
    return JSON.stringify(data, null, 2);
  }
};
```

#### Step 2: Configure API Chain

- Add API Chain node
- Configure endpoint details
- Set authentication method
- Define request/response format

#### Step 3: Agent Setup

- Connect custom tool to agent
- Add system prompt for API interaction
- Configure error handling

**System Prompt**:

```text
You are a customer service assistant with access to customer data.

When a user asks about a customer, use the customer_lookup tool to fetch their information.
Present the information in a clear, conversational manner.

Always:
- Verify customer identity before sharing sensitive info
- Handle errors gracefully
- Respect data privacy guidelines
```

**Use**: Connect chatbot to CRM, databases, or any external service

### Multi-Document RAG System

**Advanced Implementation**:

**Components**:

1. Multiple Document Loaders (different sources)
2. Document Classifier (route by type)
3. Separate Vector Stores (by document type)
4. Multi-Query Retriever
5. Context Compression
6. Chat Model with Citations

**Architecture**:

```text
Documents → Classify by Type →
  [Technical Docs → Vector Store A]
  [Marketing Docs → Vector Store B]
  [Support Docs → Vector Store C]
  
Query → Route to Appropriate Store(s) →
  Retrieve from Multiple Sources →
  Compress Context →
  Generate Response with Sources
```

**Implementation**:

```javascript
// Document classification
const classifyDocument = (doc) => {
  const technicalKeywords = ['API', 'function', 'class', 'method'];
  const marketingKeywords = ['product', 'feature', 'benefit', 'customer'];
  
  const content = doc.pageContent.toLowerCase();
  
  if (technicalKeywords.some(kw => content.includes(kw.toLowerCase()))) {
    return 'technical';
  } else if (marketingKeywords.some(kw => content.includes(kw.toLowerCase()))) {
    return 'marketing';
  }
  return 'support';
};

// Multi-store retrieval
const retrieveFromMultipleSources = async (query, stores) => {
  const results = await Promise.all(
    stores.map(store => store.similaritySearch(query, 3))
  );
  
  // Flatten and deduplicate
  const allDocs = results.flat();
  const unique = Array.from(new Map(
    allDocs.map(doc => [doc.pageContent, doc])
  ).values());
  
  return unique;
};
```

### Conversational Analytics Agent

**Scenario**: Natural language interface to business analytics

**Components**:

1. SQL Database Connection
2. SQL Agent
3. Chart Generation Tool
4. Chat Model
5. Memory

**Implementation**:

```javascript
// SQL Agent Configuration
const sqlAgentConfig = {
  database: {
    type: "postgres",
    host: "localhost",
    database: "analytics_db",
    user: "analyst",
    password: process.env.DB_PASSWORD
  },
  includeTableNames: ["sales", "customers", "products"],
  systemPrompt: `You are a data analyst assistant. 
  You can query the database and create visualizations.
  Always explain your analysis in business terms.`
};

// Custom Chart Tool
const chartTool = {
  name: "create_chart",
  description: "Create a chart from data",
  func: async (data, chartType) => {
    // Generate chart URL or base64
    const chartUrl = await generateChart(data, chartType);
    return chartUrl;
  }
};
```

**Example Interaction**:

```text
User: "Show me top 5 products by revenue this month"

Agent:
1. Generates SQL: SELECT product_name, SUM(revenue) FROM sales 
                  WHERE month = CURRENT_MONTH GROUP BY product_name 
                  ORDER BY SUM(revenue) DESC LIMIT 5
2. Executes query
3. Creates bar chart
4. Responds: "Here are the top 5 products by revenue this month:
             [Chart] Product A: $50k, Product B: $45k..."
```

## Advanced Features

### Custom Tools

Create custom tools for agents:

```javascript
const customTool = {
  name: "weather_api",
  description: "Get current weather for a location",
  func: async (location) => {
    const response = await fetch(`https://api.weather.com/${location}`);
    return await response.json();
  }
};
```

### Embeddings Caching

Enable caching to reduce API calls and costs:

- Configure cache settings in vector store
- Use Redis or in-memory cache
- Set TTL for cached embeddings

### Streaming Responses

Enable real-time streaming for better UX:

- Toggle streaming in chat model settings
- Implement in frontend with Server-Sent Events
- Handle partial responses appropriately

### Authentication

Secure your chatflows:

- Enable username/password authentication
- Configure API key requirements
- Implement rate limiting
- Add CORS restrictions

## API Usage

### Generated API Endpoint

Each chatflow gets an API endpoint:

```bash
curl -X POST http://localhost:3000/api/v1/prediction/chatflow-id \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is the capital of France?"
  }'
```

### Streaming API

Get streaming responses:

```bash
curl -X POST http://localhost:3000/api/v1/prediction/chatflow-id \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{
    "question": "Tell me a story"
  }'
```

### With Authentication

Include API key in requests:

```bash
curl -X POST http://localhost:3000/api/v1/prediction/chatflow-id \
  -H "Authorization: Bearer your-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Your query"
  }'
```

## Embedding Chat Widget

### Basic Embed

```html
<script type="module">
  import Chatbot from "https://cdn.jsdelivr.net/npm/flowise-embed/dist/web.js"
  Chatbot.init({
    chatflowid: "your-chatflow-id",
    apiHost: "http://localhost:3000",
  })
</script>
```

### React Integration

```javascript
import { BubbleChat } from 'flowise-embed-react';

function App() {
  return (
    <BubbleChat
      chatflowid="your-chatflow-id"
      apiHost="http://localhost:3000"
      theme={{
        button: { backgroundColor: "#3B81F6" },
        chatWindow: { welcomeMessage: "Hello!" }
      }}
    />
  );
}
```

## Use Cases

### Customer Support Bot

Build intelligent support chatbots with knowledge base integration.

### Document Analysis

Create systems for analyzing and querying document collections.

### Research Assistant

Develop tools that help with information gathering and synthesis.

### Code Assistant

Build coding helpers with access to documentation and examples.

### Personal Knowledge Base

Create AI assistants for personal note and document management.

## Best Practices

### Performance Optimization

- **Chunking Strategy**: Optimize text splitting for your use case
- **Embedding Caching**: Cache embeddings to reduce costs
- **Vector Store Selection**: Choose appropriate database for scale
- **Model Selection**: Use smallest effective model

### Cost Management

- **Token Optimization**: Craft efficient prompts
- **Caching**: Implement aggressive caching strategies
- **Model Tiers**: Use GPT-3.5 for simple tasks, GPT-4 for complex
- **Batch Processing**: Group similar operations

### Security

- **API Key Security**: Store keys securely
- **Authentication**: Enable auth for production
- **Input Validation**: Sanitize user inputs
- **Rate Limiting**: Prevent abuse
- **HTTPS**: Use SSL in production

### Testing

- **Test Flows**: Use built-in chat interface
- **Edge Cases**: Test with unusual inputs
- **Performance**: Monitor response times
- **Accuracy**: Validate outputs against expectations

## Deployment

### Local Development

Run Flowise locally for development:

```bash
npm start
```

### Production Deployment

#### Docker Deployment

```bash
docker run -d \
  -p 3000:3000 \
  -v ~/.flowise:/root/.flowise \
  -e FLOWISE_USERNAME=admin \
  -e FLOWISE_PASSWORD=secure-password \
  flowiseai/flowise
```

#### Cloud Platforms

- **Railway**: One-click deploy
- **Render**: Container deployment
- **Digital Ocean**: App Platform
- **AWS**: ECS or EC2
- **Azure**: Container Instances

### Environment Variables

```bash
# Authentication
FLOWISE_USERNAME=admin
FLOWISE_PASSWORD=your-password

# Database
DATABASE_PATH=/path/to/database.sqlite

# API Configuration
CORS_ORIGINS=https://yourdomain.com
APIKEY_PATH=/path/to/apikeys

# Model Defaults
OPENAI_API_KEY=sk-...
```

## Comparison with Other Tools

| Feature | Flowise | LangFlow | n8n | Zapier |
| --- | --- | --- | --- | --- |
| Primary Focus | LLM Apps | LLM Apps | General | General |
| Language | JavaScript | Python | JavaScript | N/A |
| Open Source | Yes | Yes | Yes | No |
| Self-Hosted | Yes | Yes | Yes | No |
| Chat Widget | Built-in | No | No | No |
| Ease of Use | High | High | Medium | High |
| LLM Focus | Excellent | Excellent | Good | Good |

## Troubleshooting

### Common Issues

#### Connection Errors

- Verify API keys are correct
- Check network connectivity
- Ensure correct API endpoints

#### Memory Issues

- Large documents may require chunking
- Consider upgrading system resources
- Use efficient embedding models

#### Performance Problems

- Enable caching mechanisms
- Optimize chunk sizes
- Use faster vector databases
- Consider model selection

### Debugging

- Check browser console for errors
- Review Flowise server logs
- Test components individually
- Verify API responses

## Community and Resources

### Official Resources

- [GitHub Repository](https://github.com/FlowiseAI/Flowise)
- [Documentation](https://docs.flowiseai.com/)
- [Discord Community](https://discord.gg/jbaHfsRVBW)

### Learning Materials

- Video tutorials
- Community templates
- Example projects
- Blog articles

## Updates and Roadmap

Flowise is actively developed with regular updates:

- New LLM integrations
- Enhanced component library
- Improved performance
- Better debugging tools
- Enterprise features

## Related Topics

- [LangFlow](langflow.md) - Python-based LangChain visual builder
- [Make (Integromat)](make.md) - General workflow automation platform
- [n8n](n8n.md) - Open-source workflow automation tool
- [Workflow Design Patterns](workflow-patterns.md) - Comprehensive workflow patterns
- [Integration Best Practices](best-practices.md) - Integration guidance and standards
- [Prompt Engineering](prompt-engineering.md) - Effective prompt design techniques
- [Vector Databases](vector-databases.md) - Embedding storage solutions

## Advanced Topics

### Production Deployment Architecture

#### Docker Compose with PostgreSQL

```yaml
version: '3.8'

services:
  flowise:
    image: flowiseai/flowise:latest
    restart: always
    ports:
      - "3000:3000"
    environment:
      - DATABASE_TYPE=postgres
      - DATABASE_HOST=postgres
      - DATABASE_PORT=5432
      - DATABASE_USER=flowise
      - DATABASE_PASSWORD=${DB_PASSWORD}
      - DATABASE_NAME=flowise
      - FLOWISE_USERNAME=${ADMIN_USER}
      - FLOWISE_PASSWORD=${ADMIN_PASSWORD}
      - FLOWISE_SECRETKEY_OVERWRITE=${SECRET_KEY}
      - CORS_ORIGINS=https://yourdomain.com
      - TOOL_FUNCTION_BUILTIN_DEP=crypto,fs,path
      - TOOL_FUNCTION_EXTERNAL_DEP=axios,cheerio
    volumes:
      - flowise_data:/root/.flowise
    depends_on:
      - postgres
    networks:
      - flowise_network

  postgres:
    image: postgres:15
    restart: always
    environment:
      - POSTGRES_DB=flowise
      - POSTGRES_USER=flowise
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - flowise_network

  nginx:
    image: nginx:alpine
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - flowise
    networks:
      - flowise_network

volumes:
  flowise_data:
  postgres_data:

networks:
  flowise_network:
    driver: bridge
```

#### Nginx Configuration

```nginx
upstream flowise {
    server flowise:3000;
}

server {
    listen 80;
    server_name yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com;

    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    location / {
        proxy_pass http://flowise;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts for long-running LLM requests
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }
}
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flowise
  labels:
    app: flowise
spec:
  replicas: 2
  selector:
    matchLabels:
      app: flowise
  template:
    metadata:
      labels:
        app: flowise
    spec:
      containers:
      - name: flowise
        image: flowiseai/flowise:latest
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_TYPE
          value: "postgres"
        - name: DATABASE_HOST
          valueFrom:
            secretKeyRef:
              name: flowise-secrets
              key: db-host
        - name: FLOWISE_USERNAME
          valueFrom:
            secretKeyRef:
              name: flowise-secrets
              key: admin-username
        - name: FLOWISE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: flowise-secrets
              key: admin-password
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "2000m"
        livenessProbe:
          httpGet:
            path: /api/v1/health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/v1/health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: flowise-service
spec:
  selector:
    app: flowise
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: LoadBalancer
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: flowise-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: flowise
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Monitoring and Observability

#### Custom Monitoring Setup

```javascript
// middleware/monitoring.js
const prometheus = require('prom-client');

// Create metrics
const httpRequestDuration = new prometheus.Histogram({
  name: 'flowise_http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status']
});

const chatflowExecutions = new prometheus.Counter({
  name: 'flowise_chatflow_executions_total',
  help: 'Total number of chatflow executions',
  labelNames: ['chatflow_id', 'status']
});

const llmTokenUsage = new prometheus.Counter({
  name: 'flowise_llm_tokens_total',
  help: 'Total LLM tokens used',
  labelNames: ['model', 'type']
});

// Middleware to track metrics
const monitoringMiddleware = (req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .observe(duration);
  });
  
  next();
};

module.exports = {
  monitoringMiddleware,
  chatflowExecutions,
  llmTokenUsage,
  metricsEndpoint: prometheus.register.metrics()
};
```

#### Grafana Dashboard Configuration

```json
{
  "dashboard": {
    "title": "Flowise Monitoring",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(flowise_http_request_duration_seconds_count[5m])"
          }
        ]
      },
      {
        "title": "Average Response Time",
        "targets": [
          {
            "expr": "rate(flowise_http_request_duration_seconds_sum[5m]) / rate(flowise_http_request_duration_seconds_count[5m])"
          }
        ]
      },
      {
        "title": "Chatflow Execution Success Rate",
        "targets": [
          {
            "expr": "rate(flowise_chatflow_executions_total{status=\"success\"}[5m]) / rate(flowise_chatflow_executions_total[5m])"
          }
        ]
      },
      {
        "title": "LLM Token Usage",
        "targets": [
          {
            "expr": "rate(flowise_llm_tokens_total[5m])"
          }
        ]
      }
    ]
  }
}
```

### Advanced Custom Tools

#### Web Scraping Tool

```javascript
const cheerio = require('cheerio');
const axios = require('axios');

const webScrapingTool = {
  name: "advanced_web_scraper",
  description: "Scrape and extract structured data from websites",
  schema: {
    type: "object",
    properties: {
      url: { type: "string", description: "URL to scrape" },
      selectors: { 
        type: "object",
        description: "CSS selectors for data extraction"
      }
    },
    required: ["url"]
  },
  func: async (input) => {
    try {
      const response = await axios.get(input.url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; FlowiseBot/1.0)'
        },
        timeout: 10000
      });
      
      const $ = cheerio.load(response.data);
      const data = {};
      
      if (input.selectors) {
        for (const [key, selector] of Object.entries(input.selectors)) {
          data[key] = [];
          $(selector).each((i, elem) => {
            data[key].push($(elem).text().trim());
          });
        }
      } else {
        // Default: extract main content
        data.title = $('h1').first().text().trim();
        data.paragraphs = [];
        $('p').each((i, elem) => {
          data.paragraphs.push($(elem).text().trim());
        });
      }
      
      return JSON.stringify(data, null, 2);
    } catch (error) {
      return `Error scraping ${input.url}: ${error.message}`;
    }
  }
};
```

#### Database Query Tool

```javascript
const { Pool } = require('pg');

class DatabaseQueryTool {
  constructor(config) {
    this.pool = new Pool(config);
  }
  
  getTool() {
    return {
      name: "database_query",
      description: "Execute read-only SQL queries against the database",
      schema: {
        type: "object",
        properties: {
          query: {
            type: "string",
            description: "SQL SELECT query to execute"
          }
        },
        required: ["query"]
      },
      func: async (input) => {
        // Security: Only allow SELECT queries
        if (!input.query.trim().toLowerCase().startsWith('select')) {
          return "Error: Only SELECT queries are allowed";
        }
        
        try {
          // Add timeout and row limit
          const safeQuery = `
            SET statement_timeout = 5000;
            ${input.query}
            LIMIT 100
          `;
          
          const result = await this.pool.query(safeQuery);
          
          return JSON.stringify({
            rows: result.rows,
            rowCount: result.rowCount,
            fields: result.fields.map(f => f.name)
          }, null, 2);
        } catch (error) {
          return `Database error: ${error.message}`;
        }
      }
    };
  }
}

// Usage
const dbTool = new DatabaseQueryTool({
  host: 'localhost',
  database: 'analytics',
  user: 'readonly_user',
  password: process.env.DB_PASSWORD,
  max: 10,
  idleTimeoutMillis: 30000
});
```

#### Email Integration Tool

```javascript
const nodemailer = require('nodemailer');

const emailTool = {
  name: "send_email",
  description: "Send email notifications",
  schema: {
    type: "object",
    properties: {
      to: { type: "string", description: "Recipient email" },
      subject: { type: "string", description: "Email subject" },
      body: { type: "string", description: "Email body" }
    },
    required: ["to", "subject", "body"]
  },
  func: async (input) => {
    const transporter = nodemailer.createTransporter({
      host: process.env.SMTP_HOST,
      port: process.env.SMTP_PORT,
      secure: true,
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASSWORD
      }
    });
    
    try {
      const info = await transporter.sendMail({
        from: process.env.SMTP_FROM,
        to: input.to,
        subject: input.subject,
        text: input.body,
        html: `<pre>${input.body}</pre>`
      });
      
      return `Email sent successfully. Message ID: ${info.messageId}`;
    } catch (error) {
      return `Failed to send email: ${error.message}`;
    }
  }
};
```

### Performance Optimization Techniques

#### Caching Strategy Implementation

```javascript
const Redis = require('ioredis');
const redis = new Redis(process.env.REDIS_URL);

class CachingStrategy {
  constructor() {
    this.defaultTTL = 3600; // 1 hour
  }
  
  async cacheEmbedding(text, embedding, model) {
    const key = `embedding:${model}:${this.hashText(text)}`;
    await redis.setex(key, 86400, JSON.stringify(embedding)); // 24h TTL
  }
  
  async getCachedEmbedding(text, model) {
    const key = `embedding:${model}:${this.hashText(text)}`;
    const cached = await redis.get(key);
    return cached ? JSON.parse(cached) : null;
  }
  
  async cacheResponse(query, response, chatflowId) {
    const key = `response:${chatflowId}:${this.hashText(query)}`;
    await redis.setex(key, this.defaultTTL, JSON.stringify(response));
  }
  
  async getCachedResponse(query, chatflowId) {
    const key = `response:${chatflowId}:${this.hashText(query)}`;
    const cached = await redis.get(key);
    return cached ? JSON.parse(cached) : null;
  }
  
  hashText(text) {
    const crypto = require('crypto');
    return crypto.createHash('sha256').update(text).digest('hex');
  }
  
  async invalidateCache(pattern) {
    const keys = await redis.keys(pattern);
    if (keys.length > 0) {
      await redis.del(...keys);
    }
  }
}

// Usage in chatflow
const cache = new CachingStrategy();

async function executeWithCache(chatflowId, query) {
  // Check cache first
  const cached = await cache.getCachedResponse(query, chatflowId);
  if (cached) {
    return { ...cached, fromCache: true };
  }
  
  // Execute chatflow
  const response = await executeChatflow(chatflowId, query);
  
  // Cache response
  await cache.cacheResponse(query, response, chatflowId);
  
  return { ...response, fromCache: false };
}
```

#### Batch Processing Implementation

```javascript
class BatchProcessor {
  constructor(batchSize = 10, maxWaitMs = 1000) {
    this.batchSize = batchSize;
    this.maxWaitMs = maxWaitMs;
    this.queue = [];
    this.timer = null;
  }
  
  async addToQueue(item) {
    return new Promise((resolve, reject) => {
      this.queue.push({ item, resolve, reject });
      
      if (this.queue.length >= this.batchSize) {
        this.processBatch();
      } else if (!this.timer) {
        this.timer = setTimeout(() => this.processBatch(), this.maxWaitMs);
      }
    });
  }
  
  async processBatch() {
    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }
    
    if (this.queue.length === 0) return;
    
    const batch = this.queue.splice(0, this.batchSize);
    const items = batch.map(b => b.item);
    
    try {
      // Process batch (e.g., batch embedding generation)
      const results = await this.batchProcess(items);
      
      // Resolve promises
      batch.forEach((b, i) => b.resolve(results[i]));
    } catch (error) {
      // Reject all promises in batch
      batch.forEach(b => b.reject(error));
    }
  }
  
  async batchProcess(items) {
    // Implement batch processing logic
    // For embeddings:
    const embeddings = await openai.createEmbedding({
      model: "text-embedding-ada-002",
      input: items
    });
    return embeddings.data.data.map(e => e.embedding);
  }
}

// Usage
const batchProcessor = new BatchProcessor(20, 500);

async function getEmbedding(text) {
  return await batchProcessor.addToQueue(text);
}
```

### Security Best Practices

#### Input Sanitization

```javascript
const DOMPurify = require('isomorphic-dompurify');
const validator = require('validator');

class InputSanitizer {
  sanitizeUserInput(input) {
    if (typeof input !== 'string') {
      input = String(input);
    }
    
    // Remove HTML tags
    input = DOMPurify.sanitize(input, { ALLOWED_TAGS: [] });
    
    // Trim whitespace
    input = input.trim();
    
    // Normalize unicode
    input = input.normalize('NFKC');
    
    // Remove control characters
    input = input.replace(/[\x00-\x1F\x7F]/g, '');
    
    return input;
  }
  
  validateEmail(email) {
    return validator.isEmail(email);
  }
  
  validateURL(url) {
    return validator.isURL(url, {
      protocols: ['http', 'https'],
      require_protocol: true
    });
  }
  
  detectInjectionAttempt(input) {
    const dangerousPatterns = [
      /<script/i,
      /javascript:/i,
      /on\w+\s*=/i,
      /eval\(/i,
      /__import__/,
      /exec\(/i
    ];
    
    return dangerousPatterns.some(pattern => pattern.test(input));
  }
}

// Middleware
const sanitizer = new InputSanitizer();

function sanitizationMiddleware(req, res, next) {
  if (req.body) {
    for (const key in req.body) {
      if (typeof req.body[key] === 'string') {
        if (sanitizer.detectInjectionAttempt(req.body[key])) {
          return res.status(400).json({ error: 'Invalid input detected' });
        }
        req.body[key] = sanitizer.sanitizeUserInput(req.body[key]);
      }
    }
  }
  next();
}
```

#### Rate Limiting

```javascript
const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');

// API rate limiter
const apiLimiter = rateLimit({
  store: new RedisStore({
    client: redis,
    prefix: 'rl:api:'
  }),
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per window
  message: 'Too many requests, please try again later',
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(429).json({
      error: 'Rate limit exceeded',
      retryAfter: req.rateLimit.resetTime
    });
  }
});

// Chatflow execution limiter (more strict)
const chatflowLimiter = rateLimit({
  store: new RedisStore({
    client: redis,
    prefix: 'rl:chatflow:'
  }),
  windowMs: 60 * 1000, // 1 minute
  max: 10, // 10 executions per minute
  message: 'Chatflow execution limit exceeded'
});

// Apply to routes
app.use('/api/', apiLimiter);
app.use('/api/v1/prediction/', chatflowLimiter);
```

## Troubleshooting Guide

### Common Issues and Solutions

#### Issue 1: Out of Memory Errors

**Symptoms**:

- Container crashes
- "JavaScript heap out of memory" errors
- Slow performance with large documents

**Solutions**:

```bash
# Increase Node.js memory limit
NODE_OPTIONS="--max-old-space-size=4096" npx flowise start

# In Docker
docker run -e NODE_OPTIONS="--max-old-space-size=4096" flowiseai/flowise
```

```javascript
// Optimize chunking strategy
const textSplitter = new RecursiveCharacterTextSplitter({
  chunkSize: 500, // Smaller chunks
  chunkOverlap: 50,
  lengthFunction: (text) => text.length
});
```

#### Issue 2: Slow Vector Search

**Symptoms**:

- High latency on queries
- Timeout errors
- Poor user experience

**Solutions**:

```javascript
// 1. Optimize index configuration
const pineconeIndex = {
  dimension: 1536,
  metric: 'cosine',
  pods: 1,
  pod_type: 'p1.x1' // Upgrade pod type
};

// 2. Implement query optimization
const optimizedRetriever = vectorStore.asRetriever({
  searchType: 'mmr', // Maximum marginal relevance
  searchKwargs: {
    k: 5,
    fetchK: 20, // Fetch more, then rerank
    lambda: 0.5 // Diversity parameter
  }
});

// 3. Add pre-filtering
const filteredRetriever = vectorStore.asRetriever({
  filter: {
    category: { $eq: 'technical' },
    date: { $gte: '2024-01-01' }
  }
});
```

#### Issue 3: API Rate Limit Errors

**Symptoms**:

- 429 Too Many Requests errors
- Intermittent failures
- Cost concerns

**Solutions**:

```javascript
// Implement exponential backoff
async function withRetry(fn, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (error.status === 429 && i < maxRetries - 1) {
        const delay = Math.pow(2, i) * 1000;
        await new Promise(resolve => setTimeout(resolve, delay));
        continue;
      }
      throw error;
    }
  }
}

// Use queue for rate limiting
const Queue = require('bull');
const llmQueue = new Queue('llm-requests', process.env.REDIS_URL);

llmQueue.process(async (job) => {
  return await callLLM(job.data);
});

// Add job to queue instead of direct call
await llmQueue.add({ prompt: userQuery }, {
  attempts: 3,
  backoff: {
    type: 'exponential',
    delay: 2000
  }
});
```

#### Issue 4: Inconsistent Responses

**Symptoms**:

- Different answers to same question
- Quality varies
- Unpredictable behavior

**Solutions**:

```javascript
// 1. Lower temperature for consistency
const consistentLLM = new ChatOpenAI({
  temperature: 0.1, // More deterministic
  modelName: "gpt-4"
});

// 2. Use seed parameter (if available)
const llmWithSeed = new ChatOpenAI({
  temperature: 0.7,
  seed: 42 // Reproducible results
});

// 3. Implement caching
const cachedResponse = await cache.getCachedResponse(query, chatflowId);

// 4. Use ensemble method
async function ensemblePredict(query) {
  const responses = await Promise.all([
    llm1.predict(query),
    llm2.predict(query),
    llm3.predict(query)
  ]);
  
  // Return most common or use voting mechanism
  return selectBestResponse(responses);
}
```

## Next Steps

### For Beginners

1. **Week 1**: Install Flowise and explore the interface
2. **Week 2**: Build simple chatbot with memory
3. **Week 3**: Create RAG system with your documents
4. **Week 4**: Experiment with agents and tools
5. **Week 5**: Deploy first chatbot widget

### For Intermediate Users

1. **Month 1**: Build production RAG system
2. **Month 2**: Implement custom tools and APIs
3. **Month 3**: Add authentication and monitoring
4. **Month 4**: Optimize performance and costs
5. **Month 5**: Scale with Kubernetes

### For Advanced Users

1. **Quarter 1**: Multi-agent systems
2. **Quarter 2**: Custom component development
3. **Quarter 3**: Enterprise integration patterns
4. **Quarter 4**: Advanced monitoring and optimization

## Conclusion

Flowise democratizes LLM application development by providing an intuitive visual interface backed by the powerful LangChain framework. Whether you're building simple chatbots or complex multi-agent systems, Flowise offers the tools and flexibility needed for modern AI applications.

### Key Takeaways

- **Start Simple**: Begin with pre-built templates and gradually add complexity
- **Leverage Components**: Use extensive library before building custom solutions
- **Monitor Everything**: Implement comprehensive logging and metrics from day one
- **Optimize Early**: Enable caching and batch processing for production
- **Security First**: Sanitize inputs, secure API keys, implement rate limiting
- **Scale Thoughtfully**: Use proper infrastructure for production deployments

### Success Factors

1. **Clear Requirements**: Define use case and success metrics upfront
2. **Iterative Development**: Build MVP, test, iterate based on feedback
3. **Performance Testing**: Load test before production deployment
4. **User Feedback**: Continuously gather and act on user input
5. **Stay Updated**: Follow Flowise releases for new features and improvements

### Community Resources

- Join Discord for support and best practices
- Contribute to GitHub with improvements and bug fixes
- Share your chatflows in the community marketplace
- Write blog posts about your experiences
- Attend community events and webinars

---

*Last Updated: January 4, 2026*
*Comprehensive guide to building, deploying, and optimizing Flowise applications in production environments.*
