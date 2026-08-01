---
title: "Framework Integration"
description: "LangChain, LlamaIndex, Haystack, and other orchestration frameworks"
author: "Joseph Streeter"
tags: ["local llms", "integration", "langchain", "llamaindex", "haystack", "rag"]
category: "ai"
last_updated: "2026-08-01"
---
## Framework Integration

Integration with popular AI and machine learning frameworks for enhanced functionality and workflow orchestration.

### LangChain

LangChain is a powerful framework for developing applications with language models, providing chains, agents, and memory capabilities.

**Setting up LangChain with Local LLMs:**

```python
# langchain_integration.py - LangChain with local LLM
from langchain.llms.base import LLM
from langchain.callbacks.manager import CallbackManagerForLLMRun
from langchain.chains import LLMChain, ConversationChain
from langchain.agents import initialize_agent, Tool, AgentType
from langchain.memory import ConversationBufferMemory, ConversationSummaryMemory
from langchain.prompts import PromptTemplate
from langchain.schema import Generation, LLMResult
from typing import Optional, List, Any, Dict
import requests
import json

class LocalLLM(LLM):
    """Custom LangChain LLM wrapper for local APIs"""
    
    base_url: str = "http://localhost:8080"
    model_name: str = "llama-2-7b-chat"
    temperature: float = 0.7
    max_tokens: int = 150
    api_key: Optional[str] = None
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
    
    @property
    def _llm_type(self) -> str:
        return "local_llm"
    
    def _call(
        self,
        prompt: str,
        stop: Optional[List[str]] = None,
        run_manager: Optional[CallbackManagerForLLMRun] = None,
        **kwargs: Any,
    ) -> str:
        """Call the local LLM API"""
        headers = {"Content-Type": "application/json"}
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"
        
        payload = {
            "model": self.model_name,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": self.temperature,
            "max_tokens": self.max_tokens,
            "stream": False
        }
        
        if stop:
            payload["stop"] = stop
        
        try:
            response = requests.post(
                f"{self.base_url}/v1/chat/completions",
                headers=headers,
                json=payload,
                timeout=120
            )
            response.raise_for_status()
            
            result = response.json()
            return result["choices"][0]["message"]["content"]
        except Exception as e:
            return f"Error: {str(e)}"
    
    def _generate(
        self,
        prompts: List[str],
        stop: Optional[List[str]] = None,
        run_manager: Optional[CallbackManagerForLLMRun] = None,
        **kwargs: Any,
    ) -> LLMResult:
        """Generate responses for multiple prompts"""
        generations = []
        for prompt in prompts:
            text = self._call(prompt, stop, run_manager, **kwargs)
            generations.append([Generation(text=text)])
        
        return LLMResult(generations=generations)

# Initialize the local LLM
local_llm = LocalLLM(
    base_url="http://localhost:8080",
    model_name="llama-2-7b-chat",
    temperature=0.7,
    max_tokens=200
)

# Basic chain example
from langchain.chains import LLMChain
from langchain.prompts import PromptTemplate

template = """
You are a helpful AI assistant. Answer the following question thoughtfully and accurately.

Question: {question}
Answer:"""

prompt = PromptTemplate(template=template, input_variables=["question"])
chain = LLMChain(llm=local_llm, prompt=prompt)

# Run the chain
response = chain.run(question="What are the benefits of renewable energy?")
print(f"Response: {response}")

# Conversation chain with memory
conversation_memory = ConversationBufferMemory()
conversation_chain = ConversationChain(
    llm=local_llm,
    memory=conversation_memory,
    verbose=True
)

# Interactive conversation
print("Starting conversation (type 'quit' to exit):")
while True:
    user_input = input("You: ")
    if user_input.lower() == 'quit':
        break
    
    response = conversation_chain.predict(input=user_input)
    print(f"AI: {response}")

# Custom tools for agents
def search_tool(query: str) -> str:
    """Mock search tool - replace with actual search implementation"""
    return f"Search results for '{query}': This is mock search data."

def calculator_tool(expression: str) -> str:
    """Simple calculator tool"""
    try:
        result = eval(expression)  # Note: Use safe eval in production
        return str(result)
    except Exception as e:
        return f"Error calculating {expression}: {str(e)}"

# Define tools for the agent
tools = [
    Tool(
        name="Search",
        func=search_tool,
        description="Search for information on the internet. Input should be a search query."
    ),
    Tool(
        name="Calculator", 
        func=calculator_tool,
        description="Perform mathematical calculations. Input should be a mathematical expression."
    )
]

# Initialize agent
agent = initialize_agent(
    tools=tools,
    llm=local_llm,
    agent=AgentType.ZERO_SHOT_REACT_DESCRIPTION,
    verbose=True,
    max_iterations=3
)

# Run agent
agent_response = agent.run("What is 25 * 17, and then search for information about that number")
print(f"Agent response: {agent_response}")
```

**Advanced LangChain Patterns:**

```python
# advanced_langchain.py - Complex chains and workflows
from langchain.chains import SequentialChain, TransformChain
from langchain.chains.router import MultiPromptChain, MultiRetrievalQAChain
from langchain.chains.router.llm_router import LLMRouterChain, RouterOutputParser
from langchain.vectorstores import Chroma
from langchain.embeddings import HuggingFaceEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.document_loaders import TextLoader
from langchain.chains import RetrievalQA

# Document processing pipeline
class DocumentProcessor:
    def __init__(self, local_llm):
        self.llm = local_llm
        self.embeddings = HuggingFaceEmbeddings(
            model_name="sentence-transformers/all-MiniLM-L6-v2"
        )
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200
        )
    
    def process_documents(self, file_paths: List[str]) -> Chroma:
        """Load, split, and embed documents"""
        documents = []
        for file_path in file_paths:
            loader = TextLoader(file_path)
            docs = loader.load()
            documents.extend(docs)
        
        # Split documents
        texts = self.text_splitter.split_documents(documents)
        
        # Create vector store
        vectorstore = Chroma.from_documents(
            documents=texts,
            embedding=self.embeddings,
            persist_directory="./chroma_db"
        )
        
        return vectorstore
    
    def create_qa_chain(self, vectorstore: Chroma):
        """Create Q&A chain with retrieval"""
        return RetrievalQA.from_chain_type(
            llm=self.llm,
            chain_type="stuff",
            retriever=vectorstore.as_retriever(search_kwargs={"k": 4}),
            return_source_documents=True
        )

# Multi-step processing chain
def create_analysis_pipeline(local_llm):
    # Step 1: Summarization
    summarize_template = """
    Summarize the following text in 2-3 sentences:
    
    Text: {text}
    Summary:"""
    
    summarize_prompt = PromptTemplate(
        template=summarize_template,
        input_variables=["text"]
    )
    summarize_chain = LLMChain(
        llm=local_llm,
        prompt=summarize_prompt,
        output_key="summary"
    )
    
    # Step 2: Sentiment analysis
    sentiment_template = """
    Analyze the sentiment of the following text. Respond with only: POSITIVE, NEGATIVE, or NEUTRAL
    
    Text: {summary}
    Sentiment:"""
    
    sentiment_prompt = PromptTemplate(
        template=sentiment_template,
        input_variables=["summary"]
    )
    sentiment_chain = LLMChain(
        llm=local_llm,
        prompt=sentiment_prompt,
        output_key="sentiment"
    )
    
    # Step 3: Generate recommendations
    recommendations_template = """
    Based on the summary and sentiment, provide 3 actionable recommendations:
    
    Summary: {summary}
    Sentiment: {sentiment}
    
    Recommendations:"""
    
    recommendations_prompt = PromptTemplate(
        template=recommendations_template,
        input_variables=["summary", "sentiment"]
    )
    recommendations_chain = LLMChain(
        llm=local_llm,
        prompt=recommendations_prompt,
        output_key="recommendations"
    )
    
    # Combine into sequential chain
    overall_chain = SequentialChain(
        chains=[summarize_chain, sentiment_chain, recommendations_chain],
        input_variables=["text"],
        output_variables=["summary", "sentiment", "recommendations"],
        verbose=True
    )
    
    return overall_chain

# Router chain for different types of queries
def create_router_chain(local_llm):
    # Define specialized chains for different domains
    code_template = """
    You are an expert programmer. Answer this coding question:
    
    Question: {input}
    Answer:"""
    
    science_template = """
    You are a science expert. Explain this scientific concept clearly:
    
    Question: {input}
    Answer:"""
    
    general_template = """
    You are a helpful assistant. Answer this general question:
    
    Question: {input}
    Answer:"""
    
    # Create prompt infos
    prompt_infos = [
        {
            "name": "coding",
            "description": "Good for answering programming and technical questions",
            "prompt_template": code_template
        },
        {
            "name": "science", 
            "description": "Good for answering scientific questions",
            "prompt_template": science_template
        },
        {
            "name": "general",
            "description": "Good for general questions and conversations",
            "prompt_template": general_template
        }
    ]
    
    # Create destination chains
    destination_chains = {}
    for p_info in prompt_infos:
        name = p_info["name"]
        prompt_template = p_info["prompt_template"]
        prompt = PromptTemplate(template=prompt_template, input_variables=["input"])
        chain = LLMChain(llm=local_llm, prompt=prompt)
        destination_chains[name] = chain
    
    # Create router chain
    destinations = [f"{p['name']}: {p['description']}" for p in prompt_infos]
    destinations_str = "\n".join(destinations)
    
    router_template = f"""Given a raw text input to a language model select the model prompt best suited for the input. You will be given the names of the available prompts and a description of what the prompt is best suited for.

<< FORMATTING >>
Return a markdown code block with a JSON object formatted to look like:
```json
{{{{
    "destination": string \\ name of the prompt to use or "DEFAULT"
    "next_inputs": string \\ a potentially modified version of the original input
}}}}
```

    REMEMBER: "destination" MUST be one of the candidate prompt names specified below OR it can be "DEFAULT" if the input is not well suited for any of the candidate prompts.
    REMEMBER: "next_inputs" can just be the original input if you don't think any modifications are needed.

    << CANDIDATE PROMPTS >>
    {destinations_str}

    << INPUT >>
    {{input}}

    << OUTPUT >>"""

    router_prompt = PromptTemplate(
        template=router_template,
        input_variables=["input"],
    )
    
    router_chain = LLMRouterChain.from_llm(local_llm, router_prompt)
    
    return MultiPromptChain(
        router_chain=router_chain,
        destination_chains=destination_chains,
        default_chain=destination_chains["general"],
        verbose=True
    )

# Usage examples

if __name__ == "__main__":
    local_llm = LocalLLM()
    
    # Document processing
    processor = DocumentProcessor(local_llm)
    # vectorstore = processor.process_documents(["document1.txt", "document2.txt"])
    # qa_chain = processor.create_qa_chain(vectorstore)
    
    # Analysis pipeline
    analysis_chain = create_analysis_pipeline(local_llm)
    sample_text = "The new product launch was successful beyond expectations..."
    result = analysis_chain({"text": sample_text})
    print("Analysis Result:", result)
    
    # Router chain
    router = create_router_chain(local_llm)
    coding_response = router.run("How do I sort a list in Python?")
    science_response = router.run("Explain photosynthesis")
    general_response = router.run("What's the weather like today?")
```

### LlamaIndex

LlamaIndex (formerly GPT Index) specializes in connecting LLMs with external data sources and building retrieval-augmented generation (RAG) applications.

**Basic LlamaIndex Setup:**

```python
# llamaindex_integration.py - LlamaIndex with local LLMs
from llama_index.core import VectorStoreIndex, Document, Settings
from llama_index.core.node_parser import SentenceSplitter
from llama_index.core.query_engine import RetrieverQueryEngine
from llama_index.core.retrievers import VectorIndexRetriever
from llama_index.core.postprocessor import SimilarityPostprocessor
from llama_index.embeddings.huggingface import HuggingFaceEmbedding
from llama_index.llms.openai_like import OpenAILike
from llama_index.core.callbacks import CallbackManager, LlamaDebugHandler
from typing import List, Optional
import os

class LocalLlamaIndexSetup:
    def __init__(self, base_url: str = "http://localhost:8080", model: str = "llama-2-7b-chat"):
        # Configure local LLM
        self.llm = OpenAILike(
            model=model,
            api_base=f"{base_url}/v1",
            api_key="not-needed",
            is_chat_model=True,
            context_window=4096,
            max_tokens=512,
            temperature=0.7
        )
        
        # Configure embeddings (local)
        self.embed_model = HuggingFaceEmbedding(
            model_name="sentence-transformers/all-MiniLM-L6-v2",
            device="cpu"  # Use "cuda" if available
        )
        
        # Configure global settings
        Settings.llm = self.llm
        Settings.embed_model = self.embed_model
        Settings.node_parser = SentenceSplitter(chunk_size=1024, chunk_overlap=20)
        
        # Set up debugging
        self.debug_handler = LlamaDebugHandler(print_trace_on_end=True)
        Settings.callback_manager = CallbackManager([self.debug_handler])
    
    def create_index_from_documents(self, documents: List[Document]) -> VectorStoreIndex:
        """Create vector index from documents"""
        index = VectorStoreIndex.from_documents(
            documents,
            show_progress=True
        )
        return index
    
    def create_index_from_text_files(self, file_paths: List[str]) -> VectorStoreIndex:
        """Create index from text files"""
        documents = []
        for file_path in file_paths:
            with open(file_path, 'r', encoding='utf-8') as file:
                text = file.read()
                doc = Document(
                    text=text,
                    metadata={"source": file_path, "filename": os.path.basename(file_path)}
                )
                documents.append(doc)
        
        return self.create_index_from_documents(documents)
    
    def create_query_engine(self, index: VectorStoreIndex, similarity_top_k: int = 5):
        """Create query engine with custom retriever"""
        retriever = VectorIndexRetriever(
            index=index,
            similarity_top_k=similarity_top_k
        )
        
        # Add post-processors
        postprocessor = SimilarityPostprocessor(similarity_cutoff=0.7)
        
        query_engine = RetrieverQueryEngine(
            retriever=retriever,
            node_postprocessors=[postprocessor]
        )
        
        return query_engine

# Usage examples
def demonstrate_basic_usage():
    """Basic LlamaIndex usage with local LLM"""
    # Initialize setup
    setup = LocalLlamaIndexSetup("http://localhost:8080", "llama-2-7b-chat")
    
    # Create sample documents
    documents = [
        Document(text="Climate change is affecting global weather patterns, leading to more extreme events.", metadata={"topic": "climate"}),
        Document(text="Renewable energy sources like solar and wind are becoming more cost-effective.", metadata={"topic": "energy"}),
        Document(text="Machine learning algorithms can help predict and mitigate climate impacts.", metadata={"topic": "technology"}),
        Document(text="Electric vehicles are reducing transportation emissions significantly.", metadata={"topic": "transportation"})
    ]
    
    # Create index
    print("Creating vector index...")
    index = setup.create_index_from_documents(documents)
    
    # Create query engine
    query_engine = setup.create_query_engine(index, similarity_top_k=3)
    
    # Run queries
    queries = [
        "How is climate change affecting weather?",
        "What are the benefits of renewable energy?",
        "How can technology help with climate issues?",
        "Tell me about electric vehicles and emissions"
    ]
    
    for query in queries:
        print(f"\nQuery: {query}")
        response = query_engine.query(query)
        print(f"Response: {response}")
        print(f"Sources: {[node.metadata for node in response.source_nodes]}")

# Advanced RAG with custom retrievers and reranking
from llama_index.core.schema import NodeWithScore
from llama_index.core.retrievers import BaseRetriever
from llama_index.core import QueryBundle
import torch
from sentence_transformers import CrossEncoder

class HybridRetriever(BaseRetriever):
    """Custom retriever combining vector similarity and keyword search"""
    
    def __init__(self, vector_retriever, bm25_retriever=None, alpha: float = 0.7):
        self.vector_retriever = vector_retriever
        self.bm25_retriever = bm25_retriever
        self.alpha = alpha
        super().__init__()
    
    def _retrieve(self, query_bundle: QueryBundle) -> List[NodeWithScore]:
        """Retrieve using hybrid approach"""
        # Get vector similarity results
        vector_nodes = self.vector_retriever.retrieve(query_bundle)
        
        # If BM25 retriever is available, combine results
        if self.bm25_retriever:
            bm25_nodes = self.bm25_retriever.retrieve(query_bundle)
            
            # Combine and rerank
            all_nodes = {}
            
            # Add vector results with weight
            for node in vector_nodes:
                node_id = node.node.node_id
                all_nodes[node_id] = NodeWithScore(
                    node=node.node,
                    score=self.alpha * node.score
                )
            
            # Add BM25 results with weight
            for node in bm25_nodes:
                node_id = node.node.node_id
                if node_id in all_nodes:
                    all_nodes[node_id].score += (1 - self.alpha) * node.score
                else:
                    all_nodes[node_id] = NodeWithScore(
                        node=node.node,
                        score=(1 - self.alpha) * node.score
                    )
            
            # Sort by combined score
            combined_nodes = sorted(
                all_nodes.values(),
                key=lambda x: x.score,
                reverse=True
            )
            
            return combined_nodes[:10]  # Return top 10
        
        return vector_nodes

class RerankerPostProcessor:
    """Rerank retrieved nodes using cross-encoder model"""
    
    def __init__(self, model_name: str = "cross-encoder/ms-marco-MiniLM-L-6-v2"):
        self.cross_encoder = CrossEncoder(model_name)
    
    def postprocess_nodes(self, nodes: List[NodeWithScore], query_str: str) -> List[NodeWithScore]:
        """Rerank nodes using cross-encoder"""
        if not nodes:
            return nodes
        
        # Prepare pairs for cross-encoder
        pairs = [(query_str, node.node.text) for node in nodes]
        
        # Get similarity scores
        scores = self.cross_encoder.predict(pairs)
        
        # Update node scores
        for i, node in enumerate(nodes):
            node.score = float(scores[i])
        
        # Sort by new scores
        reranked_nodes = sorted(nodes, key=lambda x: x.score, reverse=True)
        
        return reranked_nodes

# Advanced query engine with custom components
def create_advanced_rag_system():
    """Create advanced RAG system with reranking"""
    setup = LocalLlamaIndexSetup()
    
    # Load documents (example with multiple sources)
    documents = [
        Document(text="Solar panels convert sunlight directly into electricity using photovoltaic cells.", metadata={"source": "renewable_energy.txt", "category": "solar"}),
        Document(text="Wind turbines harness kinetic energy from moving air to generate electricity.", metadata={"source": "renewable_energy.txt", "category": "wind"}),
        Document(text="Hydroelectric power uses flowing water to turn turbines and generate electricity.", metadata={"source": "renewable_energy.txt", "category": "hydro"}),
        Document(text="Battery storage systems help stabilize renewable energy output by storing excess power.", metadata={"source": "energy_storage.txt", "category": "storage"}),
        Document(text="Smart grids use digital technology to manage electricity distribution efficiently.", metadata={"source": "smart_grid.txt", "category": "grid"}),
    ]
    
    # Create index
    index = setup.create_index_from_documents(documents)
    
    # Create hybrid retriever
    vector_retriever = VectorIndexRetriever(index=index, similarity_top_k=8)
    hybrid_retriever = HybridRetriever(vector_retriever, alpha=0.8)
    
    # Create reranker
    reranker = RerankerPostProcessor()
    
    # Custom query engine with reranking
    query_engine = RetrieverQueryEngine(
        retriever=hybrid_retriever,
        node_postprocessors=[
            lambda nodes, query: reranker.postprocess_nodes(nodes, query.query_str)
        ]
    )
    
    return query_engine, index

# Multi-document chat engine
from llama_index.core.chat_engine import CondensePlusContextChatEngine
from llama_index.core.memory import ChatMemoryBuffer

def create_chat_engine():
    """Create conversational RAG system"""
    setup = LocalLlamaIndexSetup()
    
    # Create index (example with technical documentation)
    documents = [
        Document(text="API authentication requires a valid API key in the Authorization header.", metadata={"doc": "api_guide"}),
        Document(text="Rate limiting is enforced at 1000 requests per hour per API key.", metadata={"doc": "api_guide"}),
        Document(text="WebSocket connections provide real-time streaming of model responses.", metadata={"doc": "api_guide"}),
        Document(text="Model parameters include temperature, max_tokens, and stop sequences.", metadata={"doc": "model_config"}),
        Document(text="Error handling should include retry logic with exponential backoff.", metadata={"doc": "best_practices"}),
    ]
    
    index = setup.create_index_from_documents(documents)
    
    # Create chat engine with memory
    memory = ChatMemoryBuffer.from_defaults(token_limit=3000)
    
    chat_engine = CondensePlusContextChatEngine.from_defaults(
        index.as_retriever(similarity_top_k=3),
        memory=memory,
        system_prompt=(
            "You are a helpful assistant that answers questions based on the provided documentation. "
            "Always cite the source of your information and ask follow-up questions when appropriate."
        ),
        verbose=True
    )
    
    return chat_engine

# Usage demonstration
if __name__ == "__main__":
    # Basic demonstration
    print("=== Basic LlamaIndex Demo ===")
    demonstrate_basic_usage()
    
    # Advanced RAG
    print("\n=== Advanced RAG Demo ===")
    query_engine, index = create_advanced_rag_system()
    
    response = query_engine.query("How do solar panels and wind turbines work together in renewable energy systems?")
    print(f"Advanced RAG Response: {response}")
    
    # Chat engine demo
    print("\n=== Chat Engine Demo ===")
    chat_engine = create_chat_engine()
    
    # Simulate conversation
    response1 = chat_engine.chat("How do I authenticate API requests?")
    print(f"Chat 1: {response1}")
    
    response2 = chat_engine.chat("What about rate limiting?")
    print(f"Chat 2: {response2}")
    
    response3 = chat_engine.chat("Can you give me a complete example of making an authenticated request with error handling?")
    print(f"Chat 3: {response3}")
```

## Haystack

Haystack is an end-to-end NLP framework for building production-ready search systems and question-answering applications.

**Haystack Integration:**

```python
# haystack_integration.py - Haystack with local LLMs
from haystack import Pipeline
from haystack.components.generators import OpenAIGenerator
from haystack.components.builders import PromptBuilder
from haystack.components.retrievers import InMemoryBM25Retriever
from haystack.components.embedders import SentenceTransformersTextEmbedder, SentenceTransformersDocumentEmbedder
from haystack.components.retrievers import InMemoryEmbeddingRetriever
from haystack.components.joiners import DocumentJoiner
from haystack.components.rankers import TransformersSimilarityRanker
from haystack.document_stores import InMemoryDocumentStore
from haystack.dataclasses import Document
from haystack.utils import ComponentConfig
from typing import List, Dict, Any
import os

class LocalHaystackLLM:
    """Haystack wrapper for local LLM APIs"""
    
    def __init__(self, base_url: str = "http://localhost:8080", model: str = "llama-2-7b-chat"):
        # Configure OpenAI-compatible generator for local LLM
        self.generator = OpenAIGenerator(
            api_key="not-needed",
            model=model,
            api_base_url=f"{base_url}/v1",
            generation_kwargs={
                "temperature": 0.7,
                "max_tokens": 512
            }
        )
        
        # Set up document store
        self.document_store = InMemoryDocumentStore()
        
        # Set up embedders
        self.text_embedder = SentenceTransformersTextEmbedder(
            model="sentence-transformers/all-MiniLM-L6-v2"
        )
        self.doc_embedder = SentenceTransformersDocumentEmbedder(
            model="sentence-transformers/all-MiniLM-L6-v2"
        )
    
    def create_rag_pipeline(self) -> Pipeline:
        """Create Retrieval-Augmented Generation pipeline"""
        
        # Template for RAG
        template = """
        Answer the question based on the provided context. If you cannot answer based on the context, say so.
        
        Context:
        {% for document in documents %}
        {{ document.content }}
        {% endfor %}
        
        Question: {{ question }}
        Answer:
        """
        
        # Build pipeline
        rag_pipeline = Pipeline()
        
        # Add components
        rag_pipeline.add_component("embedder", self.text_embedder)
        rag_pipeline.add_component("retriever", InMemoryEmbeddingRetriever(document_store=self.document_store))
        rag_pipeline.add_component("prompt_builder", PromptBuilder(template=template))
        rag_pipeline.add_component("llm", self.generator)
        
        # Connect components
        rag_pipeline.connect("embedder.embedding", "retriever.query_embedding")
        rag_pipeline.connect("retriever", "prompt_builder.documents")
        rag_pipeline.connect("prompt_builder", "llm")
        
        return rag_pipeline
    
    def create_hybrid_retrieval_pipeline(self) -> Pipeline:
        """Create hybrid retrieval pipeline combining BM25 and embeddings"""
        
        template = """
        Based on the following documents, provide a comprehensive answer to the question.
        
        Documents:
        {% for document in documents %}
        Document {{ loop.index }}:
        {{ document.content }}
        Source: {{ document.meta.get("source", "Unknown") }}
        
        {% endfor %}
        
        Question: {{ question }}
        
        Please provide a detailed answer and cite the relevant sources.
        Answer:
        """
        
        pipeline = Pipeline()
        
        # Add retrieval components
        pipeline.add_component("text_embedder", self.text_embedder)
        pipeline.add_component("embedding_retriever", InMemoryEmbeddingRetriever(document_store=self.document_store))
        pipeline.add_component("bm25_retriever", InMemoryBM25Retriever(document_store=self.document_store))
        
        # Add document processing
        pipeline.add_component("document_joiner", DocumentJoiner())
        pipeline.add_component("ranker", TransformersSimilarityRanker(model="cross-encoder/ms-marco-MiniLM-L-6-v2"))
        
        # Add generation
        pipeline.add_component("prompt_builder", PromptBuilder(template=template))
        pipeline.add_component("llm", self.generator)
        
        # Connect embedding path
        pipeline.connect("text_embedder.embedding", "embedding_retriever.query_embedding")
        
        # Connect BM25 path  
        pipeline.connect("bm25_retriever", "document_joiner.documents")
        pipeline.connect("embedding_retriever", "document_joiner.documents")
        
        # Connect reranking and generation
        pipeline.connect("document_joiner", "ranker.documents")
        pipeline.connect("ranker", "prompt_builder.documents")
        pipeline.connect("prompt_builder", "llm")
        
        return pipeline
    
    def index_documents(self, documents: List[Document]) -> None:
        """Index documents in the document store"""
        # Embed documents
        embedded_docs = self.doc_embedder.run(documents=documents)
        
        # Write to document store
        self.document_store.write_documents(embedded_docs["documents"])
        print(f"Indexed {len(documents)} documents")
    
    def create_chat_pipeline(self) -> Pipeline:
        """Create conversational pipeline with memory"""
        
        chat_template = """
        You are a helpful AI assistant. Use the provided context to answer questions accurately.
        
        Context:
        {% for document in documents %}
        {{ document.content }}
        {% endfor %}
        
        Conversation History:
        {{ chat_history }}
        
        Current Question: {{ question }}
        
        Provide a helpful and accurate response based on the context and conversation history.
        Answer:
        """
        
        pipeline = Pipeline()
        
        # Add components for chat
        pipeline.add_component("embedder", self.text_embedder)
        pipeline.add_component("retriever", InMemoryEmbeddingRetriever(document_store=self.document_store, top_k=5))
        pipeline.add_component("prompt_builder", PromptBuilder(template=chat_template))
        pipeline.add_component("llm", self.generator)
        
        # Connect components
        pipeline.connect("embedder.embedding", "retriever.query_embedding")
        pipeline.connect("retriever", "prompt_builder.documents")
        pipeline.connect("prompt_builder", "llm")
        
        return pipeline

# Specialized pipelines for different use cases
class SpecializedPipelines:
    """Collection of specialized Haystack pipelines"""
    
    def __init__(self, haystack_llm: LocalHaystackLLM):
        self.haystack_llm = haystack_llm
    
    def create_summarization_pipeline(self) -> Pipeline:
        """Create document summarization pipeline"""
        
        summary_template = """
        Please provide a concise summary of the following documents:
        
        {% for document in documents %}
        Document {{ loop.index }}:
        {{ document.content }}
        
        {% endfor %}
        
        Summary should be:
        - Comprehensive yet concise
        - Highlighting key points
        - Maximum 200 words
        
        Summary:
        """
        
        pipeline = Pipeline()
        pipeline.add_component("prompt_builder", PromptBuilder(template=summary_template))
        pipeline.add_component("llm", self.haystack_llm.generator)
        pipeline.connect("prompt_builder", "llm")
        
        return pipeline
    
    def create_classification_pipeline(self) -> Pipeline:
        """Create document classification pipeline"""
        
        classification_template = """
        Classify the following document into one of these categories:
        - Technology
        - Science
        - Business
        - Health
        - Education
        - Other
        
        Document: {{ document }}
        
        Provide only the category name as your response.
        Category:
        """
        
        pipeline = Pipeline()
        pipeline.add_component("prompt_builder", PromptBuilder(template=classification_template))
        pipeline.add_component("llm", self.haystack_llm.generator)
        pipeline.connect("prompt_builder", "llm")
        
        return pipeline
    
    def create_fact_checking_pipeline(self) -> Pipeline:
        """Create fact-checking pipeline"""
        
        fact_check_template = """
        Based on the provided reference documents, verify the following claim:
        
        Claim: {{ claim }}
        
        Reference Documents:
        {% for document in documents %}
        {{ document.content }}
        {% endfor %}
        
        Please respond with:
        1. SUPPORTED, CONTRADICTED, or NOT ENOUGH INFO
        2. Brief explanation with specific references
        
        Verification:
        """
        
        pipeline = Pipeline()
        pipeline.add_component("embedder", self.haystack_llm.text_embedder)
        pipeline.add_component("retriever", InMemoryEmbeddingRetriever(document_store=self.haystack_llm.document_store))
        pipeline.add_component("prompt_builder", PromptBuilder(template=fact_check_template))
        pipeline.add_component("llm", self.haystack_llm.generator)
        
        pipeline.connect("embedder.embedding", "retriever.query_embedding")
        pipeline.connect("retriever", "prompt_builder.documents")
        pipeline.connect("prompt_builder", "llm")
        
        return pipeline

# Usage examples and demonstrations
def demonstrate_haystack_integration():
    """Demonstrate Haystack integration with local LLM"""
    
    # Initialize Haystack LLM
    haystack_llm = LocalHaystackLLM("http://localhost:8080", "llama-2-7b-chat")
    
    # Create sample documents
    documents = [
        Document(
            content="Renewable energy sources like solar and wind are becoming increasingly cost-effective and efficient.",
            meta={"source": "energy_report.pdf", "category": "technology"}
        ),
        Document(
            content="Climate change is causing more frequent extreme weather events globally.",
            meta={"source": "climate_study.pdf", "category": "science"}
        ),
        Document(
            content="Electric vehicle adoption is accelerating due to improved battery technology and charging infrastructure.",
            meta={"source": "transport_news.pdf", "category": "technology"}
        ),
        Document(
            content="Machine learning algorithms are helping optimize energy grid management and reduce waste.",
            meta={"source": "ai_energy.pdf", "category": "technology"}
        ),
    ]
    
    # Index documents
    haystack_llm.index_documents(documents)
    
    # Test RAG pipeline
    print("=== Testing RAG Pipeline ===")
    rag_pipeline = haystack_llm.create_rag_pipeline()
    
    result = rag_pipeline.run({
        "embedder": {"text": "How is technology helping with climate and energy issues?"},
        "prompt_builder": {"question": "How is technology helping with climate and energy issues?"}
    })
    
    print("RAG Response:", result["llm"]["replies"][0])
    
    # Test hybrid retrieval
    print("\n=== Testing Hybrid Retrieval ===")
    hybrid_pipeline = haystack_llm.create_hybrid_retrieval_pipeline()
    
    hybrid_result = hybrid_pipeline.run({
        "text_embedder": {"text": "renewable energy efficiency"},
        "bm25_retriever": {"query": "renewable energy efficiency"},
        "ranker": {"query": "renewable energy efficiency"},
        "prompt_builder": {"question": "What makes renewable energy more efficient?"}
    })
    
    print("Hybrid Response:", hybrid_result["llm"]["replies"][0])
    
    # Test specialized pipelines
    specialized = SpecializedPipelines(haystack_llm)
    
    # Summarization
    print("\n=== Testing Summarization ===")
    summary_pipeline = specialized.create_summarization_pipeline()
    
    summary_result = summary_pipeline.run({
        "prompt_builder": {"documents": documents}
    })
    
    print("Summary:", summary_result["llm"]["replies"][0])
    
    # Classification
    print("\n=== Testing Classification ===")
    classification_pipeline = specialized.create_classification_pipeline()
    
    classification_result = classification_pipeline.run({
        "prompt_builder": {"document": documents[0].content}
    })
    
    print("Classification:", classification_result["llm"]["replies"][0])
    
    # Fact checking
    print("\n=== Testing Fact Checking ===")
    fact_check_pipeline = specialized.create_fact_checking_pipeline()
    
    fact_result = fact_check_pipeline.run({
        "embedder": {"text": "renewable energy is cost-effective"},
        "prompt_builder": {"claim": "Renewable energy sources are now more cost-effective than fossil fuels"}
    })
    
    print("Fact Check:", fact_result["llm"]["replies"][0])

if __name__ == "__main__":
    demonstrate_haystack_integration()
```

### Semantic Kernel

Microsoft Semantic Kernel provides AI orchestration for integrating large language models with traditional programming languages.

**Semantic Kernel Setup:**

```python
# semantic_kernel_integration.py - Semantic Kernel with local LLMs
import semantic_kernel as sk
from semantic_kernel.connectors.ai.open_ai import OpenAIChatCompletion, OpenAITextCompletion
from semantic_kernel.core_plugins import TextPlugin, ConversationSummaryPlugin
from semantic_kernel.template_engine.protocols.prompt_template_engine import PromptTemplateEngine
from semantic_kernel.orchestration.sk_context import SKContext
from semantic_kernel.skill_definition import sk_function, sk_function_context_parameter
from semantic_kernel.core_plugins.text_memory_plugin import TextMemoryPlugin
from semantic_kernel.memory.null_memory import NullMemory
from semantic_kernel.memory.semantic_text_memory import SemanticTextMemory
from semantic_kernel.connectors.memory.chroma import ChromaMemoryStore
import asyncio
from typing import Dict, List, Optional

class LocalSemanticKernel:
    """Semantic Kernel setup for local LLMs"""
    
    def __init__(self, base_url: str = "http://localhost:8080", model: str = "llama-2-7b-chat"):
        self.kernel = sk.Kernel()
        
        # Configure local LLM service
        self.kernel.add_chat_service(
            "local_llm",
            OpenAIChatCompletion(
                ai_model_id=model,
                api_key="not-needed",
                endpoint=f"{base_url}/v1"
            )
        )
        
        # Set default AI service
        self.kernel.set_default_text_completion_service("local_llm")
        
        # Configure memory (optional)
        memory_store = ChromaMemoryStore(persist_directory="./chroma_sk")
        memory = SemanticTextMemory(storage=memory_store, embeddings_generator=None)
        self.kernel.register_memory_store(memory)
        
    async def create_basic_skills(self):
        """Create and register basic skills"""
        
        # Import built-in plugins
        text_plugin = self.kernel.import_plugin(TextPlugin(), "TextPlugin")
        conversation_plugin = self.kernel.import_plugin(ConversationSummaryPlugin(self.kernel), "ConversationSummaryPlugin")
        
        # Create custom skills
        research_skill = self.create_research_skill()
        analysis_skill = self.create_analysis_skill()
        coding_skill = self.create_coding_skill()
        
        # Register custom skills
        self.kernel.import_plugin(research_skill, "ResearchSkill")
        self.kernel.import_plugin(analysis_skill, "AnalysisSkill")
        self.kernel.import_plugin(coding_skill, "CodingSkill")
        
        return {
            "text": text_plugin,
            "conversation": conversation_plugin,
            "research": research_skill,
            "analysis": analysis_skill,
            "coding": coding_skill
        }
    
    def create_research_skill(self):
        """Create custom research skill"""
        
        class ResearchSkill:
            @sk_function(
                description="Generate a comprehensive research outline for a given topic",
                name="create_outline"
            )
            @sk_function_context_parameter(
                name="topic",
                description="The research topic to create an outline for"
            )
            async def create_outline(self, context: SKContext) -> str:
                topic = context.variables.get("topic", "")
                
                prompt = f"""
                Create a detailed research outline for the topic: {topic}
                
                The outline should include:
                1. Introduction and background
                2. Key areas to investigate
                3. Potential sources and methodologies
                4. Expected findings
                5. Conclusion structure
                
                Make it comprehensive and well-organized.
                """
                
                result = await context.kernel.invoke_async(
                    function_name="CompleteChat",
                    plugin_name="local_llm",
                    input=prompt
                )
                
                return str(result)
            
            @sk_function(
                description="Summarize research findings and extract key insights",
                name="summarize_findings"
            )
            @sk_function_context_parameter(
                name="research_data",
                description="The research data to summarize"
            )
            async def summarize_findings(self, context: SKContext) -> str:
                research_data = context.variables.get("research_data", "")
                
                prompt = f"""
                Analyze the following research data and provide:
                1. Key findings (top 5)
                2. Important trends or patterns
                3. Implications and insights
                4. Recommendations for further research
                
                Research Data:
                {research_data}
                """
                
                result = await context.kernel.invoke_async(
                    function_name="CompleteChat",
                    plugin_name="local_llm",
                    input=prompt
                )
                
                return str(result)
        
        return ResearchSkill()
    
    def create_analysis_skill(self):
        """Create data analysis skill"""
        
        class AnalysisSkill:
            @sk_function(
                description="Perform sentiment analysis on text",
                name="sentiment_analysis"
            )
            @sk_function_context_parameter(
                name="text",
                description="The text to analyze for sentiment"
            )
            async def sentiment_analysis(self, context: SKContext) -> str:
                text = context.variables.get("text", "")
                
                prompt = f"""
                Analyze the sentiment of the following text and provide:
                1. Overall sentiment (Positive/Negative/Neutral)
                2. Confidence score (0-1)
                3. Key emotional indicators
                4. Brief explanation
                
                Text: {text}
                
                Format your response as JSON.
                """
                
                result = await context.kernel.invoke_async(
                    function_name="CompleteChat",
                    plugin_name="local_llm",
                    input=prompt
                )
                
                return str(result)
            
            @sk_function(
                description="Extract key topics and themes from text",
                name="topic_extraction"
            )
            @sk_function_context_parameter(
                name="text",
                description="The text to extract topics from"
            )
            async def topic_extraction(self, context: SKContext) -> str:
                text = context.variables.get("text", "")
                
                prompt = f"""
                Extract the main topics and themes from the following text:
                
                {text}
                
                Provide:
                1. Top 5 main topics
                2. Supporting themes for each topic
                3. Relevance score for each (0-1)
                4. Brief description of each topic
                
                Format as structured output.
                """
                
                result = await context.kernel.invoke_async(
                    function_name="CompleteChat",
                    plugin_name="local_llm",
                    input=prompt
                )
                
                return str(result)
        
        return AnalysisSkill()
    
    def create_coding_skill(self):
        """Create programming assistance skill"""
        
        class CodingSkill:
            @sk_function(
                description="Generate code based on requirements",
                name="generate_code"
            )
            @sk_function_context_parameter(
                name="requirements",
                description="The code requirements and specifications"
            )
            @sk_function_context_parameter(
                name="language",
                description="The programming language to use"
            )
            async def generate_code(self, context: SKContext) -> str:
                requirements = context.variables.get("requirements", "")
                language = context.variables.get("language", "python")
                
                prompt = f"""
                Generate {language} code based on the following requirements:
                
                Requirements: {requirements}
                
                Provide:
                1. Complete, working code
                2. Comments explaining key parts
                3. Error handling where appropriate
                4. Usage examples
                5. Any dependencies needed
                """
                
                result = await context.kernel.invoke_async(
                    function_name="CompleteChat",
                    plugin_name="local_llm",
                    input=prompt
                )
                
                return str(result)
            
            @sk_function(
                description="Review code and provide suggestions",
                name="code_review"
            )
            @sk_function_context_parameter(
                name="code",
                description="The code to review"
            )
            async def code_review(self, context: SKContext) -> str:
                code = context.variables.get("code", "")
                
                prompt = f"""
                Review the following code and provide:
                1. Overall code quality assessment
                2. Potential bugs or issues
                3. Performance improvements
                4. Best practice recommendations
                5. Security considerations
                
                Code:
                {code}
                """
                
                result = await context.kernel.invoke_async(
                    function_name="CompleteChat",
                    plugin_name="local_llm",
                    input=prompt
                )
                
                return str(result)
        
        return CodingSkill()
    
    async def create_complex_workflow(self):
        """Create a complex multi-step workflow"""
        
        # Define a multi-step research and analysis workflow
        workflow_template = """
        You are conducting a comprehensive analysis workflow with the following steps:
        
        Step 1: Research Phase
        Topic: {{$topic}}
        
        Step 2: Data Collection
        Sources: {{$sources}}
        
        Step 3: Analysis
        Focus Areas: {{$focus_areas}}
        
        Step 4: Synthesis
        Create a comprehensive report combining all findings.
        
        Execute this workflow systematically and provide detailed output for each step.
        """
        
        workflow_function = self.kernel.create_semantic_function(
            workflow_template,
            function_name="comprehensive_workflow",
            plugin_name="WorkflowPlugin",
            description="Execute a comprehensive research and analysis workflow",
            max_tokens=1000,
            temperature=0.7
        )
        
        return workflow_function
    
    async def create_chained_operations(self):
        """Create chained operations using multiple skills"""
        
        # Chain: Research Outline -> Data Analysis -> Summary -> Recommendations
        chain_template = """
        Execute the following chained analysis:
        
        1. Create research outline for: {{$topic}}
        2. Analyze provided data: {{$data}}
        3. Synthesize findings
        4. Generate actionable recommendations
        
        Provide comprehensive output for each step with clear transitions between phases.
        """
        
        chain_function = self.kernel.create_semantic_function(
            chain_template,
            function_name="analysis_chain",
            plugin_name="ChainPlugin",
            description="Execute chained analysis operations",
            max_tokens=1500,
            temperature=0.6
        )
        
        return chain_function

# Advanced orchestration patterns
class AdvancedOrchestration:
    """Advanced orchestration patterns with Semantic Kernel"""
    
    def __init__(self, kernel_instance: LocalSemanticKernel):
        self.kernel = kernel_instance
    
    async def parallel_processing(self, tasks: List[Dict]) -> List[str]:
        """Execute multiple tasks in parallel"""
        
        async def execute_task(task):
            context = self.kernel.kernel.create_new_context()
            for key, value in task["variables"].items():
                context.variables[key] = value
            
            result = await self.kernel.kernel.run_async(
                context.variables,
                task["skill"],
                task["function"]
            )
            
            return str(result)
        
        # Execute tasks concurrently
        results = await asyncio.gather(
            *[execute_task(task) for task in tasks]
        )
        
        return results
    
    async def conditional_workflow(self, condition_check: str, true_path: Dict, false_path: Dict) -> str:
        """Execute conditional workflow based on condition"""
        
        # Evaluate condition
        condition_template = f"""
        Evaluate the following condition and respond with only 'TRUE' or 'FALSE':
        
        Condition: {condition_check}
        """
        
        condition_result = await self.kernel.kernel.invoke_async(
            function_name="CompleteChat",
            plugin_name="local_llm",
            input=condition_template
        )
        
        # Execute appropriate path
        if "TRUE" in str(condition_result).upper():
            return await self.execute_path(true_path)
        else:
            return await self.execute_path(false_path)
    
    async def execute_path(self, path_config: Dict) -> str:
        """Execute a configured path"""
        context = self.kernel.kernel.create_new_context()
        
        for key, value in path_config.get("variables", {}).items():
            context.variables[key] = value
        
        result = await self.kernel.kernel.run_async(
            context.variables,
            path_config["skill"],
            path_config["function"]
        )
        
        return str(result)
    
    async def iterative_refinement(self, initial_input: str, refinement_steps: int = 3) -> List[str]:
        """Perform iterative refinement of content"""
        
        results = [initial_input]
        current_content = initial_input
        
        for step in range(refinement_steps):
            refinement_template = f"""
            Improve and refine the following content (Step {step + 1}):
            
            Current Content:
            {current_content}
            
            Focus on:
            - Clarity and coherence
            - Factual accuracy
            - Completeness
            - Structure and flow
            
            Provide the refined version:
            """
            
            refined_result = await self.kernel.kernel.invoke_async(
                function_name="CompleteChat",
                plugin_name="local_llm",
                input=refinement_template
            )
            
            current_content = str(refined_result)
            results.append(current_content)
        
        return results

# Usage examples and demonstrations
async def demonstrate_semantic_kernel():
    """Demonstrate Semantic Kernel integration"""
    
    # Initialize Semantic Kernel
    sk_instance = LocalSemanticKernel("http://localhost:8080", "llama-2-7b-chat")
    
    # Create and register skills
    skills = await sk_instance.create_basic_skills()
    print("Registered skills:", list(skills.keys()))
    
    # Test research skill
    print("\n=== Testing Research Skill ===")
    context = sk_instance.kernel.create_new_context()
    context.variables["topic"] = "Impact of artificial intelligence on education"
    
    outline_result = await sk_instance.kernel.run_async(
        context.variables,
        skills["research"],
        "create_outline"
    )
    print("Research Outline:", outline_result)
    
    # Test analysis skill
    print("\n=== Testing Analysis Skill ===")
    context.variables["text"] = "I absolutely love this new technology! It's going to revolutionize how we work and make everything so much more efficient."
    
    sentiment_result = await sk_instance.kernel.run_async(
        context.variables,
        skills["analysis"],
        "sentiment_analysis"
    )
    print("Sentiment Analysis:", sentiment_result)
    
    # Test coding skill
    print("\n=== Testing Coding Skill ===")
    context.variables["requirements"] = "Create a Python function that calculates the Fibonacci sequence up to n terms"
    context.variables["language"] = "python"
    
    code_result = await sk_instance.kernel.run_async(
        context.variables,
        skills["coding"],
        "generate_code"
    )
    print("Generated Code:", code_result)
    
    # Test complex workflow
    print("\n=== Testing Complex Workflow ===")
    workflow_function = await sk_instance.create_complex_workflow()
    
    workflow_context = sk_instance.kernel.create_new_context()
    workflow_context.variables["topic"] = "renewable energy adoption"
    workflow_context.variables["sources"] = "government reports, industry studies, academic papers"
    workflow_context.variables["focus_areas"] = "economic impact, technological barriers, policy implications"
    
    workflow_result = await workflow_function.invoke_async(context=workflow_context)
    print("Workflow Result:", workflow_result)
    
    # Test advanced orchestration
    print("\n=== Testing Advanced Orchestration ===")
    orchestrator = AdvancedOrchestration(sk_instance)
    
    # Parallel processing example
    parallel_tasks = [
        {
            "skill": skills["analysis"],
            "function": "sentiment_analysis",
            "variables": {"text": "This product is amazing and works perfectly!"}
        },
        {
            "skill": skills["analysis"],
            "function": "topic_extraction",
            "variables": {"text": "The conference covered artificial intelligence, machine learning, deep learning, and neural networks."}
        }
    ]
    
    parallel_results = await orchestrator.parallel_processing(parallel_tasks)
    print("Parallel Results:", parallel_results)
    
    # Iterative refinement example
    print("\n=== Testing Iterative Refinement ===")
    initial_content = "AI is good for business. It helps with automation and efficiency."
    
    refined_versions = await orchestrator.iterative_refinement(initial_content, 2)
    for i, version in enumerate(refined_versions):
        print(f"Version {i}: {version[:100]}...")

if __name__ == "__main__":
    asyncio.run(demonstrate_semantic_kernel())
```

This comprehensive Framework Integration section provides detailed implementations for:

1. **LangChain**: Complete integration with custom LLM wrapper, chains, agents, memory, document processing, and advanced patterns
2. **LlamaIndex**: RAG systems, query engines, chat engines, custom retrievers, and reranking
3. **Haystack**: Pipelines for RAG, hybrid retrieval, summarization, classification, and fact-checking
4. **Semantic Kernel**: Skills creation, orchestration, workflows, and advanced patterns

Each framework integration includes production-ready code examples with proper error handling, advanced features, and real-world usage patterns.

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
