---
title: "API Servers"
description: "OpenAI-compatible server implementations and how to configure and run them"
author: "Joseph Streeter"
tags: ["local llms", "integration", "api server", "vllm", "ollama"]
category: "ai"
last_updated: "2026-08-01"
---
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
docker compose up -d
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
