---
title: "API Standards"
description: "OpenAI-compatible and native API formats, request/response schemas, and endpoint conventions"
author: "Joseph Streeter"
tags: ["local llms", "integration", "api", "openai-compatible"]
category: "ai"
last_updated: "2026-08-01"
---
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

## Related Topics

- [Overview](index.md)
- [API Standards](api-standards.md)
- [API Servers](api-servers.md)
- [Client Libraries](client-libraries.md)
- [Framework Integration](frameworks.md)
- [Application Integration](application-integration.md)
- [Middleware and Proxies](middleware.md)
- [Database Integration](databases.md)
- [Message Queue Integration](message-queues.md)
- [Microservices Architecture](microservices.md)
- [SDK Development](sdk-development.md)
- [Webhooks](webhooks.md)
- [Streaming Integration](streaming.md)
- [Monitoring and Logging](monitoring.md)
