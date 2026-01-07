---
title: SQLAlchemy ORM Guide
description: Comprehensive guide to using SQLAlchemy for database operations in Python
---

## Overview

SQLAlchemy is a powerful SQL toolkit and Object-Relational Mapping (ORM) library for Python. It provides a full suite of enterprise-level persistence patterns designed for efficient and high-performing database access.

## Key Features

- **Dual-layer architecture**: Core (SQL Expression Language) and ORM
- **Database abstraction**: Works with PostgreSQL, MySQL, SQLite, Oracle, and more
- **Session management**: Unit of Work pattern for transaction management
- **Query building**: Pythonic API for constructing SQL queries
- **Schema migrations**: Integration with Alembic for database versioning
- **Connection pooling**: Built-in connection management

## Getting Started

### Installation

```bash
pip install sqlalchemy
```

### Basic Setup

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# Create database engine
engine = create_engine("sqlite:///example.db", echo=True)

# Create declarative base for model classes
Base = declarative_base()

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create all tables
Base.metadata.create_all(bind=engine)
```

**Connection String Formats**:

- **SQLite**: `sqlite:///path/to/database.db` (relative) or `sqlite:////absolute/path/to/database.db`
- **PostgreSQL**: `postgresql://user:password@localhost:5432/dbname`
- **MySQL**: `mysql+pymysql://user:password@localhost:3306/dbname`
- **SQL Server**: `mssql+pyodbc://user:password@localhost/dbname?driver=ODBC+Driver+17+for+SQL+Server`

**Engine Parameters**:

- `echo=True`: Log all SQL statements (useful for debugging)
- `pool_size=5`: Number of connections to maintain in the pool
- `max_overflow=10`: Maximum additional connections beyond pool_size
- `pool_pre_ping=True`: Verify connections before using them

## Core Concepts

### Engine and Connection

The **Engine** is the starting point for SQLAlchemy applications. It maintains a connection pool and provides a source of database connectivity.

```python
from sqlalchemy import create_engine, text

# Create engine
engine = create_engine("postgresql://user:password@localhost/dbname")

# Execute raw SQL using connection
with engine.connect() as connection:
    result = connection.execute(text("SELECT * FROM users"))
    for row in result:
        print(row)

# Using context manager with transaction
with engine.begin() as connection:
    connection.execute(text("INSERT INTO users (name) VALUES (:name)"), {"name": "Alice"})
    # Automatically commits on success, rolls back on exception
```

**Engine Best Practices**:

- Create **one engine per application** and reuse it
- Use **connection pooling** for better performance
- Enable `pool_pre_ping` for long-running applications
- Set appropriate timeout values for your use case
- Use **SSL connections** for production databases

### Declarative Base

The **Declarative Base** is the foundation for defining ORM models. All model classes inherit from it.

```python
from sqlalchemy.orm import declarative_base

# Create base class
Base = declarative_base()

# All models inherit from Base
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True)
    name = Column(String(50))

# Create all tables in database
Base.metadata.create_all(bind=engine)
```

**Modern Declarative Syntax (SQLAlchemy 2.0+)**:

```python
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

class Base(DeclarativeBase):
    pass

class User(Base):
    __tablename__ = "users"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(50))
    email: Mapped[str | None]  # Optional field
```

**Key Points**:

- Use **type annotations** with SQLAlchemy 2.0 for better IDE support
- `Mapped[T]` provides type safety and automatic column configuration
- `metadata` object tracks all table definitions
- Base class can include common methods or columns

### Sessions

The **Session** implements the Unit of Work pattern, managing the persistence lifecycle of objects.

```python
from sqlalchemy.orm import sessionmaker, Session

# Create session factory
SessionLocal = sessionmaker(bind=engine)

# Create and use session
session = SessionLocal()
try:
    # Perform database operations
    user = User(name="Alice")
    session.add(user)
    session.commit()
except Exception as e:
    session.rollback()
    raise
finally:
    session.close()

# Using context manager (recommended)
with Session(engine) as session:
    user = User(name="Bob")
    session.add(user)
    session.commit()
    # Automatically closes session
```

**Session Patterns**:

```python
# Dependency injection pattern (FastAPI, Flask)
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Scoped session (thread-local)
from sqlalchemy.orm import scoped_session

SessionLocal = scoped_session(sessionmaker(bind=engine))

# Access current session
session = SessionLocal()
# Remove when done
SessionLocal.remove()
```

**Key Session Methods**:

- `add(obj)`: Mark object for insertion
- `add_all([obj1, obj2])`: Add multiple objects
- `delete(obj)`: Mark object for deletion
- `commit()`: Persist changes to database
- `rollback()`: Undo uncommitted changes
- `flush()`: Send changes to database without committing
- `refresh(obj)`: Reload object state from database
- `expunge(obj)`: Remove object from session

## Defining Models

Models define the structure of database tables using Python classes.

### Basic Model

```python
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text
from sqlalchemy.sql import func
from datetime import datetime

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(100), unique=True, nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f"<User(username='{self.username}', email='{self.email}')>"
```

### Modern Typed Model (SQLAlchemy 2.0)

```python
from sqlalchemy.orm import Mapped, mapped_column
from typing import Optional
from datetime import datetime

class User(Base):
    __tablename__ = "users"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    email: Mapped[str] = mapped_column(String(100), unique=True)
    full_name: Mapped[Optional[str]] = mapped_column(String(100))
    is_active: Mapped[bool] = mapped_column(default=True)
    created_at: Mapped[datetime] = mapped_column(server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        server_default=func.now(), 
        onupdate=func.now()
    )
```

### Column Types

```python
from sqlalchemy import (
    Integer, String, Text, Boolean, Date, DateTime, Time,
    Float, Numeric, LargeBinary, JSON, Enum, UUID
)
from decimal import Decimal
import enum

class UserRole(enum.Enum):
    ADMIN = "admin"
    USER = "user"
    GUEST = "guest"

class Product(Base):
    __tablename__ = "products"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(200))
    description: Mapped[str] = mapped_column(Text)
    price: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    in_stock: Mapped[bool] = mapped_column(Boolean, default=True)
    release_date: Mapped[datetime] = mapped_column(Date)
    metadata_json: Mapped[dict] = mapped_column(JSON)
    image_data: Mapped[bytes] = mapped_column(LargeBinary)
    category: Mapped[UserRole] = mapped_column(Enum(UserRole))
```

### Constraints

```python
from sqlalchemy import CheckConstraint, UniqueConstraint, Index

class Account(Base):
    __tablename__ = "accounts"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(50))
    email: Mapped[str] = mapped_column(String(100))
    balance: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    
    # Check constraint
    __table_args__ = (
        CheckConstraint("balance >= 0", name="check_positive_balance"),
        UniqueConstraint("username", "email", name="uq_user_email"),
        Index("idx_username_email", "username", "email"),
    )
```

### Composite Primary Keys

```python
class UserRole(Base):
    __tablename__ = "user_roles"
    
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), primary_key=True)
    role_id: Mapped[int] = mapped_column(ForeignKey("roles.id"), primary_key=True)
    assigned_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)
```

### Table Inheritance

```python
# Joined Table Inheritance
class Employee(Base):
    __tablename__ = "employees"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    type: Mapped[str] = mapped_column(String(50))
    
    __mapper_args__ = {
        "polymorphic_on": type,
        "polymorphic_identity": "employee",
    }

class Engineer(Employee):
    __tablename__ = "engineers"
    
    id: Mapped[int] = mapped_column(ForeignKey("employees.id"), primary_key=True)
    engineering_field: Mapped[str] = mapped_column(String(100))
    
    __mapper_args__ = {
        "polymorphic_identity": "engineer",
    }

class Manager(Employee):
    __tablename__ = "managers"
    
    id: Mapped[int] = mapped_column(ForeignKey("employees.id"), primary_key=True)
    department: Mapped[str] = mapped_column(String(100))
    
    __mapper_args__ = {
        "polymorphic_identity": "manager",
    }
```

## CRUD Operations

### Creating Records

```python
from sqlalchemy.orm import Session

# Create single record
with Session(engine) as session:
    user = User(username="alice", email="alice@example.com")
    session.add(user)
    session.commit()
    # user.id is now populated
    print(f"Created user with ID: {user.id}")

# Create multiple records
with Session(engine) as session:
    users = [
        User(username="bob", email="bob@example.com"),
        User(username="charlie", email="charlie@example.com"),
    ]
    session.add_all(users)
    session.commit()

# Create with relationships
with Session(engine) as session:
    user = User(username="david", email="david@example.com")
    post = Post(title="My Post", content="Content here", author=user)
    session.add(post)  # Cascades to user
    session.commit()

# Bulk insert (more efficient)
with Session(engine) as session:
    session.bulk_insert_mappings(
        User,
        [
            {"username": "user1", "email": "user1@example.com"},
            {"username": "user2", "email": "user2@example.com"},
        ]
    )
    session.commit()
```

### Reading Records

```python
from sqlalchemy import select

# Get by primary key
with Session(engine) as session:
    user = session.get(User, 1)
    if user:
        print(user.username)

# Get first result
with Session(engine) as session:
    stmt = select(User).where(User.username == "alice")
    user = session.scalar(stmt)

# Get all results
with Session(engine) as session:
    stmt = select(User).where(User.is_active == True)
    users = session.scalars(stmt).all()
    for user in users:
        print(user.username)

# Get with filter conditions
with Session(engine) as session:
    stmt = select(User).where(
        User.username.like("a%"),
        User.is_active == True
    ).order_by(User.created_at.desc())
    users = session.scalars(stmt).all()

# Get one or raise exception
with Session(engine) as session:
    stmt = select(User).where(User.username == "alice")
    user = session.scalars(stmt).one()  # Raises if not found or multiple

# Get one or None
with Session(engine) as session:
    stmt = select(User).where(User.username == "alice")
    user = session.scalars(stmt).one_or_none()

# Pagination
with Session(engine) as session:
    stmt = select(User).offset(10).limit(10)
    users = session.scalars(stmt).all()

# Count records
from sqlalchemy import func

with Session(engine) as session:
    count = session.scalar(select(func.count()).select_from(User))
    print(f"Total users: {count}")
```

### Updating Records

```python
from sqlalchemy import update

# Update single record via ORM
with Session(engine) as session:
    user = session.get(User, 1)
    if user:
        user.email = "newemail@example.com"
        user.is_active = False
        session.commit()

# Update with query
with Session(engine) as session:
    stmt = select(User).where(User.username == "alice")
    user = session.scalar(stmt)
    if user:
        user.email = "alice_new@example.com"
        session.commit()

# Bulk update using UPDATE statement
with Session(engine) as session:
    stmt = (
        update(User)
        .where(User.is_active == False)
        .values(is_active=True)
    )
    result = session.execute(stmt)
    session.commit()
    print(f"Updated {result.rowcount} rows")

# Update with expression
with Session(engine) as session:
    stmt = (
        update(User)
        .where(User.id == 1)
        .values(login_count=User.login_count + 1)
    )
    session.execute(stmt)
    session.commit()

# Update returning (PostgreSQL)
with Session(engine) as session:
    stmt = (
        update(User)
        .where(User.id == 1)
        .values(email="updated@example.com")
        .returning(User)
    )
    updated_user = session.scalar(stmt)
    session.commit()
```

### Deleting Records

```python
from sqlalchemy import delete

# Delete single record via ORM
with Session(engine) as session:
    user = session.get(User, 1)
    if user:
        session.delete(user)
        session.commit()

# Delete with query
with Session(engine) as session:
    stmt = select(User).where(User.username == "alice")
    user = session.scalar(stmt)
    if user:
        session.delete(user)
        session.commit()

# Bulk delete using DELETE statement
with Session(engine) as session:
    stmt = delete(User).where(User.is_active == False)
    result = session.execute(stmt)
    session.commit()
    print(f"Deleted {result.rowcount} rows")

# Delete with complex condition
with Session(engine) as session:
    stmt = delete(User).where(
        User.created_at < datetime.utcnow() - timedelta(days=365),
        User.is_active == False
    )
    session.execute(stmt)
    session.commit()

# Delete all records (be careful!)
with Session(engine) as session:
    stmt = delete(User)
    session.execute(stmt)
    session.commit()

# Delete with returning (PostgreSQL)
with Session(engine) as session:
    stmt = (
        delete(User)
        .where(User.id == 1)
        .returning(User.id, User.username)
    )
    deleted = session.execute(stmt).first()
    session.commit()
    if deleted:
        print(f"Deleted user: {deleted.username}")
```

## Relationships

### One-to-Many

The most common relationship type where one record relates to multiple records.

```python
from sqlalchemy import ForeignKey
from sqlalchemy.orm import relationship, Mapped, mapped_column
from typing import List

class User(Base):
    __tablename__ = "users"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(50))
    
    # One user has many posts
    posts: Mapped[List["Post"]] = relationship(
        back_populates="author",
        cascade="all, delete-orphan"
    )

class Post(Base):
    __tablename__ = "posts"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(200))
    content: Mapped[str] = mapped_column(Text)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    
    # Many posts belong to one user
    author: Mapped["User"] = relationship(back_populates="posts")

# Usage
with Session(engine) as session:
    user = User(username="alice")
    post1 = Post(title="First Post", content="Content", author=user)
    post2 = Post(title="Second Post", content="More content", author=user)
    
    session.add(user)
    session.commit()
    
    # Access related objects
    print(f"User {user.username} has {len(user.posts)} posts")
    for post in user.posts:
        print(f"  - {post.title}")
```

### Many-to-Many

Relationship where multiple records relate to multiple records, using an association table.

```python
from sqlalchemy import Table, Column, ForeignKey
from typing import List

# Association table
user_group_association = Table(
    "user_group_association",
    Base.metadata,
    Column("user_id", ForeignKey("users.id"), primary_key=True),
    Column("group_id", ForeignKey("groups.id"), primary_key=True),
)

class User(Base):
    __tablename__ = "users"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(50))
    
    # Many users belong to many groups
    groups: Mapped[List["Group"]] = relationship(
        secondary=user_group_association,
        back_populates="members"
    )

class Group(Base):
    __tablename__ = "groups"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    
    # Many groups have many users
    members: Mapped[List["User"]] = relationship(
        secondary=user_group_association,
        back_populates="groups"
    )

# Usage
with Session(engine) as session:
    user1 = User(username="alice")
    user2 = User(username="bob")
    
    group1 = Group(name="Admins")
    group2 = Group(name="Users")
    
    # Add users to groups
    user1.groups.extend([group1, group2])
    user2.groups.append(group2)
    
    session.add_all([user1, user2])
    session.commit()

# Many-to-Many with Association Object (for extra fields)
class UserGroup(Base):
    __tablename__ = "user_group"
    
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), primary_key=True)
    group_id: Mapped[int] = mapped_column(ForeignKey("groups.id"), primary_key=True)
    joined_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)
    role: Mapped[str] = mapped_column(String(50))
    
    # Relationships to parent tables
    user: Mapped["User"] = relationship(back_populates="group_associations")
    group: Mapped["Group"] = relationship(back_populates="member_associations")

class User(Base):
    __tablename__ = "users"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(50))
    
    group_associations: Mapped[List["UserGroup"]] = relationship(
        back_populates="user",
        cascade="all, delete-orphan"
    )

class Group(Base):
    __tablename__ = "groups"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    
    member_associations: Mapped[List["UserGroup"]] = relationship(
        back_populates="group",
        cascade="all, delete-orphan"
    )
```

### One-to-One

Relationship where one record relates to exactly one other record.

```python
from sqlalchemy.orm import relationship, Mapped, mapped_column
from typing import Optional

class User(Base):
    __tablename__ = "users"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(50))
    
    # One user has one profile
    profile: Mapped[Optional["UserProfile"]] = relationship(
        back_populates="user",
        uselist=False,  # Makes it one-to-one
        cascade="all, delete-orphan"
    )

class UserProfile(Base):
    __tablename__ = "user_profiles"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), unique=True)
    bio: Mapped[str] = mapped_column(Text)
    avatar_url: Mapped[str] = mapped_column(String(200))
    
    # One profile belongs to one user
    user: Mapped["User"] = relationship(back_populates="profile")

# Usage
with Session(engine) as session:
    user = User(username="alice")
    profile = UserProfile(
        bio="Software developer",
        avatar_url="https://example.com/avatar.jpg",
        user=user
    )
    
    session.add(user)
    session.commit()
    
    # Access profile
    print(f"User: {user.username}")
    if user.profile:
        print(f"Bio: {user.profile.bio}")

# Alternative: Using unique foreign key as primary key
class UserProfile(Base):
    __tablename__ = "user_profiles"
    
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id"),
        primary_key=True
    )
    bio: Mapped[str] = mapped_column(Text)
    
    user: Mapped["User"] = relationship(back_populates="profile")
```

## Querying

### Basic Queries

```python
from sqlalchemy import select
from sqlalchemy.orm import Session

# Select all columns
with Session(engine) as session:
    stmt = select(User)
    users = session.scalars(stmt).all()

# Select specific columns
with Session(engine) as session:
    stmt = select(User.username, User.email)
    results = session.execute(stmt).all()
    for username, email in results:
        print(f"{username}: {email}")

# Order by
with Session(engine) as session:
    stmt = select(User).order_by(User.created_at.desc())
    users = session.scalars(stmt).all()

# Limit and offset
with Session(engine) as session:
    stmt = select(User).limit(10).offset(20)
    users = session.scalars(stmt).all()

# Distinct
with Session(engine) as session:
    stmt = select(User.email).distinct()
    emails = session.scalars(stmt).all()

# First result
with Session(engine) as session:
    stmt = select(User).order_by(User.id)
    first_user = session.scalars(stmt).first()

# Exists check
from sqlalchemy import exists

with Session(engine) as session:
    stmt = select(exists().where(User.username == "alice"))
    user_exists = session.scalar(stmt)
    print(f"User exists: {user_exists}")
```

### Filtering

```python
from sqlalchemy import select, and_, or_, not_

# Simple equality
with Session(engine) as session:
    stmt = select(User).where(User.username == "alice")
    user = session.scalar(stmt)

# Multiple conditions (AND)
with Session(engine) as session:
    stmt = select(User).where(
        User.is_active == True,
        User.email.like("%@example.com")
    )
    users = session.scalars(stmt).all()

# OR conditions
with Session(engine) as session:
    stmt = select(User).where(
        or_(
            User.username == "alice",
            User.username == "bob"
        )
    )
    users = session.scalars(stmt).all()

# AND and OR combined
with Session(engine) as session:
    stmt = select(User).where(
        and_(
            User.is_active == True,
            or_(
                User.email.like("%@example.com"),
                User.email.like("%@test.com")
            )
        )
    )
    users = session.scalars(stmt).all()

# NOT condition
with Session(engine) as session:
    stmt = select(User).where(not_(User.is_active))
    users = session.scalars(stmt).all()

# IN clause
with Session(engine) as session:
    stmt = select(User).where(User.username.in_(["alice", "bob", "charlie"]))
    users = session.scalars(stmt).all()

# NOT IN clause
with Session(engine) as session:
    stmt = select(User).where(User.username.not_in(["admin", "root"]))
    users = session.scalars(stmt).all()

# LIKE pattern matching
with Session(engine) as session:
    stmt = select(User).where(User.username.like("a%"))  # Starts with 'a'
    users = session.scalars(stmt).all()

# ILIKE (case-insensitive)
with Session(engine) as session:
    stmt = select(User).where(User.email.ilike("%@EXAMPLE.COM"))
    users = session.scalars(stmt).all()

# BETWEEN
from datetime import datetime, timedelta

with Session(engine) as session:
    start_date = datetime.utcnow() - timedelta(days=30)
    end_date = datetime.utcnow()
    stmt = select(User).where(User.created_at.between(start_date, end_date))
    users = session.scalars(stmt).all()

# IS NULL / IS NOT NULL
with Session(engine) as session:
    stmt = select(User).where(User.email.is_(None))
    users = session.scalars(stmt).all()
    
    stmt = select(User).where(User.email.is_not(None))
    users = session.scalars(stmt).all()

# Comparison operators
with Session(engine) as session:
    stmt = select(User).where(
        User.id > 10,
        User.id <= 100
    )
    users = session.scalars(stmt).all()
```

### Joins

```python
from sqlalchemy import select
from sqlalchemy.orm import selectinload, joinedload

# Inner join (explicit)
with Session(engine) as session:
    stmt = (
        select(User, Post)
        .join(Post, User.id == Post.user_id)
    )
    results = session.execute(stmt).all()
    for user, post in results:
        print(f"{user.username} - {post.title}")

# Inner join (using relationship)
with Session(engine) as session:
    stmt = select(User).join(User.posts)
    users = session.scalars(stmt).all()

# Left outer join
with Session(engine) as session:
    stmt = (
        select(User)
        .outerjoin(Post, User.id == Post.user_id)
    )
    users = session.scalars(stmt).all()

# Join with filter
with Session(engine) as session:
    stmt = (
        select(User)
        .join(User.posts)
        .where(Post.title.like("%Python%"))
        .distinct()
    )
    users = session.scalars(stmt).all()

# Multiple joins
with Session(engine) as session:
    stmt = (
        select(User)
        .join(User.posts)
        .join(Post.comments)
        .where(Comment.content.like("%interesting%"))
        .distinct()
    )
    users = session.scalars(stmt).all()

# Join with aliasing
from sqlalchemy.orm import aliased

with Session(engine) as session:
    PostAlias = aliased(Post)
    stmt = (
        select(User)
        .join(PostAlias, User.id == PostAlias.user_id)
        .where(PostAlias.title.like("%Python%"))
    )
    users = session.scalars(stmt).all()

# Self-referential join
class Employee(Base):
    __tablename__ = "employees"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str]
    manager_id: Mapped[Optional[int]] = mapped_column(ForeignKey("employees.id"))
    
    manager: Mapped[Optional["Employee"]] = relationship(
        remote_side=[id],
        back_populates="subordinates"
    )
    subordinates: Mapped[List["Employee"]] = relationship(back_populates="manager")

with Session(engine) as session:
    Manager = aliased(Employee)
    stmt = (
        select(Employee, Manager)
        .outerjoin(Manager, Employee.manager_id == Manager.id)
    )
    results = session.execute(stmt).all()
```

### Aggregations

```python
from sqlalchemy import select, func

# Count all records
with Session(engine) as session:
    count = session.scalar(select(func.count()).select_from(User))
    print(f"Total users: {count}")

# Count with condition
with Session(engine) as session:
    count = session.scalar(
        select(func.count()).select_from(User).where(User.is_active == True)
    )
    print(f"Active users: {count}")

# Count distinct
with Session(engine) as session:
    count = session.scalar(select(func.count(func.distinct(User.email))))
    print(f"Unique emails: {count}")

# Sum
with Session(engine) as session:
    total = session.scalar(select(func.sum(Order.amount)).select_from(Order))
    print(f"Total order amount: {total}")

# Average
with Session(engine) as session:
    avg = session.scalar(select(func.avg(Product.price)).select_from(Product))
    print(f"Average price: {avg}")

# Min and Max
with Session(engine) as session:
    min_price = session.scalar(select(func.min(Product.price)).select_from(Product))
    max_price = session.scalar(select(func.max(Product.price)).select_from(Product))
    print(f"Price range: ${min_price} - ${max_price}")

# Group by
with Session(engine) as session:
    stmt = (
        select(User.id, User.username, func.count(Post.id).label("post_count"))
        .outerjoin(Post, User.id == Post.user_id)
        .group_by(User.id, User.username)
        .order_by(func.count(Post.id).desc())
    )
    results = session.execute(stmt).all()
    for user_id, username, post_count in results:
        print(f"{username}: {post_count} posts")

# Having clause
with Session(engine) as session:
    stmt = (
        select(User.id, User.username, func.count(Post.id).label("post_count"))
        .join(Post, User.id == Post.user_id)
        .group_by(User.id, User.username)
        .having(func.count(Post.id) > 5)
    )
    results = session.execute(stmt).all()

# Multiple aggregations
with Session(engine) as session:
    stmt = select(
        func.count(Order.id).label("total_orders"),
        func.sum(Order.amount).label("total_amount"),
        func.avg(Order.amount).label("avg_amount"),
        func.min(Order.amount).label("min_amount"),
        func.max(Order.amount).label("max_amount")
    ).select_from(Order)
    
    result = session.execute(stmt).first()
    print(f"Orders: {result.total_orders}")
    print(f"Total: ${result.total_amount}")
    print(f"Average: ${result.avg_amount}")

# Group by with multiple columns
with Session(engine) as session:
    stmt = (
        select(
            Order.status,
            func.date_trunc('day', Order.created_at).label('date'),
            func.count(Order.id).label('count')
        )
        .group_by(Order.status, func.date_trunc('day', Order.created_at))
        .order_by('date', Order.status)
    )
    results = session.execute(stmt).all()
```

## Advanced Topics

### Eager Loading

Eager loading prevents the N+1 query problem by loading related objects upfront.

```python
from sqlalchemy.orm import selectinload, joinedload, subqueryload, contains_eager

# Lazy loading (default) - causes N+1 queries
with Session(engine) as session:
    users = session.scalars(select(User)).all()
    for user in users:
        print(f"{user.username} has {len(user.posts)} posts")  # N queries!

# Joined load (single query with JOIN)
with Session(engine) as session:
    stmt = select(User).options(joinedload(User.posts))
    users = session.scalars(stmt).unique().all()  # unique() needed with joinedload
    for user in users:
        print(f"{user.username} has {len(user.posts)} posts")  # No extra queries!

# Selectin load (two queries, IN clause)
with Session(engine) as session:
    stmt = select(User).options(selectinload(User.posts))
    users = session.scalars(stmt).all()
    for user in users:
        print(f"{user.username} has {len(user.posts)} posts")

# Subquery load (two queries, subquery)
with Session(engine) as session:
    stmt = select(User).options(subqueryload(User.posts))
    users = session.scalars(stmt).all()

# Nested eager loading
with Session(engine) as session:
    stmt = select(User).options(
        selectinload(User.posts).selectinload(Post.comments)
    )
    users = session.scalars(stmt).all()
    for user in users:
        for post in user.posts:
            print(f"{post.title}: {len(post.comments)} comments")

# Multiple relationships
with Session(engine) as session:
    stmt = select(User).options(
        selectinload(User.posts),
        selectinload(User.groups)
    )
    users = session.scalars(stmt).all()

# Contains eager (use with explicit joins)
with Session(engine) as session:
    stmt = (
        select(User)
        .join(User.posts)
        .options(contains_eager(User.posts))
        .where(Post.published == True)
    )
    users = session.scalars(stmt).unique().all()

# Raiseload (prevent lazy loading)
from sqlalchemy.orm import raiseload

with Session(engine) as session:
    stmt = select(User).options(raiseload(User.posts))
    users = session.scalars(stmt).all()
    # This would raise an exception:
    # print(users[0].posts)
```

**Loading Strategy Comparison**:

- **joinedload**: Single query with LEFT OUTER JOIN, good for one-to-one/many-to-one
- **selectinload**: Two queries with IN clause, best for one-to-many/many-to-many
- **subqueryload**: Two queries with subquery, alternative to selectinload
- **contains_eager**: Use with explicit JOIN, gives control over JOIN conditions

### Raw SQL

Execute raw SQL when ORM isn't suitable for complex queries.

```python
from sqlalchemy import text

# Execute raw SQL
with Session(engine) as session:
    result = session.execute(text("SELECT * FROM users WHERE username = :username"), 
                            {"username": "alice"})
    for row in result:
        print(row)

# Fetch single value
with Session(engine) as session:
    count = session.scalar(text("SELECT COUNT(*) FROM users"))
    print(f"Total users: {count}")

# Map results to ORM objects
with Session(engine) as session:
    result = session.execute(
        text("SELECT * FROM users WHERE is_active = :active")
        .bindparams(active=True)
    )
    users = [User(**row._mapping) for row in result]

# Use from_statement for ORM objects
with Session(engine) as session:
    stmt = text("SELECT * FROM users WHERE username LIKE :pattern")
    users = session.scalars(
        select(User).from_statement(stmt),
        {"pattern": "a%"}
    ).all()

# Insert with raw SQL
with Session(engine) as session:
    session.execute(
        text("INSERT INTO users (username, email) VALUES (:username, :email)"),
        {"username": "newuser", "email": "new@example.com"}
    )
    session.commit()

# Bulk operations
with Session(engine) as session:
    session.execute(
        text("INSERT INTO users (username, email) VALUES (:username, :email)"),
        [
            {"username": "user1", "email": "user1@example.com"},
            {"username": "user2", "email": "user2@example.com"},
        ]
    )
    session.commit()

# Complex query with CTE
with Session(engine) as session:
    query = text("""
        WITH active_users AS (
            SELECT id, username FROM users WHERE is_active = true
        )
        SELECT au.username, COUNT(p.id) as post_count
        FROM active_users au
        LEFT JOIN posts p ON au.id = p.user_id
        GROUP BY au.username
        ORDER BY post_count DESC
    """)
    results = session.execute(query).all()

# Database-specific functions
with Session(engine) as session:
    # PostgreSQL specific
    result = session.execute(text("""
        SELECT username, 
               ts_rank(to_tsvector('english', bio), query) AS rank
        FROM user_profiles, to_tsquery('english', :search) query
        WHERE to_tsvector('english', bio) @@ query
        ORDER BY rank DESC
    """), {"search": "python & developer"})
```

### Connection Pooling

SQLAlchemy includes sophisticated connection pooling for performance.

```python
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool, NullPool, StaticPool

# Default QueuePool
engine = create_engine(
    "postgresql://user:password@localhost/dbname",
    pool_size=5,           # Number of connections to maintain
    max_overflow=10,       # Additional connections when pool exhausted
    pool_timeout=30,       # Seconds to wait for connection
    pool_recycle=3600,     # Recycle connections after 1 hour
    pool_pre_ping=True,    # Verify connections before use
)

# Custom pool configuration
engine = create_engine(
    "postgresql://user:password@localhost/dbname",
    poolclass=QueuePool,
    pool_size=20,
    max_overflow=0,        # No overflow, strict limit
    pool_timeout=60,
)

# NullPool (no pooling, create new connection each time)
engine = create_engine(
    "postgresql://user:password@localhost/dbname",
    poolclass=NullPool
)

# StaticPool (single connection, for SQLite)
engine = create_engine(
    "sqlite:///database.db",
    poolclass=StaticPool,
    connect_args={"check_same_thread": False}
)

# Pool event listeners
from sqlalchemy import event

@event.listens_for(engine, "connect")
def receive_connect(dbapi_conn, connection_record):
    print("New database connection established")

@event.listens_for(engine, "checkout")
def receive_checkout(dbapi_conn, connection_record, connection_proxy):
    print("Connection checked out from pool")

@event.listens_for(engine, "checkin")
def receive_checkin(dbapi_conn, connection_record):
    print("Connection returned to pool")

# Pool statistics
pool = engine.pool
print(f"Pool size: {pool.size()}")
print(f"Checked out connections: {pool.checkedout()}")
print(f"Overflow: {pool.overflow()}")
print(f"Checked in: {pool.checkedin()}")

# Dispose pool (close all connections)
engine.dispose()
```

**Pool Types**:

- **QueuePool** (default): Maintains pool of connections, thread-safe
- **NullPool**: No pooling, creates new connection per request
- **StaticPool**: Single connection shared by all threads
- **AssertionPool**: QueuePool with assertion checking for testing

**Best Practices**:

- Set `pool_pre_ping=True` for long-running applications
- Configure `pool_recycle` less than database timeout
- Monitor pool usage in production
- Use appropriate pool size based on workload

### Event System

SQLAlchemy provides hooks for custom logic at various lifecycle points.

```python
from sqlalchemy import event
from datetime import datetime

# Before insert
@event.listens_for(User, "before_insert")
def before_insert(mapper, connection, target):
    print(f"About to insert: {target.username}")
    target.created_at = datetime.utcnow()

# After insert
@event.listens_for(User, "after_insert")
def after_insert(mapper, connection, target):
    print(f"Inserted user with ID: {target.id}")

# Before update
@event.listens_for(User, "before_update")
def before_update(mapper, connection, target):
    target.updated_at = datetime.utcnow()

# After update
@event.listens_for(User, "after_update")
def after_update(mapper, connection, target):
    print(f"Updated user: {target.username}")

# Before delete
@event.listens_for(User, "before_delete")
def before_delete(mapper, connection, target):
    print(f"About to delete: {target.username}")

# After delete
@event.listens_for(User, "after_delete")
def after_delete(mapper, connection, target):
    print(f"Deleted user: {target.username}")

# Attribute events
from sqlalchemy.orm import attributes

@event.listens_for(User.email, "set")
def receive_set(target, value, oldvalue, initiator):
    print(f"Email changed from {oldvalue} to {value}")
    return value.lower()  # Normalize email

# Session events
@event.listens_for(Session, "before_commit")
def before_commit(session):
    print("About to commit transaction")

@event.listens_for(Session, "after_commit")
def after_commit(session):
    print("Transaction committed")

@event.listens_for(Session, "after_rollback")
def after_rollback(session):
    print("Transaction rolled back")

# Connection pool events
@event.listens_for(engine, "connect")
def connect(dbapi_conn, connection_record):
    print("New connection established")

@event.listens_for(engine, "checkout")
def checkout(dbapi_conn, connection_record, connection_proxy):
    print("Connection checked out")

# Bulk operations
@event.listens_for(Session, "after_bulk_insert")
def after_bulk_insert(mapper, connection, target):
    print(f"Bulk insert into {mapper.class_.__name__}")

# Audit log example
class AuditLog(Base):
    __tablename__ = "audit_log"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    table_name: Mapped[str] = mapped_column(String(50))
    action: Mapped[str] = mapped_column(String(10))
    record_id: Mapped[int]
    timestamp: Mapped[datetime] = mapped_column(default=datetime.utcnow)
    user_id: Mapped[int | None]

@event.listens_for(User, "after_insert")
@event.listens_for(User, "after_update")
@event.listens_for(User, "after_delete")
def log_changes(mapper, connection, target):
    audit = AuditLog(
        table_name="users",
        action="INSERT",  # Determine from context
        record_id=target.id,
    )
    # Log to database
```

## Best Practices

### Session Management

```python
# ✅ Use context managers
with Session(engine) as session:
    user = session.get(User, 1)
    session.commit()

# ✅ Dependency injection (FastAPI)
from typing import Generator

def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ❌ Avoid long-lived sessions
session = SessionLocal()
user = session.get(User, 1)
# ... many operations later ...
session.commit()  # Don't do this
```

### Query Optimization

```python
# ✅ Use eager loading to prevent N+1 queries
stmt = select(User).options(selectinload(User.posts))
users = session.scalars(stmt).all()

# ✅ Select only needed columns
stmt = select(User.id, User.username).where(User.is_active == True)
results = session.execute(stmt).all()

# ✅ Use indexes on frequently queried columns
class User(Base):
    __tablename__ = "users"
    username: Mapped[str] = mapped_column(String(50), index=True)
    email: Mapped[str] = mapped_column(String(100), unique=True)  # Implicit index

# ❌ Avoid loading unnecessary data
users = session.scalars(select(User)).all()  # Loads all columns
for user in users:
    print(user.username)  # Only needed username
```

### Model Design

```python
# ✅ Use type annotations (SQLAlchemy 2.0+)
class User(Base):
    __tablename__ = "users"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(50))
    email: Mapped[str | None]  # Optional field

# ✅ Add helpful __repr__ methods
def __repr__(self):
    return f"<User(id={self.id}, username='{self.username}')>"

# ✅ Use appropriate relationships with cascade
class User(Base):
    posts: Mapped[List["Post"]] = relationship(
        back_populates="author",
        cascade="all, delete-orphan"  # Delete posts when user deleted
    )

# ✅ Add database constraints
class Account(Base):
    balance: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    
    __table_args__ = (
        CheckConstraint("balance >= 0", name="positive_balance"),
    )
```

### Error Handling

```python
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

# ✅ Handle specific exceptions
try:
    with Session(engine) as session:
        user = User(username="existing", email="test@example.com")
        session.add(user)
        session.commit()
except IntegrityError as e:
    print("User already exists or constraint violated")
except SQLAlchemyError as e:
    print(f"Database error: {e}")

# ✅ Always rollback on error
try:
    with Session(engine) as session:
        # operations
        session.commit()
except Exception:
    session.rollback()
    raise
```

### Security

```python
# ✅ Use parameterized queries
stmt = select(User).where(User.username == username)  # Safe

# ❌ Never concatenate user input
stmt = text(f"SELECT * FROM users WHERE username = '{username}'")  # SQL injection!

# ✅ Use bound parameters with text()
stmt = text("SELECT * FROM users WHERE username = :username")
result = session.execute(stmt, {"username": username})

# ✅ Validate input data
from pydantic import BaseModel, EmailStr

class UserCreate(BaseModel):
    username: str
    email: EmailStr

# ✅ Hash passwords
import bcrypt

class User(Base):
    password_hash: Mapped[str] = mapped_column(String(255))
    
    def set_password(self, password: str):
        self.password_hash = bcrypt.hashpw(
            password.encode('utf-8'),
            bcrypt.gensalt()
        ).decode('utf-8')
    
    def check_password(self, password: str) -> bool:
        return bcrypt.checkpw(
            password.encode('utf-8'),
            self.password_hash.encode('utf-8')
        )
```

## Performance Optimization

### Bulk Operations

```python
# Bulk insert (fastest)
with Session(engine) as session:
    session.bulk_insert_mappings(
        User,
        [
            {"username": "user1", "email": "user1@example.com"},
            {"username": "user2", "email": "user2@example.com"},
        ]
    )
    session.commit()

# Bulk update
with Session(engine) as session:
    session.bulk_update_mappings(
        User,
        [
            {"id": 1, "is_active": False},
            {"id": 2, "is_active": False},
        ]
    )
    session.commit()

# Core insert (even faster)
from sqlalchemy import insert

with engine.begin() as conn:
    stmt = insert(User).values([
        {"username": "user1", "email": "user1@example.com"},
        {"username": "user2", "email": "user2@example.com"},
    ])
    conn.execute(stmt)
```

### Efficient Querying

```python
# Use yield_per for large result sets
with Session(engine) as session:
    stmt = select(User)
    for user in session.scalars(stmt).yield_per(1000):
        process_user(user)

# Use streaming results
with Session(engine) as session:
    result = session.execute(select(User)).partitions(100)
    for partition in result:
        process_batch(partition)

# Limit query results
stmt = select(User).limit(100)

# Use exists() instead of count() for boolean checks
from sqlalchemy import exists

# Slow
count = session.scalar(select(func.count()).select_from(User).where(...))
if count > 0:
    # ...

# Fast
exists_stmt = select(exists().where(User.username == "alice"))
if session.scalar(exists_stmt):
    # ...
```

### Caching Strategies

```python
from functools import lru_cache
from cachetools import TTLCache, cached

# Application-level caching
cache = TTLCache(maxsize=1000, ttl=300)  # 5-minute TTL

@cached(cache)
def get_user_by_username(username: str) -> User | None:
    with Session(engine) as session:
        return session.scalar(select(User).where(User.username == username))

# Query result caching
from sqlalchemy.ext.caching import CachingQuery

# Use dogpile.cache for production
import dogpile.cache

region = dogpile.cache.make_region().configure(
    'dogpile.cache.redis',
    expiration_time=3600,
    arguments={'host': 'localhost', 'port': 6379}
)

# Second-level cache
from sqlalchemy.ext.horizontal_shard import set_shard_id
```

### Optimizing Connection Pools

```python
# Optimize pool settings for your workload
engine = create_engine(
    "postgresql://user:password@localhost/dbname",
    pool_size=20,           # Increase for high concurrency
    max_overflow=10,
    pool_timeout=30,
    pool_recycle=3600,      # Prevent stale connections
    pool_pre_ping=True,     # Verify connections
    echo_pool=True,         # Debug pool usage
)
```

### Index Usage

```python
class User(Base):
    __tablename__ = "users"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(50), index=True)
    email: Mapped[str] = mapped_column(String(100), unique=True)
    
    # Composite index
    __table_args__ = (
        Index("idx_username_email", "username", "email"),
        Index("idx_created", "created_at"),
    )

# Use EXPLAIN to analyze queries
with Session(engine) as session:
    stmt = select(User).where(User.username == "alice")
    explain = session.execute(text(f"EXPLAIN {stmt}"))
    print(explain.fetchall())
```

### Lazy vs Eager Loading

```python
# Profile your queries
import time

# Lazy loading (N+1 problem)
start = time.time()
with Session(engine) as session:
    users = session.scalars(select(User)).all()
    for user in users:
        print(len(user.posts))  # N queries!
print(f"Lazy: {time.time() - start}s")

# Eager loading (2 queries)
start = time.time()
with Session(engine) as session:
    stmt = select(User).options(selectinload(User.posts))
    users = session.scalars(stmt).all()
    for user in users:
        print(len(user.posts))
print(f"Eager: {time.time() - start}s")
```

## Testing

### Test Database Setup

```python
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import StaticPool

# Use in-memory SQLite for tests
TEST_DATABASE_URL = "sqlite:///:memory:"

@pytest.fixture(scope="function")
def engine():
    engine = create_engine(
        TEST_DATABASE_URL,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
        echo=True
    )
    Base.metadata.create_all(bind=engine)
    yield engine
    Base.metadata.drop_all(bind=engine)
    engine.dispose()

@pytest.fixture(scope="function")
def session(engine):
    SessionLocal = sessionmaker(bind=engine)
    session = SessionLocal()
    yield session
    session.close()
```

### Testing Models

```python
def test_create_user(session: Session):
    user = User(username="testuser", email="test@example.com")
    session.add(user)
    session.commit()
    
    assert user.id is not None
    assert user.username == "testuser"
    assert user.email == "test@example.com"

def test_user_relationships(session: Session):
    user = User(username="alice", email="alice@example.com")
    post = Post(title="Test Post", content="Content", author=user)
    
    session.add(user)
    session.commit()
    
    assert len(user.posts) == 1
    assert user.posts[0].title == "Test Post"
    assert post.author == user

def test_unique_constraint(session: Session):
    user1 = User(username="alice", email="alice@example.com")
    session.add(user1)
    session.commit()
    
    user2 = User(username="alice", email="alice2@example.com")
    session.add(user2)
    
    with pytest.raises(IntegrityError):
        session.commit()
```

### Testing Queries

```python
from sqlalchemy import select

def test_query_users(session: Session):
    # Setup
    users = [
        User(username="alice", email="alice@example.com"),
        User(username="bob", email="bob@example.com"),
        User(username="charlie", email="charlie@example.com"),
    ]
    session.add_all(users)
    session.commit()
    
    # Test
    stmt = select(User).where(User.username.like("a%"))
    results = session.scalars(stmt).all()
    
    assert len(results) == 1
    assert results[0].username == "alice"

def test_query_with_join(session: Session):
    user = User(username="alice", email="alice@example.com")
    post = Post(title="Test", content="Content", author=user)
    session.add(user)
    session.commit()
    
    stmt = select(User).join(User.posts).where(Post.title == "Test")
    result = session.scalar(stmt)
    
    assert result.username == "alice"
```

### Mocking and Patching

```python
from unittest.mock import Mock, patch

def test_with_mock_session():
    mock_session = Mock(spec=Session)
    mock_user = User(id=1, username="alice", email="alice@example.com")
    mock_session.get.return_value = mock_user
    
    result = mock_session.get(User, 1)
    
    assert result.username == "alice"
    mock_session.get.assert_called_once_with(User, 1)

@patch('myapp.database.SessionLocal')
def test_with_patched_session(mock_session_factory):
    mock_session = Mock()
    mock_session_factory.return_value = mock_session
    
    # Test your code that uses SessionLocal
    session = SessionLocal()
    session.add(User(username="test"))
    
    mock_session.add.assert_called_once()
```

### Integration Testing

```python
import pytest
from fastapi.testclient import TestClient
from myapp.main import app
from myapp.database import get_db, Base, engine

@pytest.fixture(scope="module")
def client():
    # Setup test database
    Base.metadata.create_all(bind=engine)
    
    # Override dependency
    def override_get_db():
        try:
            db = TestingSessionLocal()
            yield db
        finally:
            db.close()
    
    app.dependency_overrides[get_db] = override_get_db
    
    with TestClient(app) as test_client:
        yield test_client
    
    # Teardown
    Base.metadata.drop_all(bind=engine)

def test_create_user_endpoint(client):
    response = client.post(
        "/users/",
        json={"username": "alice", "email": "alice@example.com"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["username"] == "alice"
    assert "id" in data
```

### Transaction Testing

```python
def test_transaction_rollback(session: Session):
    user = User(username="alice", email="alice@example.com")
    session.add(user)
    session.flush()  # Generate ID but don't commit
    
    user_id = user.id
    session.rollback()
    
    # User should not exist
    result = session.get(User, user_id)
    assert result is None

def test_nested_transaction(session: Session):
    user = User(username="alice", email="alice@example.com")
    session.add(user)
    
    # Create savepoint
    savepoint = session.begin_nested()
    
    user.email = "newemail@example.com"
    savepoint.rollback()
    
    # Email change should be rolled back
    session.refresh(user)
    assert user.email == "alice@example.com"
```

### Factory Pattern for Tests

```python
from factory import Factory, Faker, Sequence
from factory.alchemy import SQLAlchemyModelFactory

class UserFactory(SQLAlchemyModelFactory):
    class Meta:
        model = User
        sqlalchemy_session = session
        sqlalchemy_session_persistence = "commit"
    
    username = Sequence(lambda n: f"user{n}")
    email = Faker("email")
    is_active = True

class PostFactory(SQLAlchemyModelFactory):
    class Meta:
        model = Post
        sqlalchemy_session = session
    
    title = Faker("sentence")
    content = Faker("text")
    author = factory.SubFactory(UserFactory)

# Usage
def test_with_factory(session: Session):
    user = UserFactory.create()
    post = PostFactory.create(author=user)
    
    assert user.id is not None
    assert post.author == user
    
    # Create batch
    users = UserFactory.create_batch(10)
    assert len(users) == 10
```

## Migration with Alembic

Alembic is the database migration tool for SQLAlchemy.

### Installation and Setup

```bash
# Install Alembic
pip install alembic

# Initialize Alembic in project
alembic init alembic
```

This creates:

```text
alembic/
    env.py              # Migration environment configuration
    script.py.mako      # Template for new migrations
    versions/           # Migration scripts directory
alembic.ini             # Alembic configuration
```

### Configuration

Edit `alembic.ini`:

```ini
# Set database URL
sqlalchemy.url = postgresql://user:password@localhost/dbname

# Or use environment variable
# sqlalchemy.url = driver://user:pass@localhost/dbname
```

Edit `alembic/env.py`:

```python
from myapp.database import Base
from myapp.models import User, Post  # Import all models

# Set target metadata
target_metadata = Base.metadata

# Use environment variable for URL
import os
from sqlalchemy import engine_from_config, pool

config.set_main_option(
    "sqlalchemy.url",
    os.getenv("DATABASE_URL", "sqlite:///./app.db")
)
```

### Creating Migrations

```bash
# Auto-generate migration from model changes
alembic revision --autogenerate -m "create users table"

# Create empty migration
alembic revision -m "custom migration"

# Review generated migration in alembic/versions/
```

### Migration Script Example

```python
"""create users table

Revision ID: 1a2b3c4d5e6f
Revises: 
Create Date: 2024-01-01 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers
revision = '1a2b3c4d5e6f'
down_revision = None
branch_labels = None
depends_on = None

def upgrade() -> None:
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('username', sa.String(length=50), nullable=False),
        sa.Column('email', sa.String(length=100), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('email'),
        sa.UniqueConstraint('username')
    )
    op.create_index('ix_users_username', 'users', ['username'])

def downgrade() -> None:
    op.drop_index('ix_users_username', table_name='users')
    op.drop_table('users')
```

### Running Migrations

```bash
# Apply all pending migrations
alembic upgrade head

# Apply specific number of migrations
alembic upgrade +2

# Upgrade to specific revision
alembic upgrade 1a2b3c4d5e6f

# Downgrade one migration
alembic downgrade -1

# Downgrade to specific revision
alembic downgrade 1a2b3c4d5e6f

# Downgrade all migrations
alembic downgrade base
```

### Migration History

```bash
# Show current revision
alembic current

# Show migration history
alembic history

# Show pending migrations
alembic history --verbose

# Show SQL without executing
alembic upgrade head --sql
```

### Common Migration Operations

```python
from alembic import op
import sqlalchemy as sa

def upgrade() -> None:
    # Add column
    op.add_column('users', sa.Column('phone', sa.String(20), nullable=True))
    
    # Drop column
    op.drop_column('users', 'old_column')
    
    # Alter column
    op.alter_column('users', 'username',
                   existing_type=sa.String(50),
                   type_=sa.String(100),
                   nullable=False)
    
    # Rename column
    op.alter_column('users', 'name', new_column_name='username')
    
    # Add index
    op.create_index('ix_users_email', 'users', ['email'])
    
    # Drop index
    op.drop_index('ix_users_email', table_name='users')
    
    # Add constraint
    op.create_unique_constraint('uq_users_email', 'users', ['email'])
    
    # Drop constraint
    op.drop_constraint('uq_users_email', 'users', type_='unique')
    
    # Add foreign key
    op.create_foreign_key(
        'fk_posts_user_id',
        'posts', 'users',
        ['user_id'], ['id']
    )
    
    # Drop foreign key
    op.drop_constraint('fk_posts_user_id', 'posts', type_='foreignkey')

def downgrade() -> None:
    # Reverse operations
    pass
```

### Data Migrations

```python
from alembic import op
import sqlalchemy as sa
from sqlalchemy import table, column

def upgrade() -> None:
    # Define table reference
    users_table = table('users',
        column('id', sa.Integer),
        column('username', sa.String),
        column('is_active', sa.Boolean)
    )
    
    # Update existing data
    op.execute(
        users_table.update()
        .where(users_table.c.is_active == None)
        .values(is_active=True)
    )
    
    # Bulk insert
    op.bulk_insert(users_table, [
        {'username': 'admin', 'is_active': True},
        {'username': 'guest', 'is_active': False},
    ])
    
    # Execute raw SQL
    op.execute("""
        UPDATE users
        SET email = LOWER(email)
        WHERE email IS NOT NULL
    """)
```

### Branching and Merging

```bash
# Create branch
alembic revision -m "branch a" --head=base --branch-label=brancha
alembic revision -m "branch b" --head=base --branch-label=branchb

# Merge branches
alembic merge -m "merge branches" heads

# Show branches
alembic branches
```

### Migration Best Practices

```python
# Always review auto-generated migrations
# Check for:
# - Data loss (dropping columns/tables)
# - Missing indexes
# - Constraint issues

# Use transactions (default)
def upgrade() -> None:
    # All operations in a transaction
    op.add_column('users', sa.Column('new_col', sa.String(50)))

# Disable transactions if needed
def upgrade() -> None:
    # For operations that can't run in transactions
    # (e.g., CREATE INDEX CONCURRENTLY in PostgreSQL)
    connection = op.get_bind()
    connection.execute(sa.text("COMMIT"))
    connection.execute(sa.text(
        "CREATE INDEX CONCURRENTLY ix_users_email ON users(email)"
    ))

# Add comments for complex migrations
def upgrade() -> None:
    """
    This migration:
    1. Adds new column 'status'
    2. Migrates data from 'is_active' to 'status'
    3. Drops 'is_active' column
    """
    op.add_column('users', sa.Column('status', sa.String(20)))
    # ... rest of migration
```

## See Also

- [Python Overview](../index.md)
- [PostgreSQL](../../databases/postgresql.md)
- [API Development](../apis/rest-api.md)

## Resources

- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
- [SQLAlchemy Tutorial](https://docs.sqlalchemy.org/en/20/tutorial/)
- [Alembic Documentation](https://alembic.sqlalchemy.org/)
