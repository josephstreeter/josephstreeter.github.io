---
title: "Webhooks"
description: "Event-driven integration with webhooks, callbacks, and delivery guarantees"
author: "Joseph Streeter"
tags: ["local llms", "integration", "webhooks", "events", "callbacks"]
category: "ai"
last_updated: "2026-08-01"
---
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
