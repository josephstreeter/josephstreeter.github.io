---
title: GraphQL API in Python
description: Comprehensive guide to working with GraphQL APIs in Python, including queries, mutations, subscriptions, and best practices
---

GraphQL is a query language for APIs and a runtime for executing those queries with your existing data. Unlike REST APIs, GraphQL provides a complete and understandable description of the data in your API, gives clients the power to ask for exactly what they need, and enables powerful developer tools.

## Overview

GraphQL represents a paradigm shift in API design, moving away from multiple REST endpoints to a single endpoint that accepts queries describing exactly what data is needed. This approach eliminates over-fetching and under-fetching of data, reduces the number of API calls, and provides strongly-typed schemas that serve as contracts between client and server.

In Python, several mature libraries make working with GraphQL straightforward, whether you're building a GraphQL server or consuming GraphQL APIs. The ecosystem includes tools for schema definition, query execution, type validation, and advanced features like subscriptions and federation.

## Getting Started

### Prerequisites

Before working with GraphQL in Python, ensure you have:

- Python 3.8 or higher installed
- Basic understanding of API concepts
- Familiarity with JSON data structures
- (Optional) Understanding of async/await for advanced features

### Quick Start

Install a GraphQL client library:

```bash
pip install gql[all]
```

Make your first GraphQL query:

```python
from gql import gql, Client
from gql.transport.requests import RequestsHTTPTransport

# Create a transport
transport = RequestsHTTPTransport(
    url="https://api.example.com/graphql",
    headers={"Authorization": "Bearer YOUR_TOKEN"}
)

# Create a client
client = Client(transport=transport, fetch_schema_from_transport=True)

# Define a query
query = gql("""
    query GetUser($id: ID!) {
        user(id: $id) {
            id
            name
            email
        }
    }
""")

# Execute the query
result = client.execute(query, variable_values={"id": "123"})
print(result)
```

## Basic Concepts

### What is GraphQL

GraphQL is a specification for a query language created by Facebook in 2012 and open-sourced in 2015. It provides an alternative to REST APIs by allowing clients to request exactly the data they need through a single endpoint.

**Key Characteristics:**

- **Declarative data fetching**: Clients specify exactly what data they need
- **Single endpoint**: All requests go to one URL (typically `/graphql`)
- **Strongly typed schema**: The API's structure is defined by a type system
- **Introspective**: Clients can query the schema itself to discover capabilities
- **Hierarchical**: Queries match the shape of the data returned
- **Version-free**: Add new fields without breaking existing queries

### GraphQL vs REST

Understanding the differences helps you choose the right approach for your project:

| Feature | REST | GraphQL |
| --- | --- | --- |
| **Endpoints** | Multiple endpoints per resource | Single endpoint |
| **Data Fetching** | Fixed data structure per endpoint | Client specifies exact data needed |
| **Over-fetching** | Common (get unnecessary data) | Eliminated |
| **Under-fetching** | Common (need multiple requests) | Eliminated |
| **Versioning** | Required (v1, v2, etc.) | Not needed (additive changes) |
| **Caching** | HTTP caching built-in | Requires custom implementation |
| **Learning Curve** | Lower | Higher |
| **Tooling** | Mature ecosystem | Growing ecosystem |

**When to Use GraphQL:**

- Mobile applications with limited bandwidth
- Complex data requirements with nested relationships
- Rapid frontend development with changing requirements
- Multiple clients with different data needs
- Real-time features with subscriptions

**When to Use REST:**

- Simple CRUD operations
- File uploads/downloads
- Leveraging HTTP caching extensively
- Team unfamiliar with GraphQL
- Public APIs requiring wide compatibility

### Core GraphQL Concepts

#### Schema

The schema defines the structure of your API using the GraphQL Schema Definition Language (SDL):

```graphql
type User {
    id: ID!
    name: String!
    email: String!
    posts: [Post!]!
    createdAt: DateTime!
}

type Post {
    id: ID!
    title: String!
    content: String!
    author: User!
    published: Boolean!
}

type Query {
    user(id: ID!): User
    users(limit: Int, offset: Int): [User!]!
    post(id: ID!): Post
}

type Mutation {
    createUser(name: String!, email: String!): User!
    updateUser(id: ID!, name: String, email: String): User!
    deleteUser(id: ID!): Boolean!
}
```

#### Queries

Queries are read operations that fetch data:

```graphql
query GetUserWithPosts {
    user(id: "123") {
        id
        name
        email
        posts {
            id
            title
            published
        }
    }
}
```

#### Mutations

Mutations are write operations that modify data:

```graphql
mutation CreateNewUser {
    createUser(name: "John Doe", email: "john@example.com") {
        id
        name
        email
        createdAt
    }
}
```

#### Subscriptions

Subscriptions enable real-time updates via WebSocket:

```graphql
subscription OnNewPost {
    postCreated {
        id
        title
        author {
            name
        }
    }
}
```

#### Fields and Arguments

Fields are properties you request, arguments customize the query:

```graphql
query {
    users(limit: 10, offset: 20, orderBy: "createdAt") {
        id
        name
    }
}
```

#### Aliases

Rename fields in the response to avoid conflicts:

```graphql
query {
    firstUser: user(id: "1") {
        name
    }
    secondUser: user(id: "2") {
        name
    }
}
```

#### Fragments

Reusable pieces of query logic:

```graphql
fragment UserFields on User {
    id
    name
    email
}

query {
    user(id: "1") {
        ...UserFields
        posts {
            id
            title
        }
    }
}
```

#### Variables

Parameterize queries for reusability and security:

```graphql
query GetUser($userId: ID!, $includeEmail: Boolean!) {
    user(id: $userId) {
        id
        name
        email @include(if: $includeEmail)
    }
}
```

Variables passed separately:

```json
{
    "userId": "123",
    "includeEmail": true
}
```

#### Directives

Modify query execution behavior:

- `@include(if: Boolean)`: Include field if true
- `@skip(if: Boolean)`: Skip field if true
- `@deprecated(reason: String)`: Mark fields as deprecated

```graphql
query GetUser($includeEmail: Boolean!) {
    user(id: "123") {
        name
        email @include(if: $includeEmail)
        phone @skip(if: $includeEmail)
    }
}
```

## Python Libraries

### Popular GraphQL Libraries

Python offers several excellent libraries for working with GraphQL, each with different strengths and use cases.

#### GQL (Client Library)

**Best for**: GraphQL client applications, consuming APIs

- Modern, async-first design with sync support
- Automatic schema validation
- Type-safe queries with schema introspection
- Multiple transport options (HTTP, WebSocket, AIOHTTP)
- Excellent documentation and active development

**Installation:**

```bash
pip install gql[all]
```

**Basic Usage:**

```python
from gql import gql, Client
from gql.transport.aiohttp import AIOHTTPTransport

# Async client
transport = AIOHTTPTransport(url="https://api.example.com/graphql")
client = Client(transport=transport, fetch_schema_from_transport=True)

query = gql("""
    query {
        users {
            id
            name
        }
    }
""")

result = await client.execute_async(query)
```

#### Strawberry (Server Framework)

**Best for**: Building modern GraphQL APIs with Python type hints

- Pure Python type hints for schema definition
- Django, Flask, and FastAPI integrations
- DataLoader support for batching
- Subscriptions via WebSocket
- Federation support
- Code-first approach

**Installation:**

```bash
pip install strawberry-graphql[fastapi]
```

**Basic Usage:**

```python
import strawberry
from fastapi import FastAPI
from strawberry.fastapi import GraphQLRouter

@strawberry.type
class User:
    id: int
    name: str
    email: str

@strawberry.type
class Query:
    @strawberry.field
    def user(self, id: int) -> User:
        return User(id=id, name="John Doe", email="john@example.com")

schema = strawberry.Schema(query=Query)
graphql_app = GraphQLRouter(schema)

app = FastAPI()
app.include_router(graphql_app, prefix="/graphql")
```

#### Graphene (Server Framework)

**Best for**: Django/SQLAlchemy integrations, mature projects

- Mature and battle-tested
- Excellent Django and SQLAlchemy integrations
- Relay support built-in
- Large community and ecosystem
- Class-based schema definition

**Installation:**

```bash
pip install graphene graphene-django
```

**Basic Usage:**

```python
import graphene

class User(graphene.ObjectType):
    id = graphene.ID()
    name = graphene.String()
    email = graphene.String()

class Query(graphene.ObjectType):
    user = graphene.Field(User, id=graphene.ID(required=True))
    
    def resolve_user(self, info, id):
        return User(id=id, name="John Doe", email="john@example.com")

schema = graphene.Schema(query=Query)
```

#### Ariadne (Server Framework)

**Best for**: Schema-first development, existing schemas

- Schema-first approach (write SDL first)
- Works with any web framework
- Simple and Pythonic API
- ASGI and WSGI support
- GraphQL subscriptions

**Installation:**

```bash
pip install ariadne
```

**Basic Usage:**

```python
from ariadne import QueryType, make_executable_schema
from ariadne.asgi import GraphQL

type_defs = """
    type Query {
        user(id: ID!): User
    }
    
    type User {
        id: ID!
        name: String!
        email: String!
    }
"""

query = QueryType()

@query.field("user")
def resolve_user(obj, info, id):
    return {"id": id, "name": "John Doe", "email": "john@example.com"}

schema = make_executable_schema(type_defs, query)
app = GraphQL(schema)
```

#### HTTPX + GraphQL

**Best for**: Simple queries without heavy dependencies

```python
import httpx
import json

def graphql_query(url, query, variables=None, headers=None):
    """Simple GraphQL query function"""
    payload = {"query": query}
    if variables:
        payload["variables"] = variables
    
    response = httpx.post(url, json=payload, headers=headers)
    response.raise_for_status()
    
    data = response.json()
    if "errors" in data:
        raise Exception(f"GraphQL errors: {data['errors']}")
    
    return data["data"]

# Usage
result = graphql_query(
    "https://api.example.com/graphql",
    """
    query GetUser($id: ID!) {
        user(id: $id) {
            name
            email
        }
    }
    """,
    variables={"id": "123"},
    headers={"Authorization": "Bearer token"}
)
```

### Library Comparison

| Feature | GQL | Strawberry | Graphene | Ariadne |
| --- | --- | --- | --- | --- |
| **Type** | Client | Server | Server | Server |
| **Approach** | Query builder | Code-first | Code-first | Schema-first |
| **Async Support** | Excellent | Excellent | Limited | Good |
| **Django Integration** | N/A | Good | Excellent | Good |
| **FastAPI Integration** | N/A | Excellent | Limited | Good |
| **Type Hints** | Yes | Excellent | Limited | Good |
| **Learning Curve** | Low | Medium | Medium | Low |
| **Performance** | Excellent | Excellent | Good | Good |
| **Subscriptions** | Yes | Yes | Yes | Yes |
| **Federation** | No | Yes | Yes | Yes |
| **Community** | Growing | Growing | Large | Medium |
| **Documentation** | Excellent | Excellent | Good | Excellent |

## Query Examples

### Basic Query

#### Simple Field Selection

```python
from gql import gql, Client
from gql.transport.requests import RequestsHTTPTransport

transport = RequestsHTTPTransport(url="https://api.example.com/graphql")
client = Client(transport=transport)

# Query for basic user information
query = gql("""
    query {
        user(id: "123") {
            id
            name
            email
        }
    }
""")

result = client.execute(query)
print(result["user"]["name"])
```

#### Nested Queries

Fetch related data in a single request:

```python
query = gql("""
    query {
        user(id: "123") {
            id
            name
            posts {
                id
                title
                comments {
                    id
                    content
                    author {
                        name
                    }
                }
            }
        }
    }
""")

result = client.execute(query)

# Access nested data
for post in result["user"]["posts"]:
    print(f"Post: {post['title']}")
    for comment in post["comments"]:
        print(f"  Comment by {comment['author']['name']}: {comment['content']}")
```

#### Multiple Queries in One Request

Use aliases to fetch different data:

```python
query = gql("""
    query {
        currentUser: user(id: "123") {
            name
            email
        }
        featuredPost: post(id: "456") {
            title
            author {
                name
            }
        }
        recentUsers: users(limit: 5, orderBy: "createdAt") {
            id
            name
        }
    }
""")

result = client.execute(query)
print(result["currentUser"])
print(result["featuredPost"])
print(result["recentUsers"])
```

### Query with Variables

Variables make queries reusable and secure:

#### Basic Variables

```python
query = gql("""
    query GetUser($userId: ID!, $includeEmail: Boolean!) {
        user(id: $userId) {
            id
            name
            email @include(if: $includeEmail)
        }
    }
""")

# Execute with different variables
result1 = client.execute(
    query,
    variable_values={"userId": "123", "includeEmail": True}
)

result2 = client.execute(
    query,
    variable_values={"userId": "456", "includeEmail": False}
)
```

#### Complex Variables

```python
query = gql("""
    query SearchUsers(
        $searchTerm: String!
        $limit: Int = 10
        $offset: Int = 0
        $filters: UserFilters
    ) {
        users(
            search: $searchTerm
            limit: $limit
            offset: $offset
            filters: $filters
        ) {
            id
            name
            email
            createdAt
        }
    }
""")

variables = {
    "searchTerm": "john",
    "limit": 20,
    "offset": 0,
    "filters": {
        "isActive": True,
        "role": "admin",
        "createdAfter": "2024-01-01"
    }
}

result = client.execute(query, variable_values=variables)
```

#### Input Types

```python
query = gql("""
    mutation CreateUser($input: CreateUserInput!) {
        createUser(input: $input) {
            id
            name
            email
            profile {
                bio
                website
            }
        }
    }
""")

variables = {
    "input": {
        "name": "Jane Smith",
        "email": "jane@example.com",
        "password": "securepass123",
        "profile": {
            "bio": "Software developer",
            "website": "https://jane.dev",
            "socialLinks": {
                "github": "janesmith",
                "twitter": "janesmith"
            }
        }
    }
}

result = client.execute(query, variable_values=variables)
```

### Mutation Examples

Mutations modify data on the server:

#### Create Operation

```python
mutation = gql("""
    mutation CreatePost($title: String!, $content: String!, $authorId: ID!) {
        createPost(title: $title, content: $content, authorId: $authorId) {
            id
            title
            content
            createdAt
            author {
                id
                name
            }
        }
    }
""")

result = client.execute(
    mutation,
    variable_values={
        "title": "Getting Started with GraphQL",
        "content": "GraphQL is a powerful query language...",
        "authorId": "123"
    }
)

post_id = result["createPost"]["id"]
print(f"Created post with ID: {post_id}")
```

#### Update Operation

```python
mutation = gql("""
    mutation UpdateUser($id: ID!, $input: UpdateUserInput!) {
        updateUser(id: $id, input: $input) {
            id
            name
            email
            updatedAt
        }
    }
""")

result = client.execute(
    mutation,
    variable_values={
        "id": "123",
        "input": {
            "name": "John Updated",
            "email": "john.new@example.com"
        }
    }
)
```

#### Delete Operation

```python
mutation = gql("""
    mutation DeletePost($id: ID!) {
        deletePost(id: $id) {
            success
            message
        }
    }
""")

result = client.execute(
    mutation,
    variable_values={"id": "456"}
)

if result["deletePost"]["success"]:
    print("Post deleted successfully")
```

#### Batch Mutations

```python
mutation = gql("""
    mutation BatchCreatePosts($posts: [CreatePostInput!]!) {
        createPosts(posts: $posts) {
            id
            title
            createdAt
        }
    }
""")

result = client.execute(
    mutation,
    variable_values={
        "posts": [
            {"title": "Post 1", "content": "Content 1", "authorId": "123"},
            {"title": "Post 2", "content": "Content 2", "authorId": "123"},
            {"title": "Post 3", "content": "Content 3", "authorId": "123"}
        ]
    }
)

print(f"Created {len(result['createPosts'])} posts")
```

### Using Fragments

Reusable query fragments improve maintainability:

#### Basic Fragments

```python
query = gql("""
    fragment UserFields on User {
        id
        name
        email
        createdAt
    }
    
    fragment PostFields on Post {
        id
        title
        content
        publishedAt
    }
    
    query GetUserWithPosts($userId: ID!) {
        user(id: $userId) {
            ...UserFields
            posts {
                ...PostFields
                author {
                    ...UserFields
                }
            }
        }
    }
""")

result = client.execute(query, variable_values={"userId": "123"})
```

#### Nested Fragments

```python
query = gql("""
    fragment AuthorInfo on User {
        id
        name
        email
    }
    
    fragment PostSummary on Post {
        id
        title
        excerpt
    }
    
    fragment PostDetails on Post {
        ...PostSummary
        content
        publishedAt
        author {
            ...AuthorInfo
        }
    }
    
    query GetPost($postId: ID!) {
        post(id: $postId) {
            ...PostDetails
            comments {
                id
                content
                author {
                    ...AuthorInfo
                }
            }
        }
    }
""")
```

#### Inline Fragments (Type Conditions)

```python
query = gql("""
    query GetSearchResults($query: String!) {
        search(query: $query) {
            ... on User {
                id
                name
                email
            }
            ... on Post {
                id
                title
                content
            }
            ... on Comment {
                id
                content
                author {
                    name
                }
            }
        }
    }
""")

result = client.execute(query, variable_values={"query": "python"})

for item in result["search"]:
    if "email" in item:  # User
        print(f"User: {item['name']}")
    elif "title" in item:  # Post
        print(f"Post: {item['title']}")
    else:  # Comment
        print(f"Comment: {item['content']}")
```

### Subscription Examples

Real-time updates using WebSocket:

#### Basic Subscription

```python
from gql import gql, Client
from gql.transport.websockets import WebsocketsTransport

transport = WebsocketsTransport(url="wss://api.example.com/graphql")
client = Client(transport=transport)

subscription = gql("""
    subscription OnNewMessage($channelId: ID!) {
        messageAdded(channelId: $channelId) {
            id
            content
            author {
                name
            }
            createdAt
        }
    }
""")

async for result in client.subscribe_async(
    subscription,
    variable_values={"channelId": "general"}
):
    message = result["messageAdded"]
    print(f"{message['author']['name']}: {message['content']}")
```

#### Multiple Subscriptions

```python
import asyncio

async def handle_messages():
    subscription = gql("""
        subscription {
            messageAdded {
                id
                content
            }
        }
    """)
    
    async for result in client.subscribe_async(subscription):
        print(f"New message: {result['messageAdded']['content']}")

async def handle_notifications():
    subscription = gql("""
        subscription {
            notificationReceived {
                id
                type
                message
            }
        }
    """)
    
    async for result in client.subscribe_async(subscription):
        print(f"Notification: {result['notificationReceived']['message']}")

# Run both subscriptions concurrently
await asyncio.gather(
    handle_messages(),
    handle_notifications()
)
```

### Handling Query Errors

#### Basic Error Handling

```python
from gql.transport.exceptions import TransportQueryError

try:
    result = client.execute(query, variable_values=variables)
except TransportQueryError as e:
    print(f"GraphQL errors: {e.errors}")
    for error in e.errors:
        print(f"  Message: {error['message']}")
        print(f"  Path: {error.get('path', 'N/A')}")
        print(f"  Locations: {error.get('locations', 'N/A')}")
except Exception as e:
    print(f"Network or other error: {e}")
```

#### Partial Error Handling

GraphQL can return partial data with errors:

```python
query = gql("""
    query {
        user(id: "123") {
            name
            email
        }
        post(id: "invalid") {
            title
        }
    }
""")

try:
    result = client.execute(query)
    # May have partial data even with errors
    if "user" in result:
        print(f"User data: {result['user']}")
except TransportQueryError as e:
    # Check if partial data exists
    if e.data:
        print(f"Partial data: {e.data}")
    print(f"Errors: {e.errors}")
```

### Pagination

#### Offset-based Pagination

```python
def fetch_all_users(client, page_size=50):
    """Fetch all users with offset pagination"""
    all_users = []
    offset = 0
    
    query = gql("""
        query GetUsers($limit: Int!, $offset: Int!) {
            users(limit: $limit, offset: $offset) {
                id
                name
                email
            }
        }
    """)
    
    while True:
        result = client.execute(
            query,
            variable_values={"limit": page_size, "offset": offset}
        )
        
        users = result["users"]
        if not users:
            break
        
        all_users.extend(users)
        offset += page_size
    
    return all_users
```

#### Cursor-based Pagination (Relay Style)

```python
def fetch_all_posts_cursor(client, first=20):
    """Fetch all posts using cursor pagination"""
    all_posts = []
    after = None
    
    query = gql("""
        query GetPosts($first: Int!, $after: String) {
            posts(first: $first, after: $after) {
                edges {
                    node {
                        id
                        title
                        content
                    }
                    cursor
                }
                pageInfo {
                    hasNextPage
                    endCursor
                }
            }
        }
    """)
    
    while True:
        result = client.execute(
            query,
            variable_values={"first": first, "after": after}
        )
        
        connection = result["posts"]
        all_posts.extend([edge["node"] for edge in connection["edges"]])
        
        if not connection["pageInfo"]["hasNextPage"]:
            break
        
        after = connection["pageInfo"]["endCursor"]
    
    return all_posts
```

### Advanced Query Patterns

#### Conditional Fields

```python
query = gql("""
    query GetUser($id: ID!, $includeProfile: Boolean!, $includePosts: Boolean!) {
        user(id: $id) {
            id
            name
            profile @include(if: $includeProfile) {
                bio
                website
            }
            posts @include(if: $includePosts) {
                id
                title
            }
        }
    }
""")

# Fetch with profile but without posts
result = client.execute(
    query,
    variable_values={
        "id": "123",
        "includeProfile": True,
        "includePosts": False
    }
)
```

#### Field Aliasing for Comparison

```python
query = gql("""
    query CompareUsers {
        admin: user(id: "1") {
            id
            name
            role
            postCount
        }
        moderator: user(id: "2") {
            id
            name
            role
            postCount
        }
    }
""")

result = client.execute(query)
print(f"Admin posts: {result['admin']['postCount']}")
print(f"Moderator posts: {result['moderator']['postCount']}")
```

## Best Practices

### Schema Design

#### Use Descriptive Names

```graphql
# ✅ Good
type User {
    id: ID!
    emailAddress: String!
    fullName: String!
    dateOfBirth: Date
}

# ❌ Avoid
type User {
    id: ID!
    email: String!
    name: String!
    dob: Date
}
```

#### Design for Client Needs

Structure your schema based on how clients will consume the data:

```graphql
# ✅ Good - Client-focused
type ProductPage {
    product: Product!
    relatedProducts: [Product!]!
    reviews: ReviewConnection!
    recommendations: [Product!]!
}

# ❌ Avoid - Database-focused
type Product {
    id: ID!
    name: String!
    categoryId: ID!
}

type Category {
    id: ID!
    products: [ID!]!
}
```

#### Use Enums for Fixed Sets

```graphql
enum UserRole {
    ADMIN
    MODERATOR
    USER
    GUEST
}

enum OrderStatus {
    PENDING
    PROCESSING
    SHIPPED
    DELIVERED
    CANCELLED
}

type User {
    role: UserRole!
    orders: [Order!]!
}

type Order {
    status: OrderStatus!
}
```

#### Nullable vs Non-Nullable

Be thoughtful about field nullability:

```graphql
type User {
    # Required fields - never null
    id: ID!
    email: String!
    createdAt: DateTime!
    
    # Optional fields - may be null
    phoneNumber: String
    bio: String
    website: String
    
    # Lists that may be empty but never null
    posts: [Post!]!
    
    # Lists that may be null or contain nulls (avoid this)
    favoriteColors: [String]
}
```

### Query Optimization

#### Request Only Needed Fields

```python
# ✅ Good - Request only what you need
query = gql("""
    query {
        users {
            id
            name
        }
    }
""")

# ❌ Avoid - Requesting unnecessary data
query = gql("""
    query {
        users {
            id
            name
            email
            profile {
                bio
                website
                socialLinks
            }
            posts {
                id
                title
                content
                comments {
                    id
                    content
                }
            }
        }
    }
""")
```

#### Use DataLoaders to Prevent N+1 Queries

When building servers, implement DataLoaders:

```python
from strawberry.dataloader import DataLoader

async def load_users(keys: list[int]) -> list[User]:
    """Batch load users by IDs"""
    # Single database query for all IDs
    users = await db.users.find({"id": {"$in": keys}})
    # Return in same order as keys
    user_map = {user.id: user for user in users}
    return [user_map.get(key) for key in keys]

user_loader = DataLoader(load_fn=load_users)

@strawberry.type
class Query:
    @strawberry.field
    async def posts(self) -> list[Post]:
        posts = await db.posts.find_all()
        # Load all authors in single query
        for post in posts:
            post.author = await user_loader.load(post.author_id)
        return posts
```

#### Implement Pagination

Always paginate list fields:

```python
query = gql("""
    query GetPosts($first: Int!, $after: String) {
        posts(first: $first, after: $after) {
            edges {
                node {
                    id
                    title
                }
                cursor
            }
            pageInfo {
                hasNextPage
                endCursor
            }
            totalCount
        }
    }
""")
```

#### Use Fragments for Reusability

```python
# Define common fragments
USER_FRAGMENT = """
    fragment UserInfo on User {
        id
        name
        email
        avatar
    }
"""

POST_FRAGMENT = """
    fragment PostInfo on Post {
        id
        title
        excerpt
        publishedAt
    }
"""

# Reuse in queries
query = gql(f"""
    {USER_FRAGMENT}
    {POST_FRAGMENT}
    
    query GetFeed($userId: ID!) {{
        user(id: $userId) {{
            ...UserInfo
            feed {{
                ...PostInfo
                author {{
                    ...UserInfo
                }}
            }}
        }}
    }}
""")
```

### Error Handling

#### Always Handle GraphQL Errors

```python
from gql.transport.exceptions import TransportQueryError
import logging

logger = logging.getLogger(__name__)

def execute_query_safely(client, query, variables=None):
    """Execute query with comprehensive error handling"""
    try:
        result = client.execute(query, variable_values=variables)
        return result, None
    
    except TransportQueryError as e:
        # GraphQL-specific errors
        logger.error(f"GraphQL errors: {e.errors}")
        
        error_messages = []
        for error in e.errors:
            message = error.get("message", "Unknown error")
            path = error.get("path", [])
            error_messages.append(f"{message} at {'.'.join(map(str, path))}")
        
        return e.data, error_messages  # May have partial data
    
    except Exception as e:
        # Network or other errors
        logger.exception("Failed to execute query")
        return None, [str(e)]

# Usage
result, errors = execute_query_safely(client, query, variables)
if errors:
    print(f"Errors occurred: {errors}")
if result:
    print(f"Partial or full data: {result}")
```

#### Implement Retry Logic

```python
import time
from typing import Optional

def execute_with_retry(
    client,
    query,
    variables=None,
    max_retries=3,
    backoff_factor=2
) -> Optional[dict]:
    """Execute query with exponential backoff retry"""
    for attempt in range(max_retries):
        try:
            return client.execute(query, variable_values=variables)
        
        except TransportQueryError as e:
            # Don't retry client errors (4xx)
            if any("authentication" in str(err).lower() for err in e.errors):
                raise
            
            if attempt == max_retries - 1:
                raise
            
            wait_time = backoff_factor ** attempt
            logger.warning(f"Retry {attempt + 1}/{max_retries} after {wait_time}s")
            time.sleep(wait_time)
        
        except Exception as e:
            if attempt == max_retries - 1:
                raise
            
            wait_time = backoff_factor ** attempt
            time.sleep(wait_time)
    
    return None
```

### Security

#### Validate and Sanitize Inputs

```python
from typing import Optional
import re

def validate_email(email: str) -> bool:
    """Validate email format"""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None

def sanitize_input(text: str, max_length: int = 1000) -> str:
    """Sanitize user input"""
    # Remove null bytes
    text = text.replace('\x00', '')
    # Limit length
    text = text[:max_length]
    # Strip leading/trailing whitespace
    text = text.strip()
    return text

# Use before sending to GraphQL
mutation = gql("""
    mutation CreateUser($email: String!, $bio: String!) {
        createUser(email: $email, bio: $bio) {
            id
        }
    }
""")

email = "user@example.com"
bio = user_input_bio

if not validate_email(email):
    raise ValueError("Invalid email address")

bio = sanitize_input(bio, max_length=500)

result = client.execute(
    mutation,
    variable_values={"email": email, "bio": bio}
)
```

#### Use Authentication Headers

```python
from gql.transport.requests import RequestsHTTPTransport
from gql import Client

def create_authenticated_client(api_url: str, token: str) -> Client:
    """Create GraphQL client with authentication"""
    transport = RequestsHTTPTransport(
        url=api_url,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        },
        verify=True,  # Verify SSL certificates
        retries=3,
        timeout=30
    )
    
    return Client(
        transport=transport,
        fetch_schema_from_transport=True
    )

# Usage
client = create_authenticated_client(
    "https://api.example.com/graphql",
    "your-auth-token"
)
```

#### Implement Rate Limiting on Client Side

```python
import time
from collections import deque
from datetime import datetime, timedelta

class RateLimitedClient:
    """GraphQL client with rate limiting"""
    
    def __init__(self, client, max_requests=100, time_window=60):
        self.client = client
        self.max_requests = max_requests
        self.time_window = time_window  # seconds
        self.requests = deque()
    
    def execute(self, query, variable_values=None):
        """Execute query with rate limiting"""
        now = datetime.now()
        
        # Remove old requests outside time window
        while self.requests and self.requests[0] < now - timedelta(seconds=self.time_window):
            self.requests.popleft()
        
        # Check if rate limit exceeded
        if len(self.requests) >= self.max_requests:
            sleep_time = (self.requests[0] + timedelta(seconds=self.time_window) - now).total_seconds()
            if sleep_time > 0:
                logger.warning(f"Rate limit reached, sleeping for {sleep_time:.2f}s")
                time.sleep(sleep_time)
                return self.execute(query, variable_values)
        
        # Record request and execute
        self.requests.append(now)
        return self.client.execute(query, variable_values=variable_values)

# Usage
rate_limited_client = RateLimitedClient(client, max_requests=100, time_window=60)
```

### Performance

#### Use Connection Pooling

```python
from gql.transport.aiohttp import AIOHTTPTransport
import aiohttp

async def create_pooled_client(api_url: str):
    """Create client with connection pooling"""
    connector = aiohttp.TCPConnector(
        limit=100,  # Max total connections
        limit_per_host=30,  # Max per host
        ttl_dns_cache=300  # DNS cache TTL
    )
    
    transport = AIOHTTPTransport(
        url=api_url,
        client_session_args={
            "connector": connector,
            "timeout": aiohttp.ClientTimeout(total=30)
        }
    )
    
    return Client(transport=transport)
```

#### Cache Query Results

```python
from functools import lru_cache
from typing import Optional
import hashlib
import json

class CachedGraphQLClient:
    """GraphQL client with query result caching"""
    
    def __init__(self, client, cache_ttl=300):
        self.client = client
        self.cache = {}
        self.cache_ttl = cache_ttl
    
    def _cache_key(self, query: str, variables: Optional[dict]) -> str:
        """Generate cache key from query and variables"""
        content = f"{query}:{json.dumps(variables, sort_keys=True)}"
        return hashlib.md5(content.encode()).hexdigest()
    
    def execute(self, query, variable_values=None, use_cache=True):
        """Execute query with caching"""
        if not use_cache:
            return self.client.execute(query, variable_values=variable_values)
        
        cache_key = self._cache_key(str(query), variable_values)
        now = time.time()
        
        # Check cache
        if cache_key in self.cache:
            cached_result, cached_time = self.cache[cache_key]
            if now - cached_time < self.cache_ttl:
                return cached_result
        
        # Execute and cache
        result = self.client.execute(query, variable_values=variable_values)
        self.cache[cache_key] = (result, now)
        
        return result
    
    def clear_cache(self):
        """Clear all cached results"""
        self.cache.clear()
```

#### Batch Queries When Possible

```python
async def fetch_multiple_entities(client, entity_ids: list[str]):
    """Fetch multiple entities in a single query using aliases"""
    
    # Build query with aliases for each ID
    query_parts = []
    for i, entity_id in enumerate(entity_ids):
        query_parts.append(f"""
            entity{i}: entity(id: "{entity_id}") {{
                id
                name
                description
            }}
        """)
    
    query_str = "query {\n" + "\n".join(query_parts) + "\n}"
    query = gql(query_str)
    
    result = await client.execute_async(query)
    
    # Extract entities from aliased results
    entities = []
    for i in range(len(entity_ids)):
        entity = result.get(f"entity{i}")
        if entity:
            entities.append(entity)
    
    return entities
```

### Testing

#### Mock GraphQL Responses

```python
from unittest.mock import Mock, patch
import pytest

@pytest.fixture
def mock_graphql_client():
    """Create mock GraphQL client for testing"""
    client = Mock()
    client.execute.return_value = {
        "user": {
            "id": "123",
            "name": "Test User",
            "email": "test@example.com"
        }
    }
    return client

def test_get_user(mock_graphql_client):
    """Test user retrieval"""
    query = gql("""
        query {
            user(id: "123") {
                id
                name
                email
            }
        }
    """)
    
    result = mock_graphql_client.execute(query)
    
    assert result["user"]["id"] == "123"
    assert result["user"]["name"] == "Test User"
    mock_graphql_client.execute.assert_called_once()
```

#### Integration Testing

```python
import pytest
from gql import Client
from gql.transport.requests import RequestsHTTPTransport

@pytest.fixture(scope="session")
def graphql_client():
    """Create real GraphQL client for integration tests"""
    transport = RequestsHTTPTransport(
        url="http://localhost:4000/graphql",
        verify=False  # For testing only
    )
    return Client(transport=transport)

def test_create_and_fetch_user(graphql_client):
    """Integration test for user creation and retrieval"""
    
    # Create user
    create_mutation = gql("""
        mutation CreateUser($name: String!, $email: String!) {
            createUser(name: $name, email: $email) {
                id
                name
                email
            }
        }
    """)
    
    create_result = graphql_client.execute(
        create_mutation,
        variable_values={
            "name": "Integration Test User",
            "email": "integration@test.com"
        }
    )
    
    user_id = create_result["createUser"]["id"]
    assert user_id is not None
    
    # Fetch user
    fetch_query = gql("""
        query GetUser($id: ID!) {
            user(id: $id) {
                id
                name
                email
            }
        }
    """)
    
    fetch_result = graphql_client.execute(
        fetch_query,
        variable_values={"id": user_id}
    )
    
    assert fetch_result["user"]["name"] == "Integration Test User"
    assert fetch_result["user"]["email"] == "integration@test.com"
```

### Documentation

#### Document Your Queries

```python
# queries.py

"""
GraphQL queries and mutations for the application.

This module contains all GraphQL operations organized by domain.
Each query/mutation includes documentation about its purpose and usage.
"""

# User Queries
GET_USER = gql("""
    query GetUser($id: ID!) {
        """
        Fetch a single user by ID.
        
        Args:
            id: The unique identifier of the user
            
        Returns:
            User object with id, name, and email
        """
        user(id: $id) {
            id
            name
            email
        }
    }
""")

# User Mutations
CREATE_USER = gql("""
    mutation CreateUser($input: CreateUserInput!) {
        """
        Create a new user.
        
        Args:
            input: User creation data including name, email, and password
            
        Returns:
            Newly created user object
        """
        createUser(input: $input) {
            id
            name
            email
            createdAt
        }
    }
""")
```

#### Use Type Hints

```python
from typing import Optional, List, Dict, Any
from dataclasses import dataclass

@dataclass
class User:
    """User domain model"""
    id: str
    name: str
    email: str
    created_at: Optional[str] = None

class UserRepository:
    """Repository for user-related GraphQL operations"""
    
    def __init__(self, client: Client):
        self.client = client
    
    def get_user(self, user_id: str) -> Optional[User]:
        """
        Fetch a user by ID.
        
        Args:
            user_id: The user's unique identifier
            
        Returns:
            User object if found, None otherwise
            
        Raises:
            TransportQueryError: If the GraphQL query fails
        """
        query = gql("""
            query GetUser($id: ID!) {
                user(id: $id) {
                    id
                    name
                    email
                    createdAt
                }
            }
        """)
        
        result = self.client.execute(
            query,
            variable_values={"id": user_id}
        )
        
        if not result.get("user"):
            return None
        
        user_data = result["user"]
        return User(
            id=user_data["id"],
            name=user_data["name"],
            email=user_data["email"],
            created_at=user_data.get("createdAt")
        )
    
    def list_users(self, limit: int = 50, offset: int = 0) -> List[User]:
        """
        List users with pagination.
        
        Args:
            limit: Maximum number of users to return
            offset: Number of users to skip
            
        Returns:
            List of User objects
        """
        query = gql("""
            query ListUsers($limit: Int!, $offset: Int!) {
                users(limit: $limit, offset: $offset) {
                    id
                    name
                    email
                }
            }
        """)
        
        result = self.client.execute(
            query,
            variable_values={"limit": limit, "offset": offset}
        )
        
        return [
            User(id=u["id"], name=u["name"], email=u["email"])
            for u in result["users"]
        ]
```

## Resources

### Official Documentation

#### GraphQL Specification

- [GraphQL Official Website](https://graphql.org/)
- [GraphQL Specification](https://spec.graphql.org/)
- [GraphQL Foundation](https://graphql.org/foundation/)
- [GraphQL Best Practices](https://graphql.org/learn/best-practices/)

#### Python Library Documentation

- [GQL Documentation](https://gql.readthedocs.io/)
- [Strawberry Documentation](https://strawberry.rocks/)
- [Graphene Documentation](https://docs.graphene-python.org/)
- [Ariadne Documentation](https://ariadnegraphql.org/)

### Learning Resources

#### Tutorials

- [How to GraphQL - Python Track](https://www.howtographql.com/graphql-python/0-introduction/)
- [GraphQL Python Tutorial](https://graphql.org/code/#python)
- [Real Python - GraphQL Guide](https://realpython.com/python-graphql/)
- [Full Stack Python - GraphQL](https://www.fullstackpython.com/graphql.html)

#### Video Courses

- [GraphQL with Python Crash Course](https://www.youtube.com/results?search_query=graphql+python+tutorial)
- [Building GraphQL APIs with Python](https://www.youtube.com/results?search_query=building+graphql+api+python)

#### Books

- *Learning GraphQL* by Eve Porcello and Alex Banks
- *The Road to GraphQL* by Robin Wieruch
- *Production Ready GraphQL* by Marc-André Giroux

### Tools and Utilities

#### Development Tools

- [GraphiQL](https://github.com/graphql/graphiql) - In-browser GraphQL IDE
- [GraphQL Playground](https://github.com/graphql/graphql-playground) - GraphQL IDE
- [Insomnia](https://insomnia.rest/) - API client with GraphQL support
- [Postman](https://www.postman.com/) - API platform with GraphQL support

#### Schema Tools

- [GraphQL Voyager](https://graphql-kit.com/graphql-voyager/) - Schema visualization
- [GraphQL Inspector](https://graphql-inspector.com/) - Schema comparison and validation
- [GraphQL Code Generator](https://www.graphql-code-generator.com/) - Code generation from schemas

#### Testing Tools

- [GraphQL Faker](https://github.com/APIs-guru/graphql-faker) - Mock GraphQL API
- [EasyGraphQL Tester](https://easygraphql.com/easygraphql-tester) - GraphQL testing tool

### Public GraphQL APIs

Practice with these free public APIs:

#### GitHub GraphQL API

```python
from gql import gql, Client
from gql.transport.requests import RequestsHTTPTransport

transport = RequestsHTTPTransport(
    url="https://api.github.com/graphql",
    headers={"Authorization": f"Bearer YOUR_GITHUB_TOKEN"}
)

client = Client(transport=transport)

query = gql("""
    query {
        viewer {
            login
            name
            repositories(first: 5) {
                nodes {
                    name
                    description
                }
            }
        }
    }
""")

result = client.execute(query)
```

#### SpaceX GraphQL API

```python
transport = RequestsHTTPTransport(url="https://spacex-production.up.railway.app/")
client = Client(transport=transport)

query = gql("""
    query {
        launchesPast(limit: 5) {
            mission_name
            launch_date_utc
            rocket {
                rocket_name
            }
        }
    }
""")

result = client.execute(query)
```

#### Countries GraphQL API

```python
transport = RequestsHTTPTransport(url="https://countries.trevorblades.com/")
client = Client(transport=transport)

query = gql("""
    query {
        countries(filter: { continent: { eq: "NA" } }) {
            name
            capital
            currency
        }
    }
""")

result = client.execute(query)
```

#### Rick and Morty API

```python
transport = RequestsHTTPTransport(url="https://rickandmortyapi.com/graphql")
client = Client(transport=transport)

query = gql("""
    query {
        characters(page: 1, filter: { name: "rick" }) {
            results {
                name
                status
                species
            }
        }
    }
""")

result = client.execute(query)
```

### Community Resources

#### Forums and Discussion

- [GraphQL Discord](https://discord.graphql.org/)
- [GraphQL Reddit](https://www.reddit.com/r/graphql/)
- [Stack Overflow - GraphQL Tag](https://stackoverflow.com/questions/tagged/graphql)
- [Stack Overflow - Python GraphQL](https://stackoverflow.com/questions/tagged/graphql+python)

#### Blogs and Articles

- [GraphQL Official Blog](https://graphql.org/blog/)
- [Apollo GraphQL Blog](https://www.apollographql.com/blog/)
- [The Guild Blog](https://the-guild.dev/blog)
- [Hasura Blog](https://hasura.io/blog/)

#### GitHub Repositories

- [Awesome GraphQL](https://github.com/chentsulin/awesome-graphql) - Curated list of GraphQL resources
- [GraphQL Python Examples](https://github.com/graphql-python) - Example implementations
- [GraphQL Patterns](https://github.com/topics/graphql-patterns) - Design patterns

### Standards and Specifications

- [GraphQL Spec](https://spec.graphql.org/) - Official specification
- [GraphQL over HTTP](https://graphql.github.io/graphql-over-http/) - HTTP transport spec
- [Relay Cursor Connections](https://relay.dev/graphql/connections.htm) - Pagination spec
- [GraphQL Multipart Request](https://github.com/jaydenseric/graphql-multipart-request-spec) - File upload spec

### Related Topics

- [REST API in Python](rest-api.md)
- [Async Programming with asyncio](../libraries/asyncio.md)
- [Web Development](../web-development/index.md)

### Code Examples Repository

Complete working examples are available in the following repositories:

- [GQL Examples](https://github.com/graphql-python/gql/tree/master/examples)
- [Strawberry Examples](https://github.com/strawberry-graphql/strawberry/tree/main/examples)
- [Graphene Examples](https://github.com/graphql-python/graphene/tree/master/examples)
- [Ariadne Examples](https://github.com/mirumee/ariadne/tree/main/examples)

### Performance Benchmarks

- [GraphQL vs REST Performance](https://blog.apollographql.com/graphql-vs-rest-5d425123e34b)
- [Python GraphQL Library Benchmarks](https://github.com/strawberry-graphql/strawberry/discussions/1974)

### Security Resources

- [GraphQL Security Best Practices](https://graphql.org/learn/security/)
- [OWASP GraphQL Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/GraphQL_Cheat_Sheet.html)
- [GraphQL Rate Limiting](https://www.apollographql.com/docs/apollo-server/performance/rate-limiting/)
- [GraphQL Depth Limiting](https://www.howtographql.com/advanced/4-security/)

### Real-World Case Studies

- [GitHub - Why GraphQL](https://github.blog/2016-09-14-the-github-graphql-api/)
- [Shopify - GraphQL at Scale](https://shopify.engineering/shopify-graphql-evolution)
- [Netflix - GraphQL Adoption](https://netflixtechblog.com/our-learnings-from-adopting-graphql-f099de39ae5f)
- [Airbnb - GraphQL Migration](https://medium.com/airbnb-engineering/how-airbnb-is-moving-10x-faster-at-scale-with-graphql-and-apollo-aa4ec92d69e2)

### Conferences and Events

- [GraphQL Conf](https://graphql.org/conf/) - Annual GraphQL conference
- [GraphQL Summit](https://summit.graphql.com/) - Apollo's GraphQL conference
- [Local GraphQL Meetups](https://www.meetup.com/topics/graphql/)

### Podcasts

- [GraphQL Radio](https://graphqlradio.com/)
- [The Changelog - GraphQL Episodes](https://changelog.com/topic/graphql)
- [Software Engineering Daily - GraphQL](https://softwareengineeringdaily.com/?s=graphql)

### IDE Extensions

#### VS Code

- [GraphQL for VS Code](https://marketplace.visualstudio.com/items?itemName=GraphQL.vscode-graphql)
- [Apollo GraphQL](https://marketplace.visualstudio.com/items?itemName=apollographql.vscode-apollo)
- [GraphQL Syntax Highlighting](https://marketplace.visualstudio.com/items?itemName=GraphQL.vscode-graphql-syntax)

#### PyCharm

- [JS GraphQL](https://plugins.jetbrains.com/plugin/8097-js-graphql)
- [GraphQL](https://plugins.jetbrains.com/plugin/8097-graphql)

### Monitoring and Analytics

- [Apollo Studio](https://www.apollographql.com/docs/studio/) - GraphQL monitoring
- [GraphQL Metrics](https://github.com/Workable/graphql-metrics) - Metrics collection
- [Hasura Cloud](https://hasura.io/cloud/) - Managed GraphQL with monitoring

### Newsletter

- [GraphQL Weekly](https://www.graphqlweekly.com/) - Weekly GraphQL newsletter
- [This Week in GraphQL](https://thisweekin.graphql.org/) - GraphQL news and updates
