---
title: NumPy - Scientific Computing in Python
description: Comprehensive guide to NumPy, the fundamental package for scientific computing and numerical operations in Python
keywords: numpy, python, scientific computing, arrays, linear algebra, numerical computing, data science
author: Joseph Streeter
ms.author: joseph.streeter
ms.date: 01/04/2026
ms.topic: conceptual
---

NumPy (Numerical Python) is the fundamental package for scientific computing in Python. It provides support for large, multi-dimensional arrays and matrices, along with a comprehensive collection of high-level mathematical functions to operate on these arrays efficiently.

## Overview

NumPy is the foundation of the Python scientific computing ecosystem. It offers:

- **N-dimensional array object (ndarray)**: Fast and versatile array structure
- **Broadcasting functions**: Perform operations on arrays of different shapes
- **Linear algebra operations**: Matrix operations, decompositions, eigenvalues
- **Random number generation**: Comprehensive suite of random sampling functions
- **Integration with C/C++/Fortran**: Ability to wrap compiled code
- **Memory efficiency**: Optimized data storage and computation

NumPy arrays are faster and more memory-efficient than Python lists, making them ideal for numerical computations and data analysis tasks.

## Installation

Install NumPy using pip:

```bash
pip install numpy
```

For scientific computing environments, consider installing via Anaconda:

```bash
conda install numpy
```

Verify installation:

```python
import numpy as np
print(np.__version__)
```

## Array Creation

### Creating Basic Arrays

NumPy provides multiple ways to create arrays:

```python
import numpy as np

# From Python list
arr1 = np.array([1, 2, 3, 4, 5])
print(arr1)  # [1 2 3 4 5]

# 2D array from nested lists
arr2 = np.array([[1, 2, 3], [4, 5, 6]])
print(arr2)
# [[1 2 3]
#  [4 5 6]]

# Specify data type
arr3 = np.array([1, 2, 3], dtype=np.float64)
print(arr3)  # [1. 2. 3.]

# Complex numbers
arr4 = np.array([1+2j, 3+4j])
print(arr4)  # [1.+2.j 3.+4.j]
```

### Array Initialization Functions

```python
# Array of zeros
zeros = np.zeros((3, 4))  # 3x4 array of zeros

# Array of ones
ones = np.ones((2, 3, 4))  # 3D array of ones

# Empty array (uninitialized)
empty = np.empty((2, 2))

# Array with constant value
full = np.full((3, 3), 7)  # 3x3 array filled with 7

# Identity matrix
identity = np.eye(4)  # 4x4 identity matrix

# Array from range
arange_arr = np.arange(0, 10, 2)  # [0 2 4 6 8]

# Evenly spaced values
linspace_arr = np.linspace(0, 1, 5)  # [0. 0.25 0.5 0.75 1.]

# Logarithmically spaced values
logspace_arr = np.logspace(0, 2, 5)  # [1. 3.16 10. 31.62 100.]
```

### Creating Arrays Like Existing Arrays

```python
x = np.array([[1, 2], [3, 4]])

# Create zeros with same shape
zeros_like = np.zeros_like(x)

# Create ones with same shape
ones_like = np.ones_like(x)

# Create empty with same shape
empty_like = np.empty_like(x)
```

## Array Properties and Attributes

Understanding array properties is essential for effective NumPy usage:

```python
arr = np.array([[1, 2, 3, 4], [5, 6, 7, 8]])

# Shape - dimensions of array
print(arr.shape)  # (2, 4)

# Number of dimensions
print(arr.ndim)  # 2

# Total number of elements
print(arr.size)  # 8

# Data type of elements
print(arr.dtype)  # int64

# Size of each element in bytes
print(arr.itemsize)  # 8

# Total bytes consumed
print(arr.nbytes)  # 64

# Transpose
print(arr.T)
# [[1 5]
#  [2 6]
#  [3 7]
#  [4 8]]
```

## Array Indexing and Slicing

### Basic Indexing

```python
arr = np.array([10, 20, 30, 40, 50])

# Single element access
print(arr[0])  # 10
print(arr[-1])  # 50 (last element)

# Slicing [start:stop:step]
print(arr[1:4])  # [20 30 40]
print(arr[::2])  # [10 30 50] (every other element)
print(arr[::-1])  # [50 40 30 20 10] (reverse)
```

### Multi-dimensional Indexing

```python
arr2d = np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9]])

# Access element at row 1, column 2
print(arr2d[1, 2])  # 6

# Row slicing
print(arr2d[0, :])  # [1 2 3] (first row)

# Column slicing
print(arr2d[:, 1])  # [2 5 8] (second column)

# Subarray
print(arr2d[0:2, 1:3])
# [[2 3]
#  [5 6]]
```

### Boolean Indexing

```python
arr = np.array([1, 2, 3, 4, 5, 6])

# Boolean mask
mask = arr > 3
print(mask)  # [False False False True True True]

# Filter using mask
filtered = arr[mask]
print(filtered)  # [4 5 6]

# Inline filtering
print(arr[arr % 2 == 0])  # [2 4 6] (even numbers)

# Modify elements using boolean indexing
arr[arr > 3] = 0
print(arr)  # [1 2 3 0 0 0]
```

### Fancy Indexing

```python
arr = np.array([10, 20, 30, 40, 50])

# Index with array of integers
indices = np.array([0, 2, 4])
print(arr[indices])  # [10 30 50]

# 2D fancy indexing
arr2d = np.arange(12).reshape(3, 4)
rows = np.array([0, 2])
cols = np.array([1, 3])
print(arr2d[rows, cols])  # [1 11]
```

## Array Operations

### Arithmetic Operations

```python
a = np.array([1, 2, 3, 4])
b = np.array([10, 20, 30, 40])

# Element-wise operations
print(a + b)  # [11 22 33 44]
print(a - b)  # [-9 -18 -27 -36]
print(a * b)  # [10 40 90 160]
print(a / b)  # [0.1 0.1 0.1 0.1]
print(a ** 2)  # [1 4 9 16]

# Operations with scalars (broadcasting)
print(a + 10)  # [11 12 13 14]
print(a * 2)  # [2 4 6 8]
```

### Comparison Operations

```python
a = np.array([1, 2, 3, 4, 5])

print(a > 3)  # [False False False True True]
print(a == 3)  # [False False True False False]
print(a <= 2)  # [True True False False False]

# Compare arrays
b = np.array([5, 4, 3, 2, 1])
print(a < b)  # [True True False False False]
```

### Universal Functions (ufuncs)

```python
arr = np.array([1, 4, 9, 16, 25])

# Mathematical functions
print(np.sqrt(arr))  # [1. 2. 3. 4. 5.]
print(np.exp(arr))  # Exponential
print(np.log(arr))  # Natural logarithm
print(np.log10(arr))  # Base-10 logarithm

# Trigonometric functions
angles = np.array([0, np.pi/2, np.pi])
print(np.sin(angles))  # [0. 1. 0.]
print(np.cos(angles))  # [1. 0. -1.]
print(np.tan(angles))  # Tangent values

# Rounding functions
arr_float = np.array([1.23, 4.56, 7.89])
print(np.round(arr_float))  # [1. 5. 8.]
print(np.floor(arr_float))  # [1. 4. 7.]
print(np.ceil(arr_float))  # [2. 5. 8.]
```

## Broadcasting

Broadcasting allows NumPy to perform operations on arrays of different shapes:

```python
# 1D array + scalar
a = np.array([1, 2, 3])
print(a + 5)  # [6 7 8]

# 2D array + 1D array
matrix = np.array([[1, 2, 3], [4, 5, 6]])
vector = np.array([10, 20, 30])
print(matrix + vector)
# [[11 22 33]
#  [14 25 36]]

# 2D array + column vector
matrix = np.array([[1, 2, 3], [4, 5, 6]])
col_vector = np.array([[10], [20]])
print(matrix + col_vector)
# [[11 12 13]
#  [24 25 26]]

# Broadcasting rules example
a = np.arange(3).reshape(3, 1)  # Shape (3, 1)
b = np.arange(3)  # Shape (3,)
print(a + b)
# [[0 1 2]
#  [1 2 3]
#  [2 3 4]]
```

### Broadcasting Rules

1. If arrays don't have the same rank, prepend shape of lower rank array with 1s
2. Arrays are compatible when dimensions are equal or one of them is 1
3. After broadcasting, each array behaves as if it had shape equal to element-wise maximum

## Array Manipulation

### Reshaping

```python
arr = np.arange(12)

# Reshape to 2D
reshaped = arr.reshape(3, 4)
print(reshaped)
# [[ 0  1  2  3]
#  [ 4  5  6  7]
#  [ 8  9 10 11]]

# Reshape to 3D
reshaped_3d = arr.reshape(2, 3, 2)

# Flatten array
flattened = reshaped.flatten()  # Copy
raveled = reshaped.ravel()  # View (no copy)

# Auto-calculate dimension
auto_reshape = arr.reshape(3, -1)  # -1 means "figure it out"
```

### Transposing and Swapping Axes

```python
arr = np.arange(12).reshape(3, 4)

# Transpose
transposed = arr.T
print(transposed.shape)  # (4, 3)

# Swap axes
arr3d = np.arange(24).reshape(2, 3, 4)
swapped = arr3d.swapaxes(1, 2)  # Swap axes 1 and 2
print(swapped.shape)  # (2, 4, 3)

# Transpose with axes specification
transposed_3d = arr3d.transpose(2, 1, 0)
print(transposed_3d.shape)  # (4, 3, 2)
```

### Stacking and Splitting

```python
a = np.array([[1, 2], [3, 4]])
b = np.array([[5, 6], [7, 8]])

# Vertical stack (row-wise)
v_stack = np.vstack((a, b))
# [[1 2]
#  [3 4]
#  [5 6]
#  [7 8]]

# Horizontal stack (column-wise)
h_stack = np.hstack((a, b))
# [[1 2 5 6]
#  [3 4 7 8]]

# Concatenate along axis
concat = np.concatenate((a, b), axis=0)  # Same as vstack

# Split array
arr = np.arange(9)
split1, split2, split3 = np.split(arr, 3)
print(split1)  # [0 1 2]

# Split 2D array
arr2d = np.arange(16).reshape(4, 4)
upper, lower = np.vsplit(arr2d, 2)
left, right = np.hsplit(arr2d, 2)
```

### Adding and Removing Elements

```python
arr = np.array([1, 2, 3, 4, 5])

# Append
appended = np.append(arr, [6, 7])
print(appended)  # [1 2 3 4 5 6 7]

# Insert
inserted = np.insert(arr, 2, 99)
print(inserted)  # [1 2 99 3 4 5]

# Delete
deleted = np.delete(arr, [1, 3])
print(deleted)  # [1 3 5]

# Unique values
arr_dup = np.array([1, 2, 2, 3, 3, 3, 4])
unique = np.unique(arr_dup)
print(unique)  # [1 2 3 4]

# Unique with counts
unique, counts = np.unique(arr_dup, return_counts=True)
print(counts)  # [1 2 3 1]
```

## Aggregation Functions

### Statistical Functions

```python
arr = np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9]])

# Sum
print(np.sum(arr))  # 45
print(arr.sum(axis=0))  # [12 15 18] (column sums)
print(arr.sum(axis=1))  # [6 15 24] (row sums)

# Mean
print(np.mean(arr))  # 5.0
print(arr.mean(axis=0))  # [4. 5. 6.]

# Median
print(np.median(arr))  # 5.0

# Standard deviation and variance
print(np.std(arr))  # Standard deviation
print(np.var(arr))  # Variance

# Min and max
print(np.min(arr))  # 1
print(np.max(arr))  # 9
print(arr.min(axis=1))  # [1 4 7]

# Argmin and argmax (indices)
print(np.argmin(arr))  # 0 (flattened index)
print(np.argmax(arr, axis=0))  # [2 2 2]

# Cumulative sum and product
print(np.cumsum([1, 2, 3, 4]))  # [1 3 6 10]
print(np.cumprod([1, 2, 3, 4]))  # [1 2 6 24]

# Percentiles
print(np.percentile(arr, 50))  # 5.0 (median)
print(np.percentile(arr, [25, 50, 75]))  # [3. 5. 7.]
```

### Logical Operations

```python
a = np.array([True, False, True, False])
b = np.array([True, True, False, False])

# Logical AND, OR, NOT, XOR
print(np.logical_and(a, b))  # [True False False False]
print(np.logical_or(a, b))  # [True True True False]
print(np.logical_not(a))  # [False True False True]
print(np.logical_xor(a, b))  # [False True True False]

# Any and all
arr = np.array([1, 2, 0, 4])
print(np.any(arr > 3))  # True
print(np.all(arr > 0))  # False
```

## Linear Algebra

NumPy provides comprehensive linear algebra operations through `numpy.linalg`:

### Matrix Operations

```python
A = np.array([[1, 2], [3, 4]])
B = np.array([[5, 6], [7, 8]])

# Matrix multiplication
C = np.dot(A, B)
# or
C = A @ B
print(C)
# [[19 22]
#  [43 50]]

# Element-wise multiplication
element_wise = A * B
# [[5 12]
#  [21 32]]

# Matrix power
print(np.linalg.matrix_power(A, 3))  # A^3

# Transpose
print(A.T)

# Trace (sum of diagonal)
print(np.trace(A))  # 5

# Diagonal elements
print(np.diag(A))  # [1 4]

# Create diagonal matrix
print(np.diag([1, 2, 3]))
# [[1 0 0]
#  [0 2 0]
#  [0 0 3]]
```

### Matrix Decompositions

```python
A = np.array([[1, 2], [3, 4], [5, 6]])

# Singular Value Decomposition (SVD)
U, s, Vt = np.linalg.svd(A)
print(f"U shape: {U.shape}, s shape: {s.shape}, Vt shape: {Vt.shape}")

# QR Decomposition
Q, R = np.linalg.qr(A)

# Eigenvalues and eigenvectors
A_square = np.array([[1, 2], [2, 1]])
eigenvalues, eigenvectors = np.linalg.eig(A_square)
print(f"Eigenvalues: {eigenvalues}")
print(f"Eigenvectors:\n{eigenvectors}")

# Cholesky decomposition (for positive definite matrices)
pos_def = np.array([[4, 2], [2, 3]])
L = np.linalg.cholesky(pos_def)
```

### Matrix Properties

```python
A = np.array([[1, 2], [3, 4]])

# Determinant
det = np.linalg.det(A)
print(f"Determinant: {det}")  # -2.0

# Inverse
try:
    A_inv = np.linalg.inv(A)
    print(f"Inverse:\n{A_inv}")
    
    # Verify: A @ A_inv should equal identity
    print(np.allclose(A @ A_inv, np.eye(2)))  # True
except np.linalg.LinAlgError:
    print("Matrix is singular")

# Rank
rank = np.linalg.matrix_rank(A)
print(f"Rank: {rank}")

# Norm
norm_fro = np.linalg.norm(A, 'fro')  # Frobenius norm
norm_2 = np.linalg.norm(A, 2)  # Spectral norm
print(f"Frobenius norm: {norm_fro}")
```

### Solving Linear Systems

```python
# Solve Ax = b
A = np.array([[3, 1], [1, 2]])
b = np.array([9, 8])

x = np.linalg.solve(A, b)
print(f"Solution: {x}")  # [2. 3.]

# Verify solution
print(np.allclose(A @ x, b))  # True

# Least squares solution (overdetermined system)
A = np.array([[1, 0], [1, 1], [1, 2]])
b = np.array([0, 1, 2])

x, residuals, rank, s = np.linalg.lstsq(A, b, rcond=None)
print(f"Least squares solution: {x}")
```

## Random Number Generation

NumPy provides powerful random number generation capabilities:

### Basic Random Generation

```python
# Legacy random (still widely used)
np.random.seed(42)  # For reproducibility

# Random floats in [0, 1)
random_floats = np.random.random(5)
print(random_floats)

# Random integers
random_ints = np.random.randint(0, 10, size=5)
print(random_ints)

# Random choice from array
choices = np.random.choice(['a', 'b', 'c'], size=10)
print(choices)

# Random permutation
arr = np.arange(10)
np.random.shuffle(arr)  # In-place
print(arr)

permuted = np.random.permutation(10)  # Returns new array
print(permuted)
```

### New Random Generator API (Recommended)

```python
# Create a random generator
rng = np.random.default_rng(seed=42)

# Random floats
random_floats = rng.random(5)

# Random integers
random_ints = rng.integers(0, 10, size=5)

# Random choice
choices = rng.choice(['a', 'b', 'c'], size=10)

# Random permutation
permuted = rng.permutation(10)
```

### Probability Distributions

```python
rng = np.random.default_rng(seed=42)

# Normal (Gaussian) distribution
normal = rng.normal(loc=0, scale=1, size=1000)  # mean=0, std=1

# Uniform distribution
uniform = rng.uniform(low=0, high=1, size=1000)

# Binomial distribution
binomial = rng.binomial(n=10, p=0.5, size=1000)

# Poisson distribution
poisson = rng.poisson(lam=5, size=1000)

# Exponential distribution
exponential = rng.exponential(scale=1.0, size=1000)

# Beta distribution
beta = rng.beta(a=2, b=5, size=1000)

# Gamma distribution
gamma = rng.gamma(shape=2, scale=1, size=1000)

# Chi-square distribution
chisquare = rng.chisquare(df=2, size=1000)

# Multivariate normal
mean = [0, 0]
cov = [[1, 0.5], [0.5, 1]]
multivariate = rng.multivariate_normal(mean, cov, size=100)
```

## Advanced Topics

### Memory Views and Copies

```python
# View vs. copy
original = np.arange(10)

# View (shares memory)
view = original[::2]
view[0] = 999
print(original)  # [999 1 2 3 4 5 6 7 8 9] - original changed!

# Copy (independent)
original = np.arange(10)
copy = original[::2].copy()
copy[0] = 999
print(original)  # [0 1 2 3 4 5 6 7 8 9] - original unchanged

# Check if array owns its data
print(original.flags['OWNDATA'])  # True
print(view.flags['OWNDATA'])  # False
```

### Structured Arrays

```python
# Define structured data type
dt = np.dtype([('name', 'U10'), ('age', 'i4'), ('weight', 'f8')])

# Create structured array
people = np.array([
    ('Alice', 25, 55.5),
    ('Bob', 30, 75.0),
    ('Charlie', 35, 80.2)
], dtype=dt)

# Access fields
print(people['name'])  # ['Alice' 'Bob' 'Charlie']
print(people['age'])  # [25 30 35]

# Access individual record
print(people[0])  # ('Alice', 25, 55.5)
print(people[0]['name'])  # Alice
```

### Masked Arrays

```python
# Create masked array with invalid values
data = np.array([1, 2, -999, 4, 5, -999])
masked = np.ma.masked_equal(data, -999)

print(masked)  # [1 2 -- 4 5 --]
print(masked.mean())  # 3.0 (ignores masked values)

# Create mask manually
mask = np.array([False, False, True, False, False, True])
masked2 = np.ma.array(data, mask=mask)
```

### Advanced Indexing with np.where

```python
arr = np.array([1, 2, 3, 4, 5, 6])

# Find indices where condition is true
indices = np.where(arr > 3)
print(indices)  # (array([3, 4, 5]),)

# Conditional replacement
result = np.where(arr > 3, arr * 2, arr)
print(result)  # [1 2 3 8 10 12]

# Multiple conditions
result = np.where((arr > 2) & (arr < 5), arr * 2, arr)
print(result)  # [1 2 6 8 5 6]
```

### Performance Optimization

```python
# Use vectorized operations instead of loops
import time

# Slow: Python loop
n = 1000000
arr = np.arange(n)
start = time.time()
result = []
for x in arr:
    result.append(x ** 2)
loop_time = time.time() - start

# Fast: NumPy vectorization
start = time.time()
result = arr ** 2
vectorized_time = time.time() - start

print(f"Loop: {loop_time:.4f}s, Vectorized: {vectorized_time:.4f}s")
print(f"Speedup: {loop_time / vectorized_time:.1f}x")

# Use in-place operations when possible
arr = np.arange(1000000)
arr += 1  # In-place (faster)
# vs
arr = arr + 1  # Creates new array (slower)

# Use appropriate data types
arr_float64 = np.arange(1000000, dtype=np.float64)  # 8 bytes per element
arr_float32 = np.arange(1000000, dtype=np.float32)  # 4 bytes per element
print(f"float64: {arr_float64.nbytes / 1e6:.1f} MB")
print(f"float32: {arr_float32.nbytes / 1e6:.1f} MB")
```

## Working with Files

### Saving and Loading Arrays

```python
# Save single array
arr = np.array([1, 2, 3, 4, 5])
np.save('array.npy', arr)

# Load single array
loaded = np.load('array.npy')

# Save multiple arrays
arr1 = np.array([1, 2, 3])
arr2 = np.array([4, 5, 6])
np.savez('arrays.npz', a=arr1, b=arr2)

# Load multiple arrays
loaded = np.load('arrays.npz')
print(loaded['a'])
print(loaded['b'])

# Compressed save (for large arrays)
np.savez_compressed('compressed.npz', a=arr1, b=arr2)
```

### Text File I/O

```python
# Save to text file
arr = np.array([[1, 2, 3], [4, 5, 6]])
np.savetxt('data.txt', arr, delimiter=',', fmt='%d')

# Load from text file
loaded = np.loadtxt('data.txt', delimiter=',')

# Load CSV with header
# data.csv:
# x,y,z
# 1,2,3
# 4,5,6
data = np.genfromtxt('data.csv', delimiter=',', names=True)
print(data['x'])  # [1. 4.]
```

## Common Use Cases and Patterns

### Image Processing Basics

```python
# Represent image as NumPy array
# Grayscale image: 2D array (height, width)
# Color image: 3D array (height, width, channels)

height, width = 100, 100
grayscale_image = np.random.randint(0, 256, (height, width), dtype=np.uint8)
color_image = np.random.randint(0, 256, (height, width, 3), dtype=np.uint8)

# Image operations
flipped = np.flipud(grayscale_image)  # Flip vertically
rotated = np.rot90(grayscale_image)  # Rotate 90 degrees
cropped = grayscale_image[10:50, 10:50]  # Crop region

# Normalize pixel values
normalized = grayscale_image / 255.0
```

### Time Series and Signal Processing

```python
# Generate time series
t = np.linspace(0, 1, 1000)
signal = np.sin(2 * np.pi * 5 * t) + 0.5 * np.sin(2 * np.pi * 10 * t)

# Add noise
noise = 0.2 * np.random.randn(len(t))
noisy_signal = signal + noise

# Moving average (simple smoothing)
window_size = 10
smoothed = np.convolve(noisy_signal, np.ones(window_size)/window_size, mode='valid')

# Calculate differences (derivatives)
diff = np.diff(signal)

# Calculate cumulative sum (integration)
cumsum = np.cumsum(signal)
```

### Data Normalization

```python
data = np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9]], dtype=float)

# Min-Max normalization (scale to [0, 1])
min_val = data.min()
max_val = data.max()
normalized = (data - min_val) / (max_val - min_val)

# Z-score normalization (standardization)
mean = data.mean()
std = data.std()
standardized = (data - mean) / std

# Column-wise normalization
col_min = data.min(axis=0)
col_max = data.max(axis=0)
col_normalized = (data - col_min) / (col_max - col_min)
```

## Best Practices

### Performance Tips

1. **Vectorize operations**: Avoid Python loops, use NumPy operations
2. **Use appropriate data types**: Choose smallest type that fits your data
3. **Avoid unnecessary copies**: Use views when possible
4. **Use in-place operations**: `arr += 1` instead of `arr = arr + 1`
5. **Preallocate arrays**: Create array with final size instead of appending
6. **Use built-in functions**: NumPy's C implementations are much faster

```python
# Bad: Growing array
result = np.array([])
for i in range(1000):
    result = np.append(result, i)

# Good: Preallocate
result = np.empty(1000)
for i in range(1000):
    result[i] = i

# Better: Vectorize
result = np.arange(1000)
```

### Memory Management

```python
# Check memory usage
arr = np.arange(1000000)
print(f"Memory: {arr.nbytes / 1e6:.2f} MB")

# Delete large arrays when done
del arr

# Use memory mapping for huge arrays
mmap_arr = np.memmap('large_array.dat', dtype='float32', mode='w+', shape=(1000000,))
mmap_arr[:] = np.arange(1000000)
del mmap_arr  # Flush to disk
```

### Code Style

```python
# Import convention
import numpy as np

# Prefer built-in methods
arr.sum()  # Good
np.sum(arr)  # Also fine

# Use axis parameter for clarity
arr.mean(axis=0)  # Column means
arr.mean(axis=1)  # Row means

# Chain operations for readability
result = (arr
    .reshape(10, -1)
    .mean(axis=1)
    .round(2))
```

## Common Pitfalls and Solutions

### Pitfall 1: View vs Copy Confusion

```python
# Problem
arr = np.arange(10)
subset = arr[::2]
subset[0] = 999  # Modifies original!

# Solution: Explicit copy when needed
subset = arr[::2].copy()
subset[0] = 999  # Original unchanged
```

### Pitfall 2: Integer Division

```python
# Problem
arr = np.array([1, 2, 3])
result = arr / 2  # Result is float

# Solution: Be explicit about types
result = arr // 2  # Integer division
result = arr.astype(float) / 2  # Float division
```

### Pitfall 3: Broadcasting Mistakes

```python
# Problem: Unintended broadcasting
a = np.array([1, 2, 3])  # Shape (3,)
b = np.array([[1], [2]])  # Shape (2, 1)
result = a + b  # Shape (2, 3) - probably not intended

# Solution: Verify shapes
print(f"a.shape: {a.shape}, b.shape: {b.shape}")
print(f"result.shape: {result.shape}")
```

### Pitfall 4: Floating Point Precision

```python
# Problem
a = np.array([0.1, 0.2, 0.3])
print(a.sum() == 0.6)  # False (floating point error)

# Solution: Use allclose for comparisons
print(np.allclose(a.sum(), 0.6))  # True
```

## Integration with Other Libraries

NumPy arrays are the foundation for the scientific Python ecosystem:

```python
# Pandas integration
import pandas as pd
df = pd.DataFrame(np.random.randn(5, 3), columns=['A', 'B', 'C'])
arr = df.values  # Convert to NumPy array

# Matplotlib integration
import matplotlib.pyplot as plt
x = np.linspace(0, 2*np.pi, 100)
y = np.sin(x)
plt.plot(x, y)

# SciPy integration
from scipy import stats
arr = np.random.randn(1000)
print(stats.describe(arr))

# scikit-learn integration
from sklearn.preprocessing import StandardScaler
data = np.random.randn(100, 5)
scaler = StandardScaler()
scaled = scaler.fit_transform(data)
```

## Performance Comparison

Understanding when to use NumPy vs. pure Python:

```python
import time

# Test: Sum 1 million numbers
n = 1000000

# Python list
python_list = list(range(n))
start = time.time()
result = sum(python_list)
python_time = time.time() - start

# NumPy array
numpy_array = np.arange(n)
start = time.time()
result = numpy_array.sum()
numpy_time = time.time() - start

print(f"Python: {python_time:.4f}s")
print(f"NumPy: {numpy_time:.4f}s")
print(f"NumPy is {python_time / numpy_time:.1f}x faster")
```

## See Also

### Official Documentation

- [NumPy Official Documentation](https://numpy.org/doc/)
- [NumPy User Guide](https://numpy.org/doc/stable/user/)
- [NumPy API Reference](https://numpy.org/doc/stable/reference/)
- [NumPy Tutorials](https://numpy.org/learn/)

### Learning Resources

- [NumPy Quickstart Tutorial](https://numpy.org/doc/stable/user/quickstart.html)
- [From Python to NumPy](https://www.labri.fr/perso/nrougier/from-python-to-numpy/)
- [100 NumPy Exercises](https://github.com/rougier/numpy-100)
- [NumPy for MATLAB Users](https://numpy.org/doc/stable/user/numpy-for-matlab-users.html)

### Related Libraries

- [SciPy](https://scipy.org/) - Scientific computing library built on NumPy
- [Pandas](https://pandas.pydata.org/) - Data analysis library using NumPy arrays
- [Matplotlib](https://matplotlib.org/) - Plotting library compatible with NumPy
- [scikit-learn](https://scikit-learn.org/) - Machine learning library using NumPy

### Further Reading

- [NumPy Internals](https://numpy.org/doc/stable/dev/internals.html)
- [Writing Custom ufuncs](https://numpy.org/doc/stable/user/c-info.ufunc-tutorial.html)
- [NumPy C API](https://numpy.org/doc/stable/reference/c-api/)
- [NumPy Enhancement Proposals](https://numpy.org/neps/)
