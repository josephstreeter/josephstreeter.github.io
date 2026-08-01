---
title: "Streaming Integration"
description: "Token streaming over SSE and WebSockets, buffering, and client handling"
author: "Joseph Streeter"
tags: ["local llms", "integration", "streaming", "sse", "websockets"]
category: "ai"
last_updated: "2026-08-01"
---
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
