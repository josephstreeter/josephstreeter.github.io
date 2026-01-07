---
title: Integration Testing in Python
description: Comprehensive guide to integration testing in Python including database testing, API testing, service integration, and test environment management
---

Integration testing verifies that different components, services, and systems work together correctly. Unlike unit tests that isolate individual functions, integration tests validate the interactions between modules, databases, external APIs, and other system boundaries to ensure end-to-end functionality.

## Overview

Integration testing sits between unit testing and end-to-end testing in the testing pyramid. While unit tests verify isolated logic with mocked dependencies, integration tests use real implementations of databases, message queues, caches, and external services to validate that components integrate properly. This approach catches issues that emerge only when systems interact, such as database transaction problems, API contract violations, or network failures.

Modern Python integration testing leverages powerful frameworks like pytest with specialized plugins (pytest-django, pytest-asyncio), containerization with Docker for isolated test environments, and test fixtures that manage complex setup and teardown of resources. The goal is to achieve high confidence in system behavior while maintaining reasonable test execution speed and reliability.

## Why Integration Testing Matters

### Benefits

- **Catch Integration Issues**: Detect problems that emerge only when components interact
- **Validate Database Operations**: Test real SQL queries, transactions, and constraints
- **Verify API Contracts**: Ensure API endpoints match expected behavior and data formats
- **Test Configuration**: Validate that services are configured correctly for integration
- **Discover Race Conditions**: Find concurrency issues that unit tests miss
- **Ensure Data Flow**: Verify data transformations across system boundaries
- **Build Confidence**: Increase certainty that the system works as a whole

### Challenges

- **Slower Execution**: Integration tests are slower than unit tests
- **Test Data Management**: Requires careful setup and cleanup of test data
- **Environment Dependencies**: Needs databases, services, or external systems
- **Flakiness**: Network issues or timing problems can cause intermittent failures
- **Debugging Complexity**: Failures may involve multiple components
- **Resource Intensive**: Requires more CPU, memory, and infrastructure

## Integration Testing Strategies

### Testing Pyramid Application

**Unit Tests (70-80%)**: Fast, isolated tests of individual functions

**Integration Tests (15-20%)**: Test component interactions with real dependencies

**End-to-End Tests (5-10%)**: Full user workflows through the entire system

### Layer-Based Testing

```text
┌─────────────────────────────────────┐
│     Presentation Layer (API)        │
├─────────────────────────────────────┤
│     Business Logic Layer            │
├─────────────────────────────────────┤
│     Data Access Layer (DAL)         │
├─────────────────────────────────────┤
│     Database / External Services    │
└─────────────────────────────────────┘

Integration test boundaries:
- API ↔ Business Logic
- Business Logic ↔ Data Access Layer
- Data Access Layer ↔ Database
- Business Logic ↔ External Services
```

### Test Scope Strategies

**Narrow Integration Tests**: Test interaction between 2-3 components

```python
def test_user_repository_saves_to_database(db_session):
    """Test repository interacts correctly with database."""
    repo = UserRepository(db_session)
    user = User(username="testuser", email="test@example.com")
    
    saved_user = repo.save(user)
    
    # Verify database interaction
    retrieved = db_session.query(User).filter_by(username="testuser").first()
    assert retrieved.email == "test@example.com"
    assert retrieved.id == saved_user.id
```

**Broad Integration Tests**: Test multiple layers working together

```python
def test_user_registration_flow(api_client, db_session):
    """Test complete user registration through API to database."""
    response = api_client.post('/api/register', json={
        'username': 'newuser',
        'email': 'new@example.com',
        'password': 'securepass123'
    })
    
    assert response.status_code == 201
    
    # Verify user in database
    user = db_session.query(User).filter_by(username='newuser').first()
    assert user is not None
    assert user.email == 'new@example.com'
    assert user.check_password('securepass123')
```

## Database Integration Testing

### Test Database Strategies

#### In-Memory Databases

**SQLite in Memory**: Fast but limited SQL feature support

```python
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from myapp.models import Base

@pytest.fixture(scope="function")
def db_session():
    """Create fresh in-memory database for each test."""
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    session = Session()
    
    yield session
    
    session.close()
    engine.dispose()

def test_user_creation(db_session):
    from myapp.models import User
    
    user = User(username="alice", email="alice@example.com")
    db_session.add(user)
    db_session.commit()
    
    retrieved = db_session.query(User).filter_by(username="alice").first()
    assert retrieved.email == "alice@example.com"
```

#### Docker Test Databases

**PostgreSQL with Docker**: Production-like database for tests

```python
import pytest
import docker
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from myapp.models import Base

@pytest.fixture(scope="session")
def postgres_container():
    """Start PostgreSQL container for test session."""
    client = docker.from_env()
    
    container = client.containers.run(
        "postgres:15",
        environment={
            "POSTGRES_USER": "test",
            "POSTGRES_PASSWORD": "test",
            "POSTGRES_DB": "testdb"
        },
        ports={'5432/tcp': 5433},
        detach=True,
        remove=True
    )
    
    # Wait for PostgreSQL to be ready
    import time
    time.sleep(3)
    
    yield container
    
    container.stop()

@pytest.fixture(scope="function")
def db_session(postgres_container):
    """Create database session with schema."""
    engine = create_engine("postgresql://test:test@localhost:5433/testdb")
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    session = Session()
    
    yield session
    
    session.rollback()
    session.close()
    Base.metadata.drop_all(engine)
```

#### Testcontainers

**Modern Container Management**: Pythonic API for Docker-based tests

```python
import pytest
from testcontainers.postgres import PostgresContainer
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

@pytest.fixture(scope="session")
def postgres():
    """Manage PostgreSQL test container."""
    with PostgresContainer("postgres:15") as postgres:
        yield postgres

@pytest.fixture(scope="function")
def db_session(postgres):
    """Create clean database session for each test."""
    engine = create_engine(postgres.get_connection_url())
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    session = Session()
    
    yield session
    
    session.close()
    Base.metadata.drop_all(engine)
    engine.dispose()
```

### Transaction Management

#### Automatic Rollback Pattern

```python
@pytest.fixture(scope="function")
def db_session():
    """Session that automatically rolls back after test."""
    connection = engine.connect()
    transaction = connection.begin()
    session = Session(bind=connection)
    
    yield session
    
    session.close()
    transaction.rollback()
    connection.close()

def test_user_operations(db_session):
    """Changes are automatically rolled back."""
    user = User(username="temp")
    db_session.add(user)
    db_session.commit()
    
    assert db_session.query(User).count() == 1
    # After test, rollback removes all changes
```

#### Nested Transactions with Savepoints

```python
def test_nested_transaction_rollback(db_session):
    """Test transaction rollback behavior."""
    user = User(username="user1")
    db_session.add(user)
    db_session.commit()
    
    # Create savepoint
    savepoint = db_session.begin_nested()
    
    user2 = User(username="user2")
    db_session.add(user2)
    db_session.flush()
    
    assert db_session.query(User).count() == 2
    
    # Rollback to savepoint
    savepoint.rollback()
    
    assert db_session.query(User).count() == 1
```

### Complex Query Testing

```python
def test_complex_join_query(db_session):
    """Test multi-table join with aggregation."""
    # Setup test data
    user = User(username="alice")
    db_session.add(user)
    
    for i in range(5):
        order = Order(user=user, total=100.0 * (i + 1))
        db_session.add(order)
    
    db_session.commit()
    
    # Test complex query
    result = db_session.query(
        User.username,
        func.count(Order.id).label('order_count'),
        func.sum(Order.total).label('total_spent')
    ).join(Order).group_by(User.username).first()
    
    assert result.username == "alice"
    assert result.order_count == 5
    assert result.total_spent == 1500.0
```

### Database Constraint Testing

```python
def test_unique_constraint_violation(db_session):
    """Test that database enforces unique constraints."""
    from sqlalchemy.exc import IntegrityError
    
    user1 = User(username="alice", email="alice@example.com")
    db_session.add(user1)
    db_session.commit()
    
    # Attempt duplicate username
    user2 = User(username="alice", email="different@example.com")
    db_session.add(user2)
    
    with pytest.raises(IntegrityError):
        db_session.commit()

def test_foreign_key_constraint(db_session):
    """Test foreign key relationships."""
    # Attempt to create order without user
    order = Order(user_id=99999, total=100.0)
    db_session.add(order)
    
    with pytest.raises(IntegrityError):
        db_session.commit()
```

### Django Database Testing

```python
import pytest
from django.contrib.auth.models import User
from myapp.models import Order

@pytest.mark.django_db
def test_user_order_creation():
    """Test Django ORM operations."""
    user = User.objects.create_user(
        username='testuser',
        email='test@example.com',
        password='testpass123'
    )
    
    order = Order.objects.create(
        user=user,
        total=150.00
    )
    
    assert Order.objects.filter(user=user).count() == 1
    assert order.total == 150.00

@pytest.mark.django_db(transaction=True)
def test_transaction_rollback():
    """Test with transaction support."""
    from django.db import transaction
    
    user = User.objects.create_user(username='user1')
    
    try:
        with transaction.atomic():
            User.objects.create_user(username='user2')
            raise ValueError("Force rollback")
    except ValueError:
        pass
    
    # Only user1 should exist
    assert User.objects.count() == 1
```

## API Integration Testing

### REST API Testing

#### Flask Testing

```python
import pytest
from myapp import create_app
from myapp.database import db

@pytest.fixture
def app():
    """Create Flask app configured for testing."""
    app = create_app('testing')
    
    with app.app_context():
        db.create_all()
        yield app
        db.drop_all()

@pytest.fixture
def client(app):
    """Create Flask test client."""
    return app.test_client()

def test_user_registration_api(client):
    """Test user registration endpoint."""
    response = client.post('/api/register', json={
        'username': 'newuser',
        'email': 'new@example.com',
        'password': 'securepass123'
    })
    
    assert response.status_code == 201
    data = response.json
    assert data['username'] == 'newuser'
    assert 'password' not in data
    assert 'id' in data

def test_user_login_api(client):
    """Test login endpoint."""
    # Register user first
    client.post('/api/register', json={
        'username': 'testuser',
        'email': 'test@example.com',
        'password': 'testpass123'
    })
    
    # Test login
    response = client.post('/api/login', json={
        'username': 'testuser',
        'password': 'testpass123'
    })
    
    assert response.status_code == 200
    data = response.json
    assert 'access_token' in data
    assert 'refresh_token' in data

def test_protected_endpoint(client):
    """Test authentication required endpoint."""
    response = client.get('/api/profile')
    assert response.status_code == 401
    
    # Login and get token
    login_response = client.post('/api/login', json={
        'username': 'testuser',
        'password': 'testpass123'
    })
    token = login_response.json['access_token']
    
    # Access with token
    response = client.get(
        '/api/profile',
        headers={'Authorization': f'Bearer {token}'}
    )
    assert response.status_code == 200
```

#### FastAPI Testing

```python
import pytest
from fastapi.testclient import TestClient
from myapp.main import app
from myapp.database import get_db, Base, engine

@pytest.fixture(scope="function")
def db_session():
    """Create test database session."""
    Base.metadata.create_all(bind=engine)
    
    yield
    
    Base.metadata.drop_all(bind=engine)

@pytest.fixture
def client(db_session):
    """Create FastAPI test client."""
    return TestClient(app)

def test_create_item(client):
    """Test item creation endpoint."""
    response = client.post(
        "/items/",
        json={"name": "Test Item", "price": 29.99, "description": "A test item"}
    )
    
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Test Item"
    assert data["price"] == 29.99
    assert "id" in data

def test_list_items(client):
    """Test items listing with pagination."""
    # Create test items
    for i in range(15):
        client.post("/items/", json={
            "name": f"Item {i}",
            "price": 10.0 * (i + 1)
        })
    
    # Test pagination
    response = client.get("/items/?skip=0&limit=10")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 10
    
    response = client.get("/items/?skip=10&limit=10")
    assert len(response.json()) == 5

@pytest.mark.asyncio
async def test_async_endpoint(client):
    """Test asynchronous endpoint."""
    response = client.get("/async/data")
    assert response.status_code == 200
```

#### Django REST Framework Testing

```python
import pytest
from rest_framework.test import APIClient
from django.contrib.auth.models import User

@pytest.fixture
def api_client():
    """Create DRF API client."""
    return APIClient()

@pytest.fixture
def authenticated_client(api_client):
    """Create authenticated API client."""
    user = User.objects.create_user(
        username='testuser',
        password='testpass123'
    )
    api_client.force_authenticate(user=user)
    return api_client

@pytest.mark.django_db
def test_create_post(authenticated_client):
    """Test creating post via API."""
    response = authenticated_client.post('/api/posts/', {
        'title': 'Test Post',
        'content': 'This is test content.'
    })
    
    assert response.status_code == 201
    assert response.data['title'] == 'Test Post'

@pytest.mark.django_db
def test_list_posts_with_filtering(api_client):
    """Test list endpoint with filters."""
    # Create test data
    user = User.objects.create_user(username='author')
    for i in range(5):
        Post.objects.create(
            title=f'Post {i}',
            author=user,
            published=i % 2 == 0
        )
    
    # Test filtering
    response = api_client.get('/api/posts/?published=true')
    assert response.status_code == 200
    assert len(response.data) == 3
```

### GraphQL API Testing

```python
import pytest
from graphene.test import Client
from myapp.schema import schema

@pytest.fixture
def graphql_client():
    """Create GraphQL test client."""
    return Client(schema)

def test_query_users(graphql_client, db_session):
    """Test GraphQL user query."""
    # Create test data
    user = User(username="alice", email="alice@example.com")
    db_session.add(user)
    db_session.commit()
    
    # Execute query
    query = """
        query {
            users {
                username
                email
            }
        }
    """
    
    result = graphql_client.execute(query)
    assert not result.get('errors')
    assert len(result['data']['users']) == 1
    assert result['data']['users'][0]['username'] == 'alice'

def test_mutation_create_user(graphql_client):
    """Test GraphQL mutation."""
    mutation = """
        mutation {
            createUser(username: "bob", email: "bob@example.com") {
                user {
                    id
                    username
                    email
                }
            }
        }
    """
    
    result = graphql_client.execute(mutation)
    assert not result.get('errors')
    assert result['data']['createUser']['user']['username'] == 'bob'
```

## External Service Integration

### HTTP Service Mocking

#### responses Library

```python
import pytest
import responses
import requests

@responses.activate
def test_external_api_call():
    """Test code that calls external API."""
    responses.add(
        responses.GET,
        'https://api.example.com/users/1',
        json={'id': 1, 'name': 'John Doe'},
        status=200
    )
    
    result = fetch_user_data(1)
    
    assert result['name'] == 'John Doe'
    assert len(responses.calls) == 1
    assert responses.calls[0].request.url == 'https://api.example.com/users/1'

@responses.activate
def test_api_error_handling():
    """Test handling of API errors."""
    responses.add(
        responses.GET,
        'https://api.example.com/users/999',
        json={'error': 'User not found'},
        status=404
    )
    
    with pytest.raises(UserNotFoundError):
        fetch_user_data(999)
```

#### VCR.py - Record and Replay

```python
import pytest
import vcr

my_vcr = vcr.VCR(
    cassette_library_dir='tests/fixtures/vcr_cassettes',
    record_mode='once'
)

@my_vcr.use_cassette('get_user.yaml')
def test_real_api_call():
    """Test using recorded real API response."""
    result = fetch_user_from_github('octocat')
    
    assert result['login'] == 'octocat'
    assert 'id' in result

@my_vcr.use_cassette('api_rate_limit.yaml')
def test_rate_limit_handling():
    """Test API rate limit handling."""
    with pytest.raises(RateLimitExceeded):
        for i in range(100):
            fetch_user_from_github(f'user{i}')
```

### Message Queue Testing

#### Redis/Celery Integration

```python
import pytest
from celery import Celery
from testcontainers.redis import RedisContainer

@pytest.fixture(scope="session")
def redis_container():
    """Start Redis container."""
    with RedisContainer() as redis:
        yield redis

@pytest.fixture
def celery_app(redis_container):
    """Create Celery app with test broker."""
    app = Celery('tasks', broker=redis_container.get_connection_url())
    app.conf.task_always_eager = True
    app.conf.task_eager_propagates = True
    return app

def test_async_task_execution(celery_app):
    """Test Celery task execution."""
    from myapp.tasks import process_order
    
    result = process_order.delay(order_id=123)
    
    assert result.successful()
    assert result.result == {'status': 'processed', 'order_id': 123}

def test_task_retry_on_failure(celery_app, mocker):
    """Test task retry behavior."""
    from myapp.tasks import send_email
    
    mock_send = mocker.patch('myapp.email.send')
    mock_send.side_effect = [ConnectionError(), ConnectionError(), None]
    
    result = send_email.delay(to='test@example.com', subject='Test')
    
    assert result.successful()
    assert mock_send.call_count == 3
```

#### RabbitMQ Integration

```python
import pytest
from testcontainers.rabbitmq import RabbitMQContainer
import pika

@pytest.fixture(scope="session")
def rabbitmq():
    """Start RabbitMQ container."""
    with RabbitMQContainer() as rabbitmq:
        yield rabbitmq

def test_message_publishing(rabbitmq):
    """Test publishing messages to RabbitMQ."""
    connection = pika.BlockingConnection(
        pika.URLParameters(rabbitmq.get_connection_url())
    )
    channel = connection.channel()
    channel.queue_declare(queue='test_queue')
    
    # Publish message
    channel.basic_publish(
        exchange='',
        routing_key='test_queue',
        body='Test message'
    )
    
    # Consume message
    method, properties, body = channel.basic_get('test_queue')
    
    assert body.decode() == 'Test message'
    connection.close()
```

### Cache Integration Testing

#### Redis Cache

```python
import pytest
from testcontainers.redis import RedisContainer
import redis

@pytest.fixture(scope="function")
def redis_client():
    """Create Redis test client."""
    with RedisContainer() as redis_container:
        client = redis.from_url(redis_container.get_connection_url())
        yield client
        client.flushdb()

def test_cache_set_get(redis_client):
    """Test basic cache operations."""
    from myapp.cache import CacheService
    
    cache = CacheService(redis_client)
    cache.set('user:1', {'name': 'Alice', 'email': 'alice@example.com'})
    
    result = cache.get('user:1')
    assert result['name'] == 'Alice'

def test_cache_expiration(redis_client):
    """Test cache TTL."""
    import time
    
    redis_client.setex('temp_key', 1, 'temp_value')
    assert redis_client.get('temp_key') == b'temp_value'
    
    time.sleep(1.1)
    assert redis_client.get('temp_key') is None
```

### S3/Object Storage Testing

```python
import pytest
from testcontainers.minio import MinioContainer
from minio import Minio

@pytest.fixture(scope="session")
def s3_storage():
    """Start MinIO (S3-compatible) container."""
    with MinioContainer() as minio:
        client = Minio(
            minio.get_connection_url(),
            access_key=minio.access_key,
            secret_key=minio.secret_key,
            secure=False
        )
        client.make_bucket("test-bucket")
        yield client

def test_file_upload(s3_storage):
    """Test uploading file to S3."""
    from io import BytesIO
    
    data = BytesIO(b"test file content")
    s3_storage.put_object(
        "test-bucket",
        "test.txt",
        data,
        len(b"test file content")
    )
    
    # Verify upload
    response = s3_storage.get_object("test-bucket", "test.txt")
    content = response.read()
    assert content == b"test file content"
```

## Asynchronous Integration Testing

### Testing Async Functions

```python
import pytest
import asyncio
from httpx import AsyncClient
from myapp.main import app

@pytest.mark.asyncio
async def test_async_api_endpoint():
    """Test async FastAPI endpoint."""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/async/users")
        assert response.status_code == 200
        assert len(response.json()) > 0

@pytest.mark.asyncio
async def test_concurrent_requests():
    """Test handling concurrent requests."""
    async with AsyncClient(app=app, base_url="http://test") as client:
        responses = await asyncio.gather(
            client.get("/users/1"),
            client.get("/users/2"),
            client.get("/users/3"),
        )
        
        assert all(r.status_code == 200 for r in responses)
```

### WebSocket Testing

```python
import pytest
from fastapi.testclient import TestClient

def test_websocket_communication():
    """Test WebSocket endpoint."""
    client = TestClient(app)
    
    with client.websocket_connect("/ws") as websocket:
        # Send message
        websocket.send_json({"type": "ping"})
        
        # Receive response
        data = websocket.receive_json()
        assert data["type"] == "pong"

@pytest.mark.asyncio
async def test_websocket_broadcast():
    """Test WebSocket message broadcasting."""
    async with AsyncClient(app=app, base_url="http://test") as client1:
        async with client1.websocket_connect("/ws/chat") as ws1:
            async with AsyncClient(app=app, base_url="http://test") as client2:
                async with client2.websocket_connect("/ws/chat") as ws2:
                    # Send from client 1
                    await ws1.send_json({"message": "Hello"})
                    
                    # Receive on client 2
                    data = await ws2.receive_json()
                    assert data["message"] == "Hello"
```

## Test Data Management

### Factory Pattern

#### factory_boy

```python
import factory
from myapp.models import User, Order, Product

class UserFactory(factory.Factory):
    class Meta:
        model = User
    
    username = factory.Sequence(lambda n: f'user{n}')
    email = factory.LazyAttribute(lambda obj: f'{obj.username}@example.com')
    is_active = True

class ProductFactory(factory.Factory):
    class Meta:
        model = Product
    
    name = factory.Sequence(lambda n: f'Product {n}')
    price = factory.Faker('pydecimal', left_digits=3, right_digits=2, positive=True)
    stock = factory.Faker('pyint', min_value=0, max_value=1000)

class OrderFactory(factory.Factory):
    class Meta:
        model = Order
    
    user = factory.SubFactory(UserFactory)
    product = factory.SubFactory(ProductFactory)
    quantity = factory.Faker('pyint', min_value=1, max_value=10)
    
    @factory.lazy_attribute
    def total(self):
        return self.product.price * self.quantity

# Usage in tests
def test_order_creation(db_session):
    order = OrderFactory()
    db_session.add(order)
    db_session.commit()
    
    assert order.user.username.startswith('user')
    assert order.total == order.product.price * order.quantity
```

### Faker for Realistic Data

```python
import pytest
from faker import Faker

@pytest.fixture
def fake():
    """Provide Faker instance."""
    return Faker()

def test_user_with_realistic_data(fake, db_session):
    """Test with realistic generated data."""
    user = User(
        username=fake.user_name(),
        email=fake.email(),
        first_name=fake.first_name(),
        last_name=fake.last_name(),
        address=fake.address(),
        phone=fake.phone_number()
    )
    
    db_session.add(user)
    db_session.commit()
    
    assert '@' in user.email
    assert len(user.first_name) > 0
```

### Fixture Files

```python
import pytest
import json
from pathlib import Path

@pytest.fixture
def sample_data():
    """Load sample data from JSON file."""
    fixture_path = Path(__file__).parent / 'fixtures' / 'users.json'
    with open(fixture_path) as f:
        return json.load(f)

def test_bulk_user_import(sample_data, db_session):
    """Test importing users from fixture data."""
    from myapp.services import UserImportService
    
    service = UserImportService(db_session)
    imported = service.import_users(sample_data)
    
    assert len(imported) == len(sample_data)
    assert db_session.query(User).count() == len(sample_data)
```

## Test Environment Configuration

### Environment Variables

```python
import pytest
import os

@pytest.fixture(autouse=True)
def test_environment():
    """Set test environment variables."""
    original_env = os.environ.copy()
    
    os.environ['ENV'] = 'testing'
    os.environ['DATABASE_URL'] = 'postgresql://test:test@localhost:5433/testdb'
    os.environ['REDIS_URL'] = 'redis://localhost:6380'
    os.environ['DEBUG'] = 'True'
    
    yield
    
    os.environ.clear()
    os.environ.update(original_env)
```

### Configuration Files

```python
# conftest.py
import pytest
from myapp import create_app
from myapp.config import TestingConfig

@pytest.fixture(scope="session")
def app():
    """Create app with testing configuration."""
    app = create_app(TestingConfig)
    
    with app.app_context():
        yield app
```

```python
# config.py
class TestingConfig:
    TESTING = True
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'
    WTF_CSRF_ENABLED = False
    CELERY_TASK_ALWAYS_EAGER = True
```

### Docker Compose for Integration Tests

```yaml
# docker-compose.test.yml
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test
      POSTGRES_DB: testdb
    ports:
      - "5433:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U test"]
      interval: 5s
      timeout: 5s
      retries: 5
  
  redis:
    image: redis:7
    ports:
      - "6380:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5
  
  rabbitmq:
    image: rabbitmq:3-management
    ports:
      - "5673:5672"
      - "15673:15672"
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5
```

Run tests with:

```bash
docker-compose -f docker-compose.test.yml up -d
pytest tests/integration/
docker-compose -f docker-compose.test.yml down
```

## Best Practices

### Test Isolation

```python
# Good: Each test is independent
@pytest.fixture
def user(db_session):
    user = User(username="testuser")
    db_session.add(user)
    db_session.commit()
    return user

def test_user_update(user, db_session):
    user.email = "new@example.com"
    db_session.commit()
    assert user.email == "new@example.com"

def test_user_deletion(user, db_session):
    db_session.delete(user)
    db_session.commit()
    assert db_session.query(User).filter_by(username="testuser").first() is None
```

### Clean Test Data

```python
@pytest.fixture(autouse=True)
def cleanup_test_data(db_session):
    """Clean up after each test."""
    yield
    
    # Cleanup order matters due to foreign keys
    db_session.query(Order).delete()
    db_session.query(Product).delete()
    db_session.query(User).delete()
    db_session.commit()
```

### Meaningful Assertions

```python
# Bad: Vague assertion
def test_api_response(client):
    response = client.get('/api/users')
    assert response.status_code == 200

# Good: Specific assertions
def test_api_response(client):
    response = client.get('/api/users')
    assert response.status_code == 200
    assert response.content_type == 'application/json'
    
    data = response.json
    assert isinstance(data, list)
    assert len(data) > 0
    assert all('id' in user for user in data)
    assert all('username' in user for user in data)
```

### Test Organization

```text
tests/
├── conftest.py                 # Shared fixtures
├── unit/                       # Unit tests
│   ├── test_models.py
│   └── test_services.py
├── integration/                # Integration tests
│   ├── conftest.py            # Integration fixtures
│   ├── test_database.py
│   ├── test_api.py
│   └── test_external_services.py
└── fixtures/                   # Test data
    ├── users.json
    └── products.json
```

### Avoid Test Interdependence

```python
# Bad: Tests depend on execution order
def test_01_create_user():
    global user_id
    response = client.post('/api/users', json={'username': 'test'})
    user_id = response.json['id']

def test_02_update_user():
    response = client.put(f'/api/users/{user_id}', json={'email': 'new@example.com'})
    assert response.status_code == 200

# Good: Each test is independent
@pytest.fixture
def created_user(client):
    response = client.post('/api/users', json={'username': 'test'})
    return response.json

def test_update_user(client, created_user):
    response = client.put(
        f'/api/users/{created_user["id"]}',
        json={'email': 'new@example.com'}
    )
    assert response.status_code == 200
```

### Performance Considerations

```python
# Use session-scoped fixtures for expensive operations
@pytest.fixture(scope="session")
def database_schema():
    """Create schema once for entire test session."""
    engine = create_engine(TEST_DATABASE_URL)
    Base.metadata.create_all(engine)
    yield
    Base.metadata.drop_all(engine)

# Use function-scoped for data cleanup
@pytest.fixture(scope="function")
def db_session(database_schema):
    """Provide clean session for each test."""
    connection = engine.connect()
    transaction = connection.begin()
    session = Session(bind=connection)
    
    yield session
    
    session.close()
    transaction.rollback()
    connection.close()
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  integration-tests:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: testdb
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      
      redis:
        image: redis:7
        ports:
          - 6379:6379
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          pip install -r requirements-test.txt
      
      - name: Run integration tests
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/testdb
          REDIS_URL: redis://localhost:6379
        run: |
          pytest tests/integration/ -v --cov=myapp --cov-report=xml
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

### GitLab CI Example

```yaml
integration-tests:
  stage: test
  image: python:3.11
  
  services:
    - postgres:15
    - redis:7
  
  variables:
    POSTGRES_DB: testdb
    POSTGRES_USER: test
    POSTGRES_PASSWORD: test
    DATABASE_URL: postgresql://test:test@postgres:5432/testdb
    REDIS_URL: redis://redis:6379
  
  before_script:
    - pip install -r requirements-test.txt
  
  script:
    - pytest tests/integration/ -v --cov=myapp
  
  coverage: '/TOTAL.*\s+(\d+%)$/'
```

## Debugging Integration Tests

### Verbose Output

```bash
# Detailed test output
pytest -vv tests/integration/

# Show print statements
pytest -s tests/integration/

# Stop on first failure
pytest -x tests/integration/

# Drop into debugger on failure
pytest --pdb tests/integration/
```

### Logging

```python
import logging

@pytest.fixture(autouse=True)
def configure_logging():
    """Enable logging for tests."""
    logging.basicConfig(
        level=logging.DEBUG,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

def test_with_logging(caplog):
    """Test that captures log output."""
    with caplog.at_level(logging.INFO):
        process_data()
        
        assert "Processing started" in caplog.text
        assert "Processing completed" in caplog.text
```

### Database Query Logging

```python
import logging

@pytest.fixture
def db_session_with_logging():
    """Database session with query logging."""
    logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)
    
    engine = create_engine(TEST_DATABASE_URL, echo=True)
    Session = sessionmaker(bind=engine)
    session = Session()
    
    yield session
    
    session.close()
```

## Common Pitfalls

### Flaky Tests

```python
# Bad: Time-dependent test
def test_cache_expiration():
    cache.set('key', 'value', ttl=1)
    time.sleep(1)  # Flaky: exact timing
    assert cache.get('key') is None

# Good: Use freezegun to control time
from freezegun import freeze_time

@freeze_time("2024-01-01 12:00:00")
def test_cache_expiration():
    cache.set('key', 'value', ttl=60)
    
    with freeze_time("2024-01-01 12:01:01"):
        assert cache.get('key') is None
```

### Shared State

```python
# Bad: Shared mutable state
user_cache = {}

def test_cache_set():
    user_cache['user1'] = {'name': 'Alice'}
    assert len(user_cache) == 1

def test_cache_get():
    # Fails if run after test_cache_set
    assert len(user_cache) == 0

# Good: Fresh state per test
@pytest.fixture
def user_cache():
    return {}

def test_cache_set(user_cache):
    user_cache['user1'] = {'name': 'Alice'}
    assert len(user_cache) == 1

def test_cache_get(user_cache):
    assert len(user_cache) == 0
```

### Slow Tests

```python
# Use markers to skip slow tests in development
@pytest.mark.slow
def test_large_data_processing(db_session):
    # Test that processes millions of records
    pass

# Run fast tests only
# pytest -m "not slow"

# Or use pytest-xdist for parallel execution
# pytest -n auto tests/integration/
```

## Tools and Libraries

### Essential

- **pytest**: Primary testing framework
- **pytest-cov**: Coverage reporting
- **pytest-xdist**: Parallel test execution
- **testcontainers**: Docker container management for tests

### Database Testing

- **factory_boy**: Test fixture factories
- **faker**: Generate realistic test data
- **pytest-django**: Django integration
- **alembic**: Database migrations for tests

### API Testing

- **httpx**: Async HTTP client for testing
- **responses**: Mock HTTP requests
- **vcr.py**: Record and replay HTTP interactions

### Integration Testing

- **docker**: Container management
- **testcontainers-python**: Pythonic container API
- **freezegun**: Mock datetime
- **pytest-mock**: Enhanced mocking

### Installation

```bash
# Core integration testing setup
pip install pytest pytest-cov pytest-xdist testcontainers

# Database testing
pip install factory-boy faker pytest-django alembic

# API testing
pip install httpx responses vcrpy

# Additional tools
pip install freezegun pytest-mock docker
```

## See Also

- [Python Testing Overview](index.md)
- [Unit Testing](unit-testing.md)
- [Test Automation](test-automation.md)
- [Deployment and CI/CD](../deployment/ci.md)
- [Cloud Deployment](../deployment/cloud-deployment.md)
