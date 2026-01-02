---
title: "Installation and Setup of Local LLMs"
description: "Step-by-step guide to installing and configuring local LLM environments"
author: "Joseph Streeter"
ms.date: "2025-12-31"
ms.topic: "guide"
keywords: ["installation", "setup", "configuration", "deployment", "local llm setup"]
uid: docs.ai.local-llms.installation
---

## Overview

Setting up local Large Language Models (LLMs) has become increasingly accessible, offering privacy, cost control, and customization benefits over cloud-based solutions. This comprehensive guide provides step-by-step instructions for installing and configuring popular local LLM frameworks across different operating systems and hardware configurations.

Local LLM deployment involves several key components: runtime environments, model formats, inference engines, and user interfaces. The complexity ranges from simple one-click installations to advanced custom builds optimized for specific hardware configurations.

This guide covers the most popular and reliable frameworks:

- **Ollama**: The simplest entry point for local LLMs
- **llama.cpp**: High-performance C++ implementation
- **Text Generation WebUI**: Feature-rich web interface
- **LM Studio**: Professional GUI application
- **GPT4All**: User-friendly desktop application

Each framework has distinct advantages depending on your use case, technical expertise, and hardware setup. We'll explore installation procedures for Windows, macOS, and Linux, with special attention to GPU configuration and performance optimization.

## Prerequisites

Before installing any local LLM framework, ensure your system meets the minimum requirements and has the necessary drivers and dependencies installed.

### System Requirements

**Minimum Hardware Requirements:**

- CPU: 4+ cores, 2.0+ GHz (Intel i5-8400 / AMD Ryzen 5 3600 equivalent)
- RAM: 16 GB system memory
- Storage: 50 GB available space (models require additional space)
- GPU: Optional but recommended (8+ GB VRAM for good performance)

**Recommended Hardware for Optimal Experience:**

- CPU: 8+ cores, 3.0+ GHz (Intel i7-12700K / AMD Ryzen 7 7700X)
- RAM: 32+ GB system memory
- Storage: 500+ GB NVMe SSD
- GPU: NVIDIA RTX 4070 (12 GB VRAM) or AMD RX 7800 XT (16 GB VRAM)

**Operating System Support:**

- Windows 10/11 (x64)
- macOS 10.15+ (Intel) / macOS 11+ (Apple Silicon)
- Linux distributions: Ubuntu 20.04+, Debian 11+, CentOS 8+, Arch Linux

**Network Requirements:**

- Stable internet connection for initial downloads
- 10-50 GB bandwidth for model downloads
- Optional: Local network access for multi-device usage

### Driver Installation

Proper GPU drivers are crucial for optimal performance. Install the latest drivers before proceeding with framework installation.

**NVIDIA GPU Setup:**

1. **Download and Install CUDA Toolkit:**

```bash
# Linux (Ubuntu/Debian)
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb
sudo dpkg -i cuda-keyring_1.0-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda

# Verify installation
nvcc --version
nvidia-smi
```

1. **Windows CUDA Installation:**

- Download CUDA Toolkit from NVIDIA Developer website
- Run installer with default settings
- Add CUDA to PATH: `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.3\bin`
- Verify with `nvcc --version` in Command Prompt

1. **Required CUDA Versions:**

```text
Framework        | Minimum CUDA | Recommended CUDA
llama.cpp       | 11.8         | 12.1+
Text Gen WebUI  | 11.8         | 12.1+
Ollama          | 11.2         | 12.1+
```

**AMD GPU Setup (Linux):**

```bash
# Install ROCm for AMD GPUs
curl -fsSL https://repo.radeon.com/rocm/rocm.gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/rocm.gpg
echo "deb [arch=amd64] https://repo.radeon.com/rocm/apt/5.7/ ubuntu main" | sudo tee /etc/apt/sources.list.d/rocm.list
sudo apt update
sudo apt install rocm-dev rocm-libs rccl

# Add user to render group
sudo usermod -a -G render $USER
sudo usermod -a -G video $USER

# Reboot system
sudo reboot
```

**Apple Silicon Setup:**

- No additional drivers required
- Metal Performance Shaders included in macOS
- Ensure macOS 12+ for optimal ML performance

### Software Dependencies

**Python Environment (Required for most frameworks):**

```bash
# Install Python 3.10+ (recommended version)
# Ubuntu/Debian
sudo apt update
sudo apt install python3.11 python3.11-venv python3.11-dev

# macOS (using Homebrew)
brew install python@3.11

# Windows (download from python.org or use winget)
winget install Python.Python.3.11
```

**Essential System Libraries:**

```bash
# Linux dependencies
sudo apt install build-essential cmake git wget curl unzip

# macOS (using Homebrew)
brew install cmake git wget

# Windows (using winget/chocolatey)
winget install Git.Git
winget install CMake.CMake
```

**Python Package Manager Setup:**

```bash
# Upgrade pip and install essential packages
python -m pip install --upgrade pip
pip install wheel setuptools virtualenv

# For development environments
pip install jupyterlab ipython requests numpy
```

## Installation Methods

There are several approaches to installing local LLM frameworks, each with distinct advantages depending on your technical requirements and system configuration.

### Docker-Based Setup

Container-based deployment offers consistency across environments and simplified dependency management.

**Advantages:**

- Isolated environment prevents conflicts
- Consistent behavior across different systems
- Easy backup and restoration
- Simplified GPU passthrough configuration
- Quick setup and teardown

**Docker Installation Prerequisites:**

```bash
# Install Docker (Ubuntu/Debian)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

**Docker Compose Example for Text Generation WebUI:**

```yaml
version: '3.8'
services:
  text-generation-webui:
    image: ghcr.io/oobabooga/text-generation-webui:latest
    container_name: textgen-webui
    environment:
      - CLI_ARGS=--listen --verbose
    ports:
      - "7860:7860"
    volumes:
      - ./models:/app/models
      - ./characters:/app/characters
      - ./presets:/app/presets
      - ./training:/app/training
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    restart: unless-stopped
```

### Native Installation

Direct system installation provides maximum performance and customization options.

**Advantages:**

- Maximum performance (no containerization overhead)
- Direct access to system resources
- Easier debugging and customization
- Better integration with system tools
- Lower memory usage

**Disadvantages:**

- Potential dependency conflicts
- System-specific configuration required
- More complex troubleshooting
- Difficult cleanup if issues arise

**Best Practices for Native Installation:**

1. **Use dedicated user account** for LLM services
2. **Document installation steps** for reproducibility
3. **Create system restore points** before major changes
4. **Monitor system resources** during installation
5. **Test with small models** before deploying large ones

### Virtual Environments

Python virtual environments provide isolation while maintaining native performance.

**Python venv Setup:**

```bash
# Create virtual environment
python3 -m venv ~/llm-env

# Activate environment
source ~/llm-env/bin/activate  # Linux/macOS
# or
~/llm-env/Scripts/activate.bat  # Windows

# Upgrade pip and install basic dependencies
pip install --upgrade pip wheel setuptools

# Install common ML libraries
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install transformers accelerate bitsandbytes
```

**Conda Environment Setup:**

```bash
# Install Miniconda (recommended over Anaconda for LLM work)
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

# Create environment with Python 3.11
conda create -n llm-env python=3.11
conda activate llm-env

# Install PyTorch with CUDA support
conda install pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia

# Install additional packages
conda install transformers accelerate -c huggingface
pip install bitsandbytes optimum
```

**Environment Management:**

```bash
# Save environment requirements
pip freeze > requirements.txt

# Recreate environment
pip install -r requirements.txt

# Conda environment export/import
conda env export > environment.yml
conda env create -f environment.yml
```

## Popular Frameworks

Each framework serves different use cases and skill levels. Here's a comprehensive comparison to help you choose the right tool.

### Ollama

The simplest and most user-friendly way to run local LLMs.

**Key Features:**

- One-command model downloads and execution
- Automatic GPU detection and utilization
- Built-in model quantization
- REST API for integration
- Cross-platform compatibility
- Automatic memory management

**Best For:**

- Beginners new to local LLMs
- Quick experimentation and testing
- Integration with existing applications
- Users who want minimal configuration

**Performance Characteristics:**

```text
Model Size | RAM Usage | VRAM Usage | Typical Speed
7B (Q4)    | 4 GB      | 5 GB       | 25-45 tokens/s
13B (Q4)   | 8 GB      | 9 GB       | 15-30 tokens/s
34B (Q4)   | 20 GB     | 21 GB      | 8-15 tokens/s
```

**Installation Preview:**

```bash
# Single command installation
curl -fsSL https://ollama.ai/install.sh | sh

# Start using immediately
ollama pull llama2:7b
ollama run llama2:7b
```

### llama.cpp

High-performance C++ implementation optimized for inference speed.

**Key Features:**

- Maximum inference performance
- Minimal memory usage
- Support for quantized models (GGUF format)
- CPU-only and GPU-accelerated modes
- Custom sampling parameters
- Streaming output support

**Best For:**

- Performance-critical applications
- Resource-constrained environments
- Custom integration projects
- Users comfortable with command-line tools

**Performance Advantages:**

- 20-40% faster inference than Python implementations
- Lower memory overhead
- Better CPU utilization
- Optimized for various architectures (AVX2, AVX-512)

**Supported Quantization Formats:**

```text
Format    | Quality | Size Reduction | Speed
Q8_0      | Highest | 2x            | Fast
Q6_K      | High    | 2.7x          | Fast
Q5_K_M    | Good    | 3.2x          | Very Fast
Q4_K_M    | Good    | 4x            | Very Fast
Q3_K_M    | Fair    | 5.3x          | Fastest
```

### Text Generation WebUI

Feature-rich web interface with extensive customization options.

**Key Features:**

- Intuitive web-based interface
- Multiple model backends (transformers, llama.cpp, ExLlama)
- Character/persona management
- Chat history and session management
- Extension system for additional functionality
- Fine-tuning capabilities
- Multi-user support

**Best For:**

- Interactive chat and roleplay
- Content creation and writing
- Model experimentation and comparison
- Users who prefer GUI interfaces

**Extension Ecosystem:**

- **Superbooga**: RAG (Retrieval-Augmented Generation)
- **Silero TTS**: Text-to-speech integration
- **Whisper STT**: Speech-to-text input
- **OpenAI**: API compatibility layer
- **LLaVA**: Multimodal image understanding

### LocalAI

OpenAI-compatible API server for local models.

**Key Features:**

- Drop-in replacement for OpenAI API
- Support for multiple model types (text, image, audio)
- Docker-first architecture
- Horizontal scaling support
- Authentication and rate limiting
- Prometheus metrics integration

**Best For:**

- Existing OpenAI API integrations
- Production deployments
- Multi-model serving
- Enterprise environments requiring API compatibility

**API Compatibility:**

```python
# Standard OpenAI client works unchanged
import openai

# Point to LocalAI instead of OpenAI
openai.api_base = "http://localhost:8080/v1"
openai.api_key = "your-api-key"

# Same API calls work
response = openai.ChatCompletion.create(
    model="llama2-7b-chat",
    messages=[{"role": "user", "content": "Hello!"}]
)
```

### LM Studio

Professional desktop application with enterprise features.

**Key Features:**

- Native desktop application (Windows, macOS, Linux)
- Built-in model browser and downloader
- Hardware optimization wizard
- Conversation management
- Model performance benchmarking
- Local server mode with API

**Best For:**

- Professional AI development
- Model evaluation and testing
- Non-technical users wanting powerful features
- Commercial applications

**Unique Advantages:**

- Automatic hardware detection and optimization
- Visual model performance comparisons
- Built-in safety and content filtering
- Professional support options
- Regular updates and new model support

### GPT4All

User-friendly desktop application focused on privacy and ease of use.

**Key Features:**

- Simple desktop interface
- Privacy-focused (no data collection)
- Curated model selection
- Offline operation
- Cross-platform availability
- Plugin ecosystem

**Best For:**

- Privacy-conscious users
- Casual LLM usage
- Users wanting zero configuration
- Educational purposes

**Supported Models:**

- Llama-2 variants (7B, 13B)
- Code Llama models
- Mistral 7B
- Nous Hermes
- Wizard Vicuna
- MPT models

## Installing Ollama

Ollama provides the simplest path to running local LLMs with minimal configuration required.

### Windows Installation

Multiple installation methods available for Windows users.

**Method 1:** Official Installer (Recommended)

1. **Download the installer:**
   - Visit [ollama.ai](https://ollama.ai/download)
   - Download the Windows installer (.exe)
   - Run installer with administrator privileges

2. **Verify installation:**

```cmd
# Open Command Prompt or PowerShell
ollama --version

# Should display version information
# ollama version 0.1.17
```

1. **Configure Windows Firewall:**

```cmd
# Allow Ollama through Windows Firewall
netsh advfirewall firewall add rule name="Ollama" dir=in action=allow program="%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
```

**Method 2:** PowerShell Installation

```powershell
# Download and install via PowerShell
iwr -useb https://ollama.ai/install.ps1 | iex

# Alternative: Using winget
winget install ollama
```

**Windows-Specific Configuration:**

```cmd
# Set environment variables
setx OLLAMA_HOST "0.0.0.0:11434"
setx OLLAMA_ORIGINS "*"
setx OLLAMA_NUM_PARALLEL "2"

# Restart terminal for changes to take effect
```

### macOS Installation

Streamlined installation process for macOS users.

**Method 1:** Official App (Recommended)

1. **Download Ollama.app:**
   - Visit [ollama.ai/download](https://ollama.ai/download)
   - Download the macOS app
   - Drag to Applications folder
   - Launch from Applications or Spotlight

2. **First launch setup:**
   - Grant necessary permissions when prompted
   - Allow network connections
   - Ollama will install command-line tools automatically

**Method 2:** Homebrew Installation

```bash
# Install via Homebrew
brew install ollama

# Start Ollama service
brew services start ollama

# Verify installation
ollama --version
```

**Method 3:** Manual Installation

```bash
# Download and install manually
curl -fsSL https://ollama.ai/install.sh | sh

# Add to PATH (add to ~/.zshrc or ~/.bash_profile)
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**macOS-Specific Configuration:**

```bash
# Configure environment variables
echo 'export OLLAMA_HOST="0.0.0.0:11434"' >> ~/.zshrc
echo 'export OLLAMA_ORIGINS="*"' >> ~/.zshrc
echo 'export OLLAMA_NUM_PARALLEL="2"' >> ~/.zshrc
source ~/.zshrc
```

### Linux Installation

Comprehensive Linux setup for various distributions.

**Universal Installation Script (Recommended):**

```bash
# Download and install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Verify installation
ollama --version

# Check service status
sudo systemctl status ollama
```

**Manual Installation for Advanced Users:**

```bash
# Create ollama user
sudo useradd -r -s /bin/false -m -d /usr/share/ollama ollama

# Download binary
sudo curl -L https://ollama.ai/download/ollama-linux-amd64 -o /usr/bin/ollama
sudo chmod +x /usr/bin/ollama

# Create systemd service
sudo tee /etc/systemd/system/ollama.service > /dev/null <<EOF
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="OLLAMA_HOST=0.0.0.0:11434"

[Install]
WantedBy=default.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl start ollama
```

**Distribution-Specific Installation:**

```bash
# Ubuntu/Debian
wget -qO - https://ollama.ai/install.sh | bash

# Fedora/CentOS/RHEL
curl -fsSL https://ollama.ai/install.sh | sh

# Arch Linux
yay -S ollama
# or
paru -S ollama

# openSUSE
sudo zypper install ollama
```

**GPU Support Configuration:**

```bash
# For NVIDIA GPUs
sudo nvidia-smi  # Verify GPU detection

# For AMD GPUs (ROCm)
rocm-smi  # Verify GPU detection
export HSA_OVERRIDE_GFX_VERSION=11.0.0  # For RX 7000 series

# Check GPU utilization during inference
watch -n 1 nvidia-smi  # NVIDIA
# or
watch -n 1 rocm-smi    # AMD
```

### First Model Pull

Download and run your first model with Ollama.

**Recommended Starting Models:**

```bash
# Beginner-friendly 7B models
ollama pull llama2:7b          # Meta's Llama 2 7B
ollama pull mistral:7b         # Mistral 7B
ollama pull codellama:7b       # Code Llama 7B for programming

# More capable 13B models (requires more VRAM/RAM)
ollama pull llama2:13b         # Meta's Llama 2 13B
ollama pull vicuna:13b         # Vicuna 13B (uncensored)
ollama pull wizardcoder:13b    # WizardCoder 13B

# Specialized models
ollama pull neural-chat:7b     # Intel's Neural Chat
ollama pull starling-lm:7b     # Berkeley's Starling
ollama pull dolphin-mistral:7b # Uncensored Mistral variant
```

**Model Download and Usage:**

```bash
# Download a model (this may take 10-30 minutes depending on connection)
ollama pull llama2:7b

# Run interactive chat
ollama run llama2:7b

# Example conversation
>>> Hello! Can you help me write a Python function?
I'd be happy to help you write a Python function! What specific functionality are you looking for?

>>> /bye  # Exit chat

# Run single query
echo "Write a haiku about programming" | ollama run llama2:7b
```

**Model Management:**

```bash
# List installed models
ollama list

# Remove a model to free space
ollama rm llama2:7b

# Show model information
ollama show llama2:7b

# Copy/rename model
ollama cp llama2:7b my-custom-llama
```

**API Usage Examples:**

```bash
# Start Ollama server (usually runs automatically)
ollama serve

# Test API with curl
curl http://localhost:11434/api/generate -d '{
  "model": "llama2:7b",
  "prompt": "Why is the sky blue?",
  "stream": false
}'

# Chat API example
curl http://localhost:11434/api/chat -d '{
  "model": "llama2:7b",
  "messages": [
    {"role": "user", "content": "Hello!"}
  ],
  "stream": false
}'
```

## Installing llama.cpp

llama.cpp offers maximum performance through optimized C++ implementation.

### Building from Source

Compiling from source provides the best performance optimization for your specific hardware.

**Prerequisites:**

```bash
# Linux (Ubuntu/Debian)
sudo apt update
sudo apt install build-essential cmake git

# macOS (requires Xcode Command Line Tools)
xcode-select --install
brew install cmake

# Windows (requires Visual Studio Build Tools)
# Install Visual Studio 2022 Community with C++ workload
# Install CMake and Git
```

**Clone and Build:**

```bash
# Clone repository
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp

# Build with GPU support (NVIDIA)
mkdir build
cd build
cmake .. -DLLAMA_CUBLAS=ON
cmake --build . --config Release

# Build with GPU support (AMD ROCm)
cmake .. -DLLAMA_HIPBLAS=ON
cmake --build . --config Release

# Build with Metal support (macOS)
cmake .. -DLLAMA_METAL=ON
cmake --build . --config Release

# CPU-only build (maximum compatibility)
cmake ..
cmake --build . --config Release
```

**Build Optimization Options:**

```bash
# Advanced build options
cmake .. \
  -DLLAMA_CUBLAS=ON \           # NVIDIA GPU support
  -DLLAMA_FAST_MATH=ON \        # Enable fast math optimizations
  -DLLAMA_NATIVE=ON \           # Optimize for current CPU
  -DLLAMA_AVX2=ON \             # Enable AVX2 instructions
  -DLLAMA_FMA=ON \              # Enable FMA instructions
  -DCMAKE_BUILD_TYPE=Release    # Release build optimization
```

**Verify Build:**

```bash
# Test the build
./main --version

# Quick functionality test
./main -m ../models/7B/ggml-model-q4_0.gguf -p "Hello world" -n 10
```

### Pre-Built Binaries

Faster setup using pre-compiled binaries.

**Download Pre-Built Releases:**

```bash
# Linux x64 with CUDA support
wget https://github.com/ggerganov/llama.cpp/releases/download/b1681/llama-b1681-bin-ubuntu-x64.zip
unzip llama-b1681-bin-ubuntu-x64.zip
cd llama-b1681-bin-ubuntu-x64

# Make executable
chmod +x main server

# Test installation
./main --version
```

**Windows Binary Setup:**

1. Download the latest release from GitHub
2. Extract to `C:\llama.cpp`
3. Add to PATH environment variable
4. Verify with `main.exe --version`

**macOS Binary Setup:**

```bash
# Download and extract
wget https://github.com/ggerganov/llama.cpp/releases/download/b1681/llama-b1681-bin-macos-arm64.zip
unzip llama-b1681-bin-macos-arm64.zip

# Make executable
chmod +x main server

# Move to system path (optional)
sudo mv main server /usr/local/bin/
```

### Running Models

Basic usage patterns and optimization techniques.

**Download Models:**

```bash
# Create models directory
mkdir models
cd models

# Download popular models (GGUF format)
wget https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGUF/resolve/main/llama-2-7b-chat.q4_K_M.gguf
wget https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.1-GGUF/resolve/main/mistral-7b-instruct-v0.1.q4_K_M.gguf
wget https://huggingface.co/TheBloke/CodeLlama-7B-Instruct-GGUF/resolve/main/codellama-7b-instruct.q4_K_M.gguf
```

**Basic Inference:**

```bash
# Simple text completion
./main -m models/llama-2-7b-chat.q4_K_M.gguf -p "The future of AI is" -n 50

# Interactive chat mode
./main -m models/llama-2-7b-chat.q4_K_M.gguf -i --color

# Optimized parameters for better performance
./main -m models/llama-2-7b-chat.q4_K_M.gguf \
  -p "Write a Python function to calculate fibonacci numbers" \
  -n 200 \
  -c 4096 \
  -b 512 \
  -t 8 \
  --temp 0.7 \
  --top_p 0.9 \
  --repeat_penalty 1.1
```

**Server Mode:**

```bash
# Start HTTP server
./server -m models/llama-2-7b-chat.q4_K_M.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  -c 4096 \
  -ngl 35  # Number of layers to offload to GPU

# Test server with curl
curl http://localhost:8080/completion \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Building a website can be done in 10 simple steps:",
    "n_predict": 512
  }'
```

**Performance Optimization:**

```bash
# GPU layer offloading (-ngl parameter)
# RTX 4090: -ngl 35-40 for 7B models
# RTX 4080: -ngl 30-35 for 7B models
# RTX 4070: -ngl 25-30 for 7B models

# Memory mapping optimization
./main -m models/model.gguf --mlock --no-mmap

# Batch size optimization for throughput
./main -m models/model.gguf -b 512 -ub 512

# Thread optimization (set to physical cores)
./main -m models/model.gguf -t 8
```

## Text Generation WebUI Setup

Comprehensive setup for the most feature-rich local LLM interface.

### Installation Steps

Detailed installation process for all platforms.

**Automatic Installation (Recommended):**

```bash
# Clone repository
git clone https://github.com/oobabooga/text-generation-webui.git
cd text-generation-webui

# Run automatic installer
# Linux/macOS
./start_linux.sh  # or ./start_macos.sh

# Windows (run in Command Prompt)
start_windows.bat

# Follow prompts to:
# 1. Install conda/miniconda if needed
# 2. Create virtual environment
# 3. Install PyTorch with appropriate CUDA support
# 4. Install additional dependencies
```

**Manual Installation:**

```bash
# Create virtual environment
conda create -n textgen python=3.11
conda activate textgen

# Install PyTorch (adjust for your CUDA version)
pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install Text Generation WebUI
git clone https://github.com/oobabooga/text-generation-webui.git
cd text-generation-webui
pip install -r requirements.txt

# Install additional backends
pip install llama-cpp-python --upgrade --force-reinstall --no-cache-dir --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cu121
```

**Docker Installation:**

```yaml
# docker-compose.yml
version: '3.8'
services:
  text-generation-webui:
    image: ghcr.io/oobabooga/text-generation-webui:latest-cuda
    container_name: textgen
    environment:
      - CLI_ARGS=--listen --verbose
    ports:
      - "7860:7860"
    volumes:
      - ./models:/app/models
      - ./characters:/app/characters
      - ./presets:/app/presets
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    restart: unless-stopped
```

### Extension Installation

Enhancing functionality with community extensions.

**Popular Extensions:**

```bash
# Navigate to extensions directory
cd text-generation-webui/extensions

# Install Superbooga (RAG extension)
git clone https://github.com/jndiogo/gpt4-pdf-chatbot-langchain superbooga

# Install Silero TTS
git clone https://github.com/ouoertheo/silero_tts

# Install OpenAI extension (API compatibility)
git clone https://github.com/oobabooga/text-generation-webui-extensions openai

# Install LLaVA multimodal extension
git clone https://github.com/oobabooga/text-generation-webui-extensions llava
```

**Extension Configuration:**

```python
# Enable extensions in settings.yaml
extensions:
  - superbooga
  - silero_tts
  - openai

# Or enable via command line
python server.py --extensions superbooga silero_tts openai
```

### Configuration

Optimizing settings for your use case and hardware.

**Launch Configuration:**

```bash
# Basic launch
python server.py

# Optimized launch for GPU inference
python server.py \
  --model-dir models \
  --load-in-4bit \
  --use-double-quant \
  --compute_dtype bfloat16 \
  --quant_type nf4 \
  --gpu-memory 0.85

# Launch with specific model
python server.py \
  --model TheBloke_Llama-2-7B-Chat-GPTQ \
  --wbits 4 \
  --groupsize 128 \
  --model_type llama

# Multi-GPU setup
python server.py \
  --model your-model \
  --gpu-memory 0.75 0.75 \
  --auto-devices
```

**Web Interface Configuration:**

```yaml
# settings.yaml configuration file
default_extensions:
  - gallery
  - superbooga
  - silero_tts

default_model: 'None'
default_loader: Transformers

# Interface settings
chat-buttons: true
character_menu: true
show_controls: true

# Generation parameters
max_new_tokens: 512
do_sample: true
temperature: 0.7
top_p: 0.9
typical_p: 1
repetition_penalty: 1.1
```

**Model Loading Optimization:**

```python
# For 4-bit quantized models (GPTQ)
model_settings = {
    'wbits': 4,
    'groupsize': 128,
    'model_type': 'llama',
    'pre_layer': 0
}

# For 8-bit models
model_settings = {
    'load_in_8bit': True,
    'cpu_offload': False
}

# For CPU offloading
model_settings = {
    'load_in_4bit': True,
    'cpu_offload': 10  # Number of layers to offload
}
```

## GPU Configuration

Proper GPU setup is crucial for optimal local LLM performance.

### NVIDIA CUDA Setup

Configuring NVIDIA GPUs for maximum performance.

#### CUDA Installation Verification

```bash
# Verify CUDA installation
nvcc --version
nvidia-smi

# Check CUDA toolkit location
ls /usr/local/cuda/
echo $CUDA_HOME

# Test CUDA functionality
nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv
```

#### Framework-Specific CUDA Configuration

**Ollama CUDA Setup:**

```bash
# Ollama automatically detects CUDA
# Verify GPU usage during inference
watch -n 1 'nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits'

# Force specific GPU (multi-GPU systems)
export CUDA_VISIBLE_DEVICES=0  # Use first GPU only
ollama run llama2:7b
```

**llama.cpp CUDA Configuration:**

```bash
# Build with CUDA support
mkdir build && cd build
cmake .. -DLLAMA_CUBLAS=ON
make -j$(nproc)

# Test GPU acceleration
./main -m ../models/model.gguf -ngl 35 -p "Hello world" -n 10

# Monitor GPU usage
nvidia-smi -l 1
```

**PyTorch CUDA Setup:**

```python
# Verify PyTorch CUDA installation
import torch
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"CUDA devices: {torch.cuda.device_count()}")
print(f"Current device: {torch.cuda.current_device()}")
print(f"Device name: {torch.cuda.get_device_name()}")

# Memory management
torch.cuda.empty_cache()  # Clear GPU cache
print(f"Memory allocated: {torch.cuda.memory_allocated() / 1024**3:.2f} GB")
print(f"Memory reserved: {torch.cuda.memory_reserved() / 1024**3:.2f} GB")
```

#### Multi-GPU Configuration

```bash
# List available GPUs
nvidia-smi -L

# Configure specific GPUs for different applications
# Terminal 1: Use GPU 0 for Ollama
export CUDA_VISIBLE_DEVICES=0
ollama serve

# Terminal 2: Use GPU 1 for Text Generation WebUI
export CUDA_VISIBLE_DEVICES=1
python server.py --model your-model

# Load balancing across multiple GPUs
export CUDA_VISIBLE_DEVICES=0,1
python server.py --gpu-memory 0.5 0.5
```

### AMD ROCm Setup

Configuring AMD GPUs for local LLM inference.

#### ROCm Installation and Configuration

```bash
# Verify ROCm installation
rocm-smi
rocminfo

# Check supported GPUs
rocm-smi --showproductname

# Set environment variables for RX 7000 series
export HSA_OVERRIDE_GFX_VERSION=11.0.0
export ROCM_PATH=/opt/rocm
export HIP_VISIBLE_DEVICES=0
```

#### Framework Support for AMD

**llama.cpp with ROCm:**

```bash
# Build with HIP support
mkdir build && cd build
cmake .. -DLLAMA_HIPBLAS=ON
make -j$(nproc)

# Test AMD GPU acceleration
./main -m ../models/model.gguf -ngl 35 -p "Test" -n 10

# Monitor AMD GPU usage
watch -n 1 rocm-smi
```

**PyTorch ROCm Setup:**

```bash
# Install PyTorch with ROCm support
pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm5.7

# Verify ROCm in PyTorch
python -c "import torch; print(torch.cuda.is_available()); print(torch.cuda.device_count())"
```

### Apple Metal Setup

Optimizing M-series Macs for local LLM inference.

#### Metal Performance Shaders Configuration

```bash
# Verify Metal support
system_profiler SPDisplaysDataType | grep "Metal"

# Check available memory
system_profiler SPHardwareDataType | grep "Memory"

# Monitor memory usage during inference
activity_monitor  # Or use htop
```

#### MLX Framework Setup

```bash
# Install MLX for optimal Apple Silicon performance
pip install mlx mlx-lm

# Convert and run models with MLX
mlx_lm.convert --hf-path microsoft/DialoGPT-medium
mlx_lm.generate --model microsoft/DialoGPT-medium --prompt "Hello"
```

#### Ollama Metal Configuration

```bash
# Ollama automatically uses Metal on macOS
# Monitor performance with Activity Monitor

# Set memory limits for large models
export OLLAMA_METAL_MEMORY_BUDGET=32  # 32GB limit

# Optimize for sustained workloads
export OLLAMA_NUM_PARALLEL=1  # Reduce parallel processing
```

## Model Download and Management

Efficient model acquisition and organization strategies.

### Finding Models

Comprehensive guide to model sources and selection.

#### Primary Model Repositories

**Hugging Face Hub:**

```bash
# Install Hugging Face CLI
pip install huggingface_hub

# Login for access to gated models
huggingface-cli login

# Search for models
huggingface-cli search llama --task text-generation

# Download specific model
huggingface-cli download microsoft/DialoGPT-medium
```

**Popular Model Collections:**

- **TheBloke**: Comprehensive quantized model collection
  - GGUF format for llama.cpp
  - GPTQ format for GPU inference
  - AWQ format for efficient serving

- **Microsoft**: Official Microsoft models
  - DialoGPT for conversations
  - CodeBERT for code understanding

- **Meta**: Official Meta/Facebook models
  - Llama 2 series (7B, 13B, 70B)
  - Code Llama variants

#### Model Selection Criteria

**Performance vs Resources:**

```text
Model Size | VRAM (Q4) | RAM Offload | Use Case
1B-3B      | 2-4 GB    | 8 GB        | Mobile, testing
7B         | 4-6 GB    | 16 GB       | General chat, coding
13B        | 8-12 GB   | 32 GB       | Professional use
30B-34B    | 18-24 GB  | 64 GB       | Advanced tasks
70B+       | 40+ GB    | 128+ GB     | Research, production
```

**Quality Benchmarks:**

```text
Model              | MMLU | HumanEval | MT-Bench | Use Case
Llama-2-7B-Chat    | 48.3 | 14.0      | 6.3      | General chat
Mistral-7B-Instruct| 60.1 | 30.5      | 6.8      | Instruction following
CodeLlama-7B       | 36.0 | 53.7      | 5.1      | Code generation
Vicuna-13B         | 52.1 | 19.5      | 6.4      | Uncensored chat
WizardCoder-15B    | 42.7 | 59.8      | 5.8      | Programming tasks
```

### Model Formats

Understanding different formats and their use cases.

#### GGUF Format (llama.cpp)

**Advantages:**

- Optimized for CPU and GPU inference
- Multiple quantization levels in single file
- Cross-platform compatibility
- Memory-efficient loading

**File Naming Convention:**

```text
Format Examples:
llama-2-7b-chat.q4_K_M.gguf    # 4-bit quantization, K-means, Medium
llama-2-7b-chat.q5_K_S.gguf    # 5-bit quantization, K-means, Small
llama-2-7b-chat.q8_0.gguf      # 8-bit quantization

Quantization Levels:
Q8_0   - 8-bit quantization, highest quality
Q6_K   - 6-bit quantization, very good quality
Q5_K_M - 5-bit quantization, good quality, medium size
Q4_K_M - 4-bit quantization, acceptable quality, smaller
Q3_K_M - 3-bit quantization, lower quality, smallest
```

#### GPTQ Format

**Advantages:**

- Optimized for NVIDIA GPUs
- High performance with minimal quality loss
- 4-bit quantization standard
- Wide framework support

**Usage with Text Generation WebUI:**

```python
# Loading GPTQ models
model_settings = {
    'model_type': 'llama',
    'wbits': 4,
    'groupsize': 128,
    'desc_act': False
}
```

#### AWQ Format

**Advantages:**

- Activation-aware quantization
- Better quality preservation than GPTQ
- Optimized for inference
- Growing ecosystem support

#### Model Conversion

Converting between formats for different use cases.

**HuggingFace to GGUF:**

```bash
# Install conversion tools
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
pip install -r requirements.txt

# Convert model
python convert.py --outdir ./models/converted \
  --outtype q4_K_M \
  /path/to/huggingface/model
```

**GGUF to Different Quantizations:**

```bash
# Quantize existing GGUF model
./quantize ./models/model-f16.gguf ./models/model-q4_K_M.gguf q4_K_M

# Batch convert multiple quantization levels
for quant in q8_0 q6_K q5_K_M q4_K_M; do
  ./quantize ./models/model-f16.gguf ./models/model-$quant.gguf $quant
done
```

### Storage Organization

Best practices for managing large model collections.

#### Directory Structure

```text
~/models/
├── chat/
│   ├── llama-2-7b-chat.q4_K_M.gguf
│   ├── mistral-7b-instruct.q4_K_M.gguf
│   └── vicuna-13b.q4_K_M.gguf
├── code/
│   ├── codellama-7b-instruct.q4_K_M.gguf
│   ├── wizardcoder-15b.q4_K_M.gguf
│   └── deepseek-coder-6.7b.q4_K_M.gguf
├── roleplay/
│   ├── mythomax-l2-13b.q4_K_M.gguf
│   └── goliath-120b.q4_K_M.gguf
├── experimental/
│   └── new-models/
└── archive/
    └── old-versions/
```

#### Storage Management Scripts

```bash
#!/bin/bash
# model-manager.sh - Model management utility

MODEL_DIR="$HOME/models"

function list_models() {
    find "$MODEL_DIR" -name "*.gguf" -exec ls -lh {} \; | \
    awk '{print $9, $5}' | \
    sort -k2 -hr
}

function storage_usage() {
    du -sh "$MODEL_DIR"/*
}

function cleanup_temp() {
    find "$MODEL_DIR" -name "*.tmp" -delete
    find "$MODEL_DIR" -name "*.partial" -delete
}

function archive_model() {
    local model="$1"
    if [[ -f "$MODEL_DIR/$model" ]]; then
        mkdir -p "$MODEL_DIR/archive"
        mv "$MODEL_DIR/$model" "$MODEL_DIR/archive/"
        echo "Archived: $model"
    fi
}

# Usage examples
# ./model-manager.sh list
# ./model-manager.sh usage
# ./model-manager.sh cleanup
```

#### Automated Model Downloads

```python
#!/usr/bin/env python3
# download-models.py - Automated model downloader

import os
import requests
from pathlib import Path
from huggingface_hub import hf_hub_download

MODEL_CONFIGS = {
    'chat': {
        'llama2-7b': {
            'repo': 'TheBloke/Llama-2-7B-Chat-GGUF',
            'filename': 'llama-2-7b-chat.q4_K_M.gguf'
        },
        'mistral-7b': {
            'repo': 'TheBloke/Mistral-7B-Instruct-v0.1-GGUF',
            'filename': 'mistral-7b-instruct-v0.1.q4_K_M.gguf'
        }
    },
    'code': {
        'codellama-7b': {
            'repo': 'TheBloke/CodeLlama-7B-Instruct-GGUF',
            'filename': 'codellama-7b-instruct.q4_K_M.gguf'
        }
    }
}

def download_model(category, model_name, config):
    local_dir = Path.home() / 'models' / category
    local_dir.mkdir(parents=True, exist_ok=True)
    
    try:
        file_path = hf_hub_download(
            repo_id=config['repo'],
            filename=config['filename'],
            local_dir=local_dir,
            resume_download=True
        )
        print(f"Downloaded: {file_path}")
    except Exception as e:
        print(f"Error downloading {model_name}: {e}")

def main():
    for category, models in MODEL_CONFIGS.items():
        for model_name, config in models.items():
            print(f"Downloading {model_name}...")
            download_model(category, model_name, config)

if __name__ == '__main__':
    main()
```

## Network Configuration

Configuring network access and security for local LLM deployments.

### Local Access

Running LLMs for local-only access.

**Default Configurations:**

```bash
# Ollama - Local only (default)
ollama serve  # Binds to 127.0.0.1:11434

# llama.cpp server - Local only
./server -m model.gguf --host 127.0.0.1 --port 8080

# Text Generation WebUI - Local only
python server.py --listen-host 127.0.0.1 --listen-port 7860
```

### LAN Access

Configuring network access for multiple devices.

**Enable Network Access:**

```bash
# Ollama network access
export OLLAMA_HOST=0.0.0.0:11434
ollama serve

# llama.cpp network server
./server -m model.gguf --host 0.0.0.0 --port 8080

# Text Generation WebUI network access
python server.py --listen --listen-host 0.0.0.0 --listen-port 7860
```

**Firewall Configuration:**

```bash
# Linux (ufw)
sudo ufw allow 11434/tcp  # Ollama
sudo ufw allow 8080/tcp   # llama.cpp
sudo ufw allow 7860/tcp   # Text Generation WebUI

# Windows Firewall
netsh advfirewall firewall add rule name="Ollama" dir=in action=allow protocol=TCP localport=11434

# macOS
sudo pfctl -e
echo "pass in proto tcp from any to any port 11434" | sudo pfctl -f -
```

### Security Considerations

Securing your local LLM deployment.

**Authentication Setup:**

```bash
# Basic authentication for llama.cpp server
./server -m model.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  --api-key "your-secure-api-key"

# Test authenticated access
curl -H "Authorization: Bearer your-secure-api-key" \
  http://localhost:8080/completion \
  -d '{"prompt": "Hello"}'
```

**HTTPS Configuration:**

```bash
# Generate self-signed certificate
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes

# Configure reverse proxy with nginx
sudo tee /etc/nginx/sites-available/llm > /dev/null <<EOF
server {
    listen 443 ssl;
    server_name your-domain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/llm /etc/nginx/sites-enabled/
sudo systemctl reload nginx
```

## Environment Variables

Optimizing performance through environment configuration.

### Configuration Options

Essential environment variables for each framework.

**Ollama Environment Variables:**

```bash
# Server configuration
export OLLAMA_HOST="0.0.0.0:11434"        # Bind address
export OLLAMA_ORIGINS="*"                   # CORS origins
export OLLAMA_MODELS="/custom/models/path"  # Model storage path
export OLLAMA_KEEP_ALIVE="5m"               # Model unload timeout
export OLLAMA_MAX_LOADED_MODELS="2"         # Max concurrent models

# Performance tuning
export OLLAMA_NUM_PARALLEL="4"              # Parallel requests
export OLLAMA_MAX_QUEUE="512"               # Request queue size
export OLLAMA_FLASH_ATTENTION="1"           # Enable flash attention

# GPU configuration
export OLLAMA_GPU_OVERHEAD="0"              # GPU memory overhead
export CUDA_VISIBLE_DEVICES="0,1"           # Specific GPU selection
```

**llama.cpp Environment Variables:**

```bash
# CUDA configuration
export CUDA_VISIBLE_DEVICES="0"             # GPU selection
export GGML_CUDA_FORCE_DMMV="1"            # Force DMMV kernels
export GGML_CUDA_F16="1"                    # Use FP16 for better performance

# ROCm configuration (AMD)
export HSA_OVERRIDE_GFX_VERSION="11.0.0"   # For RX 7000 series
export ROCM_PATH="/opt/rocm"

# Performance optimization
export OMP_NUM_THREADS="8"                  # OpenMP threads
export GGML_METAL_EMBED_LIBRARY="1"        # macOS Metal optimization
```

**PyTorch/Transformers Variables:**

```bash
# Memory optimization
export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:128"
export TRANSFORMERS_CACHE="/path/to/cache" # Model cache location

# Performance tuning
export TOKENIZERS_PARALLELISM="false"      # Disable tokenizer parallelism
export CUDA_LAUNCH_BLOCKING="0"            # Async CUDA operations
export TORCH_USE_CUDA_DSA="1"              # Device-side assertions
```

### Performance Tuning

Optimizing inference performance through environment configuration.

**Memory Management:**

```bash
# Linux memory optimization
echo 1 > /proc/sys/vm/overcommit_memory    # Allow memory overcommit
echo 1000 > /proc/sys/vm/swappiness        # Reduce swap usage

# Set memory limits for containers
export OLLAMA_MAX_VRAM="12GB"              # Limit VRAM usage
export OLLAMA_MAX_RAM="32GB"               # Limit RAM usage
```

**CPU Optimization:**

```bash
# CPU governor for performance
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Thread affinity
export GOMP_CPU_AFFINITY="0-7"             # Bind to specific CPU cores
export OMP_PROC_BIND="true"                # Enable processor binding
```

## Verification and Testing

Ensuring your installation works correctly.

### Testing Installation

Basic functionality verification for each framework.

**Ollama Testing:**

```bash
# Test Ollama installation
ollama --version

# Test model download and inference
ollama pull phi:2.7b
echo "Write a hello world program in Python" | ollama run phi:2.7b

# API testing
curl http://localhost:11434/api/generate -d '{
  "model": "phi:2.7b",
  "prompt": "Hello world",
  "stream": false
}'
```

**llama.cpp Testing:**

```bash
# Test build
./main --version

# Test inference with sample
./main -m models/phi-2.q4_K_M.gguf -p "Python hello world:" -n 50

# Test server mode
./server -m models/phi-2.q4_K_M.gguf --host 127.0.0.1 --port 8080 &
sleep 5
curl http://localhost:8080/completion -d '{"prompt": "Hello", "n_predict": 10}'
```

### Running Benchmarks

Performance testing and optimization validation.

**Simple Performance Test:**

```bash
#!/bin/bash
# benchmark.sh - Simple LLM performance test

MODEL="phi:2.7b"
PROMPT="Write a detailed explanation of machine learning in 200 words."

echo "Testing Ollama performance..."
time ollama run $MODEL "$PROMPT" > /dev/null

echo "Testing with longer context..."
LONG_PROMPT="Explain quantum computing, artificial intelligence, and blockchain technology in detail."
time ollama run $MODEL "$LONG_PROMPT" > /dev/null
```

**Comprehensive Benchmark Script:**

```python
#!/usr/bin/env python3
# comprehensive_benchmark.py

import time
import requests
import statistics
from typing import List

def benchmark_ollama(model: str, prompts: List[str], runs: int = 3) -> dict:
    results = []
    
    for prompt in prompts:
        times = []
        tokens = []
        
        for _ in range(runs):
            start_time = time.time()
            
            response = requests.post('http://localhost:11434/api/generate', json={
                'model': model,
                'prompt': prompt,
                'stream': False
            })
            
            end_time = time.time()
            
            if response.status_code == 200:
                data = response.json()
                duration = end_time - start_time
                token_count = len(data.get('response', '').split())
                
                times.append(duration)
                tokens.append(token_count)
        
        if times:
            results.append({
                'prompt': prompt[:50] + '...',
                'avg_time': statistics.mean(times),
                'avg_tokens': statistics.mean(tokens),
                'tokens_per_second': statistics.mean(tokens) / statistics.mean(times)
            })
    
    return results

# Test prompts
test_prompts = [
    "Hello, how are you?",
    "Write a Python function to calculate fibonacci numbers.",
    "Explain the theory of relativity in simple terms."
]

if __name__ == '__main__':
    results = benchmark_ollama('phi:2.7b', test_prompts)
    
    for result in results:
        print(f"Prompt: {result['prompt']}")
        print(f"Average time: {result['avg_time']:.2f}s")
        print(f"Tokens/second: {result['tokens_per_second']:.2f}")
        print("---")
```

### First Inference

Testing your setup with initial queries.

**Interactive Testing:**

```bash
# Test different types of queries
echo "Mathematics: What is 2+2?" | ollama run phi:2.7b
echo "Coding: Write hello world in Java" | ollama run phi:2.7b
echo "Creative: Write a haiku about AI" | ollama run phi:2.7b
echo "Analysis: Summarize the benefits of renewable energy" | ollama run phi:2.7b
```

## Troubleshooting Installation

Common issues and their solutions.

### Common Issues

Frequently encountered problems and fixes.

**CUDA Out of Memory:**

```bash
# Symptoms: RuntimeError: CUDA out of memory
# Solutions:

# 1. Reduce model size or use quantization
ollama pull llama2:7b    # Instead of llama2:13b

# 2. Adjust GPU memory allocation
export OLLAMA_GPU_OVERHEAD="1GB"

# 3. Use CPU offloading
./main -m model.gguf -ngl 20  # Reduce GPU layers

# 4. Clear GPU memory
nvidia-smi --gpu-reset
```

**Slow Performance:**

```bash
# Check GPU utilization
nvidia-smi -l 1

# Verify GPU acceleration
ollama run llama2:7b --verbose

# Check system resources
htop
iotop -a

# Optimize environment
export OMP_NUM_THREADS=$(nproc)
export OLLAMA_NUM_PARALLEL=1
```

**Model Loading Errors:**

```bash
# Verify model file integrity
sha256sum models/model.gguf

# Re-download corrupted models
ollama rm model-name
ollama pull model-name

# Check file permissions
ls -la models/
chown $USER:$USER models/*.gguf
```

### Driver Problems

GPU driver troubleshooting.

**NVIDIA Driver Issues:**

```bash
# Check driver installation
nvidia-smi
lsmod | grep nvidia

# Reinstall drivers if needed
sudo apt remove --purge nvidia-*
sudo apt install nvidia-driver-535
sudo reboot

# Verify CUDA toolkit
nvcc --version
ls /usr/local/cuda/
```

**AMD Driver Issues:**

```bash
# Check ROCm installation
rocminfo
ls /opt/rocm/

# Reinstall ROCm
sudo apt remove --purge rocm-*
# Follow ROCm installation guide
```

### Dependency Conflicts

Resolving library and version conflicts.

**Python Environment Conflicts:**

```bash
# Create clean environment
conda create -n clean-llm python=3.11
conda activate clean-llm

# Install specific versions
pip install torch==2.1.0 torchvision==0.16.0 --index-url https://download.pytorch.org/whl/cu121

# Verify no conflicts
pip check
```

**Library Version Issues:**

```bash
# Check installed versions
pip list | grep -E "torch|transformers|accelerate"

# Fix common conflicts
pip install --upgrade transformers accelerate bitsandbytes

# Force reinstall problematic packages
pip install --force-reinstall --no-cache-dir torch
```

## Updating

Keeping your local LLM installation current.

**Ollama Updates:**

```bash
# Update Ollama (Linux/macOS)
curl -fsSL https://ollama.ai/install.sh | sh

# Update models
ollama list  # Check current versions
ollama pull llama2:7b  # Re-pull for updates
```

**llama.cpp Updates:**

```bash
# Update from git
cd llama.cpp
git pull origin master
make clean
cmake --build build --config Release
```

**Framework Updates:**

```bash
# Update Text Generation WebUI
cd text-generation-webui
git pull
pip install -r requirements.txt --upgrade

# Update Python packages
pip install --upgrade torch transformers accelerate
```

## Uninstallation

Clean removal procedures for complete uninstallation.

**Ollama Removal:**

```bash
# Stop service
sudo systemctl stop ollama
sudo systemctl disable ollama

# Remove files
sudo rm /usr/bin/ollama
sudo rm /etc/systemd/system/ollama.service
rm -rf ~/.ollama

# Remove user (if created)
sudo userdel ollama
```

**Complete Environment Cleanup:**

```bash
# Remove conda environment
conda env remove -n llm-env

# Remove models and cache
rm -rf ~/models
rm -rf ~/.cache/huggingface
rm -rf ~/.cache/torch

# Clean up Docker (if used)
docker system prune -a
docker volume prune
```

By following this comprehensive guide, you should be able to successfully install, configure, and optimize local LLM frameworks for your specific use case and hardware configuration. Regular maintenance and updates will ensure optimal performance and access to the latest models and features.
