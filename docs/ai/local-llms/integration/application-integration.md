---
title: "Application Integration"
description: "Wiring local LLMs into web applications, chat interfaces, and existing systems"
author: "Joseph Streeter"
tags: ["local llms", "integration", "applications", "web", "chat"]
category: "ai"
last_updated: "2026-08-01"
---
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
