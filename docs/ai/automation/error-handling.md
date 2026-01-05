---
title: Error Handling in AI Automation
description: Strategies for handling errors, retries, and failures in AI automation workflows
author: Joseph Streeter
date: 2026-01-04
tags: [ai, automation, error-handling, retry, resilience, fault-tolerance]
---

## Overview

Robust error handling is critical for reliable AI automation workflows. This guide covers strategies for detecting, handling, and recovering from errors in AI systems.

## Common Error Types

### API Errors

#### Rate Limiting

```python
from openai import OpenAI, RateLimitError
import time

def api_call_with_retry(client, max_retries=3):
    for attempt in range(max_retries):
        try:
            response = client.chat.completions.create(
                model="gpt-4",
                messages=[{"role": "user", "content": "Hello"}]
            )
            return response
        except RateLimitError as e:
            if attempt < max_retries - 1:
                wait_time = 2 ** attempt  # Exponential backoff
                time.sleep(wait_time)
            else:
                raise
```

#### Timeout Errors

```python
from openai import OpenAI, Timeout
from requests.exceptions import ReadTimeout

def api_call_with_timeout(client, timeout_seconds=30):
    try:
        response = client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": "Hello"}],
            timeout=timeout_seconds
        )
        return response
    except Timeout:
        # Handle timeout - retry or use fallback
        return handle_timeout_fallback()
```

#### Authentication Errors

```python
from openai import OpenAI, AuthenticationError

def authenticate_with_fallback(api_key, fallback_key=None):
    try:
        client = OpenAI(api_key=api_key)
        # Test authentication
        client.models.list()
        return client
    except AuthenticationError:
        if fallback_key:
            return OpenAI(api_key=fallback_key)
        else:
            raise
```

### Model Errors

#### Context Length Exceeded

```python
def handle_context_overflow(text, model="gpt-4", max_tokens=8000):
    """Chunk text if it exceeds model context window."""
    import tiktoken
    
    encoding = tiktoken.encoding_for_model(model)
    tokens = encoding.encode(text)
    
    if len(tokens) > max_tokens:
        # Split into chunks
        chunks = []
        for i in range(0, len(tokens), max_tokens):
            chunk_tokens = tokens[i:i + max_tokens]
            chunk_text = encoding.decode(chunk_tokens)
            chunks.append(chunk_text)
        return chunks
    else:
        return [text]
```

#### Invalid Response Format

```python
import json
from pydantic import BaseModel, ValidationError

class ResponseModel(BaseModel):
    status: str
    data: dict
    confidence: float

def validate_response(response_text):
    """Validate and parse LLM response."""
    try:
        data = json.loads(response_text)
        validated = ResponseModel(**data)
        return validated
    except (json.JSONDecodeError, ValidationError) as e:
        # Log error and request reformatting
        return request_reformat(response_text, error=str(e))
```

### Data Errors

#### Missing or Invalid Input

```python
from typing import Optional

def validate_input(data: dict) -> Optional[str]:
    """Validate input data and return error message if invalid."""
    required_fields = ['user_id', 'query', 'context']
    
    for field in required_fields:
        if field not in data:
            return f"Missing required field: {field}"
        if not data[field]:
            return f"Empty value for required field: {field}"
            
    # Additional validation
    if len(data['query']) > 1000:
        return "Query exceeds maximum length of 1000 characters"
        
    return None  # No errors
```

## Retry Strategies

### Exponential Backoff

```python
import time
from typing import Callable, Any

def exponential_backoff(
    func: Callable,
    max_retries: int = 5,
    base_delay: float = 1.0,
    max_delay: float = 60.0
) -> Any:
    """Execute function with exponential backoff retry."""
    for attempt in range(max_retries):
        try:
            return func()
        except Exception as e:
            if attempt == max_retries - 1:
                raise
                
            delay = min(base_delay * (2 ** attempt), max_delay)
            print(f"Attempt {attempt + 1} failed: {e}. Retrying in {delay}s...")
            time.sleep(delay)
```

### Jittered Backoff

```python
import random

def jittered_backoff(
    func: Callable,
    max_retries: int = 5,
    base_delay: float = 1.0
) -> Any:
    """Execute function with jittered exponential backoff."""
    for attempt in range(max_retries):
        try:
            return func()
        except Exception as e:
            if attempt == max_retries - 1:
                raise
                
            delay = base_delay * (2 ** attempt)
            jitter = random.uniform(0, delay * 0.1)
            total_delay = delay + jitter
            
            time.sleep(total_delay)
```

### Circuit Breaker Pattern

```python
from datetime import datetime, timedelta
from enum import Enum

class CircuitState(Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"

class CircuitBreaker:
    def __init__(self, failure_threshold=5, timeout=60):
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.failures = 0
        self.state = CircuitState.CLOSED
        self.last_failure_time = None
        
    def call(self, func, *args, **kwargs):
        if self.state == CircuitState.OPEN:
            if datetime.now() - self.last_failure_time > timedelta(seconds=self.timeout):
                self.state = CircuitState.HALF_OPEN
            else:
                raise Exception("Circuit breaker is OPEN")
                
        try:
            result = func(*args, **kwargs)
            self.on_success()
            return result
        except Exception as e:
            self.on_failure()
            raise
            
    def on_success(self):
        self.failures = 0
        self.state = CircuitState.CLOSED
        
    def on_failure(self):
        self.failures += 1
        self.last_failure_time = datetime.now()
        
        if self.failures >= self.failure_threshold:
            self.state = CircuitState.OPEN
```

## Fallback Strategies

### Model Fallback

```python
class ModelFallbackChain:
    def __init__(self, models):
        self.models = models  # List of (model_name, client) tuples
        
    def generate(self, prompt):
        """Try models in order until one succeeds."""
        last_error = None
        
        for model_name, client in self.models:
            try:
                response = client.chat.completions.create(
                    model=model_name,
                    messages=[{"role": "user", "content": prompt}]
                )
                return response.choices[0].message.content
            except Exception as e:
                last_error = e
                print(f"Model {model_name} failed: {e}")
                continue
                
        raise Exception(f"All models failed. Last error: {last_error}")
```

### Cache Fallback

```python
import pickle
from pathlib import Path

class CachedLLM:
    def __init__(self, client, cache_dir="./cache"):
        self.client = client
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(exist_ok=True)
        
    def get_cache_key(self, prompt):
        import hashlib
        return hashlib.md5(prompt.encode()).hexdigest()
        
    def generate(self, prompt):
        cache_key = self.get_cache_key(prompt)
        cache_file = self.cache_dir / f"{cache_key}.pkl"
        
        # Try cache first
        if cache_file.exists():
            try:
                with open(cache_file, 'rb') as f:
                    return pickle.load(f)
            except Exception:
                pass
                
        # Generate new response
        try:
            response = self.client.chat.completions.create(
                model="gpt-4",
                messages=[{"role": "user", "content": prompt}]
            )
            result = response.choices[0].message.content
            
            # Cache the response
            with open(cache_file, 'wb') as f:
                pickle.dump(result, f)
                
            return result
        except Exception as e:
            # If API fails, try to use stale cache
            if cache_file.exists():
                with open(cache_file, 'rb') as f:
                    return pickle.load(f)
            raise
```

### Degraded Mode

```python
class WorkflowWithDegradedMode:
    def __init__(self, client):
        self.client = client
        self.degraded_mode = False
        
    def process(self, data):
        if self.degraded_mode:
            return self.process_degraded(data)
            
        try:
            return self.process_full(data)
        except Exception as e:
            print(f"Switching to degraded mode: {e}")
            self.degraded_mode = True
            return self.process_degraded(data)
            
    def process_full(self, data):
        """Full processing with AI."""
        response = self.client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": f"Process: {data}"}]
        )
        return response.choices[0].message.content
        
    def process_degraded(self, data):
        """Simplified processing without AI."""
        # Use rule-based logic or simpler processing
        return f"Processed with basic logic: {data}"
```

## Error Logging and Monitoring

### Structured Error Logging

```python
import logging
import json
from datetime import datetime

class WorkflowLogger:
    def __init__(self, name):
        self.logger = logging.getLogger(name)
        handler = logging.FileHandler('workflow_errors.log')
        handler.setFormatter(logging.Formatter('%(message)s'))
        self.logger.addHandler(handler)
        self.logger.setLevel(logging.ERROR)
        
    def log_error(self, error_type, error_message, context):
        log_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'error_type': error_type,
            'error_message': str(error_message),
            'context': context,
            'severity': self.classify_severity(error_type)
        }
        self.logger.error(json.dumps(log_entry))
        
    def classify_severity(self, error_type):
        critical_errors = ['AuthenticationError', 'DataLossError']
        if error_type in critical_errors:
            return 'CRITICAL'
        elif error_type.endswith('Error'):
            return 'ERROR'
        else:
            return 'WARNING'
```

### Error Metrics

```python
from collections import defaultdict
from datetime import datetime, timedelta

class ErrorMetrics:
    def __init__(self):
        self.errors = defaultdict(int)
        self.error_timestamps = defaultdict(list)
        
    def record_error(self, error_type):
        self.errors[error_type] += 1
        self.error_timestamps[error_type].append(datetime.now())
        
    def get_error_rate(self, error_type, window_minutes=60):
        """Calculate error rate over time window."""
        cutoff = datetime.now() - timedelta(minutes=window_minutes)
        recent_errors = [
            ts for ts in self.error_timestamps[error_type]
            if ts > cutoff
        ]
        return len(recent_errors) / window_minutes  # Errors per minute
        
    def get_top_errors(self, n=10):
        """Get most common errors."""
        return sorted(self.errors.items(), key=lambda x: x[1], reverse=True)[:n]
```

## Best Practices

### Fail Fast vs. Fail Safe

```python
# Fail Fast: Detect errors early
def validate_early(data):
    if not data:
        raise ValueError("Data cannot be empty")
    # Continue processing

# Fail Safe: Graceful degradation
def validate_safe(data):
    if not data:
        return default_value()
    # Continue processing
```

### Idempotency

```python
class IdempotentOperation:
    def __init__(self):
        self.completed_operations = set()
        
    def execute(self, operation_id, func, *args, **kwargs):
        """Execute operation only once per ID."""
        if operation_id in self.completed_operations:
            print(f"Operation {operation_id} already completed")
            return None
            
        try:
            result = func(*args, **kwargs)
            self.completed_operations.add(operation_id)
            return result
        except Exception as e:
            # Don't mark as completed on failure
            raise
```

### Dead Letter Queue

```python
class DeadLetterQueue:
    def __init__(self, max_retries=3):
        self.max_retries = max_retries
        self.dead_letters = []
        
    def process_with_dlq(self, item, process_func):
        """Process item with automatic DLQ for failures."""
        retry_count = getattr(item, 'retry_count', 0)
        
        try:
            return process_func(item)
        except Exception as e:
            if retry_count < self.max_retries:
                item.retry_count = retry_count + 1
                # Re-queue for retry
                return self.requeue(item)
            else:
                # Move to dead letter queue
                self.dead_letters.append({
                    'item': item,
                    'error': str(e),
                    'retry_count': retry_count
                })
                return None
```

## Testing Error Handling

### Chaos Engineering

```python
import random

class ChaosMonkey:
    def __init__(self, failure_rate=0.1):
        self.failure_rate = failure_rate
        
    def maybe_fail(self):
        """Randomly inject failures for testing."""
        if random.random() < self.failure_rate:
            raise Exception("Chaos Monkey struck!")
            
    def call_with_chaos(self, func, *args, **kwargs):
        self.maybe_fail()
        return func(*args, **kwargs)
```

## See Also

- [Monitoring](monitoring.md)
- [Best Practices](best-practices.md)
- [Workflow Patterns](workflow-patterns.md)
- [Cost Optimization](cost-optimization.md)
