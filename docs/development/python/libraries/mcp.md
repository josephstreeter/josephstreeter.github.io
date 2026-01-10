---
title: Model Context Protocol (MCP) - Universal AI Integration Standard
description: Comprehensive guide to MCP, the open protocol for connecting AI assistants to data sources, tools, and context providers with standardized server-client architecture
---

The Model Context Protocol (MCP) is an open standard that enables seamless integration between AI applications and external data sources. Developed by Anthropic, MCP provides a universal protocol for AI systems to securely access context, tools, and resources through a standardized server-client architecture.

## Overview

MCP revolutionizes how AI applications interact with the world by providing a standardized, secure protocol for context exchange. Instead of building custom integrations for every data source, developers can implement MCP servers that expose resources, prompts, and tools to any MCP-compatible client. This architectural pattern decouples AI applications from data sources, enabling unprecedented flexibility and reusability.

### The Problem MCP Solves

Traditional AI integrations face several challenges:

- **Fragmentation**: Each AI assistant requires custom integrations for every data source
- **Maintenance Burden**: Updates to data sources break multiple integrations
- **Security Risks**: Direct database access and credential management in AI applications
- **Limited Context**: AI systems struggle to access relevant, real-time information
- **Vendor Lock-in**: Integrations tied to specific AI platforms

### The MCP Solution

MCP addresses these challenges through:

- **Universal Protocol**: Single standard for all AI-to-context connections
- **Server Architecture**: Data sources expose capabilities through MCP servers
- **Security Model**: Granular permissions and isolated execution contexts
- **Extensibility**: Support for custom tools, prompts, and resource types
- **Transport Flexibility**: Works over stdio, HTTP/SSE, and custom transports

## Installation

### Core Package

The MCP Python SDK provides both server and client implementations:

```bash
# Install core MCP package
pip install mcp

# Install with CLI tools
pip install mcp[cli]

# Install with all optional dependencies
pip install mcp[all]
```

### Using UV (Recommended)

For faster installation with UV:

```bash
# Install core package
uv pip install mcp

# Install with CLI tools
uv pip install "mcp[cli]"

# Create MCP project with virtual environment
uv venv
uv pip install "mcp[cli]"
```

### Development Installation

For development with testing and documentation tools:

```bash
# Clone the repository
git clone https://github.com/anthropics/anthropic-sdk-python.git
cd anthropic-sdk-python/mcp

# Install in editable mode
pip install -e ".[dev]"
```

### Verify Installation

```bash
# Check MCP version
python -c "import mcp; print(mcp.__version__)"

# Verify CLI tools (if installed)
mcp --version
```

### System Requirements

- **Python**: 3.10 or higher
- **Operating Systems**: Linux, macOS, Windows
- **Dependencies**: aiohttp, pydantic, httpx

## Basic Usage

### Creating an MCP Server

Here's a minimal MCP server that exposes a simple resource:

```python
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Resource, TextContent
import asyncio

# Create server instance
app = Server("my-server")

@app.list_resources()
async def list_resources() -> list[Resource]:
    """List available resources."""
    return [
        Resource(
            uri="memo://greeting",
            name="Greeting Message",
            mimeType="text/plain",
            description="A simple greeting"
        )
    ]

@app.read_resource()
async def read_resource(uri: str) -> str:
    """Read resource content."""
    if uri == "memo://greeting":
        return "Hello from MCP!"
    raise ValueError(f"Unknown resource: {uri}")

async def main():
    """Run the server."""
    async with stdio_server() as (read_stream, write_stream):
        await app.run(
            read_stream,
            write_stream,
            app.create_initialization_options()
        )

if __name__ == "__main__":
    asyncio.run(main())
```

### Creating an MCP Client

Connect to an MCP server and access resources:

```python
from mcp.client import Client
from mcp.client.stdio import stdio_client
import asyncio

async def main():
    """Connect to MCP server and read resources."""
    async with stdio_client("python", ["server.py"]) as (read, write):
        async with Client(read, write) as client:
            # Initialize connection
            await client.initialize()
            
            # List available resources
            resources = await client.list_resources()
            print(f"Available resources: {resources}")
            
            # Read a resource
            content = await client.read_resource("memo://greeting")
            print(f"Resource content: {content}")

if __name__ == "__main__":
    asyncio.run(main())
```

### Server with Tools

Expose executable functions to the AI:

```python
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent
import asyncio

app = Server("calculator-server")

@app.list_tools()
async def list_tools() -> list[Tool]:
    """List available tools."""
    return [
        Tool(
            name="add",
            description="Add two numbers",
            inputSchema={
                "type": "object",
                "properties": {
                    "a": {"type": "number"},
                    "b": {"type": "number"}
                },
                "required": ["a", "b"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    """Execute tool."""
    if name == "add":
        result = arguments["a"] + arguments["b"]
        return [TextContent(
            type="text",
            text=f"Result: {result}"
        )]
    raise ValueError(f"Unknown tool: {name}")

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await app.run(
            read_stream,
            write_stream,
            app.create_initialization_options()
        )

if __name__ == "__main__":
    asyncio.run(main())
```

## Architecture

### Core Components

MCP architecture consists of three primary components:

1. **MCP Hosts**: AI applications (like Claude Desktop) that initiate connections
2. **MCP Clients**: Protocol clients within hosts that maintain server connections
3. **MCP Servers**: Lightweight programs exposing resources, prompts, and tools

```text
┌─────────────────┐
│   MCP Host      │
│  (Claude App)   │
│                 │
│  ┌───────────┐  │
│  │MCP Client │  │
│  └─────┬─────┘  │
└────────┼────────┘
         │ MCP Protocol
         │ (stdio/HTTP)
┌────────┼────────┐
│  ┌─────┴─────┐  │
│  │MCP Server │  │
│  └───────────┘  │
│                 │
│  Your Data/APIs │
└─────────────────┘
```

### Protocol Features

- **Asynchronous**: Built on Python asyncio for non-blocking operations
- **Type-Safe**: Full Pydantic models for request/response validation
- **Bidirectional**: Clients and servers can both send requests
- **Transport Agnostic**: Works over stdio, HTTP with SSE, or custom transports
- **Versioned**: Protocol negotiation ensures compatibility

## Key Features

### Resources

Resources represent any data that should be available to the AI:

- **File Systems**: Expose files and directories
- **Databases**: Query results, table schemas, live data
- **APIs**: External service data, real-time information
- **Documents**: PDFs, markdown, structured data
- **Dynamic Content**: Generated or computed on-demand

```python
# Resource structure
{
    "uri": "file:///path/to/document.txt",
    "name": "Project Documentation",
    "mimeType": "text/plain",
    "description": "Main project documentation"
}
```

### Prompts

Prompt templates with variable substitution:

- **Reusable Templates**: Standardized prompts for common tasks
- **Variable Injection**: Dynamic prompts with user-provided values
- **Multi-turn Conversations**: Complex interaction patterns
- **Context Integration**: Combine prompts with resources
- **Discoverability**: Clients can list available prompts

```python
# Prompt structure
{
    "name": "analyze-code",
    "description": "Analyze code for issues",
    "arguments": [
        {
            "name": "language",
            "description": "Programming language",
            "required": True
        }
    ]
}
```

### Tools

Functions that AI can invoke to perform actions:

- **Function Execution**: Call Python functions from AI
- **API Integration**: External service interactions
- **Data Manipulation**: Transform or process data
- **Side Effects**: Write files, update databases
- **Error Handling**: Structured error responses

```python
# Tool structure
{
    "name": "calculate",
    "description": "Perform mathematical calculations",
    "inputSchema": {
        "type": "object",
        "properties": {
            "expression": {
                "type": "string",
                "description": "Math expression to evaluate"
            }
        },
        "required": ["expression"]
    }
}
```

### Sampling

Servers can request AI completions from the host:

- **Delegation**: Servers can request AI assistance
- **Agentic Workflows**: Build autonomous agent loops
- **Context Preservation**: Maintain conversation history
- **Model Selection**: Specify preferred models
- **Streaming**: Real-time response generation

## Advanced Features

### Dynamic Resources

Create resources that update in real-time:

```python
from mcp.server import Server
from mcp.types import Resource
import asyncio
from datetime import datetime

app = Server("dynamic-server")

@app.list_resources()
async def list_resources() -> list[Resource]:
    """List dynamically updated resources."""
    return [
        Resource(
            uri="dynamic://time",
            name="Current Time",
            mimeType="text/plain",
            description="Real-time clock"
        )
    ]

@app.read_resource()
async def read_resource(uri: str) -> str:
    """Return current time."""
    if uri == "dynamic://time":
        return f"Current time: {datetime.now().isoformat()}"
    raise ValueError(f"Unknown resource: {uri}")
```

### Database Integration

Expose database queries as resources:

```python
from mcp.server import Server
from mcp.types import Resource, TextContent
import asyncio
import sqlite3
import json

app = Server("database-server")

def get_db_connection():
    """Create database connection."""
    return sqlite3.connect("data.db")

@app.list_resources()
async def list_resources() -> list[Resource]:
    """List database tables as resources."""
    conn = get_db_connection()
    cursor = conn.execute(
        "SELECT name FROM sqlite_master WHERE type='table'"
    )
    tables = cursor.fetchall()
    conn.close()
    
    return [
        Resource(
            uri=f"db://table/{table[0]}",
            name=f"Table: {table[0]}",
            mimeType="application/json",
            description=f"Data from {table[0]} table"
        )
        for table in tables
    ]

@app.read_resource()
async def read_resource(uri: str) -> str:
    """Query table data."""
    if uri.startswith("db://table/"):
        table_name = uri.split("/")[-1]
        conn = get_db_connection()
        cursor = conn.execute(f"SELECT * FROM {table_name} LIMIT 100")
        rows = cursor.fetchall()
        columns = [desc[0] for desc in cursor.description]
        conn.close()
        
        # Convert to JSON
        data = [dict(zip(columns, row)) for row in rows]
        return json.dumps(data, indent=2)
    
    raise ValueError(f"Unknown resource: {uri}")
```

### File System Server

Expose file system as MCP resources:

```python
from mcp.server import Server
from mcp.types import Resource
import asyncio
from pathlib import Path

app = Server("filesystem-server")

BASE_PATH = Path("./documents")

@app.list_resources()
async def list_resources() -> list[Resource]:
    """List all files in directory."""
    resources = []
    for file_path in BASE_PATH.rglob("*"):
        if file_path.is_file():
            resources.append(
                Resource(
                    uri=f"file://{file_path}",
                    name=file_path.name,
                    mimeType=get_mime_type(file_path),
                    description=f"File: {file_path.relative_to(BASE_PATH)}"
                )
            )
    return resources

@app.read_resource()
async def read_resource(uri: str) -> str:
    """Read file contents."""
    if uri.startswith("file://"):
        file_path = Path(uri[7:])
        if file_path.exists() and file_path.is_relative_to(BASE_PATH):
            return file_path.read_text()
    raise ValueError(f"Cannot read resource: {uri}")

def get_mime_type(path: Path) -> str:
    """Determine MIME type from extension."""
    mime_types = {
        ".txt": "text/plain",
        ".md": "text/markdown",
        ".json": "application/json",
        ".py": "text/x-python"
    }
    return mime_types.get(path.suffix, "text/plain")
```

### Prompt Templates

Create reusable prompt templates:

```python
from mcp.server import Server
from mcp.types import Prompt, PromptArgument, PromptMessage
import asyncio

app = Server("prompt-server")

@app.list_prompts()
async def list_prompts() -> list[Prompt]:
    """List available prompt templates."""
    return [
        Prompt(
            name="code-review",
            description="Review code for best practices",
            arguments=[
                PromptArgument(
                    name="language",
                    description="Programming language",
                    required=True
                ),
                PromptArgument(
                    name="code",
                    description="Code to review",
                    required=True
                )
            ]
        ),
        Prompt(
            name="summarize-doc",
            description="Summarize a document",
            arguments=[
                PromptArgument(
                    name="document",
                    description="Document to summarize",
                    required=True
                ),
                PromptArgument(
                    name="length",
                    description="Summary length (short/medium/long)",
                    required=False
                )
            ]
        )
    ]

@app.get_prompt()
async def get_prompt(name: str, arguments: dict) -> list[PromptMessage]:
    """Generate prompt from template."""
    if name == "code-review":
        language = arguments["language"]
        code = arguments["code"]
        return [
            PromptMessage(
                role="user",
                content=f"""Review this {language} code for:
- Best practices
- Potential bugs
- Performance issues
- Security concerns

Code:
{code}

Provide detailed feedback with specific recommendations."""
            )
        ]
    
    if name == "summarize-doc":
        document = arguments["document"]
        length = arguments.get("length", "medium")
        length_guide = {
            "short": "in 2-3 sentences",
            "medium": "in 1-2 paragraphs",
            "long": "in 3-4 paragraphs with key details"
        }
        return [
            PromptMessage(
                role="user",
                content=f"""Summarize the following document {length_guide[length]}:

{document}"""
            )
        ]
    
    raise ValueError(f"Unknown prompt: {name}")
```

### Tool Validation and Error Handling

Implement robust tool execution:

```python
from mcp.server import Server
from mcp.types import Tool, TextContent
from pydantic import BaseModel, ValidationError
import asyncio

app = Server("validated-server")

class CalculationInput(BaseModel):
    """Validated input model."""
    operation: str
    a: float
    b: float

@app.list_tools()
async def list_tools() -> list[Tool]:
    """List available tools."""
    return [
        Tool(
            name="calculate",
            description="Perform mathematical operations",
            inputSchema={
                "type": "object",
                "properties": {
                    "operation": {
                        "type": "string",
                        "enum": ["add", "subtract", "multiply", "divide"]
                    },
                    "a": {"type": "number"},
                    "b": {"type": "number"}
                },
                "required": ["operation", "a", "b"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    """Execute tool with validation."""
    if name == "calculate":
        try:
            # Validate input
            input_data = CalculationInput(**arguments)
            
            # Perform calculation
            operations = {
                "add": lambda a, b: a + b,
                "subtract": lambda a, b: a - b,
                "multiply": lambda a, b: a * b,
                "divide": lambda a, b: a / b if b != 0 else None
            }
            
            result = operations[input_data.operation](
                input_data.a,
                input_data.b
            )
            
            if result is None:
                return [TextContent(
                    type="text",
                    text="Error: Division by zero"
                )]
            
            return [TextContent(
                type="text",
                text=f"Result: {result}"
            )]
            
        except ValidationError as e:
            return [TextContent(
                type="text",
                text=f"Validation error: {str(e)}"
            )]
        except Exception as e:
            return [TextContent(
                type="text",
                text=f"Execution error: {str(e)}"
            )]
    
    raise ValueError(f"Unknown tool: {name}")
```

### HTTP Transport

Use HTTP with Server-Sent Events instead of stdio:

```python
from mcp.server import Server
from mcp.server.sse import sse_server
from starlette.applications import Starlette
from starlette.routing import Mount
import asyncio
import uvicorn

app = Server("http-server")

# Define your handlers here
@app.list_resources()
async def list_resources():
    # Implementation
    pass

# Create Starlette app
web_app = Starlette(
    routes=[
        Mount("/mcp", app=sse_server(app))
    ]
)

if __name__ == "__main__":
    uvicorn.run(web_app, host="0.0.0.0", port=8000)
```

### Logging and Monitoring

Implement comprehensive logging:

```python
from mcp.server import Server
from mcp.types import LoggingLevel
import asyncio
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("mcp-server")

app = Server("monitored-server")

@app.list_resources()
async def list_resources():
    """List resources with logging."""
    logger.info("Listing resources requested")
    try:
        resources = []  # Your resources
        logger.info(f"Returning {len(resources)} resources")
        return resources
    except Exception as e:
        logger.error(f"Error listing resources: {e}")
        raise

@app.read_resource()
async def read_resource(uri: str) -> str:
    """Read resource with logging."""
    logger.info(f"Reading resource: {uri}")
    try:
        content = "..."  # Your implementation
        logger.info(f"Successfully read resource: {uri}")
        return content
    except Exception as e:
        logger.error(f"Error reading resource {uri}: {e}")
        raise
```

## Configuration

### Server Configuration

Configure MCP servers through initialization options:

```python
from mcp.server import Server
from mcp.server.stdio import stdio_server
import asyncio

app = Server("my-server")

async def main():
    # Create initialization options
    options = app.create_initialization_options()
    
    # Configure capabilities
    options.capabilities = {
        "resources": True,
        "prompts": True,
        "tools": True,
        "logging": True
    }
    
    # Run server with options
    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream, options)

if __name__ == "__main__":
    asyncio.run(main())
```

### Client Configuration

Configure MCP clients with custom settings:

```python
from mcp.client import Client
from mcp.client.stdio import stdio_client
import asyncio

async def main():
    # Configure client connection
    async with stdio_client(
        "python",
        ["server.py"],
        env={"LOG_LEVEL": "DEBUG"}
    ) as (read, write):
        async with Client(read, write) as client:
            # Initialize with client info
            await client.initialize(
                client_info={
                    "name": "my-client",
                    "version": "1.0.0"
                }
            )
            
            # Use client
            resources = await client.list_resources()

if __name__ == "__main__":
    asyncio.run(main())
```

### Environment Variables

Common environment variables for MCP:

- `MCP_LOG_LEVEL`: Set logging level (DEBUG, INFO, WARNING, ERROR)
- `MCP_TRANSPORT`: Transport type (stdio, sse)
- `MCP_SERVER_NAME`: Server identification
- `MCP_TIMEOUT`: Request timeout in seconds

```bash
# Set environment variables
export MCP_LOG_LEVEL=DEBUG
export MCP_TIMEOUT=30

# Run server
python server.py
```

### Claude Desktop Integration

Configure MCP servers in Claude Desktop's config file:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`

**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

**Linux**: `~/.config/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "my-server": {
      "command": "python",
      "args": ["/path/to/server.py"],
      "env": {
        "LOG_LEVEL": "INFO"
      }
    },
    "another-server": {
      "command": "node",
      "args": ["/path/to/server.js"]
    }
  }
}
```

## Integration Patterns

### REST API Integration

Create MCP server that wraps REST APIs:

```python
from mcp.server import Server
from mcp.types import Tool, TextContent
import asyncio
import httpx

app = Server("api-server")

@app.list_tools()
async def list_tools() -> list[Tool]:
    """List API operations as tools."""
    return [
        Tool(
            name="get-user",
            description="Fetch user information",
            inputSchema={
                "type": "object",
                "properties": {
                    "user_id": {
                        "type": "string",
                        "description": "User ID to fetch"
                    }
                },
                "required": ["user_id"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    """Call API endpoint."""
    if name == "get-user":
        user_id = arguments["user_id"]
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"https://api.example.com/users/{user_id}"
            )
            return [TextContent(
                type="text",
                text=response.text
            )]
    
    raise ValueError(f"Unknown tool: {name}")
```

### Git Integration

Access git repositories through MCP:

```python
from mcp.server import Server
from mcp.types import Resource, Tool, TextContent
import asyncio
from git import Repo
from pathlib import Path

app = Server("git-server")

REPO_PATH = Path("./repo")
repo = Repo(REPO_PATH)

@app.list_resources()
async def list_resources() -> list[Resource]:
    """List git-tracked files."""
    resources = []
    for item in repo.tree().traverse():
        if item.type == "blob":
            resources.append(
                Resource(
                    uri=f"git://{item.path}",
                    name=item.path,
                    mimeType="text/plain",
                    description=f"Git file: {item.path}"
                )
            )
    return resources

@app.list_tools()
async def list_tools() -> list[Tool]:
    """List git operations."""
    return [
        Tool(
            name="git-log",
            description="Get commit history",
            inputSchema={
                "type": "object",
                "properties": {
                    "max_count": {
                        "type": "integer",
                        "description": "Maximum commits",
                        "default": 10
                    }
                }
            }
        ),
        Tool(
            name="git-diff",
            description="Show diff for file",
            inputSchema={
                "type": "object",
                "properties": {
                    "file_path": {
                        "type": "string",
                        "description": "File path"
                    }
                },
                "required": ["file_path"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    """Execute git commands."""
    if name == "git-log":
        max_count = arguments.get("max_count", 10)
        commits = list(repo.iter_commits(max_count=max_count))
        log_text = "\n".join([
            f"{c.hexsha[:7]} - {c.summary} ({c.author.name})"
            for c in commits
        ])
        return [TextContent(type="text", text=log_text)]
    
    if name == "git-diff":
        file_path = arguments["file_path"]
        diff = repo.git.diff("HEAD", file_path)
        return [TextContent(type="text", text=diff)]
    
    raise ValueError(f"Unknown tool: {name}")
```

### Multi-Server Coordination

Connect to multiple MCP servers:

```python
from mcp.client import Client
from mcp.client.stdio import stdio_client
import asyncio

async def main():
    """Connect to multiple servers."""
    # Start first server
    async with stdio_client("python", ["server1.py"]) as (r1, w1):
        client1 = Client(r1, w1)
        await client1.initialize()
        
        # Start second server
        async with stdio_client("python", ["server2.py"]) as (r2, w2):
            client2 = Client(r2, w2)
            await client2.initialize()
            
            # Use both servers
            resources1 = await client1.list_resources()
            resources2 = await client2.list_resources()
            
            print(f"Server 1 resources: {len(resources1)}")
            print(f"Server 2 resources: {len(resources2)}")

if __name__ == "__main__":
    asyncio.run(main())
```

## Best Practices

### Security

#### Input Validation

Always validate and sanitize inputs:

```python
from mcp.server import Server
from mcp.types import Tool, TextContent
from pathlib import Path
import re

app = Server("secure-server")

SAFE_PATH = Path("./safe_directory")

@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    """Secure tool execution."""
    if name == "read-file":
        file_path = arguments.get("path", "")
        
        # Validate path
        if not file_path or ".." in file_path:
            return [TextContent(
                type="text",
                text="Error: Invalid path"
            )]
        
        # Resolve and check path
        full_path = (SAFE_PATH / file_path).resolve()
        if not full_path.is_relative_to(SAFE_PATH):
            return [TextContent(
                type="text",
                text="Error: Access denied"
            )]
        
        # Read file
        content = full_path.read_text()
        return [TextContent(type="text", text=content)]
    
    raise ValueError(f"Unknown tool: {name}")
```

#### Credential Management

Use environment variables for sensitive data:

```python
import os
from mcp.server import Server
import asyncio

# Load from environment
API_KEY = os.getenv("API_KEY")
DATABASE_URL = os.getenv("DATABASE_URL")

if not API_KEY:
    raise ValueError("API_KEY environment variable required")

app = Server("secure-server")

# Use credentials securely
async def make_api_call():
    """Use API key from environment."""
    headers = {"Authorization": f"Bearer {API_KEY}"}
    # ... make request
```

#### Rate Limiting

Implement rate limiting to prevent abuse:

```python
from mcp.server import Server
from mcp.types import Tool, TextContent
import asyncio
from collections import defaultdict
from datetime import datetime, timedelta

app = Server("rate-limited-server")

# Track request counts
request_counts = defaultdict(list)
MAX_REQUESTS = 10
TIME_WINDOW = timedelta(minutes=1)

@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    """Tool with rate limiting."""
    client_id = "default"  # Get from context in real implementation
    
    # Clean old requests
    now = datetime.now()
    request_counts[client_id] = [
        ts for ts in request_counts[client_id]
        if now - ts < TIME_WINDOW
    ]
    
    # Check limit
    if len(request_counts[client_id]) >= MAX_REQUESTS:
        return [TextContent(
            type="text",
            text="Error: Rate limit exceeded. Try again later."
        )]
    
    # Record request
    request_counts[client_id].append(now)
    
    # Process tool call
    # ... your implementation
    
    return [TextContent(type="text", text="Success")]
```

### Performance

#### Caching

Implement caching for expensive operations:

```python
from mcp.server import Server
from mcp.types import Resource
from functools import lru_cache
import asyncio

app = Server("cached-server")

@lru_cache(maxsize=100)
def expensive_computation(param: str) -> str:
    """Cached expensive operation."""
    # Expensive computation here
    return f"Result for {param}"

@app.read_resource()
async def read_resource(uri: str) -> str:
    """Use cached computation."""
    param = uri.split("/")[-1]
    return expensive_computation(param)
```

#### Async Best Practices

Use async operations efficiently:

```python
from mcp.server import Server
from mcp.types import Resource
import asyncio
import httpx

app = Server("async-server")

@app.list_resources()
async def list_resources() -> list[Resource]:
    """Fetch resources concurrently."""
    async with httpx.AsyncClient() as client:
        # Fetch multiple endpoints concurrently
        tasks = [
            client.get("https://api1.example.com/data"),
            client.get("https://api2.example.com/data"),
            client.get("https://api3.example.com/data")
        ]
        responses = await asyncio.gather(*tasks)
        
        # Process responses
        resources = []
        for idx, response in enumerate(responses):
            resources.append(
                Resource(
                    uri=f"api://data/{idx}",
                    name=f"API Data {idx}",
                    mimeType="application/json",
                    description=f"Data from API {idx}"
                )
            )
        return resources
```

### Testing

#### Unit Testing

Test MCP servers with pytest:

```python
import pytest
from mcp.server import Server
from mcp.types import Resource
import asyncio

# Create test server
app = Server("test-server")

@app.list_resources()
async def list_resources() -> list[Resource]:
    """Test resource list."""
    return [
        Resource(
            uri="test://resource",
            name="Test Resource",
            mimeType="text/plain",
            description="Test"
        )
    ]

# Test function
@pytest.mark.asyncio
async def test_list_resources():
    """Test resource listing."""
    resources = await list_resources()
    assert len(resources) == 1
    assert resources[0].uri == "test://resource"
    assert resources[0].name == "Test Resource"

@pytest.mark.asyncio
async def test_read_resource():
    """Test resource reading."""
    # Test implementation
    pass
```

#### Integration Testing

Test client-server interaction:

```python
import pytest
from mcp.client import Client
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.client.stdio import stdio_client
import asyncio

@pytest.mark.asyncio
async def test_server_client_integration():
    """Test full client-server interaction."""
    # This would require setting up test infrastructure
    # See MCP documentation for complete examples
    pass
```

### Error Handling

#### Graceful Degradation

Handle errors gracefully:

```python
from mcp.server import Server
from mcp.types import Resource, TextContent
import asyncio

app = Server("resilient-server")

@app.list_resources()
async def list_resources() -> list[Resource]:
    """List resources with fallback."""
    try:
        # Try primary data source
        return await fetch_primary_resources()
    except Exception as e:
        # Log error
        print(f"Primary source failed: {e}")
        try:
            # Try backup source
            return await fetch_backup_resources()
        except Exception as e2:
            # Log error
            print(f"Backup source failed: {e2}")
            # Return minimal fallback
            return [
                Resource(
                    uri="error://fallback",
                    name="Fallback Resource",
                    mimeType="text/plain",
                    description="Service temporarily unavailable"
                )
            ]

async def fetch_primary_resources():
    """Fetch from primary source."""
    # Implementation
    pass

async def fetch_backup_resources():
    """Fetch from backup source."""
    # Implementation
    pass
```

## Real-World Examples

### Knowledge Base Server

Expose documentation as MCP resources:

```python
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Resource, Tool, TextContent
import asyncio
from pathlib import Path
import markdown

app = Server("knowledge-base")

DOCS_PATH = Path("./docs")

@app.list_resources()
async def list_resources() -> list[Resource]:
    """List all documentation files."""
    resources = []
    for md_file in DOCS_PATH.rglob("*.md"):
        resources.append(
            Resource(
                uri=f"docs://{md_file.relative_to(DOCS_PATH)}",
                name=md_file.stem.replace("-", " ").title(),
                mimeType="text/markdown",
                description=f"Documentation: {md_file.stem}"
            )
        )
    return resources

@app.read_resource()
async def read_resource(uri: str) -> str:
    """Read documentation file."""
    if uri.startswith("docs://"):
        rel_path = uri[7:]
        file_path = DOCS_PATH / rel_path
        if file_path.exists():
            return file_path.read_text()
    raise ValueError(f"Unknown resource: {uri}")

@app.list_tools()
async def list_tools() -> list[Tool]:
    """Search documentation."""
    return [
        Tool(
            name="search-docs",
            description="Search documentation for keywords",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Search query"
                    }
                },
                "required": ["query"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    """Search documentation."""
    if name == "search-docs":
        query = arguments["query"].lower()
        results = []
        
        for md_file in DOCS_PATH.rglob("*.md"):
            content = md_file.read_text().lower()
            if query in content:
                results.append(md_file.stem)
        
        return [TextContent(
            type="text",
            text=f"Found in: {', '.join(results)}" if results 
                 else "No results found"
        )]
    
    raise ValueError(f"Unknown tool: {name}")

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await app.run(
            read_stream,
            write_stream,
            app.create_initialization_options()
        )

if __name__ == "__main__":
    asyncio.run(main())
```

### Development Tools Server

Expose development tools through MCP:

```python
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent
import asyncio
import subprocess

app = Server("dev-tools")

@app.list_tools()
async def list_tools() -> list[Tool]:
    """List development tools."""
    return [
        Tool(
            name="run-tests",
            description="Run project tests",
            inputSchema={
                "type": "object",
                "properties": {
                    "test_path": {
                        "type": "string",
                        "description": "Path to test file or directory"
                    }
                }
            }
        ),
        Tool(
            name="lint-code",
            description="Lint code with ruff",
            inputSchema={
                "type": "object",
                "properties": {
                    "file_path": {
                        "type": "string",
                        "description": "File to lint"
                    }
                },
                "required": ["file_path"]
            }
        ),
        Tool(
            name="format-code",
            description="Format code with black",
            inputSchema={
                "type": "object",
                "properties": {
                    "file_path": {
                        "type": "string",
                        "description": "File to format"
                    }
                },
                "required": ["file_path"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    """Execute development tool."""
    if name == "run-tests":
        test_path = arguments.get("test_path", "tests/")
        result = subprocess.run(
            ["pytest", test_path, "-v"],
            capture_output=True,
            text=True
        )
        return [TextContent(
            type="text",
            text=f"Exit code: {result.returncode}\n\n{result.stdout}\n{result.stderr}"
        )]
    
    if name == "lint-code":
        file_path = arguments["file_path"]
        result = subprocess.run(
            ["ruff", "check", file_path],
            capture_output=True,
            text=True
        )
        return [TextContent(
            type="text",
            text=result.stdout if result.stdout else "No issues found"
        )]
    
    if name == "format-code":
        file_path = arguments["file_path"]
        result = subprocess.run(
            ["black", file_path],
            capture_output=True,
            text=True
        )
        return [TextContent(
            type="text",
            text=f"Formatted: {file_path}"
        )]
    
    raise ValueError(f"Unknown tool: {name}")

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await app.run(
            read_stream,
            write_stream,
            app.create_initialization_options()
        )

if __name__ == "__main__":
    asyncio.run(main())
```

## Troubleshooting

### Common Issues

#### Server Not Connecting

**Problem**: Client cannot connect to server

**Solutions**:

```bash
# Check server is running
python server.py

# Verify Python version
python --version  # Should be 3.10+

# Check MCP installation
python -c "import mcp; print(mcp.__version__)"

# Enable debug logging
export MCP_LOG_LEVEL=DEBUG
python server.py
```

#### Protocol Version Mismatch

**Problem**: Client and server protocol versions incompatible

**Solution**:

```python
from mcp.server import Server

app = Server("my-server")

# Specify protocol version explicitly
async def main():
    options = app.create_initialization_options()
    options.protocol_version = "2024-11-05"
    # ... run server
```

#### Resource Not Found

**Problem**: Resources listed but cannot be read

**Solution**:

```python
@app.read_resource()
async def read_resource(uri: str) -> str:
    """Add detailed error logging."""
    print(f"Attempting to read: {uri}")
    
    try:
        # Your resource reading logic
        content = fetch_content(uri)
        return content
    except Exception as e:
        print(f"Error reading {uri}: {e}")
        raise ValueError(f"Cannot read resource {uri}: {str(e)}")
```

#### Performance Issues

**Problem**: Slow resource listing or tool execution

**Solutions**:

```python
# Use caching
from functools import lru_cache

@lru_cache(maxsize=128)
def get_expensive_data(param):
    # Cached computation
    pass

# Use async operations
async def fetch_multiple():
    # Fetch concurrently
    results = await asyncio.gather(
        fetch_1(),
        fetch_2(),
        fetch_3()
    )
    return results

# Limit result size
@app.list_resources()
async def list_resources() -> list[Resource]:
    # Paginate or limit results
    all_resources = fetch_all_resources()
    return all_resources[:100]  # Limit to 100
```

### Debug Mode

Enable comprehensive debugging:

```python
import logging
from mcp.server import Server
import asyncio

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('mcp_debug.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

app = Server("debug-server")

@app.list_resources()
async def list_resources():
    """List with debug logging."""
    logger.debug("list_resources called")
    try:
        resources = []  # Your logic
        logger.debug(f"Returning {len(resources)} resources")
        return resources
    except Exception as e:
        logger.exception("Error in list_resources")
        raise
```

## See Also

- [MCP Official Specification](https://spec.modelcontextprotocol.io/)
- [MCP GitHub Repository](https://github.com/modelcontextprotocol)
- [Claude Desktop Integration Guide](https://docs.anthropic.com/claude/docs/mcp)
- [Python Async Programming with asyncio](asyncio.md)

## Additional Resources

### Community

- [MCP Discord Server](https://discord.gg/modelcontextprotocol)
- [GitHub Discussions](https://github.com/modelcontextprotocol/discussions)
- [Issue Tracker](https://github.com/modelcontextprotocol/issues)

### Example Servers

Official example implementations:

- **Filesystem Server**: Browse and read files
- **Git Server**: Git repository operations
- **Database Server**: SQL query execution
- **HTTP Server**: REST API integration
- **Slack Server**: Slack workspace integration
- **GitHub Server**: GitHub API integration

Find examples at: <https://github.com/modelcontextprotocol/servers>

### Tutorials

- [Building Your First MCP Server](https://modelcontextprotocol.io/quickstart)
- [MCP Security Best Practices](https://modelcontextprotocol.io/docs/security)
- [Advanced MCP Patterns](https://modelcontextprotocol.io/docs/patterns)
- [Testing MCP Servers](https://modelcontextprotocol.io/docs/testing)

### Related Tools

- **Claude Desktop**: AI assistant with MCP support
- **MCP Inspector**: Debug and test MCP servers
- **MCP CLI**: Command-line tools for MCP development
