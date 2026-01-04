---
title: "Troubleshooting Local LLMs"
description: "Common issues and solutions for running local LLMs"
author: "Joseph Streeter"
ms.date: "2025-12-31"
ms.topic: "troubleshooting"
keywords: ["troubleshooting", "debugging", "errors", "problems", "solutions"]
uid: docs.ai.local-llms.troubleshooting
---

## Overview

Running local Large Language Models (LLMs) can present various technical challenges across hardware, software, and configuration domains. This comprehensive troubleshooting guide provides systematic diagnostic approaches and proven solutions for common and complex issues encountered when deploying and operating local LLMs.

This guide covers:

- **Installation and setup issues**: Dependencies, drivers, permissions
- **Memory management**: OOM errors, leaks, optimization
- **Performance optimization**: Speed, latency, GPU utilization
- **Model loading problems**: Formats, corruption, compatibility
- **Hardware issues**: GPU, CUDA, thermal management
- **Output quality**: Repetition, hallucinations, formatting
- **Network and API**: Connectivity, timeouts, authentication
- **Platform-specific solutions**: Windows, Linux, macOS, WSL

## Installation Issues

### Failed Dependencies

Library conflicts and dependency issues are among the most common installation problems when setting up local LLM environments.

**Symptom**: Error messages about missing modules, version conflicts, or incompatible packages during installation.

**Common causes**:

- Conflicting Python package versions
- Missing system libraries
- Incompatible package dependencies
- Wrong Python version

**Solutions**:

**1. Use virtual environments** (always recommended):

```bash
# Create isolated environment
python -m venv llm_env
source llm_env/bin/activate  # Linux/Mac
# or
llm_env\Scripts\activate  # Windows

# Install packages
pip install llama-cpp-python torch transformers
```

**2. Resolve package conflicts**:

```bash
# Check for conflicts
pip check

# Show package dependencies
pip show llama-cpp-python

# Force reinstall with no cache
pip install --no-cache-dir --force-reinstall llama-cpp-python

# Install specific compatible versions
pip install torch==2.1.0 transformers==4.36.0
```

**3. Install system dependencies**:

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install build-essential cmake python3-dev

# Fedora/RHEL
sudo dnf install gcc gcc-c++ cmake python3-devel

# macOS
brew install cmake python@3.11
```

**4. Fix CMake build issues** (for llama-cpp-python):

```bash
# Install with specific options
CMAKE_ARGS="-DLLAMA_CUBLAS=on" pip install llama-cpp-python

# For Metal (macOS)
CMAKE_ARGS="-DLLAMA_METAL=on" pip install llama-cpp-python

# For CPU only
CMAKE_ARGS="-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS" pip install llama-cpp-python
```

**5. Address specific library errors**:

```python
# ImportError: libcudart.so not found
# Add CUDA to library path
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# ImportError: No module named 'torch'
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# ModuleNotFoundError: No module named 'tiktoken'
pip install tiktoken
```

**Prevention**:

```bash
# Use requirements.txt with pinned versions
cat > requirements.txt << EOF
torch==2.1.2
transformers==4.36.2
llama-cpp-python==0.2.27
sentencepiece==0.1.99
EOF

pip install -r requirements.txt
```

### Driver Problems

GPU driver issues prevent hardware acceleration and can cause crashes or poor performance.

**Symptom**: CUDA errors, GPU not detected, driver version mismatches, or application crashes during GPU operations.

**Diagnosis**:

```bash
# Check NVIDIA driver
nvidia-smi

# Check CUDA version
nvcc --version

# Check PyTorch CUDA availability
python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}, Version: {torch.version.cuda}')"

# Check GPU details
python -c "import torch; print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'No GPU')"
```

**Solutions**:

**1. Update NVIDIA drivers** (Linux):

```bash
# Ubuntu - recommended PPA method
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt update
sudo apt install nvidia-driver-545  # Or latest version

# Verify installation
nvidia-smi

# Reboot if needed
sudo reboot
```

**2. Install CUDA Toolkit**:

```bash
# Download from NVIDIA website or use package manager
# Ubuntu example
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/12.3.0/local_installers/cuda-repo-ubuntu2204-12-3-local_12.3.0-545.23.06-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu2204-12-3-local_12.3.0-545.23.06-1_amd64.deb
sudo cp /var/cuda-repo-ubuntu2204-12-3-local/cuda-*-keyring.gpg /usr/share/keyrings/
sudo apt update
sudo apt install cuda
```

**3. Install PyTorch with correct CUDA version**:

```bash
# For CUDA 12.1
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# For CUDA 11.8
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Verify
python -c "import torch; print(torch.cuda.is_available())"
```

**4. Fix driver/CUDA version mismatch**:

```bash
# Check compatibility
nvidia-smi  # Shows CUDA version supported by driver

# Install matching PyTorch version
# Driver 545+ supports CUDA 12.x
pip install torch --index-url https://download.pytorch.org/whl/cu121
```

**5. AMD GPU (ROCm) setup**:

```bash
# Install ROCm (Ubuntu)
sudo apt update
sudo apt install rocm-hip-sdk

# Install PyTorch for ROCm
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm5.7
```

**Windows driver updates**:

```powershell
# Download from NVIDIA website: https://www.nvidia.com/Download/index.aspx
# Or use GeForce Experience for automatic updates

# Verify installation
nvidia-smi

# Check CUDA
nvcc --version
```

### Permission Errors

File system permission issues prevent model loading, cache writes, or configuration access.

**Symptom**: "Permission denied", "Access is denied", or "Cannot write to directory" errors.

**Common scenarios**:

**1. Model directory permissions**:

```bash
# Check permissions
ls -la ~/.cache/huggingface/

# Fix ownership (Linux)
sudo chown -R $USER:$USER ~/.cache/huggingface/
chmod -R 755 ~/.cache/huggingface/

# Create directory with correct permissions
mkdir -p ~/models
chmod 755 ~/models
```

**2. Ollama permission issues**:

```bash
# Ollama model directory
sudo chown -R $USER:$USER ~/.ollama/

# Fix service permissions
sudo systemctl stop ollama
sudo chown -R ollama:ollama /usr/share/ollama
sudo systemctl start ollama
```

**3. Docker volume permissions**:

```bash
# Run container with correct UID/GID
docker run -it --gpus all \
  -v ~/models:/models \
  -u $(id -u):$(id -g) \
  ollama/ollama
```

**4. Windows permission errors**:

```powershell
# Run PowerShell as Administrator
# Grant full control to user
icacls "C:\models" /grant:r "%USERNAME%:(OI)(CI)F" /T

# Or use file properties GUI:
# Right-click folder → Properties → Security → Edit → Add User → Full Control
```

**5. Python package installation permissions**:

```bash
# Use user installation (no sudo needed)
pip install --user llama-cpp-python

# Or use virtual environment
python -m venv venv
source venv/bin/activate
pip install llama-cpp-python
```

### Path Issues

Environment variable and path configuration problems prevent tools from finding executables, libraries, or models.

**Symptom**: "Command not found", "DLL load failed", "Module not found", or "File not found" errors despite files existing.

**Diagnosis**:

```bash
# Check Python path
python -c "import sys; print('\n'.join(sys.path))"

# Check environment variables
echo $PATH
echo $LD_LIBRARY_PATH
echo $CUDA_HOME

# Windows
echo %PATH%
echo %CUDA_PATH%
```

**Solutions**:

**1. Add CUDA to path** (Linux):

```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
export CUDA_HOME=/usr/local/cuda

# Apply changes
source ~/.bashrc
```

**2. Windows CUDA path**:

```powershell
# Add to system environment variables
$env:PATH += ";C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.3\bin"
$env:CUDA_PATH = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.3"

# Permanent (requires admin)
[Environment]::SetEnvironmentVariable("CUDA_PATH", "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.3", "Machine")
```

**3. Python module path issues**:

```python
# Add custom module paths
import sys
sys.path.insert(0, '/path/to/custom/modules')

# Or use PYTHONPATH environment variable
export PYTHONPATH=/path/to/modules:$PYTHONPATH
```

**4. Model path configuration**:

```python
# Use absolute paths
model_path = os.path.abspath("./models/llama-2-7b.gguf")

# Or environment variables
import os
model_dir = os.getenv("MODEL_DIR", "./models")
model_path = os.path.join(model_dir, "model.gguf")
```

**5. Ollama model path**:

```bash
# Set custom model directory
export OLLAMA_MODELS=/path/to/models

# Verify
ollama list
```

## Memory Issues

### Out of Memory (OOM)

GPU VRAM exhaustion is one of the most common issues when running local LLMs, especially with larger models.

**Symptom**: "CUDA out of memory", "RuntimeError: Out of memory", application crashes, or system freezing.

**Diagnosis**:

```bash
# Check VRAM usage
nvidia-smi

# Monitor in real-time
watch -n 1 nvidia-smi

# Python memory check
python -c "import torch; print(f'{torch.cuda.memory_allocated()/1e9:.2f}GB allocated')"
```

**Solutions**:

**1. Use quantized models** (most effective):

```bash
# Instead of full precision (13GB for 7B model)
# Use Q4_K_M quantization (~4GB for 7B model)
ollama pull llama3.2:3b-q4_K_M  # Much smaller

# Or download GGUF quantized models
# FP16: ~14GB for 7B
# Q8: ~7GB for 7B  
# Q5_K_M: ~5GB for 7B
# Q4_K_M: ~4GB for 7B
# Q3_K_M: ~3GB for 7B
```

**2. Reduce GPU layer offloading**:

```python
from llama_cpp import Llama

# Instead of loading all layers
# llm = Llama(model_path="model.gguf", n_gpu_layers=35)  # OOM

# Reduce layers
llm = Llama(
 model_path="model.gguf",
 n_gpu_layers=20,  # Load fewer layers to GPU
 n_ctx=2048  # Also reduce context if needed
)
```

**3. Reduce context window**:

```python
# Large context uses more VRAM
# n_ctx=8192  # ~3GB additional VRAM

# Smaller context
llm = Llama(
 model_path="model.gguf",
 n_gpu_layers=30,
 n_ctx=2048,  # Reduces VRAM usage significantly
 n_batch=512  # Also reduce batch size
)
```

**4. Use CPU offloading**:

```python
# Hybrid GPU/CPU execution
llm = Llama(
 model_path="model.gguf",
 n_gpu_layers=15,  # Partial GPU offload
 n_ctx=2048,
 n_threads=8  # Use CPU for remaining layers
)
```

**5. Clear GPU cache**:

```python
import torch
import gc

# Clear PyTorch cache
torch.cuda.empty_cache()
gc.collect()

# Or restart the application
```

**6. Use model sharding** (multi-GPU):

```python
from transformers import AutoModelForCausalLM

model = AutoModelForCausalLM.from_pretrained(
 "meta-llama/Llama-2-13b-hf",
 device_map="auto",  # Automatic multi-GPU distribution
 load_in_8bit=True,  # Additional quantization
 max_memory={0: "10GB", 1: "10GB"}  # Limit per GPU
)
```

**7. Increase virtual memory (temporary workaround)**:

```bash
# Linux - increase swap
sudo fallocate -l 32G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Verify
free -h
```

**8. Use gradient checkpointing** (for training/fine-tuning):

```python
model.gradient_checkpointing_enable()
# Trades compute for memory
```

### System RAM Issues

Insufficient system RAM can cause slowdowns, crashes, or prevent model loading entirely.

**Symptom**: System freezing, "MemoryError", extremely slow performance, or swap thrashing.

**Diagnosis**:

```bash
# Check RAM usage
free -h

# Monitor process memory
top -o %MEM
htop

# Python memory profiling
python -c "import psutil; print(f'RAM: {psutil.virtual_memory().percent}%')"
```

**Solutions**:

**1. Use smaller quantized models**:

```bash
# 7B Q4 model: ~4-6GB RAM
# 13B Q4 model: ~8-10GB RAM
# 70B Q4 model: ~40-48GB RAM

# Choose model based on available RAM
ollama pull llama3.2:1b  # ~1GB RAM
ollama pull llama3.2:3b  # ~3GB RAM
```

**2. Reduce model context**:

```python
# Smaller context = less RAM
llm = Llama(
 model_path="model.gguf",
 n_ctx=1024,  # Minimum viable context
 n_batch=256  # Smaller batch size
)
```

**3. Use mmap** (memory mapping, enabled by default):

```python
# mmap loads model directly from disk
# Much lower RAM usage but slightly slower
llm = Llama(
 model_path="model.gguf",
 use_mmap=True,  # Default
 use_mlock=False  # Don't lock in RAM
)
```

**4. Close unnecessary applications**:

```bash
# Linux - find memory hogs
ps aux --sort=-%mem | head

# Kill unnecessary processes
killall chrome firefox
```

**5. Increase swap space**:

```bash
# Check current swap
swapon --show

# Create larger swap file
sudo swapoff -a
sudo dd if=/dev/zero of=/swapfile bs=1G count=32
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

**6. Use streaming to reduce memory**:

```python
# Streaming generates tokens one at a time
# Lower memory footprint
for chunk in llm("Long prompt", stream=True):
 print(chunk['choices'][0]['text'], end='', flush=True)
```

### Memory Leaks

Memory leaks cause gradual memory consumption increase over time, eventually leading to OOM or crashes.

**Symptom**: Memory usage grows continuously, degraded performance over time, eventual crashes after extended operation.

**Diagnosis**:

```python
import psutil
import time
import gc

def monitor_memory(duration=300):
 """Monitor memory usage over time."""
 process = psutil.Process()
 baseline = process.memory_info().rss / 1e9
 
 for i in range(duration):
  current = process.memory_info().rss / 1e9
  increase = current - baseline
  print(f"T+{i}s: {current:.2f}GB (Δ{increase:+.2f}GB)")
  time.sleep(1)

# Run during inference
monitor_memory()
```

**Common causes and solutions**:

**1. Not clearing model outputs**:

```python
# ❌ Memory leak
responses = []
for prompt in prompts:
 response = llm(prompt, max_tokens=512)
 responses.append(response)  # Keeps growing

# ✅ Fixed - extract only needed data
responses = []
for prompt in prompts:
 response = llm(prompt, max_tokens=512)
 responses.append(response['choices'][0]['text'])  # Store only text
 del response  # Explicitly delete
```

**2. PyTorch tensor accumulation**:

```python
# ❌ Tensors not freed
import torch
for _ in range(100):
 tensor = torch.randn(1000, 1000, device='cuda')
 result = tensor @ tensor.T

# ✅ Fixed
import torch
for _ in range(100):
 tensor = torch.randn(1000, 1000, device='cuda')
 result = tensor @ tensor.T
 del tensor, result
 torch.cuda.empty_cache()
```

**3. Conversation history accumulation**:

```python
# ❌ Unbounded conversation history
class ChatBot:
 def __init__(self):
  self.history = []
 
 def chat(self, message):
  self.history.append(message)  # Grows forever
  prompt = '\n'.join(self.history)
  return llm(prompt)

# ✅ Fixed with rolling window
class ChatBot:
 def __init__(self, max_turns=20):
  self.history = []
  self.max_turns = max_turns
 
 def chat(self, message):
  self.history.append(message)
  # Keep only recent history
  if len(self.history) > self.max_turns:
   self.history = self.history[-self.max_turns:]
  prompt = '\n'.join(self.history)
  return llm(prompt)
```

**4. Model reloading without cleanup**:

```python
# ❌ Old model not freed
def switch_model(new_model_path):
 global llm
 llm = Llama(model_path=new_model_path)  # Old llm still in memory

# ✅ Fixed
def switch_model(new_model_path):
 global llm
 if 'llm' in globals():
  del llm
 gc.collect()
 torch.cuda.empty_cache() if torch.cuda.is_available() else None
 llm = Llama(model_path=new_model_path)
```

**5. Circular references**:

```python
# Use weak references for callbacks
import weakref

class ModelManager:
 def __init__(self):
  self.callbacks = []  # Strong references
 
 def add_callback(self, callback):
  self.callbacks.append(weakref.ref(callback))  # Weak reference

# Force garbage collection periodically
import gc
gc.collect()
```

**6. Memory profiling tools**:

```python
# Install memory_profiler
# pip install memory-profiler

from memory_profiler import profile

@profile
def generate_text():
 llm = Llama(model_path="model.gguf")
 response = llm("Test prompt")
 return response

# Run and check output for memory growth
generate_text()
```

### Swap Usage

Excessive swap usage indicates insufficient RAM and causes severe performance degradation.

**Symptom**: Extremely slow performance, high disk I/O, system unresponsiveness.

**Diagnosis**:

```bash
# Check swap usage
free -h
swapon --show

# Monitor swap usage
watch -n 1 free -h

# See what's using swap
for file in /proc/*/status ; do awk '/VmSwap|Name/{printf $2 " " $3}END{ print ""}' $file; done | sort -k 2 -n -r | head
```

**Solutions**:

**1. Reduce memory usage** (see RAM solutions above)

**2. Adjust swappiness**:

```bash
# Check current swappiness (0-100, default 60)
cat /proc/sys/vm/swappiness

# Reduce swappiness (makes system prefer RAM)
sudo sysctl vm.swappiness=10

# Make permanent
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
```

**3. Use zram** (compressed RAM swap):

```bash
# Install zram
sudo apt install zram-config

# Or manual setup
sudo modprobe zram
echo lz4 | sudo tee /sys/block/zram0/comp_algorithm
echo 4G | sudo tee /sys/block/zram0/disksize
sudo mkswap /dev/zram0
sudo swapon -p 100 /dev/zram0
```

**4. Increase physical RAM** (hardware solution)

**5. Use CPU-only inference** if RAM > VRAM:

```python
# Disable GPU, use CPU with adequate RAM
llm = Llama(
 model_path="model.gguf",
 n_gpu_layers=0,  # CPU only
 n_threads=8  # Multi-threaded CPU inference
)

## Performance Problems

### Slow Inference

Slow generation speeds can stem from multiple bottlenecks including inadequate hardware utilization, suboptimal configuration, or resource contention.

**Symptom**: Low tokens per second (t/s), extended response times, slower than expected generation.

**Diagnosis**:

```python
import time

def benchmark_inference(llm, prompt="Explain AI", num_runs=5):
    """Benchmark inference speed."""
    times = []
    for i in range(num_runs):
        start = time.time()
        response = llm(prompt, max_tokens=100)
        duration = time.time() - start
        tokens = len(response['choices'][0]['text'].split())
        tps = tokens / duration
        times.append(tps)
        print(f"Run {i+1}: {tps:.2f} t/s")
    
    print(f"\nAverage: {sum(times)/len(times):.2f} t/s")

# Usage
benchmark_inference(llm)
```

**Expected performance** (approximate):

- **7B Q4 model on RTX 4090**: 80-120 t/s
- **7B Q4 model on RTX 3090**: 60-90 t/s
- **13B Q4 model on RTX 4090**: 40-60 t/s
- **7B Q4 model on CPU (32 threads)**: 10-20 t/s

**Solutions**:

**1. Increase GPU layer offloading**:

```python
# ❌ Slow - using CPU
llm = Llama(model_path="model.gguf", n_gpu_layers=0)  # 5-10 t/s

# ✅ Fast - using GPU
llm = Llama(model_path="model.gguf", n_gpu_layers=35)  # 80+ t/s
```

**2. Optimize batch size**:

```python
# Test different batch sizes
for batch_size in [128, 256, 512, 1024]:
    llm = Llama(
        model_path="model.gguf",
        n_gpu_layers=35,
        n_batch=batch_size
    )
    # Benchmark and find optimal
```

**3. Enable Flash Attention**:

```python
# For Transformers models
model = AutoModelForCausalLM.from_pretrained(
    "model-name",
    torch_dtype=torch.float16,
    attn_implementation="flash_attention_2",  # Much faster
    device_map="auto"
)
```

**4. Use better quantization**:

```bash
# Q3 and Q2 are slower to decode than Q4/Q5
# Q4_K_M is optimal speed/quality balance
ollama pull llama3.2:7b-q4_K_M  # Recommended

# Avoid Q2 for performance-critical applications
```

**5. Reduce context window**:

```python
# Large context = slower inference
# n_ctx=8192  # Slower

# Smaller context
llm = Llama(model_path="model.gguf", n_ctx=2048, n_gpu_layers=35)  # Faster
```

**6. Optimize CPU threads** (for CPU inference):

```python
import os

# Set optimal thread count (usually physical cores)
n_threads = os.cpu_count() // 2  # Physical cores

llm = Llama(
    model_path="model.gguf",
    n_gpu_layers=0,
    n_threads=n_threads,
    n_batch=512
)
```

**7. Check for background processes**:

```bash
# Linux - check GPU usage
nvidia-smi

# Check CPU usage
htop

# Kill resource-intensive processes
killall chrome
```

**8. Update software**:

```bash
# Update llama-cpp-python for performance improvements
pip install --upgrade llama-cpp-python

# Update Ollama
curl -fsSL https://ollama.com/install.sh | sh
```

### High Latency

High latency causes delayed first token generation, affecting user experience in interactive applications.

**Symptom**: Long wait time before generation starts, time-to-first-token (TTFT) > 1 second.

**Causes and solutions**:

**1. Model not pre-loaded**:

```python
# ❌ Lazy loading causes first-request latency
class ModelManager:
    def __init__(self, model_path):
        self.model_path = model_path
        self.model = None
    
    def generate(self, prompt):
        if not self.model:
            self.model = Llama(self.model_path)  # Loads on first use
        return self.model(prompt)

# ✅ Pre-load model
class ModelManager:
    def __init__(self, model_path):
        self.model = Llama(model_path, n_gpu_layers=35)  # Load immediately
        # Warm up
        self.model("", max_tokens=1)
    
    def generate(self, prompt):
        return self.model(prompt)
```

**2. Large prompt processing**:

```python
# Long prompts take time to process
# Use prompt caching if available
llm = Llama(
    model_path="model.gguf",
    n_gpu_layers=35,
    n_ctx=4096
)

# For long static prefixes, consider pre-processing
system_prompt = "Very long system instructions..."
# Cache the KV cache for reuse (advanced)
```

**3. Network latency** (API calls):

```bash
# Use local server instead of remote
# Start local Ollama server
ollama serve

# Connect locally
curl http://localhost:11434/api/generate
```

**4. Enable streaming** for perceived performance:

```python
# User sees output immediately
for chunk in llm("Prompt", stream=True):
    print(chunk['choices'][0]['text'], end='', flush=True)
```

**5. Warm-up model**:

```python
# First inference is slower due to initialization
# Warm up after loading
llm = Llama(model_path="model.gguf", n_gpu_layers=35)
llm("", max_tokens=1)  # Warm-up inference
```

### Low GPU Utilization

GPU not being fully utilized indicates bottlenecks elsewhere or suboptimal configuration.

**Symptom**: nvidia-smi shows <50% GPU usage, poor performance despite having GPU.

**Diagnosis**:

```bash
# Monitor GPU utilization
nvidia-smi dmon -s u

# Detailed monitoring
nvidia-smi --query-gpu=utilization.gpu,utilization.memory --format=csv -l 1
```

**Solutions**:

**1. Increase GPU layer offloading**:

```python
# Check current offload
llm = Llama(model_path="model.gguf", n_gpu_layers=35, verbose=True)

# Model with 32 layers - offload all
llm = Llama(model_path="model.gguf", n_gpu_layers=32)  # All layers on GPU
```

**2. Increase batch size**:

```python
# Small batch = low GPU utilization
llm = Llama(model_path="model.gguf", n_gpu_layers=35, n_batch=128)  # Low util

# Larger batch = better GPU utilization
llm = Llama(model_path="model.gguf", n_gpu_layers=35, n_batch=1024)  # Better
```

**3. Process multiple requests in parallel**:

```python
import threading
import queue

class ParallelInference:
    def __init__(self, model_path, num_workers=4):
        # Multiple model instances
        self.models = [
            Llama(model_path, n_gpu_layers=35 // num_workers)
            for _ in range(num_workers)
        ]
        self.queue = queue.Queue()
    
    def worker(self, worker_id):
        while True:
            prompt, result_queue = self.queue.get()
            if prompt is None:
                break
            response = self.models[worker_id](prompt)
            result_queue.put(response)
    
    # Start workers...
```

**4. Check CPU bottlenecks**:

```bash
# Monitor CPU usage
htop

# If CPU is maxed out, it's bottlenecking GPU
# Reduce CPU-intensive preprocessing
```

**5. Use tensor cores** (NVIDIA):

```python
# Ensure using fp16/bf16 for tensor core utilization
model = AutoModelForCausalLM.from_pretrained(
    "model-name",
    torch_dtype=torch.float16,  # Enables tensor cores
    device_map="auto"
)
```

### CPU Bottlenecks

CPU limitations can prevent GPU from reaching full potential or cause slow CPU-only inference.

**Symptom**: High CPU usage, slow inference despite available GPU, system lag.

**Solutions**:

**1. Optimize thread count**:

```python
import os

# Don't use all threads
physical_cores = os.cpu_count() // 2
llm = Llama(
    model_path="model.gguf",
    n_threads=physical_cores,  # Not total threads
    n_gpu_layers=35
)
```

**2. Enable CPU optimizations**:

```bash
# Install with CPU optimizations
CMAKE_ARGS="-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS" pip install llama-cpp-python

# Or use AVX2/AVX512
CMAKE_ARGS="-DLLAMA_AVX2=ON" pip install llama-cpp-python
```

**3. Reduce prompt processing overhead**:

```python
# Pre-tokenize prompts if reusing
tokenizer = llama_tokenizer(model_path)
tokens = tokenizer.encode("Common prefix")

# Reuse tokens instead of re-encoding
```

**4. Use process affinity** (Linux):

```bash
# Pin process to specific cores
taskset -c 0-15 python inference.py

# Or in Python
import os
os.sched_setaffinity(0, {0, 1, 2, 3, 4, 5, 6, 7})
```

**5. Upgrade CPU** or use faster model:

```bash
# Use smaller, faster model if CPU-bound
ollama pull llama3.2:1b  # Much faster than 7b
```

## Model Loading Issues

### Model Not Found

File path errors prevent the inference engine from locating model files.

**Symptom**: "FileNotFoundError", "Model file not found", "No such file or directory".

**Solutions**:

**1. Verify file existence**:

```bash
# Check if file exists
ls -lh ~/models/llama-2-7b.gguf

# Find model files
find ~ -name "*.gguf" 2>/dev/null

# Ollama models location
ls ~/.ollama/models/blobs/
```

**2. Use absolute paths**:

```python
import os

# ❌ Relative paths can fail
llm = Llama(model_path="models/model.gguf")

# ✅ Use absolute paths
model_path = os.path.abspath("./models/model.gguf")
llm = Llama(model_path=model_path)

# Or use home directory
model_path = os.path.expanduser("~/models/model.gguf")
```

**3. Check Ollama model names**:

```bash
# List available models
ollama list

# Pull missing model
ollama pull llama3.2:3b

# Use exact name from list
ollama run llama3.2:3b  # Not "llama3.2" or "llama-3.2:3b"
```

**4. Fix path separators** (Windows):

```python
# ❌ Wrong separator on Windows
model_path = "C:/models\model.gguf"  # Mixed

# ✅ Use os.path or forward slashes
import os
model_path = os.path.join("C:", "models", "model.gguf")
# Or
model_path = "C:/models/model.gguf"  # Forward slashes work on Windows
```

**5. Check permissions**:

```bash
# Verify file is readable
ls -l ~/models/model.gguf

# Fix permissions
chmod 644 ~/models/model.gguf
```

### Corrupted Models

Damaged or incomplete model files cause loading failures or unpredictable behavior.

**Symptom**: "Invalid model file", "Unexpected EOF", checksum errors, loading crashes.

**Diagnosis**:

```bash
# Check file size (should match expected size)
ls -lh model.gguf

# Verify file integrity with checksum (if provided)
sha256sum model.gguf
# Compare with official checksum

# Check if file is actually a GGUF file
file model.gguf
# Should show: GGUF model file

# Try to read file header
head -c 1000 model.gguf | xxd
# Should start with GGUF magic bytes
```

**Solutions**:

**1. Re-download model**:

```bash
# Ollama - remove and re-pull
ollama rm llama3.2:3b
ollama pull llama3.2:3b

# Hugging Face - re-download
rm model.gguf
wget https://huggingface.co/TheBloke/Llama-2-7B-GGUF/resolve/main/llama-2-7b.Q4_K_M.gguf
```

**2. Verify download with checksums**:

```bash
# Download checksum file
wget https://huggingface.co/.../checksums.txt

# Verify
sha256sum -c checksums.txt
```

**3. Check disk space during download**:

```bash
# Ensure enough space
df -h

# Models can be 3-50GB+
# Ensure 2x space for safety
```

**4. Use resume-capable download tools**:

```bash
# wget with resume
wget -c <url>

# aria2 (faster, resume support)
aria2c -x 16 -s 16 <url>

# Hugging Face CLI
pip install huggingface-hub
huggingface-cli download TheBloke/Llama-2-7B-GGUF llama-2-7b.Q4_K_M.gguf
```

**5. Check for file system errors**:

```bash
# Linux - check file system
sudo fsck /dev/sda1

# Check SMART status
sudo smartctl -a /dev/sda
```

### Format Incompatibility

Using wrong model format for the inference engine causes loading failures.

**Symptom**: "Unsupported model format", "Invalid file type", format version errors.

**Model format compatibility**:

- **llama.cpp / Ollama**: GGUF format (`.gguf`)
- **Transformers**: PyTorch (`.bin`, `.safetensors`), older GGML
- **ONNX Runtime**: ONNX format (`.onnx`)
- **TensorRT-LLM**: TensorRT engines (`.engine`)

**Solutions**:

**1. Check model format**:

```bash
# Check file extension
ls -l model.*

# GGUF is current standard for llama.cpp
# GGML is older format (convert to GGUF)
```

**2. Convert between formats**:

```bash
# Convert GGML to GGUF
python convert-llama-ggml-to-gguf.py --input model.ggml --output model.gguf

# Convert PyTorch to GGUF
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
python convert.py /path/to/model --outfile model.gguf
```

**3. Use correct library for format**:

```python
# ❌ Wrong - GGUF with Transformers
from transformers import AutoModel
model = AutoModel.from_pretrained("model.gguf")  # Fails

# ✅ Correct - GGUF with llama-cpp
from llama_cpp import Llama
model = Llama(model_path="model.gguf")

# ✅ Correct - PyTorch with Transformers
from transformers import AutoModelForCausalLM
model = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-2-7b-hf")
```

**4. Download correct format**:

```bash
# For llama.cpp/Ollama, download GGUF
wget https://huggingface.co/TheBloke/Llama-2-7B-GGUF/resolve/main/llama-2-7b.Q4_K_M.gguf

# For Transformers, use model ID
# model = AutoModel.from_pretrained("meta-llama/Llama-2-7b-hf")
```

**5. Check GGUF version**:

```bash
# Check GGUF version in file
# Recent llama.cpp requires GGUF v3

# Update llama-cpp-python if needed
pip install --upgrade llama-cpp-python
```

### Version Mismatches

Incompatible versions between model files and inference software cause failures.

**Symptom**: "Version mismatch", "Unsupported version", deprecation warnings.

**Solutions**:

**1. Update inference engine**:

```bash
# Update llama-cpp-python
pip install --upgrade llama-cpp-python

# Update Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Update Transformers
pip install --upgrade transformers
```

**2. Check version compatibility**:

```python
import llama_cpp
import transformers

print(f"llama-cpp-python: {llama_cpp.__version__}")
print(f"transformers: {transformers.__version__}")
```

**3. Use specific versions**:

```bash
# If newer version breaks, pin to working version
pip install llama-cpp-python==0.2.27
pip install transformers==4.36.2
```

**4. Re-convert old models**:

```bash
# Old GGML models need conversion to GGUF
# Download conversion script from llama.cpp repo
python convert-llama-ggml-to-gguf.py --input old-model.ggml --output new-model.gguf
```

**5. Check model architecture compatibility**:

```python
# Some models require specific library versions
# Llama-3 requires transformers >= 4.38.0
pip install "transformers>=4.38.0"

# Mixtral requires specific version
pip install "transformers>=4.36.0"
```

## GPU Problems

### CUDA Errors

CUDA errors indicate problems with GPU computation, driver compatibility, or resource allocation.

**Common CUDA errors**:

**1. "CUDA out of memory"**:

See [Out of Memory (OOM)](#out-of-memory-oom) section above.

**2. "CUDA error: no kernel image available"**:

```bash
# Symptom: Compiled for wrong CUDA architecture
# Solution: Reinstall with correct CUDA version

# Check GPU compute capability
nvidia-smi --query-gpu=compute_cap --format=csv

# Reinstall PyTorch with correct CUDA
pip uninstall torch
pip install torch --index-url https://download.pytorch.org/whl/cu121
```

**3. "CUDA error: device-side assert triggered"**:

```python
# Enable better error messages
import os
os.environ['CUDA_LAUNCH_BLOCKING'] = '1'

# Run again to see actual error
# Common causes: invalid tensor indices, NaN values
```

**4. "CUDA initialization failed"**:

```bash
# Check CUDA installation
nvcc --version

# Check if GPU is accessible
python -c "import torch; print(torch.cuda.is_available())"

# Reinstall CUDA drivers
sudo apt remove --purge nvidia-*
sudo apt install nvidia-driver-545
sudo reboot
```

**5. "CUDA error: invalid device ordinal"**:

```python
# Trying to use GPU that doesn't exist
import torch
print(f"Available GPUs: {torch.cuda.device_count()}")

# Use valid device ID
device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
```

**6. "CUDA error: out of memory after cache clear"**:

```python
# Memory fragmentation issue
import torch
import gc

# Full reset
torch.cuda.empty_cache()
gc.collect()
torch.cuda.reset_peak_memory_stats()

# Restart Python process if persists
```

### GPU Not Detected

System fails to recognize GPU for acceleration.

**Symptom**: llama.cpp uses CPU only, PyTorch shows `cuda.is_available()=False`, nvidia-smi fails.

**Diagnosis**:

```bash
# Check if GPU is visible to system
lspci | grep -i nvidia

# Check driver installation
nvidia-smi

# Check CUDA availability
python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"

# Check llama.cpp GPU support
python -c "from llama_cpp import Llama; print(Llama.__version__)"
```

**Solutions**:

**1. Install/update NVIDIA drivers**:

```bash
# Ubuntu - install drivers
sudo ubuntu-drivers devices
sudo ubuntu-drivers autoinstall
sudo reboot

# Or manual installation
sudo apt install nvidia-driver-545
```

**2. Install CUDA toolkit**:

```bash
# Check CUDA version needed
nvidia-smi  # Shows max CUDA version

# Install CUDA 12.x
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
sudo apt install cuda
```

**3. Reinstall llama-cpp-python with CUDA support**:

```bash
# Check current installation
pip show llama-cpp-python

# Reinstall with CUDA
pip uninstall llama-cpp-python
CMAKE_ARGS="-DLLAMA_CUBLAS=on" pip install llama-cpp-python

# Verify CUDA support
python -c "from llama_cpp import Llama; llm = Llama(model_path='model.gguf', n_gpu_layers=1, verbose=True)"
```

**4. Install PyTorch with CUDA**:

```bash
# Reinstall PyTorch with correct CUDA version
pip uninstall torch torchvision torchaudio
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
```

**5. Check secure boot** (can block NVIDIA drivers):

```bash
# Check secure boot status
mokutil --sb-state

# If enabled, disable in BIOS or sign drivers
# Easiest: disable secure boot in BIOS
```

**6. Check GPU in BIOS**:

- Verify GPU is enabled in BIOS/UEFI
- Check PCIe settings
- Ensure adequate power supply

### Insufficient VRAM

GPU memory limitations prevent running desired models or configurations.

**Solutions covered in** [Out of Memory (OOM)](#out-of-memory-oom) **section above.**

Additional strategies:

**1. Model sharding across multiple GPUs**:

```python
# Automatically distribute across GPUs
from transformers import AutoModelForCausalLM

model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-13b-hf",
    device_map="auto",  # Auto-distribute
    load_in_8bit=True
)
```

**2. Offloading to CPU**:

```python
from transformers import AutoModelForCausalLM
import torch

model = AutoModelForCausalLM.from_pretrained(
    "model-name",
    device_map="auto",
    offload_folder="offload",  # Offload to disk
    offload_state_dict=True
)
```

**3. Use smaller models**:

```bash
# 8GB VRAM: 7B Q4/Q5 models
# 12GB VRAM: 7B FP16 or 13B Q4 models  
# 24GB VRAM: 13B FP16 or 30B Q4 models
# 48GB VRAM: 70B Q4 models

ollama pull llama3.2:3b  # ~2-3GB VRAM
```

### Multi-GPU Issues

Problems when using multiple GPUs simultaneously.

**Symptom**: Uneven GPU utilization, crashes, memory errors, slow performance.

**Solutions**:

**1. Check GPU visibility**:

```bash
# List all GPUs
nvidia-smi

# Check from Python
import torch
print(f"GPUs: {torch.cuda.device_count()}")
for i in range(torch.cuda.device_count()):
    print(f"GPU {i}: {torch.cuda.get_device_name(i)}")
```

**2. Explicit device mapping**:

```python
# Distribute model across specific GPUs
model = AutoModelForCausalLM.from_pretrained(
    "model-name",
    device_map={
        "model.embed_tokens": 0,
        "model.layers.0-15": 0,
        "model.layers.16-31": 1,
        "model.norm": 1,
        "lm_head": 1
    }
)
```

**3. Limit GPU usage**:

```python
# Use specific GPUs only
import os
os.environ["CUDA_VISIBLE_DEVICES"] = "0,2"  # Use GPU 0 and 2 only
```

**4. Balance GPU memory allocation**:

```python
# Set max memory per GPU
model = AutoModelForCausalLM.from_pretrained(
    "model-name",
    device_map="auto",
    max_memory={0: "10GB", 1: "10GB", 2: "10GB"}
)
```

**5. Enable peer-to-peer access**:

```bash
# Check P2P capability
nvidia-smi topo -m

# Enable in code
import torch
if torch.cuda.device_count() > 1:
    torch.cuda.set_device(0)
    # Will auto-enable P2P if available
```

## Quality Issues

### Poor Output Quality

Low-quality, incoherent, or incorrect model responses.

**Common causes and solutions**:

**1. Inappropriate temperature**:

```python
# Too high temperature = incoherent
response = llm(prompt, temperature=1.5)  # Too random

# Too low temperature = repetitive
response = llm(prompt, temperature=0.1)  # Too deterministic

# Balanced setting
response = llm(prompt, temperature=0.7)  # Recommended
```

**2. Wrong model for task**:

```bash
# Use task-specific models
# For code:
ollama pull codellama:13b

# For chat:
ollama pull llama3.2:3b-instruct

# For general tasks:
ollama pull mistral:7b
```

**3. Insufficient context**:

```python
# Provide clear instructions and context
prompt = """You are a helpful assistant. Answer accurately.

Question: Explain photosynthesis.
Answer:"""

response = llm(prompt, max_tokens=256)
```

**4. Over-quantization**:

```bash
# Q2/Q3 models lose significant quality
# Use Q4_K_M or Q5_K_M for better quality
ollama pull llama3.2:7b-q4_K_M  # Good balance
ollama pull llama3.2:7b-q5_K_M  # Better quality
```

**5. Incorrect prompt format**:

```python
# Many instruct models need specific format
# Llama-2 Chat format:
prompt = """[INST] <<SYS>>
You are a helpful assistant.
<</SYS>>

Explain quantum computing [/INST]"""

# Or use chat templates (Transformers)
tokenizer.apply_chat_template(messages, tokenize=False)
```

**6. Model too small for task**:

```bash
# Complex tasks need larger models
# Simple Q&A: 1B-3B models OK
# Complex reasoning: 7B-13B models
# Advanced tasks: 30B-70B models

ollama pull llama3.2:1b  # Simple tasks
ollama pull llama3.1:70b  # Complex tasks
```

### Repetitive Text

Model generates repeated phrases, sentences, or patterns.

**Symptom**: Output contains loops of repeated text, same words used excessively.

**Solutions**:

**1. Increase repetition penalty**:

```python
# Default is 1.0 (no penalty)
response = llm(
    prompt,
    temperature=0.7,
    repetition_penalty=1.15  # Penalize repetition
)

# For severe repetition
response = llm(
    prompt,
    temperature=0.8,
    repetition_penalty=1.3  # Stronger penalty
)
```

**2. Adjust sampling parameters**:

```python
# Use nucleus sampling
response = llm(
    prompt,
    temperature=0.7,
    top_p=0.9,  # Nucleus sampling
    top_k=40,  # Top-k sampling
    repetition_penalty=1.1
)
```

**3. Use frequency/presence penalties** (OpenAI-style):

```python
# If using llama.cpp server
response = client.chat.completions.create(
    model="model",
    messages=messages,
    frequency_penalty=0.5,  # Penalize frequent tokens
    presence_penalty=0.3  # Penalize any repeated tokens
)
```

**4. Reduce temperature**:

```python
# High temperature can cause repetition
response = llm(prompt, temperature=0.5)  # Lower, more focused
```

**5. Add stop sequences**:

```python
# Stop at repeated patterns
response = llm(
    prompt,
    max_tokens=256,
    stop=["\\n\\n", "User:", "###"]  # Stop tokens
)
```

**6. Try different model**:

```bash
# Some models are more prone to repetition
# Mistral and Llama-3 generally better than Llama-2
ollama pull mistral:7b
ollama pull llama3.2:3b
```

### Hallucinations

Model generates false, fabricated, or nonsensical information.

**Understanding**: LLMs don't "know" facts - they predict plausible text. Hallucinations are inevitable but can be reduced.

**Mitigation strategies**:

**1. Lower temperature for factual tasks**:

```python
# Lower temperature = more conservative
response = llm(
    "What is the capital of France?",
    temperature=0.2  # More deterministic for facts
)
```

**2. Provide context (RAG pattern)**:

```python
# Retrieval-Augmented Generation
relevant_docs = search_knowledge_base(query)

prompt = f"""Use the following context to answer the question.
Do not make up information.

Context: {relevant_docs}

Question: {query}
Answer:"""

response = llm(prompt, temperature=0.3)
```

**3. Instruction to cite sources**:

```python
prompt = """Answer the question based only on the provided context.
If you don't know, say "I don't know."
Cite specific parts of the context in your answer.

Context: {context}
Question: {question}
Answer:"""
```

**4. Use constrained generation**:

```python
# Force specific format
prompt = """Answer with Yes or No only.

Question: Is the sky blue?
Answer:"""

response = llm(prompt, max_tokens=5, temperature=0.1)
```

**5. Multiple generations and validation**:

```python
# Generate multiple answers and check consistency
answers = []
for _ in range(3):
    response = llm(prompt, temperature=0.4)
    answers.append(response['choices'][0]['text'])

# Use most common answer or validate consistency
```

**6. Use larger, more capable models**:

```bash
# Larger models tend to hallucinate less
ollama pull llama3.1:70b  # Better factual accuracy
```

**7. Post-processing validation**:

```python
def validate_response(response, query):
    """Check for common hallucination patterns."""
    # Check for hedging language
    hedges = ["I don't know", "I'm not sure", "It's unclear"]
    if any(hedge in response for hedge in hedges):
        return response  # Model appropriately uncertain
    
    # Validate facts with external API
    # Check dates, numbers, names
    return response
```

### Formatting Problems

Incorrect output structure, broken markdown, inconsistent formatting.

**Solutions**:

**1. Explicit format instructions**:

```python
prompt = """Generate a list of programming languages.
Format as numbered list:
1. [Language Name]

Languages:"""

response = llm(prompt, temperature=0.3)
```

**2. Use JSON mode** (if supported):

```python
prompt = """Generate a person's info in JSON format:
{
  "name": "string",
  "age": number,
  "city": "string"
}"""

response = llm(prompt, temperature=0.2)
import json
try:
    data = json.loads(response['choices'][0]['text'])
except json.JSONDecodeError:
    # Handle invalid JSON
    pass
```

**3. Provide examples (few-shot)**:

```python
prompt = """Format responses as:
Q: [Question]
A: [Answer]

Q: What is Python?
A: Python is a programming language.

Q: What is JavaScript?
A:"""
```

**4. Post-process output**:

```python
import re

def clean_markdown(text):
    """Clean up markdown formatting."""
    # Remove extra blank lines
    text = re.sub(r'\\n{3,}', '\\n\\n', text)
    # Fix list formatting
    text = re.sub(r'^([*-]) ', r'\\1 ', text, flags=re.MULTILINE)
    return text

response = llm(prompt)
cleaned = clean_markdown(response['choices'][0]['text'])
```

**5. Use structured output models**:

```bash
# Some models fine-tuned for structured output
# Use function-calling capable models
```

**6. Set appropriate stop tokens**:

```python
# Stop at format boundaries
response = llm(
    prompt,
    stop=["\\n\\n\\n", "---", "### End"]
)
```

## Network Issues

### Connection Failures

API requests fail to connect to local or remote LLM servers.

**Symptom**: "Connection refused", "Connection timeout", "Cannot connect to host".

**Solutions**:

**1. Check if server is running**:

```bash
# Check Ollama
systemctl status ollama
# or
ps aux | grep ollama

# Start if not running
systemctl start ollama
# or
ollama serve
```

**2. Verify correct host and port**:

```python
# Check Ollama default
import requests
try:
    response = requests.get("http://localhost:11434/api/tags")
    print("Connected!")
except requests.exceptions.ConnectionError:
    print("Cannot connect - check if Ollama is running")
```

**3. Check firewall rules**:

```bash
# Linux - allow port
sudo ufw allow 11434
sudo ufw status

# Or temporarily disable
sudo ufw disable
```

**4. Test with curl**:

```bash
# Test Ollama
curl http://localhost:11434/api/tags

# Test llama.cpp server
curl http://localhost:8080/health
```

**5. Bind to correct interface**:

```bash
# Allow external connections
OLLAMA_HOST=0.0.0.0:11434 ollama serve

# Or localhost only (more secure)
OLLAMA_HOST=127.0.0.1:11434 ollama serve
```

### Timeout Errors

Requests exceed time limits before completing.

**Symptom**: "Request timeout", "Read timeout", "Gateway timeout".

**Solutions**:

**1. Increase timeout**:

```python
import ollama
from ollama import Client

# Default timeout may be too short
client = Client(host='http://localhost:11434', timeout=120)  # 120 seconds

response = client.generate(
    model='llama3.2:3b',
    prompt='Long prompt...'
)
```

**2. Use streaming**:

```python
# Streaming avoids timeouts
import ollama

for chunk in ollama.generate(model='llama3.2:3b', prompt='Prompt', stream=True):
    print(chunk['response'], end='', flush=True)
```

**3. Reduce generation length**:

```python
# Long generations cause timeouts
response = llm(
    prompt,
    max_tokens=256  # Reduce if timing out
)
```

**4. Check server load**:

```bash
# High load causes timeouts
top
nvidia-smi

# Kill competing processes
```

**5. Optimize model for speed**:

```bash
# Use faster quantization
ollama pull llama3.2:3b-q4_0  # Faster than q5/q6

# Or smaller model
ollama pull llama3.2:1b
```

### Port Conflicts

Desired port is already in use by another application.

**Symptom**: "Address already in use", "Port is already allocated", "Bind failed".

**Solutions**:

**1. Check what's using the port**:

```bash
# Linux
sudo lsof -i :11434
sudo netstat -tulpn | grep 11434

# Find process ID
fuser 11434/tcp
```

**2. Kill process using port**:

```bash
# Get PID
sudo lsof -i :11434
# Kill process
sudo kill -9 <PID>

# Or
sudo fuser -k 11434/tcp
```

**3. Use different port**:

```bash
# Ollama - use custom port
OLLAMA_HOST=0.0.0.0:11435 ollama serve

# llama.cpp server
./server -m model.gguf --port 8081
```

**4. Change client to use new port**:

```python
import ollama
from ollama import Client

client = Client(host='http://localhost:11435')  # Custom port
response = client.generate(model='llama3.2:3b', prompt='Test')
```

### Firewall Blocking

Firewall rules prevent network access to LLM services.

**Solutions**:

**1. Allow port through firewall** (Linux):

```bash
# UFW
sudo ufw allow 11434/tcp
sudo ufw reload

# Firewalld
sudo firewall-cmd --permanent --add-port=11434/tcp
sudo firewall-cmd --reload

# iptables
sudo iptables -A INPUT -p tcp --dport 11434 -j ACCEPT
sudo iptables-save
```

**2. Windows firewall**:

```powershell
# PowerShell (as Administrator)
New-NetFirewallRule -DisplayName "Ollama" -Direction Inbound -LocalPort 11434 -Protocol TCP -Action Allow
```

**3. Test firewall rules**:

```bash
# From another machine
curl http://<server-ip>:11434/api/tags

# Or use telnet
telnet <server-ip> 11434
```

**4. Use SSH tunnel** (if firewall can't be modified):

```bash
# Forward remote port to local
ssh -L 11434:localhost:11434 user@remote-server

# Now access via localhost
curl http://localhost:11434/api/tags
```

## Platform-Specific Issues

### Windows Problems

Common issues specific to Windows systems.

**1. Long path issues**:

```powershell
# Enable long paths (as Administrator)
New-ItemProperty -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force

# Or use subst for shorter paths
subst M: C:\\Users\\Username\\models
```

**2. Antivirus false positives**:

```powershell
# Add exclusions in Windows Defender
Add-MpPreference -ExclusionPath "C:\\path\\to\\ollama"
Add-MpPreference -ExclusionPath "C:\\Users\\Username\\.ollama"
```

**3. DLL not found errors**:

```powershell
# Install Visual C++ Redistributables
# Download from: https://aka.ms/vs/17/release/vc_redist.x64.exe

# Add CUDA to PATH
$env:PATH += ";C:\\Program Files\\NVIDIA GPU Computing Toolkit\\CUDA\\v12.3\\bin"
```

**4. PowerShell execution policy**:

```powershell
# Allow script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**5. Python from Microsoft Store issues**:

```powershell
# Uninstall Microsoft Store Python
# Install from python.org instead
# Ensures proper pip and package installation
```

### Linux Issues

Linux-specific troubleshooting.

**1. GLIBC version errors**:

```bash
# Check GLIBC version
ldd --version

# Upgrade system
sudo apt update && sudo apt upgrade

# Or use older binary/compile from source
```

**2. Permissions on /dev/nvidia***:

```bash
# Add user to video group
sudo usermod -a -G video $USER

# Or render group
sudo usermod -a -G render $USER

# Re-login for changes
```

**3. Systemd service issues**:

```bash
# Check Ollama service
systemctl status ollama

# View logs
sudo journalctl -u ollama -f

# Restart service
sudo systemctl restart ollama
```

**4. AppArmor/SELinux blocking**:

```bash
# Check AppArmor
sudo aa-status

# Disable for Ollama (if needed)
sudo aa-complain /usr/bin/ollama

# SELinux
sudo setenforce 0  # Temporary
```

**5. Missing libraries**:

```bash
# Check missing dependencies
ldd $(which ollama)

# Install missing libraries
sudo apt install libgomp1 libopenblas0
```

### macOS Problems

Mac-specific issues and solutions.

**1. Rosetta 2 on Apple Silicon**:

```bash
# Install Rosetta for x86_64 apps
softwareupdate --install-rosetta

# Use native ARM binaries when available
# Ollama has native Apple Silicon support
```

**2. Gatekeeper blocking**:

```bash
# Allow unsigned application
sudo xattr -r -d com.apple.quarantine /path/to/app

# Or in System Preferences:
# Security & Privacy → Allow apps from: App Store and identified developers
```

**3. Metal performance**:

```bash
# Install llama-cpp-python with Metal support
CMAKE_ARGS="-DLLAMA_METAL=on" pip install llama-cpp-python

# Verify Metal is being used
# Check for "Metal" in verbose output
```

**4. Python SSL certificates**:

```bash
# Fix SSL certificate verification
/Applications/Python\\ 3.11/Install\\ Certificates.command

# Or install certifi
pip install --upgrade certifi
```

**5. Memory pressure on M-series Macs**:

```bash
# Unified memory is shared between CPU/GPU
# Close unnecessary apps
# Use Activity Monitor to check memory pressure

# Reduce model size if needed
ollama pull llama3.2:3b  # Instead of 7b
```

### WSL Issues

Windows Subsystem for Linux specific problems.

**1. GPU not accessible**:

```powershell
# Requires WSL 2 with GPU support
# Update to latest Windows (21H2+)
wsl --update

# Check WSL version
wsl -l -v

# Upgrade to WSL 2 if needed
wsl --set-default-version 2
wsl --set-version Ubuntu 2
```

**2. CUDA in WSL**:

```bash
# Install CUDA toolkit in WSL
wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin
sudo mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/12.3.0/local_installers/cuda-repo-wsl-ubuntu-12-3-local_12.3.0-1_amd64.deb
sudo dpkg -i cuda-repo-wsl-ubuntu-12-3-local_12.3.0-1_amd64.deb
sudo cp /var/cuda-repo-wsl-ubuntu-12-3-local/cuda-*-keyring.gpg /usr/share/keyrings/
sudo apt-get update
sudo apt-get install cuda
```

**3. File system performance**:

```bash
# Store models on Linux filesystem, not /mnt/c/
# Much faster performance
mkdir ~/models
cp /mnt/c/Users/Username/models/*.gguf ~/models/
```

**4. Memory limits**:

```powershell
# Create/edit .wslconfig in Windows user directory
# C:\\Users\\Username\\.wslconfig
[wsl2]
memory=16GB
processors=8
swap=8GB

# Restart WSL
wsl --shutdown
```

**5. Network issues**:

```bash
# WSL uses NAT by default
# Access WSL services from Windows:
# Use localhost or WSL IP

# Get WSL IP
ip addr show eth0

# Or use localhost (bridged by default)
curl http://localhost:11434/api/tags
```

## Common Error Messages

### Error Code Reference

**"CUDA error: out of memory"**:

- See [Out of Memory (OOM)](#out-of-memory-oom) section
- Reduce model size, context window, or GPU layers

**"FileNotFoundError: No such file or directory"**:

- Check file path is correct and absolute
- Verify file exists: `ls -l /path/to/model.gguf`

**"ModuleNotFoundError: No module named 'torch'"**:

- Install PyTorch: `pip install torch`
- Check virtual environment is activated

**"ImportError: libcudart.so: cannot open shared object file"**:

- Add CUDA to library path
- `export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH`

**"ConnectionRefusedError: [Errno 111] Connection refused"**:

- Server not running - start Ollama: `ollama serve`
- Check firewall isn't blocking port

**"RuntimeError: CUDA initialization: CUDA-capable device(s) is/are busy or unavailable"**:

- Another process using GPU
- Restart machine or kill competing process

**"ValueError: Tokenizer class GPT2TokenizerFast does not exist or is not currently imported"**:

- Update transformers: `pip install --upgrade transformers`

**"OSError: [Errno 28] No space left on device"**:

- Check disk space: `df -h`
- Clean up old models or cached files

### Warning Messages

**"Model was trained with transformers version X but you have version Y"**:

- Usually safe to ignore
- Update if seeing issues: `pip install --upgrade transformers`

**"The model weights are not tied. Please use the `tie_weights` method"**:

- Informational, generally safe to ignore
- Model-specific optimization message

**"Some weights of the model checkpoint were not used"**:

- Expected when fine-tuning or using adapters
- Only concerning if unexpected weights mentioned

**"Special tokens have been added in the vocabulary"**:

- Normal informational message
- Tokenizer adding padding/special tokens

## Diagnostic Tools

### Log Analysis

**Ollama logs**:

```bash
# View Ollama service logs
sudo journalctl -u ollama -f

# Last 100 lines
sudo journalctl -u ollama -n 100

# Logs from today
sudo journalctl -u ollama --since today
```

**Application logs**:

```python
import logging

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('llm_debug.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)
logger.debug("Loading model...")
```

### System Monitoring

**GPU monitoring**:

```bash
# Real-time monitoring
nvidia-smi dmon -s pucvmet

# Specific metrics
nvidia-smi --query-gpu=timestamp,name,temperature.gpu,utilization.gpu,memory.used --format=csv -l 1

# Python monitoring
import GPUtil
GPUs = GPUtil.getGPUs()
for gpu in GPUs:
    print(f"GPU: {gpu.name}, Load: {gpu.load*100}%, Mem: {gpu.memoryUsed}MB/{gpu.memoryTotal}MB")
```

**CPU/RAM monitoring**:

```bash
# htop (interactive)
htop

# System resources
vmstat 1  # Update every second

# Memory details
free -h && cat /proc/meminfo
```

### Network Diagnostics

```bash
# Test local connectivity
curl -v http://localhost:11434/api/tags

# Test with timeout
curl --max-time 5 http://localhost:11434/api/tags

# Check port listening
netstat -tulpn | grep 11434
ss -tulpn | grep 11434

# Test from Python
import socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
result = sock.connect_ex(('localhost', 11434))
print("Open" if result == 0 else "Closed")
sock.close()
```

## Prevention Strategies

### Best Practices

**1. Use virtual environments**:

```bash
# Isolate dependencies
python -m venv llm_env
source llm_env/bin/activate
pip install -r requirements.txt
```

**2. Pin dependency versions**:

```bash
# Create requirements.txt with exact versions
pip freeze > requirements.txt

# Install exact versions
pip install -r requirements.txt
```

**3. Monitor resources**:

```python
import psutil

def check_resources():
    cpu = psutil.cpu_percent()
    ram = psutil.virtual_memory().percent
    if cpu > 90:
        print("Warning: High CPU usage")
    if ram > 90:
        print("Warning: High RAM usage")
```

**4. Regular updates**:

```bash
# Update inference engines monthly
pip install --upgrade llama-cpp-python transformers

# Update Ollama
curl -fsSL https://ollama.com/install.sh | sh
```

**5. Test before production**:

```python
# Test inference before deploying
def health_check(llm):
    try:
        response = llm("Test", max_tokens=10)
        return True
    except Exception as e:
        print(f"Health check failed: {e}")
        return False
```

### Regular Maintenance

**Weekly tasks**:

- Check disk space
- Review application logs
- Monitor performance metrics
- Test backup procedures

**Monthly tasks**:

- Update dependencies
- Clean temporary files
- Review security patches
- Optimize model selection

**Quarterly tasks**:

- Evaluate new models
- Review architecture
- Benchmark performance
- Update documentation

## Community Resources

### Forums and Support

- **Ollama Discord**: <https://discord.gg/ollama>
- **llama.cpp GitHub Discussions**: <https://github.com/ggerganov/llama.cpp/discussions>
- **Hugging Face Forums**: <https://discuss.huggingface.co/>
- **r/LocalLLaMA**: <https://reddit.com/r/LocalLLaMA>

### Issue Trackers

- **Ollama Issues**: <https://github.com/ollama/ollama/issues>
- **llama.cpp Issues**: <https://github.com/ggerganov/llama.cpp/issues>
- **Transformers Issues**: <https://github.com/huggingface/transformers/issues>

### Documentation

- **Ollama Docs**: <https://github.com/ollama/ollama/tree/main/docs>
- **llama.cpp README**: <https://github.com/ggerganov/llama.cpp/blob/master/README.md>
- **Transformers Docs**: <https://huggingface.co/docs/transformers/>
- **CUDA Toolkit Docs**: <https://docs.nvidia.com/cuda/>

## Summary

Troubleshooting local LLMs requires systematic diagnosis and targeted solutions. Key approaches:

**Memory issues**: Use quantization, reduce context, manage GPU layers
**Performance problems**: Optimize batch size, enable GPU acceleration, use appropriate models
**Installation issues**: Manage dependencies, update drivers, handle permissions
**Quality issues**: Adjust temperature, use RAG, select appropriate models
**Platform-specific**: Follow OS-specific configurations and workarounds

When troubleshooting:

1. **Diagnose first**: Use logs, monitoring tools, and error messages
2. **Start simple**: Check obvious causes (server running, file exists, permissions)
3. **Isolate variables**: Test components individually
4. **Document solutions**: Keep notes for future reference
5. **Seek help**: Use community resources when stuck

Most issues have been encountered and solved by the community. Search error messages, check GitHub issues, and ask in forums for assistance.
