---
title: "Client Libraries"
description: "Calling local LLM endpoints from Python, JavaScript, and other language clients"
author: "Joseph Streeter"
tags: ["local llms", "integration", "client", "python", "javascript", "sdk"]
category: "ai"
last_updated: "2026-08-01"
---
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
