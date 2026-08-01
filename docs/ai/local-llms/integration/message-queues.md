---
title: "Message Queue Integration"
description: "Asynchronous inference with queues, workers, and back-pressure handling"
author: "Joseph Streeter"
tags: ["local llms", "integration", "queue", "async", "workers", "rabbitmq"]
category: "ai"
last_updated: "2026-08-01"
---
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
