---
title: REST API Development in Python
description: Comprehensive guide to building robust, scalable RESTful APIs in Python using Flask, FastAPI, and Django REST Framework
---

REST (Representational State Transfer) APIs are the backbone of modern web services, enabling seamless communication between clients and servers. Python offers exceptional frameworks for building robust, scalable RESTful APIs that power everything from mobile applications to enterprise microservices.

## Overview

REST APIs provide a standardized way for applications to communicate over HTTP using standard methods (GET, POST, PUT, DELETE, etc.). Python's rich ecosystem includes powerful frameworks like FastAPI, Flask, and Django REST Framework that make building production-ready APIs straightforward and efficient.

This guide covers everything from fundamental REST principles to advanced topics like authentication, rate limiting, caching, and deployment strategies.

## REST Principles

### Core Constraints

1. **Client-Server Architecture**: Separation of concerns between client and server
2. **Stateless**: Each request contains all information needed to process it
3. **Cacheable**: Responses must define themselves as cacheable or non-cacheable
4. **Uniform Interface**: Consistent way to interact with resources
5. **Layered System**: Architecture can be composed of multiple layers
6. **Code on Demand** (optional): Servers can extend client functionality

### Resource-Based Design

REST APIs are built around resources (nouns) rather than actions (verbs):

```text
✅ Good
GET    /users          # Get all users
GET    /users/123      # Get user 123
POST   /users          # Create new user
PUT    /users/123      # Update user 123
DELETE /users/123      # Delete user 123

❌ Avoid
GET    /getUsers
POST   /createUser
POST   /updateUser
POST   /deleteUser
```

## HTTP Methods

### Standard Methods

| Method | Purpose | Idempotent | Safe |
| --- | --- | --- | --- |
| GET | Retrieve resource(s) | Yes | Yes |
| POST | Create new resource | No | No |
| PUT | Update/replace resource | Yes | No |
| PATCH | Partial update | No | No |
| DELETE | Remove resource | Yes | No |
| HEAD | Get headers only | Yes | Yes |
| OPTIONS | Get allowed methods | Yes | Yes |

### Method Semantics

```python
# GET - Retrieve data (safe, idempotent)
@app.get("/users/{user_id}")
async def get_user(user_id: int):
    return {"id": user_id, "name": "John Doe"}

# POST - Create new resource (not idempotent)
@app.post("/users")
async def create_user(user: User):
    # Create and return new user
    return {"id": 123, "name": user.name}

# PUT - Replace entire resource (idempotent)
@app.put("/users/{user_id}")
async def update_user(user_id: int, user: User):
    # Replace entire user record
    return {"id": user_id, **user.dict()}

# PATCH - Partial update
@app.patch("/users/{user_id}")
async def partial_update(user_id: int, updates: dict):
    # Update only provided fields
    return {"id": user_id, **updates}

# DELETE - Remove resource (idempotent)
@app.delete("/users/{user_id}")
async def delete_user(user_id: int):
    return {"message": "User deleted"}
```

## HTTP Status Codes

### Common Status Codes

**Success (2xx)**:

- `200 OK`: Request succeeded
- `201 Created`: Resource created successfully
- `202 Accepted`: Request accepted for processing
- `204 No Content`: Success with no response body

**Client Errors (4xx)**:

- `400 Bad Request`: Invalid request syntax
- `401 Unauthorized`: Authentication required
- `403 Forbidden`: Authenticated but not authorized
- `404 Not Found`: Resource doesn't exist
- `409 Conflict`: Request conflicts with current state
- `422 Unprocessable Entity`: Validation failed
- `429 Too Many Requests`: Rate limit exceeded

**Server Errors (5xx)**:

- `500 Internal Server Error`: Generic server error
- `502 Bad Gateway`: Invalid response from upstream
- `503 Service Unavailable`: Server temporarily unavailable
- `504 Gateway Timeout`: Upstream timeout

### Usage Examples

```python
from fastapi import FastAPI, HTTPException, status

@app.post("/users", status_code=status.HTTP_201_CREATED)
async def create_user(user: User):
    if user_exists(user.email):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="User with this email already exists"
        )
    return create_new_user(user)

@app.get("/users/{user_id}")
async def get_user(user_id: int):
    user = find_user(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User {user_id} not found"
        )
    return user

@app.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(user_id: int):
    if not delete_user_by_id(user_id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User {user_id} not found"
        )
    return None
```

## Popular Python Frameworks

### FastAPI

Modern, fast, and intuitive framework with automatic API documentation:

```python
from fastapi import FastAPI, Query, Path, Body
from pydantic import BaseModel, Field
from typing import Optional

app = FastAPI(title="My API", version="1.0.0")

class User(BaseModel):
    id: Optional[int] = None
    name: str = Field(..., min_length=1, max_length=100)
    email: str = Field(..., regex=r"^[\w\.-]+@[\w\.-]+\.\w+$")
    age: int = Field(..., ge=0, le=150)

@app.get("/users")
async def list_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100)
):
    """Get list of users with pagination."""
    return {"users": get_users(skip, limit)}

@app.get("/users/{user_id}")
async def get_user(
    user_id: int = Path(..., ge=1, description="User ID")
):
    """Get single user by ID."""
    return find_user(user_id)

@app.post("/users", status_code=201)
async def create_user(user: User = Body(...)):
    """Create new user."""
    return create_new_user(user)
```

**Advantages**:

- Automatic API documentation (Swagger UI and ReDoc)
- Data validation with Pydantic
- High performance (built on Starlette and Pydantic)
- Async support
- Type hints for editor support
- Dependency injection system

### Flask-RESTful

Lightweight and flexible framework for building REST APIs:

```python
from flask import Flask
from flask_restful import Resource, Api, reqparse, fields, marshal_with

app = Flask(__name__)
api = Api(app)

user_fields = {
    'id': fields.Integer,
    'name': fields.String,
    'email': fields.String
}

class UserResource(Resource):
    @marshal_with(user_fields)
    def get(self, user_id):
        """Get user by ID."""
        user = find_user(user_id)
        if not user:
            return {'message': 'User not found'}, 404
        return user

    @marshal_with(user_fields)
    def put(self, user_id):
        """Update user."""
        parser = reqparse.RequestParser()
        parser.add_argument('name', type=str, required=True)
        parser.add_argument('email', type=str, required=True)
        args = parser.parse_args()
        
        return update_user(user_id, args), 200

    def delete(self, user_id):
        """Delete user."""
        delete_user(user_id)
        return '', 204

class UserListResource(Resource):
    @marshal_with(user_fields)
    def get(self):
        """List all users."""
        return get_all_users()

    @marshal_with(user_fields)
    def post(self):
        """Create new user."""
        parser = reqparse.RequestParser()
        parser.add_argument('name', type=str, required=True)
        parser.add_argument('email', type=str, required=True)
        args = parser.parse_args()
        
        return create_user(args), 201

api.add_resource(UserListResource, '/users')
api.add_resource(UserResource, '/users/<int:user_id>')
```

**Advantages**:

- Minimal boilerplate
- Flask ecosystem compatibility
- Simple request parsing
- Resource-based routing

### Django REST Framework

Powerful framework for building APIs with Django:

```python
from rest_framework import serializers, viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.contrib.auth.models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']
        read_only_fields = ['id']

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("Email already exists")
        return value

class UserViewSet(viewsets.ModelViewSet):
    """
    ViewSet for viewing and editing user instances.
    """
    queryset = User.objects.all()
    serializer_class = UserSerializer

    @action(detail=True, methods=['post'])
    def set_password(self, request, pk=None):
        """Custom action to set user password."""
        user = self.get_object()
        serializer = PasswordSerializer(data=request.data)
        if serializer.is_valid():
            user.set_password(serializer.validated_data['password'])
            user.save()
            return Response({'status': 'password set'})
        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )

    @action(detail=False, methods=['get'])
    def recent_users(self, request):
        """Get recently created users."""
        recent = self.queryset.order_by('-date_joined')[:10]
        serializer = self.get_serializer(recent, many=True)
        return Response(serializer.data)

# urls.py
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
router.register(r'users', UserViewSet)
urlpatterns = router.urls
```

**Advantages**:

- Full-featured with authentication, permissions, throttling
- Django ORM integration
- Browsable API for development
- Extensive documentation
- Large ecosystem of plugins

## Request and Response Handling

### Request Validation

**FastAPI with Pydantic**:

```python
from pydantic import BaseModel, Field, validator
from typing import Optional, List
from datetime import datetime

class CreateUserRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: str = Field(..., regex=r"^[\w\.-]+@[\w\.-]+\.\w+$")
    password: str = Field(..., min_length=8)
    age: Optional[int] = Field(None, ge=0, le=150)
    tags: List[str] = []

    @validator('username')
    def username_alphanumeric(cls, v):
        if not v.isalnum():
            raise ValueError('Username must be alphanumeric')
        return v

    @validator('password')
    def password_strength(cls, v):
        if not any(c.isupper() for c in v):
            raise ValueError('Password must contain uppercase letter')
        if not any(c.isdigit() for c in v):
            raise ValueError('Password must contain digit')
        return v

@app.post("/users")
async def create_user(user: CreateUserRequest):
    # Validation happens automatically
    return {"message": "User created", "user": user.dict()}
```

### Response Models

```python
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    created_at: datetime
    
    class Config:
        from_attributes = True  # Allow ORM models

class PaginatedResponse(BaseModel):
    items: List[UserResponse]
    total: int
    page: int
    page_size: int
    has_next: bool

@app.get("/users", response_model=PaginatedResponse)
async def list_users(page: int = 1, page_size: int = 10):
    users = get_users_paginated(page, page_size)
    total = count_users()
    
    return {
        "items": users,
        "total": total,
        "page": page,
        "page_size": page_size,
        "has_next": (page * page_size) < total
    }
```

### Error Handling

```python
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError

app = FastAPI()

# Custom exception classes
class BusinessLogicError(Exception):
    def __init__(self, detail: str, status_code: int = 400):
        self.detail = detail
        self.status_code = status_code

# Global exception handlers
@app.exception_handler(BusinessLogicError)
async def business_logic_handler(request: Request, exc: BusinessLogicError):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": "BusinessLogicError",
            "detail": exc.detail,
            "path": str(request.url)
        }
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content={
            "error": "ValidationError",
            "detail": exc.errors(),
            "body": exc.body
        }
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={
            "error": "InternalServerError",
            "detail": "An unexpected error occurred"
        }
    )
```

## Authentication and Authorization

### JWT Authentication

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from datetime import datetime, timedelta
from passlib.context import CryptContext

SECRET_KEY = "your-secret-key-here"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer()

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_password(plain_password: str, hashed_password: str):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str):
    return pwd_context.hash(password)

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    token = credentials.credentials
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: int = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials"
            )
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
    
    user = get_user_by_id(user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    return user

@app.post("/login")
async def login(username: str, password: str):
    user = authenticate_user(username, password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password"
        )
    
    access_token = create_access_token(
        data={"sub": str(user.id)},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/users/me")
async def read_users_me(current_user: User = Depends(get_current_user)):
    return current_user
```

### API Key Authentication

```python
from fastapi import Security, HTTPException, status
from fastapi.security import APIKeyHeader

API_KEY_HEADER = APIKeyHeader(name="X-API-Key")

def verify_api_key(api_key: str = Security(API_KEY_HEADER)):
    if api_key not in valid_api_keys:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API Key"
        )
    return api_key

@app.get("/protected")
async def protected_route(api_key: str = Depends(verify_api_key)):
    return {"message": "Access granted"}
```

### Role-Based Access Control (RBAC)

```python
from enum import Enum
from fastapi import Depends

class Role(str, Enum):
    ADMIN = "admin"
    USER = "user"
    MODERATOR = "moderator"

class RoleChecker:
    def __init__(self, allowed_roles: List[Role]):
        self.allowed_roles = allowed_roles

    def __call__(self, user: User = Depends(get_current_user)):
        if user.role not in self.allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions"
            )
        return user

# Usage
admin_only = RoleChecker([Role.ADMIN])
admin_or_moderator = RoleChecker([Role.ADMIN, Role.MODERATOR])

@app.delete("/users/{user_id}")
async def delete_user(
    user_id: int,
    current_user: User = Depends(admin_only)
):
    delete_user_by_id(user_id)
    return {"message": "User deleted"}

@app.post("/posts/{post_id}/moderate")
async def moderate_post(
    post_id: int,
    current_user: User = Depends(admin_or_moderator)
):
    moderate_post_by_id(post_id)
    return {"message": "Post moderated"}
```

## Database Integration

### SQLAlchemy with FastAPI

```python
from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from datetime import datetime
from fastapi import Depends

DATABASE_URL = "postgresql://user:password@localhost/dbname"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Models
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    username = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)

Base.metadata.create_all(bind=engine)

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# CRUD operations
@app.post("/users")
async def create_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = User(
        email=user.email,
        username=user.username,
        hashed_password=get_password_hash(user.password)
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.get("/users/{user_id}")
async def read_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.get("/users")
async def list_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    users = db.query(User).offset(skip).limit(limit).all()
    return users
```

### MongoDB with Motor (Async)

```python
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel
from typing import Optional
from bson import ObjectId

# MongoDB connection
client = AsyncIOMotorClient("mongodb://localhost:27017")
db = client.mydatabase

class PyObjectId(ObjectId):
    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def validate(cls, v):
        if not ObjectId.is_valid(v):
            raise ValueError("Invalid ObjectId")
        return ObjectId(v)

class UserModel(BaseModel):
    id: Optional[PyObjectId] = None
    username: str
    email: str
    
    class Config:
        json_encoders = {ObjectId: str}

@app.post("/users")
async def create_user(user: UserModel):
    user_dict = user.dict(exclude={"id"})
    result = await db.users.insert_one(user_dict)
    user_dict["id"] = str(result.inserted_id)
    return user_dict

@app.get("/users/{user_id}")
async def get_user(user_id: str):
    user = await db.users.find_one({"_id": ObjectId(user_id)})
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    user["id"] = str(user.pop("_id"))
    return user

@app.get("/users")
async def list_users(skip: int = 0, limit: int = 10):
    users = []
    cursor = db.users.find().skip(skip).limit(limit)
    async for document in cursor:
        document["id"] = str(document.pop("_id"))
        users.append(document)
    return users
```

## API Documentation

### OpenAPI/Swagger with FastAPI

FastAPI automatically generates OpenAPI documentation:

```python
from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi

app = FastAPI(
    title="My API",
    description="A comprehensive REST API",
    version="1.0.0",
    contact={
        "name": "API Support",
        "email": "support@example.com"
    },
    license_info={
        "name": "MIT",
        "url": "https://opensource.org/licenses/MIT"
    }
)

def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    
    openapi_schema = get_openapi(
        title="Custom title",
        version="2.0.0",
        description="Custom description",
        routes=app.routes,
    )
    
    openapi_schema["info"]["x-logo"] = {
        "url": "https://example.com/logo.png"
    }
    
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi

# Access documentation at:
# - Swagger UI: http://localhost:8000/docs
# - ReDoc: http://localhost:8000/redoc
# - OpenAPI JSON: http://localhost:8000/openapi.json
```

### API Documentation Best Practices

```python
from fastapi import FastAPI, Path, Query, Body
from pydantic import BaseModel, Field

class User(BaseModel):
    """User model with all required fields."""
    
    id: int = Field(..., description="Unique user identifier", example=123)
    username: str = Field(
        ...,
        min_length=3,
        max_length=50,
        description="Username must be unique",
        example="johndoe"
    )
    email: str = Field(
        ...,
        description="User email address",
        example="john@example.com"
    )

@app.get(
    "/users/{user_id}",
    response_model=User,
    summary="Get user by ID",
    description="Retrieve a single user by their unique identifier",
    response_description="The requested user object",
    tags=["users"]
)
async def get_user(
    user_id: int = Path(
        ...,
        description="The ID of the user to retrieve",
        ge=1,
        example=123
    )
):
    """
    Retrieve a user by ID.
    
    - **user_id**: Required user identifier
    
    Returns the user object if found, 404 otherwise.
    """
    return find_user(user_id)
```

## Testing REST APIs

### pytest with FastAPI

```python
from fastapi.testclient import TestClient
import pytest

@pytest.fixture
def client():
    return TestClient(app)

def test_create_user(client):
    response = client.post(
        "/users",
        json={
            "username": "testuser",
            "email": "test@example.com",
            "password": "Test123!"
        }
    )
    assert response.status_code == 201
    data = response.json()
    assert data["username"] == "testuser"
    assert "id" in data

def test_get_user(client):
    # Create user first
    create_response = client.post("/users", json={
        "username": "testuser",
        "email": "test@example.com"
    })
    user_id = create_response.json()["id"]
    
    # Get user
    response = client.get(f"/users/{user_id}")
    assert response.status_code == 200
    assert response.json()["username"] == "testuser"

def test_get_nonexistent_user(client):
    response = client.get("/users/99999")
    assert response.status_code == 404

def test_list_users_pagination(client):
    response = client.get("/users?skip=0&limit=10")
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert len(data["items"]) <= 10

def test_authentication_required(client):
    response = client.get("/protected")
    assert response.status_code == 401

def test_with_authentication(client):
    # Login
    login_response = client.post("/login", json={
        "username": "testuser",
        "password": "Test123!"
    })
    token = login_response.json()["access_token"]
    
    # Access protected endpoint
    response = client.get(
        "/protected",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
```

### Integration Testing with Database

```python
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

TEST_DATABASE_URL = "sqlite:///./test.db"

@pytest.fixture
def db():
    engine = create_engine(TEST_DATABASE_URL)
    TestingSessionLocal = sessionmaker(bind=engine)
    Base.metadata.create_all(bind=engine)
    
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)

def test_database_operations(db):
    # Create
    user = User(username="testuser", email="test@example.com")
    db.add(user)
    db.commit()
    
    # Read
    retrieved = db.query(User).filter(User.username == "testuser").first()
    assert retrieved is not None
    assert retrieved.email == "test@example.com"
    
    # Update
    retrieved.email = "newemail@example.com"
    db.commit()
    
    updated = db.query(User).filter(User.username == "testuser").first()
    assert updated.email == "newemail@example.com"
    
    # Delete
    db.delete(updated)
    db.commit()
    
    deleted = db.query(User).filter(User.username == "testuser").first()
    assert deleted is None
```

## Rate Limiting and Throttling

### Simple Rate Limiting

```python
from fastapi import Request, HTTPException
from collections import defaultdict
from datetime import datetime, timedelta
import asyncio

class RateLimiter:
    def __init__(self, requests: int, window: int):
        self.requests = requests
        self.window = window
        self.clients = defaultdict(list)
    
    async def check_rate_limit(self, client_id: str):
        now = datetime.now()
        
        # Clean old requests
        self.clients[client_id] = [
            req_time for req_time in self.clients[client_id]
            if now - req_time < timedelta(seconds=self.window)
        ]
        
        # Check limit
        if len(self.clients[client_id]) >= self.requests:
            raise HTTPException(
                status_code=429,
                detail=f"Rate limit exceeded. Max {self.requests} requests per {self.window} seconds"
            )
        
        # Add current request
        self.clients[client_id].append(now)

# Create limiter: 100 requests per 60 seconds
limiter = RateLimiter(requests=100, window=60)

@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    client_id = request.client.host
    await limiter.check_rate_limit(client_id)
    response = await call_next(request)
    return response
```

### Advanced Rate Limiting with Redis

```python
from redis import Redis
from fastapi import Request, HTTPException
import time

redis_client = Redis(host='localhost', port=6379, decode_responses=True)

async def rate_limit(request: Request, max_requests: int = 100, window: int = 60):
    client_id = request.client.host
    key = f"rate_limit:{client_id}"
    
    current = redis_client.get(key)
    
    if current is None:
        redis_client.setex(key, window, 1)
    elif int(current) >= max_requests:
        raise HTTPException(
            status_code=429,
            detail="Rate limit exceeded",
            headers={"Retry-After": str(redis_client.ttl(key))}
        )
    else:
        redis_client.incr(key)

@app.get("/api/resource")
async def get_resource(request: Request):
    await rate_limit(request, max_requests=100, window=60)
    return {"data": "resource"}
```

## Caching

### In-Memory Caching

```python
from functools import lru_cache
from fastapi import FastAPI
import time

@lru_cache(maxsize=128)
def get_expensive_data(param: str):
    # Simulate expensive operation
    time.sleep(2)
    return {"data": f"Result for {param}"}

@app.get("/data/{param}")
async def cached_endpoint(param: str):
    # Will be cached after first call
    return get_expensive_data(param)
```

### Redis Caching

```python
from redis import Redis
import json
from typing import Optional

redis_client = Redis(host='localhost', port=6379, decode_responses=True)

def get_cache(key: str) -> Optional[dict]:
    data = redis_client.get(key)
    return json.loads(data) if data else None

def set_cache(key: str, value: dict, expire: int = 300):
    redis_client.setex(key, expire, json.dumps(value))

@app.get("/users/{user_id}")
async def get_user_cached(user_id: int):
    cache_key = f"user:{user_id}"
    
    # Try cache first
    cached = get_cache(cache_key)
    if cached:
        return cached
    
    # Get from database
    user = get_user_from_db(user_id)
    if not user:
        raise HTTPException(status_code=404)
    
    # Cache result
    set_cache(cache_key, user, expire=300)
    return user
```

### ETags for HTTP Caching

```python
from fastapi import Request, Response
import hashlib

def generate_etag(content: str) -> str:
    return hashlib.md5(content.encode()).hexdigest()

@app.get("/resource")
async def get_resource(request: Request):
    data = get_data()
    content = json.dumps(data)
    etag = generate_etag(content)
    
    # Check If-None-Match header
    if request.headers.get("If-None-Match") == etag:
        return Response(status_code=304)  # Not Modified
    
    return Response(
        content=content,
        media_type="application/json",
        headers={"ETag": etag, "Cache-Control": "max-age=300"}
    )
```

## Pagination

### Offset-Based Pagination

```python
from pydantic import BaseModel
from typing import List, Generic, TypeVar

T = TypeVar('T')

class PaginatedResponse(BaseModel, Generic[T]):
    items: List[T]
    total: int
    page: int
    page_size: int
    total_pages: int

@app.get("/users", response_model=PaginatedResponse[UserResponse])
async def list_users(
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db)
):
    skip = (page - 1) * page_size
    
    total = db.query(User).count()
    users = db.query(User).offset(skip).limit(page_size).all()
    
    return {
        "items": users,
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": (total + page_size - 1) // page_size
    }
```

### Cursor-Based Pagination

```python
from typing import Optional

@app.get("/users")
async def list_users_cursor(
    cursor: Optional[int] = None,
    limit: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db)
):
    query = db.query(User).order_by(User.id)
    
    if cursor:
        query = query.filter(User.id > cursor)
    
    users = query.limit(limit + 1).all()
    
    has_next = len(users) > limit
    if has_next:
        users = users[:-1]
        next_cursor = users[-1].id
    else:
        next_cursor = None
    
    return {
        "items": users,
        "next_cursor": next_cursor,
        "has_next": has_next
    }
```

## File Uploads

### Single File Upload

```python
from fastapi import File, UploadFile
import shutil
from pathlib import Path

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

@app.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    file_path = UPLOAD_DIR / file.filename
    
    with file_path.open("wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    return {
        "filename": file.filename,
        "content_type": file.content_type,
        "size": file_path.stat().st_size
    }
```

### Multiple File Uploads

```python
from typing import List

@app.post("/upload-multiple")
async def upload_multiple(files: List[UploadFile] = File(...)):
    uploaded_files = []
    
    for file in files:
        file_path = UPLOAD_DIR / file.filename
        
        with file_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        uploaded_files.append({
            "filename": file.filename,
            "size": file_path.stat().st_size
        })
    
    return {"files": uploaded_files}
```

### File Validation

```python
from fastapi import HTTPException

MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/gif"}

@app.post("/upload-image")
async def upload_image(file: UploadFile = File(...)):
    # Validate file type
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"File type {file.content_type} not allowed"
        )
    
    # Validate file size
    contents = await file.read()
    if len(contents) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"File size exceeds {MAX_FILE_SIZE} bytes"
        )
    
    # Save file
    file_path = UPLOAD_DIR / file.filename
    with file_path.open("wb") as buffer:
        buffer.write(contents)
    
    return {"filename": file.filename, "size": len(contents)}
```

## CORS Configuration

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "https://example.com"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["X-Total-Count"],
    max_age=3600
)

# For development (allow all)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)
```

## Background Tasks

```python
from fastapi import BackgroundTasks

def send_email(email: str, message: str):
    # Simulate sending email
    time.sleep(2)
    print(f"Email sent to {email}: {message}")

@app.post("/send-notification")
async def send_notification(
    email: str,
    background_tasks: BackgroundTasks
):
    background_tasks.add_task(send_email, email, "Welcome!")
    return {"message": "Notification scheduled"}

# Multiple background tasks
@app.post("/register")
async def register_user(
    user: UserCreate,
    background_tasks: BackgroundTasks
):
    # Create user
    new_user = create_user(user)
    
    # Schedule background tasks
    background_tasks.add_task(send_email, user.email, "Welcome")
    background_tasks.add_task(log_registration, new_user.id)
    background_tasks.add_task(update_analytics, "new_user")
    
    return new_user
```

## WebSocket Support

```python
from fastapi import WebSocket, WebSocketDisconnect
from typing import List

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)

manager = ConnectionManager()

@app.websocket("/ws/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: int):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            await manager.broadcast(f"Client #{client_id}: {data}")
    except WebSocketDisconnect:
        manager.disconnect(websocket)
        await manager.broadcast(f"Client #{client_id} disconnected")
```

## API Versioning

### URL Path Versioning

```python
from fastapi import APIRouter

# Version 1
v1_router = APIRouter(prefix="/api/v1")

@v1_router.get("/users")
async def get_users_v1():
    return {"version": "1.0", "users": []}

# Version 2
v2_router = APIRouter(prefix="/api/v2")

@v2_router.get("/users")
async def get_users_v2():
    return {"version": "2.0", "users": [], "metadata": {}}

app.include_router(v1_router)
app.include_router(v2_router)
```

### Header Versioning

```python
from fastapi import Header

@app.get("/users")
async def get_users(api_version: str = Header(default="1.0", alias="X-API-Version")):
    if api_version == "1.0":
        return {"version": "1.0", "users": []}
    elif api_version == "2.0":
        return {"version": "2.0", "users": [], "metadata": {}}
    else:
        raise HTTPException(status_code=400, detail="Unsupported API version")
```

## Performance Optimization

### Database Query Optimization

```python
from sqlalchemy.orm import joinedload, selectinload

# Eager loading to avoid N+1 queries
@app.get("/users-with-posts")
async def get_users_with_posts(db: Session = Depends(get_db)):
    users = db.query(User).options(
        selectinload(User.posts)
    ).all()
    return users

# Pagination with count optimization
@app.get("/users")
async def list_users_optimized(
    skip: int = 0,
    limit: int = 10,
    db: Session = Depends(get_db)
):
    from sqlalchemy import func
    
    # Get count and data in parallel
    count_query = db.query(func.count(User.id))
    data_query = db.query(User).offset(skip).limit(limit)
    
    total = count_query.scalar()
    users = data_query.all()
    
    return {"total": total, "items": users}
```

### Response Compression

```python
from fastapi.middleware.gzip import GZipMiddleware

app.add_middleware(GZipMiddleware, minimum_size=1000)
```

### Connection Pooling

```python
from sqlalchemy.pool import QueuePool

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=20,
    max_overflow=0,
    pool_pre_ping=True,
    pool_recycle=3600
)
```

## Security Best Practices

### Input Validation

```python
from pydantic import BaseModel, validator, Field
import re

class SecureUserInput(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: str
    
    @validator('username')
    def validate_username(cls, v):
        if not re.match(r'^[a-zA-Z0-9_-]+$', v):
            raise ValueError('Username contains invalid characters')
        return v
    
    @validator('email')
    def validate_email(cls, v):
        if not re.match(r'^[\w\.-]+@[\w\.-]+\.\w+$', v):
            raise ValueError('Invalid email format')
        return v.lower()
```

### SQL Injection Prevention

```python
# ✅ Good - Use parameterized queries
from sqlalchemy import text

@app.get("/users/search")
async def search_users(name: str, db: Session = Depends(get_db)):
    # SQLAlchemy ORM prevents SQL injection
    users = db.query(User).filter(User.name == name).all()
    return users

# ✅ Good - With raw SQL, use parameters
@app.get("/users/search-raw")
async def search_users_raw(name: str, db: Session = Depends(get_db)):
    query = text("SELECT * FROM users WHERE name = :name")
    result = db.execute(query, {"name": name})
    return result.fetchall()

# ❌ NEVER do this - SQL injection vulnerable
@app.get("/users/search-unsafe")
async def search_users_unsafe(name: str, db: Session = Depends(get_db)):
    query = f"SELECT * FROM users WHERE name = '{name}'"  # VULNERABLE!
    result = db.execute(text(query))
    return result.fetchall()
```

### XSS Prevention

```python
import html

@app.post("/comments")
async def create_comment(content: str):
    # Escape HTML to prevent XSS
    safe_content = html.escape(content)
    save_comment(safe_content)
    return {"content": safe_content}
```

### HTTPS Enforcement

```python
from fastapi.middleware.httpsredirect import HTTPSRedirectMiddleware

# Redirect HTTP to HTTPS
app.add_middleware(HTTPSRedirectMiddleware)
```

### Security Headers

```python
from fastapi.middleware.trustedhost import TrustedHostMiddleware

app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["example.com", "*.example.com"]
)

@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    return response
```

## Deployment

### Docker

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Run with Gunicorn
CMD ["gunicorn", "main:app", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "-b", "0.0.0.0:8000"]
```

### Docker Compose

```yaml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:password@db:5432/dbname
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis
  
  db:
    image: postgres:15
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=dbname
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: myapi:latest
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: api-secrets
              key: database-url
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: api-service
spec:
  selector:
    app: api
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
  type: LoadBalancer
```

## Monitoring and Logging

### Structured Logging

```python
import logging
from pythonjsonlogger import jsonlogger

logHandler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter()
logHandler.setFormatter(formatter)

logger = logging.getLogger()
logger.addHandler(logHandler)
logger.setLevel(logging.INFO)

@app.middleware("http")
async def log_requests(request: Request, call_next):
    logger.info("request_started", extra={
        "method": request.method,
        "path": request.url.path,
        "client": request.client.host
    })
    
    response = await call_next(request)
    
    logger.info("request_completed", extra={
        "method": request.method,
        "path": request.url.path,
        "status_code": response.status_code
    })
    
    return response
```

### Prometheus Metrics

```python
from prometheus_client import Counter, Histogram, generate_latest
from fastapi.responses import Response
import time

REQUEST_COUNT = Counter(
    'api_requests_total',
    'Total API requests',
    ['method', 'endpoint', 'status']
)

REQUEST_DURATION = Histogram(
    'api_request_duration_seconds',
    'API request duration',
    ['method', 'endpoint']
)

@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start_time = time.time()
    
    response = await call_next(request)
    
    duration = time.time() - start_time
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    
    REQUEST_DURATION.labels(
        method=request.method,
        endpoint=request.url.path
    ).observe(duration)
    
    return response

@app.get("/metrics")
async def metrics():
    return Response(content=generate_latest(), media_type="text/plain")
```

## Best Practices Summary

### API Design

- Use nouns for resources, not verbs
- Use HTTP methods correctly
- Version your API from the start
- Provide meaningful error messages
- Use standard HTTP status codes
- Implement pagination for list endpoints
- Support filtering, sorting, and searching
- Use consistent naming conventions

### Security

- Always use HTTPS in production
- Implement authentication and authorization
- Validate all input data
- Use parameterized queries to prevent SQL injection
- Implement rate limiting
- Add security headers
- Keep dependencies updated
- Don't expose sensitive data in responses

### Performance

- Use database connection pooling
- Implement caching strategically
- Enable response compression
- Optimize database queries
- Use async operations where beneficial
- Monitor and profile your API
- Implement efficient pagination

### Documentation

- Provide comprehensive API documentation
- Include examples for all endpoints
- Document error responses
- Keep documentation up to date
- Use OpenAPI/Swagger specifications

### Testing

- Write unit tests for business logic
- Test API endpoints with integration tests
- Test authentication and authorization
- Test error handling
- Use fixtures for test data
- Maintain high test coverage

## Additional Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Django REST Framework](https://www.django-rest-framework.org/)
- [REST API Tutorial](https://restfulapi.net/)
- [HTTP Status Codes](https://httpstatuses.com/)
- [OpenAPI Specification](https://swagger.io/specification/)
- [RESTful Web Services](https://restfulapi.net/)

## See Also

- [FastAPI Framework](../frameworks/fastapi.md)
- [Flask Framework](../frameworks/flask.md)
- [Django Framework](../frameworks/django.md)
- [API Testing](../../testing/api-testing.md)
- [Authentication Patterns](../../security/authentication.md)
