---
title: "Database Integration"
description: "Vector stores, relational persistence, and retrieval patterns for LLM applications"
author: "Joseph Streeter"
tags: ["local llms", "integration", "database", "vector store", "retrieval"]
category: "ai"
last_updated: "2026-08-01"
---
## Database Integration

Integrating local LLMs with various database systems for persistent storage, vector search, and session management.

### Vector Databases

Vector databases are essential for RAG (Retrieval-Augmented Generation) applications, enabling semantic search and similarity matching.

**Pinecone Integration:**

```python
# pinecone_llm_integration.py - Pinecone with local LLM
import pinecone
import openai
from typing import List, Dict, Any, Optional
import numpy as np
from sentence_transformers import SentenceTransformer
import asyncio
import logging

class PineconeLLMIntegration:
    def __init__(
        self, 
        pinecone_api_key: str,
        pinecone_env: str,
        index_name: str,
        llm_api_url: str = "http://localhost:8080",
        embedding_model: str = "all-MiniLM-L6-v2"
    ):
        # Initialize Pinecone
        pinecone.init(api_key=pinecone_api_key, environment=pinecone_env)
        self.index = pinecone.Index(index_name)
        
        # Initialize LLM client
        self.llm_client = openai.OpenAI(
            api_key="not-needed",
            base_url=f"{llm_api_url}/v1"
        )
        
        # Initialize embedding model
        self.embedding_model = SentenceTransformer(embedding_model)
        
        self.logger = logging.getLogger(__name__)
    
    def embed_text(self, text: str) -> List[float]:
        """Generate embeddings for text"""
        try:
            embedding = self.embedding_model.encode(text)
            return embedding.tolist()
        except Exception as e:
            self.logger.error(f"Error generating embedding: {e}")
            raise
    
    async def store_document(
        self, 
        doc_id: str, 
        text: str, 
        metadata: Optional[Dict[str, Any]] = None
    ) -> bool:
        """Store document with embeddings in Pinecone"""
        try:
            # Generate embedding
            embedding = self.embed_text(text)
            
            # Prepare metadata
            doc_metadata = {
                "text": text,
                "timestamp": str(asyncio.get_event_loop().time()),
                **(metadata or {})
            }
            
            # Upsert to Pinecone
            self.index.upsert(vectors=[(doc_id, embedding, doc_metadata)])
            
            self.logger.info(f"Stored document {doc_id} in Pinecone")
            return True
            
        except Exception as e:
            self.logger.error(f"Error storing document: {e}")
            return False
    
    async def semantic_search(
        self, 
        query: str, 
        top_k: int = 5,
        filter_metadata: Optional[Dict[str, Any]] = None
    ) -> List[Dict[str, Any]]:
        """Perform semantic search in Pinecone"""
        try:
            # Generate query embedding
            query_embedding = self.embed_text(query)
            
            # Search in Pinecone
            search_response = self.index.query(
                vector=query_embedding,
                top_k=top_k,
                filter=filter_metadata,
                include_metadata=True,
                include_values=False
            )
            
            # Format results
            results = []
            for match in search_response.matches:
                results.append({
                    "id": match.id,
                    "score": match.score,
                    "text": match.metadata.get("text", ""),
                    "metadata": match.metadata
                })
            
            return results
            
        except Exception as e:
            self.logger.error(f"Error in semantic search: {e}")
            return []
    
    async def rag_query(
        self, 
        query: str, 
        model: str = "llama-2-7b-chat",
        max_context_length: int = 2000,
        system_prompt: Optional[str] = None
    ) -> Dict[str, Any]:
        """Perform RAG query using Pinecone and local LLM"""
        try:
            # Search for relevant documents
            search_results = await self.semantic_search(query, top_k=3)
            
            if not search_results:
                return {
                    "response": "I don't have relevant information to answer your question.",
                    "sources": []
                }
            
            # Build context from search results
            context_parts = []
            sources = []
            
            for result in search_results:
                if len(" ".join(context_parts)) < max_context_length:
                    context_parts.append(result["text"])
                    sources.append({
                        "id": result["id"],
                        "score": result["score"],
                        "metadata": result["metadata"]
                    })
            
            context = "\n\n".join(context_parts)
            
            # Build prompt
            messages = []
            
            if system_prompt:
                messages.append({"role": "system", "content": system_prompt})
            else:
                messages.append({
                    "role": "system", 
                    "content": "You are a helpful assistant. Answer questions based on the provided context. If the context doesn't contain relevant information, say so clearly."
                })
            
            messages.append({
                "role": "user",
                "content": f"Context:\n{context}\n\nQuestion: {query}\n\nPlease provide a comprehensive answer based on the context above."
            })
            
            # Generate response with LLM
            response = self.llm_client.chat.completions.create(
                model=model,
                messages=messages,
                temperature=0.7,
                max_tokens=500
            )
            
            return {
                "response": response.choices[0].message.content,
                "sources": sources,
                "context_used": len(context_parts)
            }
            
        except Exception as e:
            self.logger.error(f"Error in RAG query: {e}")
            return {
                "response": f"Error processing query: {str(e)}",
                "sources": []
            }
    
    async def batch_store_documents(
        self, 
        documents: List[Dict[str, Any]],
        batch_size: int = 100
    ) -> Dict[str, int]:
        """Store multiple documents in batches"""
        successful = 0
        failed = 0
        
        for i in range(0, len(documents), batch_size):
            batch = documents[i:i + batch_size]
            vectors_to_upsert = []
            
            try:
                for doc in batch:
                    embedding = self.embed_text(doc["text"])
                    vectors_to_upsert.append((
                        doc["id"],
                        embedding,
                        {
                            "text": doc["text"],
                            "timestamp": str(asyncio.get_event_loop().time()),
                            **doc.get("metadata", {})
                        }
                    ))
                
                # Batch upsert
                self.index.upsert(vectors=vectors_to_upsert)
                successful += len(batch)
                
                self.logger.info(f"Processed batch {i//batch_size + 1}, stored {len(batch)} documents")
                
            except Exception as e:
                self.logger.error(f"Error in batch {i//batch_size + 1}: {e}")
                failed += len(batch)
        
        return {"successful": successful, "failed": failed}

# Usage example
async def main():
    # Initialize integration
    rag_system = PineconeLLMIntegration(
        pinecone_api_key="your-pinecone-api-key",
        pinecone_env="your-pinecone-environment", 
        index_name="llm-knowledge-base"
    )
    
    # Store some documents
    documents = [
        {
            "id": "doc1",
            "text": "Python is a high-level programming language known for its simplicity and readability.",
            "metadata": {"category": "programming", "language": "python"}
        },
        {
            "id": "doc2", 
            "text": "Machine learning is a subset of artificial intelligence that enables computers to learn without explicit programming.",
            "metadata": {"category": "ai", "topic": "machine-learning"}
        }
    ]
    
    # Batch store documents
    result = await rag_system.batch_store_documents(documents)
    print(f"Stored documents: {result}")
    
    # Perform RAG query
    response = await rag_system.rag_query("What is Python programming language?")
    print(f"Response: {response['response']}")
    print(f"Sources used: {len(response['sources'])}")

if __name__ == "__main__":
    asyncio.run(main())
```

**Chroma Integration:**

```python
# chroma_llm_integration.py - ChromaDB with local LLM
import chromadb
from chromadb.config import Settings
import openai
from typing import List, Dict, Any, Optional
import uuid
import asyncio
from pathlib import Path

class ChromaLLMIntegration:
    def __init__(
        self,
        persist_directory: str = "./chroma_db",
        collection_name: str = "llm_documents",
        llm_api_url: str = "http://localhost:8080",
        embedding_model: str = "all-MiniLM-L6-v2"
    ):
        # Initialize ChromaDB
        self.chroma_client = chromadb.PersistentClient(
            path=persist_directory,
            settings=Settings(
                anonymized_telemetry=False,
                allow_reset=True
            )
        )
        
        # Get or create collection
        self.collection = self.chroma_client.get_or_create_collection(
            name=collection_name,
            embedding_function=chromadb.utils.embedding_functions.SentenceTransformerEmbeddingFunction(
                model_name=embedding_model
            )
        )
        
        # Initialize LLM client
        self.llm_client = openai.OpenAI(
            api_key="not-needed",
            base_url=f"{llm_api_url}/v1"
        )
    
    def add_documents(
        self,
        documents: List[str],
        metadatas: Optional[List[Dict[str, Any]]] = None,
        ids: Optional[List[str]] = None
    ) -> List[str]:
        """Add documents to ChromaDB"""
        
        # Generate IDs if not provided
        if ids is None:
            ids = [str(uuid.uuid4()) for _ in documents]
        
        # Add default metadata if not provided
        if metadatas is None:
            metadatas = [{"timestamp": str(asyncio.get_event_loop().time())} for _ in documents]
        
        try:
            self.collection.add(
                documents=documents,
                metadatas=metadatas,
                ids=ids
            )
            return ids
        except Exception as e:
            print(f"Error adding documents: {e}")
            return []
    
    def search_documents(
        self,
        query: str,
        n_results: int = 5,
        where: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Search documents in ChromaDB"""
        try:
            results = self.collection.query(
                query_texts=[query],
                n_results=n_results,
                where=where
            )
            
            # Format results
            formatted_results = []
            if results['documents'] and results['documents'][0]:
                for i in range(len(results['documents'][0])):
                    formatted_results.append({
                        "id": results['ids'][0][i],
                        "document": results['documents'][0][i],
                        "metadata": results['metadatas'][0][i] if results['metadatas'] else {},
                        "distance": results['distances'][0][i] if results['distances'] else None
                    })
            
            return {
                "results": formatted_results,
                "query": query,
                "total_results": len(formatted_results)
            }
            
        except Exception as e:
            print(f"Error searching documents: {e}")
            return {"results": [], "query": query, "total_results": 0}
    
    async def rag_chat(
        self,
        query: str,
        model: str = "llama-2-7b-chat",
        context_limit: int = 2000,
        n_context_docs: int = 3
    ) -> Dict[str, Any]:
        """RAG-powered chat using ChromaDB and local LLM"""
        
        # Search for relevant documents
        search_results = self.search_documents(query, n_results=n_context_docs)
        
        if not search_results["results"]:
            return {
                "response": "I don't have relevant information in my knowledge base.",
                "context_used": [],
                "query": query
            }
        
        # Build context
        context_parts = []
        context_metadata = []
        
        for result in search_results["results"]:
            doc_text = result["document"]
            if len(" ".join(context_parts + [doc_text])) <= context_limit:
                context_parts.append(doc_text)
                context_metadata.append({
                    "id": result["id"],
                    "metadata": result["metadata"],
                    "distance": result["distance"]
                })
        
        context = "\n\n---\n\n".join(context_parts)
        
        # Create chat messages
        messages = [
            {
                "role": "system",
                "content": "You are a helpful assistant. Use the provided context to answer questions accurately. If the context doesn't contain relevant information, say so clearly. Always cite which parts of the context you're using."
            },
            {
                "role": "user", 
                "content": f"Context:\n{context}\n\nQuestion: {query}"
            }
        ]
        
        try:
            # Generate response
            response = self.llm_client.chat.completions.create(
                model=model,
                messages=messages,
                temperature=0.7,
                max_tokens=600
            )
            
            return {
                "response": response.choices[0].message.content,
                "context_used": context_metadata,
                "query": query,
                "total_context_chars": len(context)
            }
            
        except Exception as e:
            return {
                "response": f"Error generating response: {str(e)}",
                "context_used": context_metadata,
                "query": query
            }
    
    def get_collection_stats(self) -> Dict[str, Any]:
        """Get statistics about the collection"""
        try:
            count = self.collection.count()
            
            # Get sample of documents to analyze
            sample = self.collection.peek(limit=min(10, count))
            
            return {
                "total_documents": count,
                "collection_name": self.collection.name,
                "sample_ids": sample.get("ids", [])[:5],
                "has_embeddings": bool(sample.get("embeddings")),
                "metadata_fields": list(sample["metadatas"][0].keys()) if sample.get("metadatas") and sample["metadatas"] else []
            }
        except Exception as e:
            return {"error": str(e)}
    
    def delete_documents(self, ids: List[str]) -> bool:
        """Delete documents by IDs"""
        try:
            self.collection.delete(ids=ids)
            return True
        except Exception as e:
            print(f"Error deleting documents: {e}")
            return False
    
    def reset_collection(self) -> bool:
        """Reset the entire collection"""
        try:
            self.chroma_client.delete_collection(self.collection.name)
            self.collection = self.chroma_client.create_collection(
                name=self.collection.name,
                embedding_function=chromadb.utils.embedding_functions.SentenceTransformerEmbeddingFunction()
            )
            return True
        except Exception as e:
            print(f"Error resetting collection: {e}")
            return False

# Usage example with document processing
class DocumentProcessor:
    def __init__(self, chroma_integration: ChromaLLMIntegration):
        self.chroma = chroma_integration
    
    def process_text_file(self, file_path: str, chunk_size: int = 1000) -> List[str]:
        """Process a text file into chunks"""
        try:
            with open(file_path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            # Simple chunking by character count
            chunks = []
            for i in range(0, len(content), chunk_size):
                chunk = content[i:i + chunk_size]
                if chunk.strip():
                    chunks.append(chunk.strip())
            
            return chunks
            
        except Exception as e:
            print(f"Error processing file: {e}")
            return []
    
    def process_directory(self, directory_path: str, file_extensions: List[str] = [".txt", ".md"]) -> int:
        """Process all files in a directory"""
        directory = Path(directory_path)
        total_chunks = 0
        
        for ext in file_extensions:
            for file_path in directory.glob(f"**/*{ext}"):
                print(f"Processing: {file_path}")
                
                chunks = self.process_text_file(str(file_path))
                if chunks:
                    # Create metadata for chunks
                    metadatas = []
                    for i, chunk in enumerate(chunks):
                        metadatas.append({
                            "source_file": str(file_path),
                            "chunk_index": i,
                            "file_extension": ext,
                            "timestamp": str(asyncio.get_event_loop().time())
                        })
                    
                    # Add to ChromaDB
                    ids = self.chroma.add_documents(chunks, metadatas)
                    total_chunks += len(ids)
                    print(f"  Added {len(ids)} chunks")
        
        return total_chunks

# Complete usage example
async def demo_chroma_rag():
    # Initialize ChromaDB integration
    chroma_rag = ChromaLLMIntegration(
        persist_directory="./demo_chroma_db",
        collection_name="knowledge_base"
    )
    
    # Add some sample documents
    sample_docs = [
        "Python is a versatile programming language used for web development, data science, and automation.",
        "Machine learning algorithms can be supervised, unsupervised, or reinforcement learning based.",
        "Docker containers provide a lightweight way to package applications with their dependencies.",
        "REST APIs use HTTP methods like GET, POST, PUT, and DELETE to interact with resources.",
        "Database indexing improves query performance by creating efficient data access paths."
    ]
    
    sample_metadata = [
        {"topic": "programming", "language": "python"},
        {"topic": "ai", "subtopic": "machine-learning"},
        {"topic": "devops", "tool": "docker"},
        {"topic": "web-development", "type": "api"},
        {"topic": "database", "concept": "optimization"}
    ]
    
    # Add documents
    doc_ids = chroma_rag.add_documents(sample_docs, sample_metadata)
    print(f"Added {len(doc_ids)} documents")
    
    # Get collection stats
    stats = chroma_rag.get_collection_stats()
    print(f"Collection stats: {stats}")
    
    # Perform RAG queries
    queries = [
        "How is Python used in programming?",
        "What are the types of machine learning?",
        "How do REST APIs work?"
    ]
    
    for query in queries:
        print(f"\nQuery: {query}")
        response = await chroma_rag.rag_chat(query)
        print(f"Response: {response['response']}")
        print(f"Context sources: {len(response['context_used'])}")

if __name__ == "__main__":
    asyncio.run(demo_chroma_rag())
```

### Document Stores

Traditional document databases for storing conversation history, user preferences, and application data.

**MongoDB Integration:**

```python
# mongodb_llm_integration.py - MongoDB with local LLM
from motor.motor_asyncio import AsyncIOMotorClient
import openai
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
import asyncio
from bson import ObjectId
import json

class MongoLLMIntegration:
    def __init__(
        self,
        mongodb_uri: str = "mongodb://localhost:27017",
        database_name: str = "llm_app",
        llm_api_url: str = "http://localhost:8080"
    ):
        # Initialize MongoDB
        self.client = AsyncIOMotorClient(mongodb_uri)
        self.db = self.client[database_name]
        
        # Collections
        self.conversations = self.db.conversations
        self.users = self.db.users
        self.documents = self.db.documents
        self.chat_sessions = self.db.chat_sessions
        
        # Initialize LLM client
        self.llm_client = openai.OpenAI(
            api_key="not-needed",
            base_url=f"{llm_api_url}/v1"
        )
        
        # Initialize collections with indexes
        asyncio.create_task(self._setup_indexes())
    
    async def _setup_indexes(self):
        """Create database indexes for optimal performance"""
        try:
            # Conversations indexes
            await self.conversations.create_index("user_id")
            await self.conversations.create_index("session_id")
            await self.conversations.create_index("created_at")
            await self.conversations.create_index([("user_id", 1), ("created_at", -1)])
            
            # Users indexes
            await self.users.create_index("email", unique=True)
            await self.users.create_index("api_key", unique=True, sparse=True)
            
            # Documents indexes
            await self.documents.create_index("user_id")
            await self.documents.create_index("tags")
            await self.documents.create_index([("title", "text"), ("content", "text")])
            
            # Chat sessions indexes
            await self.chat_sessions.create_index("user_id")
            await self.chat_sessions.create_index("last_activity")
            await self.chat_sessions.create_index([("user_id", 1), ("last_activity", -1)])
            
        except Exception as e:
            print(f"Error setting up indexes: {e}")
    
    async def create_user(
        self, 
        email: str, 
        name: str, 
        preferences: Optional[Dict[str, Any]] = None
    ) -> Optional[str]:
        """Create a new user"""
        try:
            user_doc = {
                "email": email,
                "name": name,
                "preferences": preferences or {
                    "model": "llama-2-7b-chat",
                    "temperature": 0.7,
                    "max_tokens": 500,
                    "language": "en"
                },
                "created_at": datetime.utcnow(),
                "last_activity": datetime.utcnow(),
                "total_messages": 0,
                "total_sessions": 0
            }
            
            result = await self.users.insert_one(user_doc)
            return str(result.inserted_id)
            
        except Exception as e:
            print(f"Error creating user: {e}")
            return None
    
    async def get_user(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get user by ID"""
        try:
            user = await self.users.find_one({"_id": ObjectId(user_id)})
            if user:
                user["_id"] = str(user["_id"])
            return user
        except Exception as e:
            print(f"Error getting user: {e}")
            return None
    
    async def create_chat_session(self, user_id: str, title: str = "New Chat") -> Optional[str]:
        """Create a new chat session"""
        try:
            session_doc = {
                "user_id": user_id,
                "title": title,
                "created_at": datetime.utcnow(),
                "last_activity": datetime.utcnow(),
                "message_count": 0,
                "status": "active"
            }
            
            result = await self.chat_sessions.insert_one(session_doc)
            
            # Update user session count
            await self.users.update_one(
                {"_id": ObjectId(user_id)},
                {"$inc": {"total_sessions": 1}}
            )
            
            return str(result.inserted_id)
            
        except Exception as e:
            print(f"Error creating chat session: {e}")
            return None
    
    async def add_conversation_message(
        self,
        session_id: str,
        user_id: str,
        role: str,
        content: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> Optional[str]:
        """Add a message to a conversation"""
        try:
            message_doc = {
                "session_id": session_id,
                "user_id": user_id,
                "role": role,
                "content": content,
                "metadata": metadata or {},
                "created_at": datetime.utcnow(),
                "tokens_used": len(content.split()) * 1.3  # Rough estimate
            }
            
            result = await self.conversations.insert_one(message_doc)
            
            # Update session and user counters
            await asyncio.gather(
                self.chat_sessions.update_one(
                    {"_id": ObjectId(session_id)},
                    {
                        "$inc": {"message_count": 1},
                        "$set": {"last_activity": datetime.utcnow()}
                    }
                ),
                self.users.update_one(
                    {"_id": ObjectId(user_id)},
                    {
                        "$inc": {"total_messages": 1},
                        "$set": {"last_activity": datetime.utcnow()}
                    }
                )
            )
            
            return str(result.inserted_id)
            
        except Exception as e:
            print(f"Error adding message: {e}")
            return None
    
    async def get_conversation_history(
        self,
        session_id: str,
        limit: int = 50,
        skip: int = 0
    ) -> List[Dict[str, Any]]:
        """Get conversation history for a session"""
        try:
            cursor = self.conversations.find(
                {"session_id": session_id}
            ).sort("created_at", 1).skip(skip).limit(limit)
            
            messages = []
            async for message in cursor:
                message["_id"] = str(message["_id"])
                message["created_at"] = message["created_at"].isoformat()
                messages.append(message)
            
            return messages
            
        except Exception as e:
            print(f"Error getting conversation history: {e}")
            return []
    
    async def chat_with_context(
        self,
        session_id: str,
        user_id: str,
        message: str,
        model: Optional[str] = None,
        include_history: int = 10
    ) -> Dict[str, Any]:
        """Chat with conversation context from MongoDB"""
        try:
            # Get user preferences
            user = await self.get_user(user_id)
            if not user:
                return {"error": "User not found"}
            
            # Use user's preferred model if not specified
            model = model or user["preferences"].get("model", "llama-2-7b-chat")
            
            # Get recent conversation history
            history = await self.get_conversation_history(session_id, limit=include_history)
            
            # Build messages for LLM
            messages = []
            
            # Add system message based on user preferences
            system_prompt = user["preferences"].get("system_prompt", 
                "You are a helpful AI assistant. Provide accurate and helpful responses.")
            messages.append({"role": "system", "content": system_prompt})
            
            # Add conversation history
            for msg in history:
                if msg["role"] in ["user", "assistant"]:
                    messages.append({
                        "role": msg["role"],
                        "content": msg["content"]
                    })
            
            # Add current message
            messages.append({"role": "user", "content": message})
            
            # Store user message
            await self.add_conversation_message(session_id, user_id, "user", message)
            
            # Generate response
            response = self.llm_client.chat.completions.create(
                model=model,
                messages=messages,
                temperature=user["preferences"].get("temperature", 0.7),
                max_tokens=user["preferences"].get("max_tokens", 500)
            )
            
            assistant_response = response.choices[0].message.content
            
            # Store assistant response
            await self.add_conversation_message(
                session_id, 
                user_id, 
                "assistant", 
                assistant_response,
                {
                    "model": model,
                    "usage": dict(response.usage) if response.usage else {},
                    "total_tokens": response.usage.total_tokens if response.usage else 0
                }
            )
            
            return {
                "response": assistant_response,
                "session_id": session_id,
                "model": model,
                "usage": dict(response.usage) if response.usage else {}
            }
            
        except Exception as e:
            error_msg = f"Error in chat: {str(e)}"
            print(error_msg)
            return {"error": error_msg}
    
    async def get_user_sessions(
        self, 
        user_id: str, 
        limit: int = 20,
        skip: int = 0
    ) -> List[Dict[str, Any]]:
        """Get user's chat sessions"""
        try:
            cursor = self.chat_sessions.find(
                {"user_id": user_id}
            ).sort("last_activity", -1).skip(skip).limit(limit)
            
            sessions = []
            async for session in cursor:
                session["_id"] = str(session["_id"])
                session["created_at"] = session["created_at"].isoformat()
                session["last_activity"] = session["last_activity"].isoformat()
                sessions.append(session)
            
            return sessions
            
        except Exception as e:
            print(f"Error getting user sessions: {e}")
            return []
    
    async def search_conversations(
        self,
        user_id: str,
        query: str,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """Search user's conversations"""
        try:
            # Text search in conversation content
            cursor = self.conversations.find(
                {
                    "user_id": user_id,
                    "$text": {"$search": query}
                },
                {"score": {"$meta": "textScore"}}
            ).sort([("score", {"$meta": "textScore"})]).limit(limit)
            
            results = []
            async for message in cursor:
                message["_id"] = str(message["_id"])
                message["created_at"] = message["created_at"].isoformat()
                results.append(message)
            
            return results
            
        except Exception as e:
            print(f"Error searching conversations: {e}")
            return []
    
    async def get_analytics(self, user_id: str, days: int = 30) -> Dict[str, Any]:
        """Get user analytics"""
        try:
            start_date = datetime.utcnow() - timedelta(days=days)
            
            # Aggregate conversation stats
            pipeline = [
                {
                    "$match": {
                        "user_id": user_id,
                        "created_at": {"$gte": start_date}
                    }
                },
                {
                    "$group": {
                        "_id": {"$dateToString": {"format": "%Y-%m-%d", "date": "$created_at"}},
                        "message_count": {"$sum": 1},
                        "total_tokens": {"$sum": "$tokens_used"}
                    }
                },
                {"$sort": {"_id": 1}}
            ]
            
            daily_stats = []
            async for stat in self.conversations.aggregate(pipeline):
                daily_stats.append(stat)
            
            # Get total stats
            total_messages = await self.conversations.count_documents({
                "user_id": user_id,
                "created_at": {"$gte": start_date}
            })
            
            total_sessions = await self.chat_sessions.count_documents({
                "user_id": user_id,
                "created_at": {"$gte": start_date}
            })
            
            return {
                "daily_stats": daily_stats,
                "total_messages": total_messages,
                "total_sessions": total_sessions,
                "period_days": days
            }
            
        except Exception as e:
            print(f"Error getting analytics: {e}")
            return {}
    
    async def cleanup_old_data(self, retention_days: int = 90):
        """Clean up old conversation data"""
        try:
            cutoff_date = datetime.utcnow() - timedelta(days=retention_days)
            
            # Delete old conversations
            conv_result = await self.conversations.delete_many({
                "created_at": {"$lt": cutoff_date}
            })
            
            # Delete old inactive sessions
            session_result = await self.chat_sessions.delete_many({
                "last_activity": {"$lt": cutoff_date},
                "status": "inactive"
            })
            
            return {
                "conversations_deleted": conv_result.deleted_count,
                "sessions_deleted": session_result.deleted_count,
                "retention_days": retention_days
            }
            
        except Exception as e:
            print(f"Error cleaning up data: {e}")
            return {"error": str(e)}

# Usage example
async def demo_mongodb_integration():
    # Initialize MongoDB integration
    mongo_llm = MongoLLMIntegration()
    
    # Create a user
    user_id = await mongo_llm.create_user(
        email="test@example.com",
        name="Test User",
        preferences={
            "model": "llama-2-7b-chat",
            "temperature": 0.8,
            "system_prompt": "You are a knowledgeable programming assistant."
        }
    )
    print(f"Created user: {user_id}")
    
    # Create a chat session
    session_id = await mongo_llm.create_chat_session(user_id, "Python Help")
    print(f"Created session: {session_id}")
    
    # Have a conversation
    queries = [
        "What is Python?",
        "How do I create a list in Python?",
        "Can you show me a for loop example?"
    ]
    
    for query in queries:
        response = await mongo_llm.chat_with_context(session_id, user_id, query)
        print(f"\nUser: {query}")
        print(f"Assistant: {response.get('response', 'Error')}")
    
    # Get conversation history
    history = await mongo_llm.get_conversation_history(session_id)
    print(f"\nTotal messages in conversation: {len(history)}")
    
    # Get user analytics
    analytics = await mongo_llm.get_analytics(user_id, days=7)
    print(f"Analytics: {analytics}")

if __name__ == "__main__":
    asyncio.run(demo_mongodb_integration())
```

### Session Management

Maintain conversation state and user sessions across interactions.

**Redis Session Management:**

```python
# redis_session_manager.py - Session management with Redis
import redis.asyncio as redis
import json
import uuid
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
import hashlib
import asyncio
from dataclasses import dataclass, asdict

@dataclass
class SessionConfig:
    max_messages: int = 50
    ttl_seconds: int = 3600  # 1 hour
    cleanup_interval: int = 300  # 5 minutes
    max_memory_mb: int = 10

@dataclass
class ConversationMessage:
    role: str
    content: str
    timestamp: str
    metadata: Optional[Dict[str, Any]] = None

class RedisSessionManager:
    def __init__(
        self,
        redis_url: str = "redis://localhost:6379",
        key_prefix: str = "llm_session:",
        config: Optional[SessionConfig] = None
    ):
        self.redis = redis.from_url(redis_url)
        self.key_prefix = key_prefix
        self.config = config or SessionConfig()
        
        # Start cleanup task
        asyncio.create_task(self._periodic_cleanup())
    
    def _make_session_key(self, session_id: str) -> str:
        return f"{self.key_prefix}{session_id}"
    
    def _make_user_sessions_key(self, user_id: str) -> str:
        return f"{self.key_prefix}user:{user_id}:sessions"
    
    async def create_session(
        self, 
        user_id: str,
        initial_context: Optional[Dict[str, Any]] = None
    ) -> str:
        """Create a new session"""
        session_id = str(uuid.uuid4())
        session_key = self._make_session_key(session_id)
        
        session_data = {
            "session_id": session_id,
            "user_id": user_id,
            "created_at": datetime.utcnow().isoformat(),
            "last_activity": datetime.utcnow().isoformat(),
            "message_count": 0,
            "messages": [],
            "context": initial_context or {},
            "metadata": {
                "user_agent": "",
                "ip_address": "",
                "client_version": ""
            }
        }
        
        try:
            # Store session data
            await self.redis.set(
                session_key,
                json.dumps(session_data),
                ex=self.config.ttl_seconds
            )
            
            # Add session to user's session list
            user_sessions_key = self._make_user_sessions_key(user_id)
            await self.redis.sadd(user_sessions_key, session_id)
            await self.redis.expire(user_sessions_key, self.config.ttl_seconds)
            
            return session_id
            
        except Exception as e:
            print(f"Error creating session: {e}")
            raise
    
    async def get_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Get session data"""
        try:
            session_key = self._make_session_key(session_id)
            session_data = await self.redis.get(session_key)
            
            if session_data:
                data = json.loads(session_data)
                # Update last activity
                data["last_activity"] = datetime.utcnow().isoformat()
                await self.redis.set(
                    session_key,
                    json.dumps(data),
                    ex=self.config.ttl_seconds
                )
                return data
            
            return None
            
        except Exception as e:
            print(f"Error getting session: {e}")
            return None
    
    async def add_message(
        self,
        session_id: str,
        role: str,
        content: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> bool:
        """Add a message to the session"""
        try:
            session = await self.get_session(session_id)
            if not session:
                return False
            
            # Create message
            message = ConversationMessage(
                role=role,
                content=content,
                timestamp=datetime.utcnow().isoformat(),
                metadata=metadata
            )
            
            # Add to messages
            session["messages"].append(asdict(message))
            session["message_count"] = len(session["messages"])
            session["last_activity"] = datetime.utcnow().isoformat()
            
            # Implement sliding window to limit memory usage
            if len(session["messages"]) > self.config.max_messages:
                session["messages"] = session["messages"][-self.config.max_messages:]
                session["message_count"] = len(session["messages"])
            
            # Store updated session
            session_key = self._make_session_key(session_id)
            await self.redis.set(
                session_key,
                json.dumps(session),
                ex=self.config.ttl_seconds
            )
            
            return True
            
        except Exception as e:
            print(f"Error adding message: {e}")
            return False
    
    async def get_conversation_context(
        self,
        session_id: str,
        max_messages: Optional[int] = None,
        include_system: bool = True
    ) -> List[Dict[str, str]]:
        """Get conversation context for LLM"""
        try:
            session = await self.get_session(session_id)
            if not session:
                return []
            
            messages = session.get("messages", [])
            
            # Apply message limit
            if max_messages:
                messages = messages[-max_messages:]
            
            # Format for LLM
            llm_messages = []
            
            # Add system context if available and requested
            if include_system and session.get("context", {}).get("system_prompt"):
                llm_messages.append({
                    "role": "system",
                    "content": session["context"]["system_prompt"]
                })
            
            # Add conversation messages
            for msg in messages:
                if msg["role"] in ["user", "assistant"]:
                    llm_messages.append({
                        "role": msg["role"],
                        "content": msg["content"]
                    })
            
            return llm_messages
            
        except Exception as e:
            print(f"Error getting conversation context: {e}")
            return []
    
    async def update_session_context(
        self,
        session_id: str,
        context_updates: Dict[str, Any]
    ) -> bool:
        """Update session context"""
        try:
            session = await self.get_session(session_id)
            if not session:
                return False
            
            # Update context
            session["context"].update(context_updates)
            session["last_activity"] = datetime.utcnow().isoformat()
            
            # Store updated session
            session_key = self._make_session_key(session_id)
            await self.redis.set(
                session_key,
                json.dumps(session),
                ex=self.config.ttl_seconds
            )
            
            return True
            
        except Exception as e:
            print(f"Error updating session context: {e}")
            return False
    
    async def get_user_sessions(self, user_id: str) -> List[str]:
        """Get all session IDs for a user"""
        try:
            user_sessions_key = self._make_user_sessions_key(user_id)
            session_ids = await self.redis.smembers(user_sessions_key)
            return [sid.decode() if isinstance(sid, bytes) else sid for sid in session_ids]
            
        except Exception as e:
            print(f"Error getting user sessions: {e}")
            return []
    
    async def delete_session(self, session_id: str) -> bool:
        """Delete a session"""
        try:
            session = await self.get_session(session_id)
            if not session:
                return False
            
            user_id = session["user_id"]
            
            # Delete session data
            session_key = self._make_session_key(session_id)
            await self.redis.delete(session_key)
            
            # Remove from user's session list
            user_sessions_key = self._make_user_sessions_key(user_id)
            await self.redis.srem(user_sessions_key, session_id)
            
            return True
            
        except Exception as e:
            print(f"Error deleting session: {e}")
            return False
    
    async def extend_session(self, session_id: str, additional_seconds: int = None) -> bool:
        """Extend session TTL"""
        try:
            additional_ttl = additional_seconds or self.config.ttl_seconds
            session_key = self._make_session_key(session_id)
            
            result = await self.redis.expire(session_key, additional_ttl)
            return bool(result)
            
        except Exception as e:
            print(f"Error extending session: {e}")
            return False
    
    async def get_session_stats(self) -> Dict[str, Any]:
        """Get overall session statistics"""
        try:
            # Get all session keys
            session_keys = []
            async for key in self.redis.scan_iter(match=f"{self.key_prefix}*"):
                if not key.decode().endswith(":sessions"):
                    session_keys.append(key.decode())
            
            active_sessions = len(session_keys)
            
            # Sample a few sessions for detailed stats
            sample_size = min(10, active_sessions)
            total_messages = 0
            
            if session_keys:
                sample_keys = session_keys[:sample_size]
                for key in sample_keys:
                    try:
                        data = await self.redis.get(key)
                        if data:
                            session = json.loads(data)
                            total_messages += session.get("message_count", 0)
                    except Exception:
                        continue
            
            return {
                "active_sessions": active_sessions,
                "avg_messages_per_session": total_messages / sample_size if sample_size > 0 else 0,
                "sample_size": sample_size,
                "redis_memory": await self._get_redis_memory_usage()
            }
            
        except Exception as e:
            print(f"Error getting session stats: {e}")
            return {}
    
    async def _get_redis_memory_usage(self) -> Dict[str, Any]:
        """Get Redis memory usage information"""
        try:
            info = await self.redis.info("memory")
            return {
                "used_memory": info.get("used_memory", 0),
                "used_memory_human": info.get("used_memory_human", "0B"),
                "used_memory_peak": info.get("used_memory_peak", 0)
            }
        except Exception:
            return {}
    
    async def _periodic_cleanup(self):
        """Periodic cleanup of expired sessions"""
        while True:
            try:
                await asyncio.sleep(self.config.cleanup_interval)
                
                # Cleanup orphaned user session references
                user_session_keys = []
                async for key in self.redis.scan_iter(match=f"{self.key_prefix}user:*:sessions"):
                    user_session_keys.append(key.decode())
                
                for key in user_session_keys:
                    try:
                        session_ids = await self.redis.smembers(key)
                        valid_session_ids = []
                        
                        for session_id in session_ids:
                            session_key = self._make_session_key(session_id.decode() if isinstance(session_id, bytes) else session_id)
                            if await self.redis.exists(session_key):
                                valid_session_ids.append(session_id)
                        
                        # Update the set with only valid session IDs
                        if len(valid_session_ids) != len(session_ids):
                            await self.redis.delete(key)
                            if valid_session_ids:
                                await self.redis.sadd(key, *valid_session_ids)
                                await self.redis.expire(key, self.config.ttl_seconds)
                        
                    except Exception as e:
                        print(f"Error cleaning up user sessions {key}: {e}")
                
            except Exception as e:
                print(f"Error in periodic cleanup: {e}")

# Integration with LLM chat
class SessionAwareLLMChat:
    def __init__(
        self,
        session_manager: RedisSessionManager,
        llm_client,
        default_model: str = "llama-2-7b-chat"
    ):
        self.session_manager = session_manager
        self.llm_client = llm_client
        self.default_model = default_model
    
    async def chat(
        self,
        session_id: str,
        message: str,
        model: Optional[str] = None,
        max_context_messages: int = 20
    ) -> Dict[str, Any]:
        """Chat with session context"""
        try:
            # Add user message to session
            await self.session_manager.add_message(session_id, "user", message)
            
            # Get conversation context
            context_messages = await self.session_manager.get_conversation_context(
                session_id, max_context_messages
            )
            
            if not context_messages:
                return {"error": "Session not found"}
            
            # Generate response
            response = self.llm_client.chat.completions.create(
                model=model or self.default_model,
                messages=context_messages,
                temperature=0.7,
                max_tokens=500
            )
            
            assistant_response = response.choices[0].message.content
            
            # Add assistant response to session
            await self.session_manager.add_message(
                session_id, 
                "assistant", 
                assistant_response,
                {
                    "model": model or self.default_model,
                    "usage": dict(response.usage) if response.usage else {}
                }
            )
            
            return {
                "response": assistant_response,
                "session_id": session_id,
                "message_count": len(context_messages) + 1
            }
            
        except Exception as e:
            return {"error": str(e)}

# Usage example
async def demo_session_management():
    # Initialize session manager
    session_config = SessionConfig(
        max_messages=30,
        ttl_seconds=1800,  # 30 minutes
        cleanup_interval=300
    )
    
    session_manager = RedisSessionManager(config=session_config)
    
    # Create a session
    user_id = "user_123"
    session_id = await session_manager.create_session(
        user_id,
        initial_context={
            "system_prompt": "You are a helpful coding assistant.",
            "user_preferences": {"language": "python"}
        }
    )
    
    print(f"Created session: {session_id}")
    
    # Simulate conversation
    messages = [
        "Hello, I need help with Python",
        "Can you show me how to create a class?",
        "What about inheritance?"
    ]
    
    for msg in messages:
        await session_manager.add_message(session_id, "user", msg)
        await session_manager.add_message(session_id, "assistant", f"Response to: {msg}")
    
    # Get conversation context
    context = await session_manager.get_conversation_context(session_id)
    print(f"Context messages: {len(context)}")
    
    # Get session stats
    stats = await session_manager.get_session_stats()
    print(f"Session stats: {stats}")
    
    # Cleanup
    await session_manager.delete_session(session_id)
    print("Session deleted")

if __name__ == "__main__":
    asyncio.run(demo_session_management())
```

This comprehensive Database Integration section covers vector databases (Pinecone, ChromaDB), document stores (MongoDB), and session management (Redis). Each component includes production-ready code with proper error handling, performance optimizations, and real-world usage patterns.

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
