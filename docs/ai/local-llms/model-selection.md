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

Choosing the right local LLM.

## Model Families

### Llama Family

Meta's open models (Llama 2, Llama 3).

### Mistral Family

Mistral AI's models.

### Falcon

TII's Falcon models.

### Phi

Microsoft's small models.

### Gemma

Google's open models.

### Qwen

Alibaba's multilingual models.

### Others

Additional open-source options.

## Model Sizes

### Small Models (1-7B parameters)

Lightweight, fast inference.

### Medium Models (7-13B parameters)

Balanced performance.

### Large Models (13-34B parameters)

Better quality, higher requirements.

### Extra Large Models (34B+ parameters)

Top performance, demanding hardware.

## Quantization Levels

### No Quantization (FP16/FP32)

Full precision.

### 8-bit Quantization

Minimal quality loss.

### 4-bit Quantization (GPTQ, GGUF Q4)

Balanced compression.

### 2-bit and 3-bit Quantization

Aggressive compression.

## Model Formats

### GGUF

Llama.cpp format.

### GPTQ

GPU-optimized format.

### AWQ

Activation-aware quantization.

### ONNX

Cross-platform format.

### Original PyTorch

Native format.

## Selection Criteria

### Task Requirements

Matching model to use case.

### Hardware Constraints

Fitting models to available resources.

### Language Support

Multilingual capabilities.

### License Considerations

Commercial use restrictions.

### Context Length

Input token limits.

### Benchmark Performance

Comparing model quality.

## Specialized Models

### Code Generation

Programming-focused models.

### Instruction-Following

Chat and assistant models.

### Function Calling

Tool-use capable models.

### Embedding Models

Semantic search models.

### Vision Models

Multimodal capabilities.

## Fine-Tuned Variants

### Chat-Optimized

Conversational versions.

### Uncensored Models

Reduced content filtering.

### Domain-Specific

Specialized fine-tunes.

## Evaluation Criteria

### Quality Metrics

Benchmark scores.

### Speed Testing

Inference performance.

### Memory Usage

Actual VRAM consumption.

### Stability

Reliability and consistency.

## Popular Model Recommendations

### For 8GB VRAM

Best options for limited hardware.

### For 16GB VRAM

Mid-range configurations.

### For 24GB+ VRAM

High-end systems.

### For CPU-Only

Running without GPU.

## Model Sources

### Hugging Face

Primary model repository.

### Ollama Library

Pre-configured models.

### TheBloke

Quantized model variants.

### Other Repositories

Additional sources.

## Version Management

Tracking model versions.

## Testing New Models

Evaluation workflow.

## Migration Strategies

Switching between models.
