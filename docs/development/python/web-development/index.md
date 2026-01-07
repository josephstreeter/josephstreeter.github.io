---
title: Python Web Development
description: Comprehensive guide to building modern web applications with Python, covering frameworks, best practices, deployment strategies, and full-stack development
---

Python has evolved into one of the most powerful ecosystems for web development, offering frameworks ranging from micro-frameworks for simple APIs to full-featured solutions for enterprise applications. This guide covers the complete spectrum of Python web development, from choosing the right framework to deploying production-ready applications.

## Overview

Python's web development landscape is characterized by its diversity and pragmatism. Whether building a RESTful API, a real-time application, or a full-stack monolith, Python provides mature, well-documented frameworks backed by strong communities. The ecosystem emphasizes developer productivity, code readability, and rapid prototyping while maintaining the performance and scalability needed for production systems.

### Why Python for Web Development

- **Rapid Development**: Python's clear syntax and extensive libraries accelerate development cycles
- **Mature Ecosystem**: Battle-tested frameworks with years of production use
- **Versatility**: From APIs to full-stack applications, Python handles diverse use cases
- **Strong Community**: Extensive documentation, tutorials, and community support
- **Integration Capabilities**: Seamless integration with databases, cloud services, and third-party APIs
- **Data Science Integration**: Natural fit for ML-powered applications and data-driven features
- **Scalability**: Proven at scale by Instagram, Spotify, Netflix, and Dropbox

## Popular Web Frameworks

### Django - The Full-Stack Framework

Django is a high-level Python web framework that encourages rapid development and clean, pragmatic design. It follows the "batteries included" philosophy, providing everything needed to build complete web applications.

#### Django Key Features

- **ORM (Object-Relational Mapping)**: Database abstraction with model definitions
- **Admin Interface**: Automatically generated admin panel
- **Authentication System**: Built-in user authentication and authorization
- **Template Engine**: Django Template Language (DTL) for HTML generation
- **URL Routing**: Clean, declarative URL configuration
- **Form Handling**: Comprehensive form validation and rendering
- **Security**: CSRF protection, SQL injection prevention, XSS protection
- **Internationalization**: Built-in i18n and l10n support

#### When to Use Django

- **Content-heavy applications**: CMS, blogs, news sites
- **E-commerce platforms**: Shopping carts, payment processing
- **Enterprise applications**: Complex business logic with admin interfaces
- **Rapid prototyping**: When you need a complete solution quickly
- **Projects requiring admin panels**: Automatic CRUD interface generation

#### Django Quick Start

```bash
# Install Django
pip install django

# Create project
django-admin startproject myproject
cd myproject

# Create app
python manage.py startapp myapp

# Run development server
python manage.py runserver
```

#### Example Django View

```python
# myapp/models.py
from django.db import models

class Article(models.Model):
    Title = models.CharField(max_length=200)
    Content = models.TextField()
    Published = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return self.Title

# myapp/views.py
from django.shortcuts import render
from django.views.generic import ListView
from .models import Article

class ArticleListView(ListView):
    model = Article
    template_name = 'articles/list.html'
    context_object_name = 'articles'
    paginate_by = 10

# myapp/urls.py
from django.urls import path
from .views import ArticleListView

urlpatterns = [
    path('articles/', ArticleListView.as_view(), name='article-list'),
]
```

### FastAPI - Modern, Fast, API Development

FastAPI is a modern, high-performance web framework for building APIs with Python 3.7+ based on standard Python type hints. It's one of the fastest Python frameworks available, on par with NodeJS and Go.

#### FastAPI Key Features

- **High Performance**: Comparable to NodeJS and Go (powered by Starlette and Pydantic)
- **Type Hints**: Leverages Python type hints for validation and documentation
- **Automatic Documentation**: Interactive API docs (Swagger UI and ReDoc)
- **Fast to Code**: Reduces development time by 40-60%
- **Async Support**: Native async/await support for concurrent operations
- **Data Validation**: Automatic request/response validation with Pydantic
- **Dependency Injection**: Clean dependency injection system
- **Security**: OAuth2, JWT tokens, API keys out of the box

#### When to Use FastAPI

- **RESTful APIs**: Modern API development with automatic documentation
- **Microservices**: Fast, lightweight services
- **ML Model Serving**: Deploying machine learning models as APIs
- **Real-time Applications**: WebSocket support for real-time features
- **Data Validation**: When strict input/output validation is critical
- **High Performance Requirements**: When speed is a priority

#### FastAPI Quick Start

```bash
# Install FastAPI and server
pip install fastapi uvicorn[standard]

# Run application
uvicorn main:app --reload
```

#### Example FastAPI Application

```python
# main.py
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import datetime

app = FastAPI(title="Blog API", version="1.0.0")

# Pydantic models for validation
class ArticleBase(BaseModel):
    Title: str
    Content: str
    Published: bool = True

class ArticleCreate(ArticleBase):
    pass

class Article(ArticleBase):
    Id: int
    CreatedAt: datetime
    
    class Config:
        from_attributes = True

# In-memory database (use real DB in production)
articles_db = []

@app.post("/articles/", response_model=Article, status_code=201)
async def create_article(article: ArticleCreate):
    """Create a new article"""
    new_article = Article(
        Id=len(articles_db) + 1,
        CreatedAt=datetime.now(),
        **article.dict()
    )
    articles_db.append(new_article)
    return new_article

@app.get("/articles/", response_model=List[Article])
async def list_articles(skip: int = 0, limit: int = 10):
    """List all articles with pagination"""
    return articles_db[skip : skip + limit]

@app.get("/articles/{article_id}", response_model=Article)
async def get_article(article_id: int):
    """Get article by ID"""
    for article in articles_db:
        if article.Id == article_id:
            return article
    raise HTTPException(status_code=404, detail="Article not found")

# Automatic interactive documentation available at:
# http://localhost:8000/docs (Swagger UI)
# http://localhost:8000/redoc (ReDoc)
```

### Flask - The Micro Framework

Flask is a lightweight WSGI web application framework that provides the essentials for building web applications while remaining flexible and unopinionated about project structure.

#### Flask Key Features

- **Minimal Core**: Only provides essential features
- **Extensibility**: Large ecosystem of extensions
- **Flexible**: No prescribed project structure or components
- **Jinja2 Templates**: Powerful template engine
- **WSGI Compatible**: Works with standard WSGI servers
- **Built-in Development Server**: Quick testing and debugging
- **RESTful Request Dispatching**: Clean URL routing

#### When to Use Flask

- **Simple APIs**: Quick REST API development
- **Microservices**: Lightweight services with minimal overhead
- **Learning**: Easier learning curve than Django
- **Custom Requirements**: When you need full control over components
- **Prototypes**: Rapid prototyping and MVPs

#### Flask Quick Start

```bash
# Install Flask
pip install flask

# Run application
python app.py
```

#### Example Flask Application

```python
# app.py
from flask import Flask, request, jsonify, render_template
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///blog.db'
db = SQLAlchemy(app)

# Model
class Article(db.Model):
    Id = db.Column(db.Integer, primary_key=True)
    Title = db.Column(db.String(200), nullable=False)
    Content = db.Column(db.Text, nullable=False)
    CreatedAt = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.Id,
            'title': self.Title,
            'content': self.Content,
            'created_at': self.CreatedAt.isoformat()
        }

# Routes
@app.route('/')
def home():
    return render_template('index.html')

@app.route('/api/articles', methods=['GET'])
def get_articles():
    articles = Article.query.all()
    return jsonify([article.to_dict() for article in articles])

@app.route('/api/articles', methods=['POST'])
def create_article():
    data = request.get_json()
    article = Article(
        Title=data['title'],
        Content=data['content']
    )
    db.session.add(article)
    db.session.commit()
    return jsonify(article.to_dict()), 201

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(debug=True)
```

### Other Notable Frameworks

#### Tornado - Asynchronous Framework

- **Asynchronous**: Non-blocking I/O for handling thousands of connections
- **WebSockets**: Built-in WebSocket support
- **Long Polling**: Ideal for real-time applications
- **Use Cases**: Chat applications, real-time dashboards, streaming APIs

```python
import tornado.ioloop
import tornado.web

class MainHandler(tornado.web.RequestHandler):
    def get(self):
        self.write("Hello, Tornado!")

def make_app():
    return tornado.web.Application([
        (r"/", MainHandler),
    ])

if __name__ == "__main__":
    app = make_app()
    app.listen(8888)
    tornado.ioloop.IOLoop.current().start()
```

#### Starlette - ASGI Framework

- **Foundation**: FastAPI is built on Starlette
- **ASGI**: Modern asynchronous framework interface
- **Lightweight**: Minimal but complete
- **WebSocket Support**: Native WebSocket handling
- **GraphQL Support**: Built-in GraphQL support

#### Pyramid - Flexible Framework

- **Flexibility**: Start small, grow as needed
- **URL Generation**: Powerful URL generation and traversal
- **Authentication**: Comprehensive security policies
- **Use Cases**: Complex applications requiring fine-grained control

## Framework Comparison

### Performance Benchmarks

| Framework | Requests/sec | Latency (ms) | Use Case |
| --- | --- | --- | --- |
| **FastAPI** | 25,000+ | 3-5 | High-performance APIs |
| **Starlette** | 26,000+ | 3-4 | ASGI applications |
| **Flask** | 3,000-5,000 | 20-30 | Simple applications |
| **Django** | 2,000-4,000 | 25-40 | Full-stack applications |
| **Tornado** | 8,000-12,000 | 10-15 | Real-time applications |

Note: Benchmarks vary based on configuration and use case.

### Feature Comparison

| Feature | Django | FastAPI | Flask |
| --- | --- | --- | --- |
| **ORM** | Built-in | External | External |
| **Admin Panel** | Yes | No | No |
| **Async Support** | Partial | Full | Partial |
| **API Docs** | Manual | Automatic | Manual |
| **Learning Curve** | Steep | Moderate | Gentle |
| **Project Structure** | Prescribed | Flexible | Flexible |
| **Template Engine** | Built-in | External | Built-in |
| **Authentication** | Built-in | External | External |
| **Form Handling** | Built-in | Pydantic | External |

## Database Integration

### SQL Databases with SQLAlchemy

SQLAlchemy is the most popular SQL toolkit and ORM for Python, providing both low-level SQL expressions and high-level ORM capabilities.

#### Installation

```bash
pip install sqlalchemy psycopg2-binary  # PostgreSQL
# or
pip install sqlalchemy pymysql  # MySQL
```

#### Basic Usage

```python
from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime

# Database connection
engine = create_engine('postgresql://user:pass@localhost/dbname')
Session = sessionmaker(bind=engine)
Base = declarative_base()

# Model definition
class User(Base):
    __tablename__ = 'users'
    
    Id = Column(Integer, primary_key=True)
    Username = Column(String(50), unique=True, nullable=False)
    Email = Column(String(120), unique=True, nullable=False)
    CreatedAt = Column(DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f"<User(username='{self.Username}')>"

# Create tables
Base.metadata.create_all(engine)

# CRUD operations
session = Session()

# Create
new_user = User(Username='john_doe', Email='john@example.com')
session.add(new_user)
session.commit()

# Read
user = session.query(User).filter_by(Username='john_doe').first()

# Update
user.Email = 'newemail@example.com'
session.commit()

# Delete
session.delete(user)
session.commit()
```

### NoSQL Databases

#### MongoDB with PyMongo

```python
from pymongo import MongoClient
from datetime import datetime

# Connect to MongoDB
client = MongoClient('mongodb://localhost:27017/')
db = client['blog_database']
articles = db['articles']

# Insert document
article = {
    'title': 'Python Web Development',
    'content': 'Comprehensive guide...',
    'author': 'John Doe',
    'created_at': datetime.utcnow(),
    'tags': ['python', 'web', 'tutorial']
}
result = articles.insert_one(article)

# Query documents
for article in articles.find({'tags': 'python'}):
    print(article['title'])

# Update document
articles.update_one(
    {'_id': result.inserted_id},
    {'$set': {'content': 'Updated content...'}}
)

# Delete document
articles.delete_one({'_id': result.inserted_id})
```

#### Redis for Caching

```python
import redis
import json

# Connect to Redis
r = redis.Redis(host='localhost', port=6379, db=0)

# Cache user data
user_data = {'id': 1, 'username': 'john_doe', 'email': 'john@example.com'}
r.setex('user:1', 3600, json.dumps(user_data))  # Expire in 1 hour

# Retrieve cached data
cached_user = json.loads(r.get('user:1'))

# Cache with hashes
r.hset('user:2', mapping={
    'username': 'jane_doe',
    'email': 'jane@example.com'
})
r.expire('user:2', 3600)
```

## RESTful API Development

### Best Practices

#### API Design Principles

1. **Use Standard HTTP Methods**
   - `GET`: Retrieve resources
   - `POST`: Create resources
   - `PUT`: Update entire resource
   - `PATCH`: Partial update
   - `DELETE`: Remove resource

2. **RESTful URL Structure**
   - Collections: `/api/articles`
   - Individual resource: `/api/articles/123`
   - Nested resources: `/api/articles/123/comments`

3. **Status Codes**
   - `200 OK`: Successful GET, PUT, PATCH
   - `201 Created`: Successful POST
   - `204 No Content`: Successful DELETE
   - `400 Bad Request`: Invalid request data
   - `401 Unauthorized`: Authentication required
   - `403 Forbidden`: Insufficient permissions
   - `404 Not Found`: Resource doesn't exist
   - `500 Internal Server Error`: Server error

#### Example RESTful API with FastAPI

```python
from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext

app = FastAPI()

# Security configuration
SECRET_KEY = "your-secret-key-here"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# Models
class UserBase(BaseModel):
    Username: str = Field(..., min_length=3, max_length=50)
    Email: EmailStr

class UserCreate(UserBase):
    Password: str = Field(..., min_length=8)

class User(UserBase):
    Id: int
    IsActive: bool = True
    CreatedAt: datetime
    
    class Config:
        from_attributes = True

class Token(BaseModel):
    AccessToken: str
    TokenType: str

# Authentication functions
def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    # Fetch user from database here
    return {"username": username}

# Endpoints
@app.post("/token", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    # Verify user credentials (check database)
    # This is a simplified example
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": form_data.username},
        expires_delta=access_token_expires
    )
    return {"AccessToken": access_token, "TokenType": "bearer"}

@app.post("/users/", response_model=User, status_code=status.HTTP_201_CREATED)
async def create_user(user: UserCreate):
    """Register a new user"""
    hashed_password = get_password_hash(user.Password)
    # Save to database
    return {
        "Id": 1,
        "Username": user.Username,
        "Email": user.Email,
        "IsActive": True,
        "CreatedAt": datetime.utcnow()
    }

@app.get("/users/me", response_model=User)
async def read_users_me(current_user: dict = Depends(get_current_user)):
    """Get current user profile"""
    return current_user

@app.get("/api/health")
async def health_check():
    """Health check endpoint for monitoring"""
    return {"status": "healthy", "timestamp": datetime.utcnow()}
```

### API Versioning

#### URL Versioning

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

#### Header Versioning

```python
from fastapi import Header, HTTPException

@app.get("/api/users")
async def get_users(api_version: str = Header(default="1.0", alias="X-API-Version")):
    if api_version == "1.0":
        return {"version": "1.0", "users": []}
    elif api_version == "2.0":
        return {"version": "2.0", "users": [], "metadata": {}}
    else:
        raise HTTPException(status_code=400, detail="Unsupported API version")
```

## Authentication and Authorization

### JWT (JSON Web Tokens)

JWT is the most common authentication method for modern APIs, providing stateless authentication.

```python
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

SECRET_KEY = "your-secret-key-keep-it-secret"
ALGORITHM = "HS256"

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def create_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(hours=24))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials"
            )
        return payload
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
```

### OAuth2 with Third-Party Providers

```python
from authlib.integrations.starlette_client import OAuth
from starlette.config import Config

config = Config('.env')
oauth = OAuth(config)

# Google OAuth
oauth.register(
    name='google',
    client_id=config('GOOGLE_CLIENT_ID'),
    client_secret=config('GOOGLE_CLIENT_SECRET'),
    server_metadata_url='https://accounts.google.com/.well-known/openid-configuration',
    client_kwargs={'scope': 'openid email profile'}
)

@app.get('/login/google')
async def login_google(request: Request):
    redirect_uri = request.url_for('auth_google')
    return await oauth.google.authorize_redirect(request, redirect_uri)

@app.get('/auth/google')
async def auth_google(request: Request):
    token = await oauth.google.authorize_access_token(request)
    user_info = token.get('userinfo')
    # Create session or JWT token
    return {"user": user_info}
```

### Role-Based Access Control (RBAC)

```python
from enum import Enum
from typing import List
from fastapi import Depends, HTTPException, status

class Role(str, Enum):
    ADMIN = "admin"
    EDITOR = "editor"
    VIEWER = "viewer"

class RoleChecker:
    def __init__(self, allowed_roles: List[Role]):
        self.allowed_roles = allowed_roles
    
    def __call__(self, current_user: dict = Depends(get_current_user)):
        user_role = current_user.get("role")
        if user_role not in self.allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions"
            )
        return current_user

# Usage
admin_only = RoleChecker([Role.ADMIN])
editor_or_admin = RoleChecker([Role.ADMIN, Role.EDITOR])

@app.delete("/api/users/{user_id}")
async def delete_user(
    user_id: int,
    current_user: dict = Depends(admin_only)
):
    """Only admins can delete users"""
    return {"message": f"User {user_id} deleted"}

@app.post("/api/articles")
async def create_article(
    article: ArticleCreate,
    current_user: dict = Depends(editor_or_admin)
):
    """Editors and admins can create articles"""
    return {"message": "Article created"}
```

## Async Programming

### Understanding Async/Await

Modern Python web frameworks support asynchronous programming, allowing handling of multiple concurrent requests efficiently.

```python
import asyncio
import httpx
from typing import List

async def fetch_user(user_id: int) -> dict:
    """Fetch user data from external API"""
    async with httpx.AsyncClient() as client:
        response = await client.get(f"https://api.example.com/users/{user_id}")
        return response.json()

async def fetch_multiple_users(user_ids: List[int]) -> List[dict]:
    """Fetch multiple users concurrently"""
    tasks = [fetch_user(user_id) for user_id in user_ids]
    return await asyncio.gather(*tasks)

# FastAPI endpoint using async
@app.get("/api/users/batch")
async def get_users_batch(user_ids: List[int]):
    users = await fetch_multiple_users(user_ids)
    return {"users": users}
```

### Database Operations with Async

```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select

# Async engine
engine = create_async_engine(
    "postgresql+asyncpg://user:pass@localhost/dbname",
    echo=True
)

async_session = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False
)

async def get_user(user_id: int):
    async with async_session() as session:
        result = await session.execute(
            select(User).where(User.Id == user_id)
        )
        return result.scalar_one_or_none()

async def create_user(username: str, email: str):
    async with async_session() as session:
        user = User(Username=username, Email=email)
        session.add(user)
        await session.commit()
        return user
```

### Background Tasks

```python
from fastapi import BackgroundTasks
import logging

logger = logging.getLogger(__name__)

async def send_email(email: str, message: str):
    """Simulate sending email"""
    await asyncio.sleep(3)  # Simulate delay
    logger.info(f"Email sent to {email}: {message}")

@app.post("/api/register")
async def register_user(
    user: UserCreate,
    background_tasks: BackgroundTasks
):
    """Register user and send welcome email in background"""
    # Create user in database
    new_user = create_user(user)
    
    # Send welcome email asynchronously
    background_tasks.add_task(
        send_email,
        user.Email,
        f"Welcome {user.Username}!"
    )
    
    return {"message": "User registered", "user": new_user}
```

## Testing Web Applications

### Unit Testing with pytest

```bash
pip install pytest pytest-asyncio pytest-cov httpx
```

```python
# test_api.py
import pytest
from httpx import AsyncClient
from main import app

@pytest.mark.asyncio
async def test_create_article():
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post(
            "/articles/",
            json={"Title": "Test Article", "Content": "Test content"}
        )
        assert response.status_code == 201
        assert response.json()["Title"] == "Test Article"

@pytest.mark.asyncio
async def test_get_articles():
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/articles/")
        assert response.status_code == 200
        assert isinstance(response.json(), list)

@pytest.mark.asyncio
async def test_article_not_found():
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/articles/9999")
        assert response.status_code == 404
```

### Integration Testing

```python
# test_integration.py
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from main import app, Base, get_db

# Test database
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL)
TestingSessionLocal = sessionmaker(bind=engine)

@pytest.fixture
def test_db():
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

@pytest.mark.asyncio
async def test_full_user_workflow(test_db):
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Register user
        response = await client.post(
            "/users/",
            json={
                "Username": "testuser",
                "Email": "test@example.com",
                "Password": "securepass123"
            }
        )
        assert response.status_code == 201
        user_id = response.json()["Id"]
        
        # Login
        response = await client.post(
            "/token",
            data={"username": "testuser", "password": "securepass123"}
        )
        assert response.status_code == 200
        token = response.json()["AccessToken"]
        
        # Get user profile
        response = await client.get(
            "/users/me",
            headers={"Authorization": f"Bearer {token}"}
        )
        assert response.status_code == 200
        assert response.json()["Username"] == "testuser"
```

### Load Testing with Locust

```python
# locustfile.py
from locust import HttpUser, task, between

class WebsiteUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        """Login before starting tasks"""
        response = self.client.post("/token", data={
            "username": "testuser",
            "password": "password123"
        })
        self.token = response.json()["AccessToken"]
    
    @task(3)
    def get_articles(self):
        self.client.get("/api/articles", headers={
            "Authorization": f"Bearer {self.token}"
        })
    
    @task(1)
    def create_article(self):
        self.client.post("/api/articles", json={
            "Title": "Load Test Article",
            "Content": "Testing content"
        }, headers={
            "Authorization": f"Bearer {self.token}"
        })

# Run: locust -f locustfile.py
```

## Deployment

### Production Setup

#### Environment Configuration

```python
# config.py
from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    APP_NAME: str = "My API"
    DATABASE_URL: str
    SECRET_KEY: str
    DEBUG: bool = False
    ALLOWED_HOSTS: list = ["*"]
    REDIS_URL: str = "redis://localhost:6379"
    
    class Config:
        env_file = ".env"

@lru_cache()
def get_settings():
    return Settings()

# Usage
settings = get_settings()
```

#### Gunicorn Configuration

```bash
# Install production server
pip install gunicorn uvicorn[standard]

# Run with Gunicorn
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

```python
# gunicorn.conf.py
import multiprocessing

bind = "0.0.0.0:8000"
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "uvicorn.workers.UvicornWorker"
worker_connections = 1000
keepalive = 5
errorlog = "-"
accesslog = "-"
loglevel = "info"
```

### Docker Deployment

#### Dockerfile

```dockerfile
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8000

# Run application
CMD ["gunicorn", "main:app", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000"]
```

#### Docker Compose

```yaml
version: '3.8'

services:
  web:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/appdb
      - REDIS_URL=redis://redis:6379
      - SECRET_KEY=${SECRET_KEY}
    depends_on:
      - db
      - redis
    volumes:
      - ./:/app
    command: gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
  
  db:
    image: postgres:15
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=appdb
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
  
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - web

volumes:
  postgres_data:
```

### Cloud Deployment

#### AWS Elastic Beanstalk

```bash
# Install EB CLI
pip install awsebcli

# Initialize application
eb init -p python-3.11 my-app

# Create environment
eb create production-env

# Deploy
eb deploy

# Open in browser
eb open
```

#### Heroku

```bash
# Create Procfile
echo "web: gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker" > Procfile

# Create runtime.txt
echo "python-3.11.0" > runtime.txt

# Initialize git and deploy
git init
heroku create my-app
git add .
git commit -m "Initial commit"
git push heroku main
```

#### Google Cloud Run

```bash
# Build container
gcloud builds submit --tag gcr.io/PROJECT_ID/my-app

# Deploy
gcloud run deploy my-app \
  --image gcr.io/PROJECT_ID/my-app \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

#### Azure App Service

```bash
# Create resource group
az group create --name myResourceGroup --location eastus

# Create App Service plan
az appservice plan create \
  --name myAppServicePlan \
  --resource-group myResourceGroup \
  --sku B1 \
  --is-linux

# Create web app
az webapp create \
  --resource-group myResourceGroup \
  --plan myAppServicePlan \
  --name my-app \
  --runtime "PYTHON|3.11"

# Deploy code
az webapp up --name my-app
```

## Performance Optimization

### Caching Strategies

#### Redis Caching

```python
import redis
import json
from functools import wraps

redis_client = redis.Redis(host='localhost', port=6379, db=0)

def cache_result(expiration: int = 3600):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Create cache key
            cache_key = f"{func.__name__}:{str(args)}:{str(kwargs)}"
            
            # Check cache
            cached_result = redis_client.get(cache_key)
            if cached_result:
                return json.loads(cached_result)
            
            # Execute function
            result = await func(*args, **kwargs)
            
            # Store in cache
            redis_client.setex(
                cache_key,
                expiration,
                json.dumps(result)
            )
            return result
        return wrapper
    return decorator

@app.get("/api/articles/{article_id}")
@cache_result(expiration=300)  # Cache for 5 minutes
async def get_article(article_id: int):
    # Expensive database query
    return fetch_article_from_db(article_id)
```

#### Response Caching with FastAPI

```python
from fastapi_cache import FastAPICache
from fastapi_cache.backends.redis import RedisBackend
from fastapi_cache.decorator import cache

@app.on_event("startup")
async def startup():
    redis = redis.from_url("redis://localhost")
    FastAPICache.init(RedisBackend(redis), prefix="fastapi-cache")

@app.get("/api/articles")
@cache(expire=300)
async def get_articles():
    return fetch_all_articles()
```

### Database Optimization

#### Connection Pooling

```python
from sqlalchemy.pool import QueuePool

engine = create_engine(
    "postgresql://user:pass@localhost/db",
    poolclass=QueuePool,
    pool_size=20,
    max_overflow=40,
    pool_pre_ping=True
)
```

#### Query Optimization

```python
from sqlalchemy.orm import joinedload

# Eager loading to avoid N+1 queries
articles = session.query(Article)\
    .options(joinedload(Article.author))\
    .options(joinedload(Article.comments))\
    .all()

# Pagination
articles = session.query(Article)\
    .limit(10)\
    .offset(page * 10)\
    .all()

# Select specific columns
articles = session.query(Article.Id, Article.Title)\
    .filter(Article.Published == True)\
    .all()
```

### Load Balancing

#### Nginx Configuration

```nginx
# nginx.conf
upstream app_servers {
    least_conn;
    server app1:8000 weight=1;
    server app2:8000 weight=1;
    server app3:8000 weight=1;
}

server {
    listen 80;
    server_name example.com;
    
    location / {
        proxy_pass http://app_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /static/ {
        alias /var/www/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

## Security Best Practices

### Input Validation and Sanitization

```python
from pydantic import BaseModel, validator, Field
import re

class UserInput(BaseModel):
    Username: str = Field(..., min_length=3, max_length=50)
    Email: str
    Website: Optional[str] = None
    
    @validator('Username')
    def validate_username(cls, v):
        if not re.match(r'^[a-zA-Z0-9_-]+$', v):
            raise ValueError('Username can only contain letters, numbers, hyphens, and underscores')
        return v
    
    @validator('Website')
    def validate_url(cls, v):
        if v and not v.startswith(('http://', 'https://')):
            raise ValueError('Invalid URL format')
        return v
```

### SQL Injection Prevention

```python
# ✅ Safe - Using ORM
user = session.query(User).filter(User.Username == username).first()

# ✅ Safe - Using parameterized queries
user = session.execute(
    "SELECT * FROM users WHERE username = :username",
    {"username": username}
).first()

# ❌ Unsafe - String concatenation (NEVER DO THIS)
user = session.execute(
    f"SELECT * FROM users WHERE username = '{username}'"
).first()
```

### CORS Configuration

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://example.com"],  # Specific origins in production
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
    max_age=3600,
)
```

### Rate Limiting

```python
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.get("/api/public")
@limiter.limit("100/hour")
async def public_endpoint(request: Request):
    return {"message": "Rate limited endpoint"}

@app.get("/api/expensive")
@limiter.limit("10/minute")
async def expensive_endpoint(request: Request):
    return {"message": "Expensive operation"}
```

### HTTPS and Security Headers

```python
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from starlette.middleware.sessions import SessionMiddleware

# Trusted hosts
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["example.com", "*.example.com"]
)

# Secure session
app.add_middleware(
    SessionMiddleware,
    secret_key="your-secret-key",
    https_only=True,
    same_site="strict"
)

# Security headers
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    return response
```

## Monitoring and Logging

### Structured Logging

```python
import logging
import json
from datetime import datetime

class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_data = {
            "timestamp": datetime.utcnow().isoformat(),
            "level": record.levelname,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno
        }
        if hasattr(record, "request_id"):
            log_data["request_id"] = record.request_id
        return json.dumps(log_data)

# Configure logging
handler = logging.StreamHandler()
handler.setFormatter(JSONFormatter())
logger = logging.getLogger()
logger.addHandler(handler)
logger.setLevel(logging.INFO)

# Usage
logger.info("User logged in", extra={"user_id": 123, "request_id": "abc-123"})
```

### Application Monitoring

```python
from prometheus_fastapi_instrumentator import Instrumentator
from fastapi import FastAPI

app = FastAPI()

# Prometheus metrics
Instrumentator().instrument(app).expose(app)

# Custom metrics
from prometheus_client import Counter, Histogram

request_count = Counter('app_requests_total', 'Total requests')
request_duration = Histogram('app_request_duration_seconds', 'Request duration')

@app.middleware("http")
async def monitor_requests(request: Request, call_next):
    request_count.inc()
    with request_duration.time():
        response = await call_next(request)
    return response
```

### Error Tracking with Sentry

```python
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration

sentry_sdk.init(
    dsn="your-sentry-dsn",
    integrations=[FastApiIntegration()],
    traces_sample_rate=0.1,
    environment="production"
)

# Errors are automatically captured
@app.get("/api/error")
async def trigger_error():
    raise Exception("Test error for Sentry")
```

## WebSockets and Real-Time Features

### WebSocket Implementation

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

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            await manager.broadcast(f"Message: {data}")
    except WebSocketDisconnect:
        manager.disconnect(websocket)
        await manager.broadcast("Client disconnected")
```

### Chat Application Example

```python
from fastapi import WebSocket
import json

class ChatRoom:
    def __init__(self):
        self.connections: dict[str, WebSocket] = {}
    
    async def connect(self, username: str, websocket: WebSocket):
        await websocket.accept()
        self.connections[username] = websocket
        await self.broadcast({
            "type": "user_joined",
            "username": username,
            "timestamp": datetime.utcnow().isoformat()
        })
    
    async def disconnect(self, username: str):
        if username in self.connections:
            del self.connections[username]
            await self.broadcast({
                "type": "user_left",
                "username": username,
                "timestamp": datetime.utcnow().isoformat()
            })
    
    async def broadcast(self, message: dict):
        for connection in self.connections.values():
            await connection.send_json(message)

chat_room = ChatRoom()

@app.websocket("/chat/{username}")
async def chat_endpoint(websocket: WebSocket, username: str):
    await chat_room.connect(username, websocket)
    try:
        while True:
            data = await websocket.receive_json()
            await chat_room.broadcast({
                "type": "message",
                "username": username,
                "message": data["message"],
                "timestamp": datetime.utcnow().isoformat()
            })
    except WebSocketDisconnect:
        await chat_room.disconnect(username)
```

## GraphQL with Python

### Strawberry GraphQL

```bash
pip install strawberry-graphql[fastapi]
```

```python
import strawberry
from strawberry.fastapi import GraphQLRouter
from typing import List, Optional

@strawberry.type
class Article:
    Id: int
    Title: str
    Content: str
    Author: str

@strawberry.type
class Query:
    @strawberry.field
    def articles(self) -> List[Article]:
        return [
            Article(Id=1, Title="Article 1", Content="Content 1", Author="John"),
            Article(Id=2, Title="Article 2", Content="Content 2", Author="Jane")
        ]
    
    @strawberry.field
    def article(self, id: int) -> Optional[Article]:
        # Fetch from database
        return Article(Id=id, Title=f"Article {id}", Content="Content", Author="John")

@strawberry.type
class Mutation:
    @strawberry.mutation
    def create_article(self, title: str, content: str, author: str) -> Article:
        # Save to database
        return Article(Id=1, Title=title, Content=content, Author=author)

schema = strawberry.Schema(query=Query, mutation=Mutation)
graphql_app = GraphQLRouter(schema)

app.include_router(graphql_app, prefix="/graphql")
```

## Best Practices Summary

### Code Organization

1. **Project Structure**
   - Separate models, views, and business logic
   - Use blueprints/routers for modular organization
   - Keep configuration separate from code

2. **Dependency Management**
   - Use virtual environments
   - Pin dependencies in requirements.txt
   - Use [UV for fast package management](../package-management/uv.md)

3. **Configuration**
   - Use environment variables for secrets
   - Separate settings for development, staging, production
   - Use configuration management tools (e.g., pydantic-settings)

### Performance

1. **Caching**
   - Cache expensive operations
   - Use Redis for distributed caching
   - Implement cache invalidation strategies

2. **Database**
   - Use connection pooling
   - Optimize queries (avoid N+1 problems)
   - Implement proper indexing

3. **Async Operations**
   - Use async/await for I/O-bound operations
   - Implement background tasks for long-running processes
   - Use message queues (Celery, RabbitMQ) for task distribution

### Security

1. **Authentication**
   - Use strong password hashing (bcrypt, argon2)
   - Implement JWT for stateless authentication
   - Enforce password policies

2. **Authorization**
   - Implement role-based access control
   - Validate permissions on every request
   - Use principle of least privilege

3. **Data Protection**
   - Validate and sanitize all inputs
   - Use parameterized queries
   - Implement rate limiting
   - Enable HTTPS only
   - Set security headers

### Testing

1. **Coverage**
   - Write unit tests for business logic
   - Integration tests for API endpoints
   - End-to-end tests for critical workflows
   - Load tests for performance validation

2. **Continuous Integration**
   - Run tests automatically on commits
   - Enforce code coverage thresholds
   - Automate deployment pipelines

## See Also

- [UV Package Manager](../package-management/uv.md)
- [Python Virtual Environments](../package-management/virtualenv.md)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Django Documentation](https://docs.djangoproject.com/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)

## Additional Resources

### Official Documentation

- [FastAPI Official Docs](https://fastapi.tiangolo.com/)
- [Django Project](https://www.djangoproject.com/)
- [Flask Mega-Tutorial](https://blog.miguelgrinberg.com/post/the-flask-mega-tutorial-part-i-hello-world)
- [Python Async Documentation](https://docs.python.org/3/library/asyncio.html)

### Learning Resources

- [Real Python - Web Development Track](https://realpython.com/tutorials/web-dev/)
- [TestDriven.io FastAPI Course](https://testdriven.io/courses/tdd-fastapi/)
- [Full Stack Python](https://www.fullstackpython.com/)
- [Awesome FastAPI](https://github.com/mjhea0/awesome-fastapi)

### Community

- [Django Discord](https://discord.gg/xcRH6mN4fa)
- [FastAPI Discord](https://discord.gg/VQjSZaeJmf)
- [Python Discord](https://discord.gg/python)
- [r/django subreddit](https://www.reddit.com/r/django/)
- [r/Flask subreddit](https://www.reddit.com/r/flask/)

### Tools and Libraries

- [Django REST Framework](https://www.django-rest-framework.org/) - Powerful REST APIs with Django
- [Pydantic](https://docs.pydantic.dev/) - Data validation using Python type hints
- [SQLAlchemy](https://www.sqlalchemy.org/) - SQL toolkit and ORM
- [Alembic](https://alembic.sqlalchemy.org/) - Database migration tool
- [Celery](https://docs.celeryq.dev/) - Distributed task queue
- [Pytest](https://docs.pytest.org/) - Testing framework
