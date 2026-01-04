---
title: "Integration and APIs for Local LLMs"
description: "Connecting local LLMs to applications and creating API interfaces"
author: "Joseph Streeter"
ms.date: "2025-12-31"
ms.topic: "guide"
keywords: ["integration", "api", "sdk", "openai compatible", "local llm api"]
uid: docs.ai.local-llms.integration
---

## Overview

Integrating local Large Language Models (LLMs) with applications requires a comprehensive understanding of API architectures, client libraries, and integration patterns. This guide provides detailed instructions for connecting local LLMs to various applications, frameworks, and services while maintaining high performance, security, and scalability.

Local LLM integration offers several advantages over cloud-based solutions:

- **Privacy and Data Control**: Keep sensitive data on-premises
- **Cost Efficiency**: Eliminate per-token API fees for high-volume applications
- **Latency Optimization**: Reduce network overhead with local processing
- **Customization Freedom**: Full control over model behavior and responses
- **Offline Capability**: Function without internet connectivity
- **Compliance**: Meet strict data residency requirements

### Integration Architecture Overview

Modern local LLM integrations typically follow a layered architecture:

```text
┌─────────────────────────────────────┐
│          Client Applications        │
│  (Web, Mobile, Desktop, CLI, etc.)  │
├─────────────────────────────────────┤
│          Client Libraries           │
│     (Python, JS, Go, Rust, etc.)   │
├─────────────────────────────────────┤
│           API Gateway               │
│   (Auth, Rate Limiting, Routing)    │
├─────────────────────────────────────┤
│         API Servers                 │
│  (OpenAI-Compatible, Custom REST)   │
├─────────────────────────────────────┤
│        Middleware Layer             │
│  (Caching, Load Balancing, Logging) │
├─────────────────────────────────────┤
│         LLM Runtime                 │
│    (Ollama, llama.cpp, vLLM)       │
└─────────────────────────────────────┘
```

### Key Integration Patterns

**Synchronous Request-Response**: Traditional API pattern for single completions
**Streaming Responses**: Real-time token-by-token output for better user experience
**Batch Processing**: Efficient handling of multiple requests simultaneously
**Asynchronous Processing**: Queue-based processing for high-latency operations
**Event-Driven Architecture**: Webhook and message queue integration

### Common Use Cases

This guide covers integration patterns for:

- **Conversational AI**: Chatbots, virtual assistants, and interactive applications
- **Content Generation**: Writing assistance, code generation, and creative tools
- **Document Processing**: Summarization, translation, and analysis workflows
- **Code Assistance**: IDE plugins, code review tools, and development environments
- **Enterprise Applications**: Knowledge management, customer support, and automation
- **Research and Analytics**: Data analysis, report generation, and insights extraction

## API Standards

Understanding different API patterns and standards for local LLM integration.

### OpenAI-Compatible APIs

The most popular integration pattern leverages OpenAI's API specification as a standard.

**Advantages of OpenAI Compatibility:**

- **Drop-in Replacement**: Minimal code changes from OpenAI to local models
- **Extensive Ecosystem**: Wide library and framework support
- **Standardized Interface**: Consistent request/response patterns
- **Community Support**: Large developer community and resources

**Core Endpoints:**

```http
# Chat Completions (GPT-style conversations)
POST /v1/chat/completions
Content-Type: application/json

{
  "model": "llama-2-7b-chat",
  "messages": [
    {"role": "user", "content": "Hello, how are you?"}
  ],
  "temperature": 0.7,
  "max_tokens": 150,
  "stream": false
}

# Text Completions (Legacy format)
POST /v1/completions
Content-Type: application/json

{
  "model": "llama-2-7b",
  "prompt": "Complete this sentence: The future of AI is",
  "max_tokens": 100,
  "temperature": 0.8
}

# Model Information
GET /v1/models

# Embeddings (if supported)
POST /v1/embeddings
Content-Type: application/json

{
  "model": "text-embedding-model",
  "input": "Text to embed"
}
```

**OpenAI-Compatible Servers:**

- **LocalAI**: Complete OpenAI API implementation
- **Text Generation WebUI**: Built-in OpenAI API extension
- **Ollama**: Native OpenAI-compatible endpoints
- **vLLM**: High-performance OpenAI-compatible server
- **llama-cpp-python**: Python wrapper with OpenAI API

### Custom API Design

Building specialized APIs for specific use cases and performance requirements.

**When to Use Custom APIs:**

- **Performance Optimization**: Reduce overhead with tailored endpoints
- **Specialized Features**: Support for custom model parameters or preprocessing
- **Legacy Integration**: Match existing system interfaces
- **Advanced Features**: Multi-modal inputs, custom stopping criteria, or specialized outputs

**Custom API Design Principles:**

```python
# Example custom API design
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict, Any

app = FastAPI(title="Custom LLM API", version="1.0.0")

class GenerationRequest(BaseModel):
    prompt: str
    model_name: str = "default"
    max_length: int = 100
    temperature: float = 0.7
    stop_sequences: Optional[List[str]] = None
    custom_parameters: Optional[Dict[str, Any]] = None

class GenerationResponse(BaseModel):
    text: str
    tokens_generated: int
    processing_time: float
    model_info: Dict[str, str]

@app.post("/generate", response_model=GenerationResponse)
async def generate_text(request: GenerationRequest):
    try:
        # Custom generation logic
        result = await custom_llm_generate(
            prompt=request.prompt,
            model=request.model_name,
            max_length=request.max_length,
            temperature=request.temperature,
            stop_sequences=request.stop_sequences or [],
            **request.custom_parameters or {}
        )
        
        return GenerationResponse(
            text=result.text,
            tokens_generated=result.token_count,
            processing_time=result.duration,
            model_info=result.model_metadata
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/models")
async def list_models():
    return {"models": await get_available_models()}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.utcnow()}
```

### REST APIs

RESTful web services following HTTP standards and best practices.

**RESTful Design Principles:**

```http
# Resource-based URLs
GET    /api/v1/models                    # List all models
GET    /api/v1/models/{model_id}         # Get specific model info
POST   /api/v1/completions               # Create completion
POST   /api/v1/chat/completions          # Chat completion
GET    /api/v1/completions/{completion_id} # Get completion status
DELETE /api/v1/sessions/{session_id}    # Delete session

# Status codes
200 OK          # Successful request
201 Created     # Resource created
400 Bad Request # Invalid input
401 Unauthorized # Authentication required
429 Too Many Requests # Rate limit exceeded
500 Internal Server Error # Server error

# Content negotiation
Accept: application/json
Content-Type: application/json

# Error response format
{
  "error": {
    "code": "invalid_request",
    "message": "The request is malformed",
    "details": {
      "parameter": "temperature",
      "issue": "must be between 0.0 and 2.0"
    }
  }
}
```

**Advanced REST Features:**

```python
# Pagination for large result sets
@app.get("/api/v1/conversations")
async def list_conversations(
    page: int = 1,
    limit: int = 20,
    sort_by: str = "created_at",
    order: str = "desc"
):
    conversations = await get_conversations(
        offset=(page - 1) * limit,
        limit=limit,
        sort_by=sort_by,
        order=order
    )
    
    return {
        "conversations": conversations,
        "pagination": {
            "current_page": page,
            "total_pages": math.ceil(total_count / limit),
            "total_items": total_count,
            "items_per_page": limit
        }
    }

# Filtering and search
@app.get("/api/v1/completions")
async def search_completions(
    q: Optional[str] = None,
    model: Optional[str] = None,
    created_after: Optional[datetime] = None,
    min_tokens: Optional[int] = None
):
    filters = {
        "search_query": q,
        "model_name": model,
        "created_after": created_after,
        "min_token_count": min_tokens
    }
    
    return await search_completions_with_filters(filters)
```

### gRPC

High-performance Remote Procedure Call framework for efficient communication.

**gRPC Advantages:**

- **Performance**: Binary serialization and HTTP/2 multiplexing
- **Type Safety**: Protocol buffer definitions
- **Streaming**: Bidirectional streaming support
- **Language Support**: Code generation for multiple languages

**Protocol Buffer Definition:**

```protobuf
// llm_service.proto
syntax = "proto3";

package llm.v1;

service LLMService {
  rpc Generate(GenerateRequest) returns (GenerateResponse);
  rpc GenerateStream(GenerateRequest) returns (stream GenerateStreamResponse);
  rpc ListModels(ListModelsRequest) returns (ListModelsResponse);
  rpc GetModel(GetModelRequest) returns (Model);
}

message GenerateRequest {
  string prompt = 1;
  string model_name = 2;
  int32 max_tokens = 3;
  float temperature = 4;
  repeated string stop_sequences = 5;
  map<string, string> parameters = 6;
}

message GenerateResponse {
  string text = 1;
  int32 tokens_generated = 2;
  float processing_time = 3;
  ModelInfo model_info = 4;
}

message GenerateStreamResponse {
  string token = 1;
  bool is_complete = 2;
  GenerateResponse final_response = 3;
}

message Model {
  string id = 1;
  string name = 2;
  string description = 3;
  int64 parameter_count = 4;
  repeated string capabilities = 5;
}
```

**gRPC Server Implementation:**

```python
# grpc_server.py
import grpc
from concurrent import futures
import llm_service_pb2_grpc
import llm_service_pb2

class LLMServicer(llm_service_pb2_grpc.LLMServiceServicer):
    def __init__(self, llm_engine):
        self.llm_engine = llm_engine
    
    def Generate(self, request, context):
        try:
            result = self.llm_engine.generate(
                prompt=request.prompt,
                model_name=request.model_name,
                max_tokens=request.max_tokens,
                temperature=request.temperature,
                stop_sequences=list(request.stop_sequences)
            )
            
            return llm_service_pb2.GenerateResponse(
                text=result.text,
                tokens_generated=result.token_count,
                processing_time=result.duration,
                model_info=llm_service_pb2.ModelInfo(
                    name=result.model_name,
                    version=result.model_version
                )
            )
        except Exception as e:
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(str(e))
            return llm_service_pb2.GenerateResponse()
    
    def GenerateStream(self, request, context):
        try:
            for token in self.llm_engine.generate_stream(
                prompt=request.prompt,
                model_name=request.model_name,
                max_tokens=request.max_tokens,
                temperature=request.temperature
            ):
                yield llm_service_pb2.GenerateStreamResponse(
                    token=token.text,
                    is_complete=token.is_final
                )
        except Exception as e:
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(str(e))

def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    llm_service_pb2_grpc.add_LLMServiceServicer_to_server(
        LLMServicer(llm_engine), server
    )
    listen_addr = '[::]:50051'
    server.add_insecure_port(listen_addr)
    server.start()
    server.wait_for_termination()
```

### WebSocket

Real-time bidirectional communication for interactive applications.

**WebSocket Advantages:**

- **Low Latency**: Persistent connection eliminates handshake overhead
- **Bidirectional**: Client and server can initiate communication
- **Real-time**: Immediate token streaming and user interaction
- **Interactive**: Support for conversation flows and interruptions

**WebSocket Server Implementation:**

```python
# websocket_server.py
import asyncio
import websockets
import json
from typing import Dict, Set

class LLMWebSocketServer:
    def __init__(self, llm_engine):
        self.llm_engine = llm_engine
        self.active_connections: Set[websockets.WebSocketServerProtocol] = set()
        self.user_sessions: Dict[str, dict] = {}
    
    async def register(self, websocket, user_id: str):
        """Register new WebSocket connection"""
        self.active_connections.add(websocket)
        self.user_sessions[user_id] = {
            "websocket": websocket,
            "conversation_history": [],
            "current_generation": None
        }
        print(f"User {user_id} connected")
    
    async def unregister(self, websocket, user_id: str):
        """Unregister WebSocket connection"""
        self.active_connections.discard(websocket)
        if user_id in self.user_sessions:
            del self.user_sessions[user_id]
        print(f"User {user_id} disconnected")
    
    async def handle_message(self, websocket, user_id: str, message: dict):
        """Process incoming WebSocket messages"""
        message_type = message.get("type")
        
        if message_type == "generate":
            await self.handle_generation(websocket, user_id, message)
        elif message_type == "stop":
            await self.handle_stop_generation(user_id)
        elif message_type == "clear_history":
            await self.clear_conversation_history(user_id)
        else:
            await self.send_error(websocket, f"Unknown message type: {message_type}")
    
    async def handle_generation(self, websocket, user_id: str, message: dict):
        """Handle text generation request"""
        try:
            prompt = message.get("prompt", "")
            model_name = message.get("model", "default")
            temperature = message.get("temperature", 0.7)
            max_tokens = message.get("max_tokens", 150)
            
            # Add to conversation history
            session = self.user_sessions[user_id]
            session["conversation_history"].append({"role": "user", "content": prompt})
            
            # Send generation start notification
            await websocket.send(json.dumps({
                "type": "generation_start",
                "model": model_name
            }))
            
            # Stream generation
            full_response = ""
            async for token in self.llm_engine.generate_stream(
                prompt=prompt,
                model_name=model_name,
                temperature=temperature,
                max_tokens=max_tokens,
                conversation_history=session["conversation_history"]
            ):
                full_response += token.text
                await websocket.send(json.dumps({
                    "type": "token",
                    "content": token.text,
                    "is_complete": token.is_final
                }))
            
            # Add response to history
            session["conversation_history"].append({"role": "assistant", "content": full_response})
            
            # Send completion notification
            await websocket.send(json.dumps({
                "type": "generation_complete",
                "full_response": full_response,
                "tokens_generated": len(full_response.split())
            }))
            
        except Exception as e:
            await self.send_error(websocket, f"Generation error: {str(e)}")
    
    async def send_error(self, websocket, error_message: str):
        """Send error message to client"""
        await websocket.send(json.dumps({
            "type": "error",
            "message": error_message
        }))
    
    async def handle_client(self, websocket, path):
        """Handle individual WebSocket client connection"""
        user_id = None
        try:
            # Wait for authentication message
            auth_message = await websocket.recv()
            auth_data = json.loads(auth_message)
            
            if auth_data.get("type") == "authenticate":
                user_id = auth_data.get("user_id")
                await self.register(websocket, user_id)
                
                await websocket.send(json.dumps({
                    "type": "authenticated",
                    "user_id": user_id
                }))
                
                # Handle subsequent messages
                async for message in websocket:
                    data = json.loads(message)
                    await self.handle_message(websocket, user_id, data)
            else:
                await self.send_error(websocket, "Authentication required")
                
        except websockets.exceptions.ConnectionClosed:
            pass
        except Exception as e:
            print(f"Error handling client: {e}")
        finally:
            if user_id:
                await self.unregister(websocket, user_id)

# Start WebSocket server
async def main():
    llm_engine = await initialize_llm_engine()
    server = LLMWebSocketServer(llm_engine)
    
    start_server = websockets.serve(
        server.handle_client,
        "localhost",
        8765
    )
    
    print("WebSocket server starting on ws://localhost:8765")
    await start_server
    await asyncio.Future()  # Run forever

if __name__ == "__main__":
    asyncio.run(main())
```

**WebSocket Client Example:**

```javascript
// websocket_client.js
class LLMWebSocketClient {
    constructor(url, userId) {
        this.url = url;
        this.userId = userId;
        this.websocket = null;
        this.callbacks = {};
    }
    
    connect() {
        return new Promise((resolve, reject) => {
            this.websocket = new WebSocket(this.url);
            
            this.websocket.onopen = () => {
                // Authenticate
                this.websocket.send(JSON.stringify({
                    type: 'authenticate',
                    user_id: this.userId
                }));
            };
            
            this.websocket.onmessage = (event) => {
                const message = JSON.parse(event.data);
                
                if (message.type === 'authenticated') {
                    resolve();
                } else {
                    this.handleMessage(message);
                }
            };
            
            this.websocket.onerror = (error) => {
                reject(error);
            };
        });
    }
    
    handleMessage(message) {
        const callback = this.callbacks[message.type];
        if (callback) {
            callback(message);
        }
    }
    
    on(messageType, callback) {
        this.callbacks[messageType] = callback;
    }
    
    generate(prompt, options = {}) {
        this.websocket.send(JSON.stringify({
            type: 'generate',
            prompt: prompt,
            model: options.model || 'default',
            temperature: options.temperature || 0.7,
            max_tokens: options.maxTokens || 150
        }));
    }
    
    stopGeneration() {
        this.websocket.send(JSON.stringify({
            type: 'stop'
        }));
    }
    
    clearHistory() {
        this.websocket.send(JSON.stringify({
            type: 'clear_history'
        }));
    }
}

// Usage example
async function main() {
    const client = new LLMWebSocketClient('ws://localhost:8765', 'user123');
    
    // Set up event handlers
    client.on('token', (message) => {
        console.log('Token:', message.content);
        // Update UI with streaming token
        document.getElementById('response').textContent += message.content;
    });
    
    client.on('generation_complete', (message) => {
        console.log('Generation complete:', message.full_response);
        // Enable input for next message
        document.getElementById('input').disabled = false;
    });
    
    client.on('error', (message) => {
        console.error('Error:', message.message);
        // Show error to user
        alert('Error: ' + message.message);
    });
    
    // Connect and start conversation
    await client.connect();
    client.generate('Hello, how are you today?');
}
```

## OpenAI-Compatible Servers

Comprehensive guide to setting up OpenAI-compatible API servers for local LLMs.

### LocalAI

Complete OpenAI API compatibility with extensive model support.

**Features:**

- Full OpenAI API compatibility (chat, completions, embeddings)
- Multiple model format support (GGUF, GPTQ, ONNX, TensorFlow)
- Built-in model management and automatic downloading
- Audio transcription and text-to-speech capabilities
- Image generation support
- Function calling and JSON mode

**Installation and Setup:**

```bash
# Docker installation (recommended)
docker run -p 8080:8080 --name local-ai -ti localai/localai:latest

# Or with custom models directory
docker run -p 8080:8080 \
  -v /path/to/models:/models \
  -v /path/to/config:/config \
  --name local-ai \
  localai/localai:latest

# Binary installation
wget https://github.com/go-skynet/LocalAI/releases/download/v2.1.0/local-ai-Linux-x86_64
chmod +x local-ai-Linux-x86_64
./local-ai-Linux-x86_64 --models-path ./models --context-size 4096
```

**Configuration:**

```yaml
# config/model-config.yaml
name: llama-2-7b-chat
parameters:
  model: llama-2-7b-chat.q4_K_M.gguf
  context_size: 4096
  threads: 8
  f16: true
  temperature: 0.7
  top_k: 40
  top_p: 0.95
template:
  chat: |
    {{.Input}}
    ### Response:
  completion: |
    Complete the following: {{.Input}}
```

**Usage Example:**

```python
# Python client
import openai

# Configure for LocalAI
openai.api_base = "http://localhost:8080/v1"
openai.api_key = "not-needed"

# Chat completion
response = openai.ChatCompletion.create(
    model="llama-2-7b-chat",
    messages=[
        {"role": "user", "content": "Hello, how are you?"}
    ],
    temperature=0.7,
    max_tokens=150
)

print(response.choices[0].message.content)
```

### Text Generation WebUI API

Built-in OpenAI-compatible API server with advanced features.

**Enabling the API:**

```bash
# Start with API enabled
python server.py --api --api-blocking-port 5001 --api-streaming-port 5005

# Or with extensions
python server.py --api --extensions openai --listen --verbose
```

**API Extensions Configuration:**

```python
# extensions/openai/script.py configuration
params = {
    'embedding_device': 'cuda',
    'embedding_model': 'all-MiniLM-L6-v2',
    'sd_model': 'runwayml/stable-diffusion-v1-5',
    'debug': True
}
```

**Advanced Features:**

```python
# Custom generation parameters
response = requests.post('http://localhost:5001/v1/chat/completions', json={
    "model": "current-model",
    "messages": [{"role": "user", "content": "Hello"}],
    "temperature": 0.7,
    "max_tokens": 100,
    # Text Generation WebUI specific parameters
    "repetition_penalty": 1.1,
    "encoder_repetition_penalty": 1.0,
    "top_k": 0,
    "min_length": 0,
    "no_repeat_ngram_size": 0,
    "num_beams": 1,
    "penalty_alpha": 0,
    "length_penalty": 1,
    "early_stopping": False,
    "seed": -1,
    "add_bos_token": True,
    "truncation_length": 2048,
    "ban_eos_token": False,
    "skip_special_tokens": True
})
```

### Ollama API

Native REST API with OpenAI compatibility mode.

**Native Ollama API:**

```bash
# Generate text
curl http://localhost:11434/api/generate -d '{
  "model": "llama2:7b",
  "prompt": "Why is the sky blue?",
  "stream": false
}'

# Chat interface
curl http://localhost:11434/api/chat -d '{
  "model": "llama2:7b",
  "messages": [
    { "role": "user", "content": "Hello!" }
  ],
  "stream": false
}'

# List models
curl http://localhost:11434/api/tags

# Model information
curl http://localhost:11434/api/show -d '{"name": "llama2:7b"}'
```

**OpenAI Compatibility:**

```python
# Using OpenAI client with Ollama
from openai import OpenAI

# Point to local Ollama server
client = OpenAI(
    base_url="http://localhost:11434/v1",
    api_key="ollama"  # Required but ignored
)

# Chat completion
response = client.chat.completions.create(
    model="llama2:7b",
    messages=[
        {"role": "user", "content": "Tell me a joke"}
    ]
)

print(response.choices[0].message.content)
```

**Streaming with Ollama:**

```python
# Streaming response
import requests
import json

def stream_ollama_response(prompt, model="llama2:7b"):
    response = requests.post(
        'http://localhost:11434/api/generate',
        json={
            'model': model,
            'prompt': prompt,
            'stream': True
        },
        stream=True
    )
    
    for line in response.iter_lines():
        if line:
            data = json.loads(line)
            if 'response' in data:
                print(data['response'], end='', flush=True)
            if data.get('done', False):
                break

# Usage
stream_ollama_response("Write a short story about AI")
```

### llama-cpp-python Server

Python wrapper providing OpenAI-compatible server functionality.

**Installation:**

```bash
# Install with CUDA support
pip install llama-cpp-python[server]

# Or compile with specific features
CMAKE_ARGS="-DLLAMA_CUBLAS=on" pip install llama-cpp-python[server]
```

**Starting the Server:**

```bash
# Basic server
python -m llama_cpp.server --model models/llama-2-7b-chat.q4_K_M.gguf

# Advanced configuration
python -m llama_cpp.server \
  --model models/llama-2-7b-chat.q4_K_M.gguf \
  --host 0.0.0.0 \
  --port 8000 \
  --n_gpu_layers 35 \
  --n_ctx 4096 \
  --n_batch 512 \
  --verbose
```

**Configuration Options:**

```python
# server_config.py
from llama_cpp.server.app import create_app
from llama_cpp import Llama

# Configure model
llm = Llama(
    model_path="models/llama-2-7b-chat.q4_K_M.gguf",
    n_gpu_layers=35,
    n_ctx=4096,
    n_batch=512,
    verbose=True,
    # Performance optimization
    n_threads=8,
    n_threads_batch=8,
    use_mmap=True,
    use_mlock=True,
    # Memory optimization
    offload_kqv=True,
    flash_attn=True
)

# Create FastAPI app
app = create_app(llm)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

**Custom Middleware:**

```python
# Add custom middleware
from fastapi import FastAPI, Request
import time
import logging

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    
    response = await call_next(request)
    
    process_time = time.time() - start_time
    logging.info(
        f"{request.method} {request.url.path} - {response.status_code} - {process_time:.2f}s"
    )
    
    return response

@app.middleware("http")
async def add_cors_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "*"
    return response
```

## Setting Up API Servers

Comprehensive guide to deploying and configuring production-ready API servers.

### Installation

Step-by-step server setup process for different deployment scenarios.

**Production Docker Setup:**

```bash
# Create production directory structure
mkdir -p ~/llm-api/{config,models,logs,ssl}
cd ~/llm-api

# Docker Compose for LocalAI
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  localai:
    image: localai/localai:latest
    container_name: local-ai-server
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./models:/models:cached
      - ./config:/config:ro
      - ./logs:/var/log/localai
    environment:
      - DEBUG=true
      - MODELS_PATH=/models
      - CONFIG_FILE=/config/config.yaml
      - THREADS=8
      - CONTEXT_SIZE=4096
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/readiness"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # Nginx reverse proxy
  nginx:
    image: nginx:alpine
    container_name: llm-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
      - ./logs:/var/log/nginx
    depends_on:
      - localai

  # Redis for caching
  redis:
    image: redis:alpine
    container_name: llm-redis
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass your-redis-password
    volumes:
      - ./redis-data:/data
    ports:
      - "6379:6379"
EOF

# Start services
docker-compose up -d
```

**Systemd Service Setup:**

```bash
# Create systemd service for Ollama
sudo tee /etc/systemd/system/ollama-api.service > /dev/null <<EOF
[Unit]
Description=Ollama Local LLM API Server
After=network.target

[Service]
Type=exec
User=ollama
Group=ollama
WorkingDirectory=/home/ollama
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_MODELS=/var/lib/ollama/models"
Environment="OLLAMA_KEEP_ALIVE=5m"
ExecStart=/usr/bin/ollama serve
Restart=always
RestartSec=10

# Security settings
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/lib/ollama

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable ollama-api
sudo systemctl start ollama-api
sudo systemctl status ollama-api
```

**High Availability Setup:**

```bash
# HAProxy configuration for load balancing
cat > haproxy.cfg << 'EOF'
global
    daemon
    maxconn 4096

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    option httplog

frontend llm_frontend
    bind *:80
    bind *:443 ssl crt /etc/ssl/certs/llm-api.pem
    redirect scheme https if !{ ssl_fc }
    default_backend llm_servers

backend llm_servers
    balance roundrobin
    option httpchk GET /v1/models
    server llm1 10.0.1.10:8080 check
    server llm2 10.0.1.11:8080 check
    server llm3 10.0.1.12:8080 check
EOF

# Start HAProxy
docker run -d --name haproxy \
  -p 80:80 -p 443:443 \
  -v $(pwd)/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro \
  -v /etc/ssl/certs:/etc/ssl/certs:ro \
  haproxy:alpine
```

### Configuration

Advanced configuration options for optimal performance.

**Environment Variables:**

```bash
# Create environment configuration
cat > .env << 'EOF'
# Server Configuration
SERVER_HOST=0.0.0.0
SERVER_PORT=8080
WORKERS=4
MAX_CONNECTIONS=1000

# Model Configuration
MODELS_PATH=/models
DEFAULT_MODEL=llama-2-7b-chat
CONTEXT_SIZE=4096
BATCH_SIZE=512

# Performance Tuning
THREADS=8
GPU_LAYERS=35
USE_MMAP=true
USE_MLOCK=true

# Security
API_KEYS=key1,key2,key3
RATE_LIMIT_RPM=60
RATE_LIMIT_RPH=1000

# Logging
LOG_LEVEL=INFO
LOG_FILE=/var/log/llm-api.log
ENABLE_ACCESS_LOG=true

# Caching
REDIS_URL=redis://localhost:6379
CACHE_TTL=3600
CACHE_MAX_SIZE=1000
EOF
```

**Configuration Files:**

```yaml
# config/api-config.yaml
server:
  host: "0.0.0.0"
  port: 8080
  workers: 4
  timeout: 120
  max_request_size: 10485760  # 10MB

models:
  default: "llama-2-7b-chat"
  available:
    - name: "llama-2-7b-chat"
      path: "/models/llama-2-7b-chat.q4_K_M.gguf"
      context_size: 4096
      gpu_layers: 35
    - name: "codellama-7b"
      path: "/models/codellama-7b-instruct.q4_K_M.gguf"
      context_size: 4096
      gpu_layers: 35

performance:
  threads: 8
  batch_size: 512
  use_mmap: true
  use_mlock: true
  flash_attention: true
  
security:
  api_keys:
    - "sk-api-key-1"
    - "sk-api-key-2"
  cors:
    origins: ["*"]
    methods: ["GET", "POST", "OPTIONS"]
    headers: ["*"]
  
rate_limiting:
  requests_per_minute: 60
  requests_per_hour: 1000
  requests_per_day: 10000
  
logging:
  level: "INFO"
  file: "/var/log/llm-api.log"
  max_size: "100MB"
  backup_count: 5
  
caching:
  enabled: true
  backend: "redis"
  url: "redis://localhost:6379"
  ttl: 3600
  max_size: 1000
```

### Authentication

Securing your API with robust authentication mechanisms.

**API Key Authentication:**

```python
# auth.py - API Key authentication
from fastapi import HTTPException, Security, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import hashlib
import hmac
import time
from typing import Optional

security = HTTPBearer()

# In production, store these securely
VALID_API_KEYS = {
    "sk-api-key-1": {"name": "Production App", "rate_limit": 1000},
    "sk-api-key-2": {"name": "Development", "rate_limit": 100},
    "sk-api-key-3": {"name": "Testing", "rate_limit": 50}
}

def verify_api_key(credentials: HTTPAuthorizationCredentials = Security(security)):
    """Verify API key authentication"""
    if credentials.scheme != "Bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication scheme"
        )
    
    api_key = credentials.credentials
    
    if api_key not in VALID_API_KEYS:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key"
        )
    
    return VALID_API_KEYS[api_key]

# Usage in FastAPI
from fastapi import Depends, FastAPI

app = FastAPI()

@app.post("/v1/chat/completions")
async def chat_completions(
    request: ChatCompletionRequest,
    auth: dict = Depends(verify_api_key)
):
    # Process authenticated request
    return await process_chat_completion(request, auth)
```

**JWT Authentication:**

```python
# jwt_auth.py - JWT-based authentication
import jwt
from datetime import datetime, timedelta
from fastapi import HTTPException, status
from typing import Optional

SECRET_KEY = "your-secret-key-here"  # Use environment variable
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials"
            )
        return payload
    except jwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )

@app.post("/auth/login")
async def login(username: str, password: str):
    # Verify credentials (implement your auth logic)
    if verify_credentials(username, password):
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": username}, expires_delta=access_token_expires
        )
        return {"access_token": access_token, "token_type": "bearer"}
    else:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password"
        )
```

### CORS Configuration

Cross-Origin Resource Sharing setup for web applications.

**FastAPI CORS Setup:**

```python
# cors_config.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

def setup_cors(app: FastAPI, environment: str = "production"):
    if environment == "development":
        # Development: Allow all origins
        app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )
    else:
        # Production: Specific origins only
        allowed_origins = [
            "https://yourdomain.com",
            "https://app.yourdomain.com",
            "https://dashboard.yourdomain.com"
        ]
        
        app.add_middleware(
            CORSMiddleware,
            allow_origins=allowed_origins,
            allow_credentials=True,
            allow_methods=["GET", "POST", "OPTIONS"],
            allow_headers=[
                "Authorization",
                "Content-Type",
                "X-Requested-With",
                "X-API-Key"
            ],
            expose_headers=["X-Total-Count", "X-Request-ID"],
            max_age=3600  # Cache preflight for 1 hour
        )

# Custom CORS headers
@app.middleware("http")
async def add_security_headers(request, call_next):
    response = await call_next(request)
    
    # Security headers
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    
    return response
```

### SSL/TLS

Secure HTTPS configuration for encrypted connections.

**Nginx SSL Configuration:**

```nginx
# nginx.conf
events {
    worker_connections 1024;
}

http {
    upstream llm_backend {
        server 127.0.0.1:8080;
        # Add more servers for load balancing
        # server 127.0.0.1:8081;
    }
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=auth:10m rate=1r/s;
    
    server {
        listen 80;
        server_name api.yourdomain.com;
        
        # Redirect HTTP to HTTPS
        return 301 https://$host$request_uri;
    }
    
    server {
        listen 443 ssl http2;
        server_name api.yourdomain.com;
        
        # SSL Configuration
        ssl_certificate /etc/ssl/certs/api.yourdomain.com.crt;
        ssl_certificate_key /etc/ssl/private/api.yourdomain.com.key;
        
        # Modern SSL configuration
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;
        
        # Security headers
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload";
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        
        # API endpoints
        location /v1/ {
            # Rate limiting
            limit_req zone=api burst=20 nodelay;
            
            # Proxy settings
            proxy_pass http://llm_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Timeout settings for LLM responses
            proxy_connect_timeout 60s;
            proxy_send_timeout 300s;
            proxy_read_timeout 300s;
            
            # Enable streaming
            proxy_buffering off;
            proxy_cache off;
        }
        
        # Health check endpoint (no rate limiting)
        location /health {
            proxy_pass http://llm_backend/health;
            access_log off;
        }
        
        # Authentication endpoints with stricter rate limiting
        location /auth/ {
            limit_req zone=auth burst=5 nodelay;
            proxy_pass http://llm_backend;
        }
    }
}
```

**Let's Encrypt SSL Setup:**

```bash
# Install Certbot
sudo apt update
sudo apt install certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d api.yourdomain.com

# Auto-renewal setup
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet

# Test renewal
sudo certbot renew --dry-run
```

**Self-Signed Certificate for Development:**

```bash
# Generate self-signed certificate
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# Use with Python HTTPS server
from fastapi import FastAPI
import uvicorn
import ssl

app = FastAPI()

if __name__ == "__main__":
    ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ssl_context.load_cert_chain("cert.pem", "key.pem")
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=443,
        ssl_keyfile="key.pem",
        ssl_certfile="cert.pem"
    )
```

## Client Libraries

Comprehensive client library implementations for seamless integration across programming languages.

### Python Integration

Python offers the richest ecosystem for local LLM integration with multiple client libraries and approaches.

**OpenAI Client with Local APIs:**

```python
# Using OpenAI client with local servers
from openai import OpenAI
import asyncio

# Configure for local server
client = OpenAI(
    base_url="http://localhost:8080/v1",  # LocalAI or other compatible server
    api_key="not-needed"  # Most local servers don't require real keys
)

# Synchronous chat completion
def chat_with_local_llm(message, model="llama-2-7b-chat"):
    try:
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": message}
            ],
            temperature=0.7,
            max_tokens=150,
            stream=False
        )
        return response.choices[0].message.content
    except Exception as e:
        print(f"Error: {e}")
        return None

# Asynchronous streaming
async def stream_chat_response(message, model="llama-2-7b-chat"):
    from openai import AsyncOpenAI
    
    async_client = AsyncOpenAI(
        base_url="http://localhost:8080/v1",
        api_key="not-needed"
    )
    
    try:
        stream = await async_client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": message}],
            temperature=0.7,
            max_tokens=150,
            stream=True
        )
        
        async for chunk in stream:
            if chunk.choices[0].delta.content is not None:
                print(chunk.choices[0].delta.content, end='', flush=True)
    except Exception as e:
        print(f"Streaming error: {e}")

# Usage examples
response = chat_with_local_llm("Explain quantum computing in simple terms")
print(response)

# Run streaming example
asyncio.run(stream_chat_response("Write a short story about AI"))
```

**Direct HTTP Requests with Requests:**

```python
# Direct API interaction with requests library
import requests
import json
from typing import Dict, List, Optional, Iterator
import time

class LocalLLMClient:
    def __init__(self, base_url: str = "http://localhost:8080", api_key: Optional[str] = None):
        self.base_url = base_url.rstrip('/')
        self.api_key = api_key
        self.session = requests.Session()
        
        # Set default headers
        self.session.headers.update({
            "Content-Type": "application/json",
            "User-Agent": "LocalLLM-Python-Client/1.0"
        })
        
        if api_key:
            self.session.headers["Authorization"] = f"Bearer {api_key}"
    
    def list_models(self) -> List[Dict]:
        """Get available models"""
        try:
            response = self.session.get(f"{self.base_url}/v1/models")
            response.raise_for_status()
            return response.json().get("data", [])
        except requests.RequestException as e:
            print(f"Error listing models: {e}")
            return []
    
    def chat_completion(
        self,
        messages: List[Dict[str, str]],
        model: str = "default",
        temperature: float = 0.7,
        max_tokens: int = 150,
        stream: bool = False
    ) -> Dict:
        """Create chat completion"""
        payload = {
            "model": model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
            "stream": stream
        }
        
        try:
            if stream:
                return self._stream_completion(payload)
            else:
                response = self.session.post(
                    f"{self.base_url}/v1/chat/completions",
                    json=payload,
                    timeout=120
                )
                response.raise_for_status()
                return response.json()
        except requests.RequestException as e:
            return {"error": str(e)}
    
    def _stream_completion(self, payload: Dict) -> Iterator[Dict]:
        """Handle streaming completions"""
        try:
            response = self.session.post(
                f"{self.base_url}/v1/chat/completions",
                json=payload,
                stream=True,
                timeout=120
            )
            response.raise_for_status()
            
            for line in response.iter_lines():
                if line:
                    line_str = line.decode('utf-8')
                    if line_str.startswith('data: '):
                        data = line_str[6:]  # Remove 'data: ' prefix
                        if data.strip() == '[DONE]':
                            break
                        try:
                            yield json.loads(data)
                        except json.JSONDecodeError:
                            continue
        except requests.RequestException as e:
            yield {"error": str(e)}
    
    def health_check(self) -> bool:
        """Check server health"""
        try:
            response = self.session.get(f"{self.base_url}/health", timeout=5)
            return response.status_code == 200
        except requests.RequestException:
            return False

# Usage example
client = LocalLLMClient("http://localhost:8080")

# Check if server is running
if client.health_check():
    print("Server is running!")
    
    # List available models
    models = client.list_models()
    print(f"Available models: {[m['id'] for m in models]}")
    
    # Chat completion
    messages = [
        {"role": "system", "content": "You are a helpful coding assistant."},
        {"role": "user", "content": "Write a Python function to calculate factorial"}
    ]
    
    response = client.chat_completion(messages, model="llama-2-7b-chat")
    print(response["choices"][0]["message"]["content"])
    
    # Streaming example
    print("\nStreaming response:")
    for chunk in client.chat_completion(messages, stream=True):
        if "choices" in chunk and chunk["choices"]:
            content = chunk["choices"][0].get("delta", {}).get("content", "")
            if content:
                print(content, end='', flush=True)
else:
    print("Server is not running!")
```

**Ollama Python Client:**

```python
# Using ollama-python client
import ollama
from typing import Iterator, Dict, Any

class OllamaClient:
    def __init__(self, host: str = "http://localhost:11434"):
        self.client = ollama.Client(host=host)
    
    def list_models(self) -> list:
        """Get available models"""
        try:
            return self.client.list()['models']
        except Exception as e:
            print(f"Error listing models: {e}")
            return []
    
    def generate(
        self,
        model: str,
        prompt: str,
        stream: bool = False,
        **kwargs
    ) -> Dict[str, Any]:
        """Generate text completion"""
        try:
            if stream:
                return self._stream_generate(model, prompt, **kwargs)
            else:
                response = self.client.generate(
                    model=model,
                    prompt=prompt,
                    stream=False,
                    **kwargs
                )
                return response
        except Exception as e:
            return {"error": str(e)}
    
    def _stream_generate(self, model: str, prompt: str, **kwargs) -> Iterator[Dict]:
        """Stream generation tokens"""
        try:
            stream = self.client.generate(
                model=model,
                prompt=prompt,
                stream=True,
                **kwargs
            )
            for chunk in stream:
                yield chunk
        except Exception as e:
            yield {"error": str(e)}
    
    def chat(
        self,
        model: str,
        messages: list,
        stream: bool = False,
        **kwargs
    ) -> Dict[str, Any]:
        """Chat completion"""
        try:
            if stream:
                return self._stream_chat(model, messages, **kwargs)
            else:
                response = self.client.chat(
                    model=model,
                    messages=messages,
                    stream=False,
                    **kwargs
                )
                return response
        except Exception as e:
            return {"error": str(e)}
    
    def _stream_chat(self, model: str, messages: list, **kwargs) -> Iterator[Dict]:
        """Stream chat responses"""
        try:
            stream = self.client.chat(
                model=model,
                messages=messages,
                stream=True,
                **kwargs
            )
            for chunk in stream:
                yield chunk
        except Exception as e:
            yield {"error": str(e)}
    
    def pull_model(self, model: str) -> bool:
        """Download a model"""
        try:
            self.client.pull(model)
            return True
        except Exception as e:
            print(f"Error pulling model {model}: {e}")
            return False

# Usage example
ollama_client = OllamaClient()

# List models
models = ollama_client.list_models()
print(f"Available models: {[m['name'] for m in models]}")

# Pull a model if not available
if not any(m['name'].startswith('llama2:7b') for m in models):
    print("Pulling llama2:7b model...")
    ollama_client.pull_model('llama2:7b')

# Generate text
response = ollama_client.generate(
    model='llama2:7b',
    prompt='Explain the benefits of renewable energy',
    options={
        'temperature': 0.7,
        'num_predict': 100
    }
)
print(response['response'])

# Chat example
messages = [
    {'role': 'user', 'content': 'What is machine learning?'}
]

chat_response = ollama_client.chat(
    model='llama2:7b',
    messages=messages
)
print(chat_response['message']['content'])
```

### JavaScript/TypeScript

JavaScript and TypeScript integration for both Node.js backend and browser frontend applications.

**Node.js OpenAI Client:**

```typescript
// node-client.ts - Node.js TypeScript client
import OpenAI from 'openai';
import fetch from 'node-fetch';

interface LocalLLMConfig {
  baseUrl: string;
  apiKey?: string;
  timeout?: number;
}

class LocalLLMClient {
  private openai: OpenAI;
  private config: LocalLLMConfig;

  constructor(config: LocalLLMConfig) {
    this.config = {
      timeout: 120000,
      ...config
    };

    this.openai = new OpenAI({
      baseURL: this.config.baseUrl,
      apiKey: this.config.apiKey || 'not-needed',
      timeout: this.config.timeout
    });
  }

  async listModels(): Promise<string[]> {
    try {
      const models = await this.openai.models.list();
      return models.data.map(model => model.id);
    } catch (error) {
      console.error('Error listing models:', error);
      return [];
    }
  }

  async chatCompletion(
    messages: OpenAI.Chat.ChatCompletionMessageParam[],
    options: {
      model?: string;
      temperature?: number;
      maxTokens?: number;
      stream?: boolean;
    } = {}
  ): Promise<string | AsyncIterable<string>> {
    const {
      model = 'default',
      temperature = 0.7,
      maxTokens = 150,
      stream = false
    } = options;

    try {
      if (stream) {
        return this.streamChatCompletion(messages, { model, temperature, maxTokens });
      }

      const completion = await this.openai.chat.completions.create({
        model,
        messages,
        temperature,
        max_tokens: maxTokens,
        stream: false
      });

      return completion.choices[0]?.message?.content || '';
    } catch (error) {
      console.error('Chat completion error:', error);
      throw error;
    }
  }

  private async *streamChatCompletion(
    messages: OpenAI.Chat.ChatCompletionMessageParam[],
    options: { model: string; temperature: number; maxTokens: number }
  ): AsyncIterable<string> {
    try {
      const stream = await this.openai.chat.completions.create({
        model: options.model,
        messages,
        temperature: options.temperature,
        max_tokens: options.maxTokens,
        stream: true
      });

      for await (const chunk of stream) {
        const content = chunk.choices[0]?.delta?.content;
        if (content) {
          yield content;
        }
      }
    } catch (error) {
      console.error('Streaming error:', error);
      throw error;
    }
  }

  async healthCheck(): Promise<boolean> {
    try {
      const response = await fetch(`${this.config.baseUrl}/health`, {
        method: 'GET',
        timeout: 5000
      });
      return response.ok;
    } catch {
      return false;
    }
  }
}

// Usage example
async function main() {
  const client = new LocalLLMClient({
    baseUrl: 'http://localhost:8080/v1'
  });

  // Health check
  const isHealthy = await client.healthCheck();
  console.log(`Server healthy: ${isHealthy}`);

  if (isHealthy) {
    // List models
    const models = await client.listModels();
    console.log('Available models:', models);

    // Chat completion
    const response = await client.chatCompletion([
      { role: 'system', content: 'You are a helpful assistant.' },
      { role: 'user', content: 'Explain async/await in JavaScript' }
    ], { model: 'llama-2-7b-chat' });

    console.log('Response:', response);

    // Streaming example
    console.log('\nStreaming response:');
    const stream = await client.chatCompletion([
      { role: 'user', content: 'Tell me about Node.js' }
    ], { stream: true }) as AsyncIterable<string>;

    for await (const chunk of stream) {
      process.stdout.write(chunk);
    }
  }
}

main().catch(console.error);
```

**Browser JavaScript Client:**

```javascript
// browser-client.js - Browser-compatible client
class BrowserLLMClient {
  constructor(baseUrl, apiKey = null) {
    this.baseUrl = baseUrl.replace(/\/$/, '');
    this.apiKey = apiKey;
  }

  async request(endpoint, options = {}) {
    const url = `${this.baseUrl}${endpoint}`;
    const headers = {
      'Content-Type': 'application/json',
      ...options.headers
    };

    if (this.apiKey) {
      headers['Authorization'] = `Bearer ${this.apiKey}`;
    }

    try {
      const response = await fetch(url, {
        ...options,
        headers
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      return response;
    } catch (error) {
      console.error('Request error:', error);
      throw error;
    }
  }

  async listModels() {
    try {
      const response = await this.request('/v1/models');
      const data = await response.json();
      return data.data.map(model => model.id);
    } catch (error) {
      console.error('Error listing models:', error);
      return [];
    }
  }

  async chatCompletion(messages, options = {}) {
    const {
      model = 'default',
      temperature = 0.7,
      maxTokens = 150,
      stream = false
    } = options;

    const payload = {
      model,
      messages,
      temperature,
      max_tokens: maxTokens,
      stream
    };

    try {
      if (stream) {
        return this.streamChatCompletion(payload);
      }

      const response = await this.request('/v1/chat/completions', {
        method: 'POST',
        body: JSON.stringify(payload)
      });

      const data = await response.json();
      return data.choices[0]?.message?.content || '';
    } catch (error) {
      console.error('Chat completion error:', error);
      throw error;
    }
  }

  async *streamChatCompletion(payload) {
    try {
      const response = await this.request('/v1/chat/completions', {
        method: 'POST',
        body: JSON.stringify(payload)
      });

      const reader = response.body.getReader();
      const decoder = new TextDecoder();

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        const chunk = decoder.decode(value);
        const lines = chunk.split('\n');

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            const data = line.slice(6);
            if (data.trim() === '[DONE]') return;

            try {
              const parsed = JSON.parse(data);
              const content = parsed.choices?.[0]?.delta?.content;
              if (content) {
                yield content;
              }
            } catch (e) {
              // Ignore parsing errors for partial chunks
            }
          }
        }
      }
    } catch (error) {
      console.error('Streaming error:', error);
      throw error;
    }
  }

  async healthCheck() {
    try {
      const response = await fetch(`${this.baseUrl}/health`, {
        method: 'GET',
        timeout: 5000
      });
      return response.ok;
    } catch {
      return false;
    }
  }
}

// React Hook for LLM Integration
function useLLMClient(baseUrl) {
  const [client] = useState(() => new BrowserLLMClient(baseUrl));
  const [models, setModels] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);

  const loadModels = useCallback(async () => {
    try {
      setIsLoading(true);
      setError(null);
      const availableModels = await client.listModels();
      setModels(availableModels);
    } catch (err) {
      setError(err.message);
    } finally {
      setIsLoading(false);
    }
  }, [client]);

  const chat = useCallback(async (messages, options = {}) => {
    try {
      setError(null);
      return await client.chatCompletion(messages, options);
    } catch (err) {
      setError(err.message);
      throw err;
    }
  }, [client]);

  const streamChat = useCallback(async function* (messages, options = {}) {
    try {
      setError(null);
      const stream = client.streamChatCompletion({
        messages,
        stream: true,
        ...options
      });

      for await (const chunk of stream) {
        yield chunk;
      }
    } catch (err) {
      setError(err.message);
      throw err;
    }
  }, [client]);

  return {
    client,
    models,
    loadModels,
    chat,
    streamChat,
    isLoading,
    error
  };
}

// Usage in React component
function ChatComponent() {
  const { client, models, loadModels, streamChat, error } = useLLMClient('http://localhost:8080');
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [isStreaming, setIsStreaming] = useState(false);

  useEffect(() => {
    loadModels();
  }, [loadModels]);

  const handleSend = async () => {
    if (!input.trim() || isStreaming) return;

    const userMessage = { role: 'user', content: input };
    const newMessages = [...messages, userMessage];
    setMessages(newMessages);
    setInput('');
    setIsStreaming(true);

    let assistantMessage = { role: 'assistant', content: '' };
    setMessages([...newMessages, assistantMessage]);

    try {
      const stream = streamChat(newMessages, { model: 'llama-2-7b-chat' });

      for await (const chunk of stream) {
        assistantMessage.content += chunk;
        setMessages([...newMessages, { ...assistantMessage }]);
      }
    } catch (err) {
      console.error('Streaming error:', err);
    } finally {
      setIsStreaming(false);
    }
  };

  return (
    <div className="chat-component">
      <div className="messages">
        {messages.map((msg, idx) => (
          <div key={idx} className={`message ${msg.role}`}>
            {msg.content}
          </div>
        ))}
      </div>
      
      <div className="input-area">
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && handleSend()}
          disabled={isStreaming}
          placeholder="Type your message..."
        />
        <button onClick={handleSend} disabled={isStreaming || !input.trim()}>
          {isStreaming ? 'Sending...' : 'Send'}
        </button>
      </div>
      
      {error && <div className="error">Error: {error}</div>}
    </div>
  );
}
```

### Other Languages

Implementation examples for Go, Rust, Java, and other popular programming languages.

**Go Client:**

```go
// go-client.go - Go implementation
package main

import (
    "bytes"
    "context"
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "strings"
    "time"
)

type LocalLLMClient struct {
    BaseURL    string
    APIKey     string
    HTTPClient *http.Client
}

type ChatMessage struct {
    Role    string `json:"role"`
    Content string `json:"content"`
}

type ChatRequest struct {
    Model       string        `json:"model"`
    Messages    []ChatMessage `json:"messages"`
    Temperature float64       `json:"temperature,omitempty"`
    MaxTokens   int           `json:"max_tokens,omitempty"`
    Stream      bool          `json:"stream,omitempty"`
}

type ChatResponse struct {
    Choices []struct {
        Message struct {
            Role    string `json:"role"`
            Content string `json:"content"`
        } `json:"message"`
        Delta struct {
            Content string `json:"content"`
        } `json:"delta"`
    } `json:"choices"`
}

type Model struct {
    ID     string `json:"id"`
    Object string `json:"object"`
}

type ModelsResponse struct {
    Data []Model `json:"data"`
}

func NewLocalLLMClient(baseURL string, apiKey string) *LocalLLMClient {
    return &LocalLLMClient{
        BaseURL: strings.TrimSuffix(baseURL, "/"),
        APIKey:  apiKey,
        HTTPClient: &http.Client{
            Timeout: 120 * time.Second,
        },
    }
}

func (c *LocalLLMClient) request(ctx context.Context, method, endpoint string, body interface{}) (*http.Response, error) {
    var reqBody io.Reader
    if body != nil {
        jsonData, err := json.Marshal(body)
        if err != nil {
            return nil, fmt.Errorf("failed to marshal request body: %w", err)
        }
        reqBody = bytes.NewReader(jsonData)
    }

    req, err := http.NewRequestWithContext(ctx, method, c.BaseURL+endpoint, reqBody)
    if err != nil {
        return nil, fmt.Errorf("failed to create request: %w", err)
    }

    req.Header.Set("Content-Type", "application/json")
    if c.APIKey != "" {
        req.Header.Set("Authorization", "Bearer "+c.APIKey)
    }

    resp, err := c.HTTPClient.Do(req)
    if err != nil {
        return nil, fmt.Errorf("request failed: %w", err)
    }

    if resp.StatusCode >= 400 {
        resp.Body.Close()
        return nil, fmt.Errorf("HTTP %d: %s", resp.StatusCode, resp.Status)
    }

    return resp, nil
}

func (c *LocalLLMClient) ListModels(ctx context.Context) ([]string, error) {
    resp, err := c.request(ctx, "GET", "/v1/models", nil)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    var modelsResp ModelsResponse
    if err := json.NewDecoder(resp.Body).Decode(&modelsResp); err != nil {
        return nil, fmt.Errorf("failed to decode models response: %w", err)
    }

    models := make([]string, len(modelsResp.Data))
    for i, model := range modelsResp.Data {
        models[i] = model.ID
    }

    return models, nil
}

func (c *LocalLLMClient) ChatCompletion(ctx context.Context, messages []ChatMessage, model string, options map[string]interface{}) (string, error) {
    req := ChatRequest{
        Model:    model,
        Messages: messages,
        Stream:   false,
    }

    // Apply options
    if temp, ok := options["temperature"].(float64); ok {
        req.Temperature = temp
    }
    if maxTokens, ok := options["max_tokens"].(int); ok {
        req.MaxTokens = maxTokens
    }

    resp, err := c.request(ctx, "POST", "/v1/chat/completions", req)
    if err != nil {
        return "", err
    }
    defer resp.Body.Close()

    var chatResp ChatResponse
    if err := json.NewDecoder(resp.Body).Decode(&chatResp); err != nil {
        return "", fmt.Errorf("failed to decode chat response: %w", err)
    }

    if len(chatResp.Choices) == 0 {
        return "", fmt.Errorf("no choices in response")
    }

    return chatResp.Choices[0].Message.Content, nil
}

func (c *LocalLLMClient) StreamChatCompletion(ctx context.Context, messages []ChatMessage, model string, callback func(string)) error {
    req := ChatRequest{
        Model:    model,
        Messages: messages,
        Stream:   true,
    }

    resp, err := c.request(ctx, "POST", "/v1/chat/completions", req)
    if err != nil {
        return err
    }
    defer resp.Body.Close()

    scanner := bufio.NewScanner(resp.Body)
    for scanner.Scan() {
        line := scanner.Text()
        if strings.HasPrefix(line, "data: ") {
            data := strings.TrimPrefix(line, "data: ")
            if data == "[DONE]" {
                break
            }

            var chunk ChatResponse
            if err := json.Unmarshal([]byte(data), &chunk); err != nil {
                continue // Skip malformed chunks
            }

            if len(chunk.Choices) > 0 && chunk.Choices[0].Delta.Content != "" {
                callback(chunk.Choices[0].Delta.Content)
            }
        }
    }

    return scanner.Err()
}

func (c *LocalLLMClient) HealthCheck(ctx context.Context) bool {
    ctxWithTimeout, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()

    resp, err := c.request(ctxWithTimeout, "GET", "/health", nil)
    if err != nil {
        return false
    }
    defer resp.Body.Close()

    return resp.StatusCode == 200
}

// Usage example
func main() {
    client := NewLocalLLMClient("http://localhost:8080", "")
    ctx := context.Background()

    // Health check
    if !client.HealthCheck(ctx) {
        fmt.Println("Server is not healthy")
        return
    }
    fmt.Println("Server is healthy!")

    // List models
    models, err := client.ListModels(ctx)
    if err != nil {
        fmt.Printf("Error listing models: %v\n", err)
        return
    }
    fmt.Printf("Available models: %v\n", models)

    // Chat completion
    messages := []ChatMessage{
        {Role: "system", Content: "You are a helpful assistant."},
        {Role: "user", Content: "Explain Go concurrency patterns"},
    }

    response, err := client.ChatCompletion(ctx, messages, "llama-2-7b-chat", map[string]interface{}{
        "temperature": 0.7,
        "max_tokens":  150,
    })
    if err != nil {
        fmt.Printf("Chat completion error: %v\n", err)
        return
    }

    fmt.Printf("Response: %s\n", response)

    // Streaming example
    fmt.Println("\nStreaming response:")
    err = client.StreamChatCompletion(ctx, []ChatMessage{
        {Role: "user", Content: "Tell me about Go channels"},
    }, "llama-2-7b-chat", func(chunk string) {
        fmt.Print(chunk)
    })
    if err != nil {
        fmt.Printf("Streaming error: %v\n", err)
    }
}
```

**Rust Client:**

```rust
// rust-client/src/lib.rs - Rust implementation
use reqwest::{Client, Response};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::collections::HashMap;
use tokio_stream::{Stream, StreamExt};
use futures_core::stream::BoxStream;

#[derive(Debug, Clone)]
pub struct LocalLLMClient {
    base_url: String,
    api_key: Option<String>,
    client: Client,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ChatMessage {
    pub role: String,
    pub content: String,
}

#[derive(Debug, Serialize)]
struct ChatRequest {
    model: String,
    messages: Vec<ChatMessage>,
    #[serde(skip_serializing_if = "Option::is_none")]
    temperature: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    max_tokens: Option<u32>,
    #[serde(default)]
    stream: bool,
}

#[derive(Debug, Deserialize)]
pub struct ChatResponse {
    pub choices: Vec<Choice>,
}

#[derive(Debug, Deserialize)]
pub struct Choice {
    pub message: Option<ChatMessage>,
    pub delta: Option<Delta>,
}

#[derive(Debug, Deserialize)]
pub struct Delta {
    pub content: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct Model {
    pub id: String,
}

#[derive(Debug, Deserialize)]
pub struct ModelsResponse {
    pub data: Vec<Model>,
}

impl LocalLLMClient {
    pub fn new(base_url: String, api_key: Option<String>) -> Self {
        let client = Client::builder()
            .timeout(std::time::Duration::from_secs(120))
            .build()
            .expect("Failed to create HTTP client");

        Self {
            base_url: base_url.trim_end_matches('/').to_string(),
            api_key,
            client,
        }
    }

    async fn request(&self, method: reqwest::Method, endpoint: &str, body: Option<Value>) -> Result<Response, Box<dyn std::error::Error>> {
        let url = format!("{}{}", self.base_url, endpoint);
        let mut request = self.client.request(method, &url)
            .header("Content-Type", "application/json");

        if let Some(ref api_key) = self.api_key {
            request = request.bearer_auth(api_key);
        }

        if let Some(body) = body {
            request = request.json(&body);
        }

        let response = request.send().await?;
        
        if response.status().is_client_error() || response.status().is_server_error() {
            return Err(format!("HTTP {}: {}", response.status(), response.status().as_str()).into());
        }

        Ok(response)
    }

    pub async fn list_models(&self) -> Result<Vec<String>, Box<dyn std::error::Error>> {
        let response = self.request(reqwest::Method::GET, "/v1/models", None).await?;
        let models_response: ModelsResponse = response.json().await?;
        
        Ok(models_response.data.into_iter().map(|m| m.id).collect())
    }

    pub async fn chat_completion(
        &self,
        messages: Vec<ChatMessage>,
        model: &str,
        options: Option<HashMap<String, Value>>,
    ) -> Result<String, Box<dyn std::error::Error>> {
        let mut request = ChatRequest {
            model: model.to_string(),
            messages,
            temperature: None,
            max_tokens: None,
            stream: false,
        };

        if let Some(opts) = options {
            if let Some(temp) = opts.get("temperature").and_then(|v| v.as_f64()) {
                request.temperature = Some(temp);
            }
            if let Some(max_tokens) = opts.get("max_tokens").and_then(|v| v.as_u64()) {
                request.max_tokens = Some(max_tokens as u32);
            }
        }

        let response = self.request(
            reqwest::Method::POST,
            "/v1/chat/completions",
            Some(serde_json::to_value(request)?)
        ).await?;

        let chat_response: ChatResponse = response.json().await?;
        
        if let Some(choice) = chat_response.choices.first() {
            if let Some(message) = &choice.message {
                return Ok(message.content.clone());
            }
        }

        Err("No response content".into())
    }

    pub async fn stream_chat_completion(
        &self,
        messages: Vec<ChatMessage>,
        model: &str,
        options: Option<HashMap<String, Value>>,
    ) -> Result<BoxStream<'_, Result<String, Box<dyn std::error::Error + Send>>>, Box<dyn std::error::Error>> {
        let mut request = ChatRequest {
            model: model.to_string(),
            messages,
            temperature: None,
            max_tokens: None,
            stream: true,
        };

        if let Some(opts) = options {
            if let Some(temp) = opts.get("temperature").and_then(|v| v.as_f64()) {
                request.temperature = Some(temp);
            }
            if let Some(max_tokens) = opts.get("max_tokens").and_then(|v| v.as_u64()) {
                request.max_tokens = Some(max_tokens as u32);
            }
        }

        let response = self.request(
            reqwest::Method::POST,
            "/v1/chat/completions",
            Some(serde_json::to_value(request)?)
        ).await?;

        let stream = response.bytes_stream();
        
        let token_stream = stream.filter_map(|chunk_result| {
            async move {
                match chunk_result {
                    Ok(chunk) => {
                        let text = String::from_utf8_lossy(&chunk);
                        for line in text.lines() {
                            if line.starts_with("data: ") {
                                let data = &line[6..];
                                if data.trim() == "[DONE]" {
                                    return None;
                                }
                                
                                if let Ok(parsed) = serde_json::from_str::<ChatResponse>(data) {
                                    if let Some(choice) = parsed.choices.first() {
                                        if let Some(delta) = &choice.delta {
                                            if let Some(content) = &delta.content {
                                                return Some(Ok(content.clone()));
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Err(e) => return Some(Err(e.into())),
                }
                None
            }
        });

        Ok(Box::pin(token_stream))
    }

    pub async fn health_check(&self) -> bool {
        match tokio::time::timeout(
            std::time::Duration::from_secs(5),
            self.request(reqwest::Method::GET, "/health", None)
        ).await {
            Ok(Ok(_)) => true,
            _ => false,
        }
    }
}

// Usage example
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = LocalLLMClient::new("http://localhost:8080".to_string(), None);

    // Health check
    if !client.health_check().await {
        println!("Server is not healthy");
        return Ok(());
    }
    println!("Server is healthy!");

    // List models
    let models = client.list_models().await?;
    println!("Available models: {:?}", models);

    // Chat completion
    let messages = vec![
        ChatMessage {
            role: "system".to_string(),
            content: "You are a helpful assistant.".to_string(),
        },
        ChatMessage {
            role: "user".to_string(),
            content: "Explain Rust ownership".to_string(),
        },
    ];

    let response = client.chat_completion(
        messages.clone(),
        "llama-2-7b-chat",
        Some(HashMap::from([
            ("temperature".to_string(), json!(0.7)),
            ("max_tokens".to_string(), json!(150)),
        ]))
    ).await?;

    println!("Response: {}", response);

    // Streaming example
    println!("\nStreaming response:");
    let mut stream = client.stream_chat_completion(
        vec![ChatMessage {
            role: "user".to_string(),
            content: "Tell me about Rust async programming".to_string(),
        }],
        "llama-2-7b-chat",
        None
    ).await?;

    while let Some(token_result) = stream.next().await {
        match token_result {
            Ok(token) => print!("{}", token),
            Err(e) => eprintln!("Stream error: {}", e),
        }
    }

    Ok(())
}
```

**Java Client:**

```java
// LocalLLMClient.java - Java implementation
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.ObjectMapper;
import okhttp3.*;
import okhttp3.sse.EventSource;
import okhttp3.sse.EventSourceListener;
import okhttp3.sse.EventSources;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

public class LocalLLMClient {
    private final String baseUrl;
    private final String apiKey;
    private final OkHttpClient httpClient;
    private final ObjectMapper objectMapper;

    public LocalLLMClient(String baseUrl, String apiKey) {
        this.baseUrl = baseUrl.replaceAll("/$", "");
        this.apiKey = apiKey;
        this.objectMapper = new ObjectMapper();
        
        this.httpClient = new OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(120, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build();
    }

    public static class ChatMessage {
        public String role;
        public String content;

        public ChatMessage() {}

        public ChatMessage(String role, String content) {
            this.role = role;
            this.content = content;
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class ChatRequest {
        public String model;
        public List<ChatMessage> messages;
        public Double temperature;
        @JsonProperty("max_tokens")
        public Integer maxTokens;
        public Boolean stream = false;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class ChatResponse {
        public List<Choice> choices;

        public static class Choice {
            public ChatMessage message;
            public Delta delta;
        }

        public static class Delta {
            public String content;
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class ModelsResponse {
        public List<Model> data;

        public static class Model {
            public String id;
        }
    }

    private Request.Builder createRequest(String endpoint) {
        Request.Builder builder = new Request.Builder()
            .url(baseUrl + endpoint)
            .header("Content-Type", "application/json");

        if (apiKey != null && !apiKey.isEmpty()) {
            builder.header("Authorization", "Bearer " + apiKey);
        }

        return builder;
    }

    public CompletableFuture<List<String>> listModels() {
        CompletableFuture<List<String>> future = new CompletableFuture<>();

        Request request = createRequest("/v1/models").build();

        httpClient.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                future.completeExceptionally(e);
            }

            @Override
            public void onResponse(Call call, Response response) throws IOException {
                try (ResponseBody body = response.body()) {
                    if (!response.isSuccessful()) {
                        future.completeExceptionally(new IOException("HTTP " + response.code()));
                        return;
                    }

                    ModelsResponse modelsResponse = objectMapper.readValue(
                        body.string(), ModelsResponse.class
                    );
                    
                    List<String> modelIds = modelsResponse.data.stream()
                        .map(model -> model.id)
                        .toList();
                    
                    future.complete(modelIds);
                } catch (Exception e) {
                    future.completeExceptionally(e);
                }
            }
        });

        return future;
    }

    public CompletableFuture<String> chatCompletion(
        List<ChatMessage> messages, 
        String model, 
        Map<String, Object> options
    ) {
        CompletableFuture<String> future = new CompletableFuture<>();

        ChatRequest request = new ChatRequest();
        request.model = model;
        request.messages = messages;
        request.stream = false;

        if (options != null) {
            if (options.containsKey("temperature")) {
                request.temperature = ((Number) options.get("temperature")).doubleValue();
            }
            if (options.containsKey("max_tokens")) {
                request.maxTokens = ((Number) options.get("max_tokens")).intValue();
            }
        }

        try {
            String json = objectMapper.writeValueAsString(request);
            RequestBody body = RequestBody.create(json, MediaType.get("application/json"));
            
            Request httpRequest = createRequest("/v1/chat/completions")
                .post(body)
                .build();

            httpClient.newCall(httpRequest).enqueue(new Callback() {
                @Override
                public void onFailure(Call call, IOException e) {
                    future.completeExceptionally(e);
                }

                @Override
                public void onResponse(Call call, Response response) throws IOException {
                    try (ResponseBody responseBody = response.body()) {
                        if (!response.isSuccessful()) {
                            future.completeExceptionally(new IOException("HTTP " + response.code()));
                            return;
                        }

                        ChatResponse chatResponse = objectMapper.readValue(
                            responseBody.string(), ChatResponse.class
                        );

                        if (chatResponse.choices != null && !chatResponse.choices.isEmpty()) {
                            ChatResponse.Choice choice = chatResponse.choices.get(0);
                            if (choice.message != null) {
                                future.complete(choice.message.content);
                                return;
                            }
                        }

                        future.completeExceptionally(new IOException("No response content"));
                    } catch (Exception e) {
                        future.completeExceptionally(e);
                    }
                }
            });

        } catch (Exception e) {
            future.completeExceptionally(e);
        }

        return future;
    }

    public CompletableFuture<Void> streamChatCompletion(
        List<ChatMessage> messages,
        String model,
        Map<String, Object> options,
        Consumer<String> tokenCallback
    ) {
        CompletableFuture<Void> future = new CompletableFuture<>();

        ChatRequest request = new ChatRequest();
        request.model = model;
        request.messages = messages;
        request.stream = true;

        if (options != null) {
            if (options.containsKey("temperature")) {
                request.temperature = ((Number) options.get("temperature")).doubleValue();
            }
            if (options.containsKey("max_tokens")) {
                request.maxTokens = ((Number) options.get("max_tokens")).intValue();
            }
        }

        try {
            String json = objectMapper.writeValueAsString(request);
            RequestBody body = RequestBody.create(json, MediaType.get("application/json"));
            
            Request httpRequest = createRequest("/v1/chat/completions")
                .post(body)
                .build();

            EventSourceListener listener = new EventSourceListener() {
                @Override
                public void onEvent(EventSource eventSource, String id, String type, String data) {
                    if ("[DONE]".equals(data.trim())) {
                        eventSource.cancel();
                        future.complete(null);
                        return;
                    }

                    try {
                        ChatResponse chunk = objectMapper.readValue(data, ChatResponse.class);
                        if (chunk.choices != null && !chunk.choices.isEmpty()) {
                            ChatResponse.Choice choice = chunk.choices.get(0);
                            if (choice.delta != null && choice.delta.content != null) {
                                tokenCallback.accept(choice.delta.content);
                            }
                        }
                    } catch (Exception e) {
                        // Ignore parsing errors for partial chunks
                    }
                }

                @Override
                public void onFailure(EventSource eventSource, Throwable t, Response response) {
                    future.completeExceptionally(t);
                }

                @Override
                public void onClosed(EventSource eventSource) {
                    if (!future.isDone()) {
                        future.complete(null);
                    }
                }
            };

            EventSource eventSource = EventSources.createFactory(httpClient)
                .newEventSource(httpRequest, listener);

        } catch (Exception e) {
            future.completeExceptionally(e);
        }

        return future;
    }

    public CompletableFuture<Boolean> healthCheck() {
        CompletableFuture<Boolean> future = new CompletableFuture<>();

        Request request = createRequest("/health").build();

        httpClient.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                future.complete(false);
            }

            @Override
            public void onResponse(Call call, Response response) {
                future.complete(response.isSuccessful());
                response.close();
            }
        });

        return future;
    }

    // Usage example
    public static void main(String[] args) throws Exception {
        LocalLLMClient client = new LocalLLMClient("http://localhost:8080", null);

        // Health check
        boolean healthy = client.healthCheck().get();
        System.out.println("Server healthy: " + healthy);

        if (healthy) {
            // List models
            List<String> models = client.listModels().get();
            System.out.println("Available models: " + models);

            // Chat completion
            List<ChatMessage> messages = List.of(
                new ChatMessage("system", "You are a helpful assistant."),
                new ChatMessage("user", "Explain Java streams")
            );

            String response = client.chatCompletion(
                messages, 
                "llama-2-7b-chat",
                Map.of("temperature", 0.7, "max_tokens", 150)
            ).get();

            System.out.println("Response: " + response);

            // Streaming example
            System.out.println("\nStreaming response:");
            client.streamChatCompletion(
                List.of(new ChatMessage("user", "Tell me about Java concurrency")),
                "llama-2-7b-chat",
                null,
                token -> System.out.print(token)
            ).get();
        }
    }
}
```

## Framework Integration

Integration with popular AI and machine learning frameworks for enhanced functionality and workflow orchestration.

### LangChain

LangChain is a powerful framework for developing applications with language models, providing chains, agents, and memory capabilities.

**Setting up LangChain with Local LLMs:**

```python
# langchain_integration.py - LangChain with local LLM
from langchain.llms.base import LLM
from langchain.callbacks.manager import CallbackManagerForLLMRun
from langchain.chains import LLMChain, ConversationChain
from langchain.agents import initialize_agent, Tool, AgentType
from langchain.memory import ConversationBufferMemory, ConversationSummaryMemory
from langchain.prompts import PromptTemplate
from langchain.schema import Generation, LLMResult
from typing import Optional, List, Any, Dict
import requests
import json

class LocalLLM(LLM):
    """Custom LangChain LLM wrapper for local APIs"""
    
    base_url: str = "http://localhost:8080"
    model_name: str = "llama-2-7b-chat"
    temperature: float = 0.7
    max_tokens: int = 150
    api_key: Optional[str] = None
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
    
    @property
    def _llm_type(self) -> str:
        return "local_llm"
    
    def _call(
        self,
        prompt: str,
        stop: Optional[List[str]] = None,
        run_manager: Optional[CallbackManagerForLLMRun] = None,
        **kwargs: Any,
    ) -> str:
        """Call the local LLM API"""
        headers = {"Content-Type": "application/json"}
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"
        
        payload = {
            "model": self.model_name,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": self.temperature,
            "max_tokens": self.max_tokens,
            "stream": False
        }
        
        if stop:
            payload["stop"] = stop
        
        try:
            response = requests.post(
                f"{self.base_url}/v1/chat/completions",
                headers=headers,
                json=payload,
                timeout=120
            )
            response.raise_for_status()
            
            result = response.json()
            return result["choices"][0]["message"]["content"]
        except Exception as e:
            return f"Error: {str(e)}"
    
    def _generate(
        self,
        prompts: List[str],
        stop: Optional[List[str]] = None,
        run_manager: Optional[CallbackManagerForLLMRun] = None,
        **kwargs: Any,
    ) -> LLMResult:
        """Generate responses for multiple prompts"""
        generations = []
        for prompt in prompts:
            text = self._call(prompt, stop, run_manager, **kwargs)
            generations.append([Generation(text=text)])
        
        return LLMResult(generations=generations)

# Initialize the local LLM
local_llm = LocalLLM(
    base_url="http://localhost:8080",
    model_name="llama-2-7b-chat",
    temperature=0.7,
    max_tokens=200
)

# Basic chain example
from langchain.chains import LLMChain
from langchain.prompts import PromptTemplate

template = """
You are a helpful AI assistant. Answer the following question thoughtfully and accurately.

Question: {question}
Answer:"""

prompt = PromptTemplate(template=template, input_variables=["question"])
chain = LLMChain(llm=local_llm, prompt=prompt)

# Run the chain
response = chain.run(question="What are the benefits of renewable energy?")
print(f"Response: {response}")

# Conversation chain with memory
conversation_memory = ConversationBufferMemory()
conversation_chain = ConversationChain(
    llm=local_llm,
    memory=conversation_memory,
    verbose=True
)

# Interactive conversation
print("Starting conversation (type 'quit' to exit):")
while True:
    user_input = input("You: ")
    if user_input.lower() == 'quit':
        break
    
    response = conversation_chain.predict(input=user_input)
    print(f"AI: {response}")

# Custom tools for agents
def search_tool(query: str) -> str:
    """Mock search tool - replace with actual search implementation"""
    return f"Search results for '{query}': This is mock search data."

def calculator_tool(expression: str) -> str:
    """Simple calculator tool"""
    try:
        result = eval(expression)  # Note: Use safe eval in production
        return str(result)
    except Exception as e:
        return f"Error calculating {expression}: {str(e)}"

# Define tools for the agent
tools = [
    Tool(
        name="Search",
        func=search_tool,
        description="Search for information on the internet. Input should be a search query."
    ),
    Tool(
        name="Calculator", 
        func=calculator_tool,
        description="Perform mathematical calculations. Input should be a mathematical expression."
    )
]

# Initialize agent
agent = initialize_agent(
    tools=tools,
    llm=local_llm,
    agent=AgentType.ZERO_SHOT_REACT_DESCRIPTION,
    verbose=True,
    max_iterations=3
)

# Run agent
agent_response = agent.run("What is 25 * 17, and then search for information about that number")
print(f"Agent response: {agent_response}")
```

**Advanced LangChain Patterns:**

```python
# advanced_langchain.py - Complex chains and workflows
from langchain.chains import SequentialChain, TransformChain
from langchain.chains.router import MultiPromptChain, MultiRetrievalQAChain
from langchain.chains.router.llm_router import LLMRouterChain, RouterOutputParser
from langchain.vectorstores import Chroma
from langchain.embeddings import HuggingFaceEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.document_loaders import TextLoader
from langchain.chains import RetrievalQA

# Document processing pipeline
class DocumentProcessor:
    def __init__(self, local_llm):
        self.llm = local_llm
        self.embeddings = HuggingFaceEmbeddings(
            model_name="sentence-transformers/all-MiniLM-L6-v2"
        )
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200
        )
    
    def process_documents(self, file_paths: List[str]) -> Chroma:
        """Load, split, and embed documents"""
        documents = []
        for file_path in file_paths:
            loader = TextLoader(file_path)
            docs = loader.load()
            documents.extend(docs)
        
        # Split documents
        texts = self.text_splitter.split_documents(documents)
        
        # Create vector store
        vectorstore = Chroma.from_documents(
            documents=texts,
            embedding=self.embeddings,
            persist_directory="./chroma_db"
        )
        
        return vectorstore
    
    def create_qa_chain(self, vectorstore: Chroma):
        """Create Q&A chain with retrieval"""
        return RetrievalQA.from_chain_type(
            llm=self.llm,
            chain_type="stuff",
            retriever=vectorstore.as_retriever(search_kwargs={"k": 4}),
            return_source_documents=True
        )

# Multi-step processing chain
def create_analysis_pipeline(local_llm):
    # Step 1: Summarization
    summarize_template = """
    Summarize the following text in 2-3 sentences:
    
    Text: {text}
    Summary:"""
    
    summarize_prompt = PromptTemplate(
        template=summarize_template,
        input_variables=["text"]
    )
    summarize_chain = LLMChain(
        llm=local_llm,
        prompt=summarize_prompt,
        output_key="summary"
    )
    
    # Step 2: Sentiment analysis
    sentiment_template = """
    Analyze the sentiment of the following text. Respond with only: POSITIVE, NEGATIVE, or NEUTRAL
    
    Text: {summary}
    Sentiment:"""
    
    sentiment_prompt = PromptTemplate(
        template=sentiment_template,
        input_variables=["summary"]
    )
    sentiment_chain = LLMChain(
        llm=local_llm,
        prompt=sentiment_prompt,
        output_key="sentiment"
    )
    
    # Step 3: Generate recommendations
    recommendations_template = """
    Based on the summary and sentiment, provide 3 actionable recommendations:
    
    Summary: {summary}
    Sentiment: {sentiment}
    
    Recommendations:"""
    
    recommendations_prompt = PromptTemplate(
        template=recommendations_template,
        input_variables=["summary", "sentiment"]
    )
    recommendations_chain = LLMChain(
        llm=local_llm,
        prompt=recommendations_prompt,
        output_key="recommendations"
    )
    
    # Combine into sequential chain
    overall_chain = SequentialChain(
        chains=[summarize_chain, sentiment_chain, recommendations_chain],
        input_variables=["text"],
        output_variables=["summary", "sentiment", "recommendations"],
        verbose=True
    )
    
    return overall_chain

# Router chain for different types of queries
def create_router_chain(local_llm):
    # Define specialized chains for different domains
    code_template = """
    You are an expert programmer. Answer this coding question:
    
    Question: {input}
    Answer:"""
    
    science_template = """
    You are a science expert. Explain this scientific concept clearly:
    
    Question: {input}
    Answer:"""
    
    general_template = """
    You are a helpful assistant. Answer this general question:
    
    Question: {input}
    Answer:"""
    
    # Create prompt infos
    prompt_infos = [
        {
            "name": "coding",
            "description": "Good for answering programming and technical questions",
            "prompt_template": code_template
        },
        {
            "name": "science", 
            "description": "Good for answering scientific questions",
            "prompt_template": science_template
        },
        {
            "name": "general",
            "description": "Good for general questions and conversations",
            "prompt_template": general_template
        }
    ]
    
    # Create destination chains
    destination_chains = {}
    for p_info in prompt_infos:
        name = p_info["name"]
        prompt_template = p_info["prompt_template"]
        prompt = PromptTemplate(template=prompt_template, input_variables=["input"])
        chain = LLMChain(llm=local_llm, prompt=prompt)
        destination_chains[name] = chain
    
    # Create router chain
    destinations = [f"{p['name']}: {p['description']}" for p in prompt_infos]
    destinations_str = "\n".join(destinations)
    
    router_template = f"""Given a raw text input to a language model select the model prompt best suited for the input. You will be given the names of the available prompts and a description of what the prompt is best suited for.

<< FORMATTING >>
Return a markdown code block with a JSON object formatted to look like:
```json
{{{{
    "destination": string \\ name of the prompt to use or "DEFAULT"
    "next_inputs": string \\ a potentially modified version of the original input
}}}}
```

    REMEMBER: "destination" MUST be one of the candidate prompt names specified below OR it can be "DEFAULT" if the input is not well suited for any of the candidate prompts.
    REMEMBER: "next_inputs" can just be the original input if you don't think any modifications are needed.

    << CANDIDATE PROMPTS >>
    {destinations_str}

    << INPUT >>
    {{input}}

    << OUTPUT >>"""

    router_prompt = PromptTemplate(
        template=router_template,
        input_variables=["input"],
    )
    
    router_chain = LLMRouterChain.from_llm(local_llm, router_prompt)
    
    return MultiPromptChain(
        router_chain=router_chain,
        destination_chains=destination_chains,
        default_chain=destination_chains["general"],
        verbose=True
    )

# Usage examples

if __name__ == "__main__":
    local_llm = LocalLLM()
    
    # Document processing
    processor = DocumentProcessor(local_llm)
    # vectorstore = processor.process_documents(["document1.txt", "document2.txt"])
    # qa_chain = processor.create_qa_chain(vectorstore)
    
    # Analysis pipeline
    analysis_chain = create_analysis_pipeline(local_llm)
    sample_text = "The new product launch was successful beyond expectations..."
    result = analysis_chain({"text": sample_text})
    print("Analysis Result:", result)
    
    # Router chain
    router = create_router_chain(local_llm)
    coding_response = router.run("How do I sort a list in Python?")
    science_response = router.run("Explain photosynthesis")
    general_response = router.run("What's the weather like today?")
```

### LlamaIndex

LlamaIndex (formerly GPT Index) specializes in connecting LLMs with external data sources and building retrieval-augmented generation (RAG) applications.

**Basic LlamaIndex Setup:**

```python
# llamaindex_integration.py - LlamaIndex with local LLMs
from llama_index.core import VectorStoreIndex, Document, Settings
from llama_index.core.node_parser import SentenceSplitter
from llama_index.core.query_engine import RetrieverQueryEngine
from llama_index.core.retrievers import VectorIndexRetriever
from llama_index.core.postprocessor import SimilarityPostprocessor
from llama_index.embeddings.huggingface import HuggingFaceEmbedding
from llama_index.llms.openai_like import OpenAILike
from llama_index.core.callbacks import CallbackManager, LlamaDebugHandler
from typing import List, Optional
import os

class LocalLlamaIndexSetup:
    def __init__(self, base_url: str = "http://localhost:8080", model: str = "llama-2-7b-chat"):
        # Configure local LLM
        self.llm = OpenAILike(
            model=model,
            api_base=f"{base_url}/v1",
            api_key="not-needed",
            is_chat_model=True,
            context_window=4096,
            max_tokens=512,
            temperature=0.7
        )
        
        # Configure embeddings (local)
        self.embed_model = HuggingFaceEmbedding(
            model_name="sentence-transformers/all-MiniLM-L6-v2",
            device="cpu"  # Use "cuda" if available
        )
        
        # Configure global settings
        Settings.llm = self.llm
        Settings.embed_model = self.embed_model
        Settings.node_parser = SentenceSplitter(chunk_size=1024, chunk_overlap=20)
        
        # Set up debugging
        self.debug_handler = LlamaDebugHandler(print_trace_on_end=True)
        Settings.callback_manager = CallbackManager([self.debug_handler])
    
    def create_index_from_documents(self, documents: List[Document]) -> VectorStoreIndex:
        """Create vector index from documents"""
        index = VectorStoreIndex.from_documents(
            documents,
            show_progress=True
        )
        return index
    
    def create_index_from_text_files(self, file_paths: List[str]) -> VectorStoreIndex:
        """Create index from text files"""
        documents = []
        for file_path in file_paths:
            with open(file_path, 'r', encoding='utf-8') as file:
                text = file.read()
                doc = Document(
                    text=text,
                    metadata={"source": file_path, "filename": os.path.basename(file_path)}
                )
                documents.append(doc)
        
        return self.create_index_from_documents(documents)
    
    def create_query_engine(self, index: VectorStoreIndex, similarity_top_k: int = 5):
        """Create query engine with custom retriever"""
        retriever = VectorIndexRetriever(
            index=index,
            similarity_top_k=similarity_top_k
        )
        
        # Add post-processors
        postprocessor = SimilarityPostprocessor(similarity_cutoff=0.7)
        
        query_engine = RetrieverQueryEngine(
            retriever=retriever,
            node_postprocessors=[postprocessor]
        )
        
        return query_engine

# Usage examples
def demonstrate_basic_usage():
    """Basic LlamaIndex usage with local LLM"""
    # Initialize setup
    setup = LocalLlamaIndexSetup("http://localhost:8080", "llama-2-7b-chat")
    
    # Create sample documents
    documents = [
        Document(text="Climate change is affecting global weather patterns, leading to more extreme events.", metadata={"topic": "climate"}),
        Document(text="Renewable energy sources like solar and wind are becoming more cost-effective.", metadata={"topic": "energy"}),
        Document(text="Machine learning algorithms can help predict and mitigate climate impacts.", metadata={"topic": "technology"}),
        Document(text="Electric vehicles are reducing transportation emissions significantly.", metadata={"topic": "transportation"})
    ]
    
    # Create index
    print("Creating vector index...")
    index = setup.create_index_from_documents(documents)
    
    # Create query engine
    query_engine = setup.create_query_engine(index, similarity_top_k=3)
    
    # Run queries
    queries = [
        "How is climate change affecting weather?",
        "What are the benefits of renewable energy?",
        "How can technology help with climate issues?",
        "Tell me about electric vehicles and emissions"
    ]
    
    for query in queries:
        print(f"\nQuery: {query}")
        response = query_engine.query(query)
        print(f"Response: {response}")
        print(f"Sources: {[node.metadata for node in response.source_nodes]}")

# Advanced RAG with custom retrievers and reranking
from llama_index.core.schema import NodeWithScore
from llama_index.core.retrievers import BaseRetriever
from llama_index.core import QueryBundle
import torch
from sentence_transformers import CrossEncoder

class HybridRetriever(BaseRetriever):
    """Custom retriever combining vector similarity and keyword search"""
    
    def __init__(self, vector_retriever, bm25_retriever=None, alpha: float = 0.7):
        self.vector_retriever = vector_retriever
        self.bm25_retriever = bm25_retriever
        self.alpha = alpha
        super().__init__()
    
    def _retrieve(self, query_bundle: QueryBundle) -> List[NodeWithScore]:
        """Retrieve using hybrid approach"""
        # Get vector similarity results
        vector_nodes = self.vector_retriever.retrieve(query_bundle)
        
        # If BM25 retriever is available, combine results
        if self.bm25_retriever:
            bm25_nodes = self.bm25_retriever.retrieve(query_bundle)
            
            # Combine and rerank
            all_nodes = {}
            
            # Add vector results with weight
            for node in vector_nodes:
                node_id = node.node.node_id
                all_nodes[node_id] = NodeWithScore(
                    node=node.node,
                    score=self.alpha * node.score
                )
            
            # Add BM25 results with weight
            for node in bm25_nodes:
                node_id = node.node.node_id
                if node_id in all_nodes:
                    all_nodes[node_id].score += (1 - self.alpha) * node.score
                else:
                    all_nodes[node_id] = NodeWithScore(
                        node=node.node,
                        score=(1 - self.alpha) * node.score
                    )
            
            # Sort by combined score
            combined_nodes = sorted(
                all_nodes.values(),
                key=lambda x: x.score,
                reverse=True
            )
            
            return combined_nodes[:10]  # Return top 10
        
        return vector_nodes

class RerankerPostProcessor:
    """Rerank retrieved nodes using cross-encoder model"""
    
    def __init__(self, model_name: str = "cross-encoder/ms-marco-MiniLM-L-6-v2"):
        self.cross_encoder = CrossEncoder(model_name)
    
    def postprocess_nodes(self, nodes: List[NodeWithScore], query_str: str) -> List[NodeWithScore]:
        """Rerank nodes using cross-encoder"""
        if not nodes:
            return nodes
        
        # Prepare pairs for cross-encoder
        pairs = [(query_str, node.node.text) for node in nodes]
        
        # Get similarity scores
        scores = self.cross_encoder.predict(pairs)
        
        # Update node scores
        for i, node in enumerate(nodes):
            node.score = float(scores[i])
        
        # Sort by new scores
        reranked_nodes = sorted(nodes, key=lambda x: x.score, reverse=True)
        
        return reranked_nodes

# Advanced query engine with custom components
def create_advanced_rag_system():
    """Create advanced RAG system with reranking"""
    setup = LocalLlamaIndexSetup()
    
    # Load documents (example with multiple sources)
    documents = [
        Document(text="Solar panels convert sunlight directly into electricity using photovoltaic cells.", metadata={"source": "renewable_energy.txt", "category": "solar"}),
        Document(text="Wind turbines harness kinetic energy from moving air to generate electricity.", metadata={"source": "renewable_energy.txt", "category": "wind"}),
        Document(text="Hydroelectric power uses flowing water to turn turbines and generate electricity.", metadata={"source": "renewable_energy.txt", "category": "hydro"}),
        Document(text="Battery storage systems help stabilize renewable energy output by storing excess power.", metadata={"source": "energy_storage.txt", "category": "storage"}),
        Document(text="Smart grids use digital technology to manage electricity distribution efficiently.", metadata={"source": "smart_grid.txt", "category": "grid"}),
    ]
    
    # Create index
    index = setup.create_index_from_documents(documents)
    
    # Create hybrid retriever
    vector_retriever = VectorIndexRetriever(index=index, similarity_top_k=8)
    hybrid_retriever = HybridRetriever(vector_retriever, alpha=0.8)
    
    # Create reranker
    reranker = RerankerPostProcessor()
    
    # Custom query engine with reranking
    query_engine = RetrieverQueryEngine(
        retriever=hybrid_retriever,
        node_postprocessors=[
            lambda nodes, query: reranker.postprocess_nodes(nodes, query.query_str)
        ]
    )
    
    return query_engine, index

# Multi-document chat engine
from llama_index.core.chat_engine import CondensePlusContextChatEngine
from llama_index.core.memory import ChatMemoryBuffer

def create_chat_engine():
    """Create conversational RAG system"""
    setup = LocalLlamaIndexSetup()
    
    # Create index (example with technical documentation)
    documents = [
        Document(text="API authentication requires a valid API key in the Authorization header.", metadata={"doc": "api_guide"}),
        Document(text="Rate limiting is enforced at 1000 requests per hour per API key.", metadata={"doc": "api_guide"}),
        Document(text="WebSocket connections provide real-time streaming of model responses.", metadata={"doc": "api_guide"}),
        Document(text="Model parameters include temperature, max_tokens, and stop sequences.", metadata={"doc": "model_config"}),
        Document(text="Error handling should include retry logic with exponential backoff.", metadata={"doc": "best_practices"}),
    ]
    
    index = setup.create_index_from_documents(documents)
    
    # Create chat engine with memory
    memory = ChatMemoryBuffer.from_defaults(token_limit=3000)
    
    chat_engine = CondensePlusContextChatEngine.from_defaults(
        index.as_retriever(similarity_top_k=3),
        memory=memory,
        system_prompt=(
            "You are a helpful assistant that answers questions based on the provided documentation. "
            "Always cite the source of your information and ask follow-up questions when appropriate."
        ),
        verbose=True
    )
    
    return chat_engine

# Usage demonstration
if __name__ == "__main__":
    # Basic demonstration
    print("=== Basic LlamaIndex Demo ===")
    demonstrate_basic_usage()
    
    # Advanced RAG
    print("\n=== Advanced RAG Demo ===")
    query_engine, index = create_advanced_rag_system()
    
    response = query_engine.query("How do solar panels and wind turbines work together in renewable energy systems?")
    print(f"Advanced RAG Response: {response}")
    
    # Chat engine demo
    print("\n=== Chat Engine Demo ===")
    chat_engine = create_chat_engine()
    
    # Simulate conversation
    response1 = chat_engine.chat("How do I authenticate API requests?")
    print(f"Chat 1: {response1}")
    
    response2 = chat_engine.chat("What about rate limiting?")
    print(f"Chat 2: {response2}")
    
    response3 = chat_engine.chat("Can you give me a complete example of making an authenticated request with error handling?")
    print(f"Chat 3: {response3}")
```

## Haystack

Haystack is an end-to-end NLP framework for building production-ready search systems and question-answering applications.

**Haystack Integration:**

```python
# haystack_integration.py - Haystack with local LLMs
from haystack import Pipeline
from haystack.components.generators import OpenAIGenerator
from haystack.components.builders import PromptBuilder
from haystack.components.retrievers import InMemoryBM25Retriever
from haystack.components.embedders import SentenceTransformersTextEmbedder, SentenceTransformersDocumentEmbedder
from haystack.components.retrievers import InMemoryEmbeddingRetriever
from haystack.components.joiners import DocumentJoiner
from haystack.components.rankers import TransformersSimilarityRanker
from haystack.document_stores import InMemoryDocumentStore
from haystack.dataclasses import Document
from haystack.utils import ComponentConfig
from typing import List, Dict, Any
import os

class LocalHaystackLLM:
    """Haystack wrapper for local LLM APIs"""
    
    def __init__(self, base_url: str = "http://localhost:8080", model: str = "llama-2-7b-chat"):
        # Configure OpenAI-compatible generator for local LLM
        self.generator = OpenAIGenerator(
            api_key="not-needed",
            model=model,
            api_base_url=f"{base_url}/v1",
            generation_kwargs={
                "temperature": 0.7,
                "max_tokens": 512
            }
        )
        
        # Set up document store
        self.document_store = InMemoryDocumentStore()
        
        # Set up embedders
        self.text_embedder = SentenceTransformersTextEmbedder(
            model="sentence-transformers/all-MiniLM-L6-v2"
        )
        self.doc_embedder = SentenceTransformersDocumentEmbedder(
            model="sentence-transformers/all-MiniLM-L6-v2"
        )
    
    def create_rag_pipeline(self) -> Pipeline:
        """Create Retrieval-Augmented Generation pipeline"""
        
        # Template for RAG
        template = """
        Answer the question based on the provided context. If you cannot answer based on the context, say so.
        
        Context:
        {% for document in documents %}
        {{ document.content }}
        {% endfor %}
        
        Question: {{ question }}
        Answer:
        """
        
        # Build pipeline
        rag_pipeline = Pipeline()
        
        # Add components
        rag_pipeline.add_component("embedder", self.text_embedder)
        rag_pipeline.add_component("retriever", InMemoryEmbeddingRetriever(document_store=self.document_store))
        rag_pipeline.add_component("prompt_builder", PromptBuilder(template=template))
        rag_pipeline.add_component("llm", self.generator)
        
        # Connect components
        rag_pipeline.connect("embedder.embedding", "retriever.query_embedding")
        rag_pipeline.connect("retriever", "prompt_builder.documents")
        rag_pipeline.connect("prompt_builder", "llm")
        
        return rag_pipeline
    
    def create_hybrid_retrieval_pipeline(self) -> Pipeline:
        """Create hybrid retrieval pipeline combining BM25 and embeddings"""
        
        template = """
        Based on the following documents, provide a comprehensive answer to the question.
        
        Documents:
        {% for document in documents %}
        Document {{ loop.index }}:
        {{ document.content }}
        Source: {{ document.meta.get("source", "Unknown") }}
        
        {% endfor %}
        
        Question: {{ question }}
        
        Please provide a detailed answer and cite the relevant sources.
        Answer:
        """
        
        pipeline = Pipeline()
        
        # Add retrieval components
        pipeline.add_component("text_embedder", self.text_embedder)
        pipeline.add_component("embedding_retriever", InMemoryEmbeddingRetriever(document_store=self.document_store))
        pipeline.add_component("bm25_retriever", InMemoryBM25Retriever(document_store=self.document_store))
        
        # Add document processing
        pipeline.add_component("document_joiner", DocumentJoiner())
        pipeline.add_component("ranker", TransformersSimilarityRanker(model="cross-encoder/ms-marco-MiniLM-L-6-v2"))
        
        # Add generation
        pipeline.add_component("prompt_builder", PromptBuilder(template=template))
        pipeline.add_component("llm", self.generator)
        
        # Connect embedding path
        pipeline.connect("text_embedder.embedding", "embedding_retriever.query_embedding")
        
        # Connect BM25 path  
        pipeline.connect("bm25_retriever", "document_joiner.documents")
        pipeline.connect("embedding_retriever", "document_joiner.documents")
        
        # Connect reranking and generation
        pipeline.connect("document_joiner", "ranker.documents")
        pipeline.connect("ranker", "prompt_builder.documents")
        pipeline.connect("prompt_builder", "llm")
        
        return pipeline
    
    def index_documents(self, documents: List[Document]) -> None:
        """Index documents in the document store"""
        # Embed documents
        embedded_docs = self.doc_embedder.run(documents=documents)
        
        # Write to document store
        self.document_store.write_documents(embedded_docs["documents"])
        print(f"Indexed {len(documents)} documents")
    
    def create_chat_pipeline(self) -> Pipeline:
        """Create conversational pipeline with memory"""
        
        chat_template = """
        You are a helpful AI assistant. Use the provided context to answer questions accurately.
        
        Context:
        {% for document in documents %}
        {{ document.content }}
        {% endfor %}
        
        Conversation History:
        {{ chat_history }}
        
        Current Question: {{ question }}
        
        Provide a helpful and accurate response based on the context and conversation history.
        Answer:
        """
        
        pipeline = Pipeline()
        
        # Add components for chat
        pipeline.add_component("embedder", self.text_embedder)
        pipeline.add_component("retriever", InMemoryEmbeddingRetriever(document_store=self.document_store, top_k=5))
        pipeline.add_component("prompt_builder", PromptBuilder(template=chat_template))
        pipeline.add_component("llm", self.generator)
        
        # Connect components
        pipeline.connect("embedder.embedding", "retriever.query_embedding")
        pipeline.connect("retriever", "prompt_builder.documents")
        pipeline.connect("prompt_builder", "llm")
        
        return pipeline

# Specialized pipelines for different use cases
class SpecializedPipelines:
    """Collection of specialized Haystack pipelines"""
    
    def __init__(self, haystack_llm: LocalHaystackLLM):
        self.haystack_llm = haystack_llm
    
    def create_summarization_pipeline(self) -> Pipeline:
        """Create document summarization pipeline"""
        
        summary_template = """
        Please provide a concise summary of the following documents:
        
        {% for document in documents %}
        Document {{ loop.index }}:
        {{ document.content }}
        
        {% endfor %}
        
        Summary should be:
        - Comprehensive yet concise
        - Highlighting key points
        - Maximum 200 words
        
        Summary:
        """
        
        pipeline = Pipeline()
        pipeline.add_component("prompt_builder", PromptBuilder(template=summary_template))
        pipeline.add_component("llm", self.haystack_llm.generator)
        pipeline.connect("prompt_builder", "llm")
        
        return pipeline
    
    def create_classification_pipeline(self) -> Pipeline:
        """Create document classification pipeline"""
        
        classification_template = """
        Classify the following document into one of these categories:
        - Technology
        - Science
        - Business
        - Health
        - Education
        - Other
        
        Document: {{ document }}
        
        Provide only the category name as your response.
        Category:
        """
        
        pipeline = Pipeline()
        pipeline.add_component("prompt_builder", PromptBuilder(template=classification_template))
        pipeline.add_component("llm", self.haystack_llm.generator)
        pipeline.connect("prompt_builder", "llm")
        
        return pipeline
    
    def create_fact_checking_pipeline(self) -> Pipeline:
        """Create fact-checking pipeline"""
        
        fact_check_template = """
        Based on the provided reference documents, verify the following claim:
        
        Claim: {{ claim }}
        
        Reference Documents:
        {% for document in documents %}
        {{ document.content }}
        {% endfor %}
        
        Please respond with:
        1. SUPPORTED, CONTRADICTED, or NOT ENOUGH INFO
        2. Brief explanation with specific references
        
        Verification:
        """
        
        pipeline = Pipeline()
        pipeline.add_component("embedder", self.haystack_llm.text_embedder)
        pipeline.add_component("retriever", InMemoryEmbeddingRetriever(document_store=self.haystack_llm.document_store))
        pipeline.add_component("prompt_builder", PromptBuilder(template=fact_check_template))
        pipeline.add_component("llm", self.haystack_llm.generator)
        
        pipeline.connect("embedder.embedding", "retriever.query_embedding")
        pipeline.connect("retriever", "prompt_builder.documents")
        pipeline.connect("prompt_builder", "llm")
        
        return pipeline

# Usage examples and demonstrations
def demonstrate_haystack_integration():
    """Demonstrate Haystack integration with local LLM"""
    
    # Initialize Haystack LLM
    haystack_llm = LocalHaystackLLM("http://localhost:8080", "llama-2-7b-chat")
    
    # Create sample documents
    documents = [
        Document(
            content="Renewable energy sources like solar and wind are becoming increasingly cost-effective and efficient.",
            meta={"source": "energy_report.pdf", "category": "technology"}
        ),
        Document(
            content="Climate change is causing more frequent extreme weather events globally.",
            meta={"source": "climate_study.pdf", "category": "science"}
        ),
        Document(
            content="Electric vehicle adoption is accelerating due to improved battery technology and charging infrastructure.",
            meta={"source": "transport_news.pdf", "category": "technology"}
        ),
        Document(
            content="Machine learning algorithms are helping optimize energy grid management and reduce waste.",
            meta={"source": "ai_energy.pdf", "category": "technology"}
        ),
    ]
    
    # Index documents
    haystack_llm.index_documents(documents)
    
    # Test RAG pipeline
    print("=== Testing RAG Pipeline ===")
    rag_pipeline = haystack_llm.create_rag_pipeline()
    
    result = rag_pipeline.run({
        "embedder": {"text": "How is technology helping with climate and energy issues?"},
        "prompt_builder": {"question": "How is technology helping with climate and energy issues?"}
    })
    
    print("RAG Response:", result["llm"]["replies"][0])
    
    # Test hybrid retrieval
    print("\n=== Testing Hybrid Retrieval ===")
    hybrid_pipeline = haystack_llm.create_hybrid_retrieval_pipeline()
    
    hybrid_result = hybrid_pipeline.run({
        "text_embedder": {"text": "renewable energy efficiency"},
        "bm25_retriever": {"query": "renewable energy efficiency"},
        "ranker": {"query": "renewable energy efficiency"},
        "prompt_builder": {"question": "What makes renewable energy more efficient?"}
    })
    
    print("Hybrid Response:", hybrid_result["llm"]["replies"][0])
    
    # Test specialized pipelines
    specialized = SpecializedPipelines(haystack_llm)
    
    # Summarization
    print("\n=== Testing Summarization ===")
    summary_pipeline = specialized.create_summarization_pipeline()
    
    summary_result = summary_pipeline.run({
        "prompt_builder": {"documents": documents}
    })
    
    print("Summary:", summary_result["llm"]["replies"][0])
    
    # Classification
    print("\n=== Testing Classification ===")
    classification_pipeline = specialized.create_classification_pipeline()
    
    classification_result = classification_pipeline.run({
        "prompt_builder": {"document": documents[0].content}
    })
    
    print("Classification:", classification_result["llm"]["replies"][0])
    
    # Fact checking
    print("\n=== Testing Fact Checking ===")
    fact_check_pipeline = specialized.create_fact_checking_pipeline()
    
    fact_result = fact_check_pipeline.run({
        "embedder": {"text": "renewable energy is cost-effective"},
        "prompt_builder": {"claim": "Renewable energy sources are now more cost-effective than fossil fuels"}
    })
    
    print("Fact Check:", fact_result["llm"]["replies"][0])

if __name__ == "__main__":
    demonstrate_haystack_integration()
```

### Semantic Kernel

Microsoft Semantic Kernel provides AI orchestration for integrating large language models with traditional programming languages.

**Semantic Kernel Setup:**

```python
# semantic_kernel_integration.py - Semantic Kernel with local LLMs
import semantic_kernel as sk
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion, OpenAITextCompletion
from semantic_kernel.core_plugins import TextPlugin, ConversationSummaryPlugin
from semantic_kernel.template_engine.protocols.prompt_template_engine import PromptTemplateEngine
from semantic_kernel.orchestration.sk_context import SKContext
from semantic_kernel.skill_definition import sk_function, sk_function_context_parameter
from semantic_kernel.core_plugins.text_memory_plugin import TextMemoryPlugin
from semantic_kernel.memory.null_memory import NullMemory
from semantic_kernel.memory.semantic_text_memory import SemanticTextMemory
from semantic_kernel.connectors.memory.chroma import ChromaMemoryStore
import asyncio
from typing import Dict, List, Optional

class LocalSemanticKernel:
    """Semantic Kernel setup for local LLMs"""
    
    def __init__(self, base_url: str = "http://localhost:8080", model: str = "llama-2-7b-chat"):
        self.kernel = sk.Kernel()
        
        # Configure local LLM service
        self.kernel.add_chat_service(
            "local_llm",
            OpenAIChatCompletion(
                ai_model_id=model,
                api_key="not-needed",
                endpoint=f"{base_url}/v1"
            )
        )
        
        # Set default AI service
        self.kernel.set_default_text_completion_service("local_llm")
        
        # Configure memory (optional)
        memory_store = ChromaMemoryStore(persist_directory="./chroma_sk")
        memory = SemanticTextMemory(storage=memory_store, embeddings_generator=None)
        self.kernel.register_memory_store(memory)
        
    async def create_basic_skills(self):
        """Create and register basic skills"""
        
        # Import built-in plugins
        text_plugin = self.kernel.import_plugin(TextPlugin(), "TextPlugin")
        conversation_plugin = self.kernel.import_plugin(ConversationSummaryPlugin(self.kernel), "ConversationSummaryPlugin")
        
        # Create custom skills
        research_skill = self.create_research_skill()
        analysis_skill = self.create_analysis_skill()
        coding_skill = self.create_coding_skill()
        
        # Register custom skills
        self.kernel.import_plugin(research_skill, "ResearchSkill")
        self.kernel.import_plugin(analysis_skill, "AnalysisSkill")
        self.kernel.import_plugin(coding_skill, "CodingSkill")
        
        return {
            "text": text_plugin,
            "conversation": conversation_plugin,
            "research": research_skill,
            "analysis": analysis_skill,
            "coding": coding_skill
        }
    
    def create_research_skill(self):
        """Create custom research skill"""
        
        class ResearchSkill:
            @sk_function(
                description="Generate a comprehensive research outline for a given topic",
                name="create_outline"
            )
            @sk_function_context_parameter(
                name="topic",
                description="The research topic to create an outline for"
            )
            async def create_outline(self, context: SKContext) -> str:
                topic = context.variables.get("topic", "")
                
                prompt = f"""
                Create a detailed research outline for the topic: {topic}
                
                The outline should include:
                1. Introduction and background
                2. Key areas to investigate
                3. Potential sources and methodologies
                4. Expected findings
                5. Conclusion structure
                
                Make it comprehensive and well-organized.
                """
                
                result = await context.kernel.invoke_async(
                    function_name="CompleteChat",
                    plugin_name="local_llm",
                    input=prompt
                )
                
                return str(result)
            
            @sk_function(
                description="Summarize research findings and extract key insights",
                name="summarize_findings"
            )
            @sk_function_context_parameter(
                name="research_data",
                description="The research data to summarize"
            )
            async def summarize_findings(self, context: SKContext) -> str:
                research_data = context.variables.get("research_data", "")
                
                prompt = f"""
                Analyze the following research data and provide:
                1. Key findings (top 5)
                2. Important trends or patterns
                3. Implications and insights
                4. Recommendations for further research
                
                Research Data:
                {research_data}
                """
                
                result = await context.kernel.invoke_async(
                    function_name="CompleteChat",
                    plugin_name="local_llm",
                    input=prompt
                )
                
                return str(result)
        
        return ResearchSkill()
    
    def create_analysis_skill(self):
        """Create data analysis skill"""
        
        class AnalysisSkill:
            @sk_function(
                description="Perform sentiment analysis on text",
                name="sentiment_analysis"
            )
            @sk_function_context_parameter(
                name="text",
                description="The text to analyze for sentiment"
            )
            async def sentiment_analysis(self, context: SKContext) -> str:
                text = context.variables.get("text", "")
                
                prompt = f"""
                Analyze the sentiment of the following text and provide:
                1. Overall sentiment (Positive/Negative/Neutral)
                2. Confidence score (0-1)
                3. Key emotional indicators
                4. Brief explanation
                
                Text: {text}
                
                Format your response as JSON.
                """
                
                result = await context.kernel.invoke_async(
                    function_name="CompleteChat",
                    plugin_name="local_llm",
                    input=prompt
                )
                
                return str(result)
            
            @sk_function(
                description="Extract key topics and themes from text",
                name="topic_extraction"
            )
            @sk_function_context_parameter(
                name="text",
                description="The text to extract topics from"
            )
            async def topic_extraction(self, context: SKContext) -> str:
                text = context.variables.get("text", "")
                
                prompt = f"""
                Extract the main topics and themes from the following text:
                
                {text}
                
                Provide:
                1. Top 5 main topics
                2. Supporting themes for each topic
                3. Relevance score for each (0-1)
                4. Brief description of each topic
                
                Format as structured output.
                """
                
                result = await context.kernel.invoke_async(
                    function_name="CompleteChat",
                    plugin_name="local_llm",
                    input=prompt
                )
                
                return str(result)
        
        return AnalysisSkill()
    
    def create_coding_skill(self):
        """Create programming assistance skill"""
        
        class CodingSkill:
            @sk_function(
                description="Generate code based on requirements",
                name="generate_code"
            )
            @sk_function_context_parameter(
                name="requirements",
                description="The code requirements and specifications"
            )
            @sk_function_context_parameter(
                name="language",
                description="The programming language to use"
            )
            async def generate_code(self, context: SKContext) -> str:
                requirements = context.variables.get("requirements", "")
                language = context.variables.get("language", "python")
                
                prompt = f"""
                Generate {language} code based on the following requirements:
                
                Requirements: {requirements}
                
                Provide:
                1. Complete, working code
                2. Comments explaining key parts
                3. Error handling where appropriate
                4. Usage examples
                5. Any dependencies needed
                """
                
                result = await context.kernel.invoke_async(
                    function_name="CompleteChat",
                    plugin_name="local_llm",
                    input=prompt
                )
                
                return str(result)
            
            @sk_function(
                description="Review code and provide suggestions",
                name="code_review"
            )
            @sk_function_context_parameter(
                name="code",
                description="The code to review"
            )
            async def code_review(self, context: SKContext) -> str:
                code = context.variables.get("code", "")
                
                prompt = f"""
                Review the following code and provide:
                1. Overall code quality assessment
                2. Potential bugs or issues
                3. Performance improvements
                4. Best practice recommendations
                5. Security considerations
                
                Code:
                {code}
                """
                
                result = await context.kernel.invoke_async(
                    function_name="CompleteChat",
                    plugin_name="local_llm",
                    input=prompt
                )
                
                return str(result)
        
        return CodingSkill()
    
    async def create_complex_workflow(self):
        """Create a complex multi-step workflow"""
        
        # Define a multi-step research and analysis workflow
        workflow_template = """
        You are conducting a comprehensive analysis workflow with the following steps:
        
        Step 1: Research Phase
        Topic: {{$topic}}
        
        Step 2: Data Collection
        Sources: {{$sources}}
        
        Step 3: Analysis
        Focus Areas: {{$focus_areas}}
        
        Step 4: Synthesis
        Create a comprehensive report combining all findings.
        
        Execute this workflow systematically and provide detailed output for each step.
        """
        
        workflow_function = self.kernel.create_semantic_function(
            workflow_template,
            function_name="comprehensive_workflow",
            plugin_name="WorkflowPlugin",
            description="Execute a comprehensive research and analysis workflow",
            max_tokens=1000,
            temperature=0.7
        )
        
        return workflow_function
    
    async def create_chained_operations(self):
        """Create chained operations using multiple skills"""
        
        # Chain: Research Outline -> Data Analysis -> Summary -> Recommendations
        chain_template = """
        Execute the following chained analysis:
        
        1. Create research outline for: {{$topic}}
        2. Analyze provided data: {{$data}}
        3. Synthesize findings
        4. Generate actionable recommendations
        
        Provide comprehensive output for each step with clear transitions between phases.
        """
        
        chain_function = self.kernel.create_semantic_function(
            chain_template,
            function_name="analysis_chain",
            plugin_name="ChainPlugin",
            description="Execute chained analysis operations",
            max_tokens=1500,
            temperature=0.6
        )
        
        return chain_function

# Advanced orchestration patterns
class AdvancedOrchestration:
    """Advanced orchestration patterns with Semantic Kernel"""
    
    def __init__(self, kernel_instance: LocalSemanticKernel):
        self.kernel = kernel_instance
    
    async def parallel_processing(self, tasks: List[Dict]) -> List[str]:
        """Execute multiple tasks in parallel"""
        
        async def execute_task(task):
            context = self.kernel.kernel.create_new_context()
            for key, value in task["variables"].items():
                context.variables[key] = value
            
            result = await self.kernel.kernel.run_async(
                context.variables,
                task["skill"],
                task["function"]
            )
            
            return str(result)
        
        # Execute tasks concurrently
        results = await asyncio.gather(
            *[execute_task(task) for task in tasks]
        )
        
        return results
    
    async def conditional_workflow(self, condition_check: str, true_path: Dict, false_path: Dict) -> str:
        """Execute conditional workflow based on condition"""
        
        # Evaluate condition
        condition_template = f"""
        Evaluate the following condition and respond with only 'TRUE' or 'FALSE':
        
        Condition: {condition_check}
        """
        
        condition_result = await self.kernel.kernel.invoke_async(
            function_name="CompleteChat",
            plugin_name="local_llm",
            input=condition_template
        )
        
        # Execute appropriate path
        if "TRUE" in str(condition_result).upper():
            return await self.execute_path(true_path)
        else:
            return await self.execute_path(false_path)
    
    async def execute_path(self, path_config: Dict) -> str:
        """Execute a configured path"""
        context = self.kernel.kernel.create_new_context()
        
        for key, value in path_config.get("variables", {}).items():
            context.variables[key] = value
        
        result = await self.kernel.kernel.run_async(
            context.variables,
            path_config["skill"],
            path_config["function"]
        )
        
        return str(result)
    
    async def iterative_refinement(self, initial_input: str, refinement_steps: int = 3) -> List[str]:
        """Perform iterative refinement of content"""
        
        results = [initial_input]
        current_content = initial_input
        
        for step in range(refinement_steps):
            refinement_template = f"""
            Improve and refine the following content (Step {step + 1}):
            
            Current Content:
            {current_content}
            
            Focus on:
            - Clarity and coherence
            - Factual accuracy
            - Completeness
            - Structure and flow
            
            Provide the refined version:
            """
            
            refined_result = await self.kernel.kernel.invoke_async(
                function_name="CompleteChat",
                plugin_name="local_llm",
                input=refinement_template
            )
            
            current_content = str(refined_result)
            results.append(current_content)
        
        return results

# Usage examples and demonstrations
async def demonstrate_semantic_kernel():
    """Demonstrate Semantic Kernel integration"""
    
    # Initialize Semantic Kernel
    sk_instance = LocalSemanticKernel("http://localhost:8080", "llama-2-7b-chat")
    
    # Create and register skills
    skills = await sk_instance.create_basic_skills()
    print("Registered skills:", list(skills.keys()))
    
    # Test research skill
    print("\n=== Testing Research Skill ===")
    context = sk_instance.kernel.create_new_context()
    context.variables["topic"] = "Impact of artificial intelligence on education"
    
    outline_result = await sk_instance.kernel.run_async(
        context.variables,
        skills["research"],
        "create_outline"
    )
    print("Research Outline:", outline_result)
    
    # Test analysis skill
    print("\n=== Testing Analysis Skill ===")
    context.variables["text"] = "I absolutely love this new technology! It's going to revolutionize how we work and make everything so much more efficient."
    
    sentiment_result = await sk_instance.kernel.run_async(
        context.variables,
        skills["analysis"],
        "sentiment_analysis"
    )
    print("Sentiment Analysis:", sentiment_result)
    
    # Test coding skill
    print("\n=== Testing Coding Skill ===")
    context.variables["requirements"] = "Create a Python function that calculates the Fibonacci sequence up to n terms"
    context.variables["language"] = "python"
    
    code_result = await sk_instance.kernel.run_async(
        context.variables,
        skills["coding"],
        "generate_code"
    )
    print("Generated Code:", code_result)
    
    # Test complex workflow
    print("\n=== Testing Complex Workflow ===")
    workflow_function = await sk_instance.create_complex_workflow()
    
    workflow_context = sk_instance.kernel.create_new_context()
    workflow_context.variables["topic"] = "renewable energy adoption"
    workflow_context.variables["sources"] = "government reports, industry studies, academic papers"
    workflow_context.variables["focus_areas"] = "economic impact, technological barriers, policy implications"
    
    workflow_result = await workflow_function.invoke_async(context=workflow_context)
    print("Workflow Result:", workflow_result)
    
    # Test advanced orchestration
    print("\n=== Testing Advanced Orchestration ===")
    orchestrator = AdvancedOrchestration(sk_instance)
    
    # Parallel processing example
    parallel_tasks = [
        {
            "skill": skills["analysis"],
            "function": "sentiment_analysis",
            "variables": {"text": "This product is amazing and works perfectly!"}
        },
        {
            "skill": skills["analysis"],
            "function": "topic_extraction",
            "variables": {"text": "The conference covered artificial intelligence, machine learning, deep learning, and neural networks."}
        }
    ]
    
    parallel_results = await orchestrator.parallel_processing(parallel_tasks)
    print("Parallel Results:", parallel_results)
    
    # Iterative refinement example
    print("\n=== Testing Iterative Refinement ===")
    initial_content = "AI is good for business. It helps with automation and efficiency."
    
    refined_versions = await orchestrator.iterative_refinement(initial_content, 2)
    for i, version in enumerate(refined_versions):
        print(f"Version {i}: {version[:100]}...")

if __name__ == "__main__":
    asyncio.run(demonstrate_semantic_kernel())
```

This comprehensive Framework Integration section provides detailed implementations for:

1. **LangChain**: Complete integration with custom LLM wrapper, chains, agents, memory, document processing, and advanced patterns
2. **LlamaIndex**: RAG systems, query engines, chat engines, custom retrievers, and reranking
3. **Haystack**: Pipelines for RAG, hybrid retrieval, summarization, classification, and fact-checking
4. **Semantic Kernel**: Skills creation, orchestration, workflows, and advanced patterns

Each framework integration includes production-ready code examples with proper error handling, advanced features, and real-world usage patterns.

## Application Integration

Comprehensive integration patterns for different types of applications, from web interfaces to mobile apps and desktop software.

### Web Applications

Modern web applications can integrate local LLMs through various approaches, from simple API calls to sophisticated streaming interfaces.

**React Integration with Streaming:**

```typescript
// react-llm-chat.tsx - React component with streaming
import React, { useState, useCallback, useRef, useEffect } from 'react';
import { OpenAI } from 'openai';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
  isStreaming?: boolean;
}

interface ChatProps {
  apiUrl: string;
  model: string;
}

const ChatComponent: React.FC<ChatProps> = ({ apiUrl, model }) => {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const abortControllerRef = useRef<AbortController | null>(null);

  // Initialize OpenAI client
  const client = useRef(new OpenAI({
    apiKey: 'not-needed',
    baseURL: apiUrl,
    dangerouslyAllowBrowser: true
  }));

  // Check connection status
  useEffect(() => {
    const checkConnection = async () => {
      try {
        await fetch(`${apiUrl}/v1/models`, { 
          method: 'GET',
          signal: AbortSignal.timeout(5000)
        });
        setIsConnected(true);
      } catch (error) {
        setIsConnected(false);
      }
    };

    checkConnection();
    const interval = setInterval(checkConnection, 30000);
    return () => clearInterval(interval);
  }, [apiUrl]);

  // Auto-scroll to bottom
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSubmit = useCallback(async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || isLoading || !isConnected) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: input.trim(),
      timestamp: new Date()
    };

    const assistantMessage: Message = {
      id: (Date.now() + 1).toString(),
      role: 'assistant',
      content: '',
      timestamp: new Date(),
      isStreaming: true
    };

    setMessages(prev => [...prev, userMessage, assistantMessage]);
    setInput('');
    setIsLoading(true);

    // Create new abort controller for this request
    abortControllerRef.current = new AbortController();

    try {
      const stream = await client.current.chat.completions.create({
        model,
        messages: [
          ...messages.map(msg => ({
            role: msg.role,
            content: msg.content
          })),
          { role: 'user', content: input.trim() }
        ],
        stream: true,
        temperature: 0.7,
        max_tokens: 500
      }, {
        signal: abortControllerRef.current.signal
      });

      let fullResponse = '';
      
      for await (const chunk of stream) {
        if (abortControllerRef.current?.signal.aborted) break;
        
        const content = chunk.choices[0]?.delta?.content || '';
        if (content) {
          fullResponse += content;
          
          setMessages(prev => prev.map(msg => 
            msg.id === assistantMessage.id 
              ? { ...msg, content: fullResponse }
              : msg
          ));
        }
      }

      // Mark streaming as complete
      setMessages(prev => prev.map(msg => 
        msg.id === assistantMessage.id 
          ? { ...msg, isStreaming: false }
          : msg
      ));

    } catch (error: any) {
      if (error.name === 'AbortError') {
        console.log('Request was aborted');
        return;
      }
      
      setMessages(prev => prev.map(msg => 
        msg.id === assistantMessage.id 
          ? { 
              ...msg, 
              content: `Error: ${error.message}`, 
              isStreaming: false 
            }
          : msg
      ));
    } finally {
      setIsLoading(false);
      abortControllerRef.current = null;
    }
  }, [input, isLoading, isConnected, messages, model]);

  const handleStop = useCallback(() => {
    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
      setIsLoading(false);
    }
  }, []);

  const clearChat = useCallback(() => {
    setMessages([]);
  }, []);

  return (
    <div className="chat-container">
      <div className="chat-header">
        <h3>Local LLM Chat</h3>
        <div className="chat-controls">
          <span className={`connection-status ${isConnected ? 'connected' : 'disconnected'}`}>
            {isConnected ? '🟢 Connected' : '🔴 Disconnected'}
          </span>
          <button onClick={clearChat} disabled={isLoading}>
            Clear
          </button>
        </div>
      </div>
      
      <div className="messages">
        {messages.map((message) => (
          <div key={message.id} className={`message ${message.role}`}>
            <div className="message-header">
              <strong>{message.role === 'user' ? 'You' : 'Assistant'}</strong>
              <span className="timestamp">
                {message.timestamp.toLocaleTimeString()}
              </span>
            </div>
            <div className="message-content">
              {message.content}
              {message.isStreaming && <span className="cursor">|</span>}
            </div>
          </div>
        ))}
        <div ref={messagesEndRef} />
      </div>
      
      <form onSubmit={handleSubmit} className="input-form">
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder={isConnected ? "Type your message..." : "Waiting for connection..."}
          disabled={isLoading || !isConnected}
          className="message-input"
        />
        <div className="input-controls">
          {isLoading ? (
            <button type="button" onClick={handleStop} className="stop-button">
              Stop
            </button>
          ) : (
            <button 
              type="submit" 
              disabled={!input.trim() || !isConnected}
              className="send-button"
            >
              Send
            </button>
          )}
        </div>
      </form>
    </div>
  );
};

export default ChatComponent;
```

**Vue.js Integration:**

```vue
<!-- VueLLMChat.vue - Vue 3 composition API -->
<template>
  <div class="llm-chat">
    <div class="chat-messages" ref="messagesContainer">
      <div 
        v-for="message in messages" 
        :key="message.id"
        :class="['message', message.role]"
      >
        <div class="message-content">
          <strong>{{ message.role === 'user' ? 'You' : 'AI' }}:</strong>
          {{ message.content }}
          <span v-if="message.isStreaming" class="typing-indicator">▋</span>
        </div>
        <div class="message-time">{{ formatTime(message.timestamp) }}</div>
      </div>
    </div>
    
    <form @submit.prevent="sendMessage" class="input-form">
      <input
        v-model="inputText"
        :disabled="isLoading"
        placeholder="Type your message..."
        class="message-input"
      />
      <button 
        type="submit" 
        :disabled="!inputText.trim() || isLoading"
        class="send-button"
      >
        {{ isLoading ? 'Sending...' : 'Send' }}
      </button>
    </form>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, nextTick, onMounted } from 'vue';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
  isStreaming?: boolean;
}

interface Props {
  apiUrl: string;
  model: string;
}

const props = defineProps<Props>();

const messages = ref<Message[]>([]);
const inputText = ref('');
const isLoading = ref(false);
const messagesContainer = ref<HTMLElement>();

const sendMessage = async () => {
  if (!inputText.value.trim() || isLoading.value) return;

  const userMessage: Message = {
    id: Date.now().toString(),
    role: 'user',
    content: inputText.value.trim(),
    timestamp: new Date()
  };

  const aiMessage: Message = {
    id: (Date.now() + 1).toString(),
    role: 'assistant',
    content: '',
    timestamp: new Date(),
    isStreaming: true
  };

  messages.value.push(userMessage, aiMessage);
  const currentInput = inputText.value.trim();
  inputText.value = '';
  isLoading.value = true;

  try {
    const response = await fetch(`${props.apiUrl}/v1/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: props.model,
        messages: messages.value
          .filter(msg => !msg.isStreaming)
          .map(msg => ({
            role: msg.role,
            content: msg.content
          }))
          .concat([{ role: 'user', content: currentInput }]),
        stream: true,
        temperature: 0.7,
        max_tokens: 500
      })
    });

    if (!response.body) throw new Error('No response body');

    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let fullResponse = '';

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      const chunk = decoder.decode(value);
      const lines = chunk.split('\n');

      for (const line of lines) {
        if (line.startsWith('data: ')) {
          const data = line.slice(6);
          if (data === '[DONE]') continue;

          try {
            const parsed = JSON.parse(data);
            const content = parsed.choices?.[0]?.delta?.content || '';
            
            if (content) {
              fullResponse += content;
              const messageIndex = messages.value.findIndex(msg => msg.id === aiMessage.id);
              if (messageIndex !== -1) {
                messages.value[messageIndex].content = fullResponse;
              }
              
              await nextTick();
              scrollToBottom();
            }
          } catch (e) {
            // Skip invalid JSON
          }
        }
      }
    }

    // Mark as complete
    const messageIndex = messages.value.findIndex(msg => msg.id === aiMessage.id);
    if (messageIndex !== -1) {
      messages.value[messageIndex].isStreaming = false;
    }

  } catch (error) {
    const messageIndex = messages.value.findIndex(msg => msg.id === aiMessage.id);
    if (messageIndex !== -1) {
      messages.value[messageIndex].content = `Error: ${error.message}`;
      messages.value[messageIndex].isStreaming = false;
    }
  } finally {
    isLoading.value = false;
  }
};

const formatTime = (date: Date) => {
  return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
};

const scrollToBottom = () => {
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight;
  }
};

onMounted(() => {
  scrollToBottom();
});
</script>

<style scoped>
.llm-chat {
  display: flex;
  flex-direction: column;
  height: 500px;
  border: 1px solid #ccc;
  border-radius: 8px;
}

.chat-messages {
  flex: 1;
  overflow-y: auto;
  padding: 1rem;
}

.message {
  margin-bottom: 1rem;
}

.message.user {
  text-align: right;
}

.message.assistant {
  text-align: left;
}

.typing-indicator {
  animation: blink 1s infinite;
}

@keyframes blink {
  0%, 50% { opacity: 1; }
  51%, 100% { opacity: 0; }
}

.input-form {
  display: flex;
  padding: 1rem;
  border-top: 1px solid #eee;
}

.message-input {
  flex: 1;
  padding: 0.5rem;
  border: 1px solid #ccc;
  border-radius: 4px;
  margin-right: 0.5rem;
}

.send-button {
  padding: 0.5rem 1rem;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.send-button:disabled {
  background: #ccc;
  cursor: not-allowed;
}
</style>
```

### Desktop Applications

Desktop applications can integrate local LLMs through various approaches, from embedded HTTP clients to direct library integration.

**Electron App Integration:**

```typescript
// electron-llm-app.ts - Electron main process
import { app, BrowserWindow, ipcMain, dialog } from 'electron';
import path from 'path';
import { OpenAI } from 'openai';

class LLMElectronApp {
  private mainWindow: BrowserWindow | null = null;
  private llmClient: OpenAI;

  constructor() {
    this.llmClient = new OpenAI({
      apiKey: 'not-needed',
      baseURL: 'http://localhost:8080/v1'
    });

    this.initializeApp();
  }

  private initializeApp() {
    app.whenReady().then(() => {
      this.createMainWindow();
      this.setupIpcHandlers();
    });

    app.on('window-all-closed', () => {
      if (process.platform !== 'darwin') {
        app.quit();
      }
    });

    app.on('activate', () => {
      if (BrowserWindow.getAllWindows().length === 0) {
        this.createMainWindow();
      }
    });
  }

  private createMainWindow() {
    this.mainWindow = new BrowserWindow({
      width: 1200,
      height: 800,
      webPreferences: {
        nodeIntegration: false,
        contextIsolation: true,
        preload: path.join(__dirname, 'preload.js')
      }
    });

    this.mainWindow.loadFile('renderer/index.html');
  }

  private setupIpcHandlers() {
    // Handle chat completion requests
    ipcMain.handle('llm:chat', async (event, messages, options = {}) => {
      try {
        const response = await this.llmClient.chat.completions.create({
          model: options.model || 'llama-2-7b-chat',
          messages: messages,
          temperature: options.temperature || 0.7,
          max_tokens: options.maxTokens || 500,
          stream: false
        });

        return {
          success: true,
          content: response.choices[0]?.message?.content || '',
          usage: response.usage
        };
      } catch (error) {
        return {
          success: false,
          error: error.message
        };
      }
    });

    // Handle streaming chat
    ipcMain.handle('llm:stream-chat', async (event, messages, options = {}) => {
      try {
        const stream = await this.llmClient.chat.completions.create({
          model: options.model || 'llama-2-7b-chat',
          messages: messages,
          temperature: options.temperature || 0.7,
          max_tokens: options.maxTokens || 500,
          stream: true
        });

        for await (const chunk of stream) {
          const content = chunk.choices[0]?.delta?.content || '';
          if (content) {
            event.sender.send('llm:stream-chunk', content);
          }
        }

        event.sender.send('llm:stream-complete');
        return { success: true };
      } catch (error) {
        event.sender.send('llm:stream-error', error.message);
        return { success: false, error: error.message };
      }
    });

    // Handle model listing
    ipcMain.handle('llm:list-models', async () => {
      try {
        const models = await this.llmClient.models.list();
        return {
          success: true,
          models: models.data.map(model => model.id)
        };
      } catch (error) {
        return {
          success: false,
          error: error.message
        };
      }
    });

    // Handle file operations
    ipcMain.handle('file:select', async () => {
      const result = await dialog.showOpenDialog(this.mainWindow!, {
        filters: [
          { name: 'Text Files', extensions: ['txt', 'md', 'json'] },
          { name: 'All Files', extensions: ['*'] }
        ],
        properties: ['openFile']
      });

      if (!result.canceled && result.filePaths.length > 0) {
        const fs = await import('fs/promises');
        try {
          const content = await fs.readFile(result.filePaths[0], 'utf-8');
          return { success: true, content, path: result.filePaths[0] };
        } catch (error) {
          return { success: false, error: error.message };
        }
      }

      return { success: false, error: 'No file selected' };
    });
  }
}

new LLMElectronApp();
```

**Python Desktop App with Tkinter:**

```python
# desktop_llm_app.py - Python desktop app
import tkinter as tk
from tkinter import ttk, scrolledtext, filedialog, messagebox
import threading
import queue
import requests
import json
from typing import Dict, Any, Optional

class LLMDesktopApp:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("Local LLM Chat")
        self.root.geometry("800x600")
        
        self.api_url = "http://localhost:8080"
        self.model = "llama-2-7b-chat"
        self.conversation_history = []
        
        # Thread communication
        self.response_queue = queue.Queue()
        self.is_streaming = False
        
        self.setup_ui()
        self.check_connection()
        
    def setup_ui(self):
        # Main frame
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(1, weight=1)
        
        # Connection status
        self.connection_var = tk.StringVar(value="🔴 Checking connection...")
        ttk.Label(main_frame, textvariable=self.connection_var).grid(
            row=0, column=0, columnspan=3, pady=(0, 10)
        )
        
        # Chat display
        self.chat_display = scrolledtext.ScrolledText(
            main_frame, 
            wrap=tk.WORD,
            height=20,
            state=tk.DISABLED,
            font=('Courier', 10)
        )
        self.chat_display.grid(row=1, column=0, columnspan=3, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(0, 10))
        
        # Input frame
        input_frame = ttk.Frame(main_frame)
        input_frame.grid(row=2, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))
        input_frame.columnconfigure(0, weight=1)
        
        # Message input
        self.message_var = tk.StringVar()
        self.message_entry = ttk.Entry(input_frame, textvariable=self.message_var, font=('Arial', 11))
        self.message_entry.grid(row=0, column=0, sticky=(tk.W, tk.E), padx=(0, 10))
        self.message_entry.bind('<Return>', self.send_message)
        
        # Send button
        self.send_button = ttk.Button(input_frame, text="Send", command=self.send_message)
        self.send_button.grid(row=0, column=1)
        
        # Control frame
        control_frame = ttk.Frame(main_frame)
        control_frame.grid(row=3, column=0, columnspan=3, sticky=(tk.W, tk.E))
        
        # Clear button
        ttk.Button(control_frame, text="Clear Chat", command=self.clear_chat).grid(row=0, column=0, padx=(0, 10))
        
        # Settings button
        ttk.Button(control_frame, text="Settings", command=self.show_settings).grid(row=0, column=1, padx=(0, 10))
        
        # Load file button
        ttk.Button(control_frame, text="Load File", command=self.load_file).grid(row=0, column=2)
        
        # Start processing queue
        self.process_queue()
    
    def check_connection(self):
        """Check connection to LLM server"""
        def check():
            try:
                response = requests.get(f"{self.api_url}/v1/models", timeout=5)
                if response.status_code == 200:
                    self.connection_var.set("🟢 Connected to LLM server")
                    self.send_button.config(state='normal')
                else:
                    self.connection_var.set("🔴 Server error")
                    self.send_button.config(state='disabled')
            except Exception:
                self.connection_var.set("🔴 Connection failed")
                self.send_button.config(state='disabled')
        
        threading.Thread(target=check, daemon=True).start()
        # Schedule next check
        self.root.after(30000, self.check_connection)
    
    def add_message(self, role: str, content: str):
        """Add message to chat display"""
        self.chat_display.config(state=tk.NORMAL)
        
        # Add timestamp and role
        timestamp = tk.datetime.datetime.now().strftime("%H:%M:%S")
        header = f"[{timestamp}] {role.upper()}:\n"
        
        self.chat_display.insert(tk.END, header)
        self.chat_display.insert(tk.END, f"{content}\n\n")
        
        # Auto-scroll to bottom
        self.chat_display.see(tk.END)
        self.chat_display.config(state=tk.DISABLED)
    
    def send_message(self, event=None):
        """Send message to LLM"""
        message = self.message_var.get().strip()
        if not message or self.is_streaming:
            return
        
        # Add user message to display
        self.add_message("User", message)
        self.conversation_history.append({"role": "user", "content": message})
        
        # Clear input
        self.message_var.set("")
        
        # Disable send button during processing
        self.send_button.config(state='disabled')
        self.is_streaming = True
        
        # Start LLM request in background
        threading.Thread(
            target=self.request_llm_response,
            args=(message,),
            daemon=True
        ).start()
    
    def request_llm_response(self, user_message: str):
        """Request response from LLM"""
        try:
            payload = {
                "model": self.model,
                "messages": self.conversation_history,
                "temperature": 0.7,
                "max_tokens": 500,
                "stream": True
            }
            
            response = requests.post(
                f"{self.api_url}/v1/chat/completions",
                json=payload,
                stream=True,
                timeout=120
            )
            response.raise_for_status()
            
            # Process streaming response
            full_response = ""
            for line in response.iter_lines():
                if line:
                    line_text = line.decode('utf-8')
                    if line_text.startswith('data: '):
                        data = line_text[6:]
                        if data == '[DONE]':
                            break
                        
                        try:
                            chunk = json.loads(data)
                            content = chunk['choices'][0]['delta'].get('content', '')
                            if content:
                                full_response += content
                                # Queue update for UI thread
                                self.response_queue.put(('chunk', content))
                        except json.JSONDecodeError:
                            continue
            
            # Add complete response to conversation history
            if full_response:
                self.conversation_history.append({
                    "role": "assistant", 
                    "content": full_response
                })
                self.response_queue.put(('complete', full_response))
            
        except Exception as e:
            self.response_queue.put(('error', str(e)))
        finally:
            self.response_queue.put(('done', None))
    
    def process_queue(self):
        """Process updates from background threads"""
        try:
            while True:
                msg_type, data = self.response_queue.get_nowait()
                
                if msg_type == 'chunk':
                    # Update display with streaming content
                    self.chat_display.config(state=tk.NORMAL)
                    self.chat_display.insert(tk.END, data)
                    self.chat_display.see(tk.END)
                    self.chat_display.config(state=tk.DISABLED)
                
                elif msg_type == 'complete':
                    # Response complete
                    pass
                
                elif msg_type == 'error':
                    self.add_message("Error", data)
                
                elif msg_type == 'done':
                    # Re-enable send button
                    self.send_button.config(state='normal')
                    self.is_streaming = False
                    
        except queue.Empty:
            pass
        
        # Schedule next check
        self.root.after(100, self.process_queue)
    
    def clear_chat(self):
        """Clear chat display and conversation history"""
        self.chat_display.config(state=tk.NORMAL)
        self.chat_display.delete(1.0, tk.END)
        self.chat_display.config(state=tk.DISABLED)
        self.conversation_history = []
    
    def load_file(self):
        """Load text file and send as message"""
        file_path = filedialog.askopenfilename(
            title="Select text file",
            filetypes=[("Text files", "*.txt"), ("Markdown files", "*.md"), ("All files", "*.*")]
        )
        
        if file_path:
            try:
                with open(file_path, 'r', encoding='utf-8') as file:
                    content = file.read()
                    
                # Add file content as message
                prompt = f"Please analyze the following file content:\n\n{content}"
                self.message_var.set(prompt)
                
            except Exception as e:
                messagebox.showerror("Error", f"Could not load file: {str(e)}")
    
    def show_settings(self):
        """Show settings dialog"""
        settings_window = tk.Toplevel(self.root)
        settings_window.title("Settings")
        settings_window.geometry("400x300")
        settings_window.transient(self.root)
        settings_window.grab_set()
        
        # Settings frame
        frame = ttk.Frame(settings_window, padding="20")
        frame.pack(fill=tk.BOTH, expand=True)
        
        # API URL setting
        ttk.Label(frame, text="API URL:").pack(anchor=tk.W, pady=(0, 5))
        api_url_var = tk.StringVar(value=self.api_url)
        ttk.Entry(frame, textvariable=api_url_var, width=50).pack(fill=tk.X, pady=(0, 15))
        
        # Model setting
        ttk.Label(frame, text="Model:").pack(anchor=tk.W, pady=(0, 5))
        model_var = tk.StringVar(value=self.model)
        ttk.Entry(frame, textvariable=model_var, width=50).pack(fill=tk.X, pady=(0, 15))
        
        # Save settings
        def save_settings():
            self.api_url = api_url_var.get()
            self.model = model_var.get()
            settings_window.destroy()
            self.check_connection()
        
        ttk.Button(frame, text="Save", command=save_settings).pack(pady=10)
    
    def run(self):
        """Start the application"""
        self.root.mainloop()

if __name__ == "__main__":
    import datetime
    app = LLMDesktopApp()
    app.run()
```

### Mobile Applications

Mobile apps can integrate with local LLMs through HTTP APIs, with special considerations for network connectivity and battery optimization.

**React Native Integration:**

```typescript
// LLMChatScreen.tsx - React Native component
import React, { useState, useCallback, useEffect, useRef } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  FlatList,
  StyleSheet,
  Alert,
  Keyboard,
  KeyboardAvoidingView,
  Platform
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import NetInfo from '@react-native-community/netinfo';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
  isStreaming?: boolean;
}

interface LLMChatScreenProps {
  apiUrl: string;
  model: string;
}

const LLMChatScreen: React.FC<LLMChatScreenProps> = ({ apiUrl, model }) => {
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputText, setInputText] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const [networkType, setNetworkType] = useState<string>('unknown');
  
  const flatListRef = useRef<FlatList>(null);
  const insets = useSafeAreaInsets();
  const abortController = useRef<AbortController | null>(null);

  // Network monitoring
  useEffect(() => {
    const unsubscribe = NetInfo.addEventListener(state => {
      setIsConnected(state.isConnected ?? false);
      setNetworkType(state.type);
    });

    return unsubscribe;
  }, []);

  // Check LLM server connectivity
  const checkServerHealth = useCallback(async () => {
    try {
      const response = await fetch(`${apiUrl}/v1/models`, {
        method: 'GET',
        timeout: 5000
      });
      return response.ok;
    } catch {
      return false;
    }
  }, [apiUrl]);

  const sendMessage = useCallback(async () => {
    if (!inputText.trim() || isLoading || !isConnected) {
      Alert.alert('Error', 'Please check your connection and try again');
      return;
    }

    // Check server health first
    const serverHealthy = await checkServerHealth();
    if (!serverHealthy) {
      Alert.alert('Error', 'Cannot connect to LLM server');
      return;
    }

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: inputText.trim(),
      timestamp: new Date()
    };

    const assistantMessage: Message = {
      id: (Date.now() + 1).toString(),
      role: 'assistant',
      content: '',
      timestamp: new Date(),
      isStreaming: true
    };

    setMessages(prev => [...prev, userMessage, assistantMessage]);
    setInputText('');
    setIsLoading(true);
    Keyboard.dismiss();

    // Create abort controller
    abortController.current = new AbortController();

    try {
      const response = await fetch(`${apiUrl}/v1/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model,
          messages: messages
            .filter(msg => !msg.isStreaming)
            .map(msg => ({
              role: msg.role,
              content: msg.content
            }))
            .concat([{ role: 'user', content: inputText.trim() }]),
          stream: true,
          temperature: 0.7,
          max_tokens: 300 // Reduced for mobile
        }),
        signal: abortController.current.signal
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const reader = response.body?.getReader();
      if (!reader) throw new Error('No response body');

      const decoder = new TextDecoder();
      let fullResponse = '';

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        const chunk = decoder.decode(value);
        const lines = chunk.split('\n');

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            const data = line.slice(6);
            if (data === '[DONE]') continue;

            try {
              const parsed = JSON.parse(data);
              const content = parsed.choices?.[0]?.delta?.content || '';
              
              if (content) {
                fullResponse += content;
                setMessages(prev => 
                  prev.map(msg => 
                    msg.id === assistantMessage.id 
                      ? { ...msg, content: fullResponse }
                      : msg
                  )
                );
              }
            } catch (e) {
              // Skip invalid JSON
            }
          }
        }
      }

      // Mark as complete
      setMessages(prev => 
        prev.map(msg => 
          msg.id === assistantMessage.id 
            ? { ...msg, isStreaming: false }
            : msg
        )
      );

    } catch (error: any) {
      if (error.name === 'AbortError') return;
      
      setMessages(prev => 
        prev.map(msg => 
          msg.id === assistantMessage.id 
            ? { 
                ...msg, 
                content: `Error: ${error.message}`, 
                isStreaming: false 
              }
            : msg
        )
      );
    } finally {
      setIsLoading(false);
      abortController.current = null;
    }
  }, [inputText, messages, isLoading, isConnected, apiUrl, model, checkServerHealth]);

  const stopGeneration = useCallback(() => {
    if (abortController.current) {
      abortController.current.abort();
      setIsLoading(false);
    }
  }, []);

  const renderMessage = useCallback(({ item }: { item: Message }) => (
    <View style={[
      styles.messageContainer,
      item.role === 'user' ? styles.userMessage : styles.assistantMessage
    ]}>
      <View style={styles.messageContent}>
        <Text style={[
          styles.messageText,
          item.role === 'user' ? styles.userText : styles.assistantText
        ]}>
          {item.content}
          {item.isStreaming && <Text style={styles.cursor}>|</Text>}
        </Text>
        <Text style={styles.timestamp}>
          {item.timestamp.toLocaleTimeString([], { 
            hour: '2-digit', 
            minute: '2-digit' 
          })}
        </Text>
      </View>
    </View>
  ), []);

  return (
    <KeyboardAvoidingView 
      style={[styles.container, { paddingTop: insets.top }]}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Local LLM Chat</Text>
        <Text style={[
          styles.connectionStatus,
          { color: isConnected ? '#4CAF50' : '#F44336' }
        ]}>
          {isConnected ? `🟢 ${networkType}` : '🔴 Offline'}
        </Text>
      </View>

      {/* Messages */}
      <FlatList
        ref={flatListRef}
        data={messages}
        renderItem={renderMessage}
        keyExtractor={item => item.id}
        style={styles.messagesList}
        onContentSizeChange={() => flatListRef.current?.scrollToEnd()}
        showsVerticalScrollIndicator={false}
      />

      {/* Input */}
      <View style={[styles.inputContainer, { paddingBottom: insets.bottom }]}>
        <TextInput
          style={styles.textInput}
          value={inputText}
          onChangeText={setInputText}
          placeholder="Type your message..."
          multiline
          maxLength={1000}
          editable={!isLoading && isConnected}
          placeholderTextColor="#999"
        />
        {isLoading ? (
          <TouchableOpacity style={styles.stopButton} onPress={stopGeneration}>
            <Text style={styles.stopButtonText}>Stop</Text>
          </TouchableOpacity>
        ) : (
          <TouchableOpacity 
            style={[
              styles.sendButton,
              (!inputText.trim() || !isConnected) && styles.sendButtonDisabled
            ]}
            onPress={sendMessage}
            disabled={!inputText.trim() || !isConnected}
          >
            <Text style={styles.sendButtonText}>Send</Text>
          </TouchableOpacity>
        )}
      </View>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    backgroundColor: 'white',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
  },
  connectionStatus: {
    fontSize: 14,
    fontWeight: '500',
  },
  messagesList: {
    flex: 1,
    padding: 16,
  },
  messageContainer: {
    marginVertical: 8,
    maxWidth: '80%',
  },
  userMessage: {
    alignSelf: 'flex-end',
  },
  assistantMessage: {
    alignSelf: 'flex-start',
  },
  messageContent: {
    backgroundColor: 'white',
    padding: 12,
    borderRadius: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  messageText: {
    fontSize: 16,
    lineHeight: 20,
  },
  userText: {
    color: '#333',
  },
  assistantText: {
    color: '#333',
  },
  timestamp: {
    fontSize: 12,
    color: '#666',
    marginTop: 4,
  },
  cursor: {
    opacity: 0.8,
  },
  inputContainer: {
    flexDirection: 'row',
    padding: 16,
    backgroundColor: 'white',
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
    alignItems: 'flex-end',
  },
  textInput: {
    flex: 1,
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 20,
    paddingHorizontal: 16,
    paddingVertical: 8,
    fontSize: 16,
    maxHeight: 100,
    marginRight: 8,
  },
  sendButton: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 20,
    paddingVertical: 8,
    borderRadius: 20,
  },
  sendButtonDisabled: {
    backgroundColor: '#ccc',
  },
  sendButtonText: {
    color: 'white',
    fontWeight: '600',
  },
  stopButton: {
    backgroundColor: '#FF3B30',
    paddingHorizontal: 20,
    paddingVertical: 8,
    borderRadius: 20,
  },
  stopButtonText: {
    color: 'white',
    fontWeight: '600',
  },
});

export default LLMChatScreen;
```

### CLI Tools

Command-line interfaces provide powerful integration options for local LLMs, enabling automation and scripting workflows.

**Advanced Python CLI Tool:**

```python
#!/usr/bin/env python3
# llm_cli.py - Advanced CLI tool for local LLM interaction
import click
import requests
import json
import sys
import os
from pathlib import Path
from typing import List, Dict, Any, Optional, Iterator
import tempfile
import subprocess
from rich.console import Console
from rich.panel import Panel
from rich.syntax import Syntax
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.table import Table
import yaml

console = Console()

class LLMClient:
    def __init__(self, base_url: str, model: str, api_key: Optional[str] = None):
        self.base_url = base_url.rstrip('/')
        self.model = model
        self.api_key = api_key
        self.session = requests.Session()
        
        if api_key:
            self.session.headers.update({'Authorization': f'Bearer {api_key}'})
    
    def list_models(self) -> List[str]:
        """Get available models"""
        try:
            response = self.session.get(f"{self.base_url}/v1/models", timeout=10)
            response.raise_for_status()
            models = response.json()
            return [model['id'] for model in models['data']]
        except Exception as e:
            console.print(f"[red]Error fetching models: {e}[/red]")
            return []
    
    def chat_completion(
        self, 
        messages: List[Dict[str, str]], 
        stream: bool = False,
        **kwargs
    ) -> Iterator[str] if stream else str:
        """Get chat completion"""
        payload = {
            'model': self.model,
            'messages': messages,
            'stream': stream,
            **kwargs
        }
        
        try:
            response = self.session.post(
                f"{self.base_url}/v1/chat/completions",
                json=payload,
                stream=stream,
                timeout=120
            )
            response.raise_for_status()
            
            if stream:
                return self._stream_response(response)
            else:
                result = response.json()
                return result['choices'][0]['message']['content']
        except Exception as e:
            if stream:
                yield f"Error: {e}"
            else:
                return f"Error: {e}"
    
    def _stream_response(self, response) -> Iterator[str]:
        """Process streaming response"""
        for line in response.iter_lines():
            if line:
                line_text = line.decode('utf-8')
                if line_text.startswith('data: '):
                    data = line_text[6:]
                    if data == '[DONE]':
                        break
                    
                    try:
                        chunk = json.loads(data)
                        content = chunk['choices'][0]['delta'].get('content', '')
                        if content:
                            yield content
                    except json.JSONDecodeError:
                        continue

@click.group()
@click.option('--api-url', default='http://localhost:8080', help='LLM API URL')
@click.option('--model', default='llama-2-7b-chat', help='Model to use')
@click.option('--api-key', help='API key if required')
@click.option('--config', help='Configuration file path')
@click.pass_context
def cli(ctx, api_url, model, api_key, config):
    """Local LLM CLI tool for chat, analysis, and automation"""
    
    # Load configuration if provided
    if config and os.path.exists(config):
        with open(config, 'r') as f:
            config_data = yaml.safe_load(f)
        api_url = config_data.get('api_url', api_url)
        model = config_data.get('model', model)
        api_key = config_data.get('api_key', api_key)
    
    ctx.ensure_object(dict)
    ctx.obj['client'] = LLMClient(api_url, model, api_key)

@cli.command()
@click.pass_context
def models(ctx):
    """List available models"""
    client = ctx.obj['client']
    
    with Progress(SpinnerColumn(), TextColumn("[progress.description]{task.description}")) as progress:
        task = progress.add_task("Fetching models...", total=None)
        models_list = client.list_models()
    
    if models_list:
        table = Table(title="Available Models")
        table.add_column("Model ID", style="cyan")
        
        for model in models_list:
            table.add_row(model)
        
        console.print(table)
    else:
        console.print("[red]No models available or connection failed[/red]")

@cli.command()
@click.argument('message')
@click.option('--system', help='System prompt')
@click.option('--temperature', type=float, default=0.7, help='Temperature (0.0-2.0)')
@click.option('--max-tokens', type=int, default=500, help='Maximum tokens')
@click.option('--stream/--no-stream', default=True, help='Stream response')
@click.option('--save', help='Save conversation to file')
@click.pass_context
def chat(ctx, message, system, temperature, max_tokens, stream, save):
    """Send a chat message"""
    client = ctx.obj['client']
    
    messages = []
    if system:
        messages.append({'role': 'system', 'content': system})
    messages.append({'role': 'user', 'content': message})
    
    if stream:
        console.print(Panel(f"[bold]User:[/bold] {message}", border_style="blue"))
        console.print("[bold]Assistant:[/bold]", end=" ")
        
        full_response = ""
        for chunk in client.chat_completion(
            messages, 
            stream=True,
            temperature=temperature,
            max_tokens=max_tokens
        ):
            console.print(chunk, end="")
            full_response += chunk
        
        console.print("\n")
        
        if save:
            conversation = {
                'messages': messages + [{'role': 'assistant', 'content': full_response}],
                'settings': {
                    'temperature': temperature,
                    'max_tokens': max_tokens
                }
            }
            with open(save, 'w') as f:
                json.dump(conversation, f, indent=2)
            console.print(f"[green]Conversation saved to {save}[/green]")
    
    else:
        response = client.chat_completion(
            messages,
            temperature=temperature,
            max_tokens=max_tokens
        )
        console.print(Panel(response, title="Response", border_style="green"))

@cli.command()
@click.argument('file_path', type=click.Path(exists=True))
@click.option('--action', default='analyze', 
              type=click.Choice(['analyze', 'summarize', 'explain', 'translate', 'review']),
              help='Action to perform on file')
@click.option('--language', help='Target language for translation')
@click.option('--output', help='Output file path')
@click.pass_context
def file(ctx, file_path, action, language, output):
    """Process a file with LLM"""
    client = ctx.obj['client']
    
    # Read file content
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        console.print(f"[red]Error reading file: {e}[/red]")
        return
    
    # Create prompt based on action
    prompts = {
        'analyze': f"Please analyze the following content and provide insights:\n\n{content}",
        'summarize': f"Please provide a concise summary of the following content:\n\n{content}",
        'explain': f"Please explain the following content in simple terms:\n\n{content}",
        'translate': f"Please translate the following content to {language or 'Spanish'}:\n\n{content}",
        'review': f"Please review the following content and provide feedback:\n\n{content}"
    }
    
    message = prompts[action]
    messages = [{'role': 'user', 'content': message}]
    
    console.print(f"[blue]Processing file: {file_path}[/blue]")
    console.print(f"[blue]Action: {action.title()}[/blue]")
    
    response = client.chat_completion(messages, temperature=0.7, max_tokens=1000)
    
    if output:
        with open(output, 'w', encoding='utf-8') as f:
            f.write(response)
        console.print(f"[green]Output saved to {output}[/green]")
    else:
        console.print(Panel(response, title=f"{action.title()} Result", border_style="green"))

@cli.command()
@click.option('--history-file', default='~/.llm_history.json', help='Conversation history file')
@click.pass_context
def interactive(ctx, history_file):
    """Start interactive chat session"""
    client = ctx.obj['client']
    
    history_path = os.path.expanduser(history_file)
    conversation = []
    
    # Load history if exists
    if os.path.exists(history_path):
        try:
            with open(history_path, 'r') as f:
                data = json.load(f)
                conversation = data.get('messages', [])
            console.print(f"[green]Loaded {len(conversation)} messages from history[/green]")
        except Exception:
            pass
    
    console.print(Panel("Interactive LLM Chat Session", title="Welcome", border_style="blue"))
    console.print("Type 'quit' or 'exit' to end the session")
    console.print("Type '/clear' to clear conversation history")
    console.print("Type '/save' to save current conversation")
    console.print()
    
    try:
        while True:
            user_input = console.input("[bold blue]You:[/bold blue] ")
            
            if user_input.lower() in ['quit', 'exit']:
                break
            elif user_input == '/clear':
                conversation = []
                console.print("[yellow]Conversation cleared[/yellow]")
                continue
            elif user_input == '/save':
                try:
                    with open(history_path, 'w') as f:
                        json.dump({'messages': conversation}, f, indent=2)
                    console.print(f"[green]Conversation saved to {history_path}[/green]")
                except Exception as e:
                    console.print(f"[red]Error saving: {e}[/red]")
                continue
            elif not user_input.strip():
                continue
            
            conversation.append({'role': 'user', 'content': user_input})
            
            console.print("[bold green]Assistant:[/bold green] ", end="")
            full_response = ""
            
            for chunk in client.chat_completion(conversation, stream=True):
                console.print(chunk, end="")
                full_response += chunk
            
            console.print()
            conversation.append({'role': 'assistant', 'content': full_response})
    
    except KeyboardInterrupt:
        console.print("\n[yellow]Session interrupted[/yellow]")
    
    # Auto-save on exit
    try:
        with open(history_path, 'w') as f:
            json.dump({'messages': conversation}, f, indent=2)
        console.print(f"[green]Session saved to {history_path}[/green]")
    except Exception:
        pass

@cli.command()
@click.argument('directory', type=click.Path(exists=True))
@click.option('--pattern', default='*.py', help='File pattern to process')
@click.option('--action', default='document', 
              type=click.Choice(['document', 'review', 'test', 'optimize']),
              help='Action to perform')
@click.option('--output-dir', help='Output directory for results')
@click.pass_context
def batch(ctx, directory, pattern, action, output_dir):
    """Process multiple files in batch"""
    client = ctx.obj['client']
    
    from glob import glob
    
    files = glob(os.path.join(directory, pattern), recursive=True)
    
    if not files:
        console.print(f"[red]No files found matching pattern: {pattern}[/red]")
        return
    
    console.print(f"[blue]Found {len(files)} files to process[/blue]")
    
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
    
    with Progress() as progress:
        task = progress.add_task(f"Processing files...", total=len(files))
        
        for file_path in files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                prompt = f"Please {action} the following code:\n\n{content}"
                messages = [{'role': 'user', 'content': prompt}]
                
                response = client.chat_completion(messages, temperature=0.3, max_tokens=1000)
                
                if output_dir:
                    output_file = os.path.join(output_dir, f"{os.path.basename(file_path)}.{action}.md")
                    with open(output_file, 'w', encoding='utf-8') as f:
                        f.write(f"# {action.title()} for {file_path}\n\n{response}")
                
                progress.advance(task)
                
            except Exception as e:
                console.print(f"[red]Error processing {file_path}: {e}[/red]")
                progress.advance(task)
    
    console.print(f"[green]Batch processing complete![/green]")

if __name__ == '__main__':
    cli()
```

This comprehensive Application Integration section covers web applications (React, Vue.js), desktop applications (Electron, Python Tkinter), mobile applications (React Native), and CLI tools with advanced features. Each example includes proper error handling, streaming support, and production-ready patterns.

## Middleware and Proxies

Infrastructure components for scaling, routing, and managing local LLM deployments in production environments.

### API Gateway

Centralized routing, authentication, and management for local LLM services.

**Kong API Gateway Configuration:**

```yaml
# kong.yml - Kong configuration for LLM routing
_format_version: "3.0"

services:
  - name: llm-service-1
    url: http://localhost:8080
    tags:
      - llm
      - local
    
  - name: llm-service-2  
    url: http://localhost:8081
    tags:
      - llm
      - local

routes:
  - name: chat-completions
    service: llm-service-1
    paths:
      - /v1/chat/completions
    methods:
      - POST
    strip_path: false
    
  - name: embeddings
    service: llm-service-2
    paths:
      - /v1/embeddings
    methods:
      - POST
    strip_path: false
    
  - name: models
    service: llm-service-1
    paths:
      - /v1/models
    methods:
      - GET
    strip_path: false

plugins:
  - name: key-auth
    config:
      key_names:
        - apikey
        - X-API-Key
      hide_credentials: true
    
  - name: rate-limiting
    config:
      minute: 100
      hour: 1000
      policy: local
      hide_client_headers: false
      
  - name: cors
    config:
      origins:
        - "*"
      methods:
        - GET
        - POST
        - OPTIONS
      headers:
        - Accept
        - Accept-Version
        - Content-Length
        - Content-MD5
        - Content-Type
        - Date
        - X-API-Key
      exposed_headers:
        - X-Auth-Token
      credentials: true
      max_age: 3600

consumers:
  - username: frontend-app
    keyauth_credentials:
      - key: frontend-app-key-123
  - username: backend-service
    keyauth_credentials:
      - key: backend-service-key-456
```

**Custom Express.js API Gateway:**

```javascript
// api-gateway.js - Custom Node.js API Gateway
const express = require('express');
const httpProxy = require('http-proxy-middleware');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const cors = require('cors');
const Redis = require('redis');
const jwt = require('jsonwebtoken');

class LLMAPIGateway {
  constructor() {
    this.app = express();
    this.redis = Redis.createClient();
    this.llmServices = [
      { url: 'http://localhost:8080', weight: 1, healthy: true },
      { url: 'http://localhost:8081', weight: 1, healthy: true },
      { url: 'http://localhost:8082', weight: 2, healthy: true }
    ];
    
    this.setupMiddleware();
    this.setupRoutes();
    this.startHealthChecks();
  }

  setupMiddleware() {
    // Security headers
    this.app.use(helmet());
    
    // CORS
    this.app.use(cors({
      origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
      credentials: true
    }));

    // Rate limiting
    const limiter = rateLimit({
      windowMs: 15 * 60 * 1000, // 15 minutes
      max: 100, // limit each IP to 100 requests per windowMs
      message: 'Too many requests from this IP',
      standardHeaders: true,
      legacyHeaders: false,
      keyGenerator: (req) => {
        return req.ip + ':' + (req.headers['x-api-key'] || 'anonymous');
      }
    });
    this.app.use(limiter);

    // Request parsing
    this.app.use(express.json({ limit: '10mb' }));
    this.app.use(express.urlencoded({ extended: true }));

    // Authentication middleware
    this.app.use(this.authenticateRequest.bind(this));
    
    // Request logging
    this.app.use(this.logRequest.bind(this));
  }

  async authenticateRequest(req, res, next) {
    // Skip auth for health checks
    if (req.path === '/health') {
      return next();
    }

    const apiKey = req.headers['x-api-key'] || req.headers['authorization']?.replace('Bearer ', '');
    
    if (!apiKey) {
      return res.status(401).json({ error: 'API key required' });
    }

    try {
      // Check if API key is valid (implement your logic)
      const isValid = await this.validateAPIKey(apiKey);
      if (!isValid) {
        return res.status(401).json({ error: 'Invalid API key' });
      }

      req.user = { apiKey, authenticated: true };
      next();
    } catch (error) {
      res.status(500).json({ error: 'Authentication error' });
    }
  }

  async validateAPIKey(apiKey) {
    // Check cache first
    const cached = await this.redis.get(`api_key:${apiKey}`);
    if (cached) {
      return JSON.parse(cached);
    }

    // Validate against database/service
    const validKeys = ['key-123', 'key-456', 'key-789']; // Replace with DB lookup
    const isValid = validKeys.includes(apiKey);

    // Cache result for 5 minutes
    await this.redis.setEx(`api_key:${apiKey}`, 300, JSON.stringify(isValid));
    
    return isValid;
  }

  logRequest(req, res, next) {
    const start = Date.now();
    
    res.on('finish', () => {
      const duration = Date.now() - start;
      console.log(`${new Date().toISOString()} ${req.method} ${req.path} ${res.statusCode} ${duration}ms`);
    });
    
    next();
  }

  selectLLMService() {
    // Weighted round-robin selection
    const healthyServices = this.llmServices.filter(service => service.healthy);
    
    if (healthyServices.length === 0) {
      throw new Error('No healthy LLM services available');
    }

    // Simple random selection weighted by service weight
    const totalWeight = healthyServices.reduce((sum, service) => sum + service.weight, 0);
    let random = Math.random() * totalWeight;
    
    for (const service of healthyServices) {
      random -= service.weight;
      if (random <= 0) {
        return service;
      }
    }
    
    return healthyServices[0]; // fallback
  }

  setupRoutes() {
    // Health check
    this.app.get('/health', (req, res) => {
      const healthyCount = this.llmServices.filter(s => s.healthy).length;
      res.json({
        status: healthyCount > 0 ? 'healthy' : 'unhealthy',
        services: {
          total: this.llmServices.length,
          healthy: healthyCount
        },
        timestamp: new Date().toISOString()
      });
    });

    // Proxy LLM requests
    this.app.use('/v1', (req, res, next) => {
      try {
        const selectedService = this.selectLLMService();
        
        const proxy = httpProxy.createProxyMiddleware({
          target: selectedService.url,
          changeOrigin: true,
          timeout: 120000, // 2 minutes
          proxyTimeout: 120000,
          onError: (err, req, res) => {
            console.error('Proxy error:', err);
            if (!res.headersSent) {
              res.status(502).json({ error: 'LLM service unavailable' });
            }
          },
          onProxyReq: (proxyReq, req, res) => {
            // Add tracking headers
            proxyReq.setHeader('X-Gateway-ID', 'llm-gateway');
            proxyReq.setHeader('X-Request-ID', req.headers['x-request-id'] || Math.random().toString(36).substr(2, 9));
          }
        });

        proxy(req, res, next);
      } catch (error) {
        console.error('Service selection error:', error);
        res.status(503).json({ error: 'No available LLM services' });
      }
    });
  }

  async startHealthChecks() {
    const checkInterval = 30000; // 30 seconds
    
    setInterval(async () => {
      for (const service of this.llmServices) {
        try {
          const response = await fetch(`${service.url}/v1/models`, {
            method: 'GET',
            timeout: 5000
          });
          service.healthy = response.ok;
        } catch (error) {
          service.healthy = false;
        }
      }
      
      const healthyCount = this.llmServices.filter(s => s.healthy).length;
      console.log(`Health check completed: ${healthyCount}/${this.llmServices.length} services healthy`);
    }, checkInterval);
  }

  start(port = 3000) {
    this.app.listen(port, () => {
      console.log(`LLM API Gateway running on port ${port}`);
    });
  }
}

// Usage
const gateway = new LLMAPIGateway();
gateway.start(process.env.PORT || 3000);

module.exports = LLMAPIGateway;
```

### Load Balancing

Distribute requests across multiple LLM instances for improved performance and reliability.

**Nginx Load Balancer Configuration:**

```nginx
# nginx.conf - Advanced load balancing for LLM services
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    # Logging format
    log_format llm_access '$remote_addr - $remote_user [$time_local] '
                         '"$request" $status $body_bytes_sent '
                         '"$http_referer" "$http_user_agent" '
                         'rt=$request_time uct="$upstream_connect_time" '
                         'uht="$upstream_header_time" urt="$upstream_response_time"';
    
    access_log /var/log/nginx/llm_access.log llm_access;
    error_log  /var/log/nginx/llm_error.log warn;
    
    # Rate limiting zones
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $http_x_api_key zone=authenticated:10m rate=100r/s;
    
    # Connection limiting
    limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;
    
    # Upstream configuration - LLM services
    upstream llm_chat {
        # Weighted round-robin
        server localhost:8080 weight=3 max_fails=2 fail_timeout=30s;
        server localhost:8081 weight=3 max_fails=2 fail_timeout=30s;
        server localhost:8082 weight=2 max_fails=2 fail_timeout=30s;
        
        # Health checks
        keepalive 32;
        keepalive_requests 100;
        keepalive_timeout 60s;
    }
    
    upstream llm_embeddings {
        # Dedicated embedding servers
        server localhost:8083 weight=1 max_fails=2 fail_timeout=30s;
        server localhost:8084 weight=1 max_fails=2 fail_timeout=30s;
        
        keepalive 16;
    }
    
    # Cache configuration
    proxy_cache_path /var/cache/nginx/llm 
                     levels=1:2 
                     keys_zone=llm_cache:10m 
                     max_size=1g 
                     inactive=60m 
                     use_temp_path=off;

    server {
        listen 80;
        listen [::]:80;
        server_name api.yourdomain.com;
        
        # Redirect to HTTPS
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name api.yourdomain.com;
        
        # SSL configuration
        ssl_certificate /etc/ssl/certs/api.yourdomain.com.crt;
        ssl_certificate_key /etc/ssl/private/api.yourdomain.com.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;
        
        # Security headers
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
        
        # Rate limiting
        limit_req zone=api burst=20 nodelay;
        limit_conn conn_limit_per_ip 10;
        
        # Request size limits
        client_max_body_size 10M;
        client_body_timeout 60s;
        client_header_timeout 60s;
        
        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
        
        # Chat completions - primary LLM services
        location /v1/chat/completions {
            # Authentication check
            if ($http_x_api_key = "") {
                return 401 '{"error":"API key required"}';
            }
            
            # Apply authenticated rate limiting
            limit_req zone=authenticated burst=50 nodelay;
            
            # Proxy settings
            proxy_pass http://llm_chat;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Request-ID $request_id;
            
            # Timeouts
            proxy_connect_timeout 30s;
            proxy_send_timeout 120s;
            proxy_read_timeout 120s;
            
            # Buffer settings for streaming
            proxy_buffering off;
            proxy_cache off;
            proxy_request_buffering off;
            
            # Error handling
            proxy_intercept_errors on;
            error_page 502 503 504 = @llm_error;
        }
        
        # Embeddings - dedicated embedding services  
        location /v1/embeddings {
            if ($http_x_api_key = "") {
                return 401 '{"error":"API key required"}';
            }
            
            limit_req zone=authenticated burst=30 nodelay;
            
            proxy_pass http://llm_embeddings;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            proxy_connect_timeout 30s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
            
            # Enable caching for embeddings (if deterministic)
            proxy_cache llm_cache;
            proxy_cache_methods GET POST;
            proxy_cache_key "$request_method$request_uri$request_body";
            proxy_cache_valid 200 1h;
            proxy_cache_bypass $http_cache_control;
            add_header X-Cache-Status $upstream_cache_status;
        }
        
        # Models endpoint - cacheable
        location /v1/models {
            if ($http_x_api_key = "") {
                return 401 '{"error":"API key required"}';
            }
            
            limit_req zone=authenticated burst=10 nodelay;
            
            proxy_pass http://llm_chat;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Aggressive caching for models list
            proxy_cache llm_cache;
            proxy_cache_valid 200 5m;
            proxy_cache_key "$request_method$request_uri";
            add_header X-Cache-Status $upstream_cache_status;
        }
        
        # Error handling
        location @llm_error {
            internal;
            add_header Content-Type application/json;
            return 503 '{"error":"LLM service temporarily unavailable","retry_after":30}';
        }
        
        # Metrics endpoint for monitoring
        location /metrics {
            stub_status on;
            access_log off;
            allow 127.0.0.1;
            allow 10.0.0.0/8;
            deny all;
        }
    }
}
```

**HAProxy Configuration:**

```haproxy
# haproxy.cfg - HAProxy configuration for LLM load balancing
global
    daemon
    log stdout local0 info
    maxconn 4096
    user haproxy
    group haproxy
    
    # SSL configuration
    ssl-default-bind-ciphers ECDHE+aes128gcm:ECDHE+aes256gcm:ECDHE+aes128sha256:ECDHE+aes256sha256:ECDHE+aes128sha:ECDHE+aes256sha:ECDHE+3des:RSA+aes128gcm:RSA+aes256gcm:RSA+aes128sha256:RSA+aes256sha256:RSA+aes128sha:RSA+aes256sha:RSA+3des
    ssl-default-bind-options no-sslv3 no-tls-tickets
    ssl-default-server-ciphers ECDHE+aes128gcm:ECDHE+aes256gcm:ECDHE+aes128sha256:ECDHE+aes256sha256:ECDHE+aes128sha:ECDHE+aes256sha:ECDHE+3des:RSA+aes128gcm:RSA+aes256gcm:RSA+aes128sha256:RSA+aes256sha256:RSA+aes128sha:RSA+aes256sha:RSA+3des
    ssl-default-server-options no-sslv3 no-tls-tickets

defaults
    mode http
    log global
    option httplog
    option dontlognull
    option http-server-close
    option forwardfor except 127.0.0.0/8
    option redispatch
    retries 3
    timeout http-request 30s
    timeout queue 30s
    timeout connect 30s
    timeout client 120s
    timeout server 120s
    timeout http-keep-alive 10s
    timeout check 10s
    maxconn 3000

# Frontend - HTTPS termination
frontend llm_frontend
    bind *:443 ssl crt /etc/ssl/certs/api.yourdomain.com.pem
    bind *:80
    
    # Redirect HTTP to HTTPS
    redirect scheme https if !{ ssl_fc }
    
    # Security headers
    http-response set-header X-Frame-Options DENY
    http-response set-header X-Content-Type-Options nosniff
    http-response set-header X-XSS-Protection "1; mode=block"
    http-response set-header Strict-Transport-Security "max-age=31536000; includeSubDomains"
    
    # Rate limiting using stick tables
    stick-table type ip size 100k expire 30s store http_req_rate(10s),http_err_rate(10s)
    http-request track-sc0 src
    http-request deny if { sc_http_req_rate(0) gt 20 }
    
    # API key validation
    http-request deny unless { req.hdr(x-api-key) -m found }
    
    # Route based on path
    use_backend llm_chat_backend if { path_beg /v1/chat/completions }
    use_backend llm_embeddings_backend if { path_beg /v1/embeddings }
    use_backend llm_models_backend if { path_beg /v1/models }
    
    default_backend llm_chat_backend

# Backend - Chat completions (streaming support)
backend llm_chat_backend
    balance roundrobin
    option httpchk GET /v1/models
    http-check expect status 200
    
    server llm1 localhost:8080 check weight 3 maxconn 100
    server llm2 localhost:8081 check weight 3 maxconn 100  
    server llm3 localhost:8082 check weight 2 maxconn 80
    
    # No buffering for streaming responses
    option http-buffer-request
    no option httpclose

# Backend - Embeddings
backend llm_embeddings_backend
    balance leastconn
    option httpchk GET /health
    
    server embed1 localhost:8083 check weight 1 maxconn 50
    server embed2 localhost:8084 check weight 1 maxconn 50

# Backend - Models (cached responses)
backend llm_models_backend
    balance first
    option httpchk GET /v1/models
    
    server llm1 localhost:8080 check
    server llm2 localhost:8081 check backup
    
# Statistics
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE
```

### Caching Layer

Intelligent response caching to improve performance and reduce computational load.

**Redis Caching Middleware:**

```python
# llm_cache.py - Intelligent caching for LLM responses
import redis
import hashlib
import json
import time
from typing import Optional, Dict, Any, List
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
import pickle
import asyncio
import aioredis

@dataclass
class CacheKey:
    model: str
    messages: List[Dict[str, str]]
    temperature: float
    max_tokens: int
    top_p: float = 1.0
    frequency_penalty: float = 0.0
    presence_penalty: float = 0.0
    
    def to_hash(self) -> str:
        """Generate a hash for cache key"""
        # Normalize the data for consistent hashing
        normalized = {
            'model': self.model,
            'messages': json.dumps(self.messages, sort_keys=True),
            'temperature': round(self.temperature, 2),
            'max_tokens': self.max_tokens,
            'top_p': round(self.top_p, 2),
            'frequency_penalty': round(self.frequency_penalty, 2),
            'presence_penalty': round(self.presence_penalty, 2)
        }
        
        serialized = json.dumps(normalized, sort_keys=True)
        return hashlib.sha256(serialized.encode()).hexdigest()

@dataclass 
class CachedResponse:
    content: str
    model: str
    usage: Dict[str, int]
    cached_at: datetime
    hit_count: int = 1
    
class LLMCache:
    def __init__(self, redis_url: str = "redis://localhost:6379", prefix: str = "llm:"):
        self.redis = redis.from_url(redis_url, decode_responses=True)
        self.prefix = prefix
        self.stats_key = f"{prefix}stats"
        
    def _make_cache_key(self, key: CacheKey) -> str:
        return f"{self.prefix}response:{key.to_hash()}"
    
    def _make_stats_key(self, model: str) -> str:
        return f"{self.stats_key}:{model}"
    
    async def get(self, key: CacheKey, deterministic_only: bool = True) -> Optional[CachedResponse]:
        """Get cached response if available"""
        
        # Skip cache for non-deterministic requests
        if deterministic_only and (key.temperature > 0.1 or key.top_p < 0.95):
            return None
        
        cache_key = self._make_cache_key(key)
        
        try:
            cached_data = self.redis.get(cache_key)
            if cached_data:
                response = CachedResponse(**json.loads(cached_data))
                
                # Update hit count
                response.hit_count += 1
                self.redis.set(cache_key, json.dumps(asdict(response)), ex=3600)
                
                # Update stats
                self._update_stats(key.model, 'hit')
                
                return response
                
        except Exception as e:
            print(f"Cache get error: {e}")
            
        self._update_stats(key.model, 'miss')
        return None
    
    async def set(self, key: CacheKey, response: str, usage: Dict[str, int], ttl: int = 3600):
        """Cache a response"""
        
        cached_response = CachedResponse(
            content=response,
            model=key.model,
            usage=usage,
            cached_at=datetime.now(),
            hit_count=1
        )
        
        cache_key = self._make_cache_key(key)
        
        try:
            self.redis.set(
                cache_key, 
                json.dumps(asdict(cached_response), default=str),
                ex=ttl
            )
            
        except Exception as e:
            print(f"Cache set error: {e}")
    
    def _update_stats(self, model: str, stat_type: str):
        """Update cache statistics"""
        stats_key = self._make_stats_key(model)
        pipe = self.redis.pipeline()
        
        pipe.hincrby(stats_key, stat_type, 1)
        pipe.hincrby(stats_key, 'total', 1)
        pipe.expire(stats_key, 86400)  # 24 hours
        
        pipe.execute()
    
    def get_stats(self, model: str) -> Dict[str, Any]:
        """Get cache statistics for a model"""
        stats_key = self._make_stats_key(model)
        stats = self.redis.hgetall(stats_key)
        
        if not stats:
            return {'hit': 0, 'miss': 0, 'total': 0, 'hit_rate': 0.0}
        
        hit = int(stats.get('hit', 0))
        miss = int(stats.get('miss', 0))
        total = hit + miss
        hit_rate = (hit / total * 100) if total > 0 else 0.0
        
        return {
            'hit': hit,
            'miss': miss,
            'total': total,
            'hit_rate': round(hit_rate, 2)
        }
    
    def clear_cache(self, model: Optional[str] = None):
        """Clear cache for specific model or all models"""
        if model:
            pattern = f"{self.prefix}response:*"
            keys = self.redis.keys(pattern)
            
            # Filter by model (would need to decode each key)
            # For simplicity, this clears all - in production, use model-specific prefixes
            if keys:
                self.redis.delete(*keys)
        else:
            pattern = f"{self.prefix}*"
            keys = self.redis.keys(pattern)
            if keys:
                self.redis.delete(*keys)

# FastAPI middleware integration
from fastapi import FastAPI, Request, Response
from fastapi.middleware.base import BaseHTTPMiddleware
import json

class LLMCacheMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, cache: LLMCache):
        super().__init__(app)
        self.cache = cache
        
    async def dispatch(self, request: Request, call_next):
        # Only cache chat completions
        if request.url.path != "/v1/chat/completions" or request.method != "POST":
            return await call_next(request)
        
        # Read request body
        body = await request.body()
        
        try:
            data = json.loads(body)
            
            # Create cache key
            cache_key = CacheKey(
                model=data.get('model', 'default'),
                messages=data.get('messages', []),
                temperature=data.get('temperature', 0.7),
                max_tokens=data.get('max_tokens', 500),
                top_p=data.get('top_p', 1.0),
                frequency_penalty=data.get('frequency_penalty', 0.0),
                presence_penalty=data.get('presence_penalty', 0.0)
            )
            
            # Check cache
            cached_response = await self.cache.get(cache_key)
            
            if cached_response:
                # Return cached response
                response_data = {
                    "id": f"chatcmpl-cached-{int(time.time())}",
                    "object": "chat.completion",
                    "created": int(time.time()),
                    "model": cached_response.model,
                    "choices": [{
                        "index": 0,
                        "message": {
                            "role": "assistant",
                            "content": cached_response.content
                        },
                        "finish_reason": "stop"
                    }],
                    "usage": cached_response.usage,
                    "cached": True,
                    "cache_hit_count": cached_response.hit_count
                }
                
                return Response(
                    content=json.dumps(response_data),
                    media_type="application/json",
                    headers={"X-Cache": "HIT"}
                )
            
            # Proceed with original request
            # Recreate request with body
            request._body = body
            response = await call_next(request)
            
            # Cache the response if successful
            if response.status_code == 200 and not data.get('stream', False):
                response_body = b""
                async for chunk in response.body_iterator:
                    response_body += chunk
                
                try:
                    response_data = json.loads(response_body)
                    if 'choices' in response_data and response_data['choices']:
                        content = response_data['choices'][0]['message']['content']
                        usage = response_data.get('usage', {})
                        
                        await self.cache.set(cache_key, content, usage)
                        
                except Exception as e:
                    print(f"Error caching response: {e}")
                
                return Response(
                    content=response_body,
                    status_code=response.status_code,
                    headers=dict(response.headers) | {"X-Cache": "MISS"}
                )
            
        except Exception as e:
            print(f"Cache middleware error: {e}")
        
        return await call_next(request)

# Usage example
app = FastAPI()
cache = LLMCache("redis://localhost:6379")
app.add_middleware(LLMCacheMiddleware, cache=cache)

@app.get("/cache/stats/{model}")
async def get_cache_stats(model: str):
    return cache.get_stats(model)

@app.delete("/cache/clear")
async def clear_cache():
    cache.clear_cache()
    return {"status": "Cache cleared"}
```

### Rate Limiting

Advanced rate limiting strategies to manage API usage and prevent abuse.

**Token Bucket Rate Limiter:**

```python
# rate_limiter.py - Advanced rate limiting for LLM APIs
import time
import asyncio
import redis
import json
from typing import Dict, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime, timedelta
import math

@dataclass
class RateLimit:
    requests_per_minute: int
    requests_per_hour: int
    requests_per_day: int
    tokens_per_minute: int  # For token-based limiting
    burst_capacity: int = None
    
    def __post_init__(self):
        if self.burst_capacity is None:
            self.burst_capacity = self.requests_per_minute

class TokenBucketLimiter:
    def __init__(self, redis_client: redis.Redis, prefix: str = "rate_limit:"):
        self.redis = redis_client
        self.prefix = prefix
    
    def _get_bucket_key(self, identifier: str, window: str) -> str:
        return f"{self.prefix}{identifier}:{window}"
    
    async def check_rate_limit(
        self, 
        identifier: str, 
        limits: RateLimit,
        tokens_requested: int = 1
    ) -> Tuple[bool, Dict[str, any]]:
        """
        Check if request is within rate limits
        Returns: (allowed, info_dict)
        """
        current_time = time.time()
        
        # Check multiple time windows
        checks = [
            ("minute", limits.requests_per_minute, 60),
            ("hour", limits.requests_per_hour, 3600), 
            ("day", limits.requests_per_day, 86400)
        ]
        
        pipe = self.redis.pipeline()
        
        for window, limit, duration in checks:
            key = self._get_bucket_key(identifier, window)
            
            # Use sliding window counter
            pipe.zremrangebyscore(key, 0, current_time - duration)
            pipe.zcard(key)
            pipe.expire(key, duration)
        
        results = pipe.execute()
        
        # Process results
        for i, (window, limit, duration) in enumerate(checks):
            count = results[i * 3 + 1]  # Get count from zcard
            
            if count >= limit:
                reset_time = current_time + duration
                return False, {
                    "allowed": False,
                    "limit": limit,
                    "remaining": max(0, limit - count),
                    "reset_time": reset_time,
                    "retry_after": duration - (current_time % duration),
                    "window": window
                }
        
        # Token-based limiting for LLM usage
        if limits.tokens_per_minute and tokens_requested > 1:
            token_allowed = await self._check_token_bucket(
                identifier, 
                limits.tokens_per_minute,
                tokens_requested,
                60
            )
            
            if not token_allowed:
                return False, {
                    "allowed": False,
                    "error": "Token rate limit exceeded",
                    "tokens_requested": tokens_requested,
                    "tokens_per_minute": limits.tokens_per_minute
                }
        
        # Record the request
        await self._record_request(identifier, current_time)
        
        return True, {
            "allowed": True,
            "remaining": {
                "minute": max(0, limits.requests_per_minute - results[1]),
                "hour": max(0, limits.requests_per_hour - results[4]),
                "day": max(0, limits.requests_per_day - results[7])
            }
        }
    
    async def _check_token_bucket(
        self, 
        identifier: str, 
        rate: int, 
        tokens: int,
        window: int
    ) -> bool:
        """Token bucket algorithm for token-based rate limiting"""
        bucket_key = f"{self.prefix}tokens:{identifier}"
        current_time = time.time()
        
        # Get current bucket state
        bucket_data = self.redis.hgetall(bucket_key)
        
        if bucket_data:
            last_refill = float(bucket_data.get('last_refill', current_time))
            current_tokens = float(bucket_data.get('tokens', rate))
        else:
            last_refill = current_time
            current_tokens = rate
        
        # Calculate tokens to add based on time elapsed
        time_elapsed = current_time - last_refill
        tokens_to_add = (time_elapsed / window) * rate
        current_tokens = min(rate, current_tokens + tokens_to_add)
        
        # Check if we have enough tokens
        if current_tokens >= tokens:
            current_tokens -= tokens
            
            # Update bucket
            self.redis.hset(bucket_key, mapping={
                'tokens': current_tokens,
                'last_refill': current_time
            })
            self.redis.expire(bucket_key, window * 2)
            
            return True
        
        return False
    
    async def _record_request(self, identifier: str, timestamp: float):
        """Record a request for rate limiting"""
        pipe = self.redis.pipeline()
        
        windows = [("minute", 60), ("hour", 3600), ("day", 86400)]
        
        for window, duration in windows:
            key = self._get_bucket_key(identifier, window)
            pipe.zadd(key, {str(timestamp): timestamp})
            pipe.expire(key, duration)
        
        pipe.execute()

# FastAPI rate limiting middleware
from fastapi import FastAPI, Request, HTTPException, status
from fastapi.responses import JSONResponse
import ipaddress

class RateLimitMiddleware:
    def __init__(self, app: FastAPI, limiter: TokenBucketLimiter):
        self.app = app
        self.limiter = limiter
        
        # Default rate limits by user type
        self.rate_limits = {
            "anonymous": RateLimit(10, 100, 1000, 1000),
            "authenticated": RateLimit(100, 1000, 10000, 10000), 
            "premium": RateLimit(1000, 10000, 100000, 100000),
            "internal": RateLimit(10000, 100000, 1000000, 1000000)
        }
        
        self.whitelist = {
            ipaddress.ip_network("127.0.0.0/8"),
            ipaddress.ip_network("10.0.0.0/8"),
            ipaddress.ip_network("172.16.0.0/12"),
            ipaddress.ip_network("192.168.0.0/16")
        }
    
    async def __call__(self, request: Request, call_next):
        # Skip rate limiting for whitelisted IPs
        client_ip = ipaddress.ip_address(request.client.host)
        if any(client_ip in network for network in self.whitelist):
            return await call_next(request)
        
        # Determine user type and identifier
        api_key = request.headers.get("X-API-Key") or request.headers.get("Authorization", "").replace("Bearer ", "")
        
        if api_key:
            user_type = await self._get_user_type(api_key)
            identifier = f"api_key:{api_key}"
        else:
            user_type = "anonymous"
            identifier = f"ip:{request.client.host}"
        
        # Get rate limits for user type
        limits = self.rate_limits.get(user_type, self.rate_limits["anonymous"])
        
        # Estimate token usage for LLM requests
        tokens_requested = 1
        if request.url.path.endswith("/chat/completions"):
            try:
                body = await request.body()
                if body:
                    data = json.loads(body)
                    # Rough estimate based on request
                    estimated_tokens = self._estimate_tokens(data)
                    tokens_requested = estimated_tokens
                    
                    # Recreate request with body
                    request._body = body
            except Exception:
                pass
        
        # Check rate limits
        allowed, info = await self.limiter.check_rate_limit(
            identifier, limits, tokens_requested
        )
        
        if not allowed:
            headers = {
                "X-RateLimit-Limit": str(info.get("limit", "")),
                "X-RateLimit-Remaining": str(info.get("remaining", 0)),
                "X-RateLimit-Reset": str(info.get("reset_time", "")),
                "Retry-After": str(int(info.get("retry_after", 60)))
            }
            
            return JSONResponse(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                content={
                    "error": "Rate limit exceeded", 
                    "message": f"Too many requests in {info.get('window', 'time window')}",
                    "retry_after": int(info.get("retry_after", 60))
                },
                headers=headers
            )
        
        # Add rate limit info to response headers
        response = await call_next(request)
        
        if "remaining" in info:
            response.headers["X-RateLimit-Remaining-Minute"] = str(info["remaining"].get("minute", 0))
            response.headers["X-RateLimit-Remaining-Hour"] = str(info["remaining"].get("hour", 0))
            response.headers["X-RateLimit-Remaining-Day"] = str(info["remaining"].get("day", 0))
        
        return response
    
    def _estimate_tokens(self, data: Dict) -> int:
        """Estimate token usage for a request"""
        messages = data.get("messages", [])
        text_length = sum(len(msg.get("content", "")) for msg in messages)
        
        # Rough estimate: 4 characters per token
        input_tokens = text_length // 4
        max_tokens = data.get("max_tokens", 500)
        
        # Return total estimated tokens (input + output)
        return input_tokens + max_tokens
    
    async def _get_user_type(self, api_key: str) -> str:
        """Determine user type from API key"""
        # In production, query your user database
        user_types = {
            "premium-key": "premium",
            "internal-key": "internal"
        }
        
        return user_types.get(api_key, "authenticated")

# Usage
app = FastAPI()
redis_client = redis.from_url("redis://localhost:6379")
limiter = TokenBucketLimiter(redis_client)
app.add_middleware(RateLimitMiddleware, limiter=limiter)
```

This comprehensive Middleware and Proxies section covers API gateways (Kong, custom Node.js), load balancing (Nginx, HAProxy), intelligent caching with Redis, and advanced rate limiting with token bucket algorithms. Each component includes production-ready configurations and code examples.

## Database Integration

Integrating local LLMs with various database systems for persistent storage, vector search, and session management.

### Vector Databases

Vector databases are essential for RAG (Retrieval-Augmented Generation) applications, enabling semantic search and similarity matching.

**Pinecone Integration:**

```python
# pinecone_llm_integration.py - Pinecone with local LLM
import pinecone
import openai
from typing import List, Dict, Any, Optional
import numpy as np
from sentence_transformers import SentenceTransformer
import asyncio
import logging

class PineconeLLMIntegration:
    def __init__(
        self, 
        pinecone_api_key: str,
        pinecone_env: str,
        index_name: str,
        llm_api_url: str = "http://localhost:8080",
        embedding_model: str = "all-MiniLM-L6-v2"
    ):
        # Initialize Pinecone
        pinecone.init(api_key=pinecone_api_key, environment=pinecone_env)
        self.index = pinecone.Index(index_name)
        
        # Initialize LLM client
        self.llm_client = openai.OpenAI(
            api_key="not-needed",
            base_url=f"{llm_api_url}/v1"
        )
        
        # Initialize embedding model
        self.embedding_model = SentenceTransformer(embedding_model)
        
        self.logger = logging.getLogger(__name__)
    
    def embed_text(self, text: str) -> List[float]:
        """Generate embeddings for text"""
        try:
            embedding = self.embedding_model.encode(text)
            return embedding.tolist()
        except Exception as e:
            self.logger.error(f"Error generating embedding: {e}")
            raise
    
    async def store_document(
        self, 
        doc_id: str, 
        text: str, 
        metadata: Optional[Dict[str, Any]] = None
    ) -> bool:
        """Store document with embeddings in Pinecone"""
        try:
            # Generate embedding
            embedding = self.embed_text(text)
            
            # Prepare metadata
            doc_metadata = {
                "text": text,
                "timestamp": str(asyncio.get_event_loop().time()),
                **(metadata or {})
            }
            
            # Upsert to Pinecone
            self.index.upsert(vectors=[(doc_id, embedding, doc_metadata)])
            
            self.logger.info(f"Stored document {doc_id} in Pinecone")
            return True
            
        except Exception as e:
            self.logger.error(f"Error storing document: {e}")
            return False
    
    async def semantic_search(
        self, 
        query: str, 
        top_k: int = 5,
        filter_metadata: Optional[Dict[str, Any]] = None
    ) -> List[Dict[str, Any]]:
        """Perform semantic search in Pinecone"""
        try:
            # Generate query embedding
            query_embedding = self.embed_text(query)
            
            # Search in Pinecone
            search_response = self.index.query(
                vector=query_embedding,
                top_k=top_k,
                filter=filter_metadata,
                include_metadata=True,
                include_values=False
            )
            
            # Format results
            results = []
            for match in search_response.matches:
                results.append({
                    "id": match.id,
                    "score": match.score,
                    "text": match.metadata.get("text", ""),
                    "metadata": match.metadata
                })
            
            return results
            
        except Exception as e:
            self.logger.error(f"Error in semantic search: {e}")
            return []
    
    async def rag_query(
        self, 
        query: str, 
        model: str = "llama-2-7b-chat",
        max_context_length: int = 2000,
        system_prompt: Optional[str] = None
    ) -> Dict[str, Any]:
        """Perform RAG query using Pinecone and local LLM"""
        try:
            # Search for relevant documents
            search_results = await self.semantic_search(query, top_k=3)
            
            if not search_results:
                return {
                    "response": "I don't have relevant information to answer your question.",
                    "sources": []
                }
            
            # Build context from search results
            context_parts = []
            sources = []
            
            for result in search_results:
                if len(" ".join(context_parts)) < max_context_length:
                    context_parts.append(result["text"])
                    sources.append({
                        "id": result["id"],
                        "score": result["score"],
                        "metadata": result["metadata"]
                    })
            
            context = "\n\n".join(context_parts)
            
            # Build prompt
            messages = []
            
            if system_prompt:
                messages.append({"role": "system", "content": system_prompt})
            else:
                messages.append({
                    "role": "system", 
                    "content": "You are a helpful assistant. Answer questions based on the provided context. If the context doesn't contain relevant information, say so clearly."
                })
            
            messages.append({
                "role": "user",
                "content": f"Context:\n{context}\n\nQuestion: {query}\n\nPlease provide a comprehensive answer based on the context above."
            })
            
            # Generate response with LLM
            response = self.llm_client.chat.completions.create(
                model=model,
                messages=messages,
                temperature=0.7,
                max_tokens=500
            )
            
            return {
                "response": response.choices[0].message.content,
                "sources": sources,
                "context_used": len(context_parts)
            }
            
        except Exception as e:
            self.logger.error(f"Error in RAG query: {e}")
            return {
                "response": f"Error processing query: {str(e)}",
                "sources": []
            }
    
    async def batch_store_documents(
        self, 
        documents: List[Dict[str, Any]],
        batch_size: int = 100
    ) -> Dict[str, int]:
        """Store multiple documents in batches"""
        successful = 0
        failed = 0
        
        for i in range(0, len(documents), batch_size):
            batch = documents[i:i + batch_size]
            vectors_to_upsert = []
            
            try:
                for doc in batch:
                    embedding = self.embed_text(doc["text"])
                    vectors_to_upsert.append((
                        doc["id"],
                        embedding,
                        {
                            "text": doc["text"],
                            "timestamp": str(asyncio.get_event_loop().time()),
                            **doc.get("metadata", {})
                        }
                    ))
                
                # Batch upsert
                self.index.upsert(vectors=vectors_to_upsert)
                successful += len(batch)
                
                self.logger.info(f"Processed batch {i//batch_size + 1}, stored {len(batch)} documents")
                
            except Exception as e:
                self.logger.error(f"Error in batch {i//batch_size + 1}: {e}")
                failed += len(batch)
        
        return {"successful": successful, "failed": failed}

# Usage example
async def main():
    # Initialize integration
    rag_system = PineconeLLMIntegration(
        pinecone_api_key="your-pinecone-api-key",
        pinecone_env="your-pinecone-environment", 
        index_name="llm-knowledge-base"
    )
    
    # Store some documents
    documents = [
        {
            "id": "doc1",
            "text": "Python is a high-level programming language known for its simplicity and readability.",
            "metadata": {"category": "programming", "language": "python"}
        },
        {
            "id": "doc2", 
            "text": "Machine learning is a subset of artificial intelligence that enables computers to learn without explicit programming.",
            "metadata": {"category": "ai", "topic": "machine-learning"}
        }
    ]
    
    # Batch store documents
    result = await rag_system.batch_store_documents(documents)
    print(f"Stored documents: {result}")
    
    # Perform RAG query
    response = await rag_system.rag_query("What is Python programming language?")
    print(f"Response: {response['response']}")
    print(f"Sources used: {len(response['sources'])}")

if __name__ == "__main__":
    asyncio.run(main())
```

**Chroma Integration:**

```python
# chroma_llm_integration.py - ChromaDB with local LLM
import chromadb
from chromadb.config import Settings
import openai
from typing import List, Dict, Any, Optional
import uuid
import asyncio
from pathlib import Path

class ChromaLLMIntegration:
    def __init__(
        self,
        persist_directory: str = "./chroma_db",
        collection_name: str = "llm_documents",
        llm_api_url: str = "http://localhost:8080",
        embedding_model: str = "all-MiniLM-L6-v2"
    ):
        # Initialize ChromaDB
        self.chroma_client = chromadb.PersistentClient(
            path=persist_directory,
            settings=Settings(
                anonymized_telemetry=False,
                allow_reset=True
            )
        )
        
        # Get or create collection
        self.collection = self.chroma_client.get_or_create_collection(
            name=collection_name,
            embedding_function=chromadb.utils.embedding_functions.SentenceTransformerEmbeddingFunction(
                model_name=embedding_model
            )
        )
        
        # Initialize LLM client
        self.llm_client = openai.OpenAI(
            api_key="not-needed",
            base_url=f"{llm_api_url}/v1"
        )
    
    def add_documents(
        self,
        documents: List[str],
        metadatas: Optional[List[Dict[str, Any]]] = None,
        ids: Optional[List[str]] = None
    ) -> List[str]:
        """Add documents to ChromaDB"""
        
        # Generate IDs if not provided
        if ids is None:
            ids = [str(uuid.uuid4()) for _ in documents]
        
        # Add default metadata if not provided
        if metadatas is None:
            metadatas = [{"timestamp": str(asyncio.get_event_loop().time())} for _ in documents]
        
        try:
            self.collection.add(
                documents=documents,
                metadatas=metadatas,
                ids=ids
            )
            return ids
        except Exception as e:
            print(f"Error adding documents: {e}")
            return []
    
    def search_documents(
        self,
        query: str,
        n_results: int = 5,
        where: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Search documents in ChromaDB"""
        try:
            results = self.collection.query(
                query_texts=[query],
                n_results=n_results,
                where=where
            )
            
            # Format results
            formatted_results = []
            if results['documents'] and results['documents'][0]:
                for i in range(len(results['documents'][0])):
                    formatted_results.append({
                        "id": results['ids'][0][i],
                        "document": results['documents'][0][i],
                        "metadata": results['metadatas'][0][i] if results['metadatas'] else {},
                        "distance": results['distances'][0][i] if results['distances'] else None
                    })
            
            return {
                "results": formatted_results,
                "query": query,
                "total_results": len(formatted_results)
            }
            
        except Exception as e:
            print(f"Error searching documents: {e}")
            return {"results": [], "query": query, "total_results": 0}
    
    async def rag_chat(
        self,
        query: str,
        model: str = "llama-2-7b-chat",
        context_limit: int = 2000,
        n_context_docs: int = 3
    ) -> Dict[str, Any]:
        """RAG-powered chat using ChromaDB and local LLM"""
        
        # Search for relevant documents
        search_results = self.search_documents(query, n_results=n_context_docs)
        
        if not search_results["results"]:
            return {
                "response": "I don't have relevant information in my knowledge base.",
                "context_used": [],
                "query": query
            }
        
        # Build context
        context_parts = []
        context_metadata = []
        
        for result in search_results["results"]:
            doc_text = result["document"]
            if len(" ".join(context_parts + [doc_text])) <= context_limit:
                context_parts.append(doc_text)
                context_metadata.append({
                    "id": result["id"],
                    "metadata": result["metadata"],
                    "distance": result["distance"]
                })
        
        context = "\n\n---\n\n".join(context_parts)
        
        # Create chat messages
        messages = [
            {
                "role": "system",
                "content": "You are a helpful assistant. Use the provided context to answer questions accurately. If the context doesn't contain relevant information, say so clearly. Always cite which parts of the context you're using."
            },
            {
                "role": "user", 
                "content": f"Context:\n{context}\n\nQuestion: {query}"
            }
        ]
        
        try:
            # Generate response
            response = self.llm_client.chat.completions.create(
                model=model,
                messages=messages,
                temperature=0.7,
                max_tokens=600
            )
            
            return {
                "response": response.choices[0].message.content,
                "context_used": context_metadata,
                "query": query,
                "total_context_chars": len(context)
            }
            
        except Exception as e:
            return {
                "response": f"Error generating response: {str(e)}",
                "context_used": context_metadata,
                "query": query
            }
    
    def get_collection_stats(self) -> Dict[str, Any]:
        """Get statistics about the collection"""
        try:
            count = self.collection.count()
            
            # Get sample of documents to analyze
            sample = self.collection.peek(limit=min(10, count))
            
            return {
                "total_documents": count,
                "collection_name": self.collection.name,
                "sample_ids": sample.get("ids", [])[:5],
                "has_embeddings": bool(sample.get("embeddings")),
                "metadata_fields": list(sample["metadatas"][0].keys()) if sample.get("metadatas") and sample["metadatas"] else []
            }
        except Exception as e:
            return {"error": str(e)}
    
    def delete_documents(self, ids: List[str]) -> bool:
        """Delete documents by IDs"""
        try:
            self.collection.delete(ids=ids)
            return True
        except Exception as e:
            print(f"Error deleting documents: {e}")
            return False
    
    def reset_collection(self) -> bool:
        """Reset the entire collection"""
        try:
            self.chroma_client.delete_collection(self.collection.name)
            self.collection = self.chroma_client.create_collection(
                name=self.collection.name,
                embedding_function=chromadb.utils.embedding_functions.SentenceTransformerEmbeddingFunction()
            )
            return True
        except Exception as e:
            print(f"Error resetting collection: {e}")
            return False

# Usage example with document processing
class DocumentProcessor:
    def __init__(self, chroma_integration: ChromaLLMIntegration):
        self.chroma = chroma_integration
    
    def process_text_file(self, file_path: str, chunk_size: int = 1000) -> List[str]:
        """Process a text file into chunks"""
        try:
            with open(file_path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            # Simple chunking by character count
            chunks = []
            for i in range(0, len(content), chunk_size):
                chunk = content[i:i + chunk_size]
                if chunk.strip():
                    chunks.append(chunk.strip())
            
            return chunks
            
        except Exception as e:
            print(f"Error processing file: {e}")
            return []
    
    def process_directory(self, directory_path: str, file_extensions: List[str] = [".txt", ".md"]) -> int:
        """Process all files in a directory"""
        directory = Path(directory_path)
        total_chunks = 0
        
        for ext in file_extensions:
            for file_path in directory.glob(f"**/*{ext}"):
                print(f"Processing: {file_path}")
                
                chunks = self.process_text_file(str(file_path))
                if chunks:
                    # Create metadata for chunks
                    metadatas = []
                    for i, chunk in enumerate(chunks):
                        metadatas.append({
                            "source_file": str(file_path),
                            "chunk_index": i,
                            "file_extension": ext,
                            "timestamp": str(asyncio.get_event_loop().time())
                        })
                    
                    # Add to ChromaDB
                    ids = self.chroma.add_documents(chunks, metadatas)
                    total_chunks += len(ids)
                    print(f"  Added {len(ids)} chunks")
        
        return total_chunks

# Complete usage example
async def demo_chroma_rag():
    # Initialize ChromaDB integration
    chroma_rag = ChromaLLMIntegration(
        persist_directory="./demo_chroma_db",
        collection_name="knowledge_base"
    )
    
    # Add some sample documents
    sample_docs = [
        "Python is a versatile programming language used for web development, data science, and automation.",
        "Machine learning algorithms can be supervised, unsupervised, or reinforcement learning based.",
        "Docker containers provide a lightweight way to package applications with their dependencies.",
        "REST APIs use HTTP methods like GET, POST, PUT, and DELETE to interact with resources.",
        "Database indexing improves query performance by creating efficient data access paths."
    ]
    
    sample_metadata = [
        {"topic": "programming", "language": "python"},
        {"topic": "ai", "subtopic": "machine-learning"},
        {"topic": "devops", "tool": "docker"},
        {"topic": "web-development", "type": "api"},
        {"topic": "database", "concept": "optimization"}
    ]
    
    # Add documents
    doc_ids = chroma_rag.add_documents(sample_docs, sample_metadata)
    print(f"Added {len(doc_ids)} documents")
    
    # Get collection stats
    stats = chroma_rag.get_collection_stats()
    print(f"Collection stats: {stats}")
    
    # Perform RAG queries
    queries = [
        "How is Python used in programming?",
        "What are the types of machine learning?",
        "How do REST APIs work?"
    ]
    
    for query in queries:
        print(f"\nQuery: {query}")
        response = await chroma_rag.rag_chat(query)
        print(f"Response: {response['response']}")
        print(f"Context sources: {len(response['context_used'])}")

if __name__ == "__main__":
    asyncio.run(demo_chroma_rag())
```

### Document Stores

Traditional document databases for storing conversation history, user preferences, and application data.

**MongoDB Integration:**

```python
# mongodb_llm_integration.py - MongoDB with local LLM
from motor.motor_asyncio import AsyncIOMotorClient
import openai
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
import asyncio
from bson import ObjectId
import json

class MongoLLMIntegration:
    def __init__(
        self,
        mongodb_uri: str = "mongodb://localhost:27017",
        database_name: str = "llm_app",
        llm_api_url: str = "http://localhost:8080"
    ):
        # Initialize MongoDB
        self.client = AsyncIOMotorClient(mongodb_uri)
        self.db = self.client[database_name]
        
        # Collections
        self.conversations = self.db.conversations
        self.users = self.db.users
        self.documents = self.db.documents
        self.chat_sessions = self.db.chat_sessions
        
        # Initialize LLM client
        self.llm_client = openai.OpenAI(
            api_key="not-needed",
            base_url=f"{llm_api_url}/v1"
        )
        
        # Initialize collections with indexes
        asyncio.create_task(self._setup_indexes())
    
    async def _setup_indexes(self):
        """Create database indexes for optimal performance"""
        try:
            # Conversations indexes
            await self.conversations.create_index("user_id")
            await self.conversations.create_index("session_id")
            await self.conversations.create_index("created_at")
            await self.conversations.create_index([("user_id", 1), ("created_at", -1)])
            
            # Users indexes
            await self.users.create_index("email", unique=True)
            await self.users.create_index("api_key", unique=True, sparse=True)
            
            # Documents indexes
            await self.documents.create_index("user_id")
            await self.documents.create_index("tags")
            await self.documents.create_index([("title", "text"), ("content", "text")])
            
            # Chat sessions indexes
            await self.chat_sessions.create_index("user_id")
            await self.chat_sessions.create_index("last_activity")
            await self.chat_sessions.create_index([("user_id", 1), ("last_activity", -1)])
            
        except Exception as e:
            print(f"Error setting up indexes: {e}")
    
    async def create_user(
        self, 
        email: str, 
        name: str, 
        preferences: Optional[Dict[str, Any]] = None
    ) -> Optional[str]:
        """Create a new user"""
        try:
            user_doc = {
                "email": email,
                "name": name,
                "preferences": preferences or {
                    "model": "llama-2-7b-chat",
                    "temperature": 0.7,
                    "max_tokens": 500,
                    "language": "en"
                },
                "created_at": datetime.utcnow(),
                "last_activity": datetime.utcnow(),
                "total_messages": 0,
                "total_sessions": 0
            }
            
            result = await self.users.insert_one(user_doc)
            return str(result.inserted_id)
            
        except Exception as e:
            print(f"Error creating user: {e}")
            return None
    
    async def get_user(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get user by ID"""
        try:
            user = await self.users.find_one({"_id": ObjectId(user_id)})
            if user:
                user["_id"] = str(user["_id"])
            return user
        except Exception as e:
            print(f"Error getting user: {e}")
            return None
    
    async def create_chat_session(self, user_id: str, title: str = "New Chat") -> Optional[str]:
        """Create a new chat session"""
        try:
            session_doc = {
                "user_id": user_id,
                "title": title,
                "created_at": datetime.utcnow(),
                "last_activity": datetime.utcnow(),
                "message_count": 0,
                "status": "active"
            }
            
            result = await self.chat_sessions.insert_one(session_doc)
            
            # Update user session count
            await self.users.update_one(
                {"_id": ObjectId(user_id)},
                {"$inc": {"total_sessions": 1}}
            )
            
            return str(result.inserted_id)
            
        except Exception as e:
            print(f"Error creating chat session: {e}")
            return None
    
    async def add_conversation_message(
        self,
        session_id: str,
        user_id: str,
        role: str,
        content: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> Optional[str]:
        """Add a message to a conversation"""
        try:
            message_doc = {
                "session_id": session_id,
                "user_id": user_id,
                "role": role,
                "content": content,
                "metadata": metadata or {},
                "created_at": datetime.utcnow(),
                "tokens_used": len(content.split()) * 1.3  # Rough estimate
            }
            
            result = await self.conversations.insert_one(message_doc)
            
            # Update session and user counters
            await asyncio.gather(
                self.chat_sessions.update_one(
                    {"_id": ObjectId(session_id)},
                    {
                        "$inc": {"message_count": 1},
                        "$set": {"last_activity": datetime.utcnow()}
                    }
                ),
                self.users.update_one(
                    {"_id": ObjectId(user_id)},
                    {
                        "$inc": {"total_messages": 1},
                        "$set": {"last_activity": datetime.utcnow()}
                    }
                )
            )
            
            return str(result.inserted_id)
            
        except Exception as e:
            print(f"Error adding message: {e}")
            return None
    
    async def get_conversation_history(
        self,
        session_id: str,
        limit: int = 50,
        skip: int = 0
    ) -> List[Dict[str, Any]]:
        """Get conversation history for a session"""
        try:
            cursor = self.conversations.find(
                {"session_id": session_id}
            ).sort("created_at", 1).skip(skip).limit(limit)
            
            messages = []
            async for message in cursor:
                message["_id"] = str(message["_id"])
                message["created_at"] = message["created_at"].isoformat()
                messages.append(message)
            
            return messages
            
        except Exception as e:
            print(f"Error getting conversation history: {e}")
            return []
    
    async def chat_with_context(
        self,
        session_id: str,
        user_id: str,
        message: str,
        model: Optional[str] = None,
        include_history: int = 10
    ) -> Dict[str, Any]:
        """Chat with conversation context from MongoDB"""
        try:
            # Get user preferences
            user = await self.get_user(user_id)
            if not user:
                return {"error": "User not found"}
            
            # Use user's preferred model if not specified
            model = model or user["preferences"].get("model", "llama-2-7b-chat")
            
            # Get recent conversation history
            history = await self.get_conversation_history(session_id, limit=include_history)
            
            # Build messages for LLM
            messages = []
            
            # Add system message based on user preferences
            system_prompt = user["preferences"].get("system_prompt", 
                "You are a helpful AI assistant. Provide accurate and helpful responses.")
            messages.append({"role": "system", "content": system_prompt})
            
            # Add conversation history
            for msg in history:
                if msg["role"] in ["user", "assistant"]:
                    messages.append({
                        "role": msg["role"],
                        "content": msg["content"]
                    })
            
            # Add current message
            messages.append({"role": "user", "content": message})
            
            # Store user message
            await self.add_conversation_message(session_id, user_id, "user", message)
            
            # Generate response
            response = self.llm_client.chat.completions.create(
                model=model,
                messages=messages,
                temperature=user["preferences"].get("temperature", 0.7),
                max_tokens=user["preferences"].get("max_tokens", 500)
            )
            
            assistant_response = response.choices[0].message.content
            
            # Store assistant response
            await self.add_conversation_message(
                session_id, 
                user_id, 
                "assistant", 
                assistant_response,
                {
                    "model": model,
                    "usage": dict(response.usage) if response.usage else {},
                    "total_tokens": response.usage.total_tokens if response.usage else 0
                }
            )
            
            return {
                "response": assistant_response,
                "session_id": session_id,
                "model": model,
                "usage": dict(response.usage) if response.usage else {}
            }
            
        except Exception as e:
            error_msg = f"Error in chat: {str(e)}"
            print(error_msg)
            return {"error": error_msg}
    
    async def get_user_sessions(
        self, 
        user_id: str, 
        limit: int = 20,
        skip: int = 0
    ) -> List[Dict[str, Any]]:
        """Get user's chat sessions"""
        try:
            cursor = self.chat_sessions.find(
                {"user_id": user_id}
            ).sort("last_activity", -1).skip(skip).limit(limit)
            
            sessions = []
            async for session in cursor:
                session["_id"] = str(session["_id"])
                session["created_at"] = session["created_at"].isoformat()
                session["last_activity"] = session["last_activity"].isoformat()
                sessions.append(session)
            
            return sessions
            
        except Exception as e:
            print(f"Error getting user sessions: {e}")
            return []
    
    async def search_conversations(
        self,
        user_id: str,
        query: str,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """Search user's conversations"""
        try:
            # Text search in conversation content
            cursor = self.conversations.find(
                {
                    "user_id": user_id,
                    "$text": {"$search": query}
                },
                {"score": {"$meta": "textScore"}}
            ).sort([("score", {"$meta": "textScore"})]).limit(limit)
            
            results = []
            async for message in cursor:
                message["_id"] = str(message["_id"])
                message["created_at"] = message["created_at"].isoformat()
                results.append(message)
            
            return results
            
        except Exception as e:
            print(f"Error searching conversations: {e}")
            return []
    
    async def get_analytics(self, user_id: str, days: int = 30) -> Dict[str, Any]:
        """Get user analytics"""
        try:
            start_date = datetime.utcnow() - timedelta(days=days)
            
            # Aggregate conversation stats
            pipeline = [
                {
                    "$match": {
                        "user_id": user_id,
                        "created_at": {"$gte": start_date}
                    }
                },
                {
                    "$group": {
                        "_id": {"$dateToString": {"format": "%Y-%m-%d", "date": "$created_at"}},
                        "message_count": {"$sum": 1},
                        "total_tokens": {"$sum": "$tokens_used"}
                    }
                },
                {"$sort": {"_id": 1}}
            ]
            
            daily_stats = []
            async for stat in self.conversations.aggregate(pipeline):
                daily_stats.append(stat)
            
            # Get total stats
            total_messages = await self.conversations.count_documents({
                "user_id": user_id,
                "created_at": {"$gte": start_date}
            })
            
            total_sessions = await self.chat_sessions.count_documents({
                "user_id": user_id,
                "created_at": {"$gte": start_date}
            })
            
            return {
                "daily_stats": daily_stats,
                "total_messages": total_messages,
                "total_sessions": total_sessions,
                "period_days": days
            }
            
        except Exception as e:
            print(f"Error getting analytics: {e}")
            return {}
    
    async def cleanup_old_data(self, retention_days: int = 90):
        """Clean up old conversation data"""
        try:
            cutoff_date = datetime.utcnow() - timedelta(days=retention_days)
            
            # Delete old conversations
            conv_result = await self.conversations.delete_many({
                "created_at": {"$lt": cutoff_date}
            })
            
            # Delete old inactive sessions
            session_result = await self.chat_sessions.delete_many({
                "last_activity": {"$lt": cutoff_date},
                "status": "inactive"
            })
            
            return {
                "conversations_deleted": conv_result.deleted_count,
                "sessions_deleted": session_result.deleted_count,
                "retention_days": retention_days
            }
            
        except Exception as e:
            print(f"Error cleaning up data: {e}")
            return {"error": str(e)}

# Usage example
async def demo_mongodb_integration():
    # Initialize MongoDB integration
    mongo_llm = MongoLLMIntegration()
    
    # Create a user
    user_id = await mongo_llm.create_user(
        email="test@example.com",
        name="Test User",
        preferences={
            "model": "llama-2-7b-chat",
            "temperature": 0.8,
            "system_prompt": "You are a knowledgeable programming assistant."
        }
    )
    print(f"Created user: {user_id}")
    
    # Create a chat session
    session_id = await mongo_llm.create_chat_session(user_id, "Python Help")
    print(f"Created session: {session_id}")
    
    # Have a conversation
    queries = [
        "What is Python?",
        "How do I create a list in Python?",
        "Can you show me a for loop example?"
    ]
    
    for query in queries:
        response = await mongo_llm.chat_with_context(session_id, user_id, query)
        print(f"\nUser: {query}")
        print(f"Assistant: {response.get('response', 'Error')}")
    
    # Get conversation history
    history = await mongo_llm.get_conversation_history(session_id)
    print(f"\nTotal messages in conversation: {len(history)}")
    
    # Get user analytics
    analytics = await mongo_llm.get_analytics(user_id, days=7)
    print(f"Analytics: {analytics}")

if __name__ == "__main__":
    asyncio.run(demo_mongodb_integration())
```

### Session Management

Maintain conversation state and user sessions across interactions.

**Redis Session Management:**

```python
# redis_session_manager.py - Session management with Redis
import redis.asyncio as redis
import json
import uuid
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
import hashlib
import asyncio
from dataclasses import dataclass, asdict

@dataclass
class SessionConfig:
    max_messages: int = 50
    ttl_seconds: int = 3600  # 1 hour
    cleanup_interval: int = 300  # 5 minutes
    max_memory_mb: int = 10

@dataclass
class ConversationMessage:
    role: str
    content: str
    timestamp: str
    metadata: Optional[Dict[str, Any]] = None

class RedisSessionManager:
    def __init__(
        self,
        redis_url: str = "redis://localhost:6379",
        key_prefix: str = "llm_session:",
        config: Optional[SessionConfig] = None
    ):
        self.redis = redis.from_url(redis_url)
        self.key_prefix = key_prefix
        self.config = config or SessionConfig()
        
        # Start cleanup task
        asyncio.create_task(self._periodic_cleanup())
    
    def _make_session_key(self, session_id: str) -> str:
        return f"{self.key_prefix}{session_id}"
    
    def _make_user_sessions_key(self, user_id: str) -> str:
        return f"{self.key_prefix}user:{user_id}:sessions"
    
    async def create_session(
        self, 
        user_id: str,
        initial_context: Optional[Dict[str, Any]] = None
    ) -> str:
        """Create a new session"""
        session_id = str(uuid.uuid4())
        session_key = self._make_session_key(session_id)
        
        session_data = {
            "session_id": session_id,
            "user_id": user_id,
            "created_at": datetime.utcnow().isoformat(),
            "last_activity": datetime.utcnow().isoformat(),
            "message_count": 0,
            "messages": [],
            "context": initial_context or {},
            "metadata": {
                "user_agent": "",
                "ip_address": "",
                "client_version": ""
            }
        }
        
        try:
            # Store session data
            await self.redis.set(
                session_key,
                json.dumps(session_data),
                ex=self.config.ttl_seconds
            )
            
            # Add session to user's session list
            user_sessions_key = self._make_user_sessions_key(user_id)
            await self.redis.sadd(user_sessions_key, session_id)
            await self.redis.expire(user_sessions_key, self.config.ttl_seconds)
            
            return session_id
            
        except Exception as e:
            print(f"Error creating session: {e}")
            raise
    
    async def get_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Get session data"""
        try:
            session_key = self._make_session_key(session_id)
            session_data = await self.redis.get(session_key)
            
            if session_data:
                data = json.loads(session_data)
                # Update last activity
                data["last_activity"] = datetime.utcnow().isoformat()
                await self.redis.set(
                    session_key,
                    json.dumps(data),
                    ex=self.config.ttl_seconds
                )
                return data
            
            return None
            
        except Exception as e:
            print(f"Error getting session: {e}")
            return None
    
    async def add_message(
        self,
        session_id: str,
        role: str,
        content: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> bool:
        """Add a message to the session"""
        try:
            session = await self.get_session(session_id)
            if not session:
                return False
            
            # Create message
            message = ConversationMessage(
                role=role,
                content=content,
                timestamp=datetime.utcnow().isoformat(),
                metadata=metadata
            )
            
            # Add to messages
            session["messages"].append(asdict(message))
            session["message_count"] = len(session["messages"])
            session["last_activity"] = datetime.utcnow().isoformat()
            
            # Implement sliding window to limit memory usage
            if len(session["messages"]) > self.config.max_messages:
                session["messages"] = session["messages"][-self.config.max_messages:]
                session["message_count"] = len(session["messages"])
            
            # Store updated session
            session_key = self._make_session_key(session_id)
            await self.redis.set(
                session_key,
                json.dumps(session),
                ex=self.config.ttl_seconds
            )
            
            return True
            
        except Exception as e:
            print(f"Error adding message: {e}")
            return False
    
    async def get_conversation_context(
        self,
        session_id: str,
        max_messages: Optional[int] = None,
        include_system: bool = True
    ) -> List[Dict[str, str]]:
        """Get conversation context for LLM"""
        try:
            session = await self.get_session(session_id)
            if not session:
                return []
            
            messages = session.get("messages", [])
            
            # Apply message limit
            if max_messages:
                messages = messages[-max_messages:]
            
            # Format for LLM
            llm_messages = []
            
            # Add system context if available and requested
            if include_system and session.get("context", {}).get("system_prompt"):
                llm_messages.append({
                    "role": "system",
                    "content": session["context"]["system_prompt"]
                })
            
            # Add conversation messages
            for msg in messages:
                if msg["role"] in ["user", "assistant"]:
                    llm_messages.append({
                        "role": msg["role"],
                        "content": msg["content"]
                    })
            
            return llm_messages
            
        except Exception as e:
            print(f"Error getting conversation context: {e}")
            return []
    
    async def update_session_context(
        self,
        session_id: str,
        context_updates: Dict[str, Any]
    ) -> bool:
        """Update session context"""
        try:
            session = await self.get_session(session_id)
            if not session:
                return False
            
            # Update context
            session["context"].update(context_updates)
            session["last_activity"] = datetime.utcnow().isoformat()
            
            # Store updated session
            session_key = self._make_session_key(session_id)
            await self.redis.set(
                session_key,
                json.dumps(session),
                ex=self.config.ttl_seconds
            )
            
            return True
            
        except Exception as e:
            print(f"Error updating session context: {e}")
            return False
    
    async def get_user_sessions(self, user_id: str) -> List[str]:
        """Get all session IDs for a user"""
        try:
            user_sessions_key = self._make_user_sessions_key(user_id)
            session_ids = await self.redis.smembers(user_sessions_key)
            return [sid.decode() if isinstance(sid, bytes) else sid for sid in session_ids]
            
        except Exception as e:
            print(f"Error getting user sessions: {e}")
            return []
    
    async def delete_session(self, session_id: str) -> bool:
        """Delete a session"""
        try:
            session = await self.get_session(session_id)
            if not session:
                return False
            
            user_id = session["user_id"]
            
            # Delete session data
            session_key = self._make_session_key(session_id)
            await self.redis.delete(session_key)
            
            # Remove from user's session list
            user_sessions_key = self._make_user_sessions_key(user_id)
            await self.redis.srem(user_sessions_key, session_id)
            
            return True
            
        except Exception as e:
            print(f"Error deleting session: {e}")
            return False
    
    async def extend_session(self, session_id: str, additional_seconds: int = None) -> bool:
        """Extend session TTL"""
        try:
            additional_ttl = additional_seconds or self.config.ttl_seconds
            session_key = self._make_session_key(session_id)
            
            result = await self.redis.expire(session_key, additional_ttl)
            return bool(result)
            
        except Exception as e:
            print(f"Error extending session: {e}")
            return False
    
    async def get_session_stats(self) -> Dict[str, Any]:
        """Get overall session statistics"""
        try:
            # Get all session keys
            session_keys = []
            async for key in self.redis.scan_iter(match=f"{self.key_prefix}*"):
                if not key.decode().endswith(":sessions"):
                    session_keys.append(key.decode())
            
            active_sessions = len(session_keys)
            
            # Sample a few sessions for detailed stats
            sample_size = min(10, active_sessions)
            total_messages = 0
            
            if session_keys:
                sample_keys = session_keys[:sample_size]
                for key in sample_keys:
                    try:
                        data = await self.redis.get(key)
                        if data:
                            session = json.loads(data)
                            total_messages += session.get("message_count", 0)
                    except Exception:
                        continue
            
            return {
                "active_sessions": active_sessions,
                "avg_messages_per_session": total_messages / sample_size if sample_size > 0 else 0,
                "sample_size": sample_size,
                "redis_memory": await self._get_redis_memory_usage()
            }
            
        except Exception as e:
            print(f"Error getting session stats: {e}")
            return {}
    
    async def _get_redis_memory_usage(self) -> Dict[str, Any]:
        """Get Redis memory usage information"""
        try:
            info = await self.redis.info("memory")
            return {
                "used_memory": info.get("used_memory", 0),
                "used_memory_human": info.get("used_memory_human", "0B"),
                "used_memory_peak": info.get("used_memory_peak", 0)
            }
        except Exception:
            return {}
    
    async def _periodic_cleanup(self):
        """Periodic cleanup of expired sessions"""
        while True:
            try:
                await asyncio.sleep(self.config.cleanup_interval)
                
                # Cleanup orphaned user session references
                user_session_keys = []
                async for key in self.redis.scan_iter(match=f"{self.key_prefix}user:*:sessions"):
                    user_session_keys.append(key.decode())
                
                for key in user_session_keys:
                    try:
                        session_ids = await self.redis.smembers(key)
                        valid_session_ids = []
                        
                        for session_id in session_ids:
                            session_key = self._make_session_key(session_id.decode() if isinstance(session_id, bytes) else session_id)
                            if await self.redis.exists(session_key):
                                valid_session_ids.append(session_id)
                        
                        # Update the set with only valid session IDs
                        if len(valid_session_ids) != len(session_ids):
                            await self.redis.delete(key)
                            if valid_session_ids:
                                await self.redis.sadd(key, *valid_session_ids)
                                await self.redis.expire(key, self.config.ttl_seconds)
                        
                    except Exception as e:
                        print(f"Error cleaning up user sessions {key}: {e}")
                
            except Exception as e:
                print(f"Error in periodic cleanup: {e}")

# Integration with LLM chat
class SessionAwareLLMChat:
    def __init__(
        self,
        session_manager: RedisSessionManager,
        llm_client,
        default_model: str = "llama-2-7b-chat"
    ):
        self.session_manager = session_manager
        self.llm_client = llm_client
        self.default_model = default_model
    
    async def chat(
        self,
        session_id: str,
        message: str,
        model: Optional[str] = None,
        max_context_messages: int = 20
    ) -> Dict[str, Any]:
        """Chat with session context"""
        try:
            # Add user message to session
            await self.session_manager.add_message(session_id, "user", message)
            
            # Get conversation context
            context_messages = await self.session_manager.get_conversation_context(
                session_id, max_context_messages
            )
            
            if not context_messages:
                return {"error": "Session not found"}
            
            # Generate response
            response = self.llm_client.chat.completions.create(
                model=model or self.default_model,
                messages=context_messages,
                temperature=0.7,
                max_tokens=500
            )
            
            assistant_response = response.choices[0].message.content
            
            # Add assistant response to session
            await self.session_manager.add_message(
                session_id, 
                "assistant", 
                assistant_response,
                {
                    "model": model or self.default_model,
                    "usage": dict(response.usage) if response.usage else {}
                }
            )
            
            return {
                "response": assistant_response,
                "session_id": session_id,
                "message_count": len(context_messages) + 1
            }
            
        except Exception as e:
            return {"error": str(e)}

# Usage example
async def demo_session_management():
    # Initialize session manager
    session_config = SessionConfig(
        max_messages=30,
        ttl_seconds=1800,  # 30 minutes
        cleanup_interval=300
    )
    
    session_manager = RedisSessionManager(config=session_config)
    
    # Create a session
    user_id = "user_123"
    session_id = await session_manager.create_session(
        user_id,
        initial_context={
            "system_prompt": "You are a helpful coding assistant.",
            "user_preferences": {"language": "python"}
        }
    )
    
    print(f"Created session: {session_id}")
    
    # Simulate conversation
    messages = [
        "Hello, I need help with Python",
        "Can you show me how to create a class?",
        "What about inheritance?"
    ]
    
    for msg in messages:
        await session_manager.add_message(session_id, "user", msg)
        await session_manager.add_message(session_id, "assistant", f"Response to: {msg}")
    
    # Get conversation context
    context = await session_manager.get_conversation_context(session_id)
    print(f"Context messages: {len(context)}")
    
    # Get session stats
    stats = await session_manager.get_session_stats()
    print(f"Session stats: {stats}")
    
    # Cleanup
    await session_manager.delete_session(session_id)
    print("Session deleted")

if __name__ == "__main__":
    asyncio.run(demo_session_management())
```

This comprehensive Database Integration section covers vector databases (Pinecone, ChromaDB), document stores (MongoDB), and session management (Redis). Each component includes production-ready code with proper error handling, performance optimizations, and real-world usage patterns.

## Message Queue Integration

Asynchronous processing and communication between LLM services using message queues for scalable, reliable architectures.

### RabbitMQ Integration

RabbitMQ provides reliable message queuing for distributed LLM applications with guaranteed delivery and routing.

**RabbitMQ LLM Worker:**

```python
# rabbitmq_llm_worker.py - RabbitMQ integration for LLM processing
import pika
import json
import asyncio
import openai
from typing import Dict, Any, Optional, Callable
import logging
import traceback
from datetime import datetime
import uuid
from dataclasses import dataclass, asdict
from concurrent.futures import ThreadPoolExecutor
import signal
import sys

@dataclass
class LLMRequest:
    request_id: str
    model: str
    messages: list
    temperature: float = 0.7
    max_tokens: int = 500
    stream: bool = False
    callback_queue: Optional[str] = None
    priority: int = 5
    created_at: str = ""

@dataclass
class LLMResponse:
    request_id: str
    success: bool
    response: Optional[str] = None
    error: Optional[str] = None
    usage: Optional[Dict[str, Any]] = None
    processing_time: float = 0.0
    worker_id: str = ""
    completed_at: str = ""

class RabbitMQLLMWorker:
    def __init__(
        self,
        rabbitmq_url: str = "amqp://localhost:5672",
        llm_api_url: str = "http://localhost:8080",
        worker_id: Optional[str] = None,
        max_workers: int = 4
    ):
        self.rabbitmq_url = rabbitmq_url
        self.worker_id = worker_id or f"worker_{uuid.uuid4().hex[:8]}"
        self.max_workers = max_workers
        
        # Initialize LLM client
        self.llm_client = openai.OpenAI(
            api_key="not-needed",
            base_url=f"{llm_api_url}/v1"
        )
        
        # Setup logging
        self.logger = logging.getLogger(__name__)
        self.logger.setLevel(logging.INFO)
        
        # Connection and channels
        self.connection = None
        self.channel = None
        self.executor = ThreadPoolExecutor(max_workers=max_workers)
        
        # Queues
        self.request_queue = "llm_requests"
        self.response_queue = "llm_responses"
        self.priority_queue = "llm_priority_requests"
        self.dlq = "llm_requests_dlq"  # Dead letter queue
        
        # Graceful shutdown
        self.should_stop = False
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
    
    def _signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        self.logger.info(f"Received signal {signum}, shutting down gracefully...")
        self.should_stop = True
    
    def connect(self):
        """Establish RabbitMQ connection"""
        try:
            self.connection = pika.BlockingConnection(
                pika.URLParameters(self.rabbitmq_url)
            )
            self.channel = self.connection.channel()
            
            # Declare queues with appropriate settings
            self._declare_queues()
            
            self.logger.info(f"Worker {self.worker_id} connected to RabbitMQ")
            
        except Exception as e:
            self.logger.error(f"Failed to connect to RabbitMQ: {e}")
            raise
    
    def _declare_queues(self):
        """Declare all necessary queues"""
        # Main request queue with DLX
        self.channel.queue_declare(
            queue=self.request_queue,
            durable=True,
            arguments={
                "x-dead-letter-exchange": "",
                "x-dead-letter-routing-key": self.dlq,
                "x-message-ttl": 300000  # 5 minutes
            }
        )
        
        # Priority queue
        self.channel.queue_declare(
            queue=self.priority_queue,
            durable=True,
            arguments={
                "x-max-priority": 10,
                "x-dead-letter-exchange": "",
                "x-dead-letter-routing-key": self.dlq
            }
        )
        
        # Response queue
        self.channel.queue_declare(queue=self.response_queue, durable=True)
        
        # Dead letter queue
        self.channel.queue_declare(queue=self.dlq, durable=True)
        
        # Set QoS to process one message at a time per worker
        self.channel.basic_qos(prefetch_count=1)
    
    async def process_llm_request(self, request: LLMRequest) -> LLMResponse:
        """Process LLM request"""
        start_time = datetime.utcnow()
        
        try:
            self.logger.info(f"Processing request {request.request_id} with model {request.model}")
            
            # Create LLM request
            response = self.llm_client.chat.completions.create(
                model=request.model,
                messages=request.messages,
                temperature=request.temperature,
                max_tokens=request.max_tokens,
                stream=request.stream
            )
            
            # Handle streaming vs non-streaming
            if request.stream:
                # For streaming, collect chunks
                content_chunks = []
                for chunk in response:
                    if chunk.choices[0].delta.content:
                        content_chunks.append(chunk.choices[0].delta.content)
                
                final_content = "".join(content_chunks)
                usage_info = None  # Streaming doesn't return usage
            else:
                final_content = response.choices[0].message.content
                usage_info = dict(response.usage) if response.usage else None
            
            processing_time = (datetime.utcnow() - start_time).total_seconds()
            
            return LLMResponse(
                request_id=request.request_id,
                success=True,
                response=final_content,
                usage=usage_info,
                processing_time=processing_time,
                worker_id=self.worker_id,
                completed_at=datetime.utcnow().isoformat()
            )
            
        except Exception as e:
            processing_time = (datetime.utcnow() - start_time).total_seconds()
            error_msg = f"Error processing LLM request: {str(e)}"
            self.logger.error(f"{error_msg}\n{traceback.format_exc()}")
            
            return LLMResponse(
                request_id=request.request_id,
                success=False,
                error=error_msg,
                processing_time=processing_time,
                worker_id=self.worker_id,
                completed_at=datetime.utcnow().isoformat()
            )
    
    def _callback_wrapper(self, channel, method, properties, body):
        """Wrapper for async callback"""
        try:
            # Parse request
            request_data = json.loads(body.decode())
            request = LLMRequest(**request_data)
            
            # Process in thread pool to avoid blocking
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            
            try:
                response = loop.run_until_complete(
                    self.process_llm_request(request)
                )
                
                # Send response
                self._send_response(response, properties.reply_to)
                
                # Acknowledge message
                channel.basic_ack(delivery_tag=method.delivery_tag)
                
                self.logger.info(f"Completed request {request.request_id}")
                
            finally:
                loop.close()
            
        except Exception as e:
            self.logger.error(f"Error in callback: {e}")
            # Reject and don't requeue to avoid infinite loops
            channel.basic_nack(
                delivery_tag=method.delivery_tag,
                requeue=False
            )
    
    def _send_response(self, response: LLMResponse, reply_to: Optional[str]):
        """Send response back to client"""
        try:
            response_data = json.dumps(asdict(response))
            
            if reply_to:
                # Send to specific callback queue
                self.channel.basic_publish(
                    exchange="",
                    routing_key=reply_to,
                    body=response_data,
                    properties=pika.BasicProperties(
                        delivery_mode=2  # Make message persistent
                    )
                )
            else:
                # Send to default response queue
                self.channel.basic_publish(
                    exchange="",
                    routing_key=self.response_queue,
                    body=response_data,
                    properties=pika.BasicProperties(
                        delivery_mode=2
                    )
                )
                
        except Exception as e:
            self.logger.error(f"Error sending response: {e}")
    
    def start_consuming(self):
        """Start consuming messages"""
        try:
            self.connect()
            
            # Setup consumers for both regular and priority queues
            self.channel.basic_consume(
                queue=self.priority_queue,
                on_message_callback=self._callback_wrapper
            )
            
            self.channel.basic_consume(
                queue=self.request_queue,
                on_message_callback=self._callback_wrapper
            )
            
            self.logger.info(f"Worker {self.worker_id} started consuming...")
            
            # Start consuming with graceful shutdown
            while not self.should_stop:
                try:
                    self.connection.process_data_events(time_limit=1)
                except KeyboardInterrupt:
                    break
            
            self.logger.info("Stopping consumer...")
            self.channel.stop_consuming()
            
        except Exception as e:
            self.logger.error(f"Error in consumer: {e}")
        finally:
            self._cleanup()
    
    def _cleanup(self):
        """Clean up resources"""
        try:
            if self.executor:
                self.executor.shutdown(wait=True)
            
            if self.connection and not self.connection.is_closed:
                self.connection.close()
                
            self.logger.info(f"Worker {self.worker_id} shut down cleanly")
            
        except Exception as e:
            self.logger.error(f"Error during cleanup: {e}")

class RabbitMQLLMClient:
    """Client for sending requests to RabbitMQ LLM workers"""
    
    def __init__(self, rabbitmq_url: str = "amqp://localhost:5672"):
        self.rabbitmq_url = rabbitmq_url
        self.connection = None
        self.channel = None
        self.callback_queue = None
        self.response_futures = {}
        self.logger = logging.getLogger(__name__)
        
        self.connect()
    
    def connect(self):
        """Establish connection"""
        try:
            self.connection = pika.BlockingConnection(
                pika.URLParameters(self.rabbitmq_url)
            )
            self.channel = self.connection.channel()
            
            # Create exclusive callback queue
            result = self.channel.queue_declare(queue="", exclusive=True)
            self.callback_queue = result.method.queue
            
            # Setup response consumer
            self.channel.basic_consume(
                queue=self.callback_queue,
                on_message_callback=self._on_response,
                auto_ack=True
            )
            
        except Exception as e:
            self.logger.error(f"Failed to connect: {e}")
            raise
    
    def _on_response(self, channel, method, props, body):
        """Handle response from worker"""
        try:
            response = json.loads(body.decode())
            request_id = response.get("request_id")
            
            if request_id in self.response_futures:
                self.response_futures[request_id] = response
                
        except Exception as e:
            self.logger.error(f"Error handling response: {e}")
    
    async def send_request(
        self,
        messages: list,
        model: str = "llama-2-7b-chat",
        temperature: float = 0.7,
        max_tokens: int = 500,
        priority: int = 5,
        timeout: int = 60
    ) -> Dict[str, Any]:
        """Send LLM request and wait for response"""
        
        request_id = str(uuid.uuid4())
        
        request = LLMRequest(
            request_id=request_id,
            model=model,
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens,
            callback_queue=self.callback_queue,
            priority=priority,
            created_at=datetime.utcnow().isoformat()
        )
        
        try:
            # Choose queue based on priority
            queue = "llm_priority_requests" if priority > 5 else "llm_requests"
            
            # Send request
            self.channel.basic_publish(
                exchange="",
                routing_key=queue,
                body=json.dumps(asdict(request)),
                properties=pika.BasicProperties(
                    reply_to=self.callback_queue,
                    correlation_id=request_id,
                    delivery_mode=2,
                    priority=priority
                )
            )
            
            # Wait for response
            self.response_futures[request_id] = None
            
            # Poll for response with timeout
            start_time = datetime.utcnow()
            while (datetime.utcnow() - start_time).seconds < timeout:
                self.connection.process_data_events(time_limit=0.1)
                
                if self.response_futures.get(request_id):
                    response = self.response_futures.pop(request_id)
                    return response
            
            # Timeout
            self.response_futures.pop(request_id, None)
            return {
                "request_id": request_id,
                "success": False,
                "error": "Request timeout"
            }
            
        except Exception as e:
            return {
                "request_id": request_id,
                "success": False,
                "error": str(e)
            }
    
    def close(self):
        """Close connection"""
        try:
            if self.connection and not self.connection.is_closed:
                self.connection.close()
        except Exception as e:
            self.logger.error(f"Error closing connection: {e}")

# Usage examples
async def demo_rabbitmq_llm():
    # Start worker (in separate process/container)
    # worker = RabbitMQLLMWorker()
    # worker.start_consuming()
    
    # Client usage
    client = RabbitMQLLMClient()
    
    try:
        # Send high priority request
        response = await client.send_request(
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": "What is Python?"}
            ],
            model="llama-2-7b-chat",
            priority=8,
            timeout=30
        )
        
        print(f"Response: {response}")
        
    finally:
        client.close()

if __name__ == "__main__":
    # Run worker
    worker = RabbitMQLLMWorker()
    worker.start_consuming()
```

### Redis Pub/Sub Integration

Redis provides fast pub/sub messaging and queuing capabilities for real-time LLM applications.

```python
# redis_llm_pubsub.py - Redis pub/sub for LLM integration
import redis.asyncio as redis
import json
import asyncio
import openai
from typing import Dict, Any, Optional, Callable, List
import logging
import uuid
from datetime import datetime
from dataclasses import dataclass, asdict
import signal

@dataclass
class StreamingLLMRequest:
    request_id: str
    channel: str
    messages: list
    model: str = "llama-2-7b-chat"
    temperature: float = 0.7
    max_tokens: int = 500
    user_id: Optional[str] = None

class RedisLLMPubSub:
    def __init__(
        self,
        redis_url: str = "redis://localhost:6379",
        llm_api_url: str = "http://localhost:8080",
        worker_id: Optional[str] = None
    ):
        self.redis_url = redis_url
        self.worker_id = worker_id or f"llm_worker_{uuid.uuid4().hex[:8]}"
        
        # Initialize Redis clients
        self.redis_client = redis.from_url(redis_url)
        self.pubsub = self.redis_client.pubsub()
        
        # Initialize LLM client
        self.llm_client = openai.OpenAI(
            api_key="not-needed",
            base_url=f"{llm_api_url}/v1"
        )
        
        # Channels
        self.request_channel = "llm:requests"
        self.response_channel_prefix = "llm:responses:"
        self.status_channel = "llm:status"
        self.streaming_channel_prefix = "llm:stream:"
        
        # State
        self.is_running = False
        self.active_streams = {}
        
        self.logger = logging.getLogger(__name__)
        
        # Setup graceful shutdown
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
    
    def _signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        self.logger.info(f"Received signal {signum}, shutting down...")
        self.is_running = False
    
    async def start_worker(self):
        """Start the worker to process LLM requests"""
        try:
            self.is_running = True
            
            # Subscribe to request channel
            await self.pubsub.subscribe(self.request_channel)
            
            # Announce worker availability
            await self.redis_client.publish(
                self.status_channel,
                json.dumps({
                    "worker_id": self.worker_id,
                    "status": "online",
                    "timestamp": datetime.utcnow().isoformat()
                })
            )
            
            self.logger.info(f"Worker {self.worker_id} started listening on {self.request_channel}")
            
            # Process messages
            async for message in self.pubsub.listen():
                if not self.is_running:
                    break
                
                if message["type"] == "message":
                    await self._process_message(message)
            
        except Exception as e:
            self.logger.error(f"Error in worker: {e}")
        finally:
            await self._cleanup()
    
    async def _process_message(self, message):
        """Process incoming LLM request"""
        try:
            data = json.loads(message["data"].decode())
            request = StreamingLLMRequest(**data)
            
            self.logger.info(f"Processing request {request.request_id}")
            
            # Send processing status
            await self.redis_client.publish(
                f"{self.response_channel_prefix}{request.request_id}",
                json.dumps({
                    "status": "processing",
                    "worker_id": self.worker_id,
                    "timestamp": datetime.utcnow().isoformat()
                })
            )
            
            # Process with streaming
            if request.channel.startswith("stream:"):
                await self._process_streaming_request(request)
            else:
                await self._process_regular_request(request)
                
        except Exception as e:
            self.logger.error(f"Error processing message: {e}")
            
            # Send error response if possible
            try:
                error_data = {
                    "status": "error",
                    "error": str(e),
                    "worker_id": self.worker_id,
                    "timestamp": datetime.utcnow().isoformat()
                }
                await self.redis_client.publish(
                    f"{self.response_channel_prefix}{data.get('request_id', 'unknown')}",
                    json.dumps(error_data)
                )
            except Exception:
                pass
    
    async def _process_streaming_request(self, request: StreamingLLMRequest):
        """Process streaming LLM request"""
        try:
            stream_channel = f"{self.streaming_channel_prefix}{request.request_id}"
            
            # Generate streaming response
            response = self.llm_client.chat.completions.create(
                model=request.model,
                messages=request.messages,
                temperature=request.temperature,
                max_tokens=request.max_tokens,
                stream=True
            )
            
            # Stream chunks to Redis
            full_response = []
            
            async for chunk in response:
                if chunk.choices[0].delta.content:
                    content = chunk.choices[0].delta.content
                    full_response.append(content)
                    
                    # Publish chunk
                    chunk_data = {
                        "request_id": request.request_id,
                        "chunk": content,
                        "is_final": False,
                        "timestamp": datetime.utcnow().isoformat()
                    }
                    
                    await self.redis_client.publish(stream_channel, json.dumps(chunk_data))
            
            # Send final message
            final_data = {
                "request_id": request.request_id,
                "chunk": "",
                "is_final": True,
                "full_response": "".join(full_response),
                "timestamp": datetime.utcnow().isoformat()
            }
            
            await self.redis_client.publish(stream_channel, json.dumps(final_data))
            
            # Send completion notification
            await self.redis_client.publish(
                f"{self.response_channel_prefix}{request.request_id}",
                json.dumps({
                    "status": "completed",
                    "response": "".join(full_response),
                    "worker_id": self.worker_id,
                    "timestamp": datetime.utcnow().isoformat()
                })
            )
            
        except Exception as e:
            self.logger.error(f"Error in streaming request: {e}")
            raise
    
    async def _process_regular_request(self, request: StreamingLLMRequest):
        """Process regular (non-streaming) LLM request"""
        try:
            # Generate response
            response = self.llm_client.chat.completions.create(
                model=request.model,
                messages=request.messages,
                temperature=request.temperature,
                max_tokens=request.max_tokens
            )
            
            # Send response
            response_data = {
                "status": "completed",
                "response": response.choices[0].message.content,
                "usage": dict(response.usage) if response.usage else {},
                "worker_id": self.worker_id,
                "timestamp": datetime.utcnow().isoformat()
            }
            
            await self.redis_client.publish(
                f"{self.response_channel_prefix}{request.request_id}",
                json.dumps(response_data)
            )
            
        except Exception as e:
            self.logger.error(f"Error in regular request: {e}")
            raise
    
    async def _cleanup(self):
        """Clean up resources"""
        try:
            # Announce worker offline
            await self.redis_client.publish(
                self.status_channel,
                json.dumps({
                    "worker_id": self.worker_id,
                    "status": "offline",
                    "timestamp": datetime.utcnow().isoformat()
                })
            )
            
            # Close connections
            await self.pubsub.close()
            await self.redis_client.close()
            
            self.logger.info(f"Worker {self.worker_id} shut down cleanly")
            
        except Exception as e:
            self.logger.error(f"Error during cleanup: {e}")

class RedisLLMClient:
    """Client for sending requests via Redis pub/sub"""
    
    def __init__(self, redis_url: str = "redis://localhost:6379"):
        self.redis_client = redis.from_url(redis_url)
        self.pubsub = self.redis_client.pubsub()
        self.logger = logging.getLogger(__name__)
    
    async def send_request(
        self,
        messages: list,
        model: str = "llama-2-7b-chat",
        temperature: float = 0.7,
        max_tokens: int = 500,
        timeout: int = 60,
        user_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """Send LLM request and wait for response"""
        
        request_id = str(uuid.uuid4())
        response_channel = f"llm:responses:{request_id}"
        
        # Subscribe to response channel
        await self.pubsub.subscribe(response_channel)
        
        try:
            # Send request
            request = StreamingLLMRequest(
                request_id=request_id,
                channel="regular",
                messages=messages,
                model=model,
                temperature=temperature,
                max_tokens=max_tokens,
                user_id=user_id
            )
            
            await self.redis_client.publish(
                "llm:requests",
                json.dumps(asdict(request))
            )
            
            # Wait for response
            start_time = datetime.utcnow()
            
            async for message in self.pubsub.listen():
                if message["type"] == "message":
                    response = json.loads(message["data"].decode())
                    
                    if response.get("status") == "completed":
                        return {
                            "success": True,
                            "response": response.get("response"),
                            "usage": response.get("usage", {}),
                            "worker_id": response.get("worker_id")
                        }
                    elif response.get("status") == "error":
                        return {
                            "success": False,
                            "error": response.get("error")
                        }
                
                # Check timeout
                if (datetime.utcnow() - start_time).seconds > timeout:
                    return {
                        "success": False,
                        "error": "Request timeout"
                    }
                    
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
        finally:
            await self.pubsub.unsubscribe(response_channel)
    
    async def stream_request(
        self,
        messages: list,
        callback: Callable[[str], None],
        model: str = "llama-2-7b-chat",
        temperature: float = 0.7,
        max_tokens: int = 500,
        user_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """Send streaming LLM request"""
        
        request_id = str(uuid.uuid4())
        stream_channel = f"llm:stream:{request_id}"
        response_channel = f"llm:responses:{request_id}"
        
        # Subscribe to channels
        await self.pubsub.subscribe(stream_channel, response_channel)
        
        try:
            # Send request
            request = StreamingLLMRequest(
                request_id=request_id,
                channel="stream:",
                messages=messages,
                model=model,
                temperature=temperature,
                max_tokens=max_tokens,
                user_id=user_id
            )
            
            await self.redis_client.publish(
                "llm:requests",
                json.dumps(asdict(request))
            )
            
            full_response = []
            
            # Listen for streaming chunks
            async for message in self.pubsub.listen():
                if message["type"] == "message":
                    
                    if message["channel"].decode().startswith("llm:stream:"):
                        # Streaming chunk
                        data = json.loads(message["data"].decode())
                        
                        if not data["is_final"]:
                            chunk = data["chunk"]
                            full_response.append(chunk)
                            callback(chunk)
                        else:
                            # Final chunk
                            return {
                                "success": True,
                                "response": "".join(full_response),
                                "request_id": request_id
                            }
                    
                    elif message["channel"].decode().startswith("llm:responses:"):
                        # Status update
                        response = json.loads(message["data"].decode())
                        
                        if response.get("status") == "error":
                            return {
                                "success": False,
                                "error": response.get("error")
                            }
                            
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
        finally:
            await self.pubsub.unsubscribe(stream_channel, response_channel)
    
    async def close(self):
        """Close connections"""
        try:
            await self.pubsub.close()
            await self.redis_client.close()
        except Exception as e:
            self.logger.error(f"Error closing client: {e}")

# Usage examples
async def demo_redis_pubsub():
    # Start worker (in separate process)
    # worker = RedisLLMPubSub()
    # await worker.start_worker()
    
    # Client usage
    client = RedisLLMClient()
    
    try:
        # Regular request
        response = await client.send_request(
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": "Explain machine learning briefly."}
            ]
        )
        
        print(f"Response: {response}")
        
        # Streaming request
        def print_chunk(chunk):
            print(chunk, end="", flush=True)
        
        stream_response = await client.stream_request(
            messages=[
                {"role": "user", "content": "Tell me a short story."}
            ],
            callback=print_chunk
        )
        
        print(f"\nStream completed: {stream_response['success']}")
        
    finally:
        await client.close()

if __name__ == "__main__":
    # Run worker
    worker = RedisLLMPubSub()
    asyncio.run(worker.start_worker())
```

### Apache Kafka Integration

Kafka provides robust stream processing capabilities for high-throughput LLM applications.

```python
# kafka_llm_integration.py - Kafka integration for LLM stream processing
from kafka import KafkaProducer, KafkaConsumer
from kafka.errors import KafkaError
import json
import asyncio
import openai
from typing import Dict, Any, Optional, List, Callable
import logging
import uuid
from datetime import datetime
from dataclasses import dataclass, asdict
import threading
from concurrent.futures import ThreadPoolExecutor
import signal
import sys

@dataclass
class KafkaLLMMessage:
    message_id: str
    topic: str
    messages: list
    model: str = "llama-2-7b-chat"
    temperature: float = 0.7
    max_tokens: int = 500
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    priority: int = 5
    created_at: str = ""
    metadata: Optional[Dict[str, Any]] = None

class KafkaLLMProcessor:
    def __init__(
        self,
        bootstrap_servers: str = "localhost:9092",
        llm_api_url: str = "http://localhost:8080",
        consumer_group: str = "llm_processors",
        processor_id: Optional[str] = None
    ):
        self.bootstrap_servers = bootstrap_servers
        self.consumer_group = consumer_group
        self.processor_id = processor_id or f"processor_{uuid.uuid4().hex[:8]}"
        
        # Topics
        self.request_topic = "llm_requests"
        self.response_topic = "llm_responses" 
        self.streaming_topic = "llm_streaming"
        self.metrics_topic = "llm_metrics"
        self.errors_topic = "llm_errors"
        
        # Initialize LLM client
        self.llm_client = openai.OpenAI(
            api_key="not-needed",
            base_url=f"{llm_api_url}/v1"
        )
        
        # Kafka clients
        self.producer = None
        self.consumer = None
        self.executor = ThreadPoolExecutor(max_workers=4)
        
        # State
        self.is_running = False
        self.processed_messages = 0
        self.error_count = 0
        
        self.logger = logging.getLogger(__name__)
        
        # Graceful shutdown
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
    
    def _signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        self.logger.info(f"Received signal {signum}, shutting down...")
        self.is_running = False
    
    def _create_producer(self) -> KafkaProducer:
        """Create Kafka producer with proper configuration"""
        return KafkaProducer(
            bootstrap_servers=self.bootstrap_servers,
            value_serializer=lambda x: json.dumps(x).encode('utf-8'),
            key_serializer=lambda x: x.encode('utf-8') if x else None,
            acks='all',  # Wait for all replicas
            retries=3,
            max_in_flight_requests_per_connection=1,
            enable_idempotence=True,
            compression_type='snappy'
        )
    
    def _create_consumer(self) -> KafkaConsumer:
        """Create Kafka consumer with proper configuration"""
        return KafkaConsumer(
            self.request_topic,
            bootstrap_servers=self.bootstrap_servers,
            group_id=self.consumer_group,
            value_deserializer=lambda m: json.loads(m.decode('utf-8')),
            key_deserializer=lambda m: m.decode('utf-8') if m else None,
            auto_offset_reset='latest',
            enable_auto_commit=False,  # Manual commit for reliability
            max_poll_records=1,  # Process one at a time
            session_timeout_ms=30000,
            heartbeat_interval_ms=10000
        )
    
    def start_processing(self):
        """Start processing LLM requests from Kafka"""
        try:
            self.is_running = True
            
            # Initialize Kafka clients
            self.producer = self._create_producer()
            self.consumer = self._create_consumer()
            
            self.logger.info(f"Processor {self.processor_id} started consuming from {self.request_topic}")
            
            # Send startup metric
            self._send_metric("processor_started", {"processor_id": self.processor_id})
            
            # Main processing loop
            for message in self.consumer:
                if not self.is_running:
                    break
                
                try:
                    # Process message
                    self._process_kafka_message(message)
                    
                    # Commit offset after successful processing
                    self.consumer.commit()
                    
                    self.processed_messages += 1
                    
                    # Send periodic metrics
                    if self.processed_messages % 10 == 0:
                        self._send_metric("messages_processed", {
                            "processor_id": self.processor_id,
                            "count": self.processed_messages,
                            "errors": self.error_count
                        })
                        
                except Exception as e:
                    self.error_count += 1
                    self.logger.error(f"Error processing message: {e}")
                    
                    # Send error to error topic
                    self._send_error(message, str(e))
                    
                    # Still commit to avoid reprocessing
                    self.consumer.commit()
                    
        except Exception as e:
            self.logger.error(f"Fatal error in processor: {e}")
        finally:
            self._cleanup()
    
    def _process_kafka_message(self, kafka_message):
        """Process individual Kafka message"""
        try:
            # Parse message
            message_data = kafka_message.value
            llm_message = KafkaLLMMessage(**message_data)
            
            self.logger.info(f"Processing message {llm_message.message_id}")
            
            # Send processing status
            self._send_response({
                "message_id": llm_message.message_id,
                "status": "processing",
                "processor_id": self.processor_id,
                "timestamp": datetime.utcnow().isoformat()
            })
            
            # Check if streaming or regular processing
            if llm_message.metadata and llm_message.metadata.get("streaming", False):
                self._process_streaming_llm(llm_message)
            else:
                self._process_regular_llm(llm_message)
                
        except Exception as e:
            self.logger.error(f"Error in message processing: {e}")
            raise
    
    def _process_regular_llm(self, message: KafkaLLMMessage):
        """Process regular LLM request"""
        try:
            start_time = datetime.utcnow()
            
            # Generate response
            response = self.llm_client.chat.completions.create(
                model=message.model,
                messages=message.messages,
                temperature=message.temperature,
                max_tokens=message.max_tokens
            )
            
            processing_time = (datetime.utcnow() - start_time).total_seconds()
            
            # Send response
            response_data = {
                "message_id": message.message_id,
                "status": "completed",
                "response": response.choices[0].message.content,
                "usage": dict(response.usage) if response.usage else {},
                "processing_time": processing_time,
                "processor_id": self.processor_id,
                "timestamp": datetime.utcnow().isoformat(),
                "user_id": message.user_id,
                "session_id": message.session_id
            }
            
            self._send_response(response_data)
            
            # Send metrics
            self._send_metric("llm_request_completed", {
                "processing_time": processing_time,
                "model": message.model,
                "tokens_used": response.usage.total_tokens if response.usage else 0
            })
            
        except Exception as e:
            self.logger.error(f"Error in regular LLM processing: {e}")
            raise
    
    def _process_streaming_llm(self, message: KafkaLLMMessage):
        """Process streaming LLM request"""
        try:
            start_time = datetime.utcnow()
            
            # Generate streaming response
            response = self.llm_client.chat.completions.create(
                model=message.model,
                messages=message.messages,
                temperature=message.temperature,
                max_tokens=message.max_tokens,
                stream=True
            )
            
            full_response = []
            chunk_count = 0
            
            # Stream chunks to Kafka
            for chunk in response:
                if chunk.choices[0].delta.content:
                    content = chunk.choices[0].delta.content
                    full_response.append(content)
                    chunk_count += 1
                    
                    # Send chunk to streaming topic
                    chunk_data = {
                        "message_id": message.message_id,
                        "chunk_index": chunk_count,
                        "content": content,
                        "is_final": False,
                        "timestamp": datetime.utcnow().isoformat(),
                        "user_id": message.user_id,
                        "session_id": message.session_id
                    }
                    
                    self.producer.send(
                        self.streaming_topic,
                        key=message.message_id,
                        value=chunk_data
                    )
            
            # Send final chunk
            final_chunk = {
                "message_id": message.message_id,
                "chunk_index": chunk_count + 1,
                "content": "",
                "is_final": True,
                "full_response": "".join(full_response),
                "timestamp": datetime.utcnow().isoformat(),
                "user_id": message.user_id,
                "session_id": message.session_id
            }
            
            self.producer.send(
                self.streaming_topic,
                key=message.message_id,
                value=final_chunk
            )
            
            processing_time = (datetime.utcnow() - start_time).total_seconds()
            
            # Send completion response
            response_data = {
                "message_id": message.message_id,
                "status": "completed",
                "response": "".join(full_response),
                "chunks_sent": chunk_count,
                "processing_time": processing_time,
                "processor_id": self.processor_id,
                "timestamp": datetime.utcnow().isoformat(),
                "user_id": message.user_id,
                "session_id": message.session_id
            }
            
            self._send_response(response_data)
            
            # Ensure all messages are sent
            self.producer.flush()
            
        except Exception as e:
            self.logger.error(f"Error in streaming LLM processing: {e}")
            raise
    
    def _send_response(self, response_data: Dict[str, Any]):
        """Send response to response topic"""
        try:
            self.producer.send(
                self.response_topic,
                key=response_data["message_id"],
                value=response_data
            )
        except Exception as e:
            self.logger.error(f"Error sending response: {e}")
    
    def _send_metric(self, metric_name: str, data: Dict[str, Any]):
        """Send metrics to metrics topic"""
        try:
            metric_data = {
                "metric": metric_name,
                "timestamp": datetime.utcnow().isoformat(),
                "processor_id": self.processor_id,
                "data": data
            }
            
            self.producer.send(
                self.metrics_topic,
                key=metric_name,
                value=metric_data
            )
        except Exception as e:
            self.logger.error(f"Error sending metric: {e}")
    
    def _send_error(self, original_message, error: str):
        """Send error to error topic"""
        try:
            error_data = {
                "original_message": original_message.value if hasattr(original_message, 'value') else str(original_message),
                "error": error,
                "processor_id": self.processor_id,
                "timestamp": datetime.utcnow().isoformat()
            }
            
            self.producer.send(
                self.errors_topic,
                value=error_data
            )
        except Exception as e:
            self.logger.error(f"Error sending error message: {e}")
    
    def _cleanup(self):
        """Clean up resources"""
        try:
            # Send shutdown metric
            self._send_metric("processor_shutdown", {
                "processor_id": self.processor_id,
                "messages_processed": self.processed_messages,
                "errors": self.error_count
            })
            
            # Close connections
            if self.producer:
                self.producer.flush()
                self.producer.close()
            
            if self.consumer:
                self.consumer.close()
            
            if self.executor:
                self.executor.shutdown(wait=True)
            
            self.logger.info(f"Processor {self.processor_id} shut down cleanly")
            
        except Exception as e:
            self.logger.error(f"Error during cleanup: {e}")

class KafkaLLMClient:
    """Client for sending requests to Kafka LLM processors"""
    
    def __init__(self, bootstrap_servers: str = "localhost:9092"):
        self.bootstrap_servers = bootstrap_servers
        self.producer = KafkaProducer(
            bootstrap_servers=bootstrap_servers,
            value_serializer=lambda x: json.dumps(x).encode('utf-8'),
            key_serializer=lambda x: x.encode('utf-8') if x else None,
            acks='all',
            retries=3
        )
        
        self.logger = logging.getLogger(__name__)
    
    def send_request(
        self,
        messages: list,
        model: str = "llama-2-7b-chat",
        temperature: float = 0.7,
        max_tokens: int = 500,
        user_id: Optional[str] = None,
        session_id: Optional[str] = None,
        streaming: bool = False,
        priority: int = 5
    ) -> str:
        """Send LLM request to Kafka"""
        
        message_id = str(uuid.uuid4())
        
        request = KafkaLLMMessage(
            message_id=message_id,
            topic="llm_requests",
            messages=messages,
            model=model,
            temperature=temperature,
            max_tokens=max_tokens,
            user_id=user_id,
            session_id=session_id,
            priority=priority,
            created_at=datetime.utcnow().isoformat(),
            metadata={"streaming": streaming}
        )
        
        try:
            # Send to Kafka
            future = self.producer.send(
                "llm_requests",
                key=message_id,
                value=asdict(request)
            )
            
            # Wait for acknowledgment
            record_metadata = future.get(timeout=10)
            
            self.logger.info(f"Sent request {message_id} to {record_metadata.topic}[{record_metadata.partition}]")
            
            return message_id
            
        except KafkaError as e:
            self.logger.error(f"Failed to send request: {e}")
            raise
    
    def close(self):
        """Close producer"""
        try:
            self.producer.flush()
            self.producer.close()
        except Exception as e:
            self.logger.error(f"Error closing producer: {e}")

# Response consumer for monitoring
class KafkaLLMResponseConsumer:
    def __init__(
        self,
        bootstrap_servers: str = "localhost:9092",
        group_id: str = "response_monitors"
    ):
        self.consumer = KafkaConsumer(
            'llm_responses',
            'llm_streaming', 
            'llm_metrics',
            'llm_errors',
            bootstrap_servers=bootstrap_servers,
            group_id=group_id,
            value_deserializer=lambda m: json.loads(m.decode('utf-8')),
            auto_offset_reset='latest'
        )
        
        self.logger = logging.getLogger(__name__)
    
    def start_monitoring(self, callbacks: Dict[str, Callable] = None):
        """Start monitoring responses and metrics"""
        callbacks = callbacks or {}
        
        try:
            self.logger.info("Started monitoring Kafka topics...")
            
            for message in self.consumer:
                topic = message.topic
                data = message.value
                
                if topic == 'llm_responses':
                    callback = callbacks.get('response', self._default_response_handler)
                    callback(data)
                
                elif topic == 'llm_streaming':
                    callback = callbacks.get('streaming', self._default_streaming_handler)
                    callback(data)
                
                elif topic == 'llm_metrics':
                    callback = callbacks.get('metrics', self._default_metrics_handler)
                    callback(data)
                
                elif topic == 'llm_errors':
                    callback = callbacks.get('errors', self._default_error_handler)
                    callback(data)
                    
        except KeyboardInterrupt:
            self.logger.info("Stopping monitoring...")
        finally:
            self.consumer.close()
    
    def _default_response_handler(self, data):
        print(f"Response: {data['message_id']} - {data['status']}")
    
    def _default_streaming_handler(self, data):
        if data['is_final']:
            print(f"Stream complete: {data['message_id']}")
        else:
            print(f"Chunk {data['chunk_index']}: {data['content'][:50]}...")
    
    def _default_metrics_handler(self, data):
        print(f"Metric: {data['metric']} - {data['data']}")
    
    def _default_error_handler(self, data):
        print(f"Error: {data['error']}")

# Usage example
async def demo_kafka_llm():
    # Start processor (in separate process/container)
    # processor = KafkaLLMProcessor()
    # processor.start_processing()
    
    # Client usage
    client = KafkaLLMClient()
    
    try:
        # Send regular request
        message_id = client.send_request(
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": "Explain Kafka in simple terms."}
            ],
            user_id="user123",
            session_id="session456"
        )
        
        print(f"Sent request: {message_id}")
        
        # Send streaming request
        stream_id = client.send_request(
            messages=[
                {"role": "user", "content": "Write a short poem about technology."}
            ],
            streaming=True,
            user_id="user123"
        )
        
        print(f"Sent streaming request: {stream_id}")
        
    finally:
        client.close()

if __name__ == "__main__":
    # Run processor
    processor = KafkaLLMProcessor()
    processor.start_processing()
```

This comprehensive Message Queue Integration section provides production-ready implementations for RabbitMQ (with priority queues and dead letter handling), Redis Pub/Sub (with streaming support), and Apache Kafka (with stream processing and metrics). Each implementation includes proper error handling, monitoring, and scalability features.

## Microservices Architecture

Design patterns and deployment strategies for building scalable LLM applications using microservices architecture.

### Service Design Patterns

Building modular, scalable LLM services with proper separation of concerns and fault tolerance.

**LLM Gateway Service:**

```python
# llm_gateway_service.py - Central gateway for LLM services
from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, Field
from typing import Dict, List, Any, Optional
import httpx
import asyncio
import logging
from datetime import datetime
import uuid
import json
from circuitbreaker import circuit
from cachetools import TTLCache
import consul
import os

# Data models
class LLMRequest(BaseModel):
    model: str = Field(..., description="Model name")
    messages: List[Dict[str, str]] = Field(..., description="Chat messages")
    temperature: float = Field(0.7, ge=0.0, le=2.0)
    max_tokens: int = Field(500, ge=1, le=4000)
    stream: bool = Field(False, description="Enable streaming")
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    
class LLMResponse(BaseModel):
    response: str
    model: str
    usage: Dict[str, int]
    processing_time: float
    service_id: str
    timestamp: str

class ServiceHealth(BaseModel):
    service_id: str
    status: str
    load: float
    last_check: str

class LLMGatewayService:
    def __init__(
        self,
        service_registry_url: str = "http://localhost:8500",
        cache_ttl: int = 300,
        circuit_failure_threshold: int = 5,
        circuit_timeout: int = 60
    ):
        self.app = FastAPI(title="LLM Gateway Service", version="1.0.0")
        self.service_registry_url = service_registry_url
        self.cache = TTLCache(maxsize=1000, ttl=cache_ttl)
        
        # Service discovery
        self.consul_client = consul.Consul(host=service_registry_url.split("://")[1].split(":")[0])
        
        # HTTP client for service calls
        self.http_client = httpx.AsyncClient(timeout=30.0)
        
        # Circuit breaker settings
        self.circuit_failure_threshold = circuit_failure_threshold
        self.circuit_timeout = circuit_timeout
        
        # Service tracking
        self.service_health = {}
        self.request_counts = {}
        
        self.logger = logging.getLogger(__name__)
        
        # Setup middleware and routes
        self._setup_middleware()
        self._setup_routes()
        
        # Start background tasks
        asyncio.create_task(self._health_check_loop())
    
    def _setup_middleware(self):
        """Setup FastAPI middleware"""
        self.app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"]
        )
    
    def _setup_routes(self):
        """Setup API routes"""
        security = HTTPBearer()
        
        @self.app.post("/v1/chat/completions", response_model=LLMResponse)
        async def chat_completions(
            request: LLMRequest,
            background_tasks: BackgroundTasks,
            token: HTTPAuthorizationCredentials = Depends(security)
        ):
            return await self._process_llm_request(request, background_tasks)
        
        @self.app.get("/v1/models")
        async def list_models():
            return await self._get_available_models()
        
        @self.app.get("/health")
        async def health_check():
            return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}
        
        @self.app.get("/services")
        async def list_services():
            return await self._get_service_status()
        
        @self.app.post("/services/refresh")
        async def refresh_services():
            await self._discover_services()
            return {"status": "refreshed"}
    
    async def _process_llm_request(
        self, 
        request: LLMRequest,
        background_tasks: BackgroundTasks
    ) -> LLMResponse:
        """Process LLM request through available services"""
        
        request_id = str(uuid.uuid4())
        start_time = datetime.utcnow()
        
        try:
            # Check cache first
            cache_key = self._get_cache_key(request)
            if cache_key in self.cache and not request.stream:
                self.logger.info(f"Cache hit for request {request_id}")
                cached_response = self.cache[cache_key]
                cached_response["service_id"] = "cache"
                return LLMResponse(**cached_response)
            
            # Select best service
            service_url = await self._select_service(request.model)
            if not service_url:
                raise HTTPException(status_code=503, detail="No available services for model")
            
            # Make request to service
            response = await self._call_llm_service(service_url, request)
            
            processing_time = (datetime.utcnow() - start_time).total_seconds()
            
            # Build response
            llm_response = LLMResponse(
                response=response["response"],
                model=request.model,
                usage=response.get("usage", {}),
                processing_time=processing_time,
                service_id=response.get("service_id", "unknown"),
                timestamp=datetime.utcnow().isoformat()
            )
            
            # Cache successful response
            if not request.stream:
                self.cache[cache_key] = llm_response.dict()
            
            # Log metrics in background
            background_tasks.add_task(
                self._log_request_metrics,
                request_id,
                request.model,
                processing_time,
                "success"
            )
            
            return llm_response
            
        except Exception as e:
            processing_time = (datetime.utcnow() - start_time).total_seconds()
            
            # Log error in background
            background_tasks.add_task(
                self._log_request_metrics,
                request_id,
                request.model,
                processing_time,
                "error",
                str(e)
            )
            
            raise HTTPException(status_code=500, detail=f"Service error: {str(e)}")
    
    def _get_cache_key(self, request: LLMRequest) -> str:
        """Generate cache key for request"""
        key_data = {
            "model": request.model,
            "messages": request.messages,
            "temperature": request.temperature,
            "max_tokens": request.max_tokens
        }
        return hash(json.dumps(key_data, sort_keys=True))
    
    async def _select_service(self, model: str) -> Optional[str]:
        """Select best available service for model"""
        try:
            # Get healthy services from Consul
            services = await self._get_healthy_services()
            
            # Filter services that support the model
            compatible_services = []
            for service in services:
                if await self._service_supports_model(service["url"], model):
                    compatible_services.append(service)
            
            if not compatible_services:
                return None
            
            # Select service with lowest load
            best_service = min(compatible_services, key=lambda s: s.get("load", 0))
            return best_service["url"]
            
        except Exception as e:
            self.logger.error(f"Error selecting service: {e}")
            return None
    
    @circuit(failure_threshold=5, recovery_timeout=60)
    async def _call_llm_service(self, service_url: str, request: LLMRequest) -> Dict[str, Any]:
        """Call LLM service with circuit breaker"""
        try:
            response = await self.http_client.post(
                f"{service_url}/v1/chat/completions",
                json=request.dict(),
                headers={"Authorization": "Bearer dummy"}
            )
            
            response.raise_for_status()
            return response.json()
            
        except Exception as e:
            self.logger.error(f"Error calling service {service_url}: {e}")
            raise
    
    async def _get_healthy_services(self) -> List[Dict[str, Any]]:
        """Get healthy LLM services from Consul"""
        try:
            # Get services from Consul
            services = self.consul_client.health.service("llm-service", passing=True)[1]
            
            healthy_services = []
            for service in services:
                service_info = service["Service"]
                healthy_services.append({
                    "id": service_info["ID"],
                    "url": f"http://{service_info['Address']}:{service_info['Port']}",
                    "load": self.service_health.get(service_info["ID"], {}).get("load", 0)
                })
            
            return healthy_services
            
        except Exception as e:
            self.logger.error(f"Error getting services: {e}")
            return []
    
    async def _service_supports_model(self, service_url: str, model: str) -> bool:
        """Check if service supports the requested model"""
        try:
            response = await self.http_client.get(f"{service_url}/v1/models", timeout=5.0)
            models = response.json().get("data", [])
            return any(m.get("id") == model for m in models)
        except Exception:
            return True  # Assume support if can't check
    
    async def _get_available_models(self) -> Dict[str, Any]:
        """Get all available models from services"""
        all_models = set()
        services = await self._get_healthy_services()
        
        for service in services:
            try:
                response = await self.http_client.get(f"{service['url']}/v1/models", timeout=5.0)
                models = response.json().get("data", [])
                all_models.update(m.get("id") for m in models if m.get("id"))
            except Exception:
                continue
        
        return {
            "object": "list",
            "data": [{"id": model, "object": "model"} for model in sorted(all_models)]
        }
    
    async def _get_service_status(self) -> Dict[str, Any]:
        """Get status of all services"""
        return {
            "services": self.service_health,
            "total_requests": sum(self.request_counts.values()),
            "timestamp": datetime.utcnow().isoformat()
        }
    
    async def _discover_services(self):
        """Discover and register with services"""
        try:
            services = await self._get_healthy_services()
            for service in services:
                if service["id"] not in self.service_health:
                    self.service_health[service["id"]] = {
                        "status": "healthy",
                        "load": 0,
                        "last_check": datetime.utcnow().isoformat()
                    }
                    self.request_counts[service["id"]] = 0
                    
        except Exception as e:
            self.logger.error(f"Error discovering services: {e}")
    
    async def _health_check_loop(self):
        """Background health check for services"""
        while True:
            try:
                await asyncio.sleep(30)  # Check every 30 seconds
                await self._check_service_health()
            except Exception as e:
                self.logger.error(f"Error in health check loop: {e}")
    
    async def _check_service_health(self):
        """Check health of all registered services"""
        for service_id, health_info in self.service_health.items():
            try:
                services = await self._get_healthy_services()
                service = next((s for s in services if s["id"] == service_id), None)
                
                if service:
                    # Check service health
                    response = await self.http_client.get(
                        f"{service['url']}/health",
                        timeout=5.0
                    )
                    
                    if response.status_code == 200:
                        self.service_health[service_id].update({
                            "status": "healthy",
                            "load": response.json().get("load", 0),
                            "last_check": datetime.utcnow().isoformat()
                        })
                    else:
                        self.service_health[service_id]["status"] = "unhealthy"
                else:
                    self.service_health[service_id]["status"] = "unavailable"
                    
            except Exception as e:
                self.service_health[service_id]["status"] = "error"
                self.logger.error(f"Health check failed for {service_id}: {e}")
    
    async def _log_request_metrics(
        self,
        request_id: str,
        model: str,
        processing_time: float,
        status: str,
        error: Optional[str] = None
    ):
        """Log request metrics for monitoring"""
        metric = {
            "request_id": request_id,
            "model": model,
            "processing_time": processing_time,
            "status": status,
            "error": error,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # Send to monitoring system (e.g., Prometheus, DataDog)
        self.logger.info(f"Request metric: {json.dumps(metric)}")
    
    async def cleanup(self):
        """Cleanup resources"""
        await self.http_client.aclose()

# Service startup
def create_gateway_service():
    gateway = LLMGatewayService()
    return gateway.app

# For running directly
if __name__ == "__main__":
    import uvicorn
    app = create_gateway_service()
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### Container Deployment

Containerized deployment patterns using Docker and Kubernetes for LLM microservices.

**Docker Configuration:**

```dockerfile
# Dockerfile.llm-service - Containerized LLM service
FROM python:3.11-slim as builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    cuda-toolkit-11-8 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set work directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY src/ ./src/
COPY config/ ./config/

# Create model directory and set permissions
RUN mkdir -p /app/models && chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Start command
CMD ["python", "-m", "src.main", "--host", "0.0.0.0", "--port", "8080"]

# Multi-stage build for production
FROM python:3.11-slim as production

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /app /app
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

WORKDIR /app
USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

CMD ["python", "-m", "src.main", "--host", "0.0.0.0", "--port", "8080"]
```

**Docker Compose for Development:**

```yaml
# docker-compose.yml - Full LLM microservices stack
version: '3.8'

services:
  # Service Registry
  consul:
    image: consul:1.16
    ports:
      - "8500:8500"
    command: agent -server -bootstrap-expect=1 -ui -bind=0.0.0.0 -client=0.0.0.0
    environment:
      - CONSUL_BIND_INTERFACE=eth0
    volumes:
      - consul_data:/consul/data
    networks:
      - llm_network

  # Message Queue
  rabbitmq:
    image: rabbitmq:3.12-management
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      - RABBITMQ_DEFAULT_USER=llm_user
      - RABBITMQ_DEFAULT_PASS=llm_password
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - llm_network

  # Cache and Session Store
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - llm_network

  # Database
  mongodb:
    image: mongo:7
    ports:
      - "27017:27017"
    environment:
      - MONGO_INITDB_ROOT_USERNAME=llm_user
      - MONGO_INITDB_ROOT_PASSWORD=llm_password
    volumes:
      - mongodb_data:/data/db
    networks:
      - llm_network

  # Vector Database
  chromadb:
    image: chromadb/chroma:latest
    ports:
      - "8000:8000"
    volumes:
      - chroma_data:/chroma/chroma
    networks:
      - llm_network

  # LLM Gateway Service
  llm-gateway:
    build:
      context: .
      dockerfile: Dockerfile.gateway
    ports:
      - "8080:8080"
    environment:
      - SERVICE_REGISTRY_URL=http://consul:8500
      - REDIS_URL=redis://redis:6379
      - MONGODB_URL=mongodb://llm_user:llm_password@mongodb:27017
      - RABBITMQ_URL=amqp://llm_user:llm_password@rabbitmq:5672
    depends_on:
      - consul
      - redis
      - mongodb
      - rabbitmq
    networks:
      - llm_network
    deploy:
      replicas: 2
      resources:
        limits:
          memory: 1G
          cpus: '0.5'

  # LLM Service Workers
  llm-worker-1:
    build:
      context: .
      dockerfile: Dockerfile.llm-service
    environment:
      - MODEL_NAME=llama-2-7b-chat
      - SERVICE_PORT=8081
      - WORKER_ID=worker-1
      - SERVICE_REGISTRY_URL=http://consul:8500
      - GPU_ENABLED=false
    depends_on:
      - consul
    ports:
      - "8081:8081"
    networks:
      - llm_network
    volumes:
      - model_cache:/app/models
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: '2.0'

  llm-worker-2:
    build:
      context: .
      dockerfile: Dockerfile.llm-service
    environment:
      - MODEL_NAME=mistral-7b-instruct
      - SERVICE_PORT=8082
      - WORKER_ID=worker-2
      - SERVICE_REGISTRY_URL=http://consul:8500
      - GPU_ENABLED=false
    depends_on:
      - consul
    ports:
      - "8082:8082"
    networks:
      - llm_network
    volumes:
      - model_cache:/app/models
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: '2.0'

  # Monitoring
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    networks:
      - llm_network

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/dashboards:/etc/grafana/provisioning/dashboards
    networks:
      - llm_network

  # Load Balancer
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
    depends_on:
      - llm-gateway
    networks:
      - llm_network

volumes:
  consul_data:
  rabbitmq_data:
  redis_data:
  mongodb_data:
  chroma_data:
  model_cache:
  prometheus_data:
  grafana_data:

networks:
  llm_network:
    driver: bridge
```

**Kubernetes Deployment:**

```yaml
# k8s-deployment.yaml - Kubernetes deployment for LLM microservices
apiVersion: v1
kind: Namespace
metadata:
  name: llm-services

---
# ConfigMap for service configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: llm-config
  namespace: llm-services
data:
  REDIS_URL: "redis://redis-service:6379"
  MONGODB_URL: "mongodb://mongodb-service:27017"
  SERVICE_REGISTRY_URL: "http://consul-service:8500"
  LOG_LEVEL: "INFO"

---
# Secret for sensitive data
apiVersion: v1
kind: Secret
metadata:
  name: llm-secrets
  namespace: llm-services
type: Opaque
stringData:
  MONGODB_USERNAME: "llm_user"
  MONGODB_PASSWORD: "llm_password"
  RABBITMQ_USERNAME: "llm_user"
  RABBITMQ_PASSWORD: "llm_password"

---
# Redis Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: llm-services
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
        volumeMounts:
        - name: redis-storage
          mountPath: /data
      volumes:
      - name: redis-storage
        persistentVolumeClaim:
          claimName: redis-pvc

---
# Redis Service
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: llm-services
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379

---
# LLM Gateway Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: llm-gateway
  namespace: llm-services
spec:
  replicas: 3
  selector:
    matchLabels:
      app: llm-gateway
  template:
    metadata:
      labels:
        app: llm-gateway
    spec:
      containers:
      - name: llm-gateway
        image: llm-gateway:latest
        ports:
        - containerPort: 8080
        env:
        - name: SERVICE_REGISTRY_URL
          valueFrom:
            configMapKeyRef:
              name: llm-config
              key: SERVICE_REGISTRY_URL
        - name: REDIS_URL
          valueFrom:
            configMapKeyRef:
              name: llm-config
              key: REDIS_URL
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10

---
# LLM Gateway Service
apiVersion: v1
kind: Service
metadata:
  name: llm-gateway-service
  namespace: llm-services
spec:
  selector:
    app: llm-gateway
  ports:
  - port: 8080
    targetPort: 8080
  type: LoadBalancer

---
# LLM Worker Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: llm-worker
  namespace: llm-services
spec:
  replicas: 2
  selector:
    matchLabels:
      app: llm-worker
  template:
    metadata:
      labels:
        app: llm-worker
    spec:
      containers:
      - name: llm-worker
        image: llm-worker:latest
        ports:
        - containerPort: 8081
        env:
        - name: MODEL_NAME
          value: "llama-2-7b-chat"
        - name: SERVICE_REGISTRY_URL
          valueFrom:
            configMapKeyRef:
              name: llm-config
              key: SERVICE_REGISTRY_URL
        resources:
          requests:
            memory: "2Gi"
            cpu: "1"
            nvidia.com/gpu: 1
          limits:
            memory: "4Gi"
            cpu: "2"
            nvidia.com/gpu: 1
        volumeMounts:
        - name: model-cache
          mountPath: /app/models
        readinessProbe:
          httpGet:
            path: /health
            port: 8081
          initialDelaySeconds: 60
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /health
            port: 8081
          initialDelaySeconds: 120
          periodSeconds: 30
      volumes:
      - name: model-cache
        persistentVolumeClaim:
          claimName: model-cache-pvc
      nodeSelector:
        gpu: "true"

---
# Horizontal Pod Autoscaler
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: llm-gateway-hpa
  namespace: llm-services
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: llm-gateway
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

---
# Persistent Volume Claims
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-pvc
  namespace: llm-services
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: model-cache-pvc
  namespace: llm-services
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 50Gi

---
# Network Policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: llm-network-policy
  namespace: llm-services
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector: {}
  egress:
  - to:
    - podSelector: {}
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

### Service Discovery

Service registration and discovery patterns for dynamic LLM service management.

```python
# service_discovery.py - Service discovery for LLM microservices
import consul
import asyncio
import json
import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
from datetime import datetime
import socket
import threading
import time

@dataclass
class ServiceInfo:
    service_id: str
    service_name: str
    address: str
    port: int
    tags: List[str]
    metadata: Dict[str, Any]
    health_check_url: str
    
class ConsulServiceDiscovery:
    def __init__(
        self,
        consul_host: str = "localhost",
        consul_port: int = 8500,
        datacenter: str = "dc1"
    ):
        self.consul = consul.Consul(host=consul_host, port=consul_port, dc=datacenter)
        self.logger = logging.getLogger(__name__)
        self.registered_services = {}
        
    def register_service(
        self,
        service_info: ServiceInfo,
        health_check_interval: int = 30,
        deregister_critical_after: str = "1m"
    ) -> bool:
        """Register a service with Consul"""
        try:
            # Prepare health check
            health_check = {
                "http": service_info.health_check_url,
                "interval": f"{health_check_interval}s",
                "deregister_critical_service_after": deregister_critical_after,
                "timeout": "10s"
            }
            
            # Register service
            success = self.consul.agent.service.register(
                name=service_info.service_name,
                service_id=service_info.service_id,
                address=service_info.address,
                port=service_info.port,
                tags=service_info.tags,
                meta=service_info.metadata,
                check=health_check
            )
            
            if success:
                self.registered_services[service_info.service_id] = service_info
                self.logger.info(f"Registered service: {service_info.service_id}")
                return True
            else:
                self.logger.error(f"Failed to register service: {service_info.service_id}")
                return False
                
        except Exception as e:
            self.logger.error(f"Error registering service: {e}")
            return False
    
    def deregister_service(self, service_id: str) -> bool:
        """Deregister a service from Consul"""
        try:
            success = self.consul.agent.service.deregister(service_id)
            
            if success and service_id in self.registered_services:
                del self.registered_services[service_id]
                self.logger.info(f"Deregistered service: {service_id}")
                return True
            else:
                self.logger.error(f"Failed to deregister service: {service_id}")
                return False
                
        except Exception as e:
            self.logger.error(f"Error deregistering service: {e}")
            return False
    
    def discover_services(
        self,
        service_name: str,
        tag: Optional[str] = None,
        healthy_only: bool = True
    ) -> List[Dict[str, Any]]:
        """Discover services by name and optional tag"""
        try:
            if healthy_only:
                # Get only healthy services
                _, services = self.consul.health.service(service_name, tag=tag, passing=True)
            else:
                # Get all services
                _, services = self.consul.catalog.service(service_name, tag=tag)
            
            discovered_services = []
            for service in services:
                if healthy_only:
                    service_info = service["Service"]
                else:
                    service_info = service
                
                discovered_services.append({
                    "service_id": service_info["ID"],
                    "service_name": service_info["Service"],
                    "address": service_info["Address"],
                    "port": service_info["Port"],
                    "tags": service_info.get("Tags", []),
                    "metadata": service_info.get("Meta", {}),
                    "url": f"http://{service_info['Address']}:{service_info['Port']}"
                })
            
            self.logger.info(f"Discovered {len(discovered_services)} services for {service_name}")
            return discovered_services
            
        except Exception as e:
            self.logger.error(f"Error discovering services: {e}")
            return []
    
    def watch_service_changes(
        self,
        service_name: str,
        callback: callable,
        tag: Optional[str] = None
    ):
        """Watch for service changes and trigger callback"""
        def watch_thread():
            index = None
            while True:
                try:
                    # Long poll for changes
                    index, services = self.consul.health.service(
                        service_name,
                        tag=tag,
                        index=index,
                        wait="30s"
                    )
                    
                    # Process service changes
                    current_services = []
                    for service in services:
                        service_info = service["Service"]
                        current_services.append({
                            "service_id": service_info["ID"],
                            "service_name": service_info["Service"],
                            "address": service_info["Address"],
                            "port": service_info["Port"],
                            "status": "passing" if service["Checks"] and 
                                    all(check["Status"] == "passing" for check in service["Checks"]) 
                                    else "failing"
                        })
                    
                    # Trigger callback
                    callback(current_services)
                    
                except Exception as e:
                    self.logger.error(f"Error watching service changes: {e}")
                    time.sleep(5)  # Wait before retrying
        
        # Start watching in background thread
        watch_thread = threading.Thread(target=watch_thread, daemon=True)
        watch_thread.start()
    
    def get_service_metadata(self, service_name: str) -> Dict[str, Any]:
        """Get aggregated metadata for all instances of a service"""
        services = self.discover_services(service_name)
        
        metadata = {
            "service_name": service_name,
            "instance_count": len(services),
            "healthy_instances": len([s for s in services if s.get("status") == "passing"]),
            "instances": services,
            "tags": list(set(tag for service in services for tag in service.get("tags", []))),
            "updated_at": datetime.utcnow().isoformat()
        }
        
        return metadata
    
    def cleanup(self):
        """Cleanup and deregister all services"""
        for service_id in list(self.registered_services.keys()):
            self.deregister_service(service_id)

class LLMServiceRegistry:
    """LLM-specific service registry with model capability tracking"""
    
    def __init__(self, consul_discovery: ConsulServiceDiscovery):
        self.consul = consul_discovery
        self.service_capabilities = {}
        self.logger = logging.getLogger(__name__)
    
    def register_llm_service(
        self,
        service_id: str,
        address: str,
        port: int,
        supported_models: List[str],
        max_concurrent_requests: int = 10,
        gpu_enabled: bool = False,
        custom_metadata: Optional[Dict[str, Any]] = None
    ) -> bool:
        """Register an LLM service with capability information"""
        
        # Build tags
        tags = ["llm-service"]
        if gpu_enabled:
            tags.append("gpu-enabled")
        tags.extend([f"model:{model}" for model in supported_models])
        
        # Build metadata
        metadata = {
            "supported_models": ",".join(supported_models),
            "max_concurrent_requests": str(max_concurrent_requests),
            "gpu_enabled": str(gpu_enabled),
            "registered_at": datetime.utcnow().isoformat()
        }
        
        if custom_metadata:
            metadata.update(custom_metadata)
        
        # Create service info
        service_info = ServiceInfo(
            service_id=service_id,
            service_name="llm-service",
            address=address,
            port=port,
            tags=tags,
            metadata=metadata,
            health_check_url=f"http://{address}:{port}/health"
        )
        
        # Register with Consul
        success = self.consul.register_service(service_info)
        
        if success:
            # Store capability information
            self.service_capabilities[service_id] = {
                "supported_models": supported_models,
                "max_concurrent_requests": max_concurrent_requests,
                "gpu_enabled": gpu_enabled,
                "current_load": 0
            }
        
        return success
    
    def find_services_for_model(
        self,
        model_name: str,
        require_gpu: bool = False,
        max_load_threshold: float = 0.8
    ) -> List[Dict[str, Any]]:
        """Find services that support a specific model"""
        
        # Build tag filter
        tags = [f"model:{model_name}"]
        if require_gpu:
            tags.append("gpu-enabled")
        
        # Discover services
        services = []
        for tag in tags:
            found_services = self.consul.discover_services("llm-service", tag=tag)
            services.extend(found_services)
        
        # Remove duplicates and filter by load
        unique_services = {}
        for service in services:
            service_id = service["service_id"]
            if service_id not in unique_services:
                # Check current load
                capability = self.service_capabilities.get(service_id, {})
                current_load = capability.get("current_load", 0)
                max_requests = capability.get("max_concurrent_requests", 10)
                
                load_ratio = current_load / max_requests if max_requests > 0 else 0
                
                if load_ratio <= max_load_threshold:
                    service["load_ratio"] = load_ratio
                    service["current_load"] = current_load
                    service["max_requests"] = max_requests
                    unique_services[service_id] = service
        
        # Sort by load (lowest first)
        sorted_services = sorted(
            unique_services.values(),
            key=lambda s: s["load_ratio"]
        )
        
        return sorted_services
    
    def update_service_load(self, service_id: str, current_load: int):
        """Update current load for a service"""
        if service_id in self.service_capabilities:
            self.service_capabilities[service_id]["current_load"] = current_load
    
    def get_model_availability(self) -> Dict[str, Dict[str, Any]]:
        """Get availability information for all models"""
        services = self.consul.discover_services("llm-service")
        model_availability = {}
        
        for service in services:
            models_str = service["metadata"].get("supported_models", "")
            if models_str:
                models = models_str.split(",")
                for model in models:
                    model = model.strip()
                    if model not in model_availability:
                        model_availability[model] = {
                            "available_services": 0,
                            "total_capacity": 0,
                            "current_load": 0,
                            "gpu_enabled_services": 0
                        }
                    
                    model_availability[model]["available_services"] += 1
                    
                    max_requests = int(service["metadata"].get("max_concurrent_requests", 10))
                    model_availability[model]["total_capacity"] += max_requests
                    
                    service_id = service["service_id"]
                    if service_id in self.service_capabilities:
                        current_load = self.service_capabilities[service_id]["current_load"]
                        model_availability[model]["current_load"] += current_load
                    
                    if service["metadata"].get("gpu_enabled") == "true":
                        model_availability[model]["gpu_enabled_services"] += 1
        
        # Calculate utilization rates
        for model_info in model_availability.values():
            total_capacity = model_info["total_capacity"]
            current_load = model_info["current_load"]
            model_info["utilization_rate"] = (
                current_load / total_capacity if total_capacity > 0 else 0
            )
        
        return model_availability

# Usage example
async def demo_service_discovery():
    # Initialize service discovery
    consul_discovery = ConsulServiceDiscovery()
    llm_registry = LLMServiceRegistry(consul_discovery)
    
    try:
        # Register LLM services
        success1 = llm_registry.register_llm_service(
            service_id="llm-worker-1",
            address="192.168.1.10",
            port=8081,
            supported_models=["llama-2-7b-chat", "mistral-7b-instruct"],
            max_concurrent_requests=5,
            gpu_enabled=True
        )
        
        success2 = llm_registry.register_llm_service(
            service_id="llm-worker-2", 
            address="192.168.1.11",
            port=8082,
            supported_models=["llama-2-7b-chat", "code-llama-7b"],
            max_concurrent_requests=3,
            gpu_enabled=False
        )
        
        print(f"Service registration: {success1}, {success2}")
        
        # Find services for a model
        services = llm_registry.find_services_for_model("llama-2-7b-chat")
        print(f"Services for llama-2-7b-chat: {len(services)}")
        
        # Get model availability
        availability = llm_registry.get_model_availability()
        print(f"Model availability: {json.dumps(availability, indent=2)}")
        
        # Simulate load updates
        llm_registry.update_service_load("llm-worker-1", 3)
        llm_registry.update_service_load("llm-worker-2", 1)
        
        # Watch for service changes
        def on_service_change(services):
            print(f"Service change detected: {len(services)} active services")
        
        consul_discovery.watch_service_changes("llm-service", on_service_change)
        
        # Keep running for a bit
        await asyncio.sleep(30)
        
    finally:
        # Cleanup
        consul_discovery.cleanup()

if __name__ == "__main__":
    asyncio.run(demo_service_discovery())
```

This comprehensive Microservices Architecture section covers service design patterns (LLM gateway with circuit breakers and load balancing), container deployment (Docker and Kubernetes configurations), and service discovery (Consul-based with LLM-specific capability tracking). Each component includes production-ready patterns with proper health checks, scaling, and monitoring.

## Development Tools

### Postman

API testing.

### Swagger/OpenAPI

API documentation.

### Testing Frameworks

Automated testing.

## SDK Development

Building custom Software Development Kits (SDKs) to simplify LLM integration and provide idiomatic interfaces for different programming languages.

### Creating Custom SDKs

Designing and implementing client libraries that abstract API complexity and provide language-specific conveniences.

**SDK Architecture Principles:**

```python
# python_llm_sdk/client.py
from typing import List, Dict, Optional, Union, Iterator, AsyncIterator
from dataclasses import dataclass, asdict
from abc import ABC, abstractmethod
import httpx
import asyncio
import json
from enum import Enum

class ModelCapability(Enum):
    CHAT = "chat"
    COMPLETION = "completion"
    EMBEDDING = "embedding"
    CODE = "code"
    FUNCTION_CALLING = "function_calling"

@dataclass
class Message:
    role: str
    content: str
    name: Optional[str] = None
    function_call: Optional[Dict] = None

@dataclass
class ChatResponse:
    content: str
    model: str
    usage: Dict[str, int]
    finish_reason: str
    response_id: str

@dataclass
class StreamChunk:
    content: str
    is_complete: bool
    chunk_id: str
    model: str

class LLMClientConfig:
    def __init__(
        self,
        base_url: str,
        api_key: Optional[str] = None,
        timeout: int = 30,
        max_retries: int = 3,
        user_agent: str = "LocalLLM-SDK/1.0",
        default_model: str = "llama-2-7b-chat"
    ):
        self.base_url = base_url.rstrip('/')
        self.api_key = api_key
        self.timeout = timeout
        self.max_retries = max_retries
        self.user_agent = user_agent
        self.default_model = default_model

class LocalLLMClient:
    """Main client class for local LLM integration"""
    
    def __init__(self, config: LLMClientConfig):
        self.config = config
        self._client = httpx.AsyncClient(
            timeout=config.timeout,
            headers={
                "User-Agent": config.user_agent,
                "Authorization": f"Bearer {config.api_key}" if config.api_key else None
            }
        )
        self._models_cache = None
    
    async def __aenter__(self):
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self._client.aclose()
    
    async def chat(
        self,
        messages: List[Union[Message, Dict]],
        model: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 500,
        stream: bool = False,
        **kwargs
    ) -> Union[ChatResponse, AsyncIterator[StreamChunk]]:
        """Generate chat completion"""
        
        # Normalize messages
        normalized_messages = []
        for msg in messages:
            if isinstance(msg, Message):
                normalized_messages.append(asdict(msg))
            else:
                normalized_messages.append(msg)
        
        payload = {
            "model": model or self.config.default_model,
            "messages": normalized_messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
            "stream": stream,
            **kwargs
        }
        
        if stream:
            return self._stream_chat(payload)
        else:
            return await self._single_chat(payload)
    
    async def _single_chat(self, payload: Dict) -> ChatResponse:
        """Handle single chat completion"""
        response = await self._client.post(
            f"{self.config.base_url}/v1/chat/completions",
            json=payload
        )
        response.raise_for_status()
        
        data = response.json()
        choice = data["choices"][0]
        
        return ChatResponse(
            content=choice["message"]["content"],
            model=data["model"],
            usage=data.get("usage", {}),
            finish_reason=choice.get("finish_reason", "stop"),
            response_id=data.get("id", "")
        )
    
    async def _stream_chat(self, payload: Dict) -> AsyncIterator[StreamChunk]:
        """Handle streaming chat completion"""
        async with self._client.stream(
            "POST",
            f"{self.config.base_url}/v1/chat/completions",
            json=payload
        ) as response:
            response.raise_for_status()
            
            async for line in response.aiter_lines():
                if line.startswith("data: "):
                    data_str = line[6:]
                    
                    if data_str.strip() == "[DONE]":
                        yield StreamChunk(
                            content="",
                            is_complete=True,
                            chunk_id="final",
                            model=payload["model"]
                        )
                        break
                    
                    try:
                        data = json.loads(data_str)
                        choice = data["choices"][0]
                        delta = choice.get("delta", {})
                        
                        if "content" in delta:
                            yield StreamChunk(
                                content=delta["content"],
                                is_complete=False,
                                chunk_id=data.get("id", ""),
                                model=data["model"]
                            )
                    except json.JSONDecodeError:
                        continue
    
    async def get_models(self, force_refresh: bool = False) -> List[Dict]:
        """Get available models"""
        if self._models_cache is None or force_refresh:
            response = await self._client.get(f"{self.config.base_url}/v1/models")
            response.raise_for_status()
            self._models_cache = response.json()["data"]
        
        return self._models_cache
    
    async def health_check(self) -> Dict[str, str]:
        """Check API health status"""
        try:
            response = await self._client.get(f"{self.config.base_url}/health")
            response.raise_for_status()
            return {"status": "healthy", "response_time": str(response.elapsed.total_seconds())}
        except Exception as e:
            return {"status": "unhealthy", "error": str(e)}

# Usage example
async def demo_sdk():
    config = LLMClientConfig(
        base_url="http://localhost:8080",
        default_model="llama-2-7b-chat",
        timeout=60
    )
    
    async with LocalLLMClient(config) as client:
        # Single completion
        response = await client.chat([
            Message(role="user", content="Hello, how are you?")
        ])
        print(f"Response: {response.content}")
        
        # Streaming completion
        async for chunk in client.chat(
            messages=[{"role": "user", "content": "Tell me a story"}],
            stream=True
        ):
            if not chunk.is_complete:
                print(chunk.content, end="", flush=True)
```

### Wrapper Libraries

Creating simplified interfaces that abstract complex integration patterns and provide framework-specific conveniences.

**FastAPI Integration Wrapper:**

```python
# fastapi_llm_wrapper.py
from fastapi import FastAPI, Depends, HTTPException, Request
from fastapi.responses import StreamingResponse
from typing import List, Dict, Optional, AsyncGenerator
import asyncio
import json
from local_llm_sdk import LocalLLMClient, LLMClientConfig, Message

class FastAPILLMWrapper:
    def __init__(self, client: LocalLLMClient):
        self.client = client
        self.app = FastAPI(title="LLM FastAPI Wrapper")
        self._setup_routes()
    
    def _setup_routes(self):
        @self.app.post("/chat")
        async def chat_endpoint(
            messages: List[Dict[str, str]],
            model: Optional[str] = None,
            temperature: float = 0.7,
            max_tokens: int = 500,
            stream: bool = False
        ):
            try:
                if stream:
                    return StreamingResponse(
                        self._stream_generator(messages, model, temperature, max_tokens),
                        media_type="text/event-stream"
                    )
                else:
                    response = await self.client.chat(
                        messages=messages,
                        model=model,
                        temperature=temperature,
                        max_tokens=max_tokens
                    )
                    return {
                        "content": response.content,
                        "model": response.model,
                        "usage": response.usage
                    }
            except Exception as e:
                raise HTTPException(status_code=500, detail=str(e))
        
        @self.app.get("/models")
        async def models_endpoint():
            try:
                models = await self.client.get_models()
                return {"models": models}
            except Exception as e:
                raise HTTPException(status_code=500, detail=str(e))
    
    async def _stream_generator(
        self,
        messages: List[Dict],
        model: Optional[str],
        temperature: float,
        max_tokens: int
    ) -> AsyncGenerator[str, None]:
        async for chunk in self.client.chat(
            messages=messages,
            model=model,
            temperature=temperature,
            max_tokens=max_tokens,
            stream=True
        ):
            yield f"data: {json.dumps({'content': chunk.content, 'complete': chunk.is_complete})}\n\n"
            
            if chunk.is_complete:
                yield "data: [DONE]\n\n"
                break

# Django Integration Wrapper
class DjangoLLMWrapper:
    def __init__(self, client: LocalLLMClient):
        self.client = client
    
    async def process_chat_view(self, request):
        """Django view function wrapper"""
        from django.http import JsonResponse, StreamingHttpResponse
        import json
        
        if request.method == 'POST':
            try:
                data = json.loads(request.body)
                messages = data.get('messages', [])
                stream = data.get('stream', False)
                
                if stream:
                    return StreamingHttpResponse(
                        self._django_stream_generator(messages),
                        content_type='text/event-stream'
                    )
                else:
                    response = await self.client.chat(messages=messages)
                    return JsonResponse({
                        'content': response.content,
                        'model': response.model
                    })
            except Exception as e:
                return JsonResponse({'error': str(e)}, status=500)
    
    async def _django_stream_generator(self, messages):
        async for chunk in self.client.chat(messages=messages, stream=True):
            yield f"data: {json.dumps({'content': chunk.content})}\n\n"
```

### Type Definitions

Providing comprehensive TypeScript definitions for type-safe integration in JavaScript/TypeScript applications.

**TypeScript SDK:**

```typescript
// types/llm-client.d.ts
export interface Message {
  role: 'system' | 'user' | 'assistant' | 'function';
  content: string;
  name?: string;
  function_call?: {
    name: string;
    arguments: string;
  };
}

export interface ChatCompletionRequest {
  model: string;
  messages: Message[];
  temperature?: number;
  max_tokens?: number;
  top_p?: number;
  frequency_penalty?: number;
  presence_penalty?: number;
  stop?: string | string[];
  stream?: boolean;
  user?: string;
}

export interface ChatCompletionResponse {
  id: string;
  object: 'chat.completion';
  created: number;
  model: string;
  choices: {
    index: number;
    message: Message;
    finish_reason: 'stop' | 'length' | 'function_call' | 'content_filter';
  }[];
  usage: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
}

export interface StreamChunk {
  id: string;
  object: 'chat.completion.chunk';
  created: number;
  model: string;
  choices: {
    index: number;
    delta: {
      role?: string;
      content?: string;
      function_call?: {
        name?: string;
        arguments?: string;
      };
    };
    finish_reason?: string;
  }[];
}

export interface LLMClientConfig {
  baseURL: string;
  apiKey?: string;
  timeout?: number;
  maxRetries?: number;
  defaultModel?: string;
}

export interface ModelInfo {
  id: string;
  object: 'model';
  created: number;
  owned_by: string;
  capabilities: string[];
  max_context_length: number;
}

// Main client class
export declare class LocalLLMClient {
  constructor(config: LLMClientConfig);
  
  chat(
    request: ChatCompletionRequest
  ): Promise<ChatCompletionResponse>;
  
  chatStream(
    request: ChatCompletionRequest
  ): AsyncIterable<StreamChunk>;
  
  getModels(): Promise<ModelInfo[]>;
  
  healthCheck(): Promise<{
    status: 'healthy' | 'unhealthy';
    responseTime?: number;
    error?: string;
  }>;
}

// Utility types
export type StreamingCallback = (chunk: StreamChunk) => void;
export type ErrorCallback = (error: Error) => void;

// Configuration helpers
export interface RetryConfig {
  maxAttempts: number;
  backoffBase: number;
  backoffMax: number;
  retryCondition?: (error: any) => boolean;
}

export interface CacheConfig {
  enabled: boolean;
  ttl: number;
  maxSize: number;
  keyGenerator?: (request: ChatCompletionRequest) => string;
}
```

**JavaScript Implementation:**

```javascript
// llm-client.js
class LocalLLMClient {
  constructor(config) {
    this.config = {
      timeout: 30000,
      maxRetries: 3,
      defaultModel: 'llama-2-7b-chat',
      ...config
    };
    
    if (!this.config.baseURL) {
      throw new Error('baseURL is required');
    }
  }
  
  async chat(request) {
    const url = `${this.config.baseURL}/v1/chat/completions`;
    const response = await this._makeRequest(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(this.config.apiKey && {
          'Authorization': `Bearer ${this.config.apiKey}`
        })
      },
      body: JSON.stringify({
        model: this.config.defaultModel,
        ...request
      })
    });
    
    return await response.json();
  }
  
  async* chatStream(request) {
    const url = `${this.config.baseURL}/v1/chat/completions`;
    const response = await this._makeRequest(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        ...(this.config.apiKey && {
          'Authorization': `Bearer ${this.config.apiKey}`
        })
      },
      body: JSON.stringify({
        model: this.config.defaultModel,
        stream: true,
        ...request
      })
    });
    
    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    
    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        
        const chunk = decoder.decode(value);
        const lines = chunk.split('\n');
        
        for (const line of lines) {
          if (line.startsWith('data: ')) {
            const data = line.slice(6);
            if (data.trim() === '[DONE]') return;
            
            try {
              const parsed = JSON.parse(data);
              yield parsed;
            } catch (e) {
              // Skip invalid JSON
            }
          }
        }
      }
    } finally {
      reader.releaseLock();
    }
  }
  
  async getModels() {
    const url = `${this.config.baseURL}/v1/models`;
    const response = await this._makeRequest(url);
    const data = await response.json();
    return data.data || [];
  }
  
  async _makeRequest(url, options = {}) {
    const controller = new AbortController();
    const timeout = setTimeout(
      () => controller.abort(),
      this.config.timeout
    );
    
    try {
      const response = await fetch(url, {
        signal: controller.signal,
        ...options
      });
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      return response;
    } finally {
      clearTimeout(timeout);
    }
  }
}

// Export for different module systems
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { LocalLLMClient };
} else if (typeof define === 'function' && define.amd) {
  define(() => ({ LocalLLMClient }));
} else {
  window.LocalLLMClient = LocalLLMClient;
}
```

## Webhooks

Implementing webhook patterns for event-driven LLM integration, enabling asynchronous processing and real-time notifications.

### Implementing Webhooks

Designing webhook systems that notify external services of LLM events and responses.

**Webhook Architecture:**

```python
# webhook_manager.py
from typing import Dict, List, Optional, Callable, Any
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
import asyncio
import httpx
import hashlib
import hmac
import json
import logging
from enum import Enum
from fastapi import FastAPI, Request, HTTPException, BackgroundTasks
from pydantic import BaseModel, HttpUrl
import redis
from sqlalchemy import create_engine, Column, String, DateTime, Integer, Text, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

class WebhookEvent(Enum):
    GENERATION_STARTED = "generation.started"
    GENERATION_COMPLETED = "generation.completed"
    GENERATION_FAILED = "generation.failed"
    MODEL_LOADED = "model.loaded"
    MODEL_UNLOADED = "model.unloaded"
    SERVER_STARTED = "server.started"
    SERVER_SHUTDOWN = "server.shutdown"

@dataclass
class WebhookPayload:
    event: WebhookEvent
    timestamp: str
    data: Dict[str, Any]
    request_id: Optional[str] = None
    user_id: Optional[str] = None
    model: Optional[str] = None

class WebhookEndpoint(BaseModel):
    url: HttpUrl
    events: List[WebhookEvent]
    secret: Optional[str] = None
    headers: Dict[str, str] = {}
    active: bool = True
    retry_policy: Dict[str, Any] = {
        "max_retries": 3,
        "retry_delay": 5,
        "backoff_multiplier": 2
    }

# Database models
Base = declarative_base()

class WebhookDelivery(Base):
    __tablename__ = "webhook_deliveries"
    
    id = Column(String, primary_key=True)
    endpoint_url = Column(String, nullable=False)
    event = Column(String, nullable=False)
    payload = Column(Text, nullable=False)
    status = Column(String, nullable=False)  # pending, delivered, failed
    attempts = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    delivered_at = Column(DateTime)
    next_retry = Column(DateTime)
    error_message = Column(Text)

class WebhookManager:
    def __init__(
        self,
        database_url: str = "sqlite:///webhooks.db",
        redis_url: str = "redis://localhost:6379",
        max_workers: int = 10
    ):
        # Database setup
        self.engine = create_engine(database_url)
        Base.metadata.create_all(self.engine)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        # Redis for queuing
        self.redis = redis.from_url(redis_url)
        
        # HTTP client for webhook delivery
        self.http_client = httpx.AsyncClient(
            timeout=30.0,
            limits=httpx.Limits(max_connections=max_workers)
        )
        
        # Registered endpoints
        self.endpoints: Dict[str, WebhookEndpoint] = {}
        
        # Background task management
        self.worker_tasks = []
        self.running = False
        
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger("webhook_manager")
    
    def register_endpoint(self, endpoint_id: str, endpoint: WebhookEndpoint):
        """Register a webhook endpoint"""
        self.endpoints[endpoint_id] = endpoint
        self.logger.info(f"Registered webhook endpoint: {endpoint_id} -> {endpoint.url}")
    
    def unregister_endpoint(self, endpoint_id: str):
        """Unregister a webhook endpoint"""
        if endpoint_id in self.endpoints:
            del self.endpoints[endpoint_id]
            self.logger.info(f"Unregistered webhook endpoint: {endpoint_id}")
    
    async def emit_event(
        self,
        event: WebhookEvent,
        data: Dict[str, Any],
        request_id: Optional[str] = None,
        user_id: Optional[str] = None,
        model: Optional[str] = None
    ):
        """Emit an event to all registered webhooks"""
        payload = WebhookPayload(
            event=event,
            timestamp=datetime.utcnow().isoformat(),
            data=data,
            request_id=request_id,
            user_id=user_id,
            model=model
        )
        
        # Find endpoints that subscribe to this event
        for endpoint_id, endpoint in self.endpoints.items():
            if endpoint.active and event in endpoint.events:
                await self._queue_webhook_delivery(endpoint_id, endpoint, payload)
    
    async def _queue_webhook_delivery(
        self,
        endpoint_id: str,
        endpoint: WebhookEndpoint,
        payload: WebhookPayload
    ):
        """Queue webhook delivery for background processing"""
        delivery_id = hashlib.md5(
            f"{endpoint_id}-{payload.timestamp}-{payload.request_id}".encode()
        ).hexdigest()
        
        # Store in database
        with self.SessionLocal() as session:
            delivery = WebhookDelivery(
                id=delivery_id,
                endpoint_url=str(endpoint.url),
                event=payload.event.value,
                payload=json.dumps(asdict(payload)),
                status="pending",
                next_retry=datetime.utcnow()
            )
            session.add(delivery)
            session.commit()
        
        # Queue for immediate processing
        await self.redis.lpush(
            "webhook_queue",
            json.dumps({
                "delivery_id": delivery_id,
                "endpoint_id": endpoint_id
            })
        )
    
    async def _deliver_webhook(self, delivery_id: str, endpoint_id: str):
        """Deliver webhook to endpoint"""
        with self.SessionLocal() as session:
            delivery = session.query(WebhookDelivery).filter(
                WebhookDelivery.id == delivery_id
            ).first()
            
            if not delivery or delivery.status == "delivered":
                return
            
            endpoint = self.endpoints.get(endpoint_id)
            if not endpoint:
                self.logger.error(f"Endpoint {endpoint_id} not found")
                return
            
            try:
                # Prepare request
                payload = json.loads(delivery.payload)
                headers = {
                    "Content-Type": "application/json",
                    "User-Agent": "LocalLLM-Webhook/1.0",
                    **endpoint.headers
                }
                
                # Add signature if secret is configured
                if endpoint.secret:
                    signature = self._generate_signature(
                        delivery.payload,
                        endpoint.secret
                    )
                    headers["X-Webhook-Signature"] = signature
                
                # Make request
                response = await self.http_client.post(
                    str(endpoint.url),
                    json=payload,
                    headers=headers
                )
                
                response.raise_for_status()
                
                # Mark as delivered
                delivery.status = "delivered"
                delivery.delivered_at = datetime.utcnow()
                session.commit()
                
                self.logger.info(f"Webhook delivered: {delivery_id} -> {endpoint.url}")
                
            except Exception as e:
                delivery.attempts += 1
                delivery.error_message = str(e)
                
                max_retries = endpoint.retry_policy.get("max_retries", 3)
                
                if delivery.attempts >= max_retries:
                    delivery.status = "failed"
                    self.logger.error(
                        f"Webhook delivery failed permanently: {delivery_id} -> {endpoint.url}: {e}"
                    )
                else:
                    # Schedule retry
                    retry_delay = endpoint.retry_policy.get("retry_delay", 5)
                    backoff_multiplier = endpoint.retry_policy.get("backoff_multiplier", 2)
                    
                    delay = retry_delay * (backoff_multiplier ** (delivery.attempts - 1))
                    delivery.next_retry = datetime.utcnow() + timedelta(seconds=delay)
                    
                    self.logger.warning(
                        f"Webhook delivery failed, retry {delivery.attempts}/{max_retries} in {delay}s: {delivery_id}"
                    )
                
                session.commit()
    
    def _generate_signature(self, payload: str, secret: str) -> str:
        """Generate HMAC signature for webhook payload"""
        signature = hmac.new(
            secret.encode(),
            payload.encode(),
            hashlib.sha256
        ).hexdigest()
        return f"sha256={signature}"
    
    async def start_workers(self, num_workers: int = 5):
        """Start background workers for webhook delivery"""
        self.running = True
        
        for i in range(num_workers):
            task = asyncio.create_task(self._worker_loop(f"worker-{i}"))
            self.worker_tasks.append(task)
        
        self.logger.info(f"Started {num_workers} webhook workers")
    
    async def stop_workers(self):
        """Stop background workers"""
        self.running = False
        
        for task in self.worker_tasks:
            task.cancel()
        
        await asyncio.gather(*self.worker_tasks, return_exceptions=True)
        self.worker_tasks.clear()
        
        await self.http_client.aclose()
        self.logger.info("Stopped webhook workers")
    
    async def _worker_loop(self, worker_id: str):
        """Background worker loop for processing webhooks"""
        self.logger.info(f"Webhook worker {worker_id} started")
        
        while self.running:
            try:
                # Get next item from queue
                queue_item = await self.redis.brpop("webhook_queue", timeout=1)
                
                if queue_item:
                    _, item_data = queue_item
                    item = json.loads(item_data)
                    
                    delivery_id = item["delivery_id"]
                    endpoint_id = item["endpoint_id"]
                    
                    await self._deliver_webhook(delivery_id, endpoint_id)
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                self.logger.error(f"Worker {worker_id} error: {e}")
                await asyncio.sleep(1)
        
        self.logger.info(f"Webhook worker {worker_id} stopped")

# FastAPI integration
app = FastAPI(title="LLM Webhook Service")
webhook_manager = WebhookManager()

@app.on_event("startup")
async def startup():
    await webhook_manager.start_workers()

@app.on_event("shutdown")
async def shutdown():
    await webhook_manager.stop_workers()

@app.post("/webhooks/endpoints/{endpoint_id}")
async def register_webhook_endpoint(endpoint_id: str, endpoint: WebhookEndpoint):
    webhook_manager.register_endpoint(endpoint_id, endpoint)
    return {"message": f"Webhook endpoint {endpoint_id} registered"}

@app.delete("/webhooks/endpoints/{endpoint_id}")
async def unregister_webhook_endpoint(endpoint_id: str):
    webhook_manager.unregister_endpoint(endpoint_id)
    return {"message": f"Webhook endpoint {endpoint_id} unregistered"}

# Example webhook emission in LLM service
async def generate_text_with_webhooks(prompt: str, model: str, user_id: str):
    request_id = hashlib.md5(f"{prompt}-{datetime.utcnow()}".encode()).hexdigest()
    
    # Emit generation started event
    await webhook_manager.emit_event(
        WebhookEvent.GENERATION_STARTED,
        {
            "prompt": prompt,
            "model": model,
            "estimated_tokens": len(prompt.split()) * 2
        },
        request_id=request_id,
        user_id=user_id,
        model=model
    )
    
    try:
        # Simulate text generation
        result = await llm_engine.generate(
            prompt=prompt,
            model=model,
            max_tokens=500
        )
        
        # Emit completion event
        await webhook_manager.emit_event(
            WebhookEvent.GENERATION_COMPLETED,
            {
                "prompt": prompt,
                "response": result.text,
                "tokens_generated": result.token_count,
                "processing_time": result.duration
            },
            request_id=request_id,
            user_id=user_id,
            model=model
        )
        
        return result
        
    except Exception as e:
        # Emit failure event
        await webhook_manager.emit_event(
            WebhookEvent.GENERATION_FAILED,
            {
                "prompt": prompt,
                "error": str(e),
                "error_type": type(e).__name__
            },
            request_id=request_id,
            user_id=user_id,
            model=model
        )
        
        raise
```

### Callback Patterns

Implementing various callback patterns for asynchronous LLM operations and response handling.

**Async Callback System:**

```python
# callback_system.py
from typing import Callable, Dict, Any, Optional, List
from dataclasses import dataclass
from datetime import datetime
import asyncio
import uuid
from enum import Enum
import logging

class CallbackType(Enum):
    ON_START = "on_start"
    ON_PROGRESS = "on_progress"
    ON_COMPLETE = "on_complete"
    ON_ERROR = "on_error"
    ON_CANCEL = "on_cancel"

@dataclass
class CallbackContext:
    request_id: str
    user_id: Optional[str]
    model: str
    timestamp: datetime
    data: Dict[str, Any]

class AsyncCallbackManager:
    def __init__(self):
        self.callbacks: Dict[str, Dict[CallbackType, List[Callable]]] = {}
        self.global_callbacks: Dict[CallbackType, List[Callable]] = {
            callback_type: [] for callback_type in CallbackType
        }
        self.logger = logging.getLogger("callback_manager")
    
    def register_callback(
        self,
        callback_type: CallbackType,
        callback: Callable,
        request_id: Optional[str] = None
    ):
        """Register a callback for specific events"""
        if request_id:
            # Request-specific callback
            if request_id not in self.callbacks:
                self.callbacks[request_id] = {
                    callback_type: [] for callback_type in CallbackType
                }
            self.callbacks[request_id][callback_type].append(callback)
        else:
            # Global callback
            self.global_callbacks[callback_type].append(callback)
        
        self.logger.info(
            f"Registered {callback_type.value} callback for {'request ' + request_id if request_id else 'global'}"
        )
    
    async def emit_callback(
        self,
        callback_type: CallbackType,
        context: CallbackContext
    ):
        """Emit callbacks for a specific event"""
        callbacks_to_run = []
        
        # Add global callbacks
        callbacks_to_run.extend(self.global_callbacks[callback_type])
        
        # Add request-specific callbacks
        if context.request_id in self.callbacks:
            callbacks_to_run.extend(
                self.callbacks[context.request_id][callback_type]
            )
        
        # Execute all callbacks
        tasks = []
        for callback in callbacks_to_run:
            try:
                if asyncio.iscoroutinefunction(callback):
                    tasks.append(callback(context))
                else:
                    # Run sync callback in thread pool
                    tasks.append(
                        asyncio.get_event_loop().run_in_executor(
                            None, callback, context
                        )
                    )
            except Exception as e:
                self.logger.error(f"Error preparing callback: {e}")
        
        if tasks:
            try:
                await asyncio.gather(*tasks, return_exceptions=True)
            except Exception as e:
                self.logger.error(f"Error executing callbacks: {e}")
    
    def cleanup_callbacks(self, request_id: str):
        """Clean up callbacks for completed request"""
        if request_id in self.callbacks:
            del self.callbacks[request_id]
            self.logger.info(f"Cleaned up callbacks for request {request_id}")

# LLM Service with Callback Integration
class CallbackEnabledLLMService:
    def __init__(self, llm_engine, callback_manager: AsyncCallbackManager):
        self.llm_engine = llm_engine
        self.callback_manager = callback_manager
        self.active_requests: Dict[str, asyncio.Task] = {}
    
    async def generate_with_callbacks(
        self,
        prompt: str,
        model: str,
        user_id: Optional[str] = None,
        callbacks: Optional[Dict[CallbackType, Callable]] = None,
        **generation_kwargs
    ) -> Dict[str, Any]:
        """Generate text with callback support"""
        request_id = str(uuid.uuid4())
        
        # Register request-specific callbacks
        if callbacks:
            for callback_type, callback in callbacks.items():
                self.callback_manager.register_callback(
                    callback_type, callback, request_id
                )
        
        try:
            # Create task for cancellation support
            generation_task = asyncio.create_task(
                self._generate_with_callbacks_impl(
                    request_id, prompt, model, user_id, **generation_kwargs
                )
            )
            
            self.active_requests[request_id] = generation_task
            
            # Wait for completion
            result = await generation_task
            
            return result
            
        finally:
            # Cleanup
            if request_id in self.active_requests:
                del self.active_requests[request_id]
            
            self.callback_manager.cleanup_callbacks(request_id)
    
    async def _generate_with_callbacks_impl(
        self,
        request_id: str,
        prompt: str,
        model: str,
        user_id: Optional[str],
        **generation_kwargs
    ) -> Dict[str, Any]:
        """Implementation with callback emissions"""
        
        # Emit start callback
        await self.callback_manager.emit_callback(
            CallbackType.ON_START,
            CallbackContext(
                request_id=request_id,
                user_id=user_id,
                model=model,
                timestamp=datetime.utcnow(),
                data={
                    "prompt": prompt,
                    "generation_kwargs": generation_kwargs
                }
            )
        )
        
        try:
            # Stream generation with progress callbacks
            full_response = ""
            token_count = 0
            
            async for token in self.llm_engine.generate_stream(
                prompt=prompt,
                model=model,
                **generation_kwargs
            ):
                full_response += token.text
                token_count += 1
                
                # Emit progress callback every 10 tokens
                if token_count % 10 == 0:
                    await self.callback_manager.emit_callback(
                        CallbackType.ON_PROGRESS,
                        CallbackContext(
                            request_id=request_id,
                            user_id=user_id,
                            model=model,
                            timestamp=datetime.utcnow(),
                            data={
                                "current_response": full_response,
                                "tokens_generated": token_count,
                                "is_complete": token.is_final
                            }
                        )
                    )
                
                if token.is_final:
                    break
            
            # Emit completion callback
            result = {
                "response": full_response,
                "tokens_generated": token_count,
                "model": model,
                "request_id": request_id
            }
            
            await self.callback_manager.emit_callback(
                CallbackType.ON_COMPLETE,
                CallbackContext(
                    request_id=request_id,
                    user_id=user_id,
                    model=model,
                    timestamp=datetime.utcnow(),
                    data=result
                )
            )
            
            return result
            
        except asyncio.CancelledError:
            # Emit cancellation callback
            await self.callback_manager.emit_callback(
                CallbackType.ON_CANCEL,
                CallbackContext(
                    request_id=request_id,
                    user_id=user_id,
                    model=model,
                    timestamp=datetime.utcnow(),
                    data={"reason": "cancelled_by_client"}
                )
            )
            raise
            
        except Exception as e:
            # Emit error callback
            await self.callback_manager.emit_callback(
                CallbackType.ON_ERROR,
                CallbackContext(
                    request_id=request_id,
                    user_id=user_id,
                    model=model,
                    timestamp=datetime.utcnow(),
                    data={
                        "error": str(e),
                        "error_type": type(e).__name__
                    }
                )
            )
            raise
    
    async def cancel_request(self, request_id: str) -> bool:
        """Cancel an active request"""
        if request_id in self.active_requests:
            task = self.active_requests[request_id]
            task.cancel()
            return True
        return False

# Usage example
async def demo_callbacks():
    callback_manager = AsyncCallbackManager()
    llm_service = CallbackEnabledLLMService(llm_engine, callback_manager)
    
    # Define callback functions
    async def on_start(context: CallbackContext):
        print(f"Generation started for request {context.request_id}")
    
    async def on_progress(context: CallbackContext):
        tokens = context.data.get('tokens_generated', 0)
        print(f"Progress: {tokens} tokens generated")
    
    async def on_complete(context: CallbackContext):
        response = context.data.get('response', '')
        print(f"Generation completed: {len(response)} characters")
    
    async def on_error(context: CallbackContext):
        error = context.data.get('error', 'Unknown error')
        print(f"Generation failed: {error}")
    
    # Generate with callbacks
    result = await llm_service.generate_with_callbacks(
        prompt="Write a short story about AI",
        model="llama-2-7b-chat",
        user_id="user123",
        callbacks={
            CallbackType.ON_START: on_start,
            CallbackType.ON_PROGRESS: on_progress,
            CallbackType.ON_COMPLETE: on_complete,
            CallbackType.ON_ERROR: on_error
        },
        max_tokens=500,
        temperature=0.8
    )
    
    print(f"Final result: {result['response']}")

if __name__ == "__main__":
    asyncio.run(demo_callbacks())
```

## Streaming Integration

Real-time streaming capabilities for providing responsive user experiences with immediate token-by-token output from local LLMs.

### Server-Sent Events (SSE)

HTTP-based unidirectional streaming from server to client, ideal for simple token streaming without client interaction.

**SSE Implementation:**

```python
# sse_streaming.py
from fastapi import FastAPI, Request, Response
from fastapi.responses import StreamingResponse
from typing import Dict, Any, AsyncGenerator, Optional
import json
import asyncio
from datetime import datetime
import logging

class SSEStreamer:
    def __init__(self, llm_engine):
        self.llm_engine = llm_engine
        self.active_streams: Dict[str, bool] = {}
        self.logger = logging.getLogger("sse_streamer")
    
    async def stream_completion(
        self,
        request_id: str,
        prompt: str,
        model: str,
        temperature: float = 0.7,
        max_tokens: int = 500,
        **kwargs
    ) -> AsyncGenerator[str, None]:
        """Generate SSE stream for text completion"""
        
        self.active_streams[request_id] = True
        
        try:
            # Send initial event
            yield self._format_sse_event({
                "type": "start",
                "request_id": request_id,
                "model": model,
                "timestamp": datetime.utcnow().isoformat()
            })
            
            # Stream tokens
            full_response = ""
            token_count = 0
            
            async for token in self.llm_engine.generate_stream(
                prompt=prompt,
                model=model,
                temperature=temperature,
                max_tokens=max_tokens,
                **kwargs
            ):
                # Check if client disconnected
                if not self.active_streams.get(request_id, False):
                    self.logger.info(f"Stream {request_id} cancelled by client")
                    break
                
                full_response += token.text
                token_count += 1
                
                # Send token event
                yield self._format_sse_event({
                    "type": "token",
                    "content": token.text,
                    "token_count": token_count,
                    "is_complete": token.is_final
                })
                
                if token.is_final:
                    break
                
                # Small delay to prevent overwhelming clients
                await asyncio.sleep(0.01)
            
            # Send completion event
            yield self._format_sse_event({
                "type": "complete",
                "full_response": full_response,
                "total_tokens": token_count,
                "request_id": request_id
            })
            
        except asyncio.CancelledError:
            yield self._format_sse_event({
                "type": "cancelled",
                "request_id": request_id,
                "reason": "Client disconnected"
            })
        except Exception as e:
            yield self._format_sse_event({
                "type": "error",
                "error": str(e),
                "error_type": type(e).__name__,
                "request_id": request_id
            })
        finally:
            # Cleanup
            self.active_streams.pop(request_id, None)
    
    def _format_sse_event(self, data: Dict[str, Any], event_type: str = "message") -> str:
        """Format data as SSE event"""
        lines = []
        if event_type != "message":
            lines.append(f"event: {event_type}")
        lines.append(f"data: {json.dumps(data)}")
        lines.append("")  # Empty line required by SSE spec
        return "\n".join(lines) + "\n"
    
    def cancel_stream(self, request_id: str):
        """Cancel an active stream"""
        if request_id in self.active_streams:
            self.active_streams[request_id] = False

# FastAPI integration
app = FastAPI()
sse_streamer = SSEStreamer(llm_engine)

@app.post("/stream/completion/{request_id}")
async def stream_completion(
    request_id: str,
    request: Request,
    prompt: str,
    model: str = "llama-2-7b-chat",
    temperature: float = 0.7,
    max_tokens: int = 500
):
    # Check client disconnect
    async def check_disconnect():
        while sse_streamer.active_streams.get(request_id, False):
            if await request.is_disconnected():
                sse_streamer.cancel_stream(request_id)
                break
            await asyncio.sleep(1)
    
    # Start disconnect monitor
    asyncio.create_task(check_disconnect())
    
    return StreamingResponse(
        sse_streamer.stream_completion(
            request_id=request_id,
            prompt=prompt,
            model=model,
            temperature=temperature,
            max_tokens=max_tokens
        ),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Cache-Control"
        }
    )

@app.delete("/stream/{request_id}")
async def cancel_stream(request_id: str):
    sse_streamer.cancel_stream(request_id)
    return {"message": f"Stream {request_id} cancelled"}
```

**JavaScript SSE Client:**

```javascript
// sse_client.js
class SSELLMClient {
    constructor(baseURL) {
        this.baseURL = baseURL;
        this.activeStreams = new Map();
    }
    
    streamCompletion(options) {
        const {
            prompt,
            model = 'llama-2-7b-chat',
            temperature = 0.7,
            maxTokens = 500,
            onToken = () => {},
            onComplete = () => {},
            onError = () => {},
            onStart = () => {}
        } = options;
        
        const requestId = this.generateRequestId();
        const url = `${this.baseURL}/stream/completion/${requestId}?` +
                   new URLSearchParams({
                       prompt,
                       model,
                       temperature: temperature.toString(),
                       max_tokens: maxTokens.toString()
                   });
        
        const eventSource = new EventSource(url);
        
        eventSource.onmessage = (event) => {
            try {
                const data = JSON.parse(event.data);
                
                switch (data.type) {
                    case 'start':
                        onStart(data);
                        break;
                    case 'token':
                        onToken(data);
                        break;
                    case 'complete':
                        onComplete(data);
                        eventSource.close();
                        this.activeStreams.delete(requestId);
                        break;
                    case 'error':
                        onError(data);
                        eventSource.close();
                        this.activeStreams.delete(requestId);
                        break;
                    case 'cancelled':
                        eventSource.close();
                        this.activeStreams.delete(requestId);
                        break;
                }
            } catch (e) {
                onError({ error: 'Failed to parse server response', details: e.message });
            }
        };
        
        eventSource.onerror = (event) => {
            onError({ error: 'Connection error', event });
            eventSource.close();
            this.activeStreams.delete(requestId);
        };
        
        // Store for cancellation
        this.activeStreams.set(requestId, {
            eventSource,
            cancel: () => {
                eventSource.close();
                fetch(`${this.baseURL}/stream/${requestId}`, { method: 'DELETE' });
                this.activeStreams.delete(requestId);
            }
        });
        
        return {
            requestId,
            cancel: () => this.activeStreams.get(requestId)?.cancel()
        };
    }
    
    generateRequestId() {
        return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }
    
    cancelStream(requestId) {
        const stream = this.activeStreams.get(requestId);
        if (stream) {
            stream.cancel();
        }
    }
    
    cancelAllStreams() {
        for (const stream of this.activeStreams.values()) {
            stream.cancel();
        }
        this.activeStreams.clear();
    }
}

// Usage example
const client = new SSELLMClient('http://localhost:8000');

const stream = client.streamCompletion({
    prompt: 'Write a short poem about technology',
    model: 'llama-2-7b-chat',
    onStart: (data) => {
        console.log('Generation started:', data.model);
        document.getElementById('output').innerHTML = '';
    },
    onToken: (data) => {
        document.getElementById('output').innerHTML += data.content;
    },
    onComplete: (data) => {
        console.log('Generation completed:', data.total_tokens, 'tokens');
    },
    onError: (error) => {
        console.error('Stream error:', error);
    }
});

// Cancel after 10 seconds
setTimeout(() => {
    stream.cancel();
}, 10000);
```

### WebSocket Streaming

Full-duplex communication enabling real-time interaction, interruptions, and dynamic conversation flows.

**Advanced WebSocket Streaming:**

```python
# websocket_streaming.py
import asyncio
import websockets
import json
import uuid
from typing import Dict, Set, Optional, Any, List
from dataclasses import dataclass, asdict
from datetime import datetime
import logging

@dataclass
class StreamMessage:
    type: str
    data: Dict[str, Any]
    timestamp: str = None
    request_id: str = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.utcnow().isoformat()

class WebSocketLLMStreamer:
    def __init__(self, llm_engine):
        self.llm_engine = llm_engine
        self.connections: Dict[str, websockets.WebSocketServerProtocol] = {}
        self.user_sessions: Dict[str, Dict] = {}
        self.active_generations: Dict[str, asyncio.Task] = {}
        self.logger = logging.getLogger("websocket_streamer")
    
    async def handle_connection(self, websocket, path):
        """Handle new WebSocket connection"""
        connection_id = str(uuid.uuid4())
        self.connections[connection_id] = websocket
        
        try:
            self.logger.info(f"New WebSocket connection: {connection_id}")
            
            # Send connection confirmation
            await self.send_message(websocket, StreamMessage(
                type="connected",
                data={"connection_id": connection_id}
            ))
            
            # Handle messages
            async for message in websocket:
                await self.handle_message(connection_id, websocket, message)
                
        except websockets.exceptions.ConnectionClosed:
            self.logger.info(f"WebSocket connection closed: {connection_id}")
        except Exception as e:
            self.logger.error(f"WebSocket error: {e}")
        finally:
            await self.cleanup_connection(connection_id)
    
    async def handle_message(self, connection_id: str, websocket, raw_message: str):
        """Process incoming WebSocket message"""
        try:
            message = json.loads(raw_message)
            message_type = message.get("type")
            
            if message_type == "authenticate":
                await self.handle_authentication(connection_id, websocket, message)
            elif message_type == "generate":
                await self.handle_generation_request(connection_id, websocket, message)
            elif message_type == "interrupt":
                await self.handle_interruption(connection_id, websocket, message)
            elif message_type == "continue":
                await self.handle_continuation(connection_id, websocket, message)
            elif message_type == "clear_history":
                await self.handle_clear_history(connection_id, websocket, message)
            elif message_type == "get_status":
                await self.handle_status_request(connection_id, websocket, message)
            else:
                await self.send_error(websocket, f"Unknown message type: {message_type}")
                
        except json.JSONDecodeError:
            await self.send_error(websocket, "Invalid JSON message")
        except Exception as e:
            await self.send_error(websocket, f"Message handling error: {str(e)}")
    
    async def handle_authentication(self, connection_id: str, websocket, message: Dict):
        """Handle user authentication"""
        user_id = message.get("user_id")
        if not user_id:
            await self.send_error(websocket, "user_id required for authentication")
            return
        
        # Initialize user session
        self.user_sessions[connection_id] = {
            "user_id": user_id,
            "conversation_history": [],
            "preferences": message.get("preferences", {}),
            "authenticated_at": datetime.utcnow()
        }
        
        await self.send_message(websocket, StreamMessage(
            type="authenticated",
            data={
                "user_id": user_id,
                "connection_id": connection_id
            }
        ))
    
    async def handle_generation_request(self, connection_id: str, websocket, message: Dict):
        """Handle text generation request"""
        if connection_id not in self.user_sessions:
            await self.send_error(websocket, "Authentication required")
            return
        
        request_id = str(uuid.uuid4())
        prompt = message.get("prompt", "")
        model = message.get("model", "llama-2-7b-chat")
        temperature = message.get("temperature", 0.7)
        max_tokens = message.get("max_tokens", 500)
        
        # Cancel any existing generation for this connection
        if connection_id in self.active_generations:
            self.active_generations[connection_id].cancel()
        
        # Start new generation task
        generation_task = asyncio.create_task(
            self.stream_generation(
                connection_id, websocket, request_id,
                prompt, model, temperature, max_tokens
            )
        )
        
        self.active_generations[connection_id] = generation_task
        
        await self.send_message(websocket, StreamMessage(
            type="generation_started",
            data={
                "request_id": request_id,
                "model": model
            },
            request_id=request_id
        ))
    
    async def stream_generation(
        self,
        connection_id: str,
        websocket,
        request_id: str,
        prompt: str,
        model: str,
        temperature: float,
        max_tokens: int
    ):
        """Stream text generation to WebSocket"""
        session = self.user_sessions[connection_id]
        
        try:
            # Add user message to history
            session["conversation_history"].append({
                "role": "user",
                "content": prompt,
                "timestamp": datetime.utcnow().isoformat()
            })
            
            # Stream generation
            full_response = ""
            token_count = 0
            start_time = datetime.utcnow()
            
            async for token in self.llm_engine.generate_stream(
                prompt=prompt,
                model=model,
                temperature=temperature,
                max_tokens=max_tokens,
                conversation_history=session["conversation_history"]
            ):
                if websocket.closed:
                    break
                
                full_response += token.text
                token_count += 1
                
                # Send token
                await self.send_message(websocket, StreamMessage(
                    type="token",
                    data={
                        "content": token.text,
                        "token_count": token_count,
                        "is_complete": token.is_final
                    },
                    request_id=request_id
                ))
                
                if token.is_final:
                    break
            
            # Add response to history
            session["conversation_history"].append({
                "role": "assistant",
                "content": full_response,
                "timestamp": datetime.utcnow().isoformat(),
                "model": model,
                "token_count": token_count
            })
            
            # Send completion
            processing_time = (datetime.utcnow() - start_time).total_seconds()
            
            await self.send_message(websocket, StreamMessage(
                type="generation_complete",
                data={
                    "full_response": full_response,
                    "total_tokens": token_count,
                    "processing_time": processing_time,
                    "model": model
                },
                request_id=request_id
            ))
            
        except asyncio.CancelledError:
            await self.send_message(websocket, StreamMessage(
                type="generation_cancelled",
                data={"reason": "Cancelled by user or new request"},
                request_id=request_id
            ))
        except Exception as e:
            await self.send_message(websocket, StreamMessage(
                type="generation_error",
                data={
                    "error": str(e),
                    "error_type": type(e).__name__
                },
                request_id=request_id
            ))
        finally:
            if connection_id in self.active_generations:
                del self.active_generations[connection_id]
    
    async def handle_interruption(self, connection_id: str, websocket, message: Dict):
        """Handle generation interruption"""
        if connection_id in self.active_generations:
            self.active_generations[connection_id].cancel()
            
            await self.send_message(websocket, StreamMessage(
                type="generation_interrupted",
                data={"reason": "Interrupted by user"}
            ))
    
    async def send_message(self, websocket, message: StreamMessage):
        """Send message to WebSocket"""
        try:
            await websocket.send(json.dumps(asdict(message)))
        except websockets.exceptions.ConnectionClosed:
            pass
    
    async def send_error(self, websocket, error_message: str):
        """Send error message to WebSocket"""
        await self.send_message(websocket, StreamMessage(
            type="error",
            data={"message": error_message}
        ))
    
    async def cleanup_connection(self, connection_id: str):
        """Clean up connection resources"""
        # Cancel active generation
        if connection_id in self.active_generations:
            self.active_generations[connection_id].cancel()
            del self.active_generations[connection_id]
        
        # Remove from connections and sessions
        self.connections.pop(connection_id, None)
        self.user_sessions.pop(connection_id, None)
        
        self.logger.info(f"Cleaned up connection: {connection_id}")

# Start WebSocket server
async def main():
    streamer = WebSocketLLMStreamer(llm_engine)
    
    start_server = websockets.serve(
        streamer.handle_connection,
        "localhost",
        8765,
        ping_interval=20,
        ping_timeout=10
    )
    
    print("WebSocket LLM server starting on ws://localhost:8765")
    await start_server
    await asyncio.Future()  # Run forever

if __name__ == "__main__":
    asyncio.run(main())
```

### gRPC Streaming

High-performance bidirectional streaming with type safety and advanced flow control.

**gRPC Streaming Service:**

```protobuf
// llm_streaming.proto
syntax = "proto3";

package llm.streaming.v1;

service LLMStreamingService {
  // Unidirectional streaming from server
  rpc StreamGeneration(StreamGenerationRequest) returns (stream StreamGenerationResponse);
  
  // Bidirectional streaming for interactive conversations
  rpc InteractiveChat(stream ChatMessage) returns (stream ChatResponse);
  
  // Client streaming for batch processing
  rpc BatchGenerate(stream GenerationRequest) returns (BatchGenerationResponse);
}

message StreamGenerationRequest {
  string prompt = 1;
  string model = 2;
  float temperature = 3;
  int32 max_tokens = 4;
  repeated string stop_sequences = 5;
  map<string, string> parameters = 6;
}

message StreamGenerationResponse {
  oneof response_type {
    TokenChunk token = 1;
    GenerationComplete complete = 2;
    GenerationError error = 3;
    GenerationStatus status = 4;
  }
}

message TokenChunk {
  string content = 1;
  int32 token_index = 2;
  bool is_final = 3;
  float confidence = 4;
}

message GenerationComplete {
  string full_response = 1;
  int32 total_tokens = 2;
  float processing_time = 3;
  GenerationMetrics metrics = 4;
}

message ChatMessage {
  oneof message_type {
    UserMessage user_message = 1;
    SystemCommand system_command = 2;
    InterruptRequest interrupt = 3;
  }
}

message UserMessage {
  string content = 1;
  string role = 2;
  string user_id = 3;
}

message ChatResponse {
  oneof response_type {
    AssistantMessage assistant_message = 1;
    SystemStatus system_status = 2;
    StreamError error = 3;
  }
}
```

**gRPC Server Implementation:**

```python
# grpc_streaming_server.py
import grpc
from concurrent import futures
import asyncio
import logging
from typing import AsyncGenerator, Dict, Any
import llm_streaming_pb2_grpc
import llm_streaming_pb2

class LLMStreamingServicer(llm_streaming_pb2_grpc.LLMStreamingServiceServicer):
    def __init__(self, llm_engine):
        self.llm_engine = llm_engine
        self.logger = logging.getLogger("grpc_streaming")
    
    async def StreamGeneration(
        self,
        request: llm_streaming_pb2.StreamGenerationRequest,
        context: grpc.aio.ServicerContext
    ) -> AsyncGenerator[llm_streaming_pb2.StreamGenerationResponse, None]:
        """Unidirectional streaming generation"""
        
        try:
            # Send status update
            yield llm_streaming_pb2.StreamGenerationResponse(
                status=llm_streaming_pb2.GenerationStatus(
                    stage="starting",
                    message=f"Starting generation with model {request.model}"
                )
            )
            
            # Stream tokens
            total_tokens = 0
            start_time = asyncio.get_event_loop().time()
            
            async for token in self.llm_engine.generate_stream(
                prompt=request.prompt,
                model=request.model,
                temperature=request.temperature,
                max_tokens=request.max_tokens,
                stop_sequences=list(request.stop_sequences)
            ):
                # Check if client cancelled
                if context.cancelled():
                    break
                
                total_tokens += 1
                
                # Send token
                yield llm_streaming_pb2.StreamGenerationResponse(
                    token=llm_streaming_pb2.TokenChunk(
                        content=token.text,
                        token_index=total_tokens,
                        is_final=token.is_final,
                        confidence=getattr(token, 'confidence', 1.0)
                    )
                )\n                if token.is_final:\n                    break\n            \n            # Send completion\n            processing_time = asyncio.get_event_loop().time() - start_time\n            \n            yield llm_streaming_pb2.StreamGenerationResponse(\n                complete=llm_streaming_pb2.GenerationComplete(\n                    full_response=full_response,\n                    total_tokens=total_tokens,\n                    processing_time=processing_time,\n                    metrics=llm_streaming_pb2.GenerationMetrics(\n                        tokens_per_second=total_tokens / processing_time if processing_time > 0 else 0\n                    )\n                )\n            )\n            \n        except Exception as e:\n            self.logger.error(f\"Generation error: {e}\")\n            yield llm_streaming_pb2.StreamGenerationResponse(\n                error=llm_streaming_pb2.GenerationError(\n                    code=\"GENERATION_FAILED\",\n                    message=str(e)\n                )\n            )\n    \n    async def InteractiveChat(\n        self,\n        request_iterator: AsyncGenerator[llm_streaming_pb2.ChatMessage, None],\n        context: grpc.aio.ServicerContext\n    ) -> AsyncGenerator[llm_streaming_pb2.ChatResponse, None]:\n        \"\"\"Bidirectional streaming chat\"\"\"\n        \n        conversation_history = []\n        current_generation = None\n        \n        try:\n            async for message in request_iterator:\n                if message.HasField('user_message'):\n                    user_msg = message.user_message\n                    \n                    # Cancel current generation if any\n                    if current_generation:\n                        current_generation.cancel()\n                    \n                    # Add to history\n                    conversation_history.append({\n                        \"role\": user_msg.role or \"user\",\n                        \"content\": user_msg.content\n                    })\n                    \n                    # Start new generation\n                    current_generation = asyncio.create_task(\n                        self._generate_chat_response(\n                            user_msg.content,\n                            conversation_history,\n                            context\n                        )\n                    )\n                    \n                    # Stream the response\n                    try:\n                        async for response_chunk in current_generation:\n                            yield response_chunk\n                    except asyncio.CancelledError:\n                        pass\n                \n                elif message.HasField('interrupt'):\n                    if current_generation:\n                        current_generation.cancel()\n                        yield llm_streaming_pb2.ChatResponse(\n                            system_status=llm_streaming_pb2.SystemStatus(\n                                status=\"interrupted\",\n                                message=\"Generation interrupted by user\"\n                            )\n                        )\n        \n        except Exception as e:\n            yield llm_streaming_pb2.ChatResponse(\n                error=llm_streaming_pb2.StreamError(\n                    code=\"CHAT_ERROR\",\n                    message=str(e)\n                )\n            )\n    \n    async def _generate_chat_response(\n        self,\n        prompt: str,\n        conversation_history: list,\n        context: grpc.aio.ServicerContext\n    ) -> AsyncGenerator[llm_streaming_pb2.ChatResponse, None]:\n        \"\"\"Generate streaming chat response\"\"\"\n        \n        full_response = \"\"\n        \n        async for token in self.llm_engine.generate_stream(\n            prompt=prompt,\n            conversation_history=conversation_history\n        ):\n            if context.cancelled():\n                break\n            \n            full_response += token.text\n            \n            yield llm_streaming_pb2.ChatResponse(\n                assistant_message=llm_streaming_pb2.AssistantMessage(\n                    content=token.text,\n                    is_complete=token.is_final\n                )\n            )\n            \n            if token.is_final:\n                break\n\n# Server setup\nasync def serve():\n    server = grpc.aio.server(futures.ThreadPoolExecutor(max_workers=10))\n    \n    servicer = LLMStreamingServicer(llm_engine)\n    llm_streaming_pb2_grpc.add_LLMStreamingServiceServicer_to_server(\n        servicer, server\n    )\n    \n    listen_addr = '[::]:50051'\n    server.add_insecure_port(listen_addr)\n    \n    await server.start()\n    print(f\"gRPC streaming server started on {listen_addr}\")\n    \n    await server.wait_for_termination()\n\nif __name__ == '__main__':\n    asyncio.run(serve())\n```

## Error Handling

Comprehensive error handling strategies for robust LLM integration, covering both client-side and server-side error scenarios.

### API Error Codes

Standardized error response format and HTTP status codes for consistent error communication.

**Error Response Schema:**

```python
# error_handling.py
from typing import Optional, Dict, Any, List
from dataclasses import dataclass
from enum import Enum
import json
import traceback
from datetime import datetime
import logging

class ErrorCode(Enum):
    # Client errors (4xx)
    INVALID_REQUEST = "INVALID_REQUEST"
    UNAUTHORIZED = "UNAUTHORIZED"
    FORBIDDEN = "FORBIDDEN"
    NOT_FOUND = "NOT_FOUND"
    METHOD_NOT_ALLOWED = "METHOD_NOT_ALLOWED"
    REQUEST_TIMEOUT = "REQUEST_TIMEOUT"
    PAYLOAD_TOO_LARGE = "PAYLOAD_TOO_LARGE"
    RATE_LIMITED = "RATE_LIMITED"
    
    # Server errors (5xx)
    INTERNAL_ERROR = "INTERNAL_ERROR"
    MODEL_NOT_AVAILABLE = "MODEL_NOT_AVAILABLE"
    MODEL_LOADING_ERROR = "MODEL_LOADING_ERROR"
    GENERATION_FAILED = "GENERATION_FAILED"
    SERVICE_UNAVAILABLE = "SERVICE_UNAVAILABLE"
    GATEWAY_TIMEOUT = "GATEWAY_TIMEOUT"
    
    # LLM-specific errors
    CONTEXT_LENGTH_EXCEEDED = "CONTEXT_LENGTH_EXCEEDED"
    INVALID_PARAMETERS = "INVALID_PARAMETERS"
    CONTENT_FILTERED = "CONTENT_FILTERED"
    MODEL_OVERLOADED = "MODEL_OVERLOADED"

@dataclass
class ErrorDetail:
    field: str
    code: str
    message: str
    value: Optional[Any] = None

@dataclass
class LLMError:
    code: ErrorCode
    message: str
    details: Optional[List[ErrorDetail]] = None
    timestamp: Optional[str] = None
    request_id: Optional[str] = None
    trace_id: Optional[str] = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.utcnow().isoformat()
    
    def to_dict(self) -> Dict[str, Any]:
        result = {
            "error": {
                "code": self.code.value,
                "message": self.message,
                "timestamp": self.timestamp
            }
        }
        
        if self.details:
            result["error"]["details"] = [
                {
                    "field": detail.field,
                    "code": detail.code,
                    "message": detail.message,
                    "value": detail.value
                }
                for detail in self.details
            ]
        
        if self.request_id:
            result["error"]["request_id"] = self.request_id
        
        if self.trace_id:
            result["error"]["trace_id"] = self.trace_id
        
        return result
    
    def to_json(self) -> str:
        return json.dumps(self.to_dict(), indent=2)

class LLMException(Exception):
    def __init__(
        self,
        error: LLMError,
        status_code: int = 500,
        original_exception: Optional[Exception] = None
    ):
        self.error = error
        self.status_code = status_code
        self.original_exception = original_exception
        super().__init__(error.message)

# HTTP status code mapping
ERROR_STATUS_MAPPING = {
    ErrorCode.INVALID_REQUEST: 400,
    ErrorCode.UNAUTHORIZED: 401,
    ErrorCode.FORBIDDEN: 403,
    ErrorCode.NOT_FOUND: 404,
    ErrorCode.METHOD_NOT_ALLOWED: 405,
    ErrorCode.REQUEST_TIMEOUT: 408,
    ErrorCode.PAYLOAD_TOO_LARGE: 413,
    ErrorCode.RATE_LIMITED: 429,
    ErrorCode.INTERNAL_ERROR: 500,
    ErrorCode.MODEL_NOT_AVAILABLE: 503,
    ErrorCode.MODEL_LOADING_ERROR: 503,
    ErrorCode.GENERATION_FAILED: 500,
    ErrorCode.SERVICE_UNAVAILABLE: 503,
    ErrorCode.GATEWAY_TIMEOUT: 504,
    ErrorCode.CONTEXT_LENGTH_EXCEEDED: 400,
    ErrorCode.INVALID_PARAMETERS: 400,
    ErrorCode.CONTENT_FILTERED: 400,
    ErrorCode.MODEL_OVERLOADED: 503
}

class ErrorHandler:
    def __init__(self, logger: Optional[logging.Logger] = None):
        self.logger = logger or logging.getLogger(__name__)
    
    def create_error(
        self,
        code: ErrorCode,
        message: str,
        details: Optional[List[ErrorDetail]] = None,
        request_id: Optional[str] = None,
        trace_id: Optional[str] = None
    ) -> LLMError:
        return LLMError(
            code=code,
            message=message,
            details=details,
            request_id=request_id,
            trace_id=trace_id
        )
    
    def create_validation_error(
        self,
        validation_errors: List[ErrorDetail],
        request_id: Optional[str] = None
    ) -> LLMError:
        return self.create_error(
            code=ErrorCode.INVALID_REQUEST,
            message="Request validation failed",
            details=validation_errors,
            request_id=request_id
        )
    
    def handle_exception(
        self,
        exception: Exception,
        request_id: Optional[str] = None,
        context: Optional[Dict[str, Any]] = None
    ) -> LLMError:
        \"\"\"Convert various exceptions to standardized LLMError\"\"\"
        
        context = context or {}
        
        # Log the exception
        self.logger.error(
            f"Exception occurred: {type(exception).__name__}: {str(exception)}",
            extra={
                "request_id": request_id,
                "context": context,
                "traceback": traceback.format_exc()
            }
        )
        
        # Map known exceptions
        if isinstance(exception, ValueError):
            return self.create_error(
                ErrorCode.INVALID_PARAMETERS,
                f"Invalid parameter value: {str(exception)}",
                request_id=request_id
            )
        
        elif isinstance(exception, TimeoutError):
            return self.create_error(
                ErrorCode.GATEWAY_TIMEOUT,
                "Request timed out",
                request_id=request_id
            )
        
        elif isinstance(exception, MemoryError):
            return self.create_error(
                ErrorCode.MODEL_OVERLOADED,
                "Insufficient memory to process request",
                request_id=request_id
            )
        
        elif isinstance(exception, FileNotFoundError):
            return self.create_error(
                ErrorCode.MODEL_NOT_AVAILABLE,
                "Required model files not found",
                request_id=request_id
            )
        
        else:
            # Generic internal error
            return self.create_error(
                ErrorCode.INTERNAL_ERROR,
                "An internal error occurred",
                request_id=request_id
            )

# FastAPI error handling integration
from fastapi import FastAPI, HTTPException, Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

def setup_error_handlers(app: FastAPI, error_handler: ErrorHandler):
    @app.exception_handler(LLMException)
    async def llm_exception_handler(request: Request, exc: LLMException):
        return JSONResponse(
            status_code=exc.status_code,
            content=exc.error.to_dict()
        )
    
    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        details = []
        for error in exc.errors():
            details.append(ErrorDetail(
                field=".".join(str(x) for x in error["loc"]),
                code=error["type"],
                message=error["msg"],
                value=error.get("input")
            ))
        
        llm_error = error_handler.create_validation_error(details)
        return JSONResponse(
            status_code=400,
            content=llm_error.to_dict()
        )
    
    @app.exception_handler(StarletteHTTPException)
    async def http_exception_handler(request: Request, exc: StarletteHTTPException):
        # Map HTTP exceptions to LLM errors
        if exc.status_code == 404:
            error = error_handler.create_error(
                ErrorCode.NOT_FOUND,
                exc.detail or "Resource not found"
            )
        elif exc.status_code == 401:
            error = error_handler.create_error(
                ErrorCode.UNAUTHORIZED,
                exc.detail or "Authentication required"
            )
        else:
            error = error_handler.create_error(
                ErrorCode.INTERNAL_ERROR,
                exc.detail or "HTTP error occurred"
            )
        
        return JSONResponse(
            status_code=exc.status_code,
            content=error.to_dict()
        )
    
    @app.exception_handler(Exception)
    async def general_exception_handler(request: Request, exc: Exception):
        request_id = getattr(request.state, 'request_id', None)
        error = error_handler.handle_exception(exc, request_id)
        
        status_code = ERROR_STATUS_MAPPING.get(error.code, 500)
        
        return JSONResponse(
            status_code=status_code,
            content=error.to_dict()
        )
```

### Retry Logic

Intelligent retry mechanisms with exponential backoff and failure classification.

**Retry Strategy Implementation:**

```python
# retry_logic.py
import asyncio
import random
import time
from typing import Callable, Any, Optional, List, Type, Union
from dataclasses import dataclass
from enum import Enum
import logging

class RetryPolicy(Enum):
    EXPONENTIAL_BACKOFF = "exponential_backoff"
    LINEAR_BACKOFF = "linear_backoff"
    FIXED_DELAY = "fixed_delay"
    IMMEDIATE = "immediate"

@dataclass
class RetryConfig:
    max_attempts: int = 3
    initial_delay: float = 1.0
    max_delay: float = 60.0
    backoff_multiplier: float = 2.0
    jitter: bool = True
    policy: RetryPolicy = RetryPolicy.EXPONENTIAL_BACKOFF
    retryable_exceptions: List[Type[Exception]] = None
    non_retryable_exceptions: List[Type[Exception]] = None

class RetryableError(Exception):
    \"\"\"Indicates an operation should be retried\"\"\"
    pass

class NonRetryableError(Exception):
    \"\"\"Indicates an operation should not be retried\"\"\"
    pass

class RetryHandler:
    def __init__(self, config: RetryConfig = None):
        self.config = config or RetryConfig()
        self.logger = logging.getLogger("retry_handler")
        
        # Default retryable exceptions
        if self.config.retryable_exceptions is None:
            self.config.retryable_exceptions = [
                ConnectionError,
                TimeoutError,
                RetryableError,
                # Add HTTP exceptions that are typically retryable
            ]
        
        # Default non-retryable exceptions
        if self.config.non_retryable_exceptions is None:
            self.config.non_retryable_exceptions = [
                ValueError,
                TypeError,
                NonRetryableError,
                # Add authentication and validation errors
            ]
    
    def is_retryable(self, exception: Exception) -> bool:
        \"\"\"Determine if an exception is retryable\"\"\"
        
        # Check non-retryable first
        for exc_type in self.config.non_retryable_exceptions:
            if isinstance(exception, exc_type):
                return False
        
        # Check retryable
        for exc_type in self.config.retryable_exceptions:
            if isinstance(exception, exc_type):
                return True
        
        # Default: don't retry unknown exceptions
        return False
    
    def calculate_delay(self, attempt: int) -> float:
        \"\"\"Calculate delay for given attempt number\"\"\"
        
        if self.config.policy == RetryPolicy.EXPONENTIAL_BACKOFF:
            delay = self.config.initial_delay * (self.config.backoff_multiplier ** (attempt - 1))
        elif self.config.policy == RetryPolicy.LINEAR_BACKOFF:
            delay = self.config.initial_delay * attempt
        elif self.config.policy == RetryPolicy.FIXED_DELAY:
            delay = self.config.initial_delay
        else:  # IMMEDIATE
            delay = 0
        
        # Apply maximum delay limit
        delay = min(delay, self.config.max_delay)
        
        # Add jitter to prevent thundering herd
        if self.config.jitter and delay > 0:
            jitter = delay * 0.1 * random.random()
            delay += jitter
        
        return delay
    
    async def retry_async(
        self,
        func: Callable,
        *args,
        **kwargs
    ) -> Any:
        \"\"\"Retry async function with configured strategy\"\"\"
        
        last_exception = None
        
        for attempt in range(1, self.config.max_attempts + 1):
            try:
                self.logger.debug(f"Attempt {attempt}/{self.config.max_attempts}")
                result = await func(*args, **kwargs)
                
                if attempt > 1:
                    self.logger.info(f"Operation succeeded on attempt {attempt}")
                
                return result
                
            except Exception as e:
                last_exception = e
                
                if not self.is_retryable(e):
                    self.logger.info(f"Non-retryable exception: {type(e).__name__}: {e}")
                    raise
                
                if attempt >= self.config.max_attempts:
                    self.logger.error(
                        f"Operation failed after {self.config.max_attempts} attempts: {type(e).__name__}: {e}"
                    )
                    break
                
                delay = self.calculate_delay(attempt)
                self.logger.warning(
                    f"Attempt {attempt} failed: {type(e).__name__}: {e}. Retrying in {delay:.2f}s"
                )
                
                await asyncio.sleep(delay)
        
        # All attempts exhausted
        raise last_exception
    
    def retry_sync(
        self,
        func: Callable,
        *args,
        **kwargs
    ) -> Any:
        \"\"\"Retry sync function with configured strategy\"\"\"
        
        last_exception = None
        
        for attempt in range(1, self.config.max_attempts + 1):
            try:
                self.logger.debug(f"Attempt {attempt}/{self.config.max_attempts}")
                result = func(*args, **kwargs)
                
                if attempt > 1:
                    self.logger.info(f"Operation succeeded on attempt {attempt}")
                
                return result
                
            except Exception as e:
                last_exception = e
                
                if not self.is_retryable(e):
                    self.logger.info(f"Non-retryable exception: {type(e).__name__}: {e}")
                    raise
                
                if attempt >= self.config.max_attempts:
                    self.logger.error(
                        f"Operation failed after {self.config.max_attempts} attempts: {type(e).__name__}: {e}"
                    )
                    break
                
                delay = self.calculate_delay(attempt)
                self.logger.warning(
                    f"Attempt {attempt} failed: {type(e).__name__}: {e}. Retrying in {delay:.2f}s"
                )
                
                time.sleep(delay)
        
        # All attempts exhausted
        raise last_exception

# Decorator for easy retry functionality
def retry(config: RetryConfig = None):
    \"\"\"Decorator to add retry functionality to functions\"\"\"
    retry_handler = RetryHandler(config)
    
    def decorator(func):
        if asyncio.iscoroutinefunction(func):
            async def async_wrapper(*args, **kwargs):
                return await retry_handler.retry_async(func, *args, **kwargs)
            return async_wrapper
        else:
            def sync_wrapper(*args, **kwargs):
                return retry_handler.retry_sync(func, *args, **kwargs)
            return sync_wrapper
    
    return decorator

# LLM-specific retry implementation
class LLMRetryHandler(RetryHandler):
    def __init__(self):
        config = RetryConfig(
            max_attempts=3,
            initial_delay=2.0,
            max_delay=30.0,
            backoff_multiplier=2.0,
            retryable_exceptions=[
                ConnectionError,
                TimeoutError,
                # Add LLM-specific retryable errors
                Exception  # Be more specific in production
            ],
            non_retryable_exceptions=[
                ValueError,
                TypeError,
                # Add LLM-specific non-retryable errors
            ]
        )
        super().__init__(config)
    
    async def generate_with_retry(
        self,
        llm_engine,
        prompt: str,
        model: str,
        **kwargs
    ) -> Any:
        \"\"\"Generate text with retry logic\"\"\"
        
        return await self.retry_async(
            llm_engine.generate,
            prompt=prompt,
            model=model,
            **kwargs
        )

# Usage examples
@retry(RetryConfig(max_attempts=5, initial_delay=1.0))
async def api_call_with_retry(url: str, data: dict):
    \"\"\"Example API call with automatic retry\"\"\"
    async with httpx.AsyncClient() as client:
        response = await client.post(url, json=data, timeout=30)
        response.raise_for_status()
        return response.json()

# Context manager for retry
class RetryContext:
    def __init__(self, config: RetryConfig = None):
        self.retry_handler = RetryHandler(config)
        self.attempt = 0
    
    async def __aenter__(self):
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if exc_type and self.retry_handler.is_retryable(exc_val):
            self.attempt += 1
            if self.attempt < self.retry_handler.config.max_attempts:
                delay = self.retry_handler.calculate_delay(self.attempt)
                await asyncio.sleep(delay)
                return True  # Suppress exception to retry
        return False  # Don't suppress exception

# Usage with context manager
async def example_with_context():
    config = RetryConfig(max_attempts=3)
    
    for _ in range(config.max_attempts):
        async with RetryContext(config) as retry_ctx:
            # Your operation here
            result = await some_operation()
            return result  # Success, exit loop
    
    raise Exception("All retry attempts exhausted")
```

### Fallback Strategies

Graceful degradation mechanisms when primary LLM services fail or become unavailable.

**Fallback Implementation:**

```python
# fallback_strategies.py
from typing import List, Dict, Any, Optional, Callable, Union
from dataclasses import dataclass
from enum import Enum
import asyncio
import logging
from abc import ABC, abstractmethod

class FallbackTrigger(Enum):
    ERROR = "error"
    TIMEOUT = "timeout"
    OVERLOAD = "overload"
    MAINTENANCE = "maintenance"
    QUALITY_THRESHOLD = "quality_threshold"

@dataclass
class FallbackResult:
    content: str
    source: str
    is_fallback: bool
    trigger_reason: Optional[FallbackTrigger] = None
    quality_score: Optional[float] = None
    processing_time: Optional[float] = None

class LLMProvider(ABC):
    @abstractmethod
    async def generate(
        self,
        prompt: str,
        model: str,
        **kwargs
    ) -> FallbackResult:
        pass
    
    @abstractmethod
    async def health_check(self) -> bool:
        pass
    
    @abstractmethod
    def get_priority(self) -> int:
        pass

class PrimaryLLMProvider(LLMProvider):
    def __init__(self, llm_engine, name: str = "primary"):
        self.llm_engine = llm_engine
        self.name = name
        self.logger = logging.getLogger(f"provider_{name}")
    
    async def generate(
        self,
        prompt: str,
        model: str,
        **kwargs
    ) -> FallbackResult:
        try:
            start_time = asyncio.get_event_loop().time()
            
            result = await self.llm_engine.generate(
                prompt=prompt,
                model=model,
                **kwargs
            )
            
            processing_time = asyncio.get_event_loop().time() - start_time
            
            return FallbackResult(
                content=result.text,
                source=self.name,
                is_fallback=False,
                processing_time=processing_time,
                quality_score=getattr(result, 'quality_score', None)
            )
            
        except Exception as e:
            self.logger.error(f"Primary provider failed: {e}")
            raise
    
    async def health_check(self) -> bool:
        try:
            # Simple health check
            result = await self.llm_engine.generate(
                prompt="Test",
                model="default",
                max_tokens=5,
                timeout=5
            )
            return True
        except Exception:
            return False
    
    def get_priority(self) -> int:
        return 1  # Highest priority

class CacheLLMProvider(LLMProvider):
    def __init__(self, cache_store: dict, name: str = "cache"):
        self.cache_store = cache_store
        self.name = name
        self.logger = logging.getLogger(f"provider_{name}")
    
    async def generate(
        self,
        prompt: str,
        model: str,
        **kwargs
    ) -> FallbackResult:
        # Create cache key
        cache_key = self._create_cache_key(prompt, model, kwargs)
        
        if cache_key in self.cache_store:
            cached_result = self.cache_store[cache_key]
            
            self.logger.info(f"Cache hit for prompt: {prompt[:50]}...")
            
            return FallbackResult(
                content=cached_result["content"],
                source=f"{self.name}_{cached_result.get('original_source', 'unknown')}",
                is_fallback=True,
                trigger_reason=FallbackTrigger.ERROR,
                quality_score=cached_result.get("quality_score")
            )
        else:
            raise Exception("No cached response available")
    
    def _create_cache_key(self, prompt: str, model: str, kwargs: dict) -> str:
        import hashlib
        key_data = f"{prompt}_{model}_{str(sorted(kwargs.items()))}"
        return hashlib.md5(key_data.encode()).hexdigest()
    
    async def health_check(self) -> bool:
        return len(self.cache_store) > 0
    
    def get_priority(self) -> int:
        return 3  # Low priority fallback

class TemplateLLMProvider(LLMProvider):
    def __init__(self, templates: Dict[str, str], name: str = "template"):
        self.templates = templates
        self.name = name
        self.logger = logging.getLogger(f"provider_{name}")
    
    async def generate(
        self,
        prompt: str,
        model: str,
        **kwargs
    ) -> FallbackResult:
        # Simple keyword matching for templates
        template_response = self._match_template(prompt)
        
        if template_response:
            return FallbackResult(
                content=template_response,
                source=self.name,
                is_fallback=True,
                trigger_reason=FallbackTrigger.ERROR,
                quality_score=0.3  # Low quality score for templates
            )
        else:
            raise Exception("No matching template found")
    
    def _match_template(self, prompt: str) -> Optional[str]:
        prompt_lower = prompt.lower()
        
        # Simple keyword matching
        for keywords, response in self.templates.items():
            if any(keyword in prompt_lower for keyword in keywords.split("|")):
                return response
        
        return None
    
    async def health_check(self) -> bool:
        return len(self.templates) > 0
    
    def get_priority(self) -> int:
        return 5  # Lowest priority fallback

class FallbackManager:
    def __init__(self):
        self.providers: List[LLMProvider] = []
        self.circuit_breakers: Dict[str, dict] = {}
        self.logger = logging.getLogger("fallback_manager")
    
    def add_provider(self, provider: LLMProvider):
        \"\"\"Add a provider to the fallback chain\"\"\"
        self.providers.append(provider)
        # Sort by priority (lower number = higher priority)
        self.providers.sort(key=lambda p: p.get_priority())
        
        # Initialize circuit breaker for provider
        self.circuit_breakers[provider.name] = {
            "failure_count": 0,
            "last_failure": None,
            "circuit_open": False,
            "threshold": 5,
            "timeout": 60
        }
    
    def _is_circuit_open(self, provider_name: str) -> bool:
        \"\"\"Check if circuit breaker is open for a provider\"\"\"
        cb = self.circuit_breakers.get(provider_name, {})
        
        if not cb.get("circuit_open", False):
            return False
        
        # Check if timeout has passed
        import time
        if (time.time() - cb.get("last_failure", 0)) > cb.get("timeout", 60):
            # Reset circuit breaker
            cb["circuit_open"] = False
            cb["failure_count"] = 0
            self.logger.info(f"Circuit breaker reset for {provider_name}")
            return False
        
        return True
    
    def _record_failure(self, provider_name: str):
        \"\"\"Record a failure for circuit breaker\"\"\"
        cb = self.circuit_breakers.get(provider_name, {})
        cb["failure_count"] = cb.get("failure_count", 0) + 1
        
        import time
        cb["last_failure"] = time.time()
        
        if cb["failure_count"] >= cb.get("threshold", 5):
            cb["circuit_open"] = True
            self.logger.warning(f"Circuit breaker opened for {provider_name}")
    
    def _record_success(self, provider_name: str):
        \"\"\"Record a success for circuit breaker\"\"\"
        cb = self.circuit_breakers.get(provider_name, {})
        cb["failure_count"] = 0
        cb["circuit_open"] = False
    
    async def generate_with_fallback(
        self,
        prompt: str,
        model: str,
        quality_threshold: float = 0.5,
        **kwargs
    ) -> FallbackResult:
        \"\"\"Generate text with fallback strategy\"\"\"
        
        last_exception = None
        
        for provider in self.providers:
            # Skip if circuit breaker is open
            if self._is_circuit_open(provider.name):
                self.logger.warning(f"Skipping {provider.name} - circuit breaker open")
                continue
            
            try:
                self.logger.info(f"Trying provider: {provider.name}")
                
                result = await provider.generate(
                    prompt=prompt,
                    model=model,
                    **kwargs
                )
                
                # Check quality threshold
                if (result.quality_score is not None and 
                    result.quality_score < quality_threshold and 
                    provider.get_priority() == 1):  # Only check for primary
                    
                    self.logger.warning(
                        f"Primary provider quality below threshold: {result.quality_score} < {quality_threshold}"
                    )
                    
                    # Continue to fallback providers
                    continue
                
                # Success
                self._record_success(provider.name)
                
                if result.is_fallback:
                    self.logger.info(f"Fallback successful with {provider.name}")
                
                return result
                
            except Exception as e:
                last_exception = e
                self._record_failure(provider.name)
                self.logger.error(f"Provider {provider.name} failed: {e}")
                continue
        
        # All providers failed
        self.logger.error("All fallback providers exhausted")
        if last_exception:
            raise last_exception
        else:
            raise Exception("No providers available")
    
    async def health_check_all(self) -> Dict[str, bool]:
        \"\"\"Check health of all providers\"\"\"
        results = {}
        
        for provider in self.providers:
            try:
                health = await provider.health_check()
                results[provider.name] = health
            except Exception as e:
                results[provider.name] = False
                self.logger.error(f"Health check failed for {provider.name}: {e}")
        
        return results

# Usage example
async def setup_fallback_system():
    # Initialize fallback manager
    fallback_manager = FallbackManager()
    
    # Add primary provider
    primary_provider = PrimaryLLMProvider(llm_engine, "primary_llm")
    fallback_manager.add_provider(primary_provider)
    
    # Add cache fallback
    cache_store = {}  # In production, use Redis or similar
    cache_provider = CacheLLMProvider(cache_store, "response_cache")
    fallback_manager.add_provider(cache_provider)
    
    # Add template fallback
    templates = {\n        \"hello|hi|greetings\": \"Hello! I'm experiencing some technical difficulties, but I'm here to help.\",\n        \"help|support|assistance\": \"I'm currently operating in fallback mode. Please try again later or contact support.\",\n        \"error|problem|issue\": \"I apologize for the inconvenience. The system is experiencing technical difficulties.\"\n    }\n    template_provider = TemplateLLMProvider(templates, \"emergency_templates\")\n    fallback_manager.add_provider(template_provider)\n    \n    return fallback_manager\n\n# Example usage\nasync def demo_fallback():\n    fallback_manager = await setup_fallback_system()\n    \n    try:\n        result = await fallback_manager.generate_with_fallback(\n            prompt=\"Hello, how are you?\",\n            model=\"llama-2-7b-chat\",\n            quality_threshold=0.6\n        )\n        \n        print(f\"Response: {result.content}\")\n        print(f\"Source: {result.source}\")\n        print(f\"Is fallback: {result.is_fallback}\")\n        if result.trigger_reason:\n            print(f\"Fallback reason: {result.trigger_reason.value}\")\n        \n    except Exception as e:\n        print(f\"Complete fallback failure: {e}\")\n\nif __name__ == \"__main__\":\n    asyncio.run(demo_fallback())\n```

## Monitoring and Logging

Comprehensive observability for LLM integrations, providing insights into performance, usage patterns, and system health.

### Request Logging

Detailed logging of API requests, responses, and processing metrics for debugging and analytics.

**Structured Logging Implementation:**

```python
# request_logging.py
import logging
import json
import time
import uuid
from typing import Dict, Any, Optional, List
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from contextlib import contextmanager
import asyncio
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

@dataclass
class LogContext:
    request_id: str
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    trace_id: Optional[str] = None
    correlation_id: Optional[str] = None

@dataclass 
class RequestLog:
    # Request identification
    request_id: str
    timestamp: str
    method: str
    path: str
    
    # Request details
    user_id: Optional[str] = None
    user_agent: Optional[str] = None
    client_ip: Optional[str] = None
    
    # LLM-specific fields
    model: Optional[str] = None
    prompt: Optional[str] = None
    prompt_tokens: Optional[int] = None
    max_tokens: Optional[int] = None
    temperature: Optional[float] = None
    
    # Response details
    status_code: Optional[int] = None
    response_tokens: Optional[int] = None
    response_length: Optional[int] = None
    
    # Performance metrics
    processing_time: Optional[float] = None
    queue_time: Optional[float] = None
    model_inference_time: Optional[float] = None
    
    # Error information
    error_code: Optional[str] = None
    error_message: Optional[str] = None
    
    # Additional metadata
    stream_enabled: Optional[bool] = None
    cache_hit: Optional[bool] = None
    fallback_used: Optional[bool] = None

class StructuredLogger:
    def __init__(self, name: str = \"llm_api\", level: str = \"INFO\"):
        self.logger = logging.getLogger(name)\n        self.logger.setLevel(getattr(logging, level.upper()))\n        \n        # Configure JSON formatter\n        handler = logging.StreamHandler()\n        formatter = logging.Formatter(\n            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'\n        )\n        handler.setFormatter(formatter)\n        \n        if not self.logger.handlers:\n            self.logger.addHandler(handler)\n    \n    def log_request(self, log_entry: RequestLog):\n        \"\"\"Log a request with structured data\"\"\"\n        log_data = asdict(log_entry)\n        \n        # Remove None values for cleaner logs\n        log_data = {k: v for k, v in log_data.items() if v is not None}\n        \n        # Determine log level based on status\n        if log_entry.error_code:\n            self.logger.error(json.dumps(log_data, indent=2))\n        elif log_entry.status_code and log_entry.status_code >= 400:\n            self.logger.warning(json.dumps(log_data, indent=2))\n        else:\n            self.logger.info(json.dumps(log_data, indent=2))\n    \n    def log_performance(self, request_id: str, metrics: Dict[str, Any]):\n        \"\"\"Log performance metrics\"\"\"\n        log_data = {\n            \"event_type\": \"performance_metrics\",\n            \"request_id\": request_id,\n            \"timestamp\": datetime.utcnow().isoformat(),\n            **metrics\n        }\n        \n        self.logger.info(json.dumps(log_data))\n    \n    def log_error(self, request_id: str, error: Exception, context: Dict[str, Any] = None):\n        \"\"\"Log error with context\"\"\"\n        import traceback\n        \n        log_data = {\n            \"event_type\": \"error\",\n            \"request_id\": request_id,\n            \"timestamp\": datetime.utcnow().isoformat(),\n            \"error_type\": type(error).__name__,\n            \"error_message\": str(error),\n            \"traceback\": traceback.format_exc(),\n            \"context\": context or {}\n        }\n        \n        self.logger.error(json.dumps(log_data, indent=2))\n\nclass RequestLoggingMiddleware(BaseHTTPMiddleware):\n    def __init__(self, app, logger: StructuredLogger):\n        super().__init__(app)\n        self.logger = logger\n        self.start_times = {}\n    \n    async def dispatch(self, request: Request, call_next):\n        # Generate request ID\n        request_id = str(uuid.uuid4())\n        request.state.request_id = request_id\n        \n        # Record start time\n        start_time = time.time()\n        self.start_times[request_id] = start_time\n        \n        # Extract request information\n        log_entry = RequestLog(\n            request_id=request_id,\n            timestamp=datetime.utcnow().isoformat(),\n            method=request.method,\n            path=request.url.path,\n            user_agent=request.headers.get(\"user-agent\"),\n            client_ip=self._get_client_ip(request)\n        )\n        \n        try:\n            # Process request\n            response = await call_next(request)\n            \n            # Calculate processing time\n            processing_time = time.time() - start_time\n            \n            # Update log entry with response information\n            log_entry.status_code = response.status_code\n            log_entry.processing_time = processing_time\n            \n            # Extract LLM-specific information from request state if available\n            if hasattr(request.state, \"llm_model\"):\n                log_entry.model = request.state.llm_model\n            if hasattr(request.state, \"prompt_tokens\"):\n                log_entry.prompt_tokens = request.state.prompt_tokens\n            if hasattr(request.state, \"response_tokens\"):\n                log_entry.response_tokens = request.state.response_tokens\n            if hasattr(request.state, \"cache_hit\"):\n                log_entry.cache_hit = request.state.cache_hit\n            \n            # Log the request\n            self.logger.log_request(log_entry)\n            \n            return response\n            \n        except Exception as e:\n            # Log error\n            processing_time = time.time() - start_time\n            log_entry.processing_time = processing_time\n            log_entry.error_code = type(e).__name__\n            log_entry.error_message = str(e)\n            \n            self.logger.log_request(log_entry)\n            raise\n        \n        finally:\n            # Cleanup\n            self.start_times.pop(request_id, None)\n    \n    def _get_client_ip(self, request: Request) -> str:\n        \"\"\"Extract client IP from request\"\"\"\n        # Check for forwarded IP headers\n        forwarded_for = request.headers.get(\"x-forwarded-for\")\n        if forwarded_for:\n            return forwarded_for.split(\",\")[0].strip()\n        \n        real_ip = request.headers.get(\"x-real-ip\")\n        if real_ip:\n            return real_ip\n        \n        return request.client.host if request.client else \"unknown\"\n\n# Context manager for request tracking\nclass RequestContext:\n    def __init__(self, logger: StructuredLogger):\n        self.logger = logger\n        self.context_data = {}\n        self.start_time = None\n    \n    def set_context(self, **kwargs):\n        \"\"\"Set context data for the request\"\"\"\n        self.context_data.update(kwargs)\n    \n    def start_timing(self, operation: str):\n        \"\"\"Start timing an operation\"\"\"\n        self.context_data[f\"{operation}_start\"] = time.time()\n    \n    def end_timing(self, operation: str):\n        \"\"\"End timing an operation\"\"\"\n        start_key = f\"{operation}_start\"\n        if start_key in self.context_data:\n            duration = time.time() - self.context_data[start_key]\n            self.context_data[f\"{operation}_duration\"] = duration\n            del self.context_data[start_key]\n    \n    @contextmanager\n    def time_operation(self, operation: str):\n        \"\"\"Context manager for timing operations\"\"\"\n        self.start_timing(operation)\n        try:\n            yield\n        finally:\n            self.end_timing(operation)\n    \n    def log_metrics(self, request_id: str):\n        \"\"\"Log accumulated metrics\"\"\"\n        if self.context_data:\n            self.logger.log_performance(request_id, self.context_data)\n\n# Integration with LLM service\nclass LoggingLLMService:\n    def __init__(self, llm_engine, logger: StructuredLogger):\n        self.llm_engine = llm_engine\n        self.logger = logger\n    \n    async def generate_with_logging(\n        self,\n        request_id: str,\n        prompt: str,\n        model: str,\n        **kwargs\n    ) -> Dict[str, Any]:\n        \"\"\"Generate text with comprehensive logging\"\"\"\n        \n        context = RequestContext(self.logger)\n        context.set_context(\n            model=model,\n            prompt_length=len(prompt),\n            prompt_tokens=len(prompt.split()),  # Rough estimate\n            temperature=kwargs.get('temperature', 0.7),\n            max_tokens=kwargs.get('max_tokens', 500)\n        )\n        \n        try:\n            # Log generation start\n            self.logger.logger.info(json.dumps({\n                \"event_type\": \"generation_start\",\n                \"request_id\": request_id,\n                \"model\": model,\n                \"prompt_tokens\": len(prompt.split()),\n                \"timestamp\": datetime.utcnow().isoformat()\n            }))\n            \n            with context.time_operation(\"total_generation\"):\n                with context.time_operation(\"model_inference\"):\n                    result = await self.llm_engine.generate(\n                        prompt=prompt,\n                        model=model,\n                        **kwargs\n                    )\n                \n                # Add response metrics\n                context.set_context(\n                    response_length=len(result.text),\n                    response_tokens=len(result.text.split()),\n                    finish_reason=getattr(result, 'finish_reason', 'unknown')\n                )\n            \n            # Log generation completion\n            self.logger.logger.info(json.dumps({\n                \"event_type\": \"generation_complete\",\n                \"request_id\": request_id,\n                \"response_tokens\": len(result.text.split()),\n                \"processing_time\": context.context_data.get('total_generation_duration'),\n                \"timestamp\": datetime.utcnow().isoformat()\n            }))\n            \n            # Log metrics\n            context.log_metrics(request_id)\n            \n            return {\n                \"text\": result.text,\n                \"model\": model,\n                \"usage\": {\n                    \"prompt_tokens\": len(prompt.split()),\n                    \"completion_tokens\": len(result.text.split()),\n                    \"total_tokens\": len(prompt.split()) + len(result.text.split())\n                }\n            }\n            \n        except Exception as e:\n            # Log error\n            self.logger.log_error(request_id, e, context.context_data)\n            raise\n\n# FastAPI integration\nfrom fastapi import FastAPI\n\ndef setup_logging(app: FastAPI):\n    logger = StructuredLogger(\"llm_api\")\n    app.add_middleware(RequestLoggingMiddleware, logger=logger)\n    return logger\n\n# Usage example\napp = FastAPI()\nlogger = setup_logging(app)\nlogging_service = LoggingLLMService(llm_engine, logger)\n\n@app.post(\"/generate\")\nasync def generate_endpoint(request: Request, prompt: str, model: str = \"default\"):\n    request_id = request.state.request_id\n    \n    # Set additional request state for middleware\n    request.state.llm_model = model\n    \n    try:\n        result = await logging_service.generate_with_logging(\n            request_id=request_id,\n            prompt=prompt,\n            model=model\n        )\n        \n        # Set response metrics for middleware\n        request.state.prompt_tokens = result[\"usage\"][\"prompt_tokens\"]\n        request.state.response_tokens = result[\"usage\"][\"completion_tokens\"]\n        \n        return result\n        \n    except Exception as e:\n        logger.log_error(request_id, e, {\"prompt\": prompt, \"model\": model})\n        raise\n```\n\n### Performance Metrics\n\nDetailed performance monitoring and metrics collection for optimization and capacity planning.\n\n**Performance Monitoring System:**\n\n```python\n# performance_metrics.py\nimport time\nimport asyncio\nfrom typing import Dict, List, Optional, Any\nfrom dataclasses import dataclass, field\nfrom collections import deque, defaultdict\nfrom datetime import datetime, timedelta\nimport statistics\nimport threading\nimport json\nfrom enum import Enum\n\nclass MetricType(Enum):\n    COUNTER = \"counter\"\n    GAUGE = \"gauge\"\n    HISTOGRAM = \"histogram\"\n    TIMER = \"timer\"\n\n@dataclass\nclass MetricPoint:\n    timestamp: float\n    value: float\n    labels: Dict[str, str] = field(default_factory=dict)\n\nclass MetricCollector:\n    def __init__(self, retention_hours: int = 24):\n        self.retention_seconds = retention_hours * 3600\n        self.metrics: Dict[str, Dict[str, deque]] = defaultdict(lambda: defaultdict(deque))\n        self.counters: Dict[str, float] = defaultdict(float)\n        self.gauges: Dict[str, float] = defaultdict(float)\n        self.lock = threading.Lock()\n        \n        # Start cleanup task\n        self._cleanup_task = asyncio.create_task(self._cleanup_old_metrics())\n    \n    def increment_counter(self, name: str, value: float = 1.0, labels: Dict[str, str] = None):\n        \"\"\"Increment a counter metric\"\"\"\n        labels = labels or {}\n        label_key = self._labels_to_key(labels)\n        \n        with self.lock:\n            self.counters[f\"{name}_{label_key}\"] += value\n            self.metrics[name][label_key].append(\n                MetricPoint(time.time(), value, labels)\n            )\n    \n    def set_gauge(self, name: str, value: float, labels: Dict[str, str] = None):\n        \"\"\"Set a gauge metric value\"\"\"\n        labels = labels or {}\n        label_key = self._labels_to_key(labels)\n        \n        with self.lock:\n            self.gauges[f\"{name}_{label_key}\"] = value\n            self.metrics[name][label_key].append(\n                MetricPoint(time.time(), value, labels)\n            )\n    \n    def record_histogram(self, name: str, value: float, labels: Dict[str, str] = None):\n        \"\"\"Record a histogram value\"\"\"\n        labels = labels or {}\n        label_key = self._labels_to_key(labels)\n        \n        with self.lock:\n            self.metrics[name][label_key].append(\n                MetricPoint(time.time(), value, labels)\n            )\n    \n    def time_operation(self, name: str, labels: Dict[str, str] = None):\n        \"\"\"Context manager for timing operations\"\"\"\n        return TimerContext(self, name, labels)\n    \n    def get_metric_stats(self, name: str, labels: Dict[str, str] = None, \n                        duration_minutes: int = 60) -> Dict[str, Any]:\n        \"\"\"Get statistics for a metric over a time period\"\"\"\n        labels = labels or {}\n        label_key = self._labels_to_key(labels)\n        \n        cutoff_time = time.time() - (duration_minutes * 60)\n        \n        with self.lock:\n            if name not in self.metrics or label_key not in self.metrics[name]:\n                return {}\n            \n            points = [\n                point for point in self.metrics[name][label_key]\n                if point.timestamp > cutoff_time\n            ]\n        \n        if not points:\n            return {}\n        \n        values = [point.value for point in points]\n        \n        return {\n            \"count\": len(values),\n            \"min\": min(values),\n            \"max\": max(values),\n            \"mean\": statistics.mean(values),\n            \"median\": statistics.median(values),\n            \"std_dev\": statistics.stdev(values) if len(values) > 1 else 0,\n            \"p95\": self._percentile(values, 95),\n            \"p99\": self._percentile(values, 99),\n            \"first_timestamp\": points[0].timestamp,\n            \"last_timestamp\": points[-1].timestamp\n        }\n    \n    def _percentile(self, values: List[float], percentile: float) -> float:\n        \"\"\"Calculate percentile of values\"\"\"\n        if not values:\n            return 0\n        \n        sorted_values = sorted(values)\n        index = (percentile / 100) * (len(sorted_values) - 1)\n        \n        if index.is_integer():\n            return sorted_values[int(index)]\n        else:\n            lower_index = int(index)\n            upper_index = lower_index + 1\n            weight = index - lower_index\n            \n            return sorted_values[lower_index] * (1 - weight) + \\\n                   sorted_values[upper_index] * weight\n    \n    def _labels_to_key(self, labels: Dict[str, str]) -> str:\n        \"\"\"Convert labels dict to a consistent key\"\"\"\n        return \"|\".join(f\"{k}={v}\" for k, v in sorted(labels.items()))\n    \n    async def _cleanup_old_metrics(self):\n        \"\"\"Periodically clean up old metric points\"\"\"\n        while True:\n            try:\n                cutoff_time = time.time() - self.retention_seconds\n                \n                with self.lock:\n                    for metric_name in self.metrics:\n                        for label_key in self.metrics[metric_name]:\n                            points = self.metrics[metric_name][label_key]\n                            \n                            # Remove old points\n                            while points and points[0].timestamp < cutoff_time:\n                                points.popleft()\n                \n                await asyncio.sleep(3600)  # Cleanup every hour\n                \n            except Exception as e:\n                print(f\"Metrics cleanup error: {e}\")\n                await asyncio.sleep(60)\n\nclass TimerContext:\n    def __init__(self, collector: MetricCollector, name: str, labels: Dict[str, str] = None):\n        self.collector = collector\n        self.name = name\n        self.labels = labels or {}\n        self.start_time = None\n    \n    def __enter__(self):\n        self.start_time = time.time()\n        return self\n    \n    def __exit__(self, exc_type, exc_val, exc_tb):\n        if self.start_time:\n            duration = time.time() - self.start_time\n            self.collector.record_histogram(self.name, duration, self.labels)\n\nclass LLMMetricsCollector:\n    \"\"\"LLM-specific metrics collection\"\"\"\n    \n    def __init__(self, base_collector: MetricCollector):\n        self.collector = base_collector\n    \n    def record_request(self, model: str, endpoint: str, status_code: int, \n                      processing_time: float, tokens_generated: int = 0,\n                      prompt_tokens: int = 0, cache_hit: bool = False):\n        \"\"\"Record comprehensive request metrics\"\"\"\n        \n        labels = {\n            \"model\": model,\n            \"endpoint\": endpoint,\n            \"status\": str(status_code)\n        }\n        \n        # Request count\n        self.collector.increment_counter(\"llm_requests_total\", 1, labels)\n        \n        # Processing time\n        self.collector.record_histogram(\"llm_request_duration_seconds\", \n                                       processing_time, labels)\n        \n        # Token metrics\n        if tokens_generated > 0:\n            self.collector.record_histogram(\"llm_tokens_generated\", \n                                           tokens_generated, labels)\n            \n            # Tokens per second\n            tokens_per_second = tokens_generated / processing_time if processing_time > 0 else 0\n            self.collector.record_histogram(\"llm_tokens_per_second\", \n                                           tokens_per_second, labels)\n        \n        if prompt_tokens > 0:\n            self.collector.record_histogram(\"llm_prompt_tokens\", \n                                           prompt_tokens, labels)\n        \n        # Cache metrics\n        cache_labels = {**labels, \"cache_hit\": str(cache_hit)}\n        self.collector.increment_counter(\"llm_cache_requests\", 1, cache_labels)\n    \n    def record_model_load(self, model: str, load_time: float, memory_usage: float):\n        \"\"\"Record model loading metrics\"\"\"\n        labels = {\"model\": model}\n        \n        self.collector.record_histogram(\"llm_model_load_duration_seconds\", \n                                       load_time, labels)\n        self.collector.set_gauge(\"llm_model_memory_usage_bytes\", \n                               memory_usage, labels)\n        self.collector.increment_counter(\"llm_model_loads_total\", 1, labels)\n    \n    def record_queue_metrics(self, queue_size: int, wait_time: float = None):\n        \"\"\"Record request queue metrics\"\"\"\n        self.collector.set_gauge(\"llm_queue_size\", queue_size)\n        \n        if wait_time is not None:\n            self.collector.record_histogram(\"llm_queue_wait_duration_seconds\", wait_time)\n    \n    def record_error(self, model: str, endpoint: str, error_type: str):\n        \"\"\"Record error metrics\"\"\"\n        labels = {\n            \"model\": model,\n            \"endpoint\": endpoint,\n            \"error_type\": error_type\n        }\n        \n        self.collector.increment_counter(\"llm_errors_total\", 1, labels)\n    \n    def get_performance_summary(self, duration_minutes: int = 60) -> Dict[str, Any]:\n        \"\"\"Get comprehensive performance summary\"\"\"\n        \n        summary = {\n            \"timestamp\": datetime.utcnow().isoformat(),\n            \"duration_minutes\": duration_minutes,\n            \"metrics\": {}\n        }\n        \n        # Request metrics\n        request_stats = self.collector.get_metric_stats(\n            \"llm_requests_total\", duration_minutes=duration_minutes\n        )\n        \n        if request_stats:\n            summary[\"metrics\"][\"requests\"] = {\n                \"total_requests\": request_stats[\"count\"],\n                \"requests_per_minute\": request_stats[\"count\"] / duration_minutes\n            }\n        \n        # Response time metrics\n        response_time_stats = self.collector.get_metric_stats(\n            \"llm_request_duration_seconds\", duration_minutes=duration_minutes\n        )\n        \n        if response_time_stats:\n            summary[\"metrics\"][\"response_time\"] = {\n                \"mean_seconds\": response_time_stats[\"mean\"],\n                \"p95_seconds\": response_time_stats[\"p95\"],\n                \"p99_seconds\": response_time_stats[\"p99\"],\n                \"max_seconds\": response_time_stats[\"max\"]\n            }\n        \n        # Token metrics\n        token_stats = self.collector.get_metric_stats(\n            \"llm_tokens_generated\", duration_minutes=duration_minutes\n        )\n        \n        if token_stats:\n            summary[\"metrics\"][\"tokens\"] = {\n                \"total_generated\": token_stats[\"count\"] * token_stats[\"mean\"],\n                \"mean_per_request\": token_stats[\"mean\"],\n                \"tokens_per_minute\": (token_stats[\"count\"] * token_stats[\"mean\"]) / duration_minutes\n            }\n        \n        # Throughput metrics\n        throughput_stats = self.collector.get_metric_stats(\n            \"llm_tokens_per_second\", duration_minutes=duration_minutes\n        )\n        \n        if throughput_stats:\n            summary[\"metrics\"][\"throughput\"] = {\n                \"mean_tokens_per_second\": throughput_stats[\"mean\"],\n                \"p95_tokens_per_second\": throughput_stats[\"p95\"],\n                \"max_tokens_per_second\": throughput_stats[\"max\"]\n            }\n        \n        return summary\n\n# Integration with FastAPI\nfrom fastapi import FastAPI, Request\nfrom fastapi.responses import JSONResponse\n\nclass MetricsMiddleware:\n    def __init__(self, app: FastAPI, metrics_collector: LLMMetricsCollector):\n        self.app = app\n        self.metrics = metrics_collector\n        \n        # Add metrics endpoint\n        @app.get(\"/metrics/summary\")\n        async def get_metrics_summary(duration_minutes: int = 60):\n            return self.metrics.get_performance_summary(duration_minutes)\n        \n        @app.get(\"/metrics/health\")\n        async def get_health_metrics():\n            # Basic health check metrics\n            recent_stats = self.metrics.get_performance_summary(5)  # Last 5 minutes\n            \n            health_status = \"healthy\"\n            if \"response_time\" in recent_stats.get(\"metrics\", {}):\n                p99_time = recent_stats[\"metrics\"][\"response_time\"].get(\"p99_seconds\", 0)\n                if p99_time > 30:  # 30 second threshold\n                    health_status = \"degraded\"\n                elif p99_time > 60:  # 60 second threshold\n                    health_status = \"unhealthy\"\n            \n            return {\n                \"status\": health_status,\n                \"timestamp\": datetime.utcnow().isoformat(),\n                \"metrics\": recent_stats\n            }\n\n# Usage example\napp = FastAPI()\nbase_collector = MetricCollector()\nllm_metrics = LLMMetricsCollector(base_collector)\nmetrics_middleware = MetricsMiddleware(app, llm_metrics)\n\n@app.post(\"/generate\")\nasync def generate_with_metrics(\n    request: Request,\n    prompt: str,\n    model: str = \"default\",\n    max_tokens: int = 500\n):\n    start_time = time.time()\n    \n    try:\n        # Simulate generation\n        result = await llm_engine.generate(\n            prompt=prompt,\n            model=model,\n            max_tokens=max_tokens\n        )\n        \n        processing_time = time.time() - start_time\n        \n        # Record metrics\n        llm_metrics.record_request(\n            model=model,\n            endpoint=\"/generate\",\n            status_code=200,\n            processing_time=processing_time,\n            tokens_generated=len(result.text.split()),\n            prompt_tokens=len(prompt.split()),\n            cache_hit=False\n        )\n        \n        return {\n            \"response\": result.text,\n            \"model\": model,\n            \"processing_time\": processing_time\n        }\n        \n    except Exception as e:\n        processing_time = time.time() - start_time\n        \n        # Record error metrics\n        llm_metrics.record_error(\n            model=model,\n            endpoint=\"/generate\",\n            error_type=type(e).__name__\n        )\n        \n        llm_metrics.record_request(\n            model=model,\n            endpoint=\"/generate\",\n            status_code=500,\n            processing_time=processing_time\n        )\n        \n        raise\n```\n\n### Health Checks\n\nComprehensive health monitoring for LLM services and dependencies.\n\n**Health Check Implementation:**\n\n```python\n# health_checks.py\nimport asyncio\nimport time\nfrom typing import Dict, List, Optional, Any, Callable\nfrom dataclasses import dataclass\nfrom enum import Enum\nfrom datetime import datetime, timedelta\nimport logging\n\nclass HealthStatus(Enum):\n    HEALTHY = \"healthy\"\n    DEGRADED = \"degraded\"\n    UNHEALTHY = \"unhealthy\"\n    UNKNOWN = \"unknown\"\n\n@dataclass\nclass HealthCheckResult:\n    name: str\n    status: HealthStatus\n    response_time: float\n    message: Optional[str] = None\n    details: Optional[Dict[str, Any]] = None\n    timestamp: Optional[datetime] = None\n    \n    def __post_init__(self):\n        if self.timestamp is None:\n            self.timestamp = datetime.utcnow()\n\nclass HealthChecker:\n    def __init__(self):\n        self.checks: Dict[str, Callable] = {}\n        self.results_cache: Dict[str, HealthCheckResult] = {}\n        self.cache_ttl: Dict[str, int] = {}  # TTL in seconds\n        self.logger = logging.getLogger(\"health_checker\")\n    \n    def register_check(\n        self,\n        name: str,\n        check_func: Callable,\n        cache_ttl: int = 30\n    ):\n        \"\"\"Register a health check function\"\"\"\n        self.checks[name] = check_func\n        self.cache_ttl[name] = cache_ttl\n        self.logger.info(f\"Registered health check: {name}\")\n    \n    async def run_check(self, name: str, force_refresh: bool = False) -> HealthCheckResult:\n        \"\"\"Run a specific health check\"\"\"\n        \n        # Check cache first\n        if not force_refresh and name in self.results_cache:\n            cached_result = self.results_cache[name]\n            age = (datetime.utcnow() - cached_result.timestamp).total_seconds()\n            \n            if age < self.cache_ttl.get(name, 30):\n                return cached_result\n        \n        if name not in self.checks:\n            return HealthCheckResult(\n                name=name,\n                status=HealthStatus.UNKNOWN,\n                response_time=0,\n                message=f\"Health check '{name}' not found\"\n            )\n        \n        start_time = time.time()\n        \n        try:\n            check_func = self.checks[name]\n            \n            if asyncio.iscoroutinefunction(check_func):\n                result = await check_func()\n            else:\n                result = check_func()\n            \n            response_time = time.time() - start_time\n            \n            # Handle different return types\n            if isinstance(result, HealthCheckResult):\n                result.response_time = response_time\n                health_result = result\n            elif isinstance(result, bool):\n                health_result = HealthCheckResult(\n                    name=name,\n                    status=HealthStatus.HEALTHY if result else HealthStatus.UNHEALTHY,\n                    response_time=response_time,\n                    message=\"OK\" if result else \"Check failed\"\n                )\n            elif isinstance(result, dict):\n                health_result = HealthCheckResult(\n                    name=name,\n                    status=HealthStatus(result.get('status', 'unknown')),\n                    response_time=response_time,\n                    message=result.get('message'),\n                    details=result.get('details')\n                )\n            else:\n                health_result = HealthCheckResult(\n                    name=name,\n                    status=HealthStatus.HEALTHY,\n                    response_time=response_time,\n                    message=str(result)\n                )\n            \n            # Cache result\n            self.results_cache[name] = health_result\n            \n            return health_result\n            \n        except Exception as e:\n            response_time = time.time() - start_time\n            \n            health_result = HealthCheckResult(\n                name=name,\n                status=HealthStatus.UNHEALTHY,\n                response_time=response_time,\n                message=f\"Health check failed: {str(e)}\",\n                details={\"error_type\": type(e).__name__}\n            )\n            \n            self.logger.error(f\"Health check '{name}' failed: {e}\")\n            self.results_cache[name] = health_result\n            \n            return health_result\n    \n    async def run_all_checks(self, force_refresh: bool = False) -> Dict[str, HealthCheckResult]:\n        \"\"\"Run all registered health checks\"\"\"\n        results = {}\n        \n        # Run all checks concurrently\n        tasks = [\n            self.run_check(name, force_refresh)\n            for name in self.checks.keys()\n        ]\n        \n        completed_results = await asyncio.gather(*tasks, return_exceptions=True)\n        \n        for i, result in enumerate(completed_results):\n            check_name = list(self.checks.keys())[i]\n            \n            if isinstance(result, Exception):\n                results[check_name] = HealthCheckResult(\n                    name=check_name,\n                    status=HealthStatus.UNHEALTHY,\n                    response_time=0,\n                    message=f\"Check execution failed: {str(result)}\"\n                )\n            else:\n                results[check_name] = result\n        \n        return results\n    \n    def get_overall_status(self, results: Dict[str, HealthCheckResult]) -> HealthStatus:\n        \"\"\"Determine overall system health status\"\"\"\n        if not results:\n            return HealthStatus.UNKNOWN\n        \n        statuses = [result.status for result in results.values()]\n        \n        if any(status == HealthStatus.UNHEALTHY for status in statuses):\n            return HealthStatus.UNHEALTHY\n        elif any(status == HealthStatus.DEGRADED for status in statuses):\n            return HealthStatus.DEGRADED\n        elif any(status == HealthStatus.UNKNOWN for status in statuses):\n            return HealthStatus.UNKNOWN\n        else:\n            return HealthStatus.HEALTHY\n\nclass LLMHealthChecker(HealthChecker):\n    \"\"\"LLM-specific health checks\"\"\"\n    \n    def __init__(self, llm_engine):\n        super().__init__()\n        self.llm_engine = llm_engine\n        self._register_llm_checks()\n    \n    def _register_llm_checks(self):\n        \"\"\"Register LLM-specific health checks\"\"\"\n        \n        self.register_check(\"llm_model_available\", self._check_model_available)\n        self.register_check(\"llm_generation_test\", self._check_generation, cache_ttl=60)\n        self.register_check(\"llm_memory_usage\", self._check_memory_usage, cache_ttl=30)\n        self.register_check(\"llm_response_time\", self._check_response_time, cache_ttl=45)\n        self.register_check(\"llm_queue_status\", self._check_queue_status, cache_ttl=10)\n    \n    async def _check_model_available(self) -> Dict[str, Any]:\n        \"\"\"Check if LLM models are loaded and available\"\"\"\n        try:\n            models = await self.llm_engine.list_models()\n            \n            if not models:\n                return {\n                    \"status\": \"unhealthy\",\n                    \"message\": \"No models available\",\n                    \"details\": {\"model_count\": 0}\n                }\n            \n            return {\n                \"status\": \"healthy\",\n                \"message\": f\"{len(models)} models available\",\n                \"details\": {\n                    \"model_count\": len(models),\n                    \"models\": [model.get('id', 'unknown') for model in models]\n                }\n            }\n            \n        except Exception as e:\n            return {\n                \"status\": \"unhealthy\",\n                \"message\": f\"Failed to check models: {str(e)}\"\n            }\n    \n    async def _check_generation(self) -> Dict[str, Any]:\n        \"\"\"Test text generation functionality\"\"\"\n        try:\n            start_time = time.time()\n            \n            result = await self.llm_engine.generate(\n                prompt=\"Test\",\n                model=\"default\",\n                max_tokens=5,\n                timeout=10\n            )\n            \n            generation_time = time.time() - start_time\n            \n            if not result or not result.text:\n                return {\n                    \"status\": \"unhealthy\",\n                    \"message\": \"Generation returned empty result\"\n                }\n            \n            status = \"healthy\"\n            if generation_time > 10:\n                status = \"degraded\"\n            elif generation_time > 30:\n                status = \"unhealthy\"\n            \n            return {\n                \"status\": status,\n                \"message\": f\"Generation successful in {generation_time:.2f}s\",\n                \"details\": {\n                    \"generation_time\": generation_time,\n                    \"response_length\": len(result.text)\n                }\n            }\n            \n        except asyncio.TimeoutError:\n            return {\n                \"status\": \"unhealthy\",\n                \"message\": \"Generation timed out\"\n            }\n        except Exception as e:\n            return {\n                \"status\": \"unhealthy\",\n                \"message\": f\"Generation failed: {str(e)}\"\n            }\n    \n    async def _check_memory_usage(self) -> Dict[str, Any]:\n        \"\"\"Check memory usage\"\"\"\n        import psutil\n        \n        try:\n            process = psutil.Process()\n            memory_info = process.memory_info()\n            memory_percent = process.memory_percent()\n            \n            status = \"healthy\"\n            if memory_percent > 90:\n                status = \"unhealthy\"\n            elif memory_percent > 80:\n                status = \"degraded\"\n            \n            return {\n                \"status\": status,\n                \"message\": f\"Memory usage: {memory_percent:.1f}%\",\n                \"details\": {\n                    \"memory_percent\": memory_percent,\n                    \"memory_rss_mb\": memory_info.rss / 1024 / 1024,\n                    \"memory_vms_mb\": memory_info.vms / 1024 / 1024\n                }\n            }\n            \n        except Exception as e:\n            return {\n                \"status\": \"unknown\",\n                \"message\": f\"Failed to check memory: {str(e)}\"\n            }\n    \n    async def _check_response_time(self) -> Dict[str, Any]:\n        \"\"\"Check average response time\"\"\"\n        try:\n            # This would typically get metrics from a metrics collector\n            # For demo purposes, we'll simulate it\n            \n            avg_response_time = 2.5  # Simulated average\n            p95_response_time = 5.0  # Simulated P95\n            \n            status = \"healthy\"\n            if p95_response_time > 30:\n                status = \"unhealthy\"\n            elif p95_response_time > 15:\n                status = \"degraded\"\n            \n            return {\n                \"status\": status,\n                \"message\": f\"Avg response time: {avg_response_time:.1f}s, P95: {p95_response_time:.1f}s\",\n                \"details\": {\n                    \"avg_response_time\": avg_response_time,\n                    \"p95_response_time\": p95_response_time\n                }\n            }\n            \n        except Exception as e:\n            return {\n                \"status\": \"unknown\",\n                \"message\": f\"Failed to check response times: {str(e)}\"\n            }\n    \n    async def _check_queue_status(self) -> Dict[str, Any]:\n        \"\"\"Check request queue status\"\"\"\n        try:\n            # This would typically check actual queue metrics\n            queue_size = 0  # Simulated\n            max_queue_size = 100\n            \n            status = \"healthy\"\n            if queue_size > max_queue_size * 0.9:\n                status = \"unhealthy\"\n            elif queue_size > max_queue_size * 0.7:\n                status = \"degraded\"\n            \n            return {\n                \"status\": status,\n                \"message\": f\"Queue size: {queue_size}/{max_queue_size}\",\n                \"details\": {\n                    \"current_queue_size\": queue_size,\n                    \"max_queue_size\": max_queue_size,\n                    \"queue_utilization\": queue_size / max_queue_size\n                }\n            }\n            \n        except Exception as e:\n            return {\n                \"status\": \"unknown\",\n                \"message\": f\"Failed to check queue: {str(e)}\"\n            }\n\n# FastAPI integration\nfrom fastapi import FastAPI\nfrom fastapi.responses import JSONResponse\n\ndef setup_health_checks(app: FastAPI, llm_engine) -> LLMHealthChecker:\n    health_checker = LLMHealthChecker(llm_engine)\n    \n    @app.get(\"/health\")\n    async def health_check():\n        \"\"\"Basic health check endpoint\"\"\"\n        results = await health_checker.run_all_checks()\n        overall_status = health_checker.get_overall_status(results)\n        \n        response_data = {\n            \"status\": overall_status.value,\n            \"timestamp\": datetime.utcnow().isoformat(),\n            \"checks\": {\n                name: {\n                    \"status\": result.status.value,\n                    \"response_time\": result.response_time,\n                    \"message\": result.message,\n                    \"details\": result.details\n                }\n                for name, result in results.items()\n            }\n        }\n        \n        # Set appropriate HTTP status code\n        status_code = 200\n        if overall_status == HealthStatus.UNHEALTHY:\n            status_code = 503\n        elif overall_status == HealthStatus.DEGRADED:\n            status_code = 200  # Still accepting traffic\n        \n        return JSONResponse(content=response_data, status_code=status_code)\n    \n    @app.get(\"/health/{check_name}\")\n    async def individual_health_check(check_name: str):\n        \"\"\"Individual health check endpoint\"\"\"\n        result = await health_checker.run_check(check_name, force_refresh=True)\n        \n        response_data = {\n            \"name\": result.name,\n            \"status\": result.status.value,\n            \"response_time\": result.response_time,\n            \"message\": result.message,\n            \"details\": result.details,\n            \"timestamp\": result.timestamp.isoformat()\n        }\n        \n        status_code = 200 if result.status != HealthStatus.UNHEALTHY else 503\n        return JSONResponse(content=response_data, status_code=status_code)\n    \n    return health_checker\n\n# Usage example\napp = FastAPI()\nhealth_checker = setup_health_checks(app, llm_engine)\n```
```

## Security

### Authentication Methods

API keys, JWT, OAuth.

### Authorization

Access control.

### Input Validation

Sanitizing requests.

### Rate Limiting

Preventing abuse.

## Best Practices

### API Design

RESTful principles.

### Documentation

Clear API docs.

### Versioning

Managing API versions.

### Testing

Comprehensive testing.

## Code Examples

Sample integration code.

## Troubleshooting

Common integration issues.
