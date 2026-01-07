---
title: API Integration with Python
description: Guide to integrating external APIs in Python applications
author: Joseph Streeter
date: 2026-01-04
tags: [python, api, rest, graphql, integration, requests, http]
---

## Overview

API integration enables Python applications to interact with external services. This guide covers RESTful APIs, GraphQL, authentication, and best practices.

## REST APIs

### Using Requests Library

```python
import requests

# GET request
response = requests.get('https://api.example.com/users')
users = response.json()

# POST request
data = {'name': 'John Doe', 'email': 'john@example.com'}
response = requests.post('https://api.example.com/users', json=data)

# Error handling
try:
    response.raise_for_status()
except requests.exceptions.HTTPError as e:
    print(f"HTTP error: {e}")
```

### Authentication

#### API Keys

```python
headers = {'Authorization': f'Bearer {api_key}'}
response = requests.get(url, headers=headers)
```

#### OAuth 2.0

```python
from requests_oauthlib import OAuth2Session

client_id = 'your_client_id'
oauth = OAuth2Session(client_id)
authorization_url, state = oauth.authorization_url('https://provider.com/oauth/authorize')
```

## GraphQL

```python
from gql import gql, Client
from gql.transport.requests import RequestsHTTPTransport

transport = RequestsHTTPTransport(url='https://api.example.com/graphql')
client = Client(transport=transport)

query = gql("""
    query {
        users {
            id
            name
        }
    }
""")

result = client.execute(query)
```

## Best Practices

- Implement retry logic with exponential backoff
- Use connection pooling
- Handle rate limiting
- Validate responses
- Log API interactions

## See Also

- [Web Scraping](automation/web-scraping.md)
- [Testing](testing/index.md)
- [Best Practices](best-practices/index.md)
