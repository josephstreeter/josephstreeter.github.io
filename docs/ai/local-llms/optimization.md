---
title: "Optimization Techniques for Local LLMs"
description: "Methods to improve performance, speed, and efficiency of local LLMs"
author: "Joseph Streeter"
ms.date: "2025-12-31"
ms.topic: "guide"
keywords: ["optimization", "performance", "quantization", "efficiency", "tuning"]
uid: docs.ai.local-llms.optimization
---

## Overview

Optimization of local Large Language Models (LLMs) is critical for practical deployment, especially when working with consumer hardware constraints. This comprehensive guide explores proven techniques to maximize inference speed, reduce memory footprint, and improve overall efficiency while maintaining acceptable output quality.

Local LLM optimization involves multiple interconnected dimensions:

- **Model-level optimizations**: Quantization, pruning, and distillation techniques that modify the model itself
- **Inference optimizations**: Runtime techniques like efficient attention mechanisms and batching strategies
- **Hardware optimizations**: Leveraging specific CPU, GPU, and accelerator capabilities
- **System-level optimizations**: Memory management, caching, and resource allocation strategies

The key challenge is balancing the trade-off triangle: **speed, quality, and resource usage**. Every optimization decision involves compromises, and the optimal configuration depends on your specific use case, hardware, and quality requirements.

## Quantization

### What is Quantization?

Quantization reduces the numerical precision of model weights and activations, typically from 32-bit or 16-bit floating-point (FP32/FP16) to lower bit-width representations (8-bit, 4-bit, or even lower). This dramatically reduces model size and memory bandwidth requirements while enabling faster computation.

**Key benefits:**

- **Memory reduction**: 4-bit quantization reduces model size by ~75% compared to FP16
- **Faster inference**: Lower precision enables faster matrix operations on modern hardware
- **Broader accessibility**: Enables running larger models on consumer hardware

**Precision levels:**

- **FP16**: Minimal quality loss, 50% size reduction from FP32
- **INT8**: ~1-2% quality degradation, 75% size reduction
- **INT4**: 5-10% quality degradation, 87.5% size reduction
- **INT3/INT2**: Significant quality loss, mainly for research purposes

### Quantization Methods

#### GGUF (GPT-Generated Unified Format)

The modern standard for llama.cpp and compatible inference engines. GGUF supports multiple quantization schemes optimized for CPU inference:

```bash
# Common GGUF quantization types (ordered by quality/size):
Q2_K    # 2.5-2.8 bpw (bits per weight) - extremely compressed
Q3_K_S  # 3.4 bpw - small, good for chat models
Q3_K_M  # 3.5 bpw - medium, balanced
Q3_K_L  # 3.7 bpw - large, better quality
Q4_0    # 4.3 bpw - legacy 4-bit
Q4_K_S  # 4.3 bpw - small, improved
Q4_K_M  # 4.8 bpw - recommended for most use cases
Q5_K_S  # 5.3 bpw - minimal quality loss
Q5_K_M  # 5.6 bpw - high quality
Q6_K    # 6.6 bpw - very high quality
Q8_0    # 8.5 bpw - almost no quality loss
```

**K-quantization** variants use different quantization strategies for different layer types, preserving more precision in critical layers.

#### GPTQ (GPT Quantization)

Optimized for GPU inference with minimal accuracy loss. GPTQ uses calibration data to minimize quantization error:

```python
# Typical GPTQ configuration
from auto_gptq import AutoGPTQForCausalLM, BaseQuantizeConfig

quantize_config = BaseQuantizeConfig(
    bits=4,  # 4-bit quantization
    group_size=128,  # Quantization block size
    desc_act=False,  # Activation order optimization
    sym=True,  # Symmetric quantization
    damp_percent=0.01  # Dampening factor
)

model = AutoGPTQForCausalLM.from_pretrained(
    model_name,
    quantize_config=quantize_config
)
```

**Best for**: GPU inference with ExLlamaV2, transformers, or vLLM backends.

#### AWQ (Activation-aware Weight Quantization)

Preserves accuracy by protecting salient weights based on activation distributions:

```python
from awq import AutoAWQForCausalLM

# AWQ automatically identifies important weights
model = AutoAWQForCausalLM.from_pretrained(model_name)
model.quantize(tokenizer, quant_config={"zero_point": True, "q_group_size": 128})
```

**Advantages**: Often outperforms GPTQ at the same bit-width with better perplexity scores.

#### EXL2 (ExLlamaV2)

Variable bit-width quantization allowing mixed precision within a single model:

```python
# EXL2 supports configurations like 4.65 bpw by mixing quantization levels
# More precise control over size/quality tradeoff
```

### Quality vs Size Trade-offs

**Recommended quantization by use case:**

| Use Case               | Recommended      | Size (13B model) | Quality |
| ---------------------- | ---------------- | ---------------- | ------- |
| Production deployments | Q6_K, Q8_0       | 8-10 GB          | 99-100% |
| General purpose        | Q4_K_M, Q5_K_M   | 5-7 GB           | 95-98%  |
| Resource constrained   | Q3_K_M, Q4_K_S   | 3.5-5 GB         | 90-95%  |
| Extreme compression    | Q2_K, Q3_K_S     | 2.5-3.5 GB       | 80-90%  |

**Quality assessment metrics:**

- **Perplexity**: Lower is better (measures prediction accuracy)
- **Benchmark scores**: MMLU, HellaSwag, TruthfulQA
- **Subjective testing**: Real-world conversation quality

### Re-quantization

Converting between quantization formats to optimize for different deployment targets:

```bash
# Convert HuggingFace model to GGUF
python convert.py /path/to/model --outtype f16 --outfile model-f16.gguf

# Quantize GGUF to desired precision
./quantize model-f16.gguf model-Q4_K_M.gguf Q4_K_M

# Convert GPTQ to AWQ
python convert_gptq_to_awq.py --input gptq-model --output awq-model
```

**Important**: Always start from the highest precision available (preferably FP16) to minimize cumulative quantization error.

### Custom Quantization

Advanced users can create custom quantization schemes:

```python
# Example: Mixed precision quantization
layer_config = {
    "input_layernorm": "Q8_0",  # Keep normalization layers high precision
    "self_attn": "Q5_K_M",      # Attention weights moderately quantized
    "mlp": "Q4_K_M",            # MLP weights more aggressively quantized
    "output": "Q6_K"             # Output layer preserved
}
```

**Techniques:**

- **Per-layer quantization**: Different precision for different layers
- **Importance-based quantization**: Protect critical weights identified through analysis
- **Dynamic quantization**: Quantize activations at runtime based on their range

## Model Pruning

Pruning removes redundant or less important components from neural networks, reducing model size and computation requirements. Unlike quantization (which reduces precision), pruning reduces the model's structural complexity.

### Layer Pruning

Removing entire transformer layers can significantly reduce model size with minimal quality loss:

```python
# Example: Removing layers from a transformer model
import torch
from transformers import AutoModelForCausalLM

model = AutoModelForCausalLM.from_pretrained("model-name")

# Identify redundant layers through layer similarity analysis
layers_to_remove = [10, 15, 20]  # Example layer indices

# Remove layers
model.model.layers = torch.nn.ModuleList([
    layer for i, layer in enumerate(model.model.layers)
    if i not in layers_to_remove
])
```

**Research findings**: Studies show models can typically lose 10-20% of layers with <5% performance degradation. Middle layers are often most redundant.

**Identification strategies:**

- **Similarity analysis**: Measure layer output similarity to identify redundant transformations
- **Attribution analysis**: Use gradients to identify low-impact layers
- **Block pruning**: Remove groups of adjacent layers

### Attention Head Pruning

Multi-head attention mechanisms contain 16-96 heads per layer, many of which are redundant:

```python
# Prune attention heads based on importance scores
import torch.nn.utils.prune as prune

for layer in model.layers:
    # Calculate head importance (e.g., via gradient-based attribution)
    head_importance = calculate_head_importance(layer)
    
    # Prune least important heads
    heads_to_prune = head_importance.topk(k=8, largest=False).indices
    
    # Apply structured pruning
    prune_attention_heads(layer.self_attn, heads_to_prune)
```

**Benefits:**

- Reduces attention computation cost (O(n²) operations)
- Can remove 30-50% of heads with <3% quality loss
- Particularly effective for fine-tuned models

### Weight Pruning

Creating sparse models by setting small-magnitude weights to zero:

**Unstructured pruning** (general approach):

```python
import torch.nn.utils.prune as prune

# Remove 40% of smallest weights
prune.l1_unstructured(module, name='weight', amount=0.4)

# Make pruning permanent
prune.remove(module, 'weight')
```

**Structured pruning** (hardware-friendly):

```python
# Remove entire channels/filters
prune.ln_structured(
    module,
    name='weight',
    amount=0.3,
    n=2,  # L2 norm
    dim=0  # Prune output channels
)
```

**Pruning strategies:**

- **Magnitude-based**: Remove smallest weights
- **Movement pruning**: Consider weight magnitude changes during training
- **Lottery ticket hypothesis**: Find and train sparse subnetworks

**Sparsity patterns:**

- **Unstructured (random)**: Maximum flexibility, requires special kernels
- **Structured (N:M)**: NVIDIA A100+ support 2:4 sparsity natively
- **Block sparse**: Entire blocks set to zero for efficient computation

## Hardware Optimization

### GPU Settings

Maximizing GPU utilization for LLM inference:

**CUDA Optimizations:**

```bash
# Enable TF32 (Tensor Float 32) for faster computation on Ampere+ GPUs
export NVIDIA_TF32_OVERRIDE=1

# Use CUDA graphs for reduced kernel launch overhead
export CUDA_LAUNCH_BLOCKING=0

# Optimize memory allocator
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512,garbage_collection_threshold:0.8
```

**GPU memory optimization:**

```python
# Configure KV cache to use FP8 on H100 GPUs
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    device_map="auto",
    torch_dtype=torch.bfloat16,
    attn_implementation="flash_attention_2",
    use_cache=True
)

# Enable gradient checkpointing if fine-tuning
model.gradient_checkpointing_enable()
```

**Multi-GPU strategies:**

- **Tensor parallelism**: Split layers across GPUs (best for large batch sizes)
- **Pipeline parallelism**: Distribute layers across GPUs (better latency for small batches)
- **Hybrid approaches**: Combine strategies for optimal resource utilization

**GPU-specific optimizations:**

- **NVIDIA**: Use TensorRT-LLM for 2-4x faster inference
- **AMD**: ROCm optimization flags and MI250X/MI300 optimizations
- **Intel**: OneAPI and XPU backend optimizations

### CPU Optimizations

CPU inference can be competitive for smaller models with proper optimization:

**Threading configuration:**

```bash
# llama.cpp threading
./main -m model.gguf -t 12 --threads-batch 12

# Set optimal thread count (typically physical cores)
export OMP_NUM_THREADS=12
export MKL_NUM_THREADS=12
```

**Vectorization:**

```bash
# Build with CPU-specific optimizations
cmake -DLLAMA_NATIVE=ON  # Use -march=native
cmake -DLLAMA_AVX2=ON    # AVX2 support
cmake -DLLAMA_AVX512=ON  # AVX-512 (Xeon/newer chips)
cmake -DLLAMA_FMA=ON     # Fused multiply-add
```

**NUMA optimization** (multi-socket systems):

```bash
# Pin process to specific NUMA node
numactl --cpunodebind=0 --membind=0 ./main -m model.gguf

# Interleave memory across nodes
numactl --interleave=all ./main -m model.gguf
```

**Intel-specific:**

```bash
# Use Intel Extension for PyTorch
import intel_extension_for_pytorch as ipex
model = ipex.optimize(model, dtype=torch.bfloat16)
```

**AMD-specific:**

```bash
# Enable AMD μProf optimizations
export ATMI_MAX_THREADS=32
```

### Memory Management

Efficient memory usage is critical for running large models:

**Memory mapping** (mmap):

```python
# Load model weights using memory mapping (doesn't consume RAM until accessed)
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    device_map="auto",
    low_cpu_mem_usage=True,  # Use mmap when possible
    torch_dtype=torch.float16
)
```

**Offloading strategies:**

```python
# CPU offloading for models larger than VRAM
from accelerate import load_checkpoint_and_dispatch

model = load_checkpoint_and_dispatch(
    model,
    checkpoint_path,
    device_map="auto",
    offload_folder="offload",
    offload_state_dict=True,
    max_memory={0: "20GB", "cpu": "64GB"}  # GPU 0: 20GB, CPU: 64GB
)
```

**Paging and swap:**

```bash
# Configure swap for emergency overflow (not ideal for performance)
sudo swapon -s  # Check current swap

# Create swap file if needed (64GB example)
sudo fallocate -l 64G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Reduce swappiness to prefer RAM
sudo sysctl vm.swappiness=10
```

**KV cache management:**

```python
# Limit KV cache size to prevent OOM
generation_config = GenerationConfig(
    max_new_tokens=512,
    use_cache=True,
    cache_implementation="static",  # Fixed-size cache
)
```

### Power Management

Balancing performance with power consumption:

**GPU power settings:**

```bash
# Set power limit (example: limit RTX 4090 to 350W from 450W)
sudo nvidia-smi -pl 350

# Monitor power usage
watch -n 1 nvidia-smi --query-gpu=power.draw,temperature.gpu --format=csv

# Enable persistence mode (reduces latency)
sudo nvidia-smi -pm 1
```

**CPU power profiles:**

```bash
# Set performance governor (Linux)
sudo cpupower frequency-set -g performance

# Set balanced mode
sudo cpupower frequency-set -g powersave

# AMD Ryzen: Disable boost for consistent performance
echo 0 | sudo tee /sys/devices/system/cpu/cpufreq/boost
```

**Thermal management:**

```bash
# Monitor temperatures
sensors

# Set fan curves (NVIDIA)
nvidia-settings -a "[gpu:0]/GPUFanControlState=1" -a "[fan:0]/GPUTargetFanSpeed=75"
```

**Power-efficient inference:**

- Lower precision (INT4/INT8) reduces power consumption
- Smaller batch sizes reduce peak power
- Static batching more power-efficient than dynamic

## Inference Optimization

### Batch Processing

Grouping multiple requests together to maximize hardware utilization:

**Static batching:**

```python
# Process multiple prompts simultaneously
prompts = [
    "Tell me about AI",
    "Explain quantum computing", 
    "What is machine learning"
]

# Batch inference
inputs = tokenizer(prompts, padding=True, return_tensors="pt")
outputs = model.generate(**inputs, max_new_tokens=100)
```

**Benefits:**

- Amortizes fixed costs (model loading, memory allocation) across requests
- Better GPU utilization through parallel computation
- 2-5x throughput improvement for batch sizes of 8-32

**Trade-offs:**

- Increases latency for individual requests
- Requires sufficient VRAM for KV cache of all requests
- Padding overhead for variable-length sequences

### KV Cache Optimization

The Key-Value cache stores computed attention keys/values to avoid recomputation:

**Multi-Query Attention (MQA):**

```python
# Instead of separate KV for each head, share across heads
# Reduces KV cache size by factor of num_heads
# Used in: Falcon, MPT, StarCoder
```

**Grouped-Query Attention (GQA):**

```python
# Middle ground: Share KV across groups of heads
# Llama 2 70B uses GQA with 8 groups
# Better quality than MQA, still significant memory savings
```

**KV cache quantization:**

```python
# Quantize KV cache to INT8 or FP8
generation_config = GenerationConfig(
    cache_implementation="quantized",
    cache_config={"backend": "quanto", "nbits": 4}
)
```

**Benefits:** 4-bit KV cache reduces memory by 75%, enabling 4x longer contexts

### Flash Attention

Memory-efficient attention implementation that reduces memory from O(n²) to O(n):

```python
# Enable Flash Attention 2
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    attn_implementation="flash_attention_2",
    torch_dtype=torch.bfloat16
)
```

**Advantages:**

- 2-4x faster attention computation
- 10-20x lower memory usage
- Enables much longer context windows
- Available for CUDA GPUs with compute capability ≥8.0 (A100, RTX 30/40 series)

**Alternatives:**

- **xformers**: Memory-efficient attention for older GPUs
- **FlashAttention-3**: Latest version with additional optimizations
- **PagedAttention**: Used in vLLM for efficient memory management

### Continuous Batching

Dynamic batching that adds/removes requests as they complete:

```python
# vLLM example with continuous batching
from vllm import LLM, SamplingParams

llm = LLM(model="meta-llama/Llama-2-7b-hf")

# Requests processed dynamically as they arrive/complete
prompts = ["Prompt 1", "Prompt 2", "Prompt 3"]
sampling_params = SamplingParams(temperature=0.8, top_p=0.95)

outputs = llm.generate(prompts, sampling_params)
```

**Benefits:**

- Maximizes GPU utilization vs static batching
- Lower average latency compared to waiting for full batch
- Automatically handles variable generation lengths
- 2-3x better throughput than static batching for production workloads

## Compilation Optimizations

### TensorRT

NVIDIA's optimization toolkit for production AI deployments:

**TensorRT-LLM** for LLM inference:

```python
# Build optimized engine
import tensorrt_llm
from tensorrt_llm import Builder

builder = Builder()
network = builder.create_network()
# Configure model with FP16, INT8, or INT4 precision
network.add_model(model_path, precision='fp16')

# Build optimized engine
engine = builder.build_engine(network, builder_config)

# Run inference 2-4x faster than PyTorch
runtime = tensorrt_llm.Runtime(engine)
output = runtime.generate(input_ids)
```

**Optimizations applied:**

- Layer fusion (combine multiple operations)
- Kernel auto-tuning for specific GPU
- Precision calibration for mixed precision
- Memory layout optimization

**Best for:** Production deployments on NVIDIA GPUs requiring maximum throughput

### ONNX Runtime

Cross-platform optimization supporting CPU, GPU, and specialized accelerators:

```python
from optimum.onnxruntime import ORTModelForCausalLM

# Export and optimize model
model = ORTModelForCausalLM.from_pretrained(
    model_name,
    export=True,
    provider="CUDAExecutionProvider",  # or CPUExecutionProvider
    use_io_binding=True
)

# Automatic graph optimizations
# - Constant folding
# - Redundant node elimination
# - Operator fusion
```

**Supported backends:**

- CUDA (NVIDIA)
- ROCm (AMD)
- DirectML (Windows GPU)
- OpenVINO (Intel)
- CoreML (Apple Silicon)

### Model Compilation

Just-In-Time (JIT) and Ahead-of-Time (AOT) compilation:

**PyTorch 2.0 torch.compile:**

```python
import torch

model = AutoModelForCausalLM.from_pretrained(model_name)

# Compile model with TorchInductor
model = torch.compile(model, mode="max-autotune")

# First run compiles, subsequent runs are faster
output = model.generate(inputs)  # 1.5-2x speedup
```

**Compilation modes:**

- `default`: Balanced compilation (10-15% speedup)
- `reduce-overhead`: Minimize Python overhead (15-20% speedup)
- `max-autotune`: Aggressive optimization (20-40% speedup, longer compile time)

**AOT compilation benefits:**

- Eliminates Python interpreter overhead
- Better kernel fusion opportunities
- Static memory planning
- Particularly effective for repetitive workloads

## Context Management

### Context Window Optimization

Efficient handling of long context windows:

**Chunking strategies:**

```python
# Split long documents into manageable chunks
from langchain.text_splitter import RecursiveCharacterTextSplitter

splitter = RecursiveCharacterTextSplitter(
    chunk_size=2000,
    chunk_overlap=200,
    separators=["\n\n", "\n", " ", ""]
)

chunks = splitter.split_text(long_document)
```

**Selective context inclusion:**

- Use embeddings to retrieve only relevant chunks
- Prioritize recent conversation history
- Compress or summarize older context

**Context window sizes:**

| Model Series | Context Window | Memory (FP16) |
| ------------ | -------------- | ------------- |
| Llama 2      | 4K tokens      | ~8 GB         |
| Mistral      | 8K-32K tokens  | ~16-64 GB     |
| GPT-4        | 128K tokens    | ~256 GB       |
| Claude 3     | 200K tokens    | ~400 GB       |

### Sliding Window Attention

Efficiently manage attention for long sequences:

**Implementation:**

```python
# Mistral-style sliding window
# Each token attends to previous 4096 tokens only
attention_window = 4096

# Reduces memory from O(n²) to O(n * window_size)
```

**Benefits:**

- Linear memory growth instead of quadratic
- Enables processing arbitrarily long sequences
- Information propagates through multiple layers

**Variants:**

- **Fixed window**: Constant window size
- **Dilated attention**: Skip patterns for longer-range dependencies
- **Block-sparse attention**: Combine local and global attention

### Context Compression

Reduce token usage while preserving information:

**Automatic summarization:**

```python
# Compress older parts of conversation
def compress_context(messages, max_tokens=2000):
    if count_tokens(messages) > max_tokens:
        # Summarize oldest messages
        old_messages = messages[:-10]
        summary = summarize(old_messages)
        return [summary] + messages[-10:]
    return messages
```

**Prompt compression techniques:**

```python
# LongLLMLingua: Compress prompts by removing less important tokens
from llmlingua import PromptCompressor

compressor = PromptCompressor()
compressed_prompt = compressor.compress_prompt(
    original_prompt,
    target_token=200,  # Target length
    instruction="",
    question=""
)
# Achieves 2-10x compression with minimal quality loss
```

**Selective attention:**

- **H2O (Heavy-Hitter Oracle)**: Keep only most important KV pairs
- **StreamingLLM**: Maintain attention sinks + recent tokens
- Drop middle context, keep start + end

## Prompt Optimization

### Prompt Caching

Reuse computed representations for common prompt prefixes:

**System prompt caching:**

```python
# Anthropic Claude-style prompt caching
# Cache system instructions that don't change
response = client.messages.create(
    model="claude-3-opus-20240229",
    system=[
        {
            "type": "text",
            "text": long_system_instructions,
            "cache_control": {"type": "ephemeral"}
        }
    ],
    messages=[user_message]
)
# System prompt processed once, reused across requests
# 90% latency reduction for cached prefixes
```

**Implementation approaches:**

```python
# Manual prefix caching
cached_prefix_kvs = {}

def generate_with_cache(prompt, prefix="default_system"):
    if prefix not in cached_prefix_kvs:
        # Compute and cache KV for prefix
        cached_prefix_kvs[prefix] = model.compute_kv_cache(prefix_prompt)
    
    # Reuse cached KV, only process new tokens
    return model.generate(prompt, prefix_cache=cached_prefix_kvs[prefix])
```

**Best practices:**

- Cache static instructions, system prompts, and common few-shot examples
- Invalidate cache when prefix changes
- Monitor cache hit rates

### Prompt Compression

Reduce token count while maintaining effectiveness:

**Conciseness techniques:**

```python
# Original (72 tokens)
original = """
You are a helpful assistant. Please analyze the following text carefully and provide
a detailed summary that captures all the key points. Make sure to be thorough and
include all relevant information from the source material.
"""

# Compressed (23 tokens)
compressed = "Analyze and summarize the key points from the text:"

# 68% token reduction with equivalent results
```

**Structured formats:**

```python
# Use JSON for efficiency
prompt = {
    "task": "summarize",
    "constraints": ["max_length: 100", "style: formal"],
    "input": document
}
# Convert to string representation
```

**Token-efficient instructions:**

- Use abbreviations when unambiguous
- Eliminate redundant words
- Replace verbose explanations with examples
- Use bullet points instead of paragraphs

### Efficient Prompting

Minimize inference time through prompt engineering:

**Direct instructions:**

```python
# Inefficient: Forces model to generate longer explanation
"Explain your reasoning step by step, then provide the answer"

# Efficient: Get answer directly when reasoning not needed
"Answer: "
```

**Constrained generation:**

```python
# Limit output length
generation_config = GenerationConfig(
    max_new_tokens=50,  # Hard limit
    min_new_tokens=10,  # Ensure minimum response
)

# Use stop sequences
stop_sequences = ["\n\n", "---", "END"]
```

**Format optimization:**

```python
# Prefer structured formats that minimize tokens
output_format = {
    "classification": "positive|negative|neutral",
    "confidence": 0.0-1.0
}
# vs verbose: "The sentiment is positive with high confidence because..."
```

**Few-shot optimization:**

```python
# Use minimal but effective examples
# 2-3 examples often sufficient vs 5-10

examples = """
Q: What is 2+2? A: 4
Q: What is 5+3? A: 8
Q: What is 7+1? A:
"""
# Clear pattern established with minimal tokens
```

## Multi-Model Strategies

### Model Routing

Intelligently route requests to appropriate models based on complexity:

**Routing logic:**

```python
def route_request(prompt, complexity_threshold=0.7):
    # Fast classifier determines complexity
    complexity = estimate_complexity(prompt)
    
    if complexity < complexity_threshold:
        # Simple queries → small, fast model
        return small_model.generate(prompt)  # e.g., Llama 2 7B
    else:
        # Complex queries → large, capable model
        return large_model.generate(prompt)  # e.g., Llama 2 70B
```

**Complexity estimation methods:**

- **Token count**: Longer prompts → larger model
- **Keyword detection**: Technical terms → specialized model
- **Lightweight classifier**: Small model predicts required capability
- **Cost-based**: Balance speed/quality dynamically

**Benefits:**

- 60-80% of requests can use smaller models
- Significant cost and latency reduction
- Maintains quality for complex tasks

### Cascade Systems

Sequential model application with early stopping:

```python
def cascade_generate(prompt, confidence_threshold=0.9):
    # Try smallest model first
    result1, confidence1 = tiny_model.generate_with_confidence(prompt)
    if confidence1 > confidence_threshold:
        return result1
    
    # Fall back to medium model
    result2, confidence2 = medium_model.generate_with_confidence(prompt)
    if confidence2 > confidence_threshold:
        return result2
    
    # Finally use largest model
    return large_model.generate(prompt)
```

**Cascade tiers:**

1. **Tier 1** (90% of requests): 7B model, <100ms latency
2. **Tier 2** (8% of requests): 13B model, 200-300ms latency
3. **Tier 3** (2% of requests): 70B model, 1000ms+ latency

**Confidence estimation:**

- Output probability scores
- Consistency across samples
- Self-verification prompts

### Ensemble Methods

Combine outputs from multiple models for improved accuracy:

**Voting ensemble:**

```python
def ensemble_classify(prompt, models):
    predictions = []
    for model in models:
        prediction = model.classify(prompt)
        predictions.append(prediction)
    
    # Majority vote
    from collections import Counter
    return Counter(predictions).most_common(1)[0][0]
```

**Weighted ensemble:**

```python
def weighted_ensemble(prompt, models, weights):
    outputs = []
    for model, weight in zip(models, weights):
        output = model.generate(prompt)
        outputs.append((output, weight))
    
    # Aggregate based on weights (task-specific)
    return aggregate_outputs(outputs)
```

**Use cases:**

- **Classification tasks**: Majority voting improves accuracy
- **Generation**: Select best output via ranking model
- **Fact-checking**: Cross-verify factual claims
- **Translation**: Compare multiple translations for quality

**Trade-offs:**

- Multiplies computational cost
- Requires aggregation logic
- Best for high-stakes decisions where accuracy critical

## Memory Optimization

### Mixed Precision

Use different precisions for different components:

**Automatic mixed precision (AMP):**

```python
from torch.cuda.amp import autocast

model = model.half()  # FP16 weights

with autocast():  # Automatic precision selection
    outputs = model(inputs)
    # Computation in FP16, sensitive ops in FP32
```

**Manual mixed precision:**

```python
# Configure per-layer precision
model.layers[0:10] = model.layers[0:10].to(torch.float16)  # Input layers
model.layers[10:20] = model.layers[10:20].to(torch.int8)    # Middle layers
model.layers[20:] = model.layers[20:].to(torch.float16)     # Output layers
```

**Precision guidelines:**

- **FP32**: Training, highly sensitive operations
- **BF16**: Training on modern hardware (better range than FP16)
- **FP16**: Inference, good balance
- **FP8**: H100+ GPUs, cutting-edge inference
- **INT8**: Quantized inference, minimal quality loss
- **INT4**: Aggressive quantization, some quality loss

### Memory Mapping

Efficiently access model weights without loading into RAM:

**mmap implementation:**

```python
# llama.cpp automatic memory mapping
./main -m model.gguf --mmap 1

# Model weights stay on disk, OS handles paging
# Enables running models larger than available RAM
```

**Benefits:**

- Instant model "loading" (just opens file)
- Multiple processes can share same model file
- OS manages memory efficiently
- Falls back to swap when needed

**Trade-offs:**

- Slower first access to each weight
- Requires fast storage (NVMe SSD recommended)
- May cause stuttering on HDD

**Python implementation:**

```python
import numpy as np
import mmap

# Memory-map large numpy array
with open('model_weights.npy', 'r+b') as f:
    mm = mmap.mmap(f.fileno(), 0)
    weights = np.frombuffer(mm, dtype=np.float16)
    # Access like normal array, but stored on disk
```

### Swap Management

Configure system swap for models exceeding physical memory:

**Linux swap configuration:**

```bash
# Check current swap
free -h
swapon --show

# Create large swap file (128GB example)
sudo dd if=/dev/zero of=/swapfile bs=1G count=128
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Optimize swap behavior
sudo sysctl vm.swappiness=10  # Prefer RAM
sudo sysctl vm.vfs_cache_pressure=50  # Keep cache
```

**Windows page file:**

```powershell
# Set page file size
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name PagingFiles -Value "C:\pagefile.sys 131072 131072"
# 128GB fixed size
```

**Performance considerations:**

- Swap to NVMe SSD (not HDD)
- Use ZRAM for compressed RAM-backed swap
- Monitor swap usage: `vmstat 1`

**ZRAM setup (Linux):**

```bash
# Install zram
sudo apt install zram-config

# Configure size (50% of RAM)
echo 'ALGO=lz4' | sudo tee -a /etc/default/zramswap
echo 'PERCENT=50' | sudo tee -a /etc/default/zramswap

sudo systemctl restart zramswap
```

### Gradient Checkpointing

Trade computation for memory during training:

```python
# Enable gradient checkpointing
model.gradient_checkpointing_enable()

# Reduces memory by ~50% for training
# Increases training time by ~20%
```

**How it works:**

1. Forward pass: Store only subset of activations
2. Backward pass: Recompute missing activations on-the-fly
3. Enables training larger models or batch sizes

**Configuration:**

```python
from torch.utils.checkpoint import checkpoint

def forward_with_checkpointing(self, x):
    # Checkpoint expensive layers
    x = checkpoint(self.expensive_layer, x)
    return x
```

**Use cases:**

- Fine-tuning large models on limited VRAM
- Increasing batch size for better convergence
- Not needed for inference (no gradients computed)

## Network Optimization

### Local Caching

Cache model outputs to avoid redundant computation:

**Response caching:**

```python
from functools import lru_cache
import hashlib

class LLMCache:
    def __init__(self, max_size=1000):
        self.cache = {}
        self.max_size = max_size
    
    def get_key(self, prompt, params):
        # Create deterministic cache key
        key_str = f"{prompt}_{params}"
        return hashlib.sha256(key_str.encode()).hexdigest()
    
    def get(self, prompt, params):
        key = self.get_key(prompt, params)
        return self.cache.get(key)
    
    def set(self, prompt, params, response):
        key = self.get_key(prompt, params)
        if len(self.cache) >= self.max_size:
            # Remove oldest entry (simple FIFO)
            self.cache.pop(next(iter(self.cache)))
        self.cache[key] = response

# Usage
cache = LLMCache()
response = cache.get(prompt, generation_params)
if response is None:
    response = model.generate(prompt, **generation_params)
    cache.set(prompt, generation_params, response)
```

**Semantic caching:**

```python
# Cache based on semantic similarity, not exact match
from sentence_transformers import SentenceTransformer

class SemanticCache:
    def __init__(self, similarity_threshold=0.95):
        self.encoder = SentenceTransformer('all-MiniLM-L6-v2')
        self.cache_embeddings = []
        self.cache_responses = []
        self.threshold = similarity_threshold
    
    def find_similar(self, prompt):
        embedding = self.encoder.encode(prompt)
        for cached_emb, response in zip(self.cache_embeddings, self.cache_responses):
            similarity = cosine_similarity(embedding, cached_emb)
            if similarity > self.threshold:
                return response
        return None
```

**Benefits:**

- Instant response for repeated queries
- Reduces computational load by 30-70% for production workloads
- Lower latency and costs

### Request Queuing

Efficiently handle concurrent requests:

**Priority queue implementation:**

```python
import asyncio
from queue import PriorityQueue

class RequestQueue:
    def __init__(self, max_batch_size=8, max_wait_ms=100):
        self.queue = PriorityQueue()
        self.max_batch_size = max_batch_size
        self.max_wait_ms = max_wait_ms
    
    async def add_request(self, prompt, priority=1):
        request_id = generate_id()
        future = asyncio.Future()
        self.queue.put((priority, request_id, prompt, future))
        return await future
    
    async def process_batch(self):
        batch = []
        while len(batch) < self.max_batch_size and not self.queue.empty():
            _, req_id, prompt, future = self.queue.get()
            batch.append((req_id, prompt, future))
        
        if batch:
            prompts = [p for _, p, _ in batch]
            results = model.generate_batch(prompts)
            
            for (req_id, _, future), result in zip(batch, results):
                future.set_result(result)
```

**Queue strategies:**

- **FIFO**: First-in-first-out (fairness)
- **Priority**: VIP users, urgent requests first
- **Shortest-job-first**: Minimize average latency
- **Round-robin**: Balance across users/tenants

### Load Balancing

Distribute requests across multiple model instances:

**Simple load balancer:**

```python
class LoadBalancer:
    def __init__(self, model_instances):
        self.instances = model_instances
        self.current = 0
    
    def get_next_instance(self):
        # Round-robin
        instance = self.instances[self.current]
        self.current = (self.current + 1) % len(self.instances)
        return instance
    
    async def generate(self, prompt):
        instance = self.get_next_instance()
        return await instance.generate(prompt)
```

**Advanced strategies:**

```python
# Least-connections: Route to least busy instance
def least_connections(instances):
    return min(instances, key=lambda i: i.active_requests)

# Weighted round-robin: More requests to powerful GPUs
def weighted_rr(instances, weights):
    # GPU 1 (A100): weight 4
    # GPU 2 (RTX 3090): weight 2
    # GPU 3 (RTX 3090): weight 2
    pass

# Health-aware: Skip failed instances
def health_check(instance):
    try:
        instance.health_check()
        return True
    except:
        return False
```

**Horizontal scaling:**

- Run multiple model instances on different GPUs
- Use process-based parallelism (multiprocessing)
- Deploy across multiple machines
- Can handle 10-100x more requests than single instance

## Platform-Specific Optimizations

### Windows Optimizations

**DirectML backend** (AMD/Intel/NVIDIA GPUs):

```python
# Use DirectML for Windows GPU acceleration
import torch_directml
dml = torch_directml.device()

model = model.to(dml)
inputs = inputs.to(dml)
```

**Windows-specific settings:**

```powershell
# Disable Windows Defender real-time scanning for model directory
Add-MpPreference -ExclusionPath "C:\Models"

# Set high performance power plan
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# Increase virtual memory
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name PagingFiles -Value "C:\pagefile.sys 32768 131072"

# Disable unnecessary services
Stop-Service -Name "SysMain" # Superfetch
Stop-Service -Name "WSearch" # Windows Search
```

**Visual Studio optimizations:**

```bash
# Build with MSVC optimizations
cmake -G "Visual Studio 17 2022" -A x64 \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLAMA_NATIVE=ON \
    -DLLAMA_AVX2=ON
```

### Linux Optimizations

**Kernel parameters:**

```bash
# /etc/sysctl.conf
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=10
vm.dirty_background_ratio=5
net.core.rmem_max=134217728
net.core.wmem_max=134217728

# Apply changes
sudo sysctl -p
```

**CPU governor:**

```bash
# Set performance governor for all cores
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Or use cpupower
sudo cpupower frequency-set -g performance
```

**Huge pages:**

```bash
# Enable transparent huge pages
echo always | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo always | sudo tee /sys/kernel/mm/transparent_hugepage/defrag

# Allocate huge pages (2MB each, allocate 32GB)
echo 16384 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
```

**NUMA tuning:**

```bash
# Install numactl
sudo apt install numactl

# Check NUMA topology
numactl --hardware

# Run on specific NUMA node
numactl --cpunodebind=0 --membind=0 ./llama-server -m model.gguf

# Interleave for better average performance
numactl --interleave=all ./llama-server -m model.gguf
```

**Build optimizations:**

```bash
# GCC with maximum optimization
cmake -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="-O3 -march=native -mtune=native" \
    -DCMAKE_CXX_FLAGS="-O3 -march=native -mtune=native" \
    -DLLAMA_NATIVE=ON \
    -DLLAMA_AVX2=ON \
    -DLLAMA_FMA=ON \
    -DLLAMA_F16C=ON
```

### macOS Metal

**Apple Silicon optimization:**

```python
# Use Metal Performance Shaders (MPS) backend
import torch

device = torch.device("mps")
model = model.to(device)

# Alternatively, use mlx for Apple Silicon
import mlx.core as mx
import mlx.nn as nn

# Native Apple Silicon acceleration
model = mx.load("model")
```

**llama.cpp Metal:**

```bash
# Build with Metal support
cmake -DLLAMA_METAL=ON ..
make

# Run with Metal acceleration
./main -m model.gguf -ngl 99  # Offload all layers to GPU
```

**macOS-specific settings:**

```bash
# Increase file descriptor limit
ulimit -n 10240

# Monitor Metal performance
sudo powermetrics --samplers gpu_power,cpu_power

# Check GPU usage
sudo powermetrics --samplers gpu_power -i 1000
```

**Unified memory optimization:**

```python
# Apple Silicon has unified memory - leverage it
# Models can be larger than discrete GPU VRAM equivalent
# M1 Max: 32GB unified
# M1 Ultra: 128GB unified
# M2 Ultra: 192GB unified

# Memory efficient inference
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    device_map="auto",
    low_cpu_mem_usage=True
)
```

**MLX framework (native Apple Silicon):**

```python
import mlx.core as mx
from mlx_lm import load, generate

# Load model optimized for Apple Silicon
model, tokenizer = load("mlx-community/Llama-2-7b-chat")

# Fast generation on Metal
response = generate(model, tokenizer, prompt="Hello", max_tokens=100)
```

## Benchmarking

### Performance Testing

Systematic measurement of optimization improvements:

**Throughput testing:**

```python
import time
import numpy as np

def benchmark_throughput(model, tokenizer, num_requests=100):
    prompts = ["Test prompt " + str(i) for i in range(num_requests)]
    
    start_time = time.time()
    for prompt in prompts:
        inputs = tokenizer(prompt, return_tensors="pt")
        model.generate(**inputs, max_new_tokens=50)
    end_time = time.time()
    
    throughput = num_requests / (end_time - start_time)
    print(f"Throughput: {throughput:.2f} requests/second")
    return throughput
```

**Latency testing:**

```python
def benchmark_latency(model, tokenizer, num_runs=50):
    prompt = "Explain quantum computing"
    latencies = []
    
    # Warmup
    for _ in range(5):
        inputs = tokenizer(prompt, return_tensors="pt")
        model.generate(**inputs, max_new_tokens=100)
    
    # Measure
    for _ in range(num_runs):
        inputs = tokenizer(prompt, return_tensors="pt")
        start = time.time()
        model.generate(**inputs, max_new_tokens=100)
        latencies.append(time.time() - start)
    
    print(f"P50 latency: {np.percentile(latencies, 50)*1000:.2f}ms")
    print(f"P95 latency: {np.percentile(latencies, 95)*1000:.2f}ms")
    print(f"P99 latency: {np.percentile(latencies, 99)*1000:.2f}ms")
```

**Token generation speed:**

```python
def benchmark_tokens_per_second(model, tokenizer, prompt_length=512, gen_length=512):
    prompt = "test " * (prompt_length // 5)
    inputs = tokenizer(prompt, return_tensors="pt")
    
    start = time.time()
    outputs = model.generate(**inputs, max_new_tokens=gen_length, min_new_tokens=gen_length)
    elapsed = time.time() - start
    
    tokens_generated = outputs.shape[1] - inputs.input_ids.shape[1]
    tps = tokens_generated / elapsed
    
    print(f"Tokens per second: {tps:.2f}")
    print(f"Time to first token (TTFT): {elapsed/tokens_generated:.3f}s")
    return tps
```

### Profiling Tools

Identify performance bottlenecks:

**PyTorch Profiler:**

```python
from torch.profiler import profile, ProfilerActivity, record_function

with profile(
    activities=[ProfilerActivity.CPU, ProfilerActivity.CUDA],
    record_shapes=True,
    profile_memory=True,
    with_stack=True
) as prof:
    with record_function("model_inference"):
        outputs = model.generate(inputs, max_new_tokens=100)

# Print results
print(prof.key_averages().table(sort_by="cuda_time_total", row_limit=10))

# Export to Chrome trace
prof.export_chrome_trace("trace.json")
```

**NVIDIA Nsight Systems:**

```bash
# Profile application
nsys profile -t cuda,nvtx,osrt,cudnn,cublas python inference.py

# View in GUI
nsys-ui report.nsys-rep
```

**Memory profiling:**

```python
import tracemalloc
import torch

# Python memory
tracemalloc.start()
model = load_model()
current, peak = tracemalloc.get_traced_memory()
print(f"Peak RAM: {peak / 1024**3:.2f} GB")

# GPU memory
print(f"GPU allocated: {torch.cuda.memory_allocated() / 1024**3:.2f} GB")
print(f"GPU reserved: {torch.cuda.memory_reserved() / 1024**3:.2f} GB")
```

**llama.cpp built-in profiling:**

```bash
./main -m model.gguf --log-disable -p "Test prompt" \
    --mlock --no-mmap \
    2>&1 | grep "load time\|sample time\|eval time"
```

### Metrics

Key performance indicators for optimization:

**Primary metrics:**

```python
class PerformanceMetrics:
    def __init__(self):
        self.metrics = {
            "throughput_rps": 0,           # Requests per second
            "latency_p50_ms": 0,           # Median latency
            "latency_p95_ms": 0,           # 95th percentile
            "latency_p99_ms": 0,           # 99th percentile
            "ttft_ms": 0,                  # Time to first token
            "tps": 0,                      # Tokens per second
            "tokens_per_request": 0,       # Average output length
            "gpu_util_percent": 0,         # GPU utilization
            "gpu_memory_gb": 0,            # GPU memory usage
            "cpu_util_percent": 0,         # CPU utilization
            "ram_usage_gb": 0,             # RAM usage
        }
```

**Quality metrics:**

```python
# Perplexity (lower is better)
from torch.nn import CrossEntropyLoss

def calculate_perplexity(model, tokenizer, text):
    inputs = tokenizer(text, return_tensors="pt")
    with torch.no_grad():
        outputs = model(**inputs, labels=inputs.input_ids)
    return torch.exp(outputs.loss).item()

# BLEU score (translation quality)
from nltk.translate.bleu_score import sentence_bleu

# ROUGE score (summarization quality)
from rouge import Rouge
rouge = Rouge()
scores = rouge.get_scores(hypothesis, reference)
```

**Cost metrics:**

```python
# Cost per 1M tokens
def calculate_cost(tokens_generated, gpu_hours, gpu_cost_per_hour):
    cost_per_million = (gpu_hours * gpu_cost_per_hour) / (tokens_generated / 1e6)
    return cost_per_million

# Example: RTX 4090 at $0.50/hour
# Generates 50 tokens/second = 180K tokens/hour
# Cost: $0.50 / 0.18 = $2.78 per million tokens
```

## Monitoring and Tuning

### Real-Time Monitoring

Track performance metrics during production:

**System monitoring dashboard:**

```python
import psutil
import GPUtil
from prometheus_client import Gauge, start_http_server

# Define metrics
gpu_utilization = Gauge('gpu_utilization_percent', 'GPU utilization')
gpu_memory = Gauge('gpu_memory_used_gb', 'GPU memory usage')
inference_latency = Gauge('inference_latency_ms', 'Inference latency')
requests_per_second = Gauge('requests_per_second', 'Request rate')

def monitor_system():
    while True:
        # GPU metrics
        gpus = GPUtil.getGPUs()
        for gpu in gpus:
            gpu_utilization.set(gpu.load * 100)
            gpu_memory.set(gpu.memoryUsed / 1024)
        
        # CPU/RAM metrics
        cpu_percent = psutil.cpu_percent(interval=1)
        ram_percent = psutil.virtual_memory().percent
        
        time.sleep(1)

# Start Prometheus metrics server
start_http_server(8000)
monitor_system()
```

**Grafana dashboard setup:**

```yaml
# docker-compose.yml
version: '3'
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
  
  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

**Logging best practices:**

```python
import logging
from datetime import datetime

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('llm_inference.log'),
        logging.StreamHandler()
    ]
)

def log_inference(prompt, response, latency_ms, tokens):
    logging.info({
        "timestamp": datetime.now().isoformat(),
        "prompt_length": len(prompt),
        "response_length": len(response),
        "latency_ms": latency_ms,
        "tokens_generated": tokens,
        "tokens_per_second": tokens / (latency_ms / 1000)
    })
```

### Bottleneck Identification

Systematic approach to finding performance issues:

**CPU vs GPU bottleneck:**

```python
def identify_bottleneck(model, inputs):
    import torch.cuda as cuda
    
    # Monitor GPU utilization during inference
    cuda.synchronize()
    start_event = cuda.Event(enable_timing=True)
    end_event = cuda.Event(enable_timing=True)
    
    start_event.record()
    with torch.no_grad():
        outputs = model(**inputs)
    end_event.record()
    cuda.synchronize()
    
    gpu_time = start_event.elapsed_time(end_event)
    
    # Low GPU utilization (<60%) suggests CPU bottleneck
    # High GPU utilization (>90%) suggests GPU bottleneck
```

**Memory vs compute bottleneck:**

```python
# Memory-bound: Increasing batch size doesn't improve throughput
# Compute-bound: Linear throughput increase with batch size

def test_bottleneck_type(model, batch_sizes=[1, 2, 4, 8, 16]):
    throughputs = []
    for bs in batch_sizes:
        throughput = measure_throughput(model, batch_size=bs)
        throughputs.append(throughput)
        print(f"Batch size {bs}: {throughput:.2f} tok/s")
    
    # Analyze scaling
    if throughputs[-1] / throughputs[0] > len(batch_sizes) * 0.7:
        print("Compute-bound: Consider more aggressive quantization")
    else:
        print("Memory-bound: Consider memory optimizations")
```

**Profiling hotspots:**

```python
import cProfile
import pstats

def profile_inference():
    profiler = cProfile.Profile()
    profiler.enable()
    
    # Run inference
    for _ in range(100):
        model.generate(inputs)
    
    profiler.disable()
    stats = pstats.Stats(profiler)
    stats.sort_stats('cumulative')
    stats.print_stats(20)  # Top 20 functions
```

### Iterative Tuning

Systematic optimization process:

**Optimization workflow:**

```text
1. Establish baseline metrics
   ├─ Measure latency, throughput, memory
   └─ Document quality metrics (perplexity, task accuracy)

2. Identify primary bottleneck
   ├─ Profile to find slowest operations
   └─ Analyze resource utilization

3. Apply targeted optimization
   ├─ Choose technique addressing bottleneck
   └─ Implement single change

4. Measure impact
   ├─ Re-run benchmarks
   ├─ Compare to baseline
   └─ Verify quality maintained

5. Iterate
   ├─ If improved: Keep change, find next bottleneck
   └─ If degraded: Revert, try different approach
```

**A/B testing optimizations:**

```python
class OptimizationTest:
    def __init__(self, baseline_model, optimized_model):
        self.baseline = baseline_model
        self.optimized = optimized_model
    
    def compare(self, test_prompts):
        results = {
            "baseline": {"latency": [], "quality": []},
            "optimized": {"latency": [], "quality": []}
        }
        
        for prompt in test_prompts:
            # Baseline
            start = time.time()
            baseline_output = self.baseline.generate(prompt)
            results["baseline"]["latency"].append(time.time() - start)
            results["baseline"]["quality"].append(evaluate_quality(baseline_output))
            
            # Optimized
            start = time.time()
            optimized_output = self.optimized.generate(prompt)
            results["optimized"]["latency"].append(time.time() - start)
            results["optimized"]["quality"].append(evaluate_quality(optimized_output))
        
        # Statistical comparison
        latency_improvement = (
            np.mean(results["baseline"]["latency"]) / 
            np.mean(results["optimized"]["latency"])
        )
        
        quality_change = (
            np.mean(results["optimized"]["quality"]) - 
            np.mean(results["baseline"]["quality"])
        )
        
        return {
            "latency_speedup": latency_improvement,
            "quality_delta": quality_change
        }
```

**Hyperparameter tuning:**

```python
# Find optimal batch size, context length, etc.
from itertools import product

def grid_search_params():
    batch_sizes = [1, 4, 8, 16]
    context_lengths = [512, 1024, 2048]
    precisions = ["fp16", "int8", "int4"]
    
    best_config = None
    best_throughput = 0
    
    for bs, ctx, prec in product(batch_sizes, context_lengths, precisions):
        config = {"batch_size": bs, "context_length": ctx, "precision": prec}
        
        try:
            throughput = benchmark_config(config)
            if throughput > best_throughput:
                best_throughput = throughput
                best_config = config
        except OutOfMemoryError:
            continue
    
    return best_config, best_throughput
```

## Advanced Techniques

### Speculative Decoding

Generate multiple tokens in parallel by predicting future tokens:

**Draft-then-verify approach:**

```python
def speculative_decode(target_model, draft_model, prompt, k=4):
    """
    Use small draft model to predict k tokens ahead,
    then verify with target model in parallel
    """
    input_ids = tokenizer(prompt, return_tensors="pt").input_ids
    
    while len(input_ids[0]) < max_length:
        # Draft model predicts k tokens
        draft_tokens = draft_model.generate(
            input_ids,
            max_new_tokens=k,
            do_sample=False
        )
        
        # Target model verifies all k tokens in parallel
        with torch.no_grad():
            target_logits = target_model(draft_tokens).logits
        
        # Check which predictions match
        verified_tokens = []
        for i in range(k):
            target_token = target_logits[0, -(k-i), :].argmax()
            draft_token = draft_tokens[0, -(k-i)]
            
            if target_token == draft_token:
                verified_tokens.append(target_token)
            else:
                verified_tokens.append(target_token)
                break  # First mismatch, stop
        
        input_ids = torch.cat([input_ids, torch.tensor([verified_tokens])], dim=1)
    
    return input_ids
```

**Benefits:**

- 2-3x speedup when draft model has 70%+ accuracy
- No quality loss (target model always makes final decision)
- Works best when draft model is 10x+ faster than target

**Optimal draft models:**

- Same architecture, smaller size (Llama 2 7B → 1B)
- Distilled versions
- Quantized aggressively (INT4) while target uses higher precision

### Model Distillation

Create smaller, faster "student" models from larger "teacher" models:

**Knowledge distillation:**

```python
import torch.nn.functional as F

def distillation_loss(student_logits, teacher_logits, labels, temperature=2.0, alpha=0.5):
    """
    Combine soft targets from teacher with hard targets from labels
    """
    # Soft targets: Match teacher's probability distribution
    soft_loss = F.kl_div(
        F.log_softmax(student_logits / temperature, dim=-1),
        F.softmax(teacher_logits / temperature, dim=-1),
        reduction='batchmean'
    ) * (temperature ** 2)
    
    # Hard targets: Match actual labels
    hard_loss = F.cross_entropy(student_logits, labels)
    
    # Weighted combination
    return alpha * soft_loss + (1 - alpha) * hard_loss

# Training loop
for batch in dataloader:
    student_logits = student_model(batch.input_ids)
    
    with torch.no_grad():
        teacher_logits = teacher_model(batch.input_ids)
    
    loss = distillation_loss(student_logits, teacher_logits, batch.labels)
    loss.backward()
    optimizer.step()
```

**Distillation strategies:**

- **Architecture distillation**: Reduce layers, hidden size, attention heads
- **Feature distillation**: Match intermediate layer outputs
- **Self-distillation**: Use same model at different stages
- **Task-specific distillation**: Distill for specific downstream tasks

**Typical results:**

- 50% size reduction with 5-10% performance drop
- 75% size reduction with 15-20% performance drop
- 2-4x faster inference

### Parameter Sharing

Reduce memory by sharing weights across layers:

**Universal Transformers:**

```python
# Share parameters across all layers
class UniversalTransformer(nn.Module):
    def __init__(self, hidden_size, num_layers):
        super().__init__()
        # Single transformer block shared across layers
        self.shared_block = TransformerBlock(hidden_size)
        self.num_layers = num_layers
    
    def forward(self, x):
        for _ in range(self.num_layers):
            x = self.shared_block(x)  # Reuse same weights
        return x
```

**Benefits:**

- Reduces parameters by factor of num_layers
- Enables deeper models with same memory
- Can maintain quality with proper training

**Selective sharing:**

```python
# Share FFN weights, keep attention weights separate
class SelectiveSharing(nn.Module):
    def __init__(self, num_layers):
        # Unique attention per layer
        self.attentions = nn.ModuleList([
            Attention() for _ in range(num_layers)
        ])
        
        # Shared FFN across all layers
        self.shared_ffn = FeedForward()
    
    def forward(self, x):
        for attn in self.attentions:
            x = attn(x)
            x = self.shared_ffn(x)  # Shared
        return x
```

**Cross-layer weight tying:**

- Tie embedding and output projection matrices
- Share weights between encoder-decoder (for seq2seq)
- Group layers and share within groups (every 3 layers)

## Configuration Files

### Optimization Settings

**llama.cpp configuration:**

```ini
# server-config.ini
[server]
host = 127.0.0.1
port = 8080
threads = 12
threads_batch = 12

[model]
model_path = models/llama-2-13b-Q4_K_M.gguf
context_size = 4096
batch_size = 512
n_gpu_layers = 99  # Offload all layers to GPU
main_gpu = 0
tensor_split = 0  # For multi-GPU: e.g., "3,2" for 60/40 split

[generation]
temperature = 0.7
top_p = 0.9
top_k = 40
repeat_penalty = 1.1
max_tokens = 2048

[optimization]
use_mmap = true
use_mlock = false  # Lock model in RAM (prevents swapping)
numa = false       # Enable NUMA optimization
flash_attn = true
cont_batching = true
```

**vLLM configuration:**

```yaml
# vllm-config.yaml
model: meta-llama/Llama-2-13b-chat-hf
tensor_parallel_size: 2  # Number of GPUs
dtype: float16
max_model_len: 4096
gpu_memory_utilization: 0.90

# Quantization
quantization: awq
load_format: auto

# KV cache
kv_cache_dtype: auto  # or "fp8" for H100

# Scheduling
max_num_batched_tokens: 8192
max_num_seqs: 256
```

**HuggingFace Transformers:**

```python
# config.py
from transformers import GenerationConfig, AutoConfig

generation_config = GenerationConfig(
    max_new_tokens=512,
    min_new_tokens=1,
    temperature=0.7,
    top_p=0.9,
    top_k=50,
    repetition_penalty=1.1,
    do_sample=True,
    num_beams=1,  # Greedy or sampling (1), beam search (>1)
    early_stopping=True,
    use_cache=True,
    cache_implementation="static",  # or "quantized"
    cache_config={"backend": "quanto", "nbits": 4},
)

model_config = AutoConfig.from_pretrained(
    "model-name",
    torch_dtype="float16",
    attn_implementation="flash_attention_2",
    use_cache=True,
)
```

### Best Practices

**Hardware-specific configurations:**

```python
# RTX 4090 (24GB VRAM) - Consumer GPU
config_4090 = {
    "model_size": "13B",
    "quantization": "Q4_K_M",
    "context_window": 4096,
    "batch_size": 8,
    "flash_attention": True,
    "expected_tps": 45,  # tokens/second
}

# A100 (80GB VRAM) - Professional GPU
config_a100 = {
    "model_size": "70B",
    "quantization": "Q6_K or FP16",
    "context_window": 8192,
    "batch_size": 32,
    "tensor_parallelism": 2,  # If using 2x A100
    "flash_attention": True,
    "expected_tps": 30,
}

# CPU-only (128GB RAM)
config_cpu = {
    "model_size": "13B",
    "quantization": "Q4_K_M",
    "context_window": 2048,
    "batch_size": 1,
    "threads": 24,  # Physical cores
    "mmap": True,
    "mlock": False,
    "expected_tps": 8,
}
```

**Production deployment checklist:**

- Use quantized models (Q4_K_M or better) for balance
- Enable Flash Attention 2 on compatible GPUs
- Set context window to actual needs (don't overallocate)
- Configure appropriate batch size for throughput
- Enable prompt caching for common prefixes
- Set up monitoring (GPU util, latency, throughput)
- Implement request queuing with timeout
- Configure health checks and auto-restart
- Use load balancing for high traffic
- Set resource limits (max memory, max requests/min)

### Template Configs

**Chat application (low latency):**

```json
{
  "model": "llama-2-7b-chat-Q4_K_M.gguf",
  "optimization_goal": "latency",
  "settings": {
    "batch_size": 1,
    "context_size": 2048,
    "temperature": 0.7,
    "max_tokens": 512,
    "stream": true,
    "cache_prompt": true,
    "threads": 8
  }
}
```

**Batch processing (high throughput):**

```json
{
  "model": "llama-2-13b-Q4_K_M.gguf",
  "optimization_goal": "throughput",
  "settings": {
    "batch_size": 32,
    "context_size": 2048,
    "continuous_batching": true,
    "gpu_layers": 99,
    "flash_attention": true,
    "threads_batch": 12
  }
}
```

**Long context analysis:**

```json
{
  "model": "mistral-7b-v0.2-Q5_K_M.gguf",
  "optimization_goal": "context_length",
  "settings": {
    "batch_size": 1,
    "context_size": 32768,
    "rope_freq_base": 1000000,
    "yarn_ext_factor": 2.0,
    "yarn_attn_factor": 0.1,
    "cache_quantization": "q8_0",
    "gpu_layers": 35
  }
}
```

## Cost-Benefit Analysis

Evaluating optimization efforts requires balancing multiple factors:

### Performance vs Quality Trade-offs

**Quantization impact analysis:**

| Precision | Model Size | Speed | Quality | Use Case                            |
| --------- | ---------- | ----- | ------- | ----------------------------------- |
| FP16      | 100%       | 1.0x  | 100%    | Reference baseline                  |
| Q8_0      | 50%        | 1.3x  | 99.5%   | Production, minimal quality loss    |
| Q6_K      | 38%        | 1.5x  | 99%     | High quality, good compression      |
| Q5_K_M    | 31%        | 1.7x  | 97%     | Recommended general purpose         |
| Q4_K_M    | 25%        | 2.0x  | 95%     | Best balance for most users         |
| Q3_K_M    | 19%        | 2.3x  | 90%     | Aggressive, quality degradation     |
| Q2_K      | 13%        | 2.5x  | 80%     | Extreme, significant quality loss   |

### Optimization ROI Framework

**Calculate return on optimization investment:**

```python
class OptimizationROI:
    def __init__(self, baseline_metrics, optimized_metrics, dev_hours):
        self.baseline = baseline_metrics
        self.optimized = optimized_metrics
        self.dev_hours = dev_hours
    
    def calculate_roi(self, requests_per_month, gpu_cost_per_hour):
        # Baseline costs
        baseline_time_per_request = self.baseline['latency_ms'] / 1000
        baseline_gpu_hours = (requests_per_month * baseline_time_per_request) / 3600
        baseline_cost = baseline_gpu_hours * gpu_cost_per_hour
        
        # Optimized costs
        optimized_time_per_request = self.optimized['latency_ms'] / 1000
        optimized_gpu_hours = (requests_per_month * optimized_time_per_request) / 3600
        optimized_cost = optimized_gpu_hours * gpu_cost_per_hour
        
        # Savings
        monthly_savings = baseline_cost - optimized_cost
        annual_savings = monthly_savings * 12
        
        # Development cost (assume $100/hour)
        dev_cost = self.dev_hours * 100
        
        # ROI
        roi_months = dev_cost / monthly_savings if monthly_savings > 0 else float('inf')
        
        return {
            'monthly_savings': monthly_savings,
            'annual_savings': annual_savings,
            'roi_months': roi_months,
            'speedup': self.baseline['latency_ms'] / self.optimized['latency_ms'],
            'quality_preserved': self.optimized['quality_score'] >= self.baseline['quality_score'] * 0.95
        }

# Example
baseline = {'latency_ms': 1000, 'quality_score': 0.95}
optimized = {'latency_ms': 250, 'quality_score': 0.93}

roi = OptimizationROI(baseline, optimized, dev_hours=40)
result = roi.calculate_roi(requests_per_month=1_000_000, gpu_cost_per_hour=1.0)

print(f"4x speedup, ROI in {result['roi_months']:.1f} months")
print(f"Annual savings: ${result['annual_savings']:,.2f}")
```

### Decision Matrix

**When to optimize:**

✅ **High-value optimizations** (do these first):

- Quantization to Q4_K_M (easy, 4x memory reduction)
- Enable Flash Attention (easy, 2-3x speedup)
- Add prompt caching (easy, 10x latency reduction for repeated prefixes)
- Batch processing (medium, 3-5x throughput improvement)
- Use appropriate context window (easy, avoid overallocation)

⚠️ **Medium-value optimizations** (situational):

- Model pruning (hard, requires expertise, 20-30% size reduction)
- Custom quantization schemes (hard, marginal gains over standard)
- Speculative decoding (medium, requires draft model, 2x speedup)
- Multi-GPU setup (medium, cost vs benefit depends on scale)

❌ **Low-value optimizations** (usually not worth it):

- Extreme quantization (Q2_K) - quality degradation too severe
- Exotic hardware (unless already owned)
- Over-engineering for low request volumes
- Premature optimization before measuring bottlenecks

### Cost Comparison

**Cloud vs local inference costs (13B model, 1M tokens/month):**

| Option | Hardware | Cost/Month | Latency | Quality |
| ------ | -------- | ---------- | ------- | ------- |
| OpenAI GPT-3.5 | API | $2.00 | 500ms | High |
| AWS Sagemaker | ml.g5.2xlarge | $900 | 200ms | High |
| Local RTX 4090 | Consumer GPU | $50 (power) | 300ms | High |
| Local CPU | Threadripper | $30 (power) | 2000ms | High |
| Cloud spot GPU | g4dn.xlarge spot | $100 | 400ms | High |

**Break-even analysis:**

- Local GPU pays off after 3-6 months for moderate usage
- High volume (>10M tokens/month): Local infrastructure essential
- Low volume (<100K tokens/month): API often more economical
- Variable workload: Hybrid approach (local + cloud overflow)

## Future Optimization Trends

### Emerging Hardware

**Next-generation accelerators:**

- **NVIDIA H200** (2024): 141GB HBM3e, 4.8TB/s bandwidth, FP8 support
  - 2x memory vs H100, enables 70B models at FP16
  - Native FP8 training and inference
  
- **AMD MI300X** (2024): 192GB HBM3, unified memory architecture
  - Largest memory capacity for single GPU
  - Competitive with H100 for inference workloads
  
- **Intel Gaudi3** (2024): AI-specific architecture
  - Better price/performance than H100 for some workloads
  - Focus on inference optimization

- **Apple M4** (2025): 5nm process, enhanced Neural Engine
  - Unified memory up to 256GB (expected)
  - 2-3x faster ML performance vs M3

**Specialized inference chips:**

- **Groq LPU** (Language Processing Unit): 750+ tokens/second
  - Deterministic performance, no caching needed
  - Ultra-low latency (<100ms for complex queries)
  
- **Cerebras WSE-3**: Wafer-scale AI chip
  - 4 trillion transistors, 44GB on-chip SRAM
  - Enables models beyond current size limits

- **Custom ASICs**: Google TPU v5, AWS Inferentia2, Microsoft Maia
  - 3-5x better cost/performance than GPUs
  - Optimized for production inference

### Algorithmic Innovations

**Sub-quadratic attention:**

```python
# Current: O(n²) attention complexity
# Future: O(n log n) or O(n) alternatives

# Linear attention (RWKV, RetNet)
# - O(n) complexity
# - Constant memory regardless of sequence length
# - Trade-off: Some quality loss vs full attention

# Sparse attention patterns
# - Longformer, BigBird: O(n × window_size)
# - Maintains quality while reducing complexity
```

**Mixture of Experts (MoE):**

```python
# Mixtral 8x7B model architecture
# - 8 expert networks, activate 2 per token
# - 47B total parameters, 13B active per token
# - Better performance than dense 13B model
# - Future: 100+ experts, more efficient routing

class MoELayer:
    def __init__(self, num_experts=8, top_k=2):
        self.experts = [Expert() for _ in range(num_experts)]
        self.router = Router()
        self.top_k = top_k
    
    def forward(self, x):
        # Route to top-k experts
        expert_weights, expert_indices = self.router(x).topk(self.top_k)
        
        # Sparse computation
        output = sum(
            weight * self.experts[idx](x)
            for weight, idx in zip(expert_weights, expert_indices)
        )
        return output
```

**Conditional computation:**

- Early exit strategies (stop computing when confident)
- Adaptive depth (use fewer layers for simple inputs)
- Dynamic width (activate subset of neurons)

### Novel Quantization Methods

**Future precision formats:**

- **FP6**: 6-bit floating point (better than INT6 for some tasks)
- **MX formats** (Microsoft): Microscaling for improved accuracy
- **E4M3/E5M2**: 8-bit formats with different exponent/mantissa splits
- **Adaptive bit-width**: Per-token or per-layer precision adjustment

**Learned quantization:**

```python
# Neural architecture search for optimal quantization
# - Learn which layers benefit from higher precision
# - Automatic mixed-precision configuration
# - Task-specific quantization strategies

# DQ-BERT, BRECQ, AdaRound approaches
# - Train quantization parameters alongside model
# - Minimize accuracy loss through optimization
```

### Hardware-Software Co-design

**Integrated optimizations:**

- Models designed for specific hardware (TPU-optimized architectures)
- Hardware with built-in sparsity support (NVIDIA 2:4 structured sparsity)
- Kernel fusion at compile time (reduce memory traffic)
- On-chip model storage (reduce PCIe bottleneck)

**Neuromorphic computing:**

- Brain-inspired architectures (spiking neural networks)
- Event-driven computation (process only when needed)
- Extreme energy efficiency (<1W for inference)
- Still early stage, but 10-100x efficiency potential

### Compression Breakthroughs

**Ultra-low bit quantization:**

- **1-bit models**: BitNet architecture achieves FP16 quality with 1-bit weights
- **Ternary networks**: -1, 0, +1 weights (1.58 bits average)
- **Binary neural networks**: Complete model in <1GB

**Structured pruning advances:**

- Automatic pruning during training (no separate pruning phase)
- Hardware-aware pruning (optimize for specific GPUs/CPUs)
- Prune-retrain-prune cycles for maximum compression

### Industry Trends

**2024-2026 predictions:**

1. **Quantization becomes default**: FP16 for training, INT4/INT8 for inference
2. **Longer contexts**: 1M+ token windows become common (Gemini 1.5 Pro already at 2M)
3. **Smaller powerful models**: 7B models matching 13B quality through better training
4. **Edge deployment**: Smartphones running 7B models efficiently
5. **Open-source acceleration**: Community-driven optimizations rival proprietary solutions
6. **Unified inference engines**: Single framework supporting all hardware/formats
7. **Real-time inference**: <50ms latency for conversational AI becomes standard

**Key research areas:**

- Flash Attention 3, 4 (continued memory optimization)
- Better MoE routing algorithms
- Distillation improvements (90% quality at 10% size)
- Context compression that preserves information
- Multi-modal optimization (text + vision + audio)

### Recommended Resources

**Stay updated:**

- Research papers: arXiv cs.CL, cs.LG categories
- Repositories: llama.cpp, vLLM, Transformers
- Benchmarks: Open LLM Leaderboard, HELM, LM-Eval
- Communities: r/LocalLLaMA, HuggingFace forums
- Conferences: NeurIPS, ICML, ACL, ICLR

---

## Summary

Local LLM optimization is a rapidly evolving field requiring a multi-faceted approach:

1. **Start with quantization** (Q4_K_M for most use cases)
2. **Enable hardware-specific optimizations** (Flash Attention, GPU offloading)
3. **Optimize context management** (right-size context window, use caching)
4. **Measure continuously** (profile, benchmark, monitor)
5. **Iterate systematically** (one change at a time, validate results)

The optimal configuration depends on your specific constraints (hardware, latency requirements, quality needs), but following the techniques in this guide should achieve 2-10x improvements in speed, memory efficiency, or both while maintaining acceptable quality.
