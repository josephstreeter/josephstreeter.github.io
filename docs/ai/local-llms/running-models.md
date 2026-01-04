---
title: "Running Local LLM Models"
description: "Practical guide to executing and managing local LLM inference"
author: "Joseph Streeter"
ms.date: "2025-12-31"
ms.topic: "guide"
keywords: ["running models", "inference", "execution", "local llm usage"]
uid: docs.ai.local-llms.running
---

## Overview

Running local Large Language Models (LLMs) involves understanding inference engines, optimization techniques, and resource management strategies. This guide covers practical execution methods, parameter tuning, performance optimization, and production-ready deployment patterns for local LLM inference.

Key aspects of running local LLMs include:

- **Inference engines**: llama.cpp, GGML, vLLM, TensorRT-LLM
- **Parameter optimization**: Temperature, sampling, context management
- **Resource management**: GPU/CPU allocation, memory optimization
- **Integration patterns**: APIs, streaming, batch processing
- **Production considerations**: Error handling, monitoring, scaling

## Basic Execution

### Command Line Interface

The command-line interface provides direct, scriptable access to local LLM inference. Different frameworks offer varying CLI capabilities.

**Ollama CLI**:

```bash
# Run a model interactively
ollama run llama3.2:3b

# Single prompt execution
ollama run llama3.2:3b "Explain quantum computing"

# Pipe input from files
cat prompt.txt | ollama run codellama:13b

# Multi-line prompts
ollama run mistral:7b <<EOF
Analyze this code:
define factorial(n):
    return 1 if n <= 1 else n * factorial(n-1)
EOF
```

**llama.cpp CLI**:

```bash
# Basic inference
./main -m models/llama-2-7b.Q4_K_M.gguf \
  -p "Write a Python function to" \
  -n 256 -c 2048

# Interactive mode
./main -m models/mistral-7b.Q5_K_M.gguf \
  -i --interactive-first \
  --reverse-prompt "User:"

# With GPU acceleration
./main -m models/llama-3-8b.Q5_K_M.gguf \
  -ngl 35 -p "Prompt here"
```

**Key CLI options**:

- `-n, --n-predict`: Maximum tokens to generate
- `-c, --ctx-size`: Context window size
- `-ngl, --n-gpu-layers`: Offload N layers to GPU
- `-t, --threads`: Number of CPU threads
- `--temp`: Temperature parameter
- `--top-p`: Nucleus sampling parameter

### Web Interfaces

Web-based interfaces provide user-friendly access to local LLMs with visual controls and conversation management.

**Ollama Web UI (Open WebUI)**:

```bash
# Install and run
docker run -d -p 3000:8080 \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

Features:

- ChatGPT-style interface
- Model switching
- Conversation history
- Document upload and RAG
- Admin panel

**Text Generation WebUI (oobabooga)**:

```bash
# Clone and setup
git clone https://github.com/oobabooga/text-generation-webui
cd text-generation-webui
./start_linux.sh

# Access at http://localhost:7860
```

Provides:

- Multiple interface modes (Chat, Instruct, Notebook)
- Real-time parameter adjustment
- Model loader with quantization options
- Extensions system (streaming, API, training)
- Character/persona management

**LM Studio**:

Native GUI application for Windows/Mac/Linux:

- Drag-and-drop model loading
- Built-in model browser and downloader
- Performance benchmarking
- OpenAI-compatible API server
- Multi-model management

### Python Scripts

Python provides programmatic control over LLM inference with extensive libraries and frameworks.

**Using llama-cpp-python**:

```python
from llama_cpp import Llama

# Initialize model
llm = Llama(
 model_path="./models/llama-2-7b.Q4_K_M.gguf",
 n_gpu_layers=35,
 n_ctx=2048,
 n_batch=512,
 verbose=False
)

# Generate text
output = llm(
 "Explain the theory of relativity.",
 max_tokens=256,
 temperature=0.7,
 top_p=0.9,
 stop=["\n\n"],
 echo=False
)

print(output['choices'][0]['text'])

# Streaming generation
for token in llm(
 "Write a story about",
 max_tokens=500,
 stream=True
):
 print(token['choices'][0]['text'], end='', flush=True)
```

**Using Ollama Python library**:

```python
import ollama

# Simple generation
response = ollama.generate(
 model='llama3.2:3b',
 prompt='Why is the sky blue?'
)
print(response['response'])

# Chat interface
messages = [
 {'role': 'system', 'content': 'You are a helpful assistant.'},
 {'role': 'user', 'content': 'What is quantum entanglement?'}
]

response = ollama.chat(
 model='mistral:7b',
 messages=messages
)
print(response['message']['content'])

# Streaming chat
for chunk in ollama.chat(
 model='codellama:13b',
 messages=messages,
 stream=True
):
 print(chunk['message']['content'], end='', flush=True)
```

**Using Transformers library**:

```python
from transformers import AutoTokenizer, AutoModelForCausalLM
import torch

# Load model and tokenizer
model_name = "meta-llama/Llama-2-7b-chat-hf"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(
 model_name,
 torch_dtype=torch.float16,
 device_map="auto",
 load_in_8bit=True
)

# Generate text
prompt = "Explain machine learning:"
inputs = tokenizer(prompt, return_tensors="pt").to("cuda")

outputs = model.generate(
 **inputs,
 max_new_tokens=256,
 temperature=0.7,
 top_p=0.9,
 do_sample=True
)

print(tokenizer.decode(outputs[0], skip_special_tokens=True))
```

### API Calls

Local LLMs can expose OpenAI-compatible REST APIs for integration with existing applications.

**Ollama API**:

```bash
# Generate completion
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2:3b",
  "prompt": "Why is the ocean salty?",
  "stream": false
}'

# Chat completion
curl http://localhost:11434/api/chat -d '{
  "model": "mistral:7b",
  "messages": [
    {"role": "user", "content": "What is photosynthesis?"}
  ]
}'

# Streaming response
curl http://localhost:11434/api/generate -d '{
  "model": "codellama:13b",
  "prompt": "Write a Python function",
  "stream": true
}'
```

**OpenAI-compatible API (llama.cpp server)**:

```bash
# Start server
./server -m models/llama-2-7b.Q4_K_M.gguf \
  --port 8080 --host 0.0.0.0 -ngl 35

# Use OpenAI Python client
from openai import OpenAI

client = OpenAI(
 base_url="http://localhost:8080/v1",
 api_key="not-needed"
)

response = client.chat.completions.create(
 model="llama-2-7b",
 messages=[
  {"role": "user", "content": "Hello!"}
 ],
 temperature=0.7,
 max_tokens=256
)

print(response.choices[0].message.content)
```

**LangChain integration**:

```python
from langchain_community.llms import Ollama
from langchain.chains import LLMChain
from langchain.prompts import PromptTemplate

# Initialize LLM
llm = Ollama(model="llama3.2:3b", temperature=0.7)

# Create chain
template = "Explain {concept} in simple terms:"
prompt = PromptTemplate(template=template, input_variables=["concept"])
chain = LLMChain(llm=llm, prompt=prompt)

# Run
result = chain.run(concept="blockchain")
print(result)
```

## Inference Parameters

### Temperature

Temperature controls randomness in token selection by scaling logits before applying softmax. It's the most impactful parameter for output diversity.

**Mathematical definition**:

```text
P(token) = exp(logit / temperature) / Σ(exp(logit_i / temperature))
```

**Temperature ranges**:

- **0.0-0.3**: Deterministic, focused outputs
  - Use for: Code generation, factual queries, structured data
  - Example: "What is 2+2?" → Always "4"

- **0.4-0.7**: Balanced creativity and coherence
  - Use for: General chat, explanations, Q&A
  - Default for most applications

- **0.8-1.2**: Creative, diverse outputs
  - Use for: Creative writing, brainstorming, varied responses
  - Higher variance in quality

- **1.3+**: Highly random, potentially incoherent
  - Use for: Experimental generation, random sampling
  - Often produces nonsensical results

**Practical examples**:

```python
# Deterministic code generation
response = llm.generate(
 prompt="def fibonacci(n):",
 temperature=0.1,  # Low for consistency
 max_tokens=200
)

# Creative storytelling
response = llm.generate(
 prompt="Write a sci-fi story:",
 temperature=0.9,  # High for creativity
 max_tokens=500
)

# Balanced conversation
response = llm.generate(
 prompt="Explain photosynthesis:",
 temperature=0.7,  # Balanced
 max_tokens=256
)
```

**Impact on token distribution**:

- Temperature = 0.1: Top token has ~95% probability
- Temperature = 0.7: Top token has ~40% probability  
- Temperature = 1.5: Top token has ~15% probability

### Top-p and Top-k

Nucleus (top-p) and top-k sampling control token selection by limiting the candidate pool, complementing temperature.

**Top-k sampling**:

Considers only the k most likely tokens at each step.

```python
# Only consider top 40 tokens
response = llm.generate(
 prompt="The capital of France is",
 top_k=40,
 temperature=0.7
)
```

**Configuration guidelines**:

- `top_k=1`: Greedy decoding (deterministic)
- `top_k=10-20`: Very focused, predictable
- `top_k=40-50`: Balanced (common default)
- `top_k=100+`: More diverse options
- `top_k=0`: Disable (consider all tokens)

**Top-p (nucleus) sampling**:

Considers tokens whose cumulative probability exceeds p, creating dynamic vocabulary.

```python
# Consider tokens until 90% probability mass
response = llm.generate(
 prompt="The capital of France is",
 top_p=0.9,
 temperature=0.7
)
```

**Configuration guidelines**:

- `top_p=0.1`: Very conservative
- `top_p=0.5`: Focused, high-confidence
- `top_p=0.9`: Balanced (common default)
- `top_p=0.95`: Slightly more diverse
- `top_p=1.0`: Consider all tokens

**Combining parameters**:

```python
# Conservative, factual
factual_config = {
 "temperature": 0.3,
 "top_p": 0.85,
 "top_k": 30
}

# Balanced
balanced_config = {
 "temperature": 0.7,
 "top_p": 0.9,
 "top_k": 40
}

# Creative
creative_config = {
 "temperature": 0.95,
 "top_p": 0.95,
 "top_k": 100
}
```

**Best practices**:

1. **Use top-p over top-k**: More adaptive to context
2. **Typical values**: `top_p=0.9`, `temperature=0.7`
3. **Avoid combining aggressive settings**: Don't use `top_k=5` with `temperature=1.5`
4. **Test with your use case**: Different tasks need different settings

### Max Tokens

Max tokens controls the maximum length of generated text, measured in tokens (not words or characters).

**Understanding tokens**:

- English: ~1 token = 0.75 words (4 characters average)
- Code: ~1 token = 0.5-1 words (varies by language)
- Special characters: Often single tokens

**Examples**:

```python
# Short responses (summaries, answers)
response = llm.generate(
 prompt="What is AI?",
 max_tokens=100  # ~75 words
)

# Medium responses (explanations)
response = llm.generate(
 prompt="Explain neural networks:",
 max_tokens=512  # ~384 words
)

# Long responses (articles, stories)
response = llm.generate(
 prompt="Write a detailed guide:",
 max_tokens=2048  # ~1536 words
)
```

**Practical recommendations**:

| Use Case | Max Tokens | Approximate Length |
|----------|------------|--------------------|
| Chat response | 256-512 | 1-2 paragraphs |
| Code generation | 512-1024 | Function/class |
| Article section | 1024-2048 | 3-5 paragraphs |
| Long-form content | 2048-4096 | Multiple pages |

**Important considerations**:

1. **Context budget**: `max_tokens + prompt_tokens < context_window`
2. **Cost**: Longer generation = more compute time
3. **Quality**: Very long generation may lose coherence
4. **Truncation**: Generation stops at max_tokens even mid-sentence

**Dynamic max tokens**:

```python
def calculate_max_tokens(prompt, context_size=2048, buffer=128):
 """Calculate max tokens based on prompt length."""
 prompt_tokens = len(tokenizer.encode(prompt))
 max_response = context_size - prompt_tokens - buffer
 return max(max_response, 128)  # Minimum 128 tokens

# Usage
max_tokens = calculate_max_tokens(user_prompt)
response = llm.generate(prompt=user_prompt, max_tokens=max_tokens)
```

### Context Window

The context window is the maximum number of tokens (prompt + response) the model can process. Managing it effectively is critical for conversation quality.

**Context window sizes**:

| Model | Context Size | Approximate Content |
|-------|--------------|---------------------|
| Llama 2 | 4096 | ~8 pages |
| Llama 3 | 8192 | ~16 pages |
| Mistral 7B | 8192 | ~16 pages |
| Mixtral 8x7B | 32768 | ~65 pages |
| Llama 3.2 | 128k | ~256 pages |

**Context management strategies**:

**1. Sliding window**:

```python
class SlidingWindowContext:
 def __init__(self, max_tokens=2048, keep_system=True):
  self.max_tokens = max_tokens
  self.messages = []
  self.system_message = None
 
 def add_message(self, role, content):
  if role == 'system':
   self.system_message = content
  else:
   self.messages.append({'role': role, 'content': content})
   self._trim_context()
 
 def _trim_context(self):
  """Keep only recent messages within token limit."""
  total_tokens = 0
  keep_messages = []
  
  # Count backwards from most recent
  for msg in reversed(self.messages):
   msg_tokens = len(tokenizer.encode(msg['content']))
   if total_tokens + msg_tokens > self.max_tokens:
    break
   keep_messages.insert(0, msg)
   total_tokens += msg_tokens
  
  self.messages = keep_messages
```

**2. Summarization**:

```python
class SummarizingContext:
 def __init__(self, max_tokens=2048, summary_threshold=1500):
  self.max_tokens = max_tokens
  self.summary_threshold = summary_threshold
  self.messages = []
  self.summary = ""
 
 def add_message(self, role, content):
  self.messages.append({'role': role, 'content': content})
  
  if self._get_token_count() > self.summary_threshold:
   self._summarize_old_messages()
 
 def _summarize_old_messages(self):
  """Summarize old messages to compress context."""
  old_messages = self.messages[:-3]  # Keep last 3
  conversation_text = "\n".join(
   f"{m['role']}: {m['content']}" for m in old_messages
  )
  
  # Generate summary
  self.summary = llm.generate(
   f"Summarize this conversation:\n{conversation_text}",
   max_tokens=200
  )
  
  # Keep only recent messages
  self.messages = self.messages[-3:]
```

**3. Selective retention**:

```python
class SelectiveContext:
 """Keep system prompt, recent messages, and important context."""
 def __init__(self, max_tokens=2048):
  self.max_tokens = max_tokens
  self.system_prompt = ""
  self.important_facts = []  # Key information to retain
  self.recent_messages = []
 
 def build_context(self):
  context = [self.system_prompt]
  
  if self.important_facts:
   context.append("Key facts: " + "; ".join(self.important_facts))
  
  context.extend(self.recent_messages)
  return "\n".join(context)
```

**Best practices**:

1. **Monitor token usage**: Track prompt + response tokens
2. **Reserve buffer**: Keep 10-20% free for response
3. **Prioritize recent context**: Latest messages most relevant
4. **Keep system prompts**: Don't trim important instructions
5. **Test edge cases**: What happens at context limit?

### Stop Sequences

Stop sequences are strings that halt generation when encountered, enabling precise control over output format.

**Common use cases**:

```python
# Stop at double newline (end of paragraph)
response = llm.generate(
    prompt="Explain briefly:",
    stop=["\n\n"],
    max_tokens=200
)

# Stop at specific markers (for structured output)
response = llm.generate(
    prompt="Generate JSON:",
    stop=["}"],  # Stop after first object
    max_tokens=500
)

# Multiple stop sequences
response = llm.generate(
    prompt="User: Hello\nAssistant:",
    stop=["\nUser:", "\nHuman:", "<|endoftext|>"],
    max_tokens=256
)
```

**Practical applications**:

**1. Chat format enforcement**:

```python
def chat_completion(user_message, history):
    prompt = format_chat(history, user_message)
    
    response = llm.generate(
        prompt=prompt,
        stop=["\nUser:", "\nHuman:", "###"],  # Stop before next turn
        max_tokens=512
    )
    
    return response['text'].strip()
```

**2. Structured data extraction**:

```python
# Extract only the answer portion
prompt = """Question: What is the capital of France?
Answer:"""

response = llm.generate(
    prompt=prompt,
    stop=["\n", "Question:"],  # Stop at next line or question
    temperature=0.1
)
# Returns: "Paris"
```

**3. Code block extraction**:

```python
prompt = "Write a Python function to calculate factorial:\n```python\n"

response = llm.generate(
    prompt=prompt,
    stop=["```"],  # Stop at end of code block
    max_tokens=300
)
```

### Repetition Penalty

Repetition penalty discourages the model from repeating tokens, reducing redundant output.

**Parameter range**:

- **1.0**: No penalty (default)
- **1.1-1.15**: Subtle reduction (recommended range)
- **1.2-1.3**: Moderate penalty
- **1.5+**: Strong penalty (may reduce coherence)

**Implementation**:

```python
# Default (no penalty)
response = llm.generate(
    prompt="Tell me about",
    repetition_penalty=1.0
)

# Balanced penalty
response = llm.generate(
    prompt="Explain the concept:",
    repetition_penalty=1.1,  # Recommended
    temperature=0.7
)

# Strong penalty (for highly repetitive models)
response = llm.generate(
    prompt="Write creatively:",
    repetition_penalty=1.3,
    temperature=0.8
)
```

**Advanced: Frequency and presence penalties**:

```python
# OpenAI-style penalties (llama.cpp server)
response = client.chat.completions.create(
    model="local-model",
    messages=messages,
    frequency_penalty=0.5,  # Penalize frequently used tokens
    presence_penalty=0.2     # Penalize any repeated token
)
```

**When to use**:

- **Creative writing**: Moderate penalty (1.1-1.15)
- **Technical content**: Low penalty (1.0-1.05)
- **Conversational**: Moderate penalty (1.1)
- **Code generation**: Minimal penalty (1.0)

**Warning**: High repetition penalty can cause:

- Incoherent output
- Unnatural vocabulary choices
- Broken logic flow
- Grammatical errors

## Loading Models

### Model Loading

Efficient model loading minimizes startup time and resource consumption.

**Initial load process**:

```python
import time
from llama_cpp import Llama

def load_model_with_timing(model_path, n_gpu_layers=35):
    """Load model and measure initialization time."""
    start_time = time.time()
    
    llm = Llama(
        model_path=model_path,
        n_gpu_layers=n_gpu_layers,
        n_ctx=2048,
        n_batch=512,
        verbose=True  # Show loading progress
    )
    
    load_time = time.time() - start_time
    print(f"Model loaded in {load_time:.2f} seconds")
    
    return llm

# Usage
model = load_model_with_timing("./models/llama-2-7b.Q4_K_M.gguf")
```

**Lazy loading**:

```python
class LazyModelLoader:
    """Load model only when first needed."""
    def __init__(self, model_path, **kwargs):
        self.model_path = model_path
        self.kwargs = kwargs
        self._model = None
    
    @property
    def model(self):
        if self._model is None:
            print("Loading model...")
            self._model = Llama(
                model_path=self.model_path,
                **self.kwargs
            )
        return self._model
    
    def generate(self, *args, **kwargs):
        return self.model(*args, **kwargs)

# Model loads on first generation, not instantiation
llm = LazyModelLoader("./models/mistral-7b.gguf", n_gpu_layers=30)
response = llm.generate("Hello")  # Model loads here
```

**Optimization tips**:

1. **Use smaller quantizations** for faster loading (Q4 vs Q8)
2. **Reduce context size** if not needed (`n_ctx=512` vs `n_ctx=2048`)
3. **Adjust batch size** for GPU memory (`n_batch=256` to `n_batch=1024`)
4. **Use mmap**: Most libraries memory-map by default (fast)

### Hot Swapping

Dynamically switching between models without restarting the application.

**Basic model manager**:

```python
class ModelManager:
    def __init__(self):
        self.models = {}
        self.current_model = None
    
    def load_model(self, name, model_path, **kwargs):
        """Load and cache a model."""
        if name not in self.models:
            print(f"Loading {name}...")
            self.models[name] = Llama(
                model_path=model_path,
                **kwargs
            )
        self.current_model = name
        return self.models[name]
    
    def switch_model(self, name):
        """Switch to a different loaded model."""
        if name in self.models:
            self.current_model = name
            return True
        return False
    
    def generate(self, prompt, **kwargs):
        """Generate using current model."""
        if self.current_model:
            model = self.models[self.current_model]
            return model(prompt, **kwargs)
        raise ValueError("No model selected")

# Usage
manager = ModelManager()

# Load multiple models
manager.load_model("fast", "./models/llama-3.2-1b.Q4_K_M.gguf", n_gpu_layers=20)
manager.load_model("quality", "./models/llama-3-8b.Q5_K_M.gguf", n_gpu_layers=35)

# Quick response
manager.switch_model("fast")
quick_response = manager.generate("Brief answer:")

# Detailed response
manager.switch_model("quality")
detailed_response = manager.generate("Detailed explanation:")
```

**Memory-aware swapping**:

```python
import psutil

class MemoryAwareModelManager:
    def __init__(self, max_memory_gb=16):
        self.models = {}
        self.max_memory = max_memory_gb * 1024 * 1024 * 1024  # Convert to bytes
    
    def get_memory_usage(self):
        """Get current RAM usage."""
        return psutil.Process().memory_info().rss
    
    def unload_model(self, name):
        """Unload a model to free memory."""
        if name in self.models:
            del self.models[name]
            import gc
            gc.collect()
    
    def load_model(self, name, model_path, **kwargs):
        """Load model, unloading others if needed."""
        memory_before = self.get_memory_usage()
        
        # Estimate if we have enough memory
        if memory_before > self.max_memory * 0.7:  # 70% threshold
            # Unload least recently used model
            if self.models:
                oldest = list(self.models.keys())[0]
                print(f"Unloading {oldest} to free memory")
                self.unload_model(oldest)
        
        self.models[name] = Llama(model_path=model_path, **kwargs)
        memory_after = self.get_memory_usage()
        
        print(f"Model {name} loaded, memory: {memory_after / 1e9:.2f} GB")
        return self.models[name]
```

### Multiple Models

Running multiple models simultaneously for different tasks.

**Task-specialized models**:

```python
class MultiModelSystem:
    def __init__(self):
        # Code generation model
        self.code_model = Llama(
            model_path="./models/codellama-13b.Q4_K_M.gguf",
            n_gpu_layers=40,
            n_ctx=4096
        )
        
        # Fast chat model
        self.chat_model = Llama(
            model_path="./models/llama-3.2-3b.Q4_K_M.gguf",
            n_gpu_layers=25,
            n_ctx=2048
        )
        
        # Analysis model
        self.analysis_model = Llama(
            model_path="./models/mistral-7b.Q5_K_M.gguf",
            n_gpu_layers=30,
            n_ctx=8192
        )
    
    def generate_code(self, prompt):
        return self.code_model(
            prompt,
            temperature=0.2,
            max_tokens=1024
        )
    
    def chat(self, prompt):
        return self.chat_model(
            prompt,
            temperature=0.7,
            max_tokens=512
        )
    
    def analyze(self, prompt):
        return self.analysis_model(
            prompt,
            temperature=0.4,
            max_tokens=2048
        )

# Usage
system = MultiModelSystem()

code = system.generate_code("def fibonacci(n):")
response = system.chat("How are you?")
analysis = system.analyze("Analyze this data: ...")
```

**Concurrent execution**:

```python
import threading
import queue

class ConcurrentModelRunner:
    def __init__(self, model_path, num_instances=2):
        self.models = [
            Llama(
                model_path=model_path,
                n_gpu_layers=35 // num_instances,  # Divide GPU memory
                n_ctx=2048
            )
            for _ in range(num_instances)
        ]
        self.request_queue = queue.Queue()
        self.workers = []
        
        # Start worker threads
        for i, model in enumerate(self.models):
            worker = threading.Thread(
                target=self._worker,
                args=(i, model),
                daemon=True
            )
            worker.start()
            self.workers.append(worker)
    
    def _worker(self, worker_id, model):
        """Worker thread for processing requests."""
        while True:
            prompt, result_queue = self.request_queue.get()
            try:
                response = model(prompt, max_tokens=256)
                result_queue.put((True, response))
            except Exception as e:
                result_queue.put((False, str(e)))
    
    def generate(self, prompt, timeout=30):
        """Submit generation request."""
        result_queue = queue.Queue()
        self.request_queue.put((prompt, result_queue))
        
        try:
            success, result = result_queue.get(timeout=timeout)
            if success:
                return result
            else:
                raise Exception(result)
        except queue.Empty:
            raise TimeoutError("Generation timed out")

# Usage
runner = ConcurrentModelRunner("./models/llama-2-7b.gguf", num_instances=2)

# Process multiple requests concurrently
import concurrent.futures

prompts = ["Question 1", "Question 2", "Question 3"]
with concurrent.futures.ThreadPoolExecutor() as executor:
    futures = [executor.submit(runner.generate, p) for p in prompts]
    results = [f.result() for f in futures]
```

### Model Caching

Keeping models loaded in memory for instant access.

**LRU cache implementation**:

```python
from collections import OrderedDict
import time

class ModelCache:
    def __init__(self, max_models=3, ttl_seconds=3600):
        self.cache = OrderedDict()
        self.max_models = max_models
        self.ttl = ttl_seconds
        self.access_times = {}
    
    def get_model(self, model_path, **kwargs):
        """Get cached model or load new one."""
        # Check if cached and not expired
        if model_path in self.cache:
            if time.time() - self.access_times[model_path] < self.ttl:
                # Move to end (most recently used)
                self.cache.move_to_end(model_path)
                self.access_times[model_path] = time.time()
                return self.cache[model_path]
            else:
                # Expired, remove
                del self.cache[model_path]
                del self.access_times[model_path]
        
        # Load new model
        if len(self.cache) >= self.max_models:
            # Remove least recently used
            oldest_path = next(iter(self.cache))
            print(f"Evicting {oldest_path} from cache")
            del self.cache[oldest_path]
            del self.access_times[oldest_path]
        
        print(f"Loading {model_path}...")
        model = Llama(model_path=model_path, **kwargs)
        self.cache[model_path] = model
        self.access_times[model_path] = time.time()
        
        return model
    
    def clear_cache(self):
        """Remove all cached models."""
        self.cache.clear()
        self.access_times.clear()
        import gc
        gc.collect()

# Usage
cache = ModelCache(max_models=3, ttl_seconds=1800)  # 30 min TTL

# First call loads model
model1 = cache.get_model("./models/llama-2-7b.gguf", n_gpu_layers=35)

# Second call uses cached model (instant)
model1_again = cache.get_model("./models/llama-2-7b.gguf", n_gpu_layers=35)
```

## GPU Utilization

### GPU Layers

Offloading layers to GPU dramatically improves inference speed. Understanding layer distribution is critical for optimization.

**How GPU offloading works**:

- LLMs consist of stacked transformer layers (decoder blocks)
- Each layer can run on GPU (fast) or CPU (slow)
- Parameter `n_gpu_layers` or `ngl` controls how many layers use GPU

**Determining optimal GPU layers**:

```python
import subprocess

def get_gpu_memory():
    """Get available GPU memory in GB."""
    result = subprocess.run(
        ['nvidia-smi', '--query-gpu=memory.free', '--format=csv,noheader,nounits'],
        capture_output=True,
        text=True
    )
    return int(result.stdout.strip()) / 1024  # Convert MB to GB

def calculate_gpu_layers(model_size_b, available_vram_gb, quant_bits=4):
    """Estimate maximum GPU layers."""
    # Rough estimation
    memory_per_layer_gb = (model_size_b * quant_bits / 8) / 32  # Assuming 32 layers
    max_layers = int((available_vram_gb - 2) / memory_per_layer_gb)  # 2GB buffer
    
    return max_layers

# Example
available_vram = get_gpu_memory()
max_layers = calculate_gpu_layers(model_size_b=7, available_vram_gb=available_vram)
print(f"Can offload {max_layers} layers with {available_vram:.1f}GB VRAM")
```

**Common configurations**:

| Model | Total Layers | 8GB VRAM | 12GB VRAM | 16GB VRAM | 24GB VRAM |
|-------|--------------|----------|-----------|-----------|----------|
| 7B Q4 | 32 | 20-25 | 32 (all) | 32 (all) | 32 (all) |
| 13B Q4 | 40 | 10-15 | 25-30 | 40 (all) | 40 (all) |
| 30B Q4 | 60 | 5-8 | 12-16 | 20-25 | 40-50 |
| 70B Q4 | 80 | 0-3 | 6-10 | 12-16 | 25-35 |

**Implementation examples**:

```bash
# llama.cpp
./main -m model.gguf -ngl 35  # Offload 35 layers

# Ollama (automatic, or set in Modelfile)
ollama run llama3.2 --gpu-layers 32
```

```python
# llama-cpp-python
llm = Llama(
    model_path="./model.gguf",
    n_gpu_layers=35,  # Offload 35 layers
    n_ctx=2048
)

# Transformers with device_map
model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-7b-hf",
    device_map="auto",  # Automatic layer distribution
    torch_dtype=torch.float16
)
```

**Monitoring GPU usage**:

```python
import torch

def print_gpu_utilization():
    """Display GPU memory usage."""
    if torch.cuda.is_available():
        for i in range(torch.cuda.device_count()):
            allocated = torch.cuda.memory_allocated(i) / 1e9
            reserved = torch.cuda.memory_reserved(i) / 1e9
            print(f"GPU {i}: {allocated:.2f}GB allocated, {reserved:.2f}GB reserved")

# Check before and after loading
print_gpu_utilization()
model = load_model()
print_gpu_utilization()
```

### Batch Size

Batch size affects throughput and memory usage, critical for multi-request scenarios.

**Understanding n_batch**:

- Number of tokens processed simultaneously
- Larger = faster throughput, more VRAM
- Typical range: 128-2048

**Optimization strategy**:

```python
def optimize_batch_size(model_path, start_batch=128):
    """Find optimal batch size for GPU."""
    batch_sizes = [128, 256, 512, 1024, 2048]
    results = {}
    
    for batch_size in batch_sizes:
        try:
            llm = Llama(
                model_path=model_path,
                n_gpu_layers=35,
                n_batch=batch_size,
                n_ctx=2048
            )
            
            # Test inference
            start = time.time()
            llm("Test prompt", max_tokens=100)
            duration = time.time() - start
            
            results[batch_size] = duration
            print(f"Batch {batch_size}: {duration:.2f}s")
            
            del llm
        except Exception as e:
            print(f"Batch {batch_size} failed: {e}")
            break
    
    # Return fastest
    return min(results, key=results.get)

optimal = optimize_batch_size("./model.gguf")
print(f"Optimal batch size: {optimal}")
```

**Configuration guidelines**:

```python
# Memory-constrained (4-8GB VRAM)
llm = Llama(
    model_path=model_path,
    n_batch=256,  # Smaller batch
    n_gpu_layers=20
)

# Balanced (12-16GB VRAM)
llm = Llama(
    model_path=model_path,
    n_batch=512,  # Standard
    n_gpu_layers=32
)

# High-throughput (24GB+ VRAM)
llm = Llama(
    model_path=model_path,
    n_batch=2048,  # Maximum throughput
    n_gpu_layers=35
)
```

### Memory Management

Effective VRAM management prevents OOM errors and enables running larger models.

**Memory calculation**:

```python
def estimate_memory_requirements(model_size_b, quant_bits, context_size, batch_size):
    """Estimate VRAM needed for model."""
    # Model weights
    model_memory_gb = (model_size_b * quant_bits) / 8
    
    # Context memory (KV cache)
    kv_cache_gb = (context_size * model_size_b * 0.0001)  # Rough estimate
    
    # Batch processing overhead
    batch_overhead_gb = (batch_size / 512) * 0.5
    
    # Total with 20% buffer
    total = (model_memory_gb + kv_cache_gb + batch_overhead_gb) * 1.2
    
    return {
        'model': model_memory_gb,
        'kv_cache': kv_cache_gb,
        'batch': batch_overhead_gb,
        'total': total
    }

# Example: Llama 2 7B Q4
memory = estimate_memory_requirements(
    model_size_b=7,
    quant_bits=4,
    context_size=2048,
    batch_size=512
)

print(f"Estimated VRAM: {memory['total']:.2f}GB")
print(f"  Model: {memory['model']:.2f}GB")
print(f"  KV Cache: {memory['kv_cache']:.2f}GB")
print(f"  Batch: {memory['batch']:.2f}GB")
```

**Memory optimization techniques**:

```python
# 1. Use flash attention (if supported)
llm = Llama(
    model_path=model_path,
    n_gpu_layers=35,
    flash_attn=True  # Reduces memory, increases speed
)

# 2. Reduce context window
llm = Llama(
    model_path=model_path,
    n_ctx=1024,  # Instead of 2048
    n_gpu_layers=35
)

# 3. Mixed GPU/CPU offloading
llm = Llama(
    model_path=model_path,
    n_gpu_layers=25,  # Not all layers
    n_ctx=2048
)

# 4. Clear cache between runs
import gc
import torch

def clear_gpu_cache():
    """Free unused GPU memory."""
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
    gc.collect()

clear_gpu_cache()
```

### Multi-GPU Setup

Distributing model across multiple GPUs for larger models or higher throughput.

**Tensor parallelism** (split layers across GPUs):

```bash
# llama.cpp with multiple GPUs
export CUDA_VISIBLE_DEVICES=0,1
./main -m model.gguf -ngl 35 -mg 2  # Split across 2 GPUs
```

```python
# Transformers with tensor parallelism
import torch
from transformers import AutoModelForCausalLM

model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-70b-hf",
    device_map="auto",  # Automatically split across GPUs
    torch_dtype=torch.float16,
    max_memory={0: "20GB", 1: "20GB"}  # Limit per GPU
)
```

**Pipeline parallelism** (different requests on different GPUs):

```python
class MultiGPUModelServer:
    def __init__(self, model_path, num_gpus=2):
        self.models = []
        
        for gpu_id in range(num_gpus):
            # Load same model on each GPU
            llm = Llama(
                model_path=model_path,
                n_gpu_layers=35,
                n_ctx=2048,
                tensor_split=[1.0 if i == gpu_id else 0.0 for i in range(num_gpus)]
            )
            self.models.append(llm)
        
        self.current_gpu = 0
    
    def generate(self, prompt, **kwargs):
        """Round-robin GPU selection."""
        model = self.models[self.current_gpu]
        self.current_gpu = (self.current_gpu + 1) % len(self.models)
        return model(prompt, **kwargs)

# Usage: 2x throughput with 2 GPUs
server = MultiGPUModelServer("./model.gguf", num_gpus=2)
```

**Monitoring multi-GPU**:

```python
import torch

def monitor_multi_gpu():
    """Display usage across all GPUs."""
    for i in range(torch.cuda.device_count()):
        props = torch.cuda.get_device_properties(i)
        allocated = torch.cuda.memory_allocated(i) / 1e9
        total = props.total_memory / 1e9
        
        print(f"GPU {i} ({props.name}):")
        print(f"  Memory: {allocated:.2f}GB / {total:.2f}GB")
        print(f"  Utilization: {allocated/total*100:.1f}%")
```

## CPU Fallback

### CPU-Only Inference

Running models on CPU enables inference on systems without GPUs, though significantly slower.

**Configuration**:

```python
# llama-cpp-python CPU-only
llm = Llama(
    model_path="./models/llama-2-7b.Q4_K_M.gguf",
    n_gpu_layers=0,  # No GPU offloading
    n_threads=8,     # Use 8 CPU threads
    n_ctx=2048
)

# Optimize for CPU
llm = Llama(
    model_path="./models/llama-3.2-3b.Q4_K_M.gguf",
    n_gpu_layers=0,
    n_threads=os.cpu_count(),  # Use all available cores
    n_batch=256,               # Smaller batch for CPU
    use_mlock=True,            # Lock memory to prevent swapping
    use_mmap=True              # Memory-map model file
)
```

**Performance optimization**:

```python
import os
import multiprocessing

def optimize_cpu_threads():
    """Determine optimal thread count."""
    cpu_count = multiprocessing.cpu_count()
    physical_cores = cpu_count // 2  # Assuming hyperthreading
    
    # Use physical cores, leave some for system
    return max(physical_cores - 2, 1)

# Usage
optimal_threads = optimize_cpu_threads()
llm = Llama(
    model_path=model_path,
    n_gpu_layers=0,
    n_threads=optimal_threads
)
```

**Model selection for CPU**:

- **Prefer smaller models**: 1B-7B parameter range
- **Use aggressive quantization**: Q3_K_S or Q4_K_S
- **Reduce context**: 1024 or 512 tokens instead of 2048+

**Performance expectations**:

| Model | Quantization | CPU (Ryzen 9 5950X) | GPU (RTX 3090) |
|-------|--------------|---------------------|----------------|
| 1B | Q4_K_M | 25-30 t/s | 150+ t/s |
| 3B | Q4_K_M | 12-18 t/s | 100+ t/s |
| 7B | Q4_K_M | 5-8 t/s | 60-80 t/s |
| 13B | Q4_K_M | 2-4 t/s | 40-50 t/s |

### Hybrid CPU/GPU

Partial GPU offloading balances performance and memory constraints.

**Strategy**:

```python
def hybrid_configuration(model_path, available_vram_gb):
    """Configure model for hybrid CPU/GPU."""
    # Estimate layers that fit in VRAM
    if available_vram_gb < 6:
        gpu_layers = 15
        batch_size = 256
    elif available_vram_gb < 10:
        gpu_layers = 25
        batch_size = 512
    else:
        gpu_layers = 35
        batch_size = 1024
    
    llm = Llama(
        model_path=model_path,
        n_gpu_layers=gpu_layers,  # Partial offloading
        n_threads=6,              # CPU handles remaining layers
        n_batch=batch_size,
        n_ctx=2048
    )
    
    return llm

# Usage
llm = hybrid_configuration("./model.gguf", available_vram_gb=8)
```

**Layer distribution impact**:

```python
# Test different GPU layer counts
import time

def benchmark_gpu_layers(model_path, layer_counts):
    """Compare performance with different GPU offloading."""
    results = {}
    
    for n_layers in layer_counts:
        llm = Llama(
            model_path=model_path,
            n_gpu_layers=n_layers,
            n_threads=6,
            n_ctx=2048
        )
        
        # Benchmark
        start = time.time()
        llm("Write a short story", max_tokens=200)
        duration = time.time() - start
        
        tokens_per_second = 200 / duration
        results[n_layers] = tokens_per_second
        
        print(f"{n_layers} GPU layers: {tokens_per_second:.1f} t/s")
        del llm
    
    return results

# Test
results = benchmark_gpu_layers(
    "./models/llama-2-7b.Q4_K_M.gguf",
    layer_counts=[0, 10, 20, 30, 35]
)
```

### Performance Expectations

Understanding CPU inference performance helps set realistic expectations.

**Factors affecting CPU speed**:

1. **CPU architecture**: Modern CPUs (AVX2, AVX-512) significantly faster
2. **Thread count**: More physical cores = better performance
3. **Memory bandwidth**: DDR5 faster than DDR4
4. **Model quantization**: Q4 faster than Q8
5. **Context length**: Shorter contexts = faster inference

**Benchmark examples**:

```python
import time

def benchmark_inference(llm, num_runs=5):
    """Measure tokens/second."""
    total_time = 0
    total_tokens = 0
    
    for _ in range(num_runs):
        start = time.time()
        result = llm(
            "Explain quantum computing",
            max_tokens=100,
            stream=False
        )
        duration = time.time() - start
        
        tokens = len(result['choices'][0]['text'].split())
        total_time += duration
        total_tokens += tokens
    
    avg_speed = total_tokens / total_time
    print(f"Average speed: {avg_speed:.2f} tokens/second")
    return avg_speed

# Compare CPU vs GPU
print("CPU-only:")
cpu_llm = Llama(model_path=model_path, n_gpu_layers=0, n_threads=8)
cpu_speed = benchmark_inference(cpu_llm)

print("\nGPU-accelerated:")
gpu_llm = Llama(model_path=model_path, n_gpu_layers=35)
gpu_speed = benchmark_inference(gpu_llm)

print(f"\nSpeedup: {gpu_speed/cpu_speed:.1f}x")
```

## Conversation Management

### Context Preservation

Maintaining conversation state across multiple turns is essential for coherent dialogue.

**Simple conversation history**:

```python
class ConversationManager:
    def __init__(self, llm, system_prompt=""):
        self.llm = llm
        self.system_prompt = system_prompt
        self.history = []
    
    def add_user_message(self, message):
        """Add user message to history."""
        self.history.append({'role': 'user', 'content': message})
    
    def add_assistant_message(self, message):
        """Add assistant response to history."""
        self.history.append({'role': 'assistant', 'content': message})
    
    def build_prompt(self):
        """Format conversation as prompt."""
        prompt = self.system_prompt + "\n\n" if self.system_prompt else ""
        
        for msg in self.history:
            if msg['role'] == 'user':
                prompt += f"User: {msg['content']}\n"
            else:
                prompt += f"Assistant: {msg['content']}\n"
        
        prompt += "Assistant:"
        return prompt
    
    def chat(self, user_message):
        """Process user message and generate response."""
        self.add_user_message(user_message)
        prompt = self.build_prompt()
        
        response = self.llm(
            prompt,
            max_tokens=512,
            stop=["\nUser:", "\nHuman:"],
            temperature=0.7
        )
        
        assistant_message = response['choices'][0]['text'].strip()
        self.add_assistant_message(assistant_message)
        
        return assistant_message
    
    def clear_history(self):
        """Reset conversation."""
        self.history = []

# Usage
llm = Llama(model_path="./model.gguf", n_gpu_layers=35)
conversation = ConversationManager(
    llm,
    system_prompt="You are a helpful AI assistant."
)

response1 = conversation.chat("What is machine learning?")
print(f"AI: {response1}")

response2 = conversation.chat("Can you give me an example?")
print(f"AI: {response2}")
```

### System Prompts

System prompts establish behavior, personality, and capabilities for the model.

**Effective system prompt patterns**:

```python
# Technical assistant
technical_system = """You are an expert software engineer with deep knowledge 
of Python, algorithms, and system design. Provide clear, concise answers 
with code examples when appropriate. Explain complex concepts in simple terms."""

# Creative writer
writer_system = """You are a creative writing assistant. Generate engaging, 
original content with vivid descriptions. Adapt your writing style to match 
the user's requested genre and tone."""

# Factual educator
educator_system = """You are a knowledgeable teacher. Explain concepts clearly 
using examples and analogies. Break down complex topics into understandable parts. 
Admit when you're uncertain about information."""

# Code reviewer
reviewer_system = """You are a senior code reviewer. Analyze code for bugs, 
performance issues, security vulnerabilities, and style violations. Provide 
specific, actionable feedback with examples of improvements."""
```

**Implementing system prompts**:

```python
class SystemPromptManager:
    """Manage different system prompts for various tasks."""
    
    PROMPTS = {
        'assistant': 'You are a helpful AI assistant.',
        'coder': 'You are an expert programmer. Write clean, efficient code.',
        'teacher': 'You are a patient teacher. Explain concepts clearly.',
        'analyst': 'You are a data analyst. Provide insights from data.'
    }
    
    def __init__(self, llm, default_role='assistant'):
        self.llm = llm
        self.current_role = default_role
        self.history = []
    
    def set_role(self, role):
        """Change system prompt."""
        if role in self.PROMPTS:
            self.current_role = role
            self.history = []  # Clear history on role change
        else:
            raise ValueError(f"Unknown role: {role}")
    
    def chat(self, message):
        """Chat with current role's system prompt."""
        system_prompt = self.PROMPTS[self.current_role]
        
        prompt = f"{system_prompt}\n\n"
        for msg in self.history:
            prompt += f"{msg['role']}: {msg['content']}\n"
        prompt += f"User: {message}\nAssistant:"
        
        response = self.llm(
            prompt,
            max_tokens=512,
            stop=["\nUser:"],
            temperature=0.7
        )
        
        assistant_msg = response['choices'][0]['text'].strip()
        self.history.append({'role': 'User', 'content': message})
        self.history.append({'role': 'Assistant', 'content': assistant_msg})
        
        return assistant_msg
```

### Multi-Turn Dialogue

Managing extended conversations with context windows and memory.

```python
class MultiTurnDialogue:
    def __init__(self, llm, max_context_tokens=2048):
        self.llm = llm
        self.max_context = max_context_tokens
        self.messages = []
        self.token_counts = []
    
    def estimate_tokens(self, text):
        """Rough token estimation (4 chars ≈ 1 token)."""
        return len(text) // 4
    
    def add_turn(self, user_msg, assistant_msg):
        """Add conversation turn."""
        self.messages.append({
            'user': user_msg,
            'assistant': assistant_msg
        })
        
        turn_tokens = self.estimate_tokens(user_msg + assistant_msg)
        self.token_counts.append(turn_tokens)
        
        # Trim if exceeds context
        while sum(self.token_counts) > self.max_context * 0.7:
            self.messages.pop(0)
            self.token_counts.pop(0)
    
    def generate_response(self, user_message):
        """Generate response maintaining context."""
        # Build prompt from history
        prompt = ""
        for turn in self.messages:
            prompt += f"User: {turn['user']}\n"
            prompt += f"Assistant: {turn['assistant']}\n"
        prompt += f"User: {user_message}\nAssistant:"
        
        response = self.llm(
            prompt,
            max_tokens=512,
            stop=["\nUser:"],
            temperature=0.7
        )
        
        assistant_response = response['choices'][0]['text'].strip()
        self.add_turn(user_message, assistant_response)
        
        return assistant_response
    
    def get_context_usage(self):
        """Report context window usage."""
        total_tokens = sum(self.token_counts)
        percentage = (total_tokens / self.max_context) * 100
        return f"{total_tokens}/{self.max_context} tokens ({percentage:.1f}%)"
```

### Context Reset

Clearing conversation history when needed.

```python
class ConversationWithReset:
    def __init__(self, llm, system_prompt="", auto_reset_turns=20):
        self.llm = llm
        self.system_prompt = system_prompt
        self.auto_reset_turns = auto_reset_turns
        self.messages = []
        self.turn_count = 0
    
    def chat(self, user_message):
        """Chat with automatic reset."""
        # Auto-reset if too many turns
        if self.turn_count >= self.auto_reset_turns:
            print("Auto-resetting conversation...")
            self.reset()
        
        self.messages.append({'role': 'user', 'content': user_message})
        prompt = self._build_prompt()
        
        response = self.llm(
            prompt,
            max_tokens=512,
            temperature=0.7,
            stop=["\nUser:"]
        )
        
        assistant_msg = response['choices'][0]['text'].strip()
        self.messages.append({'role': 'assistant', 'content': assistant_msg})
        self.turn_count += 1
        
        return assistant_msg
    
    def reset(self, keep_system_prompt=True):
        """Clear conversation history."""
        self.messages = []
        self.turn_count = 0
        print("Conversation reset.")
    
    def soft_reset(self, keep_last_n=5):
        """Keep only recent messages."""
        if len(self.messages) > keep_last_n:
            self.messages = self.messages[-keep_last_n:]
        self.turn_count = len(self.messages) // 2
    
    def _build_prompt(self):
        """Build prompt from messages."""
        prompt = self.system_prompt + "\n\n" if self.system_prompt else ""
        for msg in self.messages:
            role = msg['role'].capitalize()
            prompt += f"{role}: {msg['content']}\n"
        prompt += "Assistant:"
        return prompt
```

## Batch Processing

### Bulk Inference

Processing multiple requests efficiently for high throughput scenarios.

**Sequential batch processing**:

```python
import time
from typing import List, Dict

class BatchProcessor:
    def __init__(self, llm, batch_size=10):
        self.llm = llm
        self.batch_size = batch_size
    
    def process_batch(self, prompts: List[str], **kwargs) -> List[Dict]:
        """Process a batch of prompts."""
        results = []
        total_time = 0
        
        for i, prompt in enumerate(prompts):
            start = time.time()
            
            response = self.llm(
                prompt,
                max_tokens=kwargs.get('max_tokens', 256),
                temperature=kwargs.get('temperature', 0.7),
                stop=kwargs.get('stop', None)
            )
            
            duration = time.time() - start
            total_time += duration
            
            results.append({
                'prompt': prompt,
                'response': response['choices'][0]['text'],
                'duration': duration,
                'tokens': len(response['choices'][0]['text'].split())
            })
            
            if (i + 1) % self.batch_size == 0:
                print(f"Processed {i + 1}/{len(prompts)} prompts")
        
        avg_time = total_time / len(prompts)
        print(f"\nBatch complete. Average: {avg_time:.2f}s per prompt")
        
        return results

# Usage
llm = Llama(model_path="./model.gguf", n_gpu_layers=35)
processor = BatchProcessor(llm, batch_size=5)

prompts = [
    "Explain machine learning",
    "What is quantum computing?",
    "Describe neural networks",
    "What is blockchain?",
    "Explain artificial intelligence"
]

results = processor.process_batch(prompts, max_tokens=200)

# Save results
import json
with open('batch_results.json', 'w') as f:
    json.dump(results, f, indent=2)
```

**Parallel batch processing** (for multi-GPU or API servers):

```python
import concurrent.futures
import queue
import threading

class ParallelBatchProcessor:
    def __init__(self, model_path, num_workers=2):
        self.model_path = model_path
        self.num_workers = num_workers
        self.results = []
        self.lock = threading.Lock()
    
    def _worker(self, prompts, worker_id, **kwargs):
        """Worker thread for processing subset of prompts."""
        # Each worker loads its own model instance
        llm = Llama(
            model_path=self.model_path,
            n_gpu_layers=35 // self.num_workers,
            n_ctx=2048
        )
        
        for i, prompt in enumerate(prompts):
            response = llm(
                prompt,
                max_tokens=kwargs.get('max_tokens', 256),
                temperature=kwargs.get('temperature', 0.7)
            )
            
            result = {
                'prompt': prompt,
                'response': response['choices'][0]['text'],
                'worker': worker_id
            }
            
            with self.lock:
                self.results.append(result)
                print(f"Worker {worker_id}: Completed {i+1}/{len(prompts)}")
    
    def process(self, prompts: List[str], **kwargs):
        """Process prompts in parallel."""
        self.results = []
        
        # Split prompts among workers
        chunk_size = len(prompts) // self.num_workers
        chunks = [
            prompts[i:i + chunk_size]
            for i in range(0, len(prompts), chunk_size)
        ]
        
        # Launch workers
        with concurrent.futures.ThreadPoolExecutor(max_workers=self.num_workers) as executor:
            futures = [
                executor.submit(self._worker, chunk, i, **kwargs)
                for i, chunk in enumerate(chunks)
            ]
            concurrent.futures.wait(futures)
        
        return self.results

# Usage
processor = ParallelBatchProcessor("./model.gguf", num_workers=2)
results = processor.process(large_prompt_list, max_tokens=200)
```

### Queue Management

Handling incoming requests with priority and rate limiting.

```python
import queue
import threading
import time
from enum import Enum
from dataclasses import dataclass, field
from typing import Optional

class Priority(Enum):
    HIGH = 1
    NORMAL = 2
    LOW = 3

@dataclass(order=True)
class Request:
    priority: int
    prompt: str = field(compare=False)
    max_tokens: int = field(default=256, compare=False)
    callback: Optional[callable] = field(default=None, compare=False)
    timestamp: float = field(default_factory=time.time, compare=False)

class QueuedInferenceServer:
    def __init__(self, model_path, max_queue_size=100):
        self.llm = Llama(model_path=model_path, n_gpu_layers=35)
        self.request_queue = queue.PriorityQueue(maxsize=max_queue_size)
        self.is_running = False
        self.worker_thread = None
        self.stats = {
            'processed': 0,
            'failed': 0,
            'total_time': 0
        }
    
    def start(self):
        """Start processing queue."""
        self.is_running = True
        self.worker_thread = threading.Thread(target=self._process_queue, daemon=True)
        self.worker_thread.start()
        print("Inference server started")
    
    def stop(self):
        """Stop processing queue."""
        self.is_running = False
        if self.worker_thread:
            self.worker_thread.join()
        print("Inference server stopped")
    
    def submit_request(self, prompt: str, priority: Priority = Priority.NORMAL,
                      max_tokens: int = 256, callback: Optional[callable] = None):
        """Submit inference request to queue."""
        try:
            request = Request(
                priority=priority.value,
                prompt=prompt,
                max_tokens=max_tokens,
                callback=callback
            )
            self.request_queue.put(request, timeout=1.0)
            return True
        except queue.Full:
            print("Queue is full, request rejected")
            return False
    
    def _process_queue(self):
        """Worker thread to process queued requests."""
        while self.is_running:
            try:
                # Get next request (blocks with timeout)
                request = self.request_queue.get(timeout=1.0)
                
                # Process request
                start_time = time.time()
                try:
                    response = self.llm(
                        request.prompt,
                        max_tokens=request.max_tokens,
                        temperature=0.7
                    )
                    
                    duration = time.time() - start_time
                    result = response['choices'][0]['text']
                    
                    # Update stats
                    self.stats['processed'] += 1
                    self.stats['total_time'] += duration
                    
                    # Call callback if provided
                    if request.callback:
                        request.callback(result, duration)
                    
                    print(f"Processed request in {duration:.2f}s")
                    
                except Exception as e:
                    self.stats['failed'] += 1
                    print(f"Error processing request: {e}")
                
                self.request_queue.task_done()
                
            except queue.Empty:
                continue
    
    def get_stats(self):
        """Get server statistics."""
        if self.stats['processed'] > 0:
            avg_time = self.stats['total_time'] / self.stats['processed']
        else:
            avg_time = 0
        
        return {
            'queue_size': self.request_queue.qsize(),
            'processed': self.stats['processed'],
            'failed': self.stats['failed'],
            'average_time': avg_time
        }

# Usage
server = QueuedInferenceServer("./model.gguf", max_queue_size=50)
server.start()

# Submit requests with different priorities
server.submit_request("Urgent question", priority=Priority.HIGH)
server.submit_request("Normal question", priority=Priority.NORMAL)
server.submit_request("Low priority", priority=Priority.LOW)

# Check stats
time.sleep(5)
stats = server.get_stats()
print(f"Stats: {stats}")

server.stop()
```

### Asynchronous Processing

Non-blocking inference for responsive applications.

```python
import asyncio
import concurrent.futures
from typing import List, Dict

class AsyncInferenceEngine:
    def __init__(self, model_path, max_workers=2):
        self.model_path = model_path
        self.executor = concurrent.futures.ThreadPoolExecutor(max_workers=max_workers)
        # Load models in executor
        self.models = []
        for _ in range(max_workers):
            model = Llama(model_path=model_path, n_gpu_layers=35)
            self.models.append(model)
        self.current_model_idx = 0
    
    def _get_next_model(self):
        """Round-robin model selection."""
        model = self.models[self.current_model_idx]
        self.current_model_idx = (self.current_model_idx + 1) % len(self.models)
        return model
    
    async def generate(self, prompt: str, **kwargs) -> str:
        """Async generation."""
        loop = asyncio.get_event_loop()
        model = self._get_next_model()
        
        # Run inference in thread pool
        response = await loop.run_in_executor(
            self.executor,
            lambda: model(
                prompt,
                max_tokens=kwargs.get('max_tokens', 256),
                temperature=kwargs.get('temperature', 0.7)
            )
        )
        
        return response['choices'][0]['text']
    
    async def generate_many(self, prompts: List[str], **kwargs) -> List[str]:
        """Generate responses for multiple prompts concurrently."""
        tasks = [self.generate(prompt, **kwargs) for prompt in prompts]
        results = await asyncio.gather(*tasks)
        return results
    
    def shutdown(self):
        """Clean up resources."""
        self.executor.shutdown(wait=True)

# Usage with asyncio
async def main():
    engine = AsyncInferenceEngine("./model.gguf", max_workers=2)
    
    # Single async generation
    response = await engine.generate("What is AI?")
    print(f"Response: {response}")
    
    # Multiple concurrent generations
    prompts = [
        "Explain machine learning",
        "What is deep learning?",
        "Describe neural networks",
        "What is NLP?"
    ]
    
    responses = await engine.generate_many(prompts, max_tokens=200)
    
    for prompt, response in zip(prompts, responses):
        print(f"\nQ: {prompt}")
        print(f"A: {response[:100]}...")
    
    engine.shutdown()

# Run async code
asyncio.run(main())
```

## Streaming Responses

### Token Streaming

Real-time token-by-token generation for responsive user experiences.

**Basic streaming**:

```python
from llama_cpp import Llama

llm = Llama(model_path="./model.gguf", n_gpu_layers=35)

# Stream tokens as they're generated
for chunk in llm(
    "Write a story about a robot",
    max_tokens=500,
    stream=True
):
    print(chunk['choices'][0]['text'], end='', flush=True)

print()  # New line at end
```

**Streaming with metadata**:

```python
import time

def stream_with_stats(llm, prompt, max_tokens=500):
    """Stream with performance statistics."""
    start_time = time.time()
    token_count = 0
    first_token_time = None
    
    for chunk in llm(prompt, max_tokens=max_tokens, stream=True):
        if token_count == 0:
            first_token_time = time.time() - start_time
        
        text = chunk['choices'][0]['text']
        print(text, end='', flush=True)
        token_count += 1
    
    total_time = time.time() - start_time
    tokens_per_second = token_count / total_time
    
    print(f"\n\nStats:")
    print(f"  Time to first token: {first_token_time:.2f}s")
    print(f"  Total tokens: {token_count}")
    print(f"  Total time: {total_time:.2f}s")
    print(f"  Speed: {tokens_per_second:.1f} tokens/s")

# Usage
stream_with_stats(llm, "Explain quantum mechanics")
```

### Implementation

Implementing streaming in various frameworks.

**Flask streaming endpoint**:

```python
from flask import Flask, Response, request, stream_with_context
import json

app = Flask(__name__)
llm = Llama(model_path="./model.gguf", n_gpu_layers=35)

@app.route('/generate/stream', methods=['POST'])
def generate_stream():
    """Streaming generation endpoint."""
    data = request.json
    prompt = data.get('prompt', '')
    max_tokens = data.get('max_tokens', 512)
    
    def generate():
        for chunk in llm(
            prompt,
            max_tokens=max_tokens,
            stream=True,
            temperature=0.7
        ):
            text = chunk['choices'][0]['text']
            # Send as Server-Sent Events
            yield f"data: {json.dumps({'text': text})}\n\n"
        
        yield "data: [DONE]\n\n"
    
    return Response(
        stream_with_context(generate()),
        mimetype='text/event-stream',
        headers={
            'Cache-Control': 'no-cache',
            'X-Accel-Buffering': 'no'
        }
    )

# Non-streaming endpoint for comparison
@app.route('/generate', methods=['POST'])
def generate():
    """Non-streaming generation endpoint."""
    data = request.json
    prompt = data.get('prompt', '')
    
    response = llm(
        prompt,
        max_tokens=512,
        stream=False,
        temperature=0.7
    )
    
    return json.dumps({
        'text': response['choices'][0]['text']
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

**FastAPI streaming**:

```python
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
import json

app = FastAPI()
llm = Llama(model_path="./model.gguf", n_gpu_layers=35)

class GenerateRequest(BaseModel):
    prompt: str
    max_tokens: int = 512
    temperature: float = 0.7

@app.post("/generate/stream")
async def generate_stream(request: GenerateRequest):
    """Async streaming endpoint."""
    
    async def token_generator():
        for chunk in llm(
            request.prompt,
            max_tokens=request.max_tokens,
            temperature=request.temperature,
            stream=True
        ):
            text = chunk['choices'][0]['text']
            yield f"data: {json.dumps({'token': text})}\n\n"
        
        yield "data: [DONE]\n\n"
    
    return StreamingResponse(
        token_generator(),
        media_type="text/event-stream"
    )

@app.post("/generate")
def generate(request: GenerateRequest):
    """Standard non-streaming endpoint."""
    response = llm(
        request.prompt,
        max_tokens=request.max_tokens,
        temperature=request.temperature,
        stream=False
    )
    
    return {"text": response['choices'][0]['text']}
```

**WebSocket streaming**:

```python
import asyncio
import websockets
import json

async def stream_handler(websocket, path):
    """Handle WebSocket streaming connections."""
    llm = Llama(model_path="./model.gguf", n_gpu_layers=35)
    
    try:
        async for message in websocket:
            data = json.loads(message)
            prompt = data.get('prompt', '')
            
            # Stream tokens back
            for chunk in llm(prompt, max_tokens=512, stream=True):
                text = chunk['choices'][0]['text']
                await websocket.send(json.dumps({
                    'type': 'token',
                    'data': text
                }))
            
            # Send completion message
            await websocket.send(json.dumps({
                'type': 'done'
            }))
    
    except websockets.exceptions.ConnectionClosed:
        print("Connection closed")

# Start WebSocket server
start_server = websockets.serve(stream_handler, "localhost", 8765)

asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()
```

### UI Integration

Displaying streaming text in user interfaces.

**JavaScript client (Server-Sent Events)**:

```javascript
const streamEndpoint = 'http://localhost:5000/generate/stream';
const outputDiv = document.getElementById('output');

function streamGeneration(prompt) {
    outputDiv.textContent = '';
    
    fetch(streamEndpoint, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            prompt: prompt,
            max_tokens: 512
        })
    })
    .then(response => {
        const reader = response.body.getReader();
        const decoder = new TextDecoder();
        
        function readChunk() {
            reader.read().then(({ done, value }) => {
                if (done) {
                    console.log('Stream complete');
                    return;
                }
                
                const chunk = decoder.decode(value);
                const lines = chunk.split('\n');
                
                for (const line of lines) {
                    if (line.startsWith('data: ')) {
                        const data = line.substring(6);
                        
                        if (data === '[DONE]') {
                            return;
                        }
                        
                        try {
                            const json = JSON.parse(data);
                            outputDiv.textContent += json.text;
                        } catch (e) {
                            // Ignore parse errors
                        }
                    }
                }
                
                readChunk();
            });
        }
        
        readChunk();
    })
    .catch(error => {
        console.error('Error:', error);
        outputDiv.textContent = 'Error: ' + error.message;
    });
}

// Usage
streamGeneration('Write a story about AI');
```

**Python client**:

```python
import requests
import json

def stream_client(prompt, endpoint="http://localhost:5000/generate/stream"):
    """Client for streaming endpoint."""
    
    response = requests.post(
        endpoint,
        json={'prompt': prompt, 'max_tokens': 512},
        stream=True
    )
    
    for line in response.iter_lines():
        if line:
            decoded = line.decode('utf-8')
            if decoded.startswith('data: '):
                data = decoded[6:]
                
                if data == '[DONE]':
                    break
                
                try:
                    json_data = json.loads(data)
                    text = json_data.get('text', '')
                    print(text, end='', flush=True)
                except json.JSONDecodeError:
                    pass
    
    print()  # New line

# Usage
stream_client("Explain quantum computing")
```

## Performance Monitoring

### Inference Speed

Measuring and optimizing tokens per second for inference performance.

```python
import time
from typing import Dict, List
import statistics

class PerformanceMonitor:
    def __init__(self):
        self.measurements = []
    
    def measure_inference(self, llm, prompt: str, max_tokens: int = 256,
                         num_runs: int = 3) -> Dict:
        """Measure inference performance over multiple runs."""
        run_stats = []
        
        for run in range(num_runs):
            start_time = time.time()
            
            response = llm(
                prompt,
                max_tokens=max_tokens,
                stream=False
            )
            
            end_time = time.time()
            duration = end_time - start_time
            
            # Count tokens (approximate)
            generated_text = response['choices'][0]['text']
            token_count = len(generated_text.split())
            
            tokens_per_second = token_count / duration
            
            run_stats.append({
                'run': run + 1,
                'duration': duration,
                'tokens': token_count,
                'tokens_per_second': tokens_per_second
            })
        
        # Calculate statistics
        tps_values = [r['tokens_per_second'] for r in run_stats]
        
        results = {
            'runs': run_stats,
            'average_tps': statistics.mean(tps_values),
            'median_tps': statistics.median(tps_values),
            'std_dev': statistics.stdev(tps_values) if len(tps_values) > 1 else 0,
            'min_tps': min(tps_values),
            'max_tps': max(tps_values)
        }
        
        self.measurements.append(results)
        return results
    
    def print_results(self, results: Dict):
        """Print formatted performance results."""
        print("\n=== Performance Results ===")
        print(f"Average TPS: {results['average_tps']:.2f}")
        print(f"Median TPS: {results['median_tps']:.2f}")
        print(f"Std Dev: {results['std_dev']:.2f}")
        print(f"Range: {results['min_tps']:.2f} - {results['max_tps']:.2f}")
        print("\nIndividual runs:")
        for run in results['runs']:
            print(f"  Run {run['run']}: {run['tokens_per_second']:.2f} t/s "
                  f"({run['tokens']} tokens in {run['duration']:.2f}s)")

# Usage
monitor = PerformanceMonitor()
llm = Llama(model_path="./model.gguf", n_gpu_layers=35)

results = monitor.measure_inference(
    llm,
    prompt="Explain artificial intelligence",
    max_tokens=256,
    num_runs=5
)

monitor.print_results(results)
```

**Real-time performance tracking**:

```python
import time
from collections import deque
import threading

class RealtimePerformanceTracker:
    def __init__(self, window_size=100):
        self.window_size = window_size
        self.token_times = deque(maxlen=window_size)
        self.request_times = deque(maxlen=window_size)
        self.lock = threading.Lock()
    
    def record_inference(self, duration: float, tokens: int):
        """Record inference metrics."""
        with self.lock:
            tps = tokens / duration if duration > 0 else 0
            self.token_times.append(tps)
            self.request_times.append(duration)
    
    def get_current_stats(self) -> Dict:
        """Get current performance statistics."""
        with self.lock:
            if not self.token_times:
                return {'tps': 0, 'avg_duration': 0, 'num_samples': 0}
            
            return {
                'tps': statistics.mean(self.token_times),
                'avg_duration': statistics.mean(self.request_times),
                'num_samples': len(self.token_times),
                'min_tps': min(self.token_times),
                'max_tps': max(self.token_times)
            }
    
    def print_dashboard(self):
        """Print real-time performance dashboard."""
        stats = self.get_current_stats()
        print(f"\r TPS: {stats['tps']:.1f} | "
              f"Avg Duration: {stats['avg_duration']:.2f}s | "
              f"Samples: {stats['num_samples']}",
              end='', flush=True)

# Usage
tracker = RealtimePerformanceTracker()

for i in range(10):
    start = time.time()
    response = llm("Test prompt", max_tokens=100)
    duration = time.time() - start
    
    tokens = len(response['choices'][0]['text'].split())
    tracker.record_inference(duration, tokens)
    tracker.print_dashboard()
```

### Memory Usage

Tracking GPU and system memory consumption.

```python
import psutil
import torch
import GPUtil
from dataclasses import dataclass
from typing import List

@dataclass
class MemorySnapshot:
    timestamp: float
    ram_used_gb: float
    ram_available_gb: float
    vram_used_gb: List[float]
    vram_total_gb: List[float]

class MemoryMonitor:
    def __init__(self):
        self.snapshots = []
    
    def get_ram_usage(self) -> tuple:
        """Get current RAM usage."""
        memory = psutil.virtual_memory()
        used_gb = memory.used / (1024 ** 3)
        available_gb = memory.available / (1024 ** 3)
        return used_gb, available_gb
    
    def get_vram_usage(self) -> tuple:
        """Get VRAM usage for all GPUs."""
        vram_used = []
        vram_total = []
        
        if torch.cuda.is_available():
            for i in range(torch.cuda.device_count()):
                allocated = torch.cuda.memory_allocated(i) / (1024 ** 3)
                total = torch.cuda.get_device_properties(i).total_memory / (1024 ** 3)
                vram_used.append(allocated)
                vram_total.append(total)
        
        return vram_used, vram_total
    
    def take_snapshot(self) -> MemorySnapshot:
        """Capture current memory state."""
        ram_used, ram_available = self.get_ram_usage()
        vram_used, vram_total = self.get_vram_usage()
        
        snapshot = MemorySnapshot(
            timestamp=time.time(),
            ram_used_gb=ram_used,
            ram_available_gb=ram_available,
            vram_used_gb=vram_used,
            vram_total_gb=vram_total
        )
        
        self.snapshots.append(snapshot)
        return snapshot
    
    def print_snapshot(self, snapshot: MemorySnapshot):
        """Print formatted memory snapshot."""
        print(f"\n=== Memory Snapshot ===")
        print(f"RAM: {snapshot.ram_used_gb:.2f}GB used, "
              f"{snapshot.ram_available_gb:.2f}GB available")
        
        for i, (used, total) in enumerate(zip(snapshot.vram_used_gb,
                                               snapshot.vram_total_gb)):
            percentage = (used / total) * 100 if total > 0 else 0
            print(f"GPU {i}: {used:.2f}GB / {total:.2f}GB ({percentage:.1f}%)")
    
    def monitor_loading(self, load_function, *args, **kwargs):
        """Monitor memory during model loading."""
        print("Before loading:")
        before = self.take_snapshot()
        self.print_snapshot(before)
        
        # Load model
        result = load_function(*args, **kwargs)
        
        print("\nAfter loading:")
        after = self.take_snapshot()
        self.print_snapshot(after)
        
        # Calculate delta
        ram_delta = after.ram_used_gb - before.ram_used_gb
        print(f"\nRAM increase: {ram_delta:.2f}GB")
        
        for i in range(len(after.vram_used_gb)):
            vram_delta = after.vram_used_gb[i] - before.vram_used_gb[i]
            print(f"GPU {i} VRAM increase: {vram_delta:.2f}GB")
        
        return result

# Usage
monitor = MemoryMonitor()

def load_model():
    return Llama(model_path="./model.gguf", n_gpu_layers=35)

llm = monitor.monitor_loading(load_model)
```

### Temperature Monitoring

Monitoring hardware temperatures during inference.

```python
import GPUtil
import time
from threading import Thread, Event

class TemperatureMonitor:
    def __init__(self, interval=1.0, warn_temp=80, critical_temp=90):
        self.interval = interval
        self.warn_temp = warn_temp
        self.critical_temp = critical_temp
        self.is_monitoring = False
        self.monitor_thread = None
        self.stop_event = Event()
        self.temperature_history = []
    
    def get_gpu_temps(self) -> List[float]:
        """Get current GPU temperatures."""
        gpus = GPUtil.getGPUs()
        return [gpu.temperature for gpu in gpus]
    
    def start_monitoring(self):
        """Start temperature monitoring thread."""
        self.is_monitoring = True
        self.stop_event.clear()
        self.monitor_thread = Thread(target=self._monitor_loop, daemon=True)
        self.monitor_thread.start()
        print("Temperature monitoring started")
    
    def stop_monitoring(self):
        """Stop temperature monitoring."""
        self.is_monitoring = False
        self.stop_event.set()
        if self.monitor_thread:
            self.monitor_thread.join()
        print("Temperature monitoring stopped")
    
    def _monitor_loop(self):
        """Monitoring loop."""
        while not self.stop_event.is_set():
            temps = self.get_gpu_temps()
            self.temperature_history.append({
                'timestamp': time.time(),
                'temperatures': temps
            })
            
            # Check for warnings
            for i, temp in enumerate(temps):
                if temp >= self.critical_temp:
                    print(f"\n⚠️ CRITICAL: GPU {i} temperature: {temp}°C")
                elif temp >= self.warn_temp:
                    print(f"\n⚠️ WARNING: GPU {i} temperature: {temp}°C")
            
            time.sleep(self.interval)
    
    def get_stats(self) -> Dict:
        """Get temperature statistics."""
        if not self.temperature_history:
            return {}
        
        all_temps = []
        for entry in self.temperature_history:
            all_temps.extend(entry['temperatures'])
        
        return {
            'current': self.get_gpu_temps(),
            'average': statistics.mean(all_temps),
            'max': max(all_temps),
            'min': min(all_temps),
            'samples': len(self.temperature_history)
        }

# Usage
temp_monitor = TemperatureMonitor(interval=2.0, warn_temp=80, critical_temp=90)
temp_monitor.start_monitoring()

# Run inference
for i in range(10):
    response = llm("Test prompt", max_tokens=200)
    time.sleep(1)

temp_monitor.stop_monitoring()
stats = temp_monitor.get_stats()
print(f"\nTemperature stats: {stats}")
```

### Logging

Comprehensive performance and error logging.

```python
import logging
import json
from datetime import datetime
from pathlib import Path

class InferenceLogger:
    def __init__(self, log_dir="logs"):
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(exist_ok=True)
        
        # Setup file logging
        log_file = self.log_dir / f"inference_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler()
            ]
        )
        
        self.logger = logging.getLogger('InferenceLogger')
        self.metrics_file = self.log_dir / "metrics.jsonl"
    
    def log_inference(self, prompt: str, response: str, duration: float,
                     tokens: int, **kwargs):
        """Log inference details."""
        self.logger.info(
            f"Inference - Tokens: {tokens}, Duration: {duration:.2f}s, "
            f"TPS: {tokens/duration:.1f}"
        )
        
        # Write detailed metrics
        metrics = {
            'timestamp': datetime.now().isoformat(),
            'prompt_length': len(prompt),
            'response_length': len(response),
            'duration': duration,
            'tokens': tokens,
            'tokens_per_second': tokens / duration,
            **kwargs
        }
        
        with open(self.metrics_file, 'a') as f:
            f.write(json.dumps(metrics) + '\n')
    
    def log_error(self, error: Exception, context: Dict = None):
        """Log error with context."""
        self.logger.error(f"Error: {str(error)}", exc_info=True)
        
        if context:
            self.logger.error(f"Context: {json.dumps(context)}")
    
    def log_model_load(self, model_path: str, config: Dict, duration: float):
        """Log model loading."""
        self.logger.info(
            f"Model loaded: {model_path} in {duration:.2f}s\n"
            f"Config: {json.dumps(config)}"
        )

# Usage
logger = InferenceLogger()

# Log model loading
start = time.time()
llm = Llama(model_path="./model.gguf", n_gpu_layers=35)
duration = time.time() - start
logger.log_model_load(
    "./model.gguf",
    {'n_gpu_layers': 35, 'n_ctx': 2048},
    duration
)

# Log inference
start = time.time()
response = llm("Test prompt", max_tokens=256)
duration = time.time() - start
logger.log_inference(
    prompt="Test prompt",
    response=response['choices'][0]['text'],
    duration=duration,
    tokens=256,
    temperature=0.7,
    model="llama-2-7b"
)
```

## Error Handling

### Out of Memory

Handling OOM errors gracefully with fallback strategies.

```python
import torch
import gc
from typing import Optional

class OOMHandler:
    def __init__(self, model_path: str):
        self.model_path = model_path
        self.current_config = None
        self.llm = None
    
    def load_with_fallback(self, initial_gpu_layers=35):
        """Try loading with decreasing GPU layers until success."""
        configs_to_try = [
            {'n_gpu_layers': initial_gpu_layers, 'n_ctx': 2048, 'n_batch': 512},
            {'n_gpu_layers': initial_gpu_layers // 2, 'n_ctx': 2048, 'n_batch': 512},
            {'n_gpu_layers': initial_gpu_layers // 4, 'n_ctx': 1024, 'n_batch': 256},
            {'n_gpu_layers': 0, 'n_ctx': 1024, 'n_batch': 256},  # CPU fallback
        ]
        
        for config in configs_to_try:
            try:
                print(f"Attempting load with config: {config}")
                self.llm = Llama(
                    model_path=self.model_path,
                    **config
                )
                self.current_config = config
                print(f"✅ Successfully loaded with: {config}")
                return self.llm
            
            except RuntimeError as e:
                if "out of memory" in str(e).lower():
                    print(f"❌ OOM with config: {config}")
                    self.cleanup_memory()
                    continue
                else:
                    raise
        
        raise RuntimeError("Failed to load model with all fallback configurations")
    
    def cleanup_memory(self):
        """Free GPU and system memory."""
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
            torch.cuda.ipc_collect()
        gc.collect()
    
    def generate_with_retry(self, prompt: str, max_retries=3, **kwargs):
        """Generate with OOM retry logic."""
        for attempt in range(max_retries):
            try:
                return self.llm(prompt, **kwargs)
            
            except RuntimeError as e:
                if "out of memory" in str(e).lower() and attempt < max_retries - 1:
                    print(f"OOM during generation (attempt {attempt + 1}), retrying...")
                    
                    # Reduce batch size if possible
                    if 'n_batch' in kwargs:
                        kwargs['n_batch'] = kwargs['n_batch'] // 2
                    
                    # Reduce context if possible
                    if 'max_tokens' in kwargs:
                        kwargs['max_tokens'] = min(kwargs['max_tokens'], 256)
                    
                    self.cleanup_memory()
                    time.sleep(1)
                    continue
                else:
                    raise
        
        raise RuntimeError("Failed to generate after all retries")

# Usage
handler = OOMHandler("./large-model.gguf")
llm = handler.load_with_fallback(initial_gpu_layers=40)

response = handler.generate_with_retry(
    "Explain AI",
    max_tokens=512,
    temperature=0.7
)
```

### Timeout Management

Handling slow responses with timeouts.

```python
import signal
from contextlib import contextmanager
import threading

class TimeoutError(Exception):
    pass

class GenerationTimeout:
    """Handle generation timeouts."""
    
    @staticmethod
    @contextmanager
    def time_limit(seconds):
        """Context manager for timeout."""
        def signal_handler(signum, frame):
            raise TimeoutError(f"Generation exceeded {seconds}s timeout")
        
        signal.signal(signal.SIGALRM, signal_handler)
        signal.alarm(seconds)
        try:
            yield
        finally:
            signal.alarm(0)
    
    @staticmethod
    def generate_with_timeout(llm, prompt: str, timeout_seconds=30, **kwargs):
        """Generate with timeout limit."""
        result = {'response': None, 'error': None, 'timed_out': False}
        
        def generate():
            try:
                result['response'] = llm(prompt, **kwargs)
            except Exception as e:
                result['error'] = e
        
        thread = threading.Thread(target=generate)
        thread.start()
        thread.join(timeout=timeout_seconds)
        
        if thread.is_alive():
            result['timed_out'] = True
            # Note: Can't actually kill the thread, but we can stop waiting
            return None, True
        
        if result['error']:
            raise result['error']
        
        return result['response'], False

# Usage
from generation_timeout import GenerationTimeout

try:
    response, timed_out = GenerationTimeout.generate_with_timeout(
        llm,
        "Write a very long story",
        timeout_seconds=30,
        max_tokens=2048
    )
    
    if timed_out:
        print("Generation timed out, using fallback")
        # Use cached response or shorter prompt
    else:
        print(f"Response: {response['choices'][0]['text']}")

except Exception as e:
    print(f"Error: {e}")
```

### Model Failures

Recovery strategies for model failures.

```python
import time
from enum import Enum
from dataclasses import dataclass
from typing import Optional, Callable

class FailureType(Enum):
    OOM = "out_of_memory"
    TIMEOUT = "timeout"
    MODEL_ERROR = "model_error"
    NETWORK = "network"
    UNKNOWN = "unknown"

@dataclass
class FailureStrategy:
    max_retries: int = 3
    retry_delay: float = 1.0
    exponential_backoff: bool = True
    fallback_model: Optional[str] = None
    cache_responses: bool = True

class RobustInferenceEngine:
    def __init__(self, model_path: str, strategy: FailureStrategy = None):
        self.model_path = model_path
        self.strategy = strategy or FailureStrategy()
        self.llm = None
        self.response_cache = {}
        self.failure_count = 0
    
    def load_model(self):
        """Load model with retry."""
        for attempt in range(self.strategy.max_retries):
            try:
                self.llm = Llama(
                    model_path=self.model_path,
                    n_gpu_layers=35,
                    n_ctx=2048
                )
                return True
            
            except Exception as e:
                print(f"Load attempt {attempt + 1} failed: {e}")
                if attempt < self.strategy.max_retries - 1:
                    delay = self.strategy.retry_delay * (2 ** attempt) if self.strategy.exponential_backoff else self.strategy.retry_delay
                    time.sleep(delay)
                else:
                    return False
        
        return False
    
    def classify_error(self, error: Exception) -> FailureType:
        """Classify error type."""
        error_str = str(error).lower()
        
        if "out of memory" in error_str or "oom" in error_str:
            return FailureType.OOM
        elif "timeout" in error_str:
            return FailureType.TIMEOUT
        elif "model" in error_str or "inference" in error_str:
            return FailureType.MODEL_ERROR
        elif "connection" in error_str or "network" in error_str:
            return FailureType.NETWORK
        else:
            return FailureType.UNKNOWN
    
    def generate(self, prompt: str, use_cache=True, **kwargs):
        """Generate with comprehensive error handling."""
        # Check cache first
        cache_key = f"{prompt}:{kwargs.get('max_tokens', 256)}"
        if use_cache and self.strategy.cache_responses and cache_key in self.response_cache:
            print("Using cached response")
            return self.response_cache[cache_key]
        
        last_error = None
        
        for attempt in range(self.strategy.max_retries):
            try:
                response = self.llm(prompt, **kwargs)
                
                # Cache successful response
                if self.strategy.cache_responses:
                    self.response_cache[cache_key] = response
                
                # Reset failure count on success
                self.failure_count = 0
                
                return response
            
            except Exception as e:
                last_error = e
                failure_type = self.classify_error(e)
                self.failure_count += 1
                
                print(f"Attempt {attempt + 1} failed ({failure_type.value}): {e}")
                
                # Apply recovery strategy based on failure type
                if failure_type == FailureType.OOM:
                    if torch.cuda.is_available():
                        torch.cuda.empty_cache()
                    gc.collect()
                    # Reduce parameters
                    if 'max_tokens' in kwargs:
                        kwargs['max_tokens'] = min(kwargs['max_tokens'], 128)
                
                elif failure_type == FailureType.MODEL_ERROR:
                    # Try reloading model
                    if self.failure_count >= 3:
                        print("Too many failures, reloading model...")
                        self.load_model()
                        self.failure_count = 0
                
                # Exponential backoff
                if attempt < self.strategy.max_retries - 1:
                    delay = self.strategy.retry_delay * (2 ** attempt) if self.strategy.exponential_backoff else self.strategy.retry_delay
                    time.sleep(delay)
        
        # All retries failed
        if self.strategy.fallback_model and self.failure_count > 5:
            print(f"Switching to fallback model: {self.strategy.fallback_model}")
            self.model_path = self.strategy.fallback_model
            self.load_model()
            return self.generate(prompt, use_cache=False, **kwargs)
        
        raise last_error

# Usage
strategy = FailureStrategy(
    max_retries=3,
    retry_delay=2.0,
    exponential_backoff=True,
    fallback_model="./smaller-model.gguf",
    cache_responses=True
)

engine = RobustInferenceEngine("./model.gguf", strategy=strategy)
engine.load_model()

try:
    response = engine.generate(
        "Explain quantum computing",
        max_tokens=512,
        temperature=0.7
    )
    print(response['choices'][0]['text'])

except Exception as e:
    print(f"Fatal error after all retries: {e}")
```

## Session Management

### Persistence

Saving and loading conversation sessions.

```python
import json
import pickle
from pathlib import Path
from datetime import datetime
from typing import List, Dict

class SessionManager:
    def __init__(self, session_dir="sessions"):
        self.session_dir = Path(session_dir)
        self.session_dir.mkdir(exist_ok=True)
        self.current_session = {
            'id': None,
            'created': None,
            'messages': [],
            'metadata': {}
        }
    
    def create_session(self, metadata: Dict = None):
        """Create new session."""
        session_id = datetime.now().strftime('%Y%m%d_%H%M%S')
        self.current_session = {
            'id': session_id,
            'created': datetime.now().isoformat(),
            'messages': [],
            'metadata': metadata or {}
        }
        return session_id
    
    def add_message(self, role: str, content: str):
        """Add message to current session."""
        self.current_session['messages'].append({
            'role': role,
            'content': content,
            'timestamp': datetime.now().isoformat()
        })
    
    def save_session(self, session_id: str = None):
        """Save session to disk."""
        sid = session_id or self.current_session['id']
        if not sid:
            raise ValueError("No session ID")
        
        session_file = self.session_dir / f"{sid}.json"
        with open(session_file, 'w') as f:
            json.dump(self.current_session, f, indent=2)
        
        print(f"Session saved: {session_file}")
    
    def load_session(self, session_id: str):
        """Load session from disk."""
        session_file = self.session_dir / f"{session_id}.json"
        
        if not session_file.exists():
            raise FileNotFoundError(f"Session not found: {session_id}")
        
        with open(session_file, 'r') as f:
            self.current_session = json.load(f)
        
        print(f"Session loaded: {session_id}")
        return self.current_session
    
    def list_sessions(self) -> List[str]:
        """List all saved sessions."""
        return [f.stem for f in self.session_dir.glob("*.json")]
    
    def delete_session(self, session_id: str):
        """Delete session."""
        session_file = self.session_dir / f"{session_id}.json"
        if session_file.exists():
            session_file.unlink()
            print(f"Session deleted: {session_id}")

# Usage
manager = SessionManager()
session_id = manager.create_session(metadata={'user': 'john', 'topic': 'AI'})

manager.add_message('user', 'What is AI?')
manager.add_message('assistant', 'Artificial Intelligence is...')

manager.save_session()

# Later, load the session
manager.load_session(session_id)
print(f"Loaded {len(manager.current_session['messages'])} messages")
```

### State Management

Managing application state across sessions.

```python
class StatefulChatbot:
    def __init__(self, llm, session_manager):
        self.llm = llm
        self.session_manager = session_manager
        self.state = {
            'user_preferences': {},
            'conversation_context': [],
            'active_tasks': []
        }
    
    def chat(self, user_message: str):
        """Chat with state management."""
        # Add to session
        self.session_manager.add_message('user', user_message)
        
        # Build prompt with state
        prompt = self._build_stateful_prompt(user_message)
        
        # Generate response
        response = self.llm(prompt, max_tokens=512, temperature=0.7)
        assistant_message = response['choices'][0]['text'].strip()
        
        # Update state
        self._update_state(user_message, assistant_message)
        
        # Add to session
        self.session_manager.add_message('assistant', assistant_message)
        
        return assistant_message
    
    def _build_stateful_prompt(self, message: str) -> str:
        """Build prompt including state."""
        prompt = "Context:\n"
        
        if self.state['user_preferences']:
            prompt += f"User preferences: {self.state['user_preferences']}\n"
        
        if self.state['conversation_context']:
            recent = self.state['conversation_context'][-3:]
            prompt += f"Recent topics: {', '.join(recent)}\n"
        
        prompt += f"\nUser: {message}\nAssistant:"
        return prompt
    
    def _update_state(self, user_msg: str, assistant_msg: str):
        """Update internal state."""
        # Extract topics (simplified)
        if len(user_msg.split()) > 3:
            self.state['conversation_context'].append(user_msg[:50])
        
        # Keep only recent context
        if len(self.state['conversation_context']) > 10:
            self.state['conversation_context'] = self.state['conversation_context'][-10:]

# Usage
llm = Llama(model_path="./model.gguf", n_gpu_layers=35)
manager = SessionManager()
bot = StatefulChatbot(llm, manager)

bot.chat("Hello!")
bot.chat("What can you help me with?")
```

### Cleanup

Proper resource deallocation.

```python
import atexit

class ManagedInferenceEngine:
    def __init__(self, model_path: str):
        self.model_path = model_path
        self.llm = None
        self.resources = []
        
        # Register cleanup on exit
        atexit.register(self.cleanup)
    
    def __enter__(self):
        """Context manager entry."""
        self.llm = Llama(
            model_path=self.model_path,
            n_gpu_layers=35
        )
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        self.cleanup()
    
    def cleanup(self):
        """Clean up resources."""
        print("Cleaning up resources...")
        
        # Delete model
        if self.llm is not None:
            del self.llm
            self.llm = None
        
        # Clear GPU memory
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
            torch.cuda.ipc_collect()
        
        # Garbage collection
        gc.collect()
        
        print("Cleanup complete")

# Usage with context manager
with ManagedInferenceEngine("./model.gguf") as engine:
    response = engine.llm("Test prompt", max_tokens=256)
    print(response)
# Automatic cleanup on exit
```

## Integration Patterns

### REST API Server

Production-ready API server implementation.

```python
from flask import Flask, request, jsonify
from flask_cors import CORS
import logging

app = Flask(__name__)
CORS(app)

# Initialize model
llm = Llama(model_path="./model.gguf", n_gpu_layers=35)

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint."""
    return jsonify({'status': 'healthy', 'model': 'loaded'})

@app.route('/generate', methods=['POST'])
def generate():
    """Generation endpoint."""
    try:
        data = request.json
        prompt = data.get('prompt', '')
        max_tokens = data.get('max_tokens', 256)
        temperature = data.get('temperature', 0.7)
        
        if not prompt:
            return jsonify({'error': 'No prompt provided'}), 400
        
        response = llm(
            prompt,
            max_tokens=max_tokens,
            temperature=temperature
        )
        
        return jsonify({
            'text': response['choices'][0]['text'],
            'tokens': len(response['choices'][0]['text'].split())
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, threaded=True)
```

### WebSocket Connections

Real-time bidirectional communication.

```python
import asyncio
import websockets
import json

async def chat_handler(websocket, path):
    """Handle WebSocket chat connections."""
    print(f"Client connected: {websocket.remote_address}")
    
    try:
        async for message in websocket:
            data = json.loads(message)
            
            if data['type'] == 'generate':
                prompt = data['prompt']
                
                # Stream response
                for chunk in llm(prompt, max_tokens=512, stream=True):
                    await websocket.send(json.dumps({
                        'type': 'token',
                        'text': chunk['choices'][0]['text']
                    }))
                
                await websocket.send(json.dumps({'type': 'done'}))
    
    except websockets.exceptions.ConnectionClosed:
        print(f"Client disconnected: {websocket.remote_address}")

start_server = websockets.serve(chat_handler, "localhost", 8765)
asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()
```

### Message Queues

Async processing with message queues.

```python
import pika
import json

def callback(ch, method, properties, body):
    """Process message from queue."""
    data = json.loads(body)
    prompt = data['prompt']
    
    response = llm(prompt, max_tokens=256)
    
    result = {
        'request_id': data['request_id'],
        'response': response['choices'][0]['text']
    }
    
    # Publish result
    ch.basic_publish(
        exchange='',
        routing_key='responses',
        body=json.dumps(result)
    )
    
    ch.basic_ack(delivery_tag=method.delivery_tag)

# Connect to RabbitMQ
connection = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
channel = connection.channel()
channel.queue_declare(queue='requests')
channel.basic_consume(queue='requests', on_message_callback=callback)

print('Waiting for messages...')
channel.start_consuming()
```

## CLI Tools

### Ollama Commands

Comprehensive Ollama CLI usage.

```bash
# Run model
ollama run llama3.2:3b "Explain AI"

# List models
ollama list

# Pull model
ollama pull mistral:7b

# Remove model
ollama rm llama2:7b

# Show model info
ollama show llama3.2:3b

# Create custom model from Modelfile
ollama create mymodel -f Modelfile
```

### llama.cpp Usage

Advanced llama.cpp options.

```bash
# Basic usage
./main -m model.gguf -p "Prompt" -n 256

# GPU acceleration
./main -m model.gguf -ngl 35 -p "Prompt"

# Interactive mode
./main -m model.gguf -i --interactive-first

# Conversation mode
./main -m model.gguf -i --reverse-prompt "User:"

# With specific parameters
./main -m model.gguf \
  -p "Prompt" \
  -n 512 \
  -c 2048 \
  --temp 0.7 \
  --top-p 0.9 \
  --repeat-penalty 1.1
```

### Custom Scripts

Building custom CLI tools.

```python
import argparse
from llama_cpp import Llama

def main():
    parser = argparse.ArgumentParser(description='Local LLM CLI')
    parser.add_argument('prompt', help='Prompt text')
    parser.add_argument('--model', required=True, help='Model path')
    parser.add_argument('--tokens', type=int, default=256)
    parser.add_argument('--temp', type=float, default=0.7)
    parser.add_argument('--stream', action='store_true')
    
    args = parser.parse_args()
    
    llm = Llama(model_path=args.model, n_gpu_layers=35)
    
    if args.stream:
        for chunk in llm(args.prompt, max_tokens=args.tokens, 
                        temperature=args.temp, stream=True):
            print(chunk['choices'][0]['text'], end='', flush=True)
        print()
    else:
        response = llm(args.prompt, max_tokens=args.tokens, temperature=args.temp)
        print(response['choices'][0]['text'])

if __name__ == '__main__':
    main()
```

## Automation

### Scheduled Inference

Automated periodic tasks.

```python
import schedule
import time

def daily_summary():
    """Generate daily summary."""
    prompt = "Generate a summary of today's tasks"
    response = llm(prompt, max_tokens=512)
    
    with open(f'summary_{date.today()}.txt', 'w') as f:
        f.write(response['choices'][0]['text'])

# Schedule daily at 6 PM
schedule.every().day.at("18:00").do(daily_summary)

while True:
    schedule.run_pending()
    time.sleep(60)
```

### Batch Jobs

Bulk processing automation.

```python
import glob
import json

def process_batch_file(input_file: str, output_file: str):
    """Process batch of prompts from file."""
    with open(input_file, 'r') as f:
        prompts = [line.strip() for line in f if line.strip()]
    
    results = []
    for i, prompt in enumerate(prompts):
        print(f"Processing {i+1}/{len(prompts)}...")
        response = llm(prompt, max_tokens=256)
        results.append({
            'prompt': prompt,
            'response': response['choices'][0]['text']
        })
    
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2)

# Process all input files
for input_file in glob.glob('input/*.txt'):
    output_file = f"output/{Path(input_file).stem}_results.json"
    process_batch_file(input_file, output_file)
```

### Monitoring Scripts

Health checks and monitoring.

```python
import time
import smtplib
from email.message import EmailMessage

def check_model_health(llm):
    """Health check with alert."""
    try:
        start = time.time()
        response = llm("Test", max_tokens=10)
        duration = time.time() - start
        
        if duration > 30:  # Slow response
            send_alert(f"Slow inference: {duration:.2f}s")
        
        return True
    except Exception as e:
        send_alert(f"Model failure: {str(e)}")
        return False

def send_alert(message: str):
    """Send email alert."""
    msg = EmailMessage()
    msg['Subject'] = 'LLM Alert'
    msg['From'] = 'monitor@example.com'
    msg['To'] = 'admin@example.com'
    msg.set_content(message)
    
    with smtplib.SMTP('localhost') as s:
        s.send_message(msg)

# Monitor every 5 minutes
while True:
    check_model_health(llm)
    time.sleep(300)
```

## Best Practices

### Resource Management

- Load models once and reuse instances
- Use context managers for automatic cleanup
- Monitor memory usage and implement limits
- Implement graceful degradation strategies
- Use lazy loading when possible

### Error Handling Strategies

- Implement retry logic with exponential backoff
- Classify errors and handle appropriately
- Provide fallback options for critical paths
- Log errors with context for debugging
- Use circuit breakers for repeated failures

### Logging and Monitoring

- Log all inferences with timing metrics
- Track token usage and costs
- Monitor GPU temperature and utilization
- Set up alerts for anomalies
- Maintain performance baselines

## Common Workflows

### Development Workflow

1. Load model with optimal parameters
2. Test with various prompts
3. Monitor performance metrics
4. Adjust parameters based on results
5. Implement error handling
6. Add logging and monitoring
7. Test edge cases
8. Deploy to production

### Production Workflow

1. Initialize model with production config
2. Implement health checks
3. Set up request queue
4. Enable streaming for responsiveness
5. Monitor resource usage
6. Log all requests and responses
7. Implement graceful degradation
8. Set up alerting
9. Regular performance reviews
10. Optimize based on metrics
