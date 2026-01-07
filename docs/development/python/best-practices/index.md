---
title: "Python Best Practices"
description: "Documentation for Python Development Best Practices"
author: "Joseph Streeter"
ms.date: "2025-07-18"
ms.topic: "article"
---

## Code Style and Formatting

### PEP 8 Compliance

```python
# Good: Following PEP 8 standards
import os
import sys
from typing import List, Dict, Optional

class DataProcessor:
    """Process and analyze data with various operations."""
    
    def __init__(self, data_source: str, max_items: int = 1000) -> None:
        self.data_source = data_source
        self.max_items = max_items
        self._processed_count = 0
    
    def process_data(self, input_data: List[Dict]) -> List[Dict]:
        """Process input data and return cleaned results."""
        processed_results = []
        
        for item in input_data[:self.max_items]:
            if self._is_valid_item(item):
                cleaned_item = self._clean_item(item)
                processed_results.append(cleaned_item)
                self._processed_count += 1
        
        return processed_results
    
    def _is_valid_item(self, item: Dict) -> bool:
        """Check if item meets validation criteria."""
        required_fields = ['id', 'name', 'timestamp']
        return all(field in item for field in required_fields)
    
    def _clean_item(self, item: Dict) -> Dict:
        """Clean and normalize item data."""
        return {
            'id': str(item['id']).strip(),
            'name': item['name'].title(),
            'timestamp': item['timestamp'],
            'processed_at': time.time()
        }

# Bad: Poor formatting and naming
import os,sys
from typing import *
class dataprocessor:
    def __init__(self,datasource,maxitems=1000):
        self.datasource=datasource
        self.maxitems=maxitems
        self.processedcount=0
    def processdata(self,inputdata):
        processedresults=[]
        for item in inputdata[:self.maxitems]:
            if self.isvaliditem(item):
                cleaneditem=self.cleanitem(item)
                processedresults.append(cleaneditem)
                self.processedcount+=1
        return processedresults
```

### Code Formatting Tools

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/psf/black
    rev: 23.7.0
    hooks:
      - id: black
        language_version: python3.11

  - repo: https://github.com/PyCQA/isort
    rev: 5.12.0
    hooks:
      - id: isort
        args: ["--profile", "black"]

  - repo: https://github.com/PyCQA/flake8
    rev: 6.0.0
    hooks:
      - id: flake8
        additional_dependencies: [flake8-docstrings, flake8-type-checking]

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.5.1
    hooks:
      - id: mypy
        additional_dependencies: [types-requests, types-PyYAML]
```

## Project Structure and Organization

### Standard Project Layout

```text
my_project/
├── README.md
├── pyproject.toml
├── requirements.txt
├── requirements-dev.txt
├── .env.example
├── .gitignore
├── .pre-commit-config.yaml
├── src/
│   └── my_project/
│       ├── __init__.py
│       ├── main.py
│       ├── config/
│       │   ├── __init__.py
│       │   └── settings.py
│       ├── core/
│       │   ├── __init__.py
│       │   ├── models.py
│       │   └── services.py
│       ├── utils/
│       │   ├── __init__.py
│       │   ├── helpers.py
│       │   └── validators.py
│       └── cli/
│           ├── __init__.py
│           └── commands.py
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   ├── unit/
│   │   ├── __init__.py
│   │   ├── test_models.py
│   │   └── test_services.py
│   └── integration/
│       ├── __init__.py
│       └── test_api.py
├── docs/
│   ├── conf.py
│   ├── index.rst
│   └── api/
└── scripts/
    ├── setup.sh
    └── deploy.sh
```

### Configuration Management

```python
# config/settings.py
import os
from pathlib import Path
from typing import Dict, Any
from dataclasses import dataclass
from functools import lru_cache

@dataclass
class DatabaseConfig:
    """Database configuration settings."""
    host: str
    port: int
    name: str
    user: str
    password: str
    ssl_mode: str = "require"
    
    @property
    def connection_string(self) -> str:
        """Generate database connection string."""
        return (
            f"postgresql://{self.user}:{self.password}"
            f"@{self.host}:{self.port}/{self.name}"
            f"?sslmode={self.ssl_mode}"
        )

@dataclass
class AppConfig:
    """Application configuration settings."""
    debug: bool
    secret_key: str
    database: DatabaseConfig
    redis_url: str
    log_level: str = "INFO"
    max_upload_size: int = 10 * 1024 * 1024  # 10MB
    
    @classmethod
    def from_env(cls) -> 'AppConfig':
        """Create configuration from environment variables."""
        database_config = DatabaseConfig(
            host=os.getenv('DB_HOST', 'localhost'),
            port=int(os.getenv('DB_PORT', '5432')),
            name=os.getenv('DB_NAME', 'myapp'),
            user=os.getenv('DB_USER', 'postgres'),
            password=os.getenv('DB_PASSWORD', ''),
            ssl_mode=os.getenv('DB_SSL_MODE', 'require')
        )
        
        return cls(
            debug=os.getenv('DEBUG', 'False').lower() == 'true',
            secret_key=os.getenv('SECRET_KEY', ''),
            database=database_config,
            redis_url=os.getenv('REDIS_URL', 'redis://localhost:6379'),
            log_level=os.getenv('LOG_LEVEL', 'INFO'),
            max_upload_size=int(os.getenv('MAX_UPLOAD_SIZE', '10485760'))
        )

@lru_cache()
def get_config() -> AppConfig:
    """Get cached application configuration."""
    return AppConfig.from_env()
```

## Error Handling and Logging

### Robust Error Handling

```python
import logging
import traceback
from typing import Optional, Type, Union
from contextlib import contextmanager
from functools import wraps

# Custom exceptions with clear hierarchy
class AppError(Exception):
    """Base application exception."""
    def __init__(self, message: str, error_code: Optional[str] = None):
        super().__init__(message)
        self.error_code = error_code
        self.message = message

class ValidationError(AppError):
    """Raised when data validation fails."""
    pass

class DatabaseError(AppError):
    """Raised when database operations fail."""
    pass

class ExternalServiceError(AppError):
    """Raised when external service calls fail."""
    pass

# Error handling decorator
def handle_errors(
    error_types: Union[Type[Exception], tuple] = Exception,
    default_return=None,
    log_errors: bool = True
):
    """Decorator for handling and logging errors."""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            try:
                return func(*args, **kwargs)
            except error_types as e:
                if log_errors:
                    logger = logging.getLogger(func.__module__)
                    logger.error(
                        f"Error in {func.__name__}: {str(e)}",
                        exc_info=True,
                        extra={
                            'function': func.__name__,
                            'args': str(args),
                            'kwargs': str(kwargs)
                        }
                    )
                
                if isinstance(e, AppError):
                    raise  # Re-raise custom exceptions
                
                # Convert to custom exception
                raise AppError(f"Unexpected error in {func.__name__}: {str(e)}")
        
        return wrapper
    return decorator

# Context manager for error handling
@contextmanager
def error_handler(operation_name: str):
    """Context manager for handling errors in operations."""
    logger = logging.getLogger(__name__)
    logger.info(f"Starting operation: {operation_name}")
    
    try:
        yield
        logger.info(f"Operation completed successfully: {operation_name}")
    except Exception as e:
        logger.error(
            f"Operation failed: {operation_name} - {str(e)}",
            exc_info=True
        )
        raise
    finally:
        logger.debug(f"Cleaning up operation: {operation_name}")

# Example usage
class DataService:
    """Service for data operations with robust error handling."""
    
    def __init__(self, database_url: str):
        self.database_url = database_url
        self.logger = logging.getLogger(__name__)
    
    @handle_errors(error_types=(DatabaseError, ValidationError))
    def save_user(self, user_data: dict) -> dict:
        """Save user data with error handling."""
        with error_handler("save_user"):
            # Validate input
            if not user_data.get('email'):
                raise ValidationError("Email is required")
            
            # Simulate database operation
            try:
                # Database save logic here
                result = {'id': 123, **user_data}
                self.logger.info(f"User saved successfully: {result['id']}")
                return result
            except Exception as e:
                raise DatabaseError(f"Failed to save user: {str(e)}")
```

### Structured Logging

```python
import logging
import json
import sys
from datetime import datetime
from typing import Dict, Any

class StructuredFormatter(logging.Formatter):
    """JSON structured logging formatter."""
    
    def format(self, record: logging.LogRecord) -> str:
        """Format log record as structured JSON."""
        log_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'module': record.module,
            'function': record.funcName,
            'line': record.lineno
        }
        
        # Add extra fields
        if hasattr(record, '__dict__'):
            for key, value in record.__dict__.items():
                if key not in ['name', 'msg', 'args', 'levelname', 'levelno',
                              'pathname', 'filename', 'module', 'lineno',
                              'funcName', 'created', 'msecs', 'relativeCreated',
                              'thread', 'threadName', 'processName', 'process',
                              'getMessage', 'exc_info', 'exc_text', 'stack_info']:
                    log_entry[key] = value
        
        # Add exception info
        if record.exc_info:
            log_entry['exception'] = self.formatException(record.exc_info)
        
        return json.dumps(log_entry, ensure_ascii=False)

def setup_logging(level: str = "INFO", structured: bool = True) -> None:
    """Setup application logging configuration."""
    
    # Create logger
    logger = logging.getLogger()
    logger.setLevel(getattr(logging, level.upper()))
    
    # Remove existing handlers
    for handler in logger.handlers[:]:
        logger.removeHandler(handler)
    
    # Create console handler
    console_handler = logging.StreamHandler(sys.stdout)
    
    if structured:
        formatter = StructuredFormatter()
    else:
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
    
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)
    
    # Add file handler for production
    if level.upper() != "DEBUG":
        file_handler = logging.FileHandler('app.log')
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

# Logger utility class
class LoggerMixin:
    """Mixin to provide logging capabilities to classes."""
    
    @property
    def logger(self) -> logging.Logger:
        """Get logger for this class."""
        return logging.getLogger(f"{self.__class__.__module__}.{self.__class__.__name__}")
    
    def log_method_call(self, method_name: str, **kwargs):
        """Log method call with parameters."""
        self.logger.debug(
            f"Calling {method_name}",
            extra={'method': method_name, 'parameters': kwargs}
        )
```

## Testing Best Practices

### Comprehensive Test Strategy

```python
# tests/conftest.py
import pytest
import asyncio
from unittest.mock import Mock, patch
from typing import Generator, AsyncGenerator

@pytest.fixture
def mock_database():
    """Mock database connection."""
    with patch('my_project.database.get_connection') as mock_conn:
        mock_conn.return_value = Mock()
        yield mock_conn.return_value

@pytest.fixture
async def async_client():
    """Async test client fixture."""
    from my_project.app import create_app
    app = create_app(testing=True)
    
    async with app.test_client() as client:
        yield client

@pytest.fixture
def sample_user_data():
    """Sample user data for testing."""
    return {
        'name': 'John Doe',
        'email': 'john.doe@example.com',
        'age': 30,
        'role': 'user'
    }

# tests/unit/test_services.py
import pytest
from unittest.mock import Mock, patch, AsyncMock
from my_project.services import UserService
from my_project.models import User
from my_project.exceptions import ValidationError, DatabaseError

class TestUserService:
    """Test cases for UserService."""
    
    @pytest.fixture
    def user_service(self, mock_database):
        """Create UserService instance with mocked database."""
        return UserService(mock_database)
    
    def test_create_user_success(self, user_service, sample_user_data):
        """Test successful user creation."""
        # Arrange
        user_service.db.save.return_value = {'id': 1, **sample_user_data}
        
        # Act
        result = user_service.create_user(sample_user_data)
        
        # Assert
        assert result['id'] == 1
        assert result['name'] == sample_user_data['name']
        user_service.db.save.assert_called_once()
    
    def test_create_user_validation_error(self, user_service):
        """Test user creation with invalid data."""
        # Arrange
        invalid_data = {'name': ''}  # Missing email
        
        # Act & Assert
        with pytest.raises(ValidationError) as exc_info:
            user_service.create_user(invalid_data)
        
        assert 'email' in str(exc_info.value)
    
    @patch('my_project.services.send_email')
    def test_create_user_with_notification(self, mock_send_email, user_service, sample_user_data):
        """Test user creation with email notification."""
        # Arrange
        user_service.db.save.return_value = {'id': 1, **sample_user_data}
        
        # Act
        result = user_service.create_user(sample_user_data, send_notification=True)
        
        # Assert
        assert result['id'] == 1
        mock_send_email.assert_called_once_with(
            sample_user_data['email'],
            'Welcome!',
            pytest.any(str)
        )
    
    def test_get_user_not_found(self, user_service):
        """Test getting non-existent user."""
        # Arrange
        user_service.db.get.return_value = None
        
        # Act & Assert
        with pytest.raises(ValidationError):
            user_service.get_user(999)

# Property-based testing with Hypothesis
from hypothesis import given, strategies as st

class TestDataValidation:
    """Property-based tests for data validation."""
    
    @given(st.emails())
    def test_email_validation_with_valid_emails(self, email):
        """Test email validation with generated valid emails."""
        from my_project.utils.validators import is_valid_email
        assert is_valid_email(email) is True
    
    @given(st.text().filter(lambda x: '@' not in x))
    def test_email_validation_with_invalid_emails(self, invalid_email):
        """Test email validation with invalid emails."""
        from my_project.utils.validators import is_valid_email
        assert is_valid_email(invalid_email) is False
    
    @given(st.integers(min_value=1, max_value=120))
    def test_age_validation_with_valid_ages(self, age):
        """Test age validation with valid ranges."""
        from my_project.utils.validators import is_valid_age
        assert is_valid_age(age) is True

# Integration tests
class TestUserIntegration:
    """Integration tests for user operations."""
    
    @pytest.mark.integration
    async def test_full_user_workflow(self, async_client, sample_user_data):
        """Test complete user workflow from creation to deletion."""
        # Create user
        response = await async_client.post('/users', json=sample_user_data)
        assert response.status_code == 201
        user_id = response.json['id']
        
        # Get user
        response = await async_client.get(f'/users/{user_id}')
        assert response.status_code == 200
        assert response.json['email'] == sample_user_data['email']
        
        # Update user
        update_data = {'name': 'Jane Doe'}
        response = await async_client.patch(f'/users/{user_id}', json=update_data)
        assert response.status_code == 200
        assert response.json['name'] == 'Jane Doe'
        
        # Delete user
        response = await async_client.delete(f'/users/{user_id}')
        assert response.status_code == 204

# Performance tests
class TestPerformance:
    """Performance and load tests."""
    
    @pytest.mark.performance
    def test_bulk_user_creation_performance(self, user_service):
        """Test performance of bulk user creation."""
        import time
        
        users_data = [
            {'name': f'User {i}', 'email': f'user{i}@example.com'}
            for i in range(1000)
        ]
        
        start_time = time.time()
        results = user_service.create_users_bulk(users_data)
        end_time = time.time()
        
        # Assert all users created
        assert len(results) == 1000
        
        # Assert performance threshold (< 5 seconds for 1000 users)
        execution_time = end_time - start_time
        assert execution_time < 5.0, f"Bulk creation took {execution_time:.2f}s"
```

### Test Configuration

```ini
# pytest.ini
[tool:pytest]
minversion = 6.0
addopts = 
    -ra
    --strict-markers
    --strict-config
    --cov=src
    --cov-report=term-missing
    --cov-report=html
    --cov-report=xml
    --cov-fail-under=80
testpaths = tests
markers =
    unit: Unit tests
    integration: Integration tests
    performance: Performance tests
    slow: Slow running tests
    external: Tests requiring external services
filterwarnings =
    error
    ignore::UserWarning
    ignore::DeprecationWarning
```

## Performance Optimization

### Profiling and Monitoring

```python
import cProfile
import pstats
import functools
import time
import psutil
import asyncio
from typing import Callable, Any
from contextlib import contextmanager

def profile_function(sort_by: str = 'cumulative'):
    """Decorator to profile function execution."""
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            profiler = cProfile.Profile()
            profiler.enable()
            
            try:
                result = func(*args, **kwargs)
                return result
            finally:
                profiler.disable()
                
                # Print profile stats
                stats = pstats.Stats(profiler)
                stats.sort_stats(sort_by)
                stats.print_stats(20)  # Top 20 functions
        
        return wrapper
    return decorator

def time_it(func: Callable) -> Callable:
    """Decorator to measure function execution time."""
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        start_time = time.perf_counter()
        result = func(*args, **kwargs)
        end_time = time.perf_counter()
        
        execution_time = end_time - start_time
        print(f"{func.__name__} executed in {execution_time:.4f} seconds")
        
        return result
    return wrapper

@contextmanager
def memory_monitor(description: str = "Operation"):
    """Context manager to monitor memory usage."""
    process = psutil.Process()
    
    # Get initial memory usage
    initial_memory = process.memory_info().rss / 1024 / 1024  # MB
    print(f"{description} - Initial memory: {initial_memory:.2f} MB")
    
    try:
        yield
    finally:
        # Get final memory usage
        final_memory = process.memory_info().rss / 1024 / 1024  # MB
        memory_diff = final_memory - initial_memory
        print(f"{description} - Final memory: {final_memory:.2f} MB")
        print(f"{description} - Memory difference: {memory_diff:+.2f} MB")

# Async performance utilities
class AsyncPerformanceMonitor:
    """Monitor async operations performance."""
    
    def __init__(self):
        self.operation_times = {}
        self.operation_counts = {}
    
    async def __aenter__(self):
        self.start_time = time.perf_counter()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        self.execution_time = time.perf_counter() - self.start_time
    
    def record_operation(self, operation_name: str, execution_time: float):
        """Record operation performance metrics."""
        if operation_name not in self.operation_times:
            self.operation_times[operation_name] = []
            self.operation_counts[operation_name] = 0
        
        self.operation_times[operation_name].append(execution_time)
        self.operation_counts[operation_name] += 1
    
    def get_stats(self) -> dict:
        """Get performance statistics."""
        stats = {}
        
        for operation, times in self.operation_times.items():
            stats[operation] = {
                'count': self.operation_counts[operation],
                'total_time': sum(times),
                'average_time': sum(times) / len(times),
                'min_time': min(times),
                'max_time': max(times)
            }
        
        return stats

# Example usage
class OptimizedDataProcessor:
    """Data processor with performance optimizations."""
    
    def __init__(self):
        self.cache = {}
        self.performance_monitor = AsyncPerformanceMonitor()
    
    @time_it
    @profile_function()
    def process_large_dataset(self, data: list) -> list:
        """Process large dataset with performance monitoring."""
        with memory_monitor("Large dataset processing"):
            # Use generator for memory efficiency
            return list(self._process_items_generator(data))
    
    def _process_items_generator(self, data: list):
        """Generator for memory-efficient processing."""
        for item in data:
            # Simulate processing
            processed_item = self._process_single_item(item)
            yield processed_item
    
    def _process_single_item(self, item: dict) -> dict:
        """Process single item with caching."""
        cache_key = f"{item.get('id', '')}-{item.get('type', '')}"
        
        if cache_key in self.cache:
            return self.cache[cache_key]
        
        # Simulate expensive operation
        result = {
            'id': item.get('id'),
            'processed': True,
            'timestamp': time.time()
        }
        
        # Cache result
        self.cache[cache_key] = result
        return result
    
    async def async_batch_process(self, items: list, batch_size: int = 100) -> list:
        """Process items in async batches for better performance."""
        results = []
        
        for i in range(0, len(items), batch_size):
            batch = items[i:i + batch_size]
            
            async with AsyncPerformanceMonitor() as monitor:
                batch_results = await asyncio.gather(*[
                    self._async_process_item(item) for item in batch
                ])
                results.extend(batch_results)
            
            self.performance_monitor.record_operation(
                f"batch_process_{len(batch)}", 
                monitor.execution_time
            )
        
        return results
    
    async def _async_process_item(self, item: dict) -> dict:
        """Async processing of single item."""
        # Simulate async operation
        await asyncio.sleep(0.01)
        return self._process_single_item(item)
```

## Security Best Practices

### Input Validation and Sanitization

```python
import re
import html
import bleach
from typing import Any, Dict, List
from urllib.parse import urlparse
from dataclasses import dataclass

@dataclass
class ValidationRule:
    """Data validation rule configuration."""
    field_name: str
    required: bool = False
    data_type: type = str
    min_length: int = 0
    max_length: int = 1000
    regex_pattern: str = None
    allowed_values: List[Any] = None
    custom_validator: callable = None

class SecureValidator:
    """Secure data validation and sanitization."""
    
    EMAIL_PATTERN = re.compile(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    )
    
    # Safe HTML tags for content
    ALLOWED_HTML_TAGS = [
        'p', 'br', 'strong', 'em', 'u', 'ol', 'ul', 'li',
        'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'blockquote'
    ]
    
    ALLOWED_HTML_ATTRIBUTES = {
        '*': ['class'],
        'a': ['href', 'title'],
        'img': ['src', 'alt', 'width', 'height']
    }
    
    @classmethod
    def validate_email(cls, email: str) -> bool:
        """Validate email format."""
        if not email or not isinstance(email, str):
            return False
        return bool(cls.EMAIL_PATTERN.match(email.strip().lower()))
    
    @classmethod
    def validate_url(cls, url: str) -> bool:
        """Validate URL format and safety."""
        try:
            parsed = urlparse(url)
            return bool(
                parsed.scheme in ('http', 'https') and
                parsed.netloc and
                len(url) <= 2048
            )
        except Exception:
            return False
    
    @classmethod
    def sanitize_html(cls, content: str) -> str:
        """Sanitize HTML content to prevent XSS."""
        if not content:
            return ""
        
        # Clean HTML with bleach
        cleaned = bleach.clean(
            content,
            tags=cls.ALLOWED_HTML_TAGS,
            attributes=cls.ALLOWED_HTML_ATTRIBUTES,
            strip=True
        )
        
        return cleaned
    
    @classmethod
    def sanitize_string(cls, value: str, escape_html: bool = True) -> str:
        """Sanitize string input."""
        if not isinstance(value, str):
            return ""
        
        # Strip whitespace
        sanitized = value.strip()
        
        # Escape HTML if requested
        if escape_html:
            sanitized = html.escape(sanitized)
        
        return sanitized
    
    @classmethod
    def validate_data(cls, data: Dict[str, Any], rules: List[ValidationRule]) -> Dict[str, Any]:
        """Validate data against rules."""
        errors = {}
        validated_data = {}
        
        for rule in rules:
            field_value = data.get(rule.field_name)
            
            # Check required fields
            if rule.required and (field_value is None or field_value == ""):
                errors[rule.field_name] = f"{rule.field_name} is required"
                continue
            
            # Skip validation for None values on optional fields
            if field_value is None and not rule.required:
                validated_data[rule.field_name] = None
                continue
            
            # Type validation
            if not isinstance(field_value, rule.data_type):
                try:
                    field_value = rule.data_type(field_value)
                except (ValueError, TypeError):
                    errors[rule.field_name] = f"{rule.field_name} must be of type {rule.data_type.__name__}"
                    continue
            
            # String length validation
            if isinstance(field_value, str):
                if len(field_value) < rule.min_length:
                    errors[rule.field_name] = f"{rule.field_name} must be at least {rule.min_length} characters"
                    continue
                
                if len(field_value) > rule.max_length:
                    errors[rule.field_name] = f"{rule.field_name} must be no more than {rule.max_length} characters"
                    continue
                
                # Sanitize string
                field_value = cls.sanitize_string(field_value)
            
            # Regex pattern validation
            if rule.regex_pattern and isinstance(field_value, str):
                if not re.match(rule.regex_pattern, field_value):
                    errors[rule.field_name] = f"{rule.field_name} format is invalid"
                    continue
            
            # Allowed values validation
            if rule.allowed_values and field_value not in rule.allowed_values:
                errors[rule.field_name] = f"{rule.field_name} must be one of: {', '.join(map(str, rule.allowed_values))}"
                continue
            
            # Custom validation
            if rule.custom_validator:
                try:
                    if not rule.custom_validator(field_value):
                        errors[rule.field_name] = f"{rule.field_name} failed custom validation"
                        continue
                except Exception as e:
                    errors[rule.field_name] = f"{rule.field_name} validation error: {str(e)}"
                    continue
            
            validated_data[rule.field_name] = field_value
        
        if errors:
            raise ValidationError(f"Validation failed: {errors}")
        
        return validated_data

# Example secure API endpoint
from flask import Flask, request, jsonify
import hashlib
import secrets

class SecureUserAPI:
    """Secure user API with validation and rate limiting."""
    
    def __init__(self):
        self.rate_limit_store = {}  # In production, use Redis
        self.user_validation_rules = [
            ValidationRule('name', required=True, min_length=2, max_length=100),
            ValidationRule('email', required=True, max_length=255, 
                         custom_validator=SecureValidator.validate_email),
            ValidationRule('age', required=False, data_type=int),
            ValidationRule('role', required=True, 
                         allowed_values=['user', 'admin', 'moderator'])
        ]
    
    def create_user(self, request_data: dict) -> dict:
        """Create user with secure validation."""
        try:
            # Rate limiting check
            client_ip = request.environ.get('REMOTE_ADDR', 'unknown')
            if not self._check_rate_limit(client_ip):
                raise SecurityError("Rate limit exceeded")
            
            # Validate and sanitize input
            validated_data = SecureValidator.validate_data(
                request_data, 
                self.user_validation_rules
            )
            
            # Hash sensitive data
            if 'password' in request_data:
                validated_data['password_hash'] = self._hash_password(
                    request_data['password']
                )
            
            # Generate secure token
            validated_data['user_token'] = self._generate_secure_token()
            
            # Save user (implementation depends on your database)
            user_id = self._save_user(validated_data)
            
            return {
                'id': user_id,
                'name': validated_data['name'],
                'email': validated_data['email'],
                'role': validated_data['role'],
                'token': validated_data['user_token']
            }
            
        except ValidationError as e:
            raise APIError(f"Validation failed: {str(e)}", status_code=400)
        except Exception as e:
            # Log error but don't expose details
            logging.error(f"User creation failed: {str(e)}")
            raise APIError("Internal server error", status_code=500)
    
    def _check_rate_limit(self, client_ip: str) -> bool:
        """Simple rate limiting implementation."""
        current_time = time.time()
        window_start = current_time - 3600  # 1 hour window
        
        if client_ip not in self.rate_limit_store:
            self.rate_limit_store[client_ip] = []
        
        # Clean old requests
        self.rate_limit_store[client_ip] = [
            req_time for req_time in self.rate_limit_store[client_ip]
            if req_time > window_start
        ]
        
        # Check limit (100 requests per hour)
        if len(self.rate_limit_store[client_ip]) >= 100:
            return False
        
        # Record current request
        self.rate_limit_store[client_ip].append(current_time)
        return True
    
    def _hash_password(self, password: str) -> str:
        """Securely hash password with salt."""
        salt = secrets.token_hex(16)
        password_hash = hashlib.pbkdf2_hmac(
            'sha256',
            password.encode('utf-8'),
            salt.encode('utf-8'),
            100000  # iterations
        )
        return f"{salt}:{password_hash.hex()}"
    
    def _generate_secure_token(self) -> str:
        """Generate cryptographically secure token."""
        return secrets.token_urlsafe(32)
```

## Dependency Management

### Modern Dependency Management with Poetry

```toml
# pyproject.toml
[tool.poetry]
name = "my-project"
version = "1.0.0"
description = "A modern Python project"
authors = ["Your Name <you@example.com>"]
readme = "README.md"
packages = [{include = "my_project", from = "src"}]

[tool.poetry.dependencies]
python = "^3.11"
fastapi = "^0.104.1"
pydantic = "^2.5.0"
sqlalchemy = "^2.0.23"
alembic = "^1.13.1"
redis = "^5.0.1"
celery = "^5.3.4"
requests = "^2.31.0"
python-multipart = "^0.0.6"
uvicorn = {extras = ["standard"], version = "^0.24.0"}

[tool.poetry.group.dev.dependencies]
pytest = "^7.4.3"
pytest-asyncio = "^0.21.1"
pytest-cov = "^4.1.0"
black = "^23.11.0"
isort = "^5.12.0"
flake8 = "^6.1.0"
mypy = "^1.7.1"
pre-commit = "^3.6.0"
hypothesis = "^6.92.1"

[tool.poetry.group.docs.dependencies]
sphinx = "^7.2.6"
sphinx-rtd-theme = "^1.3.0"
sphinx-autodoc-typehints = "^1.25.2"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"

[tool.black]
line-length = 88
target-version = ['py311']
include = '\.pyi?$'
extend-exclude = '''
/(
  # directories
  \.eggs
  | \.git
  | \.hg
  | \.mypy_cache
  | \.tox
  | \.venv
  | build
  | dist
)/
'''

[tool.isort]
profile = "black"
multi_line_output = 3
line_length = 88
known_first_party = ["my_project"]

[tool.mypy]
python_version = "3.11"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
disallow_incomplete_defs = true
check_untyped_defs = true
disallow_untyped_decorators = true
no_implicit_optional = true
warn_redundant_casts = true
warn_unused_ignores = true
warn_no_return = true
warn_unreachable = true
strict_equality = true

[tool.coverage.run]
source = ["src"]
omit = ["*/tests/*", "*/test_*.py"]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "if self.debug:",
    "if settings.DEBUG",
    "raise AssertionError",
    "raise NotImplementedError",
    "if 0:",
    "if __name__ == .__main__.:"
]
```

## Documentation Standards

### Comprehensive Documentation with Sphinx

```python
# docs/conf.py
import os
import sys
sys.path.insert(0, os.path.abspath('../src'))

project = 'My Project'
copyright = '2024, Your Name'
author = 'Your Name'
release = '1.0.0'

extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.autosummary',
    'sphinx.ext.viewcode',
    'sphinx.ext.napoleon',
    'sphinx_autodoc_typehints',
    'sphinx.ext.intersphinx'
]

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

html_theme = 'sphinx_rtd_theme'
html_static_path = ['_static']

# Napoleon settings
napoleon_google_docstring = True
napoleon_numpy_docstring = True
napoleon_include_init_with_doc = False
napoleon_include_private_with_doc = False

# Autodoc settings
autodoc_default_options = {
    'members': True,
    'member-order': 'bysource',
    'special-members': '__init__',
    'undoc-members': True,
    'exclude-members': '__weakref__'
}

# Intersphinx mapping
intersphinx_mapping = {
    'python': ('https://docs.python.org/3', None),
    'requests': ('https://requests.readthedocs.io/en/latest/', None),
}
```

## Related Topics

- [Python Web Development](../web-development/index.md)
- [Python Data Science](../data-science/index.md)
- [Package Management](../package-management/index.md)
- [Flask Development](../web-development/flask.md)
