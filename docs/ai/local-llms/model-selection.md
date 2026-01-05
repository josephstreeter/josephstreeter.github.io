---
title: "Local LLM Model Selection"
description: "Guide to choosing the right local LLM for your needs"
author: "Joseph Streeter"
ms.date: "2025-12-31"
ms.topic: "guide"
keywords: ["model selection", "local models", "llama", "mistral", "model comparison"]
uid: docs.ai.local-llms.model-selection
---

## Overview

Selecting the right local Large Language Model (LLM) is a critical decision that impacts performance, cost, and capability. This comprehensive guide examines model families, architectures, quantization strategies, and selection criteria to help you choose the optimal model for your specific use case and hardware constraints.

Key considerations in model selection:

- **Model family and architecture**: Llama, Mistral, Phi, Gemma, Qwen, and others
- **Parameter count**: From 1B to 70B+ parameters
- **Quantization level**: Trading memory for quality
- **Task specialization**: General, code, chat, vision, embeddings
- **Hardware requirements**: VRAM, RAM, CPU capabilities
- **License restrictions**: Commercial use, derivatives, attribution
- **Context window size**: From 2K to 128K+ tokens
- **Performance benchmarks**: Quality metrics and comparisons

This guide provides practical recommendations based on real-world testing and deployment experience.

## Model Families

### Llama Family

Meta's Llama series represents the most influential open-source LLM family, setting benchmarks for quality and spawning numerous fine-tunes and derivatives.

**Llama 2** (Released July 2023):

- **Architecture**: Decoder-only transformer with RMSNorm, SwiGLU activations, rotary positional embeddings (RoPE)
- **Sizes**: 7B, 13B, 70B parameters
- **Context**: 4096 tokens
- **Training**: 2 trillion tokens, primarily English
- **Variants**: Base (pre-trained) and Chat (instruction-tuned)
- **License**: Llama 2 Community License (permits commercial use with restrictions)

**Key characteristics**:

- Strong general-purpose capabilities
- Excellent base for fine-tuning
- Large ecosystem of derivatives
- Good reasoning and instruction-following

**Llama 3** (Released April 2024):

- **Architecture**: Improved tokenizer (128K vocabulary vs 32K), grouped query attention (GQA)
- **Sizes**: 8B, 70B parameters
- **Context**: 8192 tokens (extended versions available up to 128K)
- **Training**: 15 trillion tokens, multilingual
- **Improvements**: Better coding, reasoning, and multilingual performance

**Key characteristics**:

- Superior tokenization efficiency
- Significantly better code generation
- Improved mathematical reasoning
- Enhanced multilingual support

**Llama 3.1** (Released July 2024):

- **Sizes**: 8B, 70B, 405B parameters
- **Context**: 128K tokens (all sizes)
- **New capabilities**: Tool use, improved instruction following
- **Training**: Updated with more recent data

**Llama 3.2** (Released September 2024):

- **Sizes**: 1B, 3B (text-only), 11B, 90B (vision-capable)
- **Context**: 128K tokens
- **Innovation**: Smallest viable models, multimodal vision models
- **Key strength**: Edge deployment, mobile devices, vision understanding

**Use cases**:

- **7-8B models**: General chat, content generation, personal assistants
- **13B models**: Code generation, analysis, technical writing
- **70B models**: Complex reasoning, research, professional applications
- **1-3B models**: Edge devices, mobile apps, resource-constrained environments

**Example configuration**:

```python
# Llama 3.2 3B - Efficient for most tasks
model_path = "models/llama-3.2-3b-instruct.Q4_K_M.gguf"
llm = Llama(
    model_path=model_path,
    n_gpu_layers=25,  # Full GPU offloading on 8GB VRAM
    n_ctx=8192,       # Good balance
    n_batch=512
)
```

### Mistral Family

Mistral AI's models are known for exceptional quality-to-size ratio, punching above their weight class with architectural innovations.

**Mistral 7B** (Released September 2023):

- **Architecture**: Grouped query attention (GQA), sliding window attention (4096 window)
- **Size**: 7.3B parameters
- **Context**: 8192 tokens (32K with rope scaling)
- **Training**: High-quality curated data
- **License**: Apache 2.0 (fully open)

**Key characteristics**:

- Outperforms Llama 2 13B on many benchmarks
- Efficient inference due to GQA
- Strong coding and reasoning
- Excellent for production deployment

**Mistral 7B Instruct**:

- Instruction-tuned version
- Superior conversational abilities
- Better task following
- Less verbose than base model

**Mixtral 8x7B** (Released December 2023):

- **Architecture**: Sparse Mixture of Experts (SMoE) with 8 experts
- **Active parameters**: 12.9B (only 2 experts active per token)
- **Total parameters**: 46.7B
- **Context**: 32K tokens
- **Performance**: Matches or exceeds GPT-3.5 on many tasks

**Key characteristics**:

- MoE efficiency: Large model capacity with smaller active parameters
- Multilingual excellence (English, French, German, Spanish, Italian)
- Strong code generation
- Cost-effective for quality delivered

**Mixtral 8x22B** (Released April 2024):

- **Active parameters**: 39B per token
- **Total parameters**: 141B
- **Context**: 64K tokens
- **Performance**: Approaches GPT-4 level on many benchmarks

**Mistral Small, Medium, Large** (API-only):

- Closed-source commercial models
- Not available for local deployment

**Use cases**:

- **Mistral 7B**: Production chatbots, content generation, coding assistance
- **Mixtral 8x7B**: Complex reasoning, multilingual applications, research
- **Mixtral 8x22B**: Professional applications, analysis, advanced reasoning

**Example configuration**:

```python
# Mixtral 8x7B - High quality with reasonable requirements
model_path = "models/mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf"
llm = Llama(
    model_path=model_path,
    n_gpu_layers=32,  # Partial GPU offloading
    n_ctx=16384,      # Take advantage of long context
    n_batch=512,
    n_threads=8       # CPU handles some layers
)
```

### Falcon

Technology Innovation Institute (TII) of UAE's Falcon series, known for strong performance and commercial-friendly licensing.

**Falcon 7B / 40B** (Released March 2023):

- **Architecture**: Multi-query attention, ALiBi positional embeddings
- **Sizes**: 7B, 40B, 180B parameters
- **Context**: 2048 tokens
- **Training**: 1.5 trillion tokens from RefinedWeb dataset
- **License**: Apache 2.0 / TII Falcon LLM License

**Key characteristics**:

- RefinedWeb: High-quality web data filtering
- Strong performance on reasoning benchmarks
- Multilingual capabilities
- Commercial-friendly licensing

**Falcon 180B**:

- One of the largest open models
- Requires distributed inference
- Competitive with GPT-3.5
- Challenging to run locally

**Use cases**:

- **Falcon 7B**: Resource-efficient deployment
- **Falcon 40B**: High-quality applications with sufficient hardware
- Best for organizations needing strong licensing terms

**Considerations**:

- Less ecosystem support than Llama
- Fewer fine-tuned variants available
- Higher memory bandwidth requirements

### Phi

Microsoft's Phi series demonstrates that smaller, carefully trained models can match larger models on specific benchmarks through high-quality data and focused training.

**Phi-1 / Phi-1.5** (Released June/September 2023):

- **Size**: 1.3B parameters
- **Focus**: Code generation, reasoning
- **Training**: Textbook-quality synthetic data
- **Context**: 2048 tokens

**Phi-2** (Released December 2023):

- **Size**: 2.7B parameters
- **Context**: 2048 tokens
- **Performance**: Matches or exceeds 7B models on reasoning tasks
- **Training**: 1.4 trillion tokens of high-quality data

**Key characteristics**:

- Exceptional performance per parameter
- Strong mathematical and logical reasoning
- Good code generation despite small size
- Fast inference on CPU

**Phi-3** (Released April 2024):

- **Sizes**: Mini (3.8B), Small (7B), Medium (14B)
- **Context**: 4K-128K tokens (depending on variant)
- **Innovations**: Long context, improved multilingual
- **Training**: 3.3 trillion tokens

**Phi-3.5** (Released August 2024):

- **Variants**: Mini (3.8B), MoE (16x3.8B = 42B total, 6.6B active)
- **Context**: Up to 128K tokens
- **Vision**: Multimodal variants available

**Use cases**:

- Edge devices and mobile applications
- Quick prototyping and testing
- Resource-constrained environments
- Educational applications

**Example configuration**:

```python
# Phi-3 Mini - Excellent for edge deployment
model_path = "models/phi-3-mini-128k-instruct.Q4_K_M.gguf"
llm = Llama(
    model_path=model_path,
    n_gpu_layers=32,  # Can fit entirely in 4GB VRAM
    n_ctx=8192,       # Reduce from 128K for efficiency
    n_batch=256
)
```

### Gemma

Google's Gemma models, derived from Gemini research, offer strong performance with unique architectural features.

**Gemma 2B / 7B** (Released February 2024):

- **Architecture**: Multi-query attention, RoPE embeddings
- **Sizes**: 2B, 7B parameters
- **Context**: 8192 tokens
- **Training**: 2T tokens (2B), 6T tokens (7B)
- **License**: Gemma Terms of Use (restrictive for some uses)

**Key characteristics**:

- Strong safety alignment
- Excellent instruction following
- Good multilingual support
- Derived from Gemini research

**Gemma 2** (Released June 2024):

- **Sizes**: 9B, 27B parameters
- **Context**: 8192 tokens
- **Innovations**: Improved architecture, better reasoning
- **Performance**: Competitive with much larger models

**Key characteristics**:

- Knowledge distillation from Gemini
- Strong mathematical reasoning
- Enhanced coding capabilities
- Better long-form generation

**CodeGemma**:

- Specialized for code generation
- 2B (fill-in-the-middle), 7B (instruction)
- Competitive with larger code models

**Use cases**:

- Safety-critical applications
- Content moderation systems
- Educational chatbots
- Mobile and edge deployment (2B)

**License considerations**:

- Restrictions on certain use cases
- Cannot be used to improve other models
- Review terms carefully for commercial use

### Qwen

Alibaba Cloud's Qwen (Tongyi Qianwen) series excels at multilingual tasks, particularly Chinese-English, with strong overall capabilities.

**Qwen 1.5** (Released February 2024):

- **Sizes**: 0.5B, 1.8B, 4B, 7B, 14B, 32B, 72B, 110B parameters
- **Context**: 32K tokens (all sizes)
- **Languages**: Excellent Chinese, English, and 25+ other languages
- **Training**: 3 trillion tokens

**Key characteristics**:

- Best-in-class multilingual performance
- Strong reasoning and knowledge
- Excellent code generation
- Long context as standard

**Qwen 2** (Released June 2024):

- **Sizes**: 0.5B, 1.5B, 7B, 57B, 72B parameters
- **Context**: 128K tokens (larger models)
- **Improvements**: Better English, enhanced reasoning
- **Training**: High-quality multilingual corpus

**Qwen 2.5** (Released September 2024):

- **Sizes**: 0.5B, 1.5B, 3B, 7B, 14B, 32B, 72B parameters
- **Context**: Up to 128K tokens
- **Specializations**: Coder, Math variants
- **Performance**: State-of-the-art for size class

**Specialized variants**:

- **Qwen-Coder**: Optimized for code (1.5B-32B)
- **Qwen-Math**: Mathematical reasoning focus
- **Qwen-VL**: Vision-language multimodal

**Use cases**:

- Multilingual applications (especially Asian languages)
- International business applications
- Translation and localization
- Code generation in multiple languages
- Long document analysis

**Example configuration**:

```python
# Qwen 2.5 7B - Strong multilingual capabilities
model_path = "models/qwen2.5-7b-instruct.Q4_K_M.gguf"
llm = Llama(
    model_path=model_path,
    n_gpu_layers=35,
    n_ctx=32768,  # Take advantage of long context
    n_batch=512
)
```

### Others

**DeepSeek Models**:

- **DeepSeek Coder**: State-of-the-art code generation (1.3B-33B)
- **DeepSeek Math**: Mathematical reasoning specialist
- Strong performance on technical tasks
- Apache 2.0 license

**Yi Models** (01.AI):

- Strong general-purpose models (6B, 34B)
- Long context (200K tokens)
- Apache 2.0 license
- Good multilingual support

**Orca 2** (Microsoft Research):

- Based on Llama 2
- Advanced reasoning techniques
- 7B, 13B sizes
- Research-focused

**Zephyr** (HuggingFace):

- Llama 2 fine-tune with DPO
- Excellent instruction following
- 7B size
- Strong community support

**StableLM** (Stability AI):

- Various sizes (3B, 7B, etc.)
- Apache 2.0 license
- Good for creative applications

**OpenHermes / Nous-Hermes** (NousResearch):

- High-quality Llama/Mistral fine-tunes
- Excellent instruction following
- Large training on diverse data
- Popular for local deployment

## Model Sizes

### Small Models (1-7B parameters)

Small models offer the best balance of performance and resource efficiency for many applications, with modern architectures delivering impressive capabilities despite their compact size.

**Parameter ranges**:

- **Ultra-small (0.5-1.5B)**: Phi-1, Qwen 0.5B, TinyLlama
- **Small (1.5-3B)**: Phi-2, Llama 3.2 3B, Gemma 2B, Qwen 1.5B
- **Medium-small (3-7B)**: Phi-3, Mistral 7B, Llama 3.2/3.1 8B, Gemma 7B

**Resource requirements**:

| Model Size | FP16 | Q8 | Q4 | Q3 |
| --- | --- | --- | --- | --- |
| 1B | 2GB | 1GB | 0.6GB | 0.4GB |
| 3B | 6GB | 3GB | 1.7GB | 1.2GB |
| 7B | 14GB | 7GB | 4GB | 2.8GB |

**Performance characteristics**:

- **Inference speed**: 20-100+ tokens/second on consumer GPUs
- **Context handling**: Typically 2K-32K tokens
- **Latency**: Excellent for real-time applications
- **Throughput**: Can handle multiple concurrent requests

**Strengths**:

- Fast inference on CPU and mobile devices
- Minimal VRAM requirements
- Cost-effective for high-volume inference
- Easy to fine-tune
- Quick iteration during development
- Edge and mobile deployment viable

**Weaknesses**:

- Limited reasoning depth
- Less factual knowledge
- More prone to hallucination
- Shorter, less detailed responses
- Reduced instruction-following consistency
- Limited multilingual capabilities (except Qwen)

**Ideal use cases**:

- **Chatbots**: Customer service, support assistants
- **Content drafting**: Email responses, social media
- **Code completion**: Real-time IDE integration
- **Classification**: Intent detection, sentiment analysis
- **Summarization**: Short document summaries
- **Edge applications**: Mobile apps, IoT devices
- **Prototyping**: Rapid development and testing

**Recommended models**:

```python
# Phi-3 Mini: Best quality-to-size ratio
phi3_mini = "phi-3-mini-128k-instruct.Q4_K_M.gguf"  # 2.3GB

# Llama 3.2 3B: Balanced performance
llama_3_2 = "llama-3.2-3b-instruct.Q4_K_M.gguf"  # 1.9GB

# Mistral 7B: Production-ready quality
mistral_7b = "mistral-7b-instruct-v0.2.Q4_K_M.gguf"  # 4.1GB

# Qwen 2.5 7B: Multilingual champion
qwen_7b = "qwen2.5-7b-instruct.Q4_K_M.gguf"  # 4.4GB
```

### Medium Models (7-13B parameters)

Medium models provide significant capability improvements over small models while remaining practical for consumer hardware.

**Parameter ranges**:

- **Lower medium (7-10B)**: Llama 3 8B, Mistral 7B, Gemma 9B
- **Upper medium (10-15B)**: Llama 2 13B, Phi-3 Medium 14B, Qwen 14B

**Resource requirements**:

| Model Size | FP16 | Q8 | Q4 | Q3 |
| --- | --- | --- | --- | --- |
| 8B | 16GB | 8GB | 4.5GB | 3.2GB |
| 13B | 26GB | 13GB | 7GB | 5GB |

**Performance characteristics**:

- **Inference speed**: 10-50 tokens/second on consumer GPUs
- **Context handling**: 4K-128K tokens
- **Quality**: Noticeable improvement in reasoning
- **Consistency**: More reliable outputs

**Strengths**:

- Significantly better reasoning than 7B models
- More factual knowledge
- Improved instruction following
- Better long-form content generation
- More consistent responses
- Can handle complex multi-step tasks
- Still manageable on consumer hardware

**Weaknesses**:

- Slower than smaller models
- Requires 8GB+ VRAM for Q4
- Higher latency for interactive use
- More expensive inference costs
- Still below expert-level reasoning

**Ideal use cases**:

- **Content creation**: Blog posts, articles, creative writing
- **Code generation**: Complete functions and classes
- **Analysis**: Document analysis, data interpretation
- **Technical writing**: Documentation, explanations
- **Tutoring**: Educational applications
- **Research assistance**: Literature review, summarization
- **Professional chatbots**: More sophisticated conversations

**Recommended models**:

```python
# Llama 3.1 8B: Excellent all-around
llama_3_1_8b = "llama-3.1-8b-instruct.Q4_K_M.gguf"  # 4.9GB

# Phi-3 Medium: Strong reasoning
phi3_medium = "phi-3-medium-128k-instruct.Q4_K_M.gguf"  # 8.2GB

# Qwen 2.5 14B: Best multilingual
qwen_14b = "qwen2.5-14b-instruct.Q4_K_M.gguf"  # 8.4GB
```

### Large Models (13-34B parameters)

Large models deliver professional-grade quality for demanding applications, requiring serious hardware investment.

**Parameter ranges**:

- **Standard large (13-20B)**: Llama 2 13B, various fine-tunes
- **Extra large (20-40B)**: Falcon 40B, Yi 34B, Qwen 32B

**Resource requirements**:

| Model Size | FP16 | Q8 | Q4 | Q3 |
| --- | --- | --- | --- | --- |
| 13B | 26GB | 13GB | 7GB | 5GB |
| 20B | 40GB | 20GB | 11GB | 7.5GB |
| 34B | 68GB | 34GB | 18GB | 12GB |

**Performance characteristics**:

- **Inference speed**: 5-20 tokens/second (depending on quantization and offloading)
- **Context handling**: 4K-200K tokens
- **Quality**: Professional-grade outputs
- **Hardware**: 16GB+ VRAM recommended, often requires CPU offloading

**Strengths**:

- Near-GPT-3.5 quality on many tasks
- Strong reasoning and problem-solving
- Extensive factual knowledge
- Excellent long-form generation
- More nuanced understanding
- Better at complex instructions
- Reduced hallucination

**Weaknesses**:

- Requires substantial VRAM (16-24GB)
- Slower inference (especially with CPU offloading)
- Higher operational costs
- Not suitable for edge deployment
- May require quantization compromises

**Ideal use cases**:

- **Research**: Complex analysis, literature review
- **Professional writing**: Reports, technical documentation
- **Code review**: Analyzing and improving code
- **Legal/medical**: Domain-specific applications (with fine-tuning)
- **Education**: Advanced tutoring, course content
- **Business intelligence**: Data analysis, insights
- **Creative projects**: Novel writing, screenplays

**Recommended models**:

```python
# Yi 34B: Excellent quality
yi_34b = "yi-34b-chat.Q4_K_M.gguf"  # 19GB

# Qwen 2.5 32B: Best multilingual large model
qwen_32b = "qwen2.5-32b-instruct.Q4_K_M.gguf"  # 18GB

# Mixtral 8x7B: MoE efficiency (runs like ~13B active)
mixtral = "mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf"  # 26GB
```

### Extra Large Models (34B+ parameters)

Extra large models represent state-of-the-art open-source capabilities, approaching or exceeding GPT-3.5/4 performance levels.

**Parameter ranges**:

- **Very large (40-80B)**: Llama 2/3 70B, Falcon 180B, Qwen 72B
- **Massive (100B+)**: Mixtral 8x22B (141B total, 39B active), Falcon 180B

**Resource requirements**:

| Model Size | FP16 | Q8 | Q4 | Q3 |
| --- | --- | --- | --- | --- |
| 70B | 140GB | 70GB | 38GB | 26GB |
| 180B | 360GB | 180GB | 95GB | 65GB |

**Performance characteristics**:

- **Inference speed**: 1-10 tokens/second (heavily dependent on hardware)
- **Context handling**: 4K-128K tokens
- **Quality**: GPT-3.5 to GPT-4 level
- **Hardware**: 24GB+ VRAM, often needs multi-GPU or extensive CPU offloading

**Strengths**:

- Best-in-class reasoning
- Extensive knowledge
- Superior instruction following
- Excellent at complex tasks
- Strong few-shot learning
- Professional-grade outputs
- Minimal hallucination

**Weaknesses**:

- Requires high-end hardware (24GB+ VRAM)
- Slow inference without multi-GPU
- High operational costs
- Complex deployment
- May need distributed inference
- Significant memory requirements

**Ideal use cases**:

- **Enterprise applications**: Mission-critical deployments
- **Research**: Advanced AI research, experimentation
- **Professional services**: Legal, medical, financial analysis
- **Content production**: High-quality content at scale
- **Complex reasoning**: Multi-step problem solving
- **Specialized domains**: With domain-specific fine-tuning

**Recommended models**:

```python
# Llama 3.1 70B: Top open-source quality
llama_70b = "llama-3.1-70b-instruct.Q4_K_M.gguf"  # 39GB

# Qwen 2.5 72B: Multilingual powerhouse
qwen_72b = "qwen2.5-72b-instruct.Q4_K_M.gguf"  # 41GB

# Mixtral 8x22B: MoE efficiency at scale
mixtral_large = "mixtral-8x22b-instruct.Q4_K_M.gguf"  # 78GB
```

**Hardware configurations for 70B models**:

```python
# 24GB VRAM: Q3/Q4 with partial GPU offloading
llm = Llama(
    model_path="llama-3.1-70b-instruct.Q3_K_M.gguf",
    n_gpu_layers=25,  # Partial offloading
    n_ctx=4096,
    n_threads=16      # CPU handles remaining layers
)

# 48GB VRAM (A6000, 2x RTX 3090): Q4 fully on GPU
llm = Llama(
    model_path="llama-3.1-70b-instruct.Q4_K_M.gguf",
    n_gpu_layers=80,  # Full GPU offloading
    n_ctx=8192
)

# CPU-only: Q2/Q3 (very slow but possible)
llm = Llama(
    model_path="llama-3.1-70b-instruct.Q2_K.gguf",
    n_gpu_layers=0,
    n_ctx=2048,
    n_threads=32,
    use_mlock=True
)
```

## Quantization Levels

### No Quantization (FP16/FP32)

Full precision models provide maximum quality at the cost of memory and performance.

**FP32 (32-bit floating point)**:

- **Memory**: ~4 bytes per parameter
- **Quality**: Maximum precision
- **Use case**: Training, research, benchmarking
- **Compatibility**: Universal support
- **Performance**: Slower inference, 2x memory vs FP16

**FP16 (16-bit floating point)**:

- **Memory**: ~2 bytes per parameter
- **Quality**: Negligible loss vs FP32 for inference
- **Use case**: Production inference without quantization
- **Compatibility**: Requires GPU with FP16 support
- **Performance**: 2x faster than FP32, baseline for quantized models

**Memory requirements (FP16)**:

| Model Size | FP16 Memory |
| --- | --- |
| 1B | ~2GB |
| 3B | ~6GB |
| 7B | ~14GB |
| 13B | ~26GB |
| 70B | ~140GB |

**Advantages**:

- Maximum quality and accuracy
- No perceptual quality loss
- Best for fine-tuning
- Ideal for benchmarking
- No special loading requirements

**Disadvantages**:

- Highest memory consumption
- Requires substantial VRAM
- Slower inference
- Not practical for large models
- Limited deployment options

**When to use**:

- Fine-tuning models
- Maximum quality requirements
- Benchmarking and evaluation
- Research applications
- When hardware is not constrained

```python
# Loading unquantized model with Transformers
from transformers import AutoModelForCausalLM
import torch

model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-7b-hf",
    torch_dtype=torch.float16,  # FP16
    device_map="auto"
)
```

### 8-bit Quantization

8-bit quantization offers an excellent balance, halving memory usage with minimal quality impact.

**INT8 (8-bit integer)**:

- **Memory**: ~1 byte per parameter
- **Compression ratio**: 2x vs FP16
- **Quality loss**: Minimal (<2% perplexity increase)
- **Methods**: LLM.int8(), bitsandbytes

**Memory requirements**:

| Model Size | INT8 Memory | Savings vs FP16 |
| --- | --- | --- |
| 1B | ~1GB | 50% |
| 3B | ~3GB | 50% |
| 7B | ~7GB | 50% |
| 13B | ~13GB | 50% |
| 70B | ~70GB | 50% |

**Quality characteristics**:

- Perplexity increase: 0.5-2%
- Virtually imperceptible in chat
- Maintains reasoning capability
- Negligible impact on instruction following
- Safe for production use

**Advantages**:

- 50% memory reduction
- Minimal quality loss
- Still maintains high precision
- Good for fine-tuning (with LoRA)
- Wide hardware compatibility

**Disadvantages**:

- 2x memory savings may not be enough for very large models
- Slightly slower than 4-bit on some hardware
- Requires specific library support (bitsandbytes)

**Implementation**:

```python
# 8-bit with bitsandbytes
model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-13b-hf",
    load_in_8bit=True,
    device_map="auto",
    torch_dtype=torch.float16
)

# GGUF Q8_0
llm = Llama(
    model_path="llama-2-13b.Q8_0.gguf",
    n_gpu_layers=40
)
```

**When to use**:

- Maximum quality with memory savings
- When 4-bit is too lossy
- Fine-tuning with QLoRA
- Critical applications
- Benchmarking quantized models

### 4-bit Quantization (GPTQ, GGUF Q4)

4-bit quantization is the sweet spot for local LLMs, offering 75% memory reduction with acceptable quality loss.

**Quantization methods**:

**GPTQ (GPU optimized)**:

- Asymmetric quantization
- Group-wise quantization (typically 128 group size)
- Optimized for GPU inference
- Fast on CUDA devices
- 4.5GB for 7B model

**GGUF Q4 variants**:

- **Q4_0**: Original 4-bit, no quality improvements
- **Q4_1**: Improved zero-point handling
- **Q4_K_S**: Small block size, faster but lower quality
- **Q4_K_M**: Medium block size, best balance (recommended)
- **Q4_K_L**: Large block size, slower but higher quality

**Memory requirements**:

| Model Size | Q4 Memory | Savings vs FP16 |
| --- | --- | --- |
| 1B | ~0.6GB | 70% |
| 3B | ~1.8GB | 70% |
| 7B | ~4GB | 71% |
| 13B | ~7.5GB | 71% |
| 70B | ~39GB | 72% |

**Quality characteristics**:

- Perplexity increase: 3-7% (varies by model)
- Noticeable but acceptable in most tasks
- Maintains general capabilities
- May reduce factual precision
- Still coherent and useful

**Advantages**:

- 4x memory reduction vs FP16
- Fits 7B on 8GB VRAM, 13B on 12GB, 70B on 48GB
- Fast inference
- Wide format support (GGUF, GPTQ, AWQ)
- Best balance for production

**Disadvantages**:

- 5-10% quality degradation
- More hallucinations than 8-bit
- Reduced reasoning for complex tasks
- Math/logic accuracy decreases
- May need larger model to compensate

**Quality comparison Q4 variants**:

```text
Quality (best to worst): Q4_K_L > Q4_K_M > Q4_K_S > Q4_1 > Q4_0
Speed (fastest to slowest): Q4_0 ≈ Q4_K_S > Q4_K_M > Q4_K_L > Q4_1
```

**Recommended variants**:

- **General use**: Q4_K_M (best balance)
- **Maximum speed**: Q4_K_S or Q4_0
- **Maximum quality**: Q4_K_L
- **GPU-only**: GPTQ or AWQ

**Implementation**:

```python
# GGUF Q4_K_M (most popular)
llm = Llama(
    model_path="llama-3.1-8b-instruct.Q4_K_M.gguf",
    n_gpu_layers=35,
    n_ctx=8192
)

# GPTQ
from auto_gptq import AutoGPTQForCausalLM

model = AutoGPTQForCausalLM.from_quantized(
    "TheBloke/Llama-2-7B-GPTQ",
    device="cuda:0",
    use_safetensors=True,
    use_triton=True
)
```

**When to use**:

- Most local deployments (recommended default)
- Limited VRAM (8-16GB)
- Production chatbots
- When speed matters more than perfect quality
- Consumer hardware deployment

### 2-bit and 3-bit Quantization

Aggressive quantization for extreme memory constraints, with significant quality tradeoffs.

**Q3 (3-bit quantization)**:

- **Memory**: ~0.4-0.45 bytes per parameter
- **Compression**: ~4.5x vs FP16
- **Quality loss**: Noticeable (10-15% perplexity increase)

**Q2 (2-bit quantization)**:

- **Memory**: ~0.3 bytes per parameter
- **Compression**: ~6x vs FP16
- **Quality loss**: Significant (20-30% perplexity increase)

**Memory requirements**:

| Model Size | Q3 Memory | Q2 Memory |
| --- | --- | --- |
| 1B | ~0.5GB | ~0.35GB |
| 3B | ~1.4GB | ~1GB |
| 7B | ~3GB | ~2.2GB |
| 13B | ~5.5GB | ~4GB |
| 70B | ~28GB | ~21GB |

**Quality impact**:

**Q3_K_M**:

- Maintains basic coherence
- Reduced factual accuracy
- More frequent hallucinations
- Acceptable for simple tasks
- Not recommended for professional use

**Q2_K**:

- Significantly degraded quality
- Frequent nonsensical outputs
- Limited reasoning ability
- Use only when necessary
- Better to use smaller model at Q4

**Advantages**:

- Extreme memory savings
- Enables running very large models
- Fast inference
- Last resort for hardware constraints

**Disadvantages**:

- Substantial quality loss
- Frequent hallucinations
- Reduced coherence
- Limited reasoning
- Not suitable for production (except Q3 for non-critical tasks)

**When to use Q3**:

- 4GB VRAM running 13B model
- CPU-only inference of large models
- Quick testing of large models
- Non-critical applications
- When Q4 doesn't fit

**When to use Q2**:

- Absolutely cannot fit Q3
- Experimental purposes
- Model testing only
- **Generally not recommended**

**Implementation**:

```python
# Q3_K_M (usable in limited scenarios)
llm = Llama(
    model_path="llama-3.1-70b-instruct.Q3_K_M.gguf",
    n_gpu_layers=30,  # Partial offloading on 16GB VRAM
    n_ctx=4096
)

# Q2_K (emergency only)
llm = Llama(
    model_path="llama-3.1-70b-instruct.Q2_K.gguf",
    n_gpu_layers=50,
    n_ctx=2048
)
```

**Quality vs size tradeoff recommendations**:

```text
Best approach: Use smaller model at Q4 rather than larger model at Q2
Example: Llama 3.1 8B Q4 > Llama 3.1 70B Q2
```

## Model Formats

### GGUF

GGUF (GPT-Generated Unified Format) is the standard for llama.cpp and the most popular format for local LLM deployment.

**Key characteristics**:

- **Developed by**: Georgi Gerganov (llama.cpp creator)
- **Successor to**: GGML format
- **File extension**: .gguf
- **Architecture support**: Llama, Mistral, Falcon, Phi, Gemma, Qwen, and most modern LLMs
- **Quantization**: Q2 through Q8, plus K-quants
- **Platform**: CPU, GPU (CUDA, Metal, OpenCL, Vulkan)

**Quantization variants**:

```text
Q2_K: 2.67 bits per weight
Q3_K_S, Q3_K_M, Q3_K_L: ~3.5 bits per weight
Q4_0, Q4_1: 4.5 bits per weight
Q4_K_S, Q4_K_M, Q4_K_L: 4.5-5.0 bits per weight
Q5_K_S, Q5_K_M: 5.5 bits per weight
Q6_K: 6.5 bits per weight
Q8_0: 8.5 bits per weight
```

**Advantages**:

- Single-file distribution
- Embedded metadata (architecture, tokenizer, parameters)
- Memory mapping support (fast loading)
- Cross-platform compatibility
- Active development and optimization
- Extensive model library
- Direct CPU support

**Best for**:

- Local deployment
- CPU inference
- Apple Silicon (Metal)
- Cross-platform applications
- Easy distribution

**Where to get**:

- Hugging Face (TheBloke, mradermacher, bartowski)
- Ollama library (auto-downloads)
- Direct conversions from PyTorch

**Usage example**:

```python
from llama_cpp import Llama

llm = Llama(
    model_path="./models/llama-3.1-8b-instruct.Q4_K_M.gguf",
    n_gpu_layers=35,
    n_ctx=8192,
    n_batch=512,
    verbose=False
)
```

### GPTQ

GPTQ (GPT Quantization) optimizes 4-bit models specifically for GPU inference with minimal quality loss.

**Key characteristics**:

- **Optimization**: GPU-specific quantization calibration
- **Precision**: 4-bit with 128 group size (typical)
- **File format**: SafeTensors or .bin
- **Framework**: AutoGPTQ, Exllama/ExllamaV2
- **Platform**: CUDA GPUs only
- **Performance**: Fastest GPU inference at 4-bit

**Technical details**:

- Layer-wise quantization calibration
- Asymmetric quantization (better accuracy)
- Group-wise quantization (typically 128)
- Requires calibration dataset
- Preserves activation precision

**Advantages**:

- Fastest 4-bit inference on NVIDIA GPUs
- Better quality than GGUF Q4 for same size
- Optimized for batched inference
- Good for API servers
- Excellent with Exllama backend

**Disadvantages**:

- CUDA only (no CPU, no AMD, no Apple Silicon)
- Requires GPU for inference
- More complex setup than GGUF
- Larger file sizes (model + configuration)
- Less portable

**Best for**:

- NVIDIA GPU deployment
- Maximum GPU performance
- API servers
- Production inference at scale

**Usage example**:

```python
from auto_gptq import AutoGPTQForCausalLM
from transformers import AutoTokenizer

model_name = "TheBloke/Llama-2-13B-chat-GPTQ"
tokenizer = AutoTokenizer.from_pretrained(model_name)

model = AutoGPTQForCausalLM.from_quantized(
    model_name,
    device="cuda:0",
    use_safetensors=True,
    use_triton=True,  # Triton backend for speed
    quantize_config=None
)
```

### AWQ

AWQ (Activation-aware Weight Quantization) is another GPU-optimized 4-bit format focusing on preserving important weights.

**Key characteristics**:

- **Innovation**: Preserves weights with high activation magnitude
- **Precision**: 4-bit quantization
- **Platform**: CUDA GPUs
- **Framework**: AutoAWQ, vLLM support
- **Quality**: Often better than GPTQ at same size

**Technical approach**:

- Analyzes activation patterns
- Protects salient weights
- Channel-wise quantization
- Better accuracy than naive 4-bit

**Advantages**:

- Higher quality than GPTQ for same bit-width
- Fast inference
- Good vLLM integration
- Efficient memory usage

**Disadvantages**:

- Less common than GPTQ/GGUF
- CUDA only
- Fewer pre-quantized models available
- Requires specific libraries

**Best for**:

- Maximum quality at 4-bit on GPU
- vLLM deployments
- When quality matters more than ubiquity

**Usage example**:

```python
from awq import AutoAWQForCausalLM
from transformers import AutoTokenizer

model_name = "TheBloke/Llama-2-7B-AWQ"
tokenizer = AutoTokenizer.from_pretrained(model_name)

model = AutoAWQForCausalLM.from_quantized(
    model_name,
    fuse_layers=True
)
```

### ONNX

ONNX (Open Neural Network Exchange) provides cross-platform model portability with hardware-specific optimizations.

**Key characteristics**:

- **Purpose**: Cross-platform deployment
- **Optimization**: Hardware-specific acceleration
- **Platform**: CPU, GPU, NPU, mobile
- **Framework**: ONNX Runtime
- **Quantization**: INT8, INT4 via ONNX Runtime

**Advantages**:

- Hardware vendor optimization (Intel, AMD, ARM, Qualcomm)
- Mobile deployment (iOS, Android)
- Edge devices
- NPU/TPU acceleration
- Good tooling

**Disadvantages**:

- Limited LLM library compared to GGUF
- More complex conversion process
- May lose some model features
- Less community support for LLMs

**Best for**:

- Mobile applications
- Edge AI
- Specific hardware platforms
- Production deployment with ONNX Runtime

### Original PyTorch

Native PyTorch format with full precision and flexibility.

**Key characteristics**:

- **Format**: .bin or SafeTensors
- **Precision**: FP32, FP16, BF16
- **Framework**: PyTorch, Transformers
- **Purpose**: Training, research, fine-tuning

**Advantages**:

- Full model capabilities
- Easy fine-tuning
- Best for development
- Maximum compatibility with tools
- Direct from model creators

**Disadvantages**:

- Largest file sizes
- Highest memory requirements
- Slower inference than quantized
- Not optimized for deployment

**Best for**:

- Fine-tuning
- Research
- Development
- Source for creating quantized versions

**Format recommendation by use case**:

| Use Case | Recommended Format | Second Choice |
| --- | --- | --- |
| General local use | GGUF | PyTorch + Transformers |
| NVIDIA GPU | GPTQ | AWQ |
| Apple Silicon | GGUF | ONNX |
| CPU-only | GGUF | ONNX |
| Mobile/Edge | ONNX | GGUF |
| Fine-tuning | PyTorch | - |
| Maximum quality | PyTorch FP16 | GGUF Q8 |
| Maximum speed | GPTQ/AWQ (GPU) | GGUF Q4_K_S |

## Selection Criteria

### Task Requirements

Matching model capabilities to your specific use case is the most important selection criterion.

**Conversational AI / Chatbots**:

- **Requirements**: Good instruction following, natural language, consistent personality
- **Recommended**:
  - Budget: Phi-3 Mini, Llama 3.2 3B
  - Balanced: Mistral 7B Instruct, Llama 3.1 8B Instruct
  - Premium: Llama 3.1 70B Instruct, Qwen 2.5 72B
- **Key features**: Instruct/chat tuning, safety alignment, coherent multi-turn
- **Quantization**: Q4_K_M acceptable, Q5 better for consistency

**Code Generation**:

- **Requirements**: Syntax understanding, multiple languages, completion and generation
- **Recommended**:
  - Specialized: DeepSeek Coder 6.7B/33B, Code Llama 13B/34B
  - General: Llama 3.1 8B/70B, Qwen 2.5 Coder, Mistral 7B
  - Small: Phi-3 Mini, Qwen 2.5 Coder 1.5B
- **Key features**: Code-specific training, fill-in-middle support, multi-language
- **Quantization**: Q4_K_M or higher (Q5_K_M for complex code)

**Content Creation / Writing**:

- **Requirements**: Creativity, coherence, style matching, long-form generation
- **Recommended**:
  - Creative: Mistral 7B, Llama 3.1 8B, various creative fine-tunes
  - Professional: Llama 3.1 70B, Qwen 2.5 32B/72B
  - Technical: Llama 3.1 8B, Mixtral 8x7B
- **Key features**: Long context, coherent generation, stylistic control
- **Quantization**: Q5_K_M or higher for best quality

**Data Analysis / Reasoning**:

- **Requirements**: Logical reasoning, mathematical ability, structured thinking
- **Recommended**:
  - Small: Phi-3 Medium, DeepSeek Math
  - Medium: Llama 3.1 8B, Mixtral 8x7B
  - Large: Llama 3.1 70B, Qwen 2.5 72B
- **Key features**: Strong base training, reasoning emphasis
- **Quantization**: Q6_K or Q8_0 for accuracy-critical tasks

**Translation / Multilingual**:

- **Requirements**: Multiple language support, cultural understanding
- **Recommended**:
  - Best: Qwen 2.5 7B/14B/72B (especially Asian languages)
  - Alternative: Mixtral 8x7B/8x22B (European languages)
  - Budget: Qwen 2.5 3B
- **Key features**: Multilingual training, language balance
- **Quantization**: Q4_K_M minimum, Q5_K_M for quality

**Summarization**:

- **Requirements**: Comprehension, conciseness, key point extraction
- **Recommended**:
  - Short documents: Any 7B+ instruct model
  - Long documents: Models with long context (Llama 3.1/3.2, Qwen 2.5)
  - Technical: Llama 3.1, Mistral
- **Key features**: Long context support, instruction following
- **Quantization**: Q4_K_M acceptable

**Embeddings / Semantic Search**:

- **Different category**: Specialized embedding models, not generative LLMs
- **Recommended**: BGE, E5, sentence-transformers models
- **Note**: These are separate from conversational LLMs

### Hardware Constraints

Your available hardware determines which models are feasible and at what performance level.

**4GB VRAM (GTX 1650, GTX 1050 Ti)**:

**Viable models**:

- 3B Q4_K_M: Phi-3 Mini, Llama 3.2 3B, Qwen 2.5 3B
- 7B Q3_K_M: Mistral 7B, Llama 3.1 8B (quality loss)
- 1-2B Q4/Q5: TinyLlama, Qwen 2.5 1.5B

**Configuration**:

```python
llm = Llama(
    model_path="phi-3-mini-128k-instruct.Q4_K_M.gguf",
    n_gpu_layers=32,  # All layers
    n_ctx=4096,       # Reduce if needed
    n_batch=256       # Smaller batches
)
```

**Expectations**: 15-30 tokens/second with 3B Q4, usable for personal chatbots

**8GB VRAM (RTX 3060, RTX 2070, RX 6600 XT)**:

**Viable models**:

- 7B Q5_K_M: Mistral 7B, Llama 3.1 8B (high quality)
- 7B Q8_0: Any 7B model (maximum quality)
- 13B Q3_K_M: Llama 2 13B (acceptable quality)
- 13B Q4_K_M: Partial GPU + CPU

**Configuration**:

```python
# Full GPU with 7B Q5
llm = Llama(
    model_path="llama-3.1-8b-instruct.Q5_K_M.gguf",
    n_gpu_layers=35,
    n_ctx=8192,
    n_batch=512
)

# Hybrid with 13B Q4
llm = Llama(
    model_path="llama-2-13b-chat.Q4_K_M.gguf",
    n_gpu_layers=20,  # Partial offloading
    n_threads=8,      # CPU handles rest
    n_ctx=4096
)
```

**Expectations**: 30-60 tokens/second with 7B Q5, 15-25 t/s with 13B Q4 hybrid

**12GB VRAM (RTX 3060 12GB, RTX 2080 Ti)**:

**Viable models**:

- 7B Q8_0: Full precision quantized (best 7B quality)
- 13B Q5_K_M: High quality medium models
- 13B Q6_K: Near-full quality
- 34B Q3_K_M: Larger models with quality tradeoff
- Mixtral 8x7B Q3_K_M: MoE models

**Configuration**:

```python
# 13B high quality
llm = Llama(
    model_path="llama-2-13b-chat.Q5_K_M.gguf",
    n_gpu_layers=40,
    n_ctx=4096,
    n_batch=512
)
```

**Expectations**: 40-70 t/s with 7B, 20-40 t/s with 13B Q5

**16GB VRAM (RTX 4060 Ti 16GB, RTX 3090 Ti)**:

**Viable models**:

- 13B Q8_0: Maximum quality medium models
- 34B Q4_K_M: Large models with good quality
- Mixtral 8x7B Q4_K_M: High-quality MoE
- 70B Q2_K: Experimental large models (not recommended)

**Configuration**:

```python
# Mixtral 8x7B
llm = Llama(
    model_path="mixtral-8x7b-instruct.Q4_K_M.gguf",
    n_gpu_layers=32,
    n_ctx=16384,
    n_batch=512
)

# 34B high quality
llm = Llama(
    model_path="yi-34b-chat.Q4_K_M.gguf",
    n_gpu_layers=60,
    n_ctx=4096
)
```

**Expectations**: 25-35 t/s with Mixtral Q4, 15-25 t/s with 34B Q4

**24GB VRAM (RTX 3090, RTX 4090, A5000)**:

**Viable models**:

- 34B Q5_K_M/Q6_K: High-quality large models
- Mixtral 8x7B Q5_K_M: Premium MoE quality
- 70B Q3_K_M: Acceptable quality with large model
- 70B Q4_K_M: Partial GPU + CPU offloading

**Configuration**:

```python
# 70B partial offloading
llm = Llama(
    model_path="llama-3.1-70b-instruct.Q3_K_M.gguf",
    n_gpu_layers=50,  # Some on GPU
    n_threads=16,     # CPU handles rest
    n_ctx=4096
)

# Mixtral high quality
llm = Llama(
    model_path="mixtral-8x7b-instruct.Q5_K_M.gguf",
    n_gpu_layers=32,
    n_ctx=32768
)
```

**Expectations**: 30-40 t/s with Mixtral Q5, 8-15 t/s with 70B Q3 hybrid

**48GB+ VRAM (A6000, 2x RTX 3090, A100)**:

**Viable models**:

- 70B Q4_K_M: Full GPU, good quality
- 70B Q5_K_M/Q6_K: High quality large models
- Mixtral 8x22B Q3_K_M/Q4_K_M: Largest MoE models
- Multiple models simultaneously

**Configuration**:

```python
# 70B full quality
llm = Llama(
    model_path="llama-3.1-70b-instruct.Q4_K_M.gguf",
    n_gpu_layers=80,  # Full offloading
    n_ctx=8192,
    n_batch=512
)
```

**Expectations**: 15-30 t/s with 70B Q4

**CPU-Only (No GPU)**:

**Viable models**:

- 1-3B Q4: Phi-3 Mini, Llama 3.2 1B/3B, Qwen 2.5 3B
- 7B Q3/Q4: Slower but usable

**Configuration**:

```python
llm = Llama(
    model_path="phi-3-mini-128k-instruct.Q4_K_M.gguf",
    n_gpu_layers=0,
    n_threads=os.cpu_count(),
    n_ctx=4096,
    use_mlock=True,
    use_mmap=True
)
```

**Expectations**: 5-15 t/s with modern CPU (Ryzen 5000+, Intel 12th gen+) and 3B model

### Language Support

Multilingual capability varies significantly across model families.

**English-only use**:

- All models perform well
- Llama, Mistral, Phi excel
- No special considerations

**English + European languages**:

**Best models**:

- Mixtral 8x7B/8x22B: Excellent French, German, Spanish, Italian
- Qwen 2.5: Good all-around
- Llama 3/3.1: Decent multilingual

**Languages**: French, German, Spanish, Italian, Portuguese, Dutch

**English + Asian languages**:

**Best models**:

- **Qwen 2.5**: Best-in-class for Chinese, Japanese, Korean
- Llama 3/3.1: Improving but still behind
- Yi: Good for Chinese

**Languages**: Chinese (Mandarin), Japanese, Korean, Vietnamese, Thai

**True multilingual (100+ languages)**:

- Qwen 2.5: Widest coverage
- Llama 3.1: Good coverage
- Mixtral: European languages primarily

**Language quality comparison**:

| Model Family | English | European | Asian | Other |
| --- | --- | --- | --- | --- |
| Llama 3.1 | Excellent | Good | Fair | Fair |
| Mistral/Mixtral | Excellent | Excellent | Poor | Poor |
| Qwen 2.5 | Excellent | Good | Excellent | Good |
| Phi-3 | Excellent | Fair | Poor | Poor |
| Gemma 2 | Excellent | Good | Fair | Fair |

### License Considerations

Understanding licenses is crucial for commercial deployment and distribution.

**Apache 2.0 (Most permissive)**:

**Models**: Mistral, Falcon, Yi, StableLM, Qwen

**Allows**:

- Commercial use without restrictions
- Modification and distribution
- Private use
- Patent grant

**Best for**: Any commercial application

**Llama 2/3 Community License**:

**Models**: Llama 2, Llama 3, Llama 3.1, Llama 3.2, Code Llama

**Allows**:

- Commercial use with conditions
- Modification and distribution
- 700M+ monthly active users require special license

**Restrictions**:

- Cannot use to improve other LLMs
- Must request special license if > 700M MAU
- Attribution required

**Best for**: Most commercial applications (unless massive scale)

**Gemma Terms of Use**:

**Models**: Gemma, Gemma 2, CodeGemma

**Allows**:

- Commercial use
- Modification

**Restrictions**:

- Cannot use to improve other models
- Cannot use outputs to develop AI models
- Restrictions on certain use cases
- Must comply with Google's policies

**Best for**: Applications not involving model development

**Research-only licenses**:

**Models**: Some academic releases, early research models

**Restrictions**: Cannot use commercially

**Best for**: Academic research, experiments only

**License recommendations**:

- **Safest commercial**: Apache 2.0 models (Mistral, Qwen, Falcon)
- **Most capable with license**: Llama 3.1 (acceptable restrictions for most)
- **Avoid for commercial**: Research-only, restrictive terms

### Context Length

Context window size determines how much text the model can process simultaneously.

**Context size ranges**:

| Size | Token Count | Approximate Pages | Use Cases |
| --- | --- | --- | --- |
| Small | 2K-4K | 4-8 pages | Chat, short tasks |
| Medium | 4K-8K | 8-16 pages | Standard applications |
| Large | 8K-32K | 16-64 pages | Document analysis |
| Very Large | 32K-128K | 64-256 pages | Long documents |
| Extreme | 128K+ | 256+ pages | Entire books |

**Model context capabilities**:

| Model | Base Context | Extended Context Available |
| --- | --- | --- |
| Llama 2 | 4K | 32K (rope scaling) |
| Llama 3 | 8K | 128K (rope scaling) |
| Llama 3.1/3.2 | 128K | Native |
| Mistral 7B | 8K | 32K (rope scaling) |
| Mixtral | 32K/64K | Native |
| Phi-3 | 4K/128K | Varies by variant |
| Qwen 2.5 | 32K-128K | Native |
| Gemma 2 | 8K | Native |

**Performance impact**:

- Longer context = more memory
- Longer context = slower inference
- Quality may degrade at maximum context
- Consider actual needs vs maximum capability

**Context window memory formula**:

```text
KV Cache Memory ≈ context_size × layers × hidden_dim × 2 × bytes_per_param
```

**Example** (Llama 3 8B):

- 8K context: ~512MB KV cache
- 32K context: ~2GB KV cache
- 128K context: ~8GB KV cache

**Recommendations**:

- **Chat/assistant**: 4K-8K sufficient
- **Code generation**: 8K-16K for context
- **Document analysis**: 32K-128K needed
- **RAG applications**: 8K-16K (retrieval provides context)

**Configuration**:

```python
# Standard context
llm = Llama(
    model_path=model_path,
    n_ctx=8192  # 8K context
)

# Extended context (if supported)
llm = Llama(
    model_path=model_path,
    n_ctx=32768,  # 32K context
    rope_freq_base=10000,  # Adjust for rope scaling
    rope_freq_scale=0.25
)

# Very long context (native support)
llm = Llama(
    model_path="llama-3.1-8b-instruct.Q4_K_M.gguf",
    n_ctx=131072  # 128K native context
)
```

### Benchmark Performance

Benchmarks provide quantitative comparisons but should be interpreted with real-world testing.

**Common benchmarks**:

**MMLU (Massive Multitask Language Understanding)**:

- Measures: General knowledge across 57 subjects
- Range: 0-100%
- Good for: Comparing general capability
- Limitations: Academic knowledge focus

**HumanEval (Code)**:

- Measures: Python code generation pass@1
- Range: 0-100%
- Good for: Comparing coding ability
- Limitations: Only Python, simple problems

**GSM8K (Math)**:

- Measures: Grade school math problems
- Range: 0-100%
- Good for: Mathematical reasoning
- Limitations: Limited to arithmetic

**TruthfulQA**:

- Measures: Resistance to common misconceptions
- Range: 0-100%
- Good for: Factual accuracy
- Limitations: Specific question set

**Approximate benchmark scores** (Q4 quantization, subject to variation):

| Model | MMLU | HumanEval | GSM8K | Params |
| --- | --- | --- | --- | --- |
| Phi-3 Mini | 69% | 59% | 82% | 3.8B |
| Llama 3.2 3B | 63% | 50% | 52% | 3B |
| Mistral 7B v0.2 | 64% | 31% | 52% | 7B |
| Llama 3.1 8B | 69% | 72% | 84% | 8B |
| Gemma 2 9B | 72% | 68% | 85% | 9B |
| Qwen 2.5 7B | 71% | 61% | 79% | 7B |
| Llama 2 13B | 55% | 18% | 28% | 13B |
| Mixtral 8x7B | 71% | 40% | 74% | 47B |
| Llama 3.1 70B | 83% | 81% | 95% | 70B |
| Qwen 2.5 72B | 85% | 86% | 95% | 72B |

**Benchmark limitations**:

- Don't reflect real-world performance
- Can be gamed or overfit
- Miss important qualities (creativity, helpfulness)
- Quantization impact not always measured
- May not represent your specific use case

**What to focus on**:

1. **Relevant benchmarks**: If coding, look at HumanEval
2. **Similar models**: Compare within size/type class
3. **Multiple metrics**: No single score tells full story
4. **Qualitative testing**: Try models yourself
5. **Community feedback**: Reddit, Discord, forums

**Better evaluation approach**:

```python
# Create task-specific test set
test_prompts = [
    "Explain quantum entanglement simply",
    "Write a Python function to merge sorted lists",
    "Summarize this article: [text]",
    # Add 20-50 prompts representing your use case
]

def evaluate_model(model_path, test_prompts):
    llm = Llama(model_path=model_path, n_gpu_layers=35)
    
    results = []
    for prompt in test_prompts:
        start = time.time()
        response = llm(prompt, max_tokens=512)
        duration = time.time() - start
        
        results.append({
            'prompt': prompt,
            'response': response['choices'][0]['text'],
            'duration': duration
        })
    
    return results

# Compare models on your tasks
results_mistral = evaluate_model("mistral-7b.gguf", test_prompts)
results_llama = evaluate_model("llama-3.1-8b.gguf", test_prompts)
# Manual review of quality
```

## Specialized Models

### Code Generation

Models optimized specifically for programming tasks with code-specific training and features.

**Code Llama** (Meta):

- **Sizes**: 7B, 13B, 34B, 70B
- **Variants**: Base, Python-specialized, Instruct
- **Context**: 16K tokens (100K for long-context variant)
- **Training**: 500B tokens of code
- **License**: Llama 2 Community License

**Features**:

- Fill-in-the-middle (FIM) support
- Multi-language (Python, C++, Java, PHP, C#, TypeScript, Bash)
- Instruction following for code tasks
- Code completion and generation

**DeepSeek Coder** (DeepSeek):

- **Sizes**: 1.3B, 6.7B, 33B
- **Variants**: Base, Instruct
- **Context**: 16K tokens
- **Training**: 2T tokens, 87% code, 13% natural language
- **License**: MIT (fully open)

**Features**:

- State-of-the-art code generation
- Project-level code completion
- 87 programming languages
- Excellent instruction following
- Repository-level understanding

**Qwen 2.5 Coder** (Alibaba):

- **Sizes**: 1.5B, 7B, 14B, 32B
- **Context**: 128K tokens
- **Training**: 5.5T tokens
- **License**: Apache 2.0

**Features**:

- Long context for repository understanding
- Artifact generation
- Multilingual code
- Strong reasoning about code

**Specialized code models comparison**:

| Model | Best Use Case | Strength |
| --- | --- | --- |
| Code Llama 7B | IDE integration, completion | Fast, efficient |
| Code Llama 34B | Complex code generation | Quality, multi-step |
| DeepSeek Coder 6.7B | Project-level understanding | Repo context |
| DeepSeek Coder 33B | Professional development | Best quality |
| Qwen 2.5 Coder 7B | Long-context code | 128K window |

**Configuration example**:

```python
# DeepSeek Coder for code generation
llm = Llama(
    model_path="deepseek-coder-6.7b-instruct.Q4_K_M.gguf",
    n_gpu_layers=35,
    n_ctx=16384,
    temperature=0.2,  # Lower for code
    top_p=0.95
)

prompt = """Write a Python function that implements a binary search tree with insert, search, and delete operations."""

response = llm(prompt, max_tokens=1024)
```

### Instruction-Following

Models fine-tuned specifically for following instructions and conversational tasks.

**Characteristics of instruction-tuned models**:

- RLHF (Reinforcement Learning from Human Feedback)
- Supervised fine-tuning on instruction datasets
- Safety alignment
- Consistent formatting
- Reduced hallucination

**Top instruction models**:

**Llama 3.1 Instruct**:

- Excellent general instruction following
- Strong multi-turn conversations
- Tool use capable
- Safety aligned

**Mistral 7B Instruct v0.2**:

- Concise, accurate responses
- Good for production chatbots
- Less verbose than Llama
- Strong reasoning

**OpenHermes 2.5** (Mistral fine-tune):

- Trained on 1M examples
- Excellent instruction diversity
- Strong multi-domain
- Community favorite

**Nous-Hermes** (Various base models):

- Multiple variants (Llama, Mistral, Mixtral)
- High-quality instruction tuning
- Good for creative tasks
- Less restrictive alignment

**Zephyr 7B Beta**:

- Trained with DPO (Direct Preference Optimization)
- Very helpful and harmless
- Great for chatbots
- HuggingFace H4 team

**Instruction prompt format**:

Different models use different formats. Using the correct format is crucial:

```python
# Llama 3 format
llama3_prompt = """<|begin_of_text|><|start_header_id|>system<|end_header_id|>

You are a helpful assistant.<|eot_id|><|start_header_id|>user<|end_header_id|>

{user_message}<|eot_id|><|start_header_id|>assistant<|end_header_id|>"""

# Mistral/Mixtral format
mistral_prompt = """<s>[INST] {user_message} [/INST]"""

# ChatML format (OpenHermes, Zephyr)
chatml_prompt = """<|im_start|>system
You are a helpful assistant.<|im_end|>
<|im_start|>user
{user_message}<|im_end|>
<|im_start|>assistant
"""

# Alpaca format (older models)
alpaca_prompt = """Below is an instruction that describes a task. Write a response that appropriately completes the request.

### Instruction:
{instruction}

### Response:
"""
```

### Function Calling

Models capable of generating structured outputs for tool use and API calls.

**Function calling capabilities**:

- Structured output generation (JSON)
- Understanding available tools
- Selecting appropriate tools
- Generating valid function calls
- Chaining multiple calls

**Models with function calling**:

**Llama 3.1 Instruct** (8B, 70B, 405B):

- Native tool use support
- Built-in function calling
- JSON mode
- Strong structured output

**Mistral 7B Instruct v0.2**:

- JSON mode
- Function calling support
- Good for API integration

**Functionary** (Fine-tuned models):

- Specialized for function calling
- Multiple versions (v2, v3)
- Based on Llama/Mistral
- Excellent tool selection

**Hermes Function Calling**:

- NousResearch fine-tune
- Strong function calling
- Multiple sizes

**Function calling example**:

```python
import json

# Define available functions
functions = [
    {
        "name": "get_weather",
        "description": "Get current weather for a location",
        "parameters": {
            "type": "object",
            "properties": {
                "location": {"type": "string"},
                "unit": {"type": "string", "enum": ["celsius", "fahrenheit"]}
            },
            "required": ["location"]
        }
    }
]

# Prompt with function definitions
prompt = f"""You have access to the following functions:

{json.dumps(functions, indent=2)}

User: What's the weather in San Francisco?

Generate a function call to answer this question."""

response = llm(prompt, max_tokens=256, temperature=0.1)

# Parse function call from response
# {"name": "get_weather", "arguments": {"location": "San Francisco", "unit": "fahrenheit"}}
```

**Structured output mode** (some models):

```python
# Force JSON output
llm = Llama(
    model_path="llama-3.1-8b-instruct.Q4_K_M.gguf",
    n_gpu_layers=35
)

# JSON mode grammar
json_schema = {
    "type": "object",
    "properties": {
        "name": {"type": "string"},
        "age": {"type": "number"},
        "email": {"type": "string"}
    },
    "required": ["name", "age"]
}

response = llm(
    "Extract person information: John Doe, 30 years old, john@example.com",
    max_tokens=256,
    grammar=json_schema  # Force valid JSON
)
```

### Embedding Models

Specialized models for converting text to vector representations for semantic search and RAG.

**Note**: These are different from generative LLMs - they don't generate text, only embeddings.

**Popular embedding models**:

**BGE (BAAI General Embedding)**:

- **Sizes**: Small (33M), Base (110M), Large (335M)
- **Dimensions**: 384-1024
- **Languages**: Multilingual
- **Quality**: State-of-the-art

**E5 (Microsoft)**:

- **Variants**: Small, Base, Large, Mistral-based
- **Training**: Contrastive learning
- **Performance**: Excellent on MTEB

**all-MiniLM-L6-v2**:

- **Size**: 22M parameters
- **Speed**: Very fast
- **Quality**: Good for size
- **Popular**: Sentence-transformers default

**Nomic Embed**:

- **Context**: 8K tokens (long context)
- **Dimensions**: 768
- **Use case**: Long document embedding

**Embedding model usage**:

```python
from sentence_transformers import SentenceTransformer

# Load embedding model
model = SentenceTransformer('BAAI/bge-large-en-v1.5')

# Generate embeddings
texts = [
    "Machine learning is a subset of AI",
    "Deep learning uses neural networks",
    "Python is a programming language"
]

embeddings = model.encode(texts)

# Compute similarity
from sklearn.metrics.pairwise import cosine_similarity
similarity = cosine_similarity([embeddings[0]], [embeddings[1]])[0][0]
print(f"Similarity: {similarity:.3f}")
```

**RAG (Retrieval Augmented Generation) workflow**:

```python
# 1. Embed documents
documents = load_documents()
doc_embeddings = embedding_model.encode(documents)

# 2. Store in vector database
from qdrant_client import QdrantClient
client = QdrantClient(":memory:")
client.upsert(collection_name="docs", points=doc_embeddings)

# 3. Query
query = "What is machine learning?"
query_embedding = embedding_model.encode([query])

# 4. Retrieve relevant documents
results = client.search(
    collection_name="docs",
    query_vector=query_embedding[0],
    limit=3
)

# 5. Generate with context
context = "\n".join([r.payload['text'] for r in results])
prompt = f"Context: {context}\n\nQuestion: {query}\n\nAnswer:"
response = llm(prompt, max_tokens=256)
```

### Vision Models

Multimodal models capable of understanding both text and images.

**Llama 3.2 Vision** (11B, 90B):

- Native vision understanding
- Image + text input
- OCR, scene understanding, visual reasoning
- 128K context

**Phi-3.5 Vision**:

- 4.2B parameters
- Efficient vision model
- Good for edge deployment
- Strong OCR and chart understanding

**Qwen-VL** (2B, 7B):

- Image and text understanding
- Multiple image inputs
- Video understanding (some variants)
- Chinese + English

**LLaVA** (Various sizes):

- Built on Llama/Vicuna
- Visual instruction tuning
- Good general vision understanding
- Multiple versions (1.5, 1.6, NeXT)

**Vision model usage**:

```python
# Using llama.cpp with Llama 3.2 Vision
llm = Llama(
    model_path="llama-3.2-11b-vision-instruct.gguf",
    n_gpu_layers=40,
    n_ctx=8192,
    clip_model_path="mmproj-model.gguf"  # Vision encoder
)

# Generate with image
response = llm.create_chat_completion(
    messages=[
        {
            "role": "user",
            "content": [
                {"type": "text", "text": "What's in this image?"},
                {"type": "image_url", "image_url": {"url": "path/to/image.jpg"}}
            ]
        }
    ]
)
```

**Vision model use cases**:

- Document OCR and understanding
- Chart/graph analysis
- Visual question answering
- Image captioning
- UI/UX analysis
- Medical image analysis (with fine-tuning)
- Receipt/invoice processing

## Fine-Tuned Variants

### Chat-Optimized

Chat-optimized variants are instruction-tuned specifically for conversational AI.

**Key differences from base models**:

- Trained on conversational datasets
- Better multi-turn coherence
- Safety alignment
- Consistent personality
- Reduced harmful outputs
- Better refusal of inappropriate requests

**Suffix conventions**:

- `-Instruct`: General instruction following
- `-Chat`: Conversational optimization
- `-RLHF`: Reinforcement learning from human feedback
- `-DPO`: Direct preference optimization

**Examples**:

- `llama-3.1-8b-instruct` vs `llama-3.1-8b` (base)
- `mistral-7b-instruct-v0.2` vs `mistral-7b-v0.1` (base)
- `qwen2.5-7b-instruct` vs `qwen2.5-7b` (base)

**When to use base vs chat**:

**Base models**:

- Fine-tuning for specific tasks
- Completion (not chat)
- Research
- When you want to train your own behavior

**Chat/Instruct models**:

- Ready-to-use chatbots
- Interactive applications
- Instruction following
- Production deployment without fine-tuning

### Uncensored Models

Models with reduced or removed safety restrictions for specific use cases.

**Characteristics**:

- Respond to requests filtered models refuse
- More creative freedom
- No content policy restrictions
- May generate harmful content
- Responsibility on user

**Popular uncensored variants**:

- **Dolphin** (Eric Hartford): Llama/Mistral/Mixtral based
- **WizardLM-Uncensored**: Various sizes
- **Nous-Hermes**: Less restrictive than base
- **MythoMax**: Merged models for creative writing

**Use cases**:

- Creative writing (fiction, adult content)
- Research on model behavior
- Scenarios requiring uncensored historical content
- Ethical hacking/security research
- Private personal use

**Warnings**:

- May generate offensive content
- Not suitable for public-facing applications
- Legal considerations for deployment
- Ethical responsibility
- May violate terms of service

**Configuration**:

```python
# Dolphin Mistral example
llm = Llama(
    model_path="dolphin-2.6-mistral-7b.Q4_K_M.gguf",
    n_gpu_layers=35
)

# Note: No system prompt restricts behavior
prompt = "User: {request}\nAssistant:"
```

### Domain-Specific

Models fine-tuned for specific domains or industries.

**Medical**:

- **Med-PaLM**: Medical question answering (Google)
- **BioMistral**: Biomedical applications
- **Clinical-Llama**: Clinical notes, diagnoses
- **Considerations**: Requires careful validation, not for clinical use without approval

**Legal**:

- **SaulLM**: Legal text understanding (Mistral-based)
- **Legal-BERT**: Contract analysis
- **Case-law specific**: Various fine-tunes

**Finance**:

- **FinGPT**: Financial analysis
- **BloombergGPT**: Financial news and analysis
- **Risk assessment models**: Various

**Science/Research**:

- **Galactica**: Scientific knowledge (Meta)
- **PubMedGPT**: Biomedical literature
- **ChemGPT**: Chemistry-focused

**Creating domain-specific models**:

```python
# Fine-tuning workflow (simplified)
from transformers import AutoModelForCausalLM, TrainingArguments
from peft import LoraConfig, get_peft_model

# Load base model
model = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-2-7b-hf")

# Configure LoRA for efficient fine-tuning
lora_config = LoraConfig(
    r=16,
    lora_alpha=32,
    target_modules=["q_proj", "v_proj"],
    lora_dropout=0.05,
    bias="none",
    task_type="CAUSAL_LM"
)

model = get_peft_model(model, lora_config)

# Train on domain-specific data
# trainer.train()
```

## Popular Model Recommendations

### For 8GB VRAM

Optimal models for mainstream consumer GPUs (RTX 3060 Ti, RTX 2070 Super, RX 6600 XT).

**Best overall** - **Llama 3.1 8B Instruct Q5_K_M**:

- File size: ~5.8GB
- Performance: 40-60 tokens/second
- Quality: Excellent for size
- Context: 128K tokens
- Use case: General purpose, best quality on 8GB

```python
llm = Llama(
    model_path="llama-3.1-8b-instruct.Q5_K_M.gguf",
    n_gpu_layers=35,
    n_ctx=8192,
    n_batch=512
)
```

**Best for speed** - **Phi-3 Mini Q4_K_M**:

- File size: ~2.3GB
- Performance: 70-100 tokens/second
- Quality: Excellent for 3.8B
- Context: 128K tokens
- Use case: Fast responses, edge deployment

**Best for code** - **DeepSeek Coder 6.7B Q4_K_M**:

- File size: ~3.9GB
- Performance: 50-70 tokens/second
- Quality: State-of-the-art coding
- Context: 16K tokens
- Use case: Code generation, IDE integration

**Best multilingual** - **Qwen 2.5 7B Instruct Q5_K_M**:

- File size: ~5.2GB
- Performance: 40-60 tokens/second
- Quality: Best multilingual in class
- Context: 32K tokens
- Use case: Non-English languages, especially Asian

**Budget option** - **Mistral 7B Instruct v0.2 Q4_K_M**:

- File size: ~4.1GB
- Performance: 50-70 tokens/second
- Quality: Very good, production-ready
- Context: 32K tokens
- Use case: Reliable, well-tested, Apache 2.0 license

### For 16GB VRAM

Premium consumer and professional GPUs (RTX 4060 Ti 16GB, RTX 4080, A4000).

**Best overall** - **Mixtral 8x7B Instruct Q4_K_M**:

- File size: ~26GB (partial GPU + CPU)
- Performance: 25-35 tokens/second
- Quality: Near GPT-3.5 level
- Context: 32K tokens
- Use case: Professional applications

```python
llm = Llama(
    model_path="mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf",
    n_gpu_layers=25,  # Partial offloading
    n_threads=8,      # CPU assists
    n_ctx=16384
)
```

**Alternative** - **Yi 34B Chat Q4_K_M**:

- File size: ~19GB
- Performance: 15-25 tokens/second
- Quality: Excellent reasoning
- Context: 200K tokens
- Use case: Long-context analysis

**High-speed option** - **Llama 3.1 8B Instruct Q8_0**:

- File size: ~8.5GB
- Performance: 50-70 tokens/second
- Quality: Maximum quality for 8B
- Context: 128K tokens
- Use case: When you want best 8B quality

**Best for code** - **DeepSeek Coder 33B Instruct Q3_K_M**:

- File size: ~14GB
- Performance: 15-25 tokens/second
- Quality: Professional-grade coding
- Context: 16K tokens
- Use case: Complex code generation

### For 24GB+ VRAM

High-end consumer and professional GPUs (RTX 3090, RTX 4090, A5000, A6000).

**Best overall** - **Llama 3.1 70B Instruct Q4_K_M**:

- File size: ~39GB (with smart offloading)
- Performance: 10-20 tokens/second
- Quality: GPT-3.5 to GPT-4 level
- Context: 128K tokens
- Use case: Professional applications, research

```python
llm = Llama(
    model_path="llama-3.1-70b-instruct.Q4_K_M.gguf",
    n_gpu_layers=50,  # Partial offloading
    n_threads=16,     # CPU handles some layers
    n_ctx=8192
)
```

**Maximum quality** - **Qwen 2.5 72B Instruct Q4_K_M**:

- File size: ~41GB
- Performance: 10-20 tokens/second
- Quality: State-of-the-art multilingual
- Context: 128K tokens
- Use case: Best available open-source quality

**MoE option** - **Mixtral 8x7B Instruct Q6_K**:

- File size: ~31GB
- Performance: 30-40 tokens/second
- Quality: High quality MoE
- Context: 32K tokens
- Use case: When speed matters with good quality

**Fully on GPU** - **Mixtral 8x7B Instruct Q5_K_M**:

- File size: ~29GB
- Performance: 35-45 tokens/second
- Context: 32K tokens
- Use case: Maximum speed with excellent quality

### For CPU-Only

Running models without GPU on modern CPUs (Ryzen 5000+, Intel 12th gen+).

**Best overall** - **Phi-3 Mini Q4_K_M**:

- File size: ~2.3GB
- Performance: 10-20 tokens/second
- Quality: Excellent for size
- RAM: 4GB
- Use case: Best quality/speed on CPU

```python
llm = Llama(
    model_path="phi-3-mini-128k-instruct.Q4_K_M.gguf",
    n_gpu_layers=0,
    n_threads=os.cpu_count(),
    n_ctx=8192,
    use_mlock=True,
    use_mmap=True
)
```

**Ultra-fast** - **TinyLlama 1.1B Q4_K_M**:

- File size: ~0.7GB
- Performance: 20-40 tokens/second
- Quality: Basic but usable
- RAM: 2GB
- Use case: Maximum speed, simple tasks

**Balanced** - **Llama 3.2 3B Instruct Q4_K_M**:

- File size: ~1.9GB
- Performance: 8-15 tokens/second
- Quality: Good for size
- RAM: 4GB
- Use case: Good balance of quality and speed

**Best quality** - **Llama 3.1 8B Instruct Q4_K_M**:

- File size: ~4.9GB
- Performance: 3-8 tokens/second
- Quality: Excellent (slow but good)
- RAM: 8GB
- Use case: When quality matters more than speed

**Configuration tips for CPU**:

```python
# Optimize for CPU
import os

llm = Llama(
    model_path=model_path,
    n_gpu_layers=0,
    n_threads=os.cpu_count(),  # Use all cores
    n_batch=256,                # Smaller batches for CPU
    use_mlock=True,            # Lock in RAM
    use_mmap=True,             # Memory map file
    n_ctx=4096                 # Reduce if needed
)
```

## Model Sources

### Hugging Face

Hugging Face is the primary repository for open-source LLMs, offering the largest collection of models and quantized variants.

**Main hubs**:

- **Official releases**: meta-llama, mistralai, microsoft, alibaba-cloud
- **Quantized models**: TheBloke, mradermacher, bartowski, LoneStriker
- **Fine-tuned variants**: NousResearch, Open-Orca, WizardLM, teknium

**Finding models**:

```bash
# Search Hugging Face
https://huggingface.co/models?search=llama

# Filter by task, size, license
```

**Downloading models**:

```bash
# Using huggingface-cli
pip install huggingface-hub

# Download specific model
huggingface-cli download TheBloke/Llama-2-7B-Chat-GGUF \
    llama-2-7b-chat.Q4_K_M.gguf \
    --local-dir ./models

# Download entire repo
git lfs install
git clone https://huggingface.co/meta-llama/Llama-2-7b-hf
```

**Python API**:

```python
from huggingface_hub import hf_hub_download

# Download single file
model_path = hf_hub_download(
    repo_id="TheBloke/Llama-2-7B-Chat-GGUF",
    filename="llama-2-7b-chat.Q4_K_M.gguf",
    local_dir="./models"
)

# Load model
from llama_cpp import Llama
llm = Llama(model_path=model_path, n_gpu_layers=35)
```

**Key contributors**:

- **TheBloke**: Largest quantization library (GGUF, GPTQ, AWQ)
- **mradermacher**: High-quality GGUF quantizations, K-quant focus
- **bartowski**: Recent models, quick turnaround
- **NousResearch**: Quality fine-tunes (Hermes, Nous)
- **Open-Orca**: Instruction-tuned variants

### Ollama Library

Ollama provides a curated, pre-configured library of models with one-command installation.

**Advantages**:

- Pre-configured optimal settings
- Automatic format handling
- Easy model management
- Modelfile system for customization
- Built-in model versioning

**Using Ollama**:

```bash
# Search available models
ollama list

# Pull a model (auto-downloads and configures)
ollama pull llama3.2:3b
ollama pull mistral:7b
ollama pull codellama:13b

# List installed models
ollama list

# Remove model
ollama rm llama2:7b

# Show model info
ollama show llama3.2:3b
```

**Popular Ollama models**:

```bash
# Latest Llama
ollama pull llama3.2:1b        # Ultra-fast
ollama pull llama3.2:3b        # Balanced
ollama pull llama3.1:8b        # High quality
ollama pull llama3.1:70b       # Best quality

# Mistral family
ollama pull mistral:7b         # Production-ready
ollama pull mixtral:8x7b       # MoE model

# Code models
ollama pull codellama:13b      # Code generation
ollama pull deepseek-coder:6.7b # State-of-the-art

# Small models
ollama pull phi3:mini          # Microsoft Phi-3
ollama pull qwen2.5:3b        # Multilingual
```

**Custom Modelfiles**:

```bash
# Create custom model
cat > Modelfile <<EOF
FROM llama3.1:8b

# Set temperature
PARAMETER temperature 0.8

# Set system message
SYSTEM You are a helpful coding assistant.
EOF

ollama create my-coding-assistant -f Modelfile
ollama run my-coding-assistant
```

**Ollama vs manual GGUF**:

| Feature | Ollama | Manual GGUF |
| --- | --- | --- |
| Setup | One command | Download + configure |
| Configuration | Pre-optimized | Manual tuning |
| Updates | `ollama pull` | Manual download |
| Formats | GGUF only | Any format |
| Customization | Modelfile | Full control |
| Storage | ~/.ollama/models | User-defined |

### TheBloke

TheBloke (Tom Jobbins) is the most prolific quantizer, providing GGUF, GPTQ, and AWQ versions of nearly every significant open-source LLM.

**What TheBloke provides**:

- GGUF quantizations (Q2 through Q8, all K-variants)
- GPTQ quantizations (4-bit, various group sizes)
- AWQ quantizations
- Model cards with usage instructions
- Consistent naming conventions
- Quick availability after model releases

**Naming conventions**:

```text
Format: ModelName-Size-Variant-Format
Examples:
- Llama-2-7B-Chat-GGUF
- Mistral-7B-Instruct-v0.2-GGUF
- CodeLlama-13B-Instruct-GPTQ
- Mixtral-8x7B-Instruct-v0.1-GGUF
```

**Finding specific quantization**:

```bash
# Repository structure
TheBloke/Llama-2-7B-Chat-GGUF/
├── llama-2-7b-chat.Q2_K.gguf
├── llama-2-7b-chat.Q3_K_M.gguf
├── llama-2-7b-chat.Q4_K_M.gguf  # Recommended
├── llama-2-7b-chat.Q5_K_M.gguf
├── llama-2-7b-chat.Q6_K.gguf
└── llama-2-7b-chat.Q8_0.gguf
```

**Download script**:

```bash
#!/bin/bash

MODEL_REPO="TheBloke/Llama-2-7B-Chat-GGUF"
QUANT="Q4_K_M"
MODEL_FILE="llama-2-7b-chat.${QUANT}.gguf"

huggingface-cli download \
    "$MODEL_REPO" \
    "$MODEL_FILE" \
    --local-dir ./models \
    --local-dir-use-symlinks False
```

**Quality recommendations by TheBloke**:

- **Q4_K_M**: Recommended default (best balance)
- **Q5_K_M**: Higher quality, slight size increase
- **Q6_K**: Near-full quality
- **Q8_0**: Maximum quality, 2x size
- **Q4_K_S**: Faster, slight quality loss
- **Q3_K_M**: Smaller, noticeable quality loss

### Other Repositories

**GPT4All**:

- Curated collection of models
- Focus on CPU-friendly models
- Desktop application
- Cross-platform support
- <https://gpt4all.io>

**LM Studio Models**:

- Integrated with LM Studio app
- Pre-configured settings
- Discovery interface
- One-click download
- Quality ratings

**Oobabooga Text Generation WebUI**:

- Models tab with integrated downloader
- Supports multiple formats
- Automatic configuration
- Built-in model loader

**Direct from developers**:

- Meta AI (Llama): <https://ai.meta.com>
- Mistral AI: <https://mistral.ai>
- Microsoft (Phi): <https://huggingface.co/microsoft>
- Google (Gemma): <https://huggingface.co/google>
- Alibaba (Qwen): <https://huggingface.co/Qwen>

**Converting models yourself**:

```bash
# Convert PyTorch model to GGUF
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp

python convert.py /path/to/pytorch/model \
    --outfile output.gguf \
    --outtype f16

# Quantize GGUF
./quantize output.gguf output.Q4_K_M.gguf Q4_K_M
```

## Version Management

### Tracking Model Versions

Models evolve through versions with improvements and changes. Tracking versions ensures reproducibility and quality control.

**Version naming patterns**:

```text
Llama Series:
- Llama 2 (July 2023)
- Llama 3 (April 2024)
- Llama 3.1 (July 2024)
- Llama 3.2 (September 2024)

Mistral Series:
- Mistral 7B v0.1
- Mistral 7B Instruct v0.2
- Mistral 7B Instruct v0.3

Qwen Series:
- Qwen 1.5
- Qwen 2
- Qwen 2.5
```

**Version metadata**:

```python
import json

model_info = {
    "name": "Llama-3.1-8B-Instruct",
    "version": "3.1",
    "release_date": "2024-07-23",
    "quantization": "Q4_K_M",
    "source": "TheBloke",
    "downloaded": "2024-12-15",
    "hash": "sha256:abc123...",
    "size_bytes": 4920000000,
    "performance_baseline": {
        "tokens_per_second": 45.2,
        "vram_usage_gb": 5.1
    }
}

with open("models/llama-3.1-8b-instruct.json", "w") as f:
    json.dump(model_info, f, indent=2)
```

**Version control best practices**:

1. **Document versions**: Keep metadata file for each model
2. **Test before replacing**: Benchmark new version vs old
3. **Backup configs**: Save generation parameters
4. **Track performance**: Monitor quality and speed changes
5. **Staged rollout**: Test in development before production

**Model registry**:

```python
class ModelRegistry:
    def __init__(self, registry_path="model_registry.json"):
        self.registry_path = registry_path
        self.models = self.load_registry()
    
    def load_registry(self):
        if os.path.exists(self.registry_path):
            with open(self.registry_path) as f:
                return json.load(f)
        return {}
    
    def register_model(self, model_id, metadata):
        self.models[model_id] = {
            **metadata,
            "registered_at": datetime.now().isoformat()
        }
        self.save_registry()
    
    def save_registry(self):
        with open(self.registry_path, 'w') as f:
            json.dump(self.models, f, indent=2)
    
    def get_model(self, model_id):
        return self.models.get(model_id)

# Usage
registry = ModelRegistry()
registry.register_model("llama-3.1-8b-q4", {
    "path": "./models/llama-3.1-8b-instruct.Q4_K_M.gguf",
    "version": "3.1",
    "size_gb": 4.9,
    "parameters": "8B"
})
```

## Testing New Models

### Evaluation Workflow

Systematic testing ensures you select the right model for your needs.

**Phase 1: Quick viability test (5 minutes)**:

```python
def quick_test(model_path):
    """Rapid viability check."""
    try:
        # Load model
        start = time.time()
        llm = Llama(model_path=model_path, n_gpu_layers=35, n_ctx=2048)
        load_time = time.time() - start
        
        # Test inference
        test_prompt = "Explain artificial intelligence in one sentence."
        start = time.time()
        response = llm(test_prompt, max_tokens=50)
        inference_time = time.time() - start
        
        # Basic quality check
        output = response['choices'][0]['text']
        has_content = len(output.strip()) > 20
        is_coherent = not any(char * 5 in output for char in output)
        
        return {
            "viable": has_content and is_coherent,
            "load_time": load_time,
            "inference_time": inference_time,
            "tokens_per_second": 50 / inference_time
        }
    except Exception as e:
        return {"viable": False, "error": str(e)}

result = quick_test("./models/new-model.gguf")
print(f"Model viable: {result['viable']}")
print(f"Speed: {result['tokens_per_second']:.1f} t/s")
```

**Phase 2: Quality evaluation (30 minutes)**:

```python
# Standardized test prompts
test_suite = {
    "reasoning": [
        "If all roses are flowers and some flowers fade quickly, can we conclude that some roses fade quickly?",
        "A farmer has 17 sheep. All but 9 die. How many are left?"
    ],
    "knowledge": [
        "What is the capital of Australia?",
        "Who wrote 'To Kill a Mockingbird'?"
    ],
    "instruction": [
        "Write a Python function to calculate factorial.",
        "Summarize the concept of quantum entanglement."
    ],
    "creativity": [
        "Write a haiku about artificial intelligence.",
        "Create a short story opening about a robot discovering emotions."
    ]
}

def evaluate_quality(model_path, test_suite):
    llm = Llama(model_path=model_path, n_gpu_layers=35)
    results = {}
    
    for category, prompts in test_suite.items():
        category_results = []
        for prompt in prompts:
            response = llm(prompt, max_tokens=512, temperature=0.7)
            category_results.append({
                "prompt": prompt,
                "response": response['choices'][0]['text']
            })
        results[category] = category_results
    
    return results

# Manual review of quality
quality_results = evaluate_quality("./models/model.gguf", test_suite)
```

**Phase 3: Performance benchmarking (1 hour)**:

```python
def benchmark_performance(model_path, num_runs=10):
    """Comprehensive performance test."""
    llm = Llama(model_path=model_path, n_gpu_layers=35)
    
    metrics = {
        "short": [],   # 128 tokens
        "medium": [],  # 512 tokens
        "long": []     # 2048 tokens
    }
    
    lengths = {"short": 128, "medium": 512, "long": 2048}
    
    for length_type, max_tokens in lengths.items():
        for _ in range(num_runs):
            start = time.time()
            response = llm(
                "Write a detailed explanation",
                max_tokens=max_tokens
            )
            duration = time.time() - start
            
            actual_tokens = len(response['choices'][0]['text'].split())
            tps = actual_tokens / duration
            
            metrics[length_type].append(tps)
    
    # Calculate statistics
    results = {}
    for length_type, speeds in metrics.items():
        results[length_type] = {
            "mean": statistics.mean(speeds),
            "median": statistics.median(speeds),
            "std_dev": statistics.stdev(speeds),
            "min": min(speeds),
            "max": max(speeds)
        }
    
    return results
```

**Phase 4: Resource monitoring (ongoing)**:

```python
import psutil
import torch

def monitor_resources(model_path, duration_minutes=10):
    """Monitor resource usage over time."""
    llm = Llama(model_path=model_path, n_gpu_layers=35)
    
    samples = []
    end_time = time.time() + (duration_minutes * 60)
    
    while time.time() < end_time:
        # Generate inference
        llm("Test prompt", max_tokens=256)
        
        # Sample resources
        ram_used = psutil.virtual_memory().used / 1e9
        
        if torch.cuda.is_available():
            vram_used = torch.cuda.memory_allocated(0) / 1e9
            gpu_temp = torch.cuda.temperature()
        else:
            vram_used = 0
            gpu_temp = 0
        
        samples.append({
            "timestamp": time.time(),
            "ram_gb": ram_used,
            "vram_gb": vram_used,
            "gpu_temp": gpu_temp
        })
        
        time.sleep(10)
    
    return {
        "avg_ram": statistics.mean(s["ram_gb"] for s in samples),
        "max_ram": max(s["ram_gb"] for s in samples),
        "avg_vram": statistics.mean(s["vram_gb"] for s in samples),
        "max_vram": max(s["vram_gb"] for s in samples),
        "max_temp": max(s["gpu_temp"] for s in samples)
    }
```

**Evaluation checklist**:

- [ ] Model loads without errors
- [ ] Inference speed acceptable (>10 t/s)
- [ ] VRAM usage within limits
- [ ] Response quality matches expectations
- [ ] Instruction following works
- [ ] No frequent hallucinations
- [ ] Consistent performance over time
- [ ] Temperature stability
- [ ] Multi-turn conversations coherent
- [ ] Handles edge cases gracefully

## Migration Strategies

### Switching Between Models

Smoothly transitioning between models in production systems requires careful planning.

**Migration approaches**:

**1. Blue-Green deployment**:

```python
class ModelManager:
    def __init__(self):
        self.active_model = "blue"  # or "green"
        self.models = {
            "blue": None,
            "green": None
        }
    
    def load_model(self, slot, model_path):
        """Load model into specified slot."""
        self.models[slot] = Llama(
            model_path=model_path,
            n_gpu_layers=35
        )
    
    def switch_active(self):
        """Switch active model."""
        self.active_model = "green" if self.active_model == "blue" else "blue"
    
    def generate(self, prompt, **kwargs):
        """Generate using active model."""
        active = self.models[self.active_model]
        return active(prompt, **kwargs)

# Usage
manager = ModelManager()

# Load current production model
manager.load_model("blue", "./models/llama-3.1-8b.gguf")

# Test new model in green slot
manager.load_model("green", "./models/llama-3.2-3b.gguf")

# Test green slot
test_response = manager.models["green"]("test prompt")

# If satisfied, switch
manager.switch_active()

# Old model still available for rollback
```

**2. Canary deployment**:

```python
import random

class CanaryModelManager:
    def __init__(self, primary_path, canary_path, canary_percentage=10):
        self.primary = Llama(model_path=primary_path, n_gpu_layers=35)
        self.canary = Llama(model_path=canary_path, n_gpu_layers=35)
        self.canary_percentage = canary_percentage
        self.metrics = {"primary": [], "canary": []}
    
    def generate(self, prompt, **kwargs):
        """Route to primary or canary based on percentage."""
        use_canary = random.random() * 100 < self.canary_percentage
        
        model = self.canary if use_canary else self.primary
        model_name = "canary" if use_canary else "primary"
        
        start = time.time()
        response = model(prompt, **kwargs)
        duration = time.time() - start
        
        # Track metrics
        self.metrics[model_name].append({
            "duration": duration,
            "success": True
        })
        
        return response
    
    def increase_canary(self, new_percentage):
        """Gradually increase canary traffic."""
        self.canary_percentage = min(new_percentage, 100)
    
    def get_metrics(self):
        """Compare performance."""
        return {
            model: {
                "count": len(metrics),
                "avg_duration": statistics.mean(m["duration"] for m in metrics)
            }
            for model, metrics in self.metrics.items()
            if metrics
        }

# Usage
manager = CanaryModelManager(
    primary_path="./models/llama-3.1-8b.gguf",
    canary_path="./models/llama-3.2-3b.gguf",
    canary_percentage=10  # Start with 10%
)

# Gradually increase canary traffic
# 10% -> 25% -> 50% -> 100%
```

**3. Gradual rollout**:

```python
class GradualRollout:
    def __init__(self):
        self.models = {}
        self.user_assignments = {}  # user_id -> model_version
    
    def add_model_version(self, version, model_path):
        """Add new model version."""
        self.models[version] = Llama(
            model_path=model_path,
            n_gpu_layers=35
        )
    
    def assign_user_cohort(self, user_id, version, cohort_size=0.1):
        """Assign users to model versions."""
        # Simple hash-based assignment
        if user_id not in self.user_assignments:
            user_hash = hash(user_id) % 100
            if user_hash < cohort_size * 100:
                self.user_assignments[user_id] = version
            else:
                self.user_assignments[user_id] = "stable"
    
    def generate_for_user(self, user_id, prompt, **kwargs):
        """Generate using user's assigned model."""
        version = self.user_assignments.get(user_id, "stable")
        model = self.models.get(version, self.models["stable"])
        return model(prompt, **kwargs)

# Usage
rollout = GradualRollout()
rollout.add_model_version("stable", "./models/llama-3.1-8b.gguf")
rollout.add_model_version("v2", "./models/llama-3.2-3b.gguf")

# 10% of users get new version
for user_id in user_database:
    rollout.assign_user_cohort(user_id, "v2", cohort_size=0.1)
```

**Migration checklist**:

- [ ] Benchmark new model performance
- [ ] Test with production data sample
- [ ] Compare quality metrics
- [ ] Verify prompt format compatibility
- [ ] Check context window requirements
- [ ] Test edge cases and error handling
- [ ] Monitor resource usage
- [ ] Have rollback plan ready
- [ ] Document parameter changes
- [ ] Train team on new model characteristics

**Prompt format migration**:

```python
def convert_prompt_format(prompt, from_format, to_format):
    """Convert between different prompt formats."""
    
    # Llama 2 -> Llama 3
    if from_format == "llama2" and to_format == "llama3":
        # Llama 2: [INST] prompt [/INST]
        # Llama 3: <|begin_of_text|><|start_header_id|>user<|end_header_id|>...
        prompt = prompt.replace("[INST]", "<|start_header_id|>user<|end_header_id|>\n\n")
        prompt = prompt.replace("[/INST]", "<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n")
        prompt = "<|begin_of_text|>" + prompt
        return prompt
    
    # Add other conversions as needed
    return prompt
```

**A/B testing results analysis**:

```python
def analyze_ab_test(model_a_results, model_b_results):
    """Statistical comparison of two models."""
    from scipy import stats
    
    # Compare response times
    ttest_time = stats.ttest_ind(
        [r['duration'] for r in model_a_results],
        [r['duration'] for r in model_b_results]
    )
    
    # Compare quality scores (if available)
    ttest_quality = stats.ttest_ind(
        [r['quality_score'] for r in model_a_results],
        [r['quality_score'] for r in model_b_results]
    )
    
    return {
        "time_difference_significant": ttest_time.pvalue < 0.05,
        "quality_difference_significant": ttest_quality.pvalue < 0.05,
        "model_a_faster": ttest_time.statistic < 0,
        "model_b_better_quality": ttest_quality.statistic > 0
    }
```

## Summary

Model selection for local LLM deployment requires balancing multiple factors:

1. **Task requirements**: Match model capabilities to your use case
2. **Hardware constraints**: Choose models that fit your VRAM/RAM
3. **Quality needs**: Balance between model size and output quality
4. **Quantization tradeoffs**: Understand memory vs quality tradeoffs
5. **Format selection**: Choose GGUF for versatility, GPTQ for GPU speed
6. **License compliance**: Ensure proper licensing for your use case
7. **Testing and validation**: Always test before production deployment

**Quick selection guide**:

- **Limited hardware (8GB VRAM)**: Llama 3.1 8B Q4/Q5, Phi-3 Mini
- **Balanced (16GB VRAM)**: Mixtral 8x7B Q4, Yi 34B Q4
- **High-end (24GB+ VRAM)**: Llama 3.1 70B Q4, Qwen 2.5 72B
- **Code generation**: DeepSeek Coder, Code Llama, Qwen Coder
- **Multilingual**: Qwen 2.5, Mixtral (European), Command R
- **Speed priority**: Phi-3 Mini, Llama 3.2 3B, Mistral 7B
- **Quality priority**: Llama 3.1 70B, Qwen 2.5 72B, Mixtral 8x22B

The landscape of local LLMs evolves rapidly. Stay informed through community forums (Reddit r/LocalLLaMA, HuggingFace forums), benchmark leaderboards (Chatbot Arena, Open LLM Leaderboard), and hands-on testing with your specific use cases.
