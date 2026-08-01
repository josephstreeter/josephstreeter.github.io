---
title: "Microservices Architecture"
description: "Decomposing LLM workloads into services, with routing, scaling, and resilience"
author: "Joseph Streeter"
tags: ["local llms", "integration", "microservices", "architecture", "scaling"]
category: "ai"
last_updated: "2026-08-01"
---
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
