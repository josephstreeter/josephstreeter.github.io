---
title: Vector Databases for AI Automation
description: Guide to using vector databases for semantic search and RAG in AI automation workflows
author: Joseph Streeter
date: 2026-01-04
tags: [ai, vector-database, embeddings, rag, semantic-search, knowledge-base]
---

## Overview

Vector databases store and query high-dimensional vectors (embeddings) that represent semantic meaning of text, images, or other data. They are essential for Retrieval Augmented Generation (RAG), semantic search, and recommendation systems in AI automation workflows.

## Key Concepts

### Embeddings

Numerical representations of data that capture semantic meaning:

- **Text Embeddings**: Convert text to vectors (e.g., 1536 dimensions for OpenAI ada-002)
- **Image Embeddings**: Visual feature vectors
- **Multimodal Embeddings**: Combined text and image representations

### Vector Similarity

Measure semantic similarity using:

- **Cosine Similarity**: Measures angle between vectors
- **Euclidean Distance**: Straight-line distance between points
- **Dot Product**: Combines magnitude and direction

### Vector Search

Find similar items efficiently:

- **K-Nearest Neighbors (KNN)**: Find K most similar vectors
- **Approximate Nearest Neighbors (ANN)**: Fast approximate search
- **Hybrid Search**: Combine vector and keyword search

## Popular Vector Databases

### Pinecone

Cloud-native vector database:

```python
import pinecone
from openai import OpenAI

# Initialize Pinecone
pinecone.init(api_key="your-api-key", environment="us-west1-gcp")

# Create index
index = pinecone.Index("my-index")

# Create embeddings
client = OpenAI()
response = client.embeddings.create(
    input="Your text here",
    model="text-embedding-ada-002"
)
embedding = response.data[0].embedding

# Upsert vectors
index.upsert(vectors=[
    ("id1", embedding, {"text": "Your text here"})
])

# Query
results = index.query(
    vector=embedding,
    top_k=5,
    include_metadata=True
)
```

### Weaviate

Open-source vector search engine:

```python
import weaviate
from weaviate.classes.init import Auth

# Connect to Weaviate
client = weaviate.connect_to_wcs(
    cluster_url="your-cluster-url",
    auth_credentials=Auth.api_key("your-api-key")
)

# Create collection
collection = client.collections.create(
    name="Documents",
    vectorizer_config=weaviate.classes.config.Configure.Vectorizer.text2vec_openai(),
)

# Add objects
collection.data.insert({
    "title": "Document Title",
    "content": "Document content here"
})

# Semantic search
response = collection.query.near_text(
    query="search query",
    limit=5
)
```

### Qdrant

High-performance vector search engine:

```python
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct

# Initialize client
client = QdrantClient(url="http://localhost:6333")

# Create collection
client.create_collection(
    collection_name="my_collection",
    vectors_config=VectorParams(size=1536, distance=Distance.COSINE)
)

# Insert vectors
client.upsert(
    collection_name="my_collection",
    points=[
        PointStruct(
            id=1,
            vector=embedding,
            payload={"text": "Document content"}
        )
    ]
)

# Search
results = client.search(
    collection_name="my_collection",
    query_vector=query_embedding,
    limit=5
)
```

### Chroma

Lightweight, embeddable vector database:

```python
import chromadb
from chromadb.config import Settings

# Initialize Chroma
client = chromadb.Client(Settings(
    chroma_db_impl="duckdb+parquet",
    persist_directory="./chroma_data"
))

# Create collection
collection = client.create_collection(name="documents")

# Add documents (embeddings created automatically)
collection.add(
    documents=["Document 1 content", "Document 2 content"],
    metadatas=[{"source": "doc1"}, {"source": "doc2"}],
    ids=["id1", "id2"]
)

# Query
results = collection.query(
    query_texts=["search query"],
    n_results=5
)
```

### Milvus

Scalable vector database:

```python
from pymilvus import connections, Collection, FieldSchema, CollectionSchema, DataType

# Connect
connections.connect(host="localhost", port="19530")

# Define schema
fields = [
    FieldSchema(name="id", dtype=DataType.INT64, is_primary=True),
    FieldSchema(name="embedding", dtype=DataType.FLOAT_VECTOR, dim=1536),
    FieldSchema(name="text", dtype=DataType.VARCHAR, max_length=65535)
]
schema = CollectionSchema(fields=fields)

# Create collection
collection = Collection(name="documents", schema=schema)

# Insert data
collection.insert([
    [1, 2, 3],  # IDs
    [embedding1, embedding2, embedding3],  # Vectors
    ["text1", "text2", "text3"]  # Metadata
])

# Search
search_params = {"metric_type": "COSINE", "params": {"nprobe": 10}}
results = collection.search(
    data=[query_embedding],
    anns_field="embedding",
    param=search_params,
    limit=5
)
```

## RAG Implementation

### Basic RAG Pattern

```python
from openai import OpenAI
import chromadb

class RAGSystem:
    def __init__(self):
        self.client = OpenAI()
        self.chroma_client = chromadb.Client()
        self.collection = self.chroma_client.create_collection("knowledge_base")
        
    def add_documents(self, documents):
        """Add documents to vector database."""
        self.collection.add(
            documents=documents,
            ids=[f"doc_{i}" for i in range(len(documents))]
        )
        
    def retrieve(self, query, k=5):
        """Retrieve relevant documents."""
        results = self.collection.query(
            query_texts=[query],
            n_results=k
        )
        return results['documents'][0]
        
    def generate(self, query, context):
        """Generate response using retrieved context."""
        prompt = f"""Answer the question based on the context below.
        
Context:
{chr(10).join(context)}

Question: {query}

Answer:"""
        
        response = self.client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}]
        )
        return response.choices[0].message.content
        
    def query(self, question):
        """Complete RAG pipeline."""
        # Retrieve relevant context
        context = self.retrieve(question)
        
        # Generate response
        answer = self.generate(question, context)
        
        return {
            'answer': answer,
            'sources': context
        }
```

### Advanced RAG with Reranking

```python
from sentence_transformers import CrossEncoder

class AdvancedRAG(RAGSystem):
    def __init__(self):
        super().__init__()
        self.reranker = CrossEncoder('cross-encoder/ms-marco-MiniLM-L-6-v2')
        
    def retrieve_and_rerank(self, query, k=5, rerank_k=20):
        """Retrieve more documents and rerank them."""
        # Initial retrieval
        initial_results = self.collection.query(
            query_texts=[query],
            n_results=rerank_k
        )
        
        documents = initial_results['documents'][0]
        
        # Rerank using cross-encoder
        pairs = [[query, doc] for doc in documents]
        scores = self.reranker.predict(pairs)
        
        # Sort by score and take top k
        ranked_docs = sorted(zip(documents, scores), key=lambda x: x[1], reverse=True)
        return [doc for doc, score in ranked_docs[:k]]
```

## Hybrid Search

Combine vector and keyword search:

```python
class HybridSearch:
    def __init__(self, vector_db, keyword_db):
        self.vector_db = vector_db
        self.keyword_db = keyword_db
        
    def search(self, query, alpha=0.5):
        """
        Hybrid search combining vector and keyword results.
        alpha: weight for vector search (1-alpha for keyword)
        """
        # Vector search
        vector_results = self.vector_db.search(query)
        
        # Keyword search (BM25, Elasticsearch, etc.)
        keyword_results = self.keyword_db.search(query)
        
        # Combine scores
        combined_scores = {}
        
        for result in vector_results:
            combined_scores[result['id']] = alpha * result['score']
            
        for result in keyword_results:
            combined_scores[result['id']] = combined_scores.get(result['id'], 0) + (1 - alpha) * result['score']
            
        # Sort by combined score
        sorted_results = sorted(combined_scores.items(), key=lambda x: x[1], reverse=True)
        
        return sorted_results
```

## Data Ingestion Strategies

### Document Chunking

```python
def chunk_document(text, chunk_size=500, overlap=50):
    """Split document into overlapping chunks."""
    words = text.split()
    chunks = []
    
    for i in range(0, len(words), chunk_size - overlap):
        chunk = ' '.join(words[i:i + chunk_size])
        chunks.append(chunk)
        
    return chunks
```

### Metadata Enrichment

```python
def enrich_document(document, metadata):
    """Add metadata for filtering and retrieval."""
    return {
        'content': document,
        'metadata': {
            'source': metadata.get('source'),
            'date': metadata.get('date'),
            'category': metadata.get('category'),
            'author': metadata.get('author'),
            'tags': metadata.get('tags', [])
        }
    }
```

## Performance Optimization

### Indexing Strategies

- **HNSW (Hierarchical Navigable Small World)**: Fast approximate search
- **IVF (Inverted File Index)**: Memory-efficient for large datasets
- **Product Quantization**: Reduce memory usage

### Caching

```python
from functools import lru_cache

class CachedVectorSearch:
    def __init__(self, vector_db):
        self.vector_db = vector_db
        
    @lru_cache(maxsize=1000)
    def search(self, query, k=5):
        """Cache search results for repeated queries."""
        return self.vector_db.search(query, k)
```

### Batch Processing

```python
def batch_upsert(vector_db, documents, batch_size=100):
    """Insert documents in batches for better performance."""
    for i in range(0, len(documents), batch_size):
        batch = documents[i:i + batch_size]
        vector_db.upsert(batch)
```

## Best Practices

### Choosing Embedding Models

- **OpenAI ada-002**: High quality, 1536 dimensions
- **Sentence Transformers**: Open-source, various sizes
- **Cohere Embed**: Optimized for search
- **Custom Fine-tuned**: Domain-specific embeddings

### Collection Management

- **Separate Collections**: Different document types or domains
- **Namespace Isolation**: Tenant separation in multi-tenant systems
- **Version Control**: Track embedding model versions

### Metadata Filtering

```python
# Filter by metadata before vector search
results = collection.query(
    query_texts=["search query"],
    n_results=10,
    where={"category": "technical", "date": {"$gte": "2024-01-01"}}
)
```

## Security Considerations

### Access Control

```python
def search_with_access_control(user_id, query, vector_db):
    """Enforce row-level security."""
    results = vector_db.search(query)
    
    # Filter results based on user permissions
    filtered_results = [
        r for r in results
        if has_permission(user_id, r['metadata']['resource_id'])
    ]
    
    return filtered_results
```

### Data Privacy

- Encrypt vectors at rest
- Use secure connections (TLS)
- Implement audit logging
- Regular access reviews

## Cost Optimization

### Reduce Storage Costs

- Use smaller embedding dimensions when possible
- Implement data lifecycle policies
- Compress metadata
- Remove duplicate vectors

### Optimize API Usage

- Batch embedding generation
- Cache frequently accessed vectors
- Use cheaper models for less critical searches

## See Also

- [Prompt Engineering](prompt-engineering.md)
- [Best Practices](best-practices.md)
- [LangFlow](langflow.md)
- [Flowise](flowise.md)
