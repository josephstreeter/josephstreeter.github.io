---
title: "SDK Development"
description: "Building custom SDKs that wrap LLM endpoints with idiomatic language interfaces"
author: "Joseph Streeter"
tags: ["local llms", "integration", "sdk", "libraries", "packaging"]
category: "ai"
last_updated: "2026-08-01"
---
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
