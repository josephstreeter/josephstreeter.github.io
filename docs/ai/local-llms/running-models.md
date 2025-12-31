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

How to run local LLMs effectively.

## Basic Execution

### Command Line Interface

Running models from terminal.

### Web Interfaces

Using GUI applications.

### Python Scripts

Programmatic access.

### API Calls

RESTful API usage.

## Inference Parameters

### Temperature

Controlling randomness.

### Top-p and Top-k

Sampling strategies.

### Max Tokens

Response length limits.

### Context Window

Managing conversation history.

### Stop Sequences

Controlling output termination.

### Repetition Penalty

Reducing repetitive text.

## Loading Models

### Model Loading

Initial model load process.

### Hot Swapping

Switching models dynamically.

### Multiple Models

Running concurrent models.

### Model Caching

Keeping models in memory.

## GPU Utilization

### GPU Layers

Offloading layers to GPU.

### Batch Size

Optimizing throughput.

### Memory Management

Managing VRAM usage.

### Multi-GPU Setup

Distributing across GPUs.

## CPU Fallback

### CPU-Only Inference

Running without GPU.

### Hybrid CPU/GPU

Partial GPU offloading.

### Performance Expectations

CPU inference speeds.

## Conversation Management

### Context Preservation

Maintaining conversation state.

### System Prompts

Setting behavior guidelines.

### Multi-Turn Dialogue

Managing conversations.

### Context Reset

Clearing conversation history.

## Batch Processing

### Bulk Inference

Processing multiple requests.

### Queue Management

Handling request queues.

### Asynchronous Processing

Non-blocking inference.

## Streaming Responses

### Token Streaming

Real-time output generation.

### Implementation

Setting up streaming.

### UI Integration

Displaying streaming text.

## Performance Monitoring

### Inference Speed

Tokens per second.

### Memory Usage

Tracking resource consumption.

### Temperature Monitoring

Hardware monitoring.

### Logging

Recording performance data.

## Error Handling

### Out of Memory

Handling OOM errors.

### Timeout Management

Dealing with slow responses.

### Model Failures

Recovery strategies.

## Session Management

### Persistence

Saving and loading sessions.

### State Management

Managing application state.

### Cleanup

Resource deallocation.

## Integration Patterns

### REST API Server

Creating API endpoints.

### WebSocket Connections

Real-time communication.

### Message Queues

Async processing patterns.

## CLI Tools

### Ollama Commands

Using Ollama CLI.

### llama.cpp Usage

Command-line options.

### Custom Scripts

Building your own tools.

## Automation

### Scheduled Inference

Automated tasks.

### Batch Jobs

Bulk processing.

### Monitoring Scripts

Health checks.

## Best Practices

### Resource Management

Efficient resource use.

### Error Handling Strategies

Robust error management.

### Logging and Monitoring

Comprehensive logging.

## Common Workflows

Typical usage patterns.
