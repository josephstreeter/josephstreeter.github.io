---
title: "Middleware and Proxies"
description: "Gateways, routers, caching layers, and proxies in front of LLM endpoints"
author: "Joseph Streeter"
tags: ["local llms", "integration", "middleware", "proxy", "gateway", "caching"]
category: "ai"
last_updated: "2026-08-01"
---
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
