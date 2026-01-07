---
title: PyTorch - Deep Learning Framework
description: Comprehensive guide to PyTorch, the dynamic deep learning framework for research and production with GPU acceleration and automatic differentiation
---

PyTorch is an open-source deep learning framework developed by Meta AI (formerly Facebook AI Research) that provides a flexible, pythonic interface for building neural networks. It features dynamic computational graphs, automatic differentiation, and seamless GPU acceleration, making it the preferred choice for both research and production in machine learning.

## Overview

PyTorch revolutionized deep learning by introducing dynamic computation graphs (define-by-run), allowing for more intuitive and flexible model building compared to static graph frameworks. Its tight integration with Python, NumPy-like tensor operations, and powerful automatic differentiation system make it exceptionally productive for rapid prototyping and experimentation.

The framework has become the dominant choice in research (used in over 70% of ML papers) and is increasingly adopted in production environments through tools like TorchServe and TorchScript. PyTorch's ecosystem includes specialized libraries for computer vision (torchvision), natural language processing (torchtext), audio processing (torchaudio), and more.

## Key Features

### Dynamic Computational Graphs

- **Define-by-run execution**: Graphs built on-the-fly during forward pass
- **Native Python control flow**: Use if/else, loops, and functions naturally
- **Easy debugging**: Standard Python debuggers work seamlessly
- **Flexibility**: Graph structure can change between iterations

### Automatic Differentiation

- **Autograd system**: Automatic gradient computation for any operation
- **Reverse-mode differentiation**: Efficient backpropagation
- **Higher-order gradients**: Support for second derivatives and beyond
- **Custom gradient functions**: Define custom backward passes

### GPU Acceleration

- **CUDA integration**: Native GPU support for NVIDIA GPUs
- **Simple device management**: Move tensors/models with `.to(device)`
- **Multi-GPU training**: Built-in data parallel and distributed training
- **Mixed precision**: Automatic mixed precision (AMP) for faster training

### Production Readiness

- **TorchScript**: Compile models for deployment
- **TorchServe**: Production-grade model serving
- **ONNX export**: Interoperability with other frameworks
- **Mobile deployment**: PyTorch Mobile for iOS and Android

## Installation

### Using pip

```bash
# CPU only
pip install torch torchvision torchaudio

# CUDA 11.8 (check PyTorch website for latest)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# CUDA 12.1
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
```

### Using conda

```bash
# CPU only
conda install pytorch torchvision torchaudio cpuonly -c pytorch

# CUDA 11.8
conda install pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia

# CUDA 12.1
conda install pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia
```

### Using UV (Fastest)

```bash
# CPU only
uv pip install torch torchvision torchaudio

# CUDA 11.8
uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Verify installation and check CUDA availability
python -c "import torch; print(torch.__version__); print(torch.cuda.is_available())"
```

### Build from Source

For cutting-edge features or custom builds:

```bash
git clone --recursive https://github.com/pytorch/pytorch
cd pytorch
export CMAKE_PREFIX_PATH=${CONDA_PREFIX:-"$(dirname $(which conda))/../"}
python setup.py install
```

## Core Concepts

### Tensors

Tensors are the fundamental data structure in PyTorch, similar to NumPy arrays but with GPU acceleration support.

#### Creating Tensors

```python
import torch

# From Python lists
tensor_a = torch.tensor([1, 2, 3, 4])
tensor_b = torch.tensor([[1, 2], [3, 4]])

# Zeros and ones
zeros = torch.zeros(3, 4)
ones = torch.ones(2, 3)

# Random tensors
rand_uniform = torch.rand(2, 3)  # Uniform [0, 1)
rand_normal = torch.randn(2, 3)  # Normal distribution
rand_int = torch.randint(0, 10, (3, 3))  # Random integers

# From NumPy arrays
import numpy as np
numpy_array = np.array([1, 2, 3])
tensor_from_numpy = torch.from_numpy(numpy_array)

# Like another tensor (same shape, different data)
x = torch.ones(2, 3)
y = torch.zeros_like(x)
z = torch.rand_like(x)

# Specified data types
float_tensor = torch.tensor([1, 2, 3], dtype=torch.float32)
int_tensor = torch.tensor([1.5, 2.7], dtype=torch.int64)
```

#### Tensor Properties

```python
tensor = torch.randn(3, 4, 5)

print(tensor.shape)        # torch.Size([3, 4, 5])
print(tensor.size())       # Same as shape
print(tensor.dtype)        # torch.float32
print(tensor.device)       # cpu or cuda
print(tensor.requires_grad) # False by default
print(tensor.ndim)         # 3 (number of dimensions)
print(tensor.numel())      # 60 (total elements)
```

#### Tensor Operations

```python
# Element-wise operations
x = torch.tensor([1.0, 2.0, 3.0])
y = torch.tensor([4.0, 5.0, 6.0])

addition = x + y
subtraction = x - y
multiplication = x * y
division = x / y
power = x ** 2

# In-place operations (end with _)
x.add_(y)      # x = x + y
x.mul_(2)      # x = x * 2
x.sqrt_()      # x = sqrt(x)

# Matrix operations
a = torch.randn(3, 4)
b = torch.randn(4, 5)

matmul = torch.matmul(a, b)  # or a @ b
matmul = a.mm(b)             # same as matmul for 2D
transpose = a.t()            # or a.T

# Reduction operations
tensor = torch.randn(3, 4)
sum_all = tensor.sum()
sum_dim0 = tensor.sum(dim=0)  # Sum along dimension 0
mean = tensor.mean()
max_val = tensor.max()
argmax = tensor.argmax()

# Reshaping
x = torch.randn(12)
reshaped = x.view(3, 4)      # View (shares memory)
reshaped = x.reshape(3, 4)   # Reshape (may copy)
flattened = x.flatten()
squeezed = torch.randn(1, 3, 1).squeeze()  # Remove dims of size 1
unsqueezed = x.unsqueeze(0)  # Add dimension

# Concatenation and stacking
x = torch.randn(2, 3)
y = torch.randn(2, 3)

concatenated = torch.cat([x, y], dim=0)  # Shape: (4, 3)
stacked = torch.stack([x, y], dim=0)     # Shape: (2, 2, 3)
```

### Moving Tensors Between Devices

```python
# Check CUDA availability
print(torch.cuda.is_available())
print(torch.cuda.device_count())
print(torch.cuda.get_device_name(0))

# Create tensors on GPU
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# Method 1: Specify device during creation
tensor_gpu = torch.randn(3, 4, device=device)

# Method 2: Move existing tensor to GPU
tensor_cpu = torch.randn(3, 4)
tensor_gpu = tensor_cpu.to(device)
tensor_gpu = tensor_cpu.cuda()  # Alternative

# Move back to CPU
tensor_cpu = tensor_gpu.cpu()
tensor_cpu = tensor_gpu.to("cpu")

# Multi-GPU
tensor_gpu0 = torch.randn(3, 4, device="cuda:0")
tensor_gpu1 = torch.randn(3, 4, device="cuda:1")
```

### Autograd and Automatic Differentiation

PyTorch's autograd system automatically computes gradients for tensor operations.

#### Basic Autograd

```python
# Enable gradient tracking
x = torch.tensor([2.0, 3.0], requires_grad=True)

# Forward pass
y = x ** 2
z = y.sum()

# Backward pass (compute gradients)
z.backward()

# Access gradients
print(x.grad)  # tensor([4., 6.])  (dz/dx)

# Gradient accumulation (multiple backward passes)
x.grad.zero_()  # Clear previous gradients
z.backward()
```

#### Gradient Context Managers

```python
# Disable gradient tracking (inference mode)
with torch.no_grad():
    y = x ** 2  # No gradient computation
    
# Inference mode (faster than no_grad)
with torch.inference_mode():
    y = x ** 2
    
# Temporarily enable gradients
x = torch.tensor([1.0], requires_grad=False)
with torch.enable_grad():
    x.requires_grad = True
    y = x ** 2
```

#### Custom Backward Functions

```python
class CustomFunction(torch.autograd.Function):
    @staticmethod
    def forward(ctx, input):
        ctx.save_for_backward(input)
        return input.clamp(min=0)  # ReLU-like function
        
    @staticmethod
    def backward(ctx, grad_output):
        input, = ctx.saved_tensors
        grad_input = grad_output.clone()
        grad_input[input < 0] = 0
        return grad_input

# Usage
x = torch.randn(5, requires_grad=True)
y = CustomFunction.apply(x)
y.sum().backward()
```

## Building Neural Networks

### nn.Module Basics

All neural networks inherit from `torch.nn.Module`:

```python
import torch.nn as nn
import torch.nn.functional as F

class SimpleNetwork(nn.Module):
    def __init__(self, InputSize, HiddenSize, OutputSize):
        super(SimpleNetwork, self).__init__()
        self.Fc1 = nn.Linear(InputSize, HiddenSize)
        self.Fc2 = nn.Linear(HiddenSize, OutputSize)
        
    def forward(self, x):
        x = F.relu(self.Fc1(x))
        x = self.Fc2(x)
        return x

# Create and use the network
model = SimpleNetwork(784, 128, 10)
input_data = torch.randn(32, 784)  # Batch size 32
output = model(input_data)
print(output.shape)  # torch.Size([32, 10])
```

### Common Neural Network Layers

#### Linear (Fully Connected) Layers

```python
# Basic linear layer
linear = nn.Linear(in_features=100, out_features=50, bias=True)

# With custom initialization
linear = nn.Linear(100, 50)
nn.init.xavier_uniform_(linear.weight)
nn.init.zeros_(linear.bias)
```

#### Convolutional Layers

```python
# 2D Convolution (for images)
conv2d = nn.Conv2d(
    in_channels=3,      # RGB input
    out_channels=64,    # Number of filters
    kernel_size=3,      # 3x3 kernel
    stride=1,
    padding=1
)

# 1D Convolution (for sequences)
conv1d = nn.Conv1d(in_channels=256, out_channels=128, kernel_size=5)

# Transposed convolution (upsampling)
deconv = nn.ConvTranspose2d(64, 32, kernel_size=4, stride=2, padding=1)
```

#### Pooling Layers

```python
# Max pooling
maxpool = nn.MaxPool2d(kernel_size=2, stride=2)

# Average pooling
avgpool = nn.AvgPool2d(kernel_size=2, stride=2)

# Adaptive pooling (output size independent of input size)
adaptive = nn.AdaptiveAvgPool2d(output_size=(7, 7))
```

#### Normalization Layers

```python
# Batch normalization
batch_norm = nn.BatchNorm2d(num_features=64)

# Layer normalization
layer_norm = nn.LayerNorm(normalized_shape=[128])

# Instance normalization
instance_norm = nn.InstanceNorm2d(num_features=64)

# Group normalization
group_norm = nn.GroupNorm(num_groups=8, num_channels=64)
```

#### Dropout and Regularization

```python
# Standard dropout
dropout = nn.Dropout(p=0.5)

# 2D dropout (for convolutional layers)
dropout2d = nn.Dropout2d(p=0.5)

# Alpha dropout (for SELU activation)
alpha_dropout = nn.AlphaDropout(p=0.5)
```

#### Recurrent Layers

```python
# LSTM
lstm = nn.LSTM(
    input_size=256,
    hidden_size=512,
    num_layers=2,
    batch_first=True,
    dropout=0.5,
    bidirectional=False
)

# GRU
gru = nn.GRU(input_size=256, hidden_size=512, num_layers=2, batch_first=True)

# Simple RNN
rnn = nn.RNN(input_size=256, hidden_size=512, batch_first=True)
```

#### Attention Layers

```python
# Multi-head attention
attention = nn.MultiheadAttention(
    embed_dim=512,
    num_heads=8,
    dropout=0.1,
    batch_first=True
)

# Transformer encoder layer
encoder_layer = nn.TransformerEncoderLayer(
    d_model=512,
    nhead=8,
    dim_feedforward=2048,
    dropout=0.1
)

# Full transformer encoder
encoder = nn.TransformerEncoder(encoder_layer, num_layers=6)
```

### Activation Functions

```python
# ReLU (most common)
relu = nn.ReLU()
output = F.relu(input)  # Functional API

# Leaky ReLU
leaky_relu = nn.LeakyReLU(negative_slope=0.01)

# GELU (used in transformers)
gelu = nn.GELU()

# Sigmoid
sigmoid = nn.Sigmoid()

# Tanh
tanh = nn.Tanh()

# Softmax
softmax = nn.Softmax(dim=-1)

# ELU
elu = nn.ELU(alpha=1.0)

# SELU (self-normalizing)
selu = nn.SELU()

# Swish/SiLU
silu = nn.SiLU()
```

### Complex Network Architectures

#### Convolutional Neural Network (CNN)

```python
class CNN(nn.Module):
    def __init__(self, NumClasses=10):
        super(CNN, self).__init__()
        
        # Convolutional layers
        self.Conv1 = nn.Conv2d(3, 64, kernel_size=3, padding=1)
        self.Bn1 = nn.BatchNorm2d(64)
        self.Conv2 = nn.Conv2d(64, 128, kernel_size=3, padding=1)
        self.Bn2 = nn.BatchNorm2d(128)
        self.Conv3 = nn.Conv2d(128, 256, kernel_size=3, padding=1)
        self.Bn3 = nn.BatchNorm2d(256)
        
        self.Pool = nn.MaxPool2d(2, 2)
        self.Dropout = nn.Dropout(0.5)
        
        # Fully connected layers
        self.Fc1 = nn.Linear(256 * 4 * 4, 512)
        self.Fc2 = nn.Linear(512, NumClasses)
        
    def forward(self, x):
        # Input: (batch, 3, 32, 32)
        x = self.Pool(F.relu(self.Bn1(self.Conv1(x))))  # (batch, 64, 16, 16)
        x = self.Pool(F.relu(self.Bn2(self.Conv2(x))))  # (batch, 128, 8, 8)
        x = self.Pool(F.relu(self.Bn3(self.Conv3(x))))  # (batch, 256, 4, 4)
        
        x = x.view(x.size(0), -1)  # Flatten
        x = self.Dropout(F.relu(self.Fc1(x)))
        x = self.Fc2(x)
        return x
```

#### Recurrent Neural Network (RNN)

```python
class RNNClassifier(nn.Module):
    def __init__(self, VocabSize, EmbedDim, HiddenDim, NumClasses, NumLayers=2):
        super(RNNClassifier, self).__init__()
        
        self.Embedding = nn.Embedding(VocabSize, EmbedDim)
        self.Lstm = nn.LSTM(
            EmbedDim,
            HiddenDim,
            num_layers=NumLayers,
            batch_first=True,
            dropout=0.5,
            bidirectional=True
        )
        self.Fc = nn.Linear(HiddenDim * 2, NumClasses)  # *2 for bidirectional
        self.Dropout = nn.Dropout(0.5)
        
    def forward(self, x):
        # x shape: (batch, seq_len)
        embedded = self.Embedding(x)  # (batch, seq_len, embed_dim)
        
        # LSTM output
        lstm_out, (hidden, cell) = self.Lstm(embedded)
        
        # Use final hidden state from both directions
        hidden = torch.cat((hidden[-2], hidden[-1]), dim=1)
        
        output = self.Dropout(hidden)
        output = self.Fc(output)
        return output
```

#### Transformer Network

```python
class TransformerClassifier(nn.Module):
    def __init__(self, VocabSize, EmbedDim, NumHeads, NumLayers, NumClasses, MaxSeqLen=512):
        super(TransformerClassifier, self).__init__()
        
        self.Embedding = nn.Embedding(VocabSize, EmbedDim)
        self.PositionalEncoding = self._create_positional_encoding(MaxSeqLen, EmbedDim)
        
        encoder_layer = nn.TransformerEncoderLayer(
            d_model=EmbedDim,
            nhead=NumHeads,
            dim_feedforward=EmbedDim * 4,
            dropout=0.1,
            batch_first=True
        )
        self.Transformer = nn.TransformerEncoder(encoder_layer, num_layers=NumLayers)
        
        self.Fc = nn.Linear(EmbedDim, NumClasses)
        self.Dropout = nn.Dropout(0.1)
        
    def _create_positional_encoding(self, MaxLen, Dim):
        pe = torch.zeros(MaxLen, Dim)
        position = torch.arange(0, MaxLen, dtype=torch.float).unsqueeze(1)
        div_term = torch.exp(torch.arange(0, Dim, 2).float() * (-torch.log(torch.tensor(10000.0)) / Dim))
        
        pe[:, 0::2] = torch.sin(position * div_term)
        pe[:, 1::2] = torch.cos(position * div_term)
        return nn.Parameter(pe.unsqueeze(0), requires_grad=False)
        
    def forward(self, x):
        # x shape: (batch, seq_len)
        seq_len = x.size(1)
        
        embedded = self.Embedding(x)
        embedded = embedded + self.PositionalEncoding[:, :seq_len, :]
        embedded = self.Dropout(embedded)
        
        transformer_out = self.Transformer(embedded)
        
        # Global average pooling
        pooled = transformer_out.mean(dim=1)
        
        output = self.Fc(pooled)
        return output
```

#### Residual Network (ResNet)

```python
class ResidualBlock(nn.Module):
    def __init__(self, InChannels, OutChannels, stride=1):
        super(ResidualBlock, self).__init__()
        
        self.Conv1 = nn.Conv2d(InChannels, OutChannels, kernel_size=3, stride=stride, padding=1, bias=False)
        self.Bn1 = nn.BatchNorm2d(OutChannels)
        self.Conv2 = nn.Conv2d(OutChannels, OutChannels, kernel_size=3, stride=1, padding=1, bias=False)
        self.Bn2 = nn.BatchNorm2d(OutChannels)
        
        # Shortcut connection
        self.Shortcut = nn.Sequential()
        if stride != 1 or InChannels != OutChannels:
            self.Shortcut = nn.Sequential(
                nn.Conv2d(InChannels, OutChannels, kernel_size=1, stride=stride, bias=False),
                nn.BatchNorm2d(OutChannels)
            )
            
    def forward(self, x):
        out = F.relu(self.Bn1(self.Conv1(x)))
        out = self.Bn2(self.Conv2(out))
        out += self.Shortcut(x)
        out = F.relu(out)
        return out

class ResNet(nn.Module):
    def __init__(self, block, NumBlocks, NumClasses=10):
        super(ResNet, self).__init__()
        
        self.InChannels = 64
        self.Conv1 = nn.Conv2d(3, 64, kernel_size=3, stride=1, padding=1, bias=False)
        self.Bn1 = nn.BatchNorm2d(64)
        
        self.Layer1 = self._make_layer(block, 64, NumBlocks[0], stride=1)
        self.Layer2 = self._make_layer(block, 128, NumBlocks[1], stride=2)
        self.Layer3 = self._make_layer(block, 256, NumBlocks[2], stride=2)
        self.Layer4 = self._make_layer(block, 512, NumBlocks[3], stride=2)
        
        self.AvgPool = nn.AdaptiveAvgPool2d((1, 1))
        self.Fc = nn.Linear(512, NumClasses)
        
    def _make_layer(self, block, OutChannels, NumBlocks, stride):
        strides = [stride] + [1] * (NumBlocks - 1)
        layers = []
        for stride in strides:
            layers.append(block(self.InChannels, OutChannels, stride))
            self.InChannels = OutChannels
        return nn.Sequential(*layers)
        
    def forward(self, x):
        out = F.relu(self.Bn1(self.Conv1(x)))
        out = self.Layer1(out)
        out = self.Layer2(out)
        out = self.Layer3(out)
        out = self.Layer4(out)
        out = self.AvgPool(out)
        out = out.view(out.size(0), -1)
        out = self.Fc(out)
        return out

# Create ResNet-18
def ResNet18(NumClasses=10):
    return ResNet(ResidualBlock, [2, 2, 2, 2], NumClasses)
```

## Training Neural Networks

### Basic Training Loop

```python
import torch.optim as optim

# Setup
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = SimpleNetwork(784, 128, 10).to(device)
criterion = nn.CrossEntropyLoss()
optimizer = optim.Adam(model.parameters(), lr=0.001)

# Training loop
NumEpochs = 10
for epoch in range(NumEpochs):
    model.train()  # Set to training mode
    running_loss = 0.0
    
    for batch_idx, (data, target) in enumerate(train_loader):
        # Move data to device
        data, target = data.to(device), target.to(device)
        
        # Zero gradients
        optimizer.zero_grad()
        
        # Forward pass
        output = model(data)
        loss = criterion(output, target)
        
        # Backward pass
        loss.backward()
        
        # Update weights
        optimizer.step()
        
        running_loss += loss.item()
        
        if batch_idx % 100 == 0:
            print(f'Epoch [{epoch+1}/{NumEpochs}], Step [{batch_idx}/{len(train_loader)}], Loss: {loss.item():.4f}')
    
    avg_loss = running_loss / len(train_loader)
    print(f'Epoch [{epoch+1}/{NumEpochs}], Average Loss: {avg_loss:.4f}')
```

### Validation and Testing

```python
def evaluate(model, data_loader, device):
    model.eval()  # Set to evaluation mode
    correct = 0
    total = 0
    total_loss = 0
    
    with torch.no_grad():  # Disable gradient computation
        for data, target in data_loader:
            data, target = data.to(device), target.to(device)
            
            output = model(data)
            loss = criterion(output, target)
            total_loss += loss.item()
            
            # Get predictions
            _, predicted = torch.max(output.data, 1)
            total += target.size(0)
            correct += (predicted == target).sum().item()
    
    accuracy = 100 * correct / total
    avg_loss = total_loss / len(data_loader)
    
    return accuracy, avg_loss

# Validation during training
for epoch in range(NumEpochs):
    # Training code here...
    
    # Validation
    val_accuracy, val_loss = evaluate(model, val_loader, device)
    print(f'Validation - Accuracy: {val_accuracy:.2f}%, Loss: {val_loss:.4f}')
```

### Loss Functions

```python
# Classification
cross_entropy = nn.CrossEntropyLoss()  # For multi-class classification
bce = nn.BCELoss()  # Binary cross-entropy
bce_logits = nn.BCEWithLogitsLoss()  # BCE with sigmoid (more stable)
nll = nn.NLLLoss()  # Negative log likelihood

# Regression
mse = nn.MSELoss()  # Mean squared error
mae = nn.L1Loss()  # Mean absolute error
smooth_l1 = nn.SmoothL1Loss()  # Huber loss
huber = nn.HuberLoss()

# Custom loss with weights
weights = torch.tensor([1.0, 2.0, 3.0])  # Class weights
weighted_ce = nn.CrossEntropyLoss(weight=weights)
```

### Optimizers

```python
# SGD (Stochastic Gradient Descent)
optimizer = optim.SGD(model.parameters(), lr=0.01, momentum=0.9, weight_decay=1e-4)

# Adam (Adaptive Moment Estimation)
optimizer = optim.Adam(model.parameters(), lr=0.001, betas=(0.9, 0.999), weight_decay=1e-4)

# AdamW (Adam with weight decay fix)
optimizer = optim.AdamW(model.parameters(), lr=0.001, weight_decay=0.01)

# RMSprop
optimizer = optim.RMSprop(model.parameters(), lr=0.001, alpha=0.99)

# Adagrad
optimizer = optim.Adagrad(model.parameters(), lr=0.01)

# Adadelta
optimizer = optim.Adadelta(model.parameters(), lr=1.0, rho=0.9)

# Per-parameter options
optimizer = optim.SGD([
    {'params': model.conv_layers.parameters(), 'lr': 0.01},
    {'params': model.fc_layers.parameters(), 'lr': 0.001}
], momentum=0.9)
```

### Learning Rate Scheduling

```python
from torch.optim.lr_scheduler import StepLR, ReduceLROnPlateau, CosineAnnealingLR, OneCycleLR

# Step decay
scheduler = StepLR(optimizer, step_size=30, gamma=0.1)

# Reduce on plateau
scheduler = ReduceLROnPlateau(optimizer, mode='min', factor=0.1, patience=10, verbose=True)

# Cosine annealing
scheduler = CosineAnnealingLR(optimizer, T_max=100, eta_min=0)

# One cycle policy (super-convergence)
scheduler = OneCycleLR(optimizer, max_lr=0.01, steps_per_epoch=len(train_loader), epochs=NumEpochs)

# Exponential decay
scheduler = torch.optim.lr_scheduler.ExponentialLR(optimizer, gamma=0.95)

# Usage in training loop
for epoch in range(NumEpochs):
    for batch in train_loader:
        # Training code...
        optimizer.step()
        scheduler.step()  # For OneCycleLR (per batch)
    
    # scheduler.step()  # For StepLR, CosineAnnealingLR (per epoch)
    # scheduler.step(val_loss)  # For ReduceLROnPlateau
```

### Gradient Clipping

```python
# Clip by norm
torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)

# Clip by value
torch.nn.utils.clip_grad_value_(model.parameters(), clip_value=0.5)

# Usage in training loop
for epoch in range(NumEpochs):
    for data, target in train_loader:
        optimizer.zero_grad()
        output = model(data)
        loss = criterion(output, target)
        loss.backward()
        
        # Clip gradients before optimizer step
        torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
        
        optimizer.step()
```

### Mixed Precision Training

```python
from torch.cuda.amp import autocast, GradScaler

# Create gradient scaler
scaler = GradScaler()

for epoch in range(NumEpochs):
    for data, target in train_loader:
        data, target = data.to(device), target.to(device)
        
        optimizer.zero_grad()
        
        # Mixed precision forward pass
        with autocast():
            output = model(data)
            loss = criterion(output, target)
        
        # Scaled backward pass
        scaler.scale(loss).backward()
        scaler.step(optimizer)
        scaler.update()
```

## Data Loading and Preprocessing

### Dataset and DataLoader

```python
from torch.utils.data import Dataset, DataLoader

# Custom dataset
class CustomDataset(Dataset):
    def __init__(self, data, labels, transform=None):
        self.data = data
        self.labels = labels
        self.transform = transform
        
    def __len__(self):
        return len(self.data)
        
    def __getitem__(self, idx):
        sample = self.data[idx]
        label = self.labels[idx]
        
        if self.transform:
            sample = self.transform(sample)
            
        return sample, label

# Create dataset and dataloader
dataset = CustomDataset(data, labels)
dataloader = DataLoader(
    dataset,
    batch_size=32,
    shuffle=True,
    num_workers=4,
    pin_memory=True  # Faster GPU transfer
)

# Iterate through data
for batch_idx, (data, labels) in enumerate(dataloader):
    # Training code...
    pass
```

### Torchvision Datasets

```python
from torchvision import datasets, transforms

# Define transforms
transform = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

# Load popular datasets
train_dataset = datasets.CIFAR10(root='./data', train=True, download=True, transform=transform)
test_dataset = datasets.CIFAR10(root='./data', train=False, download=True, transform=transform)

# Other datasets
mnist = datasets.MNIST(root='./data', train=True, download=True, transform=transform)
fashion_mnist = datasets.FashionMNIST(root='./data', train=True, download=True, transform=transform)
imagenet = datasets.ImageNet(root='./data', split='train', transform=transform)
coco = datasets.CocoDetection(root='./data', annFile='annotations.json', transform=transform)
```

### Data Augmentation

```python
from torchvision import transforms

# Training augmentation
train_transform = transforms.Compose([
    transforms.RandomResizedCrop(224),
    transforms.RandomHorizontalFlip(),
    transforms.RandomRotation(15),
    transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2, hue=0.1),
    transforms.RandomAffine(degrees=0, translate=(0.1, 0.1)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    transforms.RandomErasing(p=0.5)
])

# Test augmentation (minimal)
test_transform = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

# Advanced augmentations
from torchvision.transforms import v2

augment = v2.Compose([
    v2.RandomResizedCrop(224),
    v2.RandomHorizontalFlip(p=0.5),
    v2.RandAugment(num_ops=2, magnitude=9),  # AutoAugment
    v2.ToTensor(),
    v2.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])
```

## Model Checkpointing and Saving

### Saving and Loading Models

```python
# Save entire model
torch.save(model, 'model_complete.pth')

# Load entire model
model = torch.load('model_complete.pth')
model.eval()

# Save model state dict (recommended)
torch.save(model.state_dict(), 'model_weights.pth')

# Load model state dict
model = SimpleNetwork(784, 128, 10)
model.load_state_dict(torch.load('model_weights.pth'))
model.eval()

# Save training checkpoint
checkpoint = {
    'epoch': epoch,
    'model_state_dict': model.state_dict(),
    'optimizer_state_dict': optimizer.state_dict(),
    'loss': loss,
    'accuracy': accuracy
}
torch.save(checkpoint, 'checkpoint.pth')

# Load checkpoint
checkpoint = torch.load('checkpoint.pth')
model.load_state_dict(checkpoint['model_state_dict'])
optimizer.load_state_dict(checkpoint['optimizer_state_dict'])
epoch = checkpoint['epoch']
loss = checkpoint['loss']
```

### Early Stopping

```python
class EarlyStopping:
    def __init__(self, patience=7, min_delta=0, verbose=False):
        self.patience = patience
        self.min_delta = min_delta
        self.verbose = verbose
        self.counter = 0
        self.best_loss = None
        self.early_stop = False
        
    def __call__(self, val_loss, model):
        if self.best_loss is None:
            self.best_loss = val_loss
            self.save_checkpoint(model)
        elif val_loss > self.best_loss - self.min_delta:
            self.counter += 1
            if self.verbose:
                print(f'EarlyStopping counter: {self.counter} out of {self.patience}')
            if self.counter >= self.patience:
                self.early_stop = True
        else:
            self.best_loss = val_loss
            self.save_checkpoint(model)
            self.counter = 0
            
    def save_checkpoint(self, model):
        torch.save(model.state_dict(), 'best_model.pth')

# Usage
early_stopping = EarlyStopping(patience=10, verbose=True)

for epoch in range(NumEpochs):
    # Training...
    val_loss = evaluate(model, val_loader, device)
    
    early_stopping(val_loss, model)
    if early_stopping.early_stop:
        print("Early stopping triggered")
        break
```

## Distributed Training

### DataParallel (Single Machine, Multiple GPUs)

```python
# Wrap model with DataParallel
if torch.cuda.device_count() > 1:
    print(f"Using {torch.cuda.device_count()} GPUs")
    model = nn.DataParallel(model)

model = model.to(device)

# Training code remains the same
```

### DistributedDataParallel (Multi-Machine)

```python
import torch.distributed as dist
from torch.nn.parallel import DistributedDataParallel as DDP
from torch.utils.data.distributed import DistributedSampler

def setup(rank, world_size):
    dist.init_process_group("nccl", rank=rank, world_size=world_size)

def cleanup():
    dist.destroy_process_group()

def train_ddp(rank, world_size):
    setup(rank, world_size)
    
    # Create model and move to GPU
    model = SimpleNetwork(784, 128, 10).to(rank)
    model = DDP(model, device_ids=[rank])
    
    # Create distributed sampler
    train_sampler = DistributedSampler(
        train_dataset,
        num_replicas=world_size,
        rank=rank
    )
    
    train_loader = DataLoader(
        train_dataset,
        batch_size=32,
        sampler=train_sampler
    )
    
    # Training loop
    for epoch in range(NumEpochs):
        train_sampler.set_epoch(epoch)
        for data, target in train_loader:
            # Training code...
            pass
    
    cleanup()

# Launch
if __name__ == '__main__':
    world_size = torch.cuda.device_count()
    torch.multiprocessing.spawn(
        train_ddp,
        args=(world_size,),
        nprocs=world_size,
        join=True
    )
```

## Transfer Learning and Pre-trained Models

### Using Pre-trained Models

```python
from torchvision import models

# Load pre-trained ResNet
model = models.resnet50(pretrained=True)

# Freeze all layers
for param in model.parameters():
    param.requires_grad = False

# Replace final layer for your task
num_features = model.fc.in_features
model.fc = nn.Linear(num_features, NumClasses)

# Only train final layer
optimizer = optim.Adam(model.fc.parameters(), lr=0.001)
```

### Fine-tuning Pre-trained Models

```python
# Load pre-trained model
model = models.resnet50(pretrained=True)

# Freeze early layers
for name, param in model.named_parameters():
    if "layer4" not in name and "fc" not in name:
        param.requires_grad = False

# Replace classifier
num_features = model.fc.in_features
model.fc = nn.Linear(num_features, NumClasses)

# Different learning rates for different parts
optimizer = optim.Adam([
    {'params': model.layer4.parameters(), 'lr': 1e-4},
    {'params': model.fc.parameters(), 'lr': 1e-3}
])
```

### Available Pre-trained Models

```python
# Image classification
resnet = models.resnet50(pretrained=True)
vgg = models.vgg16(pretrained=True)
densenet = models.densenet121(pretrained=True)
mobilenet = models.mobilenet_v2(pretrained=True)
efficientnet = models.efficientnet_b0(pretrained=True)
vit = models.vit_b_16(pretrained=True)  # Vision Transformer
swin = models.swin_t(pretrained=True)   # Swin Transformer

# Object detection
faster_rcnn = models.detection.fasterrcnn_resnet50_fpn(pretrained=True)
mask_rcnn = models.detection.maskrcnn_resnet50_fpn(pretrained=True)
retinanet = models.detection.retinanet_resnet50_fpn(pretrained=True)

# Semantic segmentation
fcn = models.segmentation.fcn_resnet50(pretrained=True)
deeplabv3 = models.segmentation.deeplabv3_resnet50(pretrained=True)
```

## Model Deployment

### TorchScript (Production Deployment)

```python
# Tracing (for models without control flow)
model.eval()
example_input = torch.randn(1, 3, 224, 224)
traced_model = torch.jit.trace(model, example_input)
traced_model.save('model_traced.pt')

# Scripting (for models with control flow)
scripted_model = torch.jit.script(model)
scripted_model.save('model_scripted.pt')

# Load and use
loaded_model = torch.jit.load('model_traced.pt')
output = loaded_model(example_input)
```

### ONNX Export

```python
import torch.onnx

# Export to ONNX
model.eval()
dummy_input = torch.randn(1, 3, 224, 224)

torch.onnx.export(
    model,
    dummy_input,
    "model.onnx",
    export_params=True,
    opset_version=11,
    do_constant_folding=True,
    input_names=['input'],
    output_names=['output'],
    dynamic_axes={'input': {0: 'batch_size'}, 'output': {0: 'batch_size'}}
)
```

### TorchServe (Model Serving)

```bash
# Install TorchServe
pip install torchserve torch-model-archiver

# Archive model
torch-model-archiver \
    --model-name my_model \
    --version 1.0 \
    --model-file model.py \
    --serialized-file model.pth \
    --handler image_classifier

# Start server
torchserve --start --model-store model_store --models my_model=my_model.mar

# Make predictions
curl http://localhost:8080/predictions/my_model -T image.jpg
```

## Best Practices

### Reproducibility

```python
import random
import numpy as np

def set_seed(seed=42):
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False

set_seed(42)
```

### Memory Management

```python
# Clear cache
torch.cuda.empty_cache()

# Delete large tensors
del large_tensor
torch.cuda.empty_cache()

# Use gradient checkpointing (trade compute for memory)
from torch.utils.checkpoint import checkpoint

def custom_forward(module):
    def forward(*inputs):
        return checkpoint(module, *inputs)
    return forward

# Monitor memory
print(torch.cuda.memory_allocated() / 1024**2)  # MB
print(torch.cuda.memory_reserved() / 1024**2)   # MB
print(torch.cuda.max_memory_allocated() / 1024**2)
```

### Debugging

```python
# Check for NaN/Inf
torch.autograd.set_detect_anomaly(True)

# Print model architecture
print(model)

# Count parameters
total_params = sum(p.numel() for p in model.parameters())
trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
print(f"Total parameters: {total_params:,}")
print(f"Trainable parameters: {trainable_params:,}")

# Hook for debugging gradients
def print_grad(grad):
    print(f"Gradient: {grad}")

# Register hook
handle = tensor.register_hook(print_grad)
```

### Performance Optimization

```python
# Enable cuDNN autotuner
torch.backends.cudnn.benchmark = True

# Use pin_memory for faster data transfer
train_loader = DataLoader(dataset, batch_size=32, pin_memory=True, num_workers=4)

# Prefetch data to GPU
for data, target in train_loader:
    data, target = data.to(device, non_blocking=True), target.to(device, non_blocking=True)

# Use appropriate data types
model = model.half()  # Use FP16 for faster inference

# Fuse operations
model = torch.jit.optimize_for_inference(torch.jit.script(model))
```

## Advanced Topics

### Custom CUDA Kernels

```python
from torch.utils.cpp_extension import load

# Load custom CUDA kernel
custom_kernel = load(
    name="custom_kernel",
    sources=["custom_kernel.cpp", "custom_kernel.cu"],
    verbose=True
)

# Use in forward pass
output = custom_kernel.forward(input)
```

### Quantization

```python
# Dynamic quantization (post-training)
quantized_model = torch.quantization.quantize_dynamic(
    model,
    {nn.Linear, nn.Conv2d},
    dtype=torch.qint8
)

# Static quantization
model.qconfig = torch.quantization.get_default_qconfig('fbgemm')
torch.quantization.prepare(model, inplace=True)

# Calibrate with representative data
with torch.no_grad():
    for data, _ in calibration_loader:
        model(data)

torch.quantization.convert(model, inplace=True)

# Quantization-aware training
model.qconfig = torch.quantization.get_default_qat_qconfig('fbgemm')
torch.quantization.prepare_qat(model, inplace=True)

# Train with fake quantization
for epoch in range(NumEpochs):
    # Training loop...
    pass

torch.quantization.convert(model, inplace=True)
```

### Pruning

```python
import torch.nn.utils.prune as prune

# Prune 30% of connections in a layer
prune.l1_unstructured(model.fc1, name='weight', amount=0.3)

# Global pruning across multiple layers
parameters_to_prune = (
    (model.fc1, 'weight'),
    (model.fc2, 'weight'),
)
prune.global_unstructured(
    parameters_to_prune,
    pruning_method=prune.L1Unstructured,
    amount=0.3,
)

# Remove pruning reparameterization
prune.remove(model.fc1, 'weight')
```

### Knowledge Distillation

```python
def distillation_loss(student_logits, teacher_logits, labels, temperature=3.0, alpha=0.5):
    # Soft targets from teacher
    soft_targets = F.softmax(teacher_logits / temperature, dim=1)
    soft_student = F.log_softmax(student_logits / temperature, dim=1)
    
    # KL divergence loss
    distillation_loss = F.kl_div(soft_student, soft_targets, reduction='batchmean') * (temperature ** 2)
    
    # Student loss on hard labels
    student_loss = F.cross_entropy(student_logits, labels)
    
    # Combined loss
    return alpha * distillation_loss + (1 - alpha) * student_loss

# Training with distillation
teacher_model.eval()
student_model.train()

for data, labels in train_loader:
    optimizer.zero_grad()
    
    with torch.no_grad():
        teacher_logits = teacher_model(data)
    
    student_logits = student_model(data)
    loss = distillation_loss(student_logits, teacher_logits, labels)
    
    loss.backward()
    optimizer.step()
```

## Common Pitfalls and Solutions

### Issue: Out of Memory (OOM)

```python
# Solution 1: Reduce batch size
train_loader = DataLoader(dataset, batch_size=16)  # Instead of 32

# Solution 2: Gradient accumulation
accumulation_steps = 4
for i, (data, target) in enumerate(train_loader):
    output = model(data)
    loss = criterion(output, target) / accumulation_steps
    loss.backward()
    
    if (i + 1) % accumulation_steps == 0:
        optimizer.step()
        optimizer.zero_grad()

# Solution 3: Use gradient checkpointing
from torch.utils.checkpoint import checkpoint_sequential
output = checkpoint_sequential(model, chunks=4, input=data)
```

### Issue: Training is Too Slow

```python
# Solution 1: Use DataLoader with multiple workers
train_loader = DataLoader(dataset, batch_size=32, num_workers=4, pin_memory=True)

# Solution 2: Mixed precision training
from torch.cuda.amp import autocast, GradScaler
scaler = GradScaler()

# Solution 3: Profile code
from torch.profiler import profile, record_function, ProfilerActivity

with profile(activities=[ProfilerActivity.CPU, ProfilerActivity.CUDA]) as prof:
    for data, target in train_loader:
        output = model(data)
        loss = criterion(output, target)
        loss.backward()
        optimizer.step()

print(prof.key_averages().table(sort_by="cuda_time_total", row_limit=10))
```

### Issue: Model Not Learning

```python
# Check 1: Verify gradients are flowing
for name, param in model.named_parameters():
    if param.grad is not None:
        print(f"{name}: grad norm = {param.grad.norm()}")

# Check 2: Learning rate too high or low
# Try different learning rates: 1e-2, 1e-3, 1e-4

# Check 3: Verify loss is decreasing
# Log loss at every iteration

# Check 4: Check data normalization
mean = train_dataset.data.mean()
std = train_dataset.data.std()
print(f"Data mean: {mean}, std: {std}")
```

## Performance Benchmarks

### Training Speed Comparison

| Framework | ResNet-50 (ImageNet) | Throughput (imgs/sec) | Relative Speed |
| --- | --- | --- | --- |
| PyTorch 2.0 | Eager Mode | 350 | 1.0x |
| PyTorch 2.0 | torch.compile | 520 | **1.5x** |
| PyTorch 2.0 | Mixed Precision | 680 | **1.9x** |
| PyTorch 2.0 | DDP (4 GPUs) | 1400 | **4.0x** |

### Memory Efficiency

| Technique | Memory Usage | Speed Impact |
| --- | --- | --- |
| Baseline (FP32) | 100% | 1.0x |
| Mixed Precision (FP16) | 50% | 1.8x faster |
| Gradient Checkpointing | 40% | 0.8x slower |
| 8-bit Quantization | 25% | 2.5x faster (inference) |

## PyTorch 2.0 Features

### torch.compile

```python
# Compile model for faster execution
model = torch.compile(model)

# Different modes
model = torch.compile(model, mode="reduce-overhead")  # Best for small models
model = torch.compile(model, mode="max-autotune")     # Best for large models
model = torch.compile(model, mode="default")          # Balanced

# Selective compilation
@torch.compile
def custom_function(x, y):
    return x @ y + y
```

### Nested Tensors

```python
# Handle sequences of different lengths efficiently
sequences = [
    torch.randn(10, 128),
    torch.randn(15, 128),
    torch.randn(8, 128)
]

# Create nested tensor (no padding needed)
nested = torch.nested.nested_tensor(sequences)
```

## See Also

- [PyTorch Official Documentation](https://pytorch.org/docs/stable/index.html)
- [PyTorch Tutorials](https://pytorch.org/tutorials/)
- [PyTorch Examples](https://github.com/pytorch/examples)
- [PyTorch Forums](https://discuss.pytorch.org/)
- [Deep Learning with PyTorch Book](https://pytorch.org/assets/deep-learning/Deep-Learning-with-PyTorch.pdf)
- [TensorFlow vs PyTorch Comparison](tensorflow.md)
- [Machine Learning Overview](index.md)
- [Neural Network Architectures](../algorithms/neural-networks.md)

## Additional Resources

### Official Resources

- [PyTorch GitHub Repository](https://github.com/pytorch/pytorch)
- [PyTorch Blog](https://pytorch.org/blog/)
- [PyTorch Lightning](https://lightning.ai/) - High-level framework
- [Hugging Face Transformers](https://huggingface.co/docs/transformers/) - Pre-trained models
- [MMDetection](https://github.com/open-mmlab/mmdetection) - Object detection toolbox
- [Detectron2](https://github.com/facebookresearch/detectron2) - Facebook's detection library

### Learning Resources

- [Deep Learning Specialization](https://www.coursera.org/specializations/deep-learning)
- [Fast.ai Practical Deep Learning](https://course.fast.ai/)
- [PyTorch Deep Learning Course](https://github.com/mrdbourke/pytorch-deep-learning)
- [Papers With Code](https://paperswithcode.com/lib/pytorch)

### Community

- [PyTorch Discord](https://discord.gg/pytorch)
- [PyTorch Forums](https://discuss.pytorch.org/)
- [PyTorch YouTube Channel](https://www.youtube.com/c/PyTorch)
- [r/PyTorch Subreddit](https://www.reddit.com/r/PyTorch/)

### Related Tools

- [TorchVision](https://pytorch.org/vision/stable/index.html) - Computer vision datasets and models
- [TorchText](https://pytorch.org/text/stable/index.html) - NLP datasets and utilities
- [TorchAudio](https://pytorch.org/audio/stable/index.html) - Audio processing
- [TorchServe](https://pytorch.org/serve/) - Model serving in production
- [PyTorch Geometric](https://pytorch-geometric.readthedocs.io/) - Graph neural networks
- [Captum](https://captum.ai/) - Model interpretability
