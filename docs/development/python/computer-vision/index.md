---
title: Computer Vision with Python
description: Comprehensive guide to computer vision concepts, techniques, and practical implementations using OpenCV, PIL, and deep learning frameworks
---

Computer vision is a field of artificial intelligence that enables computers to interpret and understand visual information from the world. This guide covers fundamental concepts, classical algorithms, and modern deep learning approaches for image and video processing.

## Overview

Computer vision has revolutionized how machines interact with visual data, enabling applications ranging from autonomous vehicles to medical image analysis. By combining classical image processing techniques with modern deep learning, we can build systems that understand, analyze, and generate visual content.

**Key Applications:**

- Image classification and object detection
- Facial recognition and biometric systems
- Autonomous vehicles and robotics
- Medical imaging and diagnostics
- Augmented and virtual reality
- Quality control and manufacturing
- Video surveillance and security
- Document analysis and OCR

**Core Concepts:**

- Image representation and color spaces
- Image filtering and enhancement
- Feature detection and description
- Object detection and tracking
- Image segmentation
- 3D reconstruction and depth estimation
- Neural networks for computer vision

## Getting Started

### Installation and Setup

Install essential computer vision libraries:

```bash
# Core libraries
pip install opencv-python opencv-contrib-python
pip install pillow
pip install numpy matplotlib

# Deep learning frameworks
pip install torch torchvision
pip install tensorflow

# Additional tools
pip install scikit-image
pip install imageio
pip install albumentations  # Image augmentation
```

For GPU acceleration with CUDA:

```bash
# PyTorch with CUDA
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118

# TensorFlow with GPU
pip install tensorflow[and-cuda]
```

### Basic Image Operations

#### Loading and Displaying Images

```python
import cv2
import numpy as np
from PIL import Image
import matplotlib.pyplot as plt

# Load image with OpenCV (BGR format)
img_bgr = cv2.imread('image.jpg')

# Convert BGR to RGB
img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)

# Load with PIL
img_pil = Image.open('image.jpg')

# Load with matplotlib
img_plt = plt.imread('image.jpg')

# Display with matplotlib
plt.figure(figsize=(10, 6))
plt.imshow(img_rgb)
plt.axis('off')
plt.title('Image Display')
plt.show()

# Display with OpenCV
cv2.imshow('Image Window', img_bgr)
cv2.waitKey(0)
cv2.destroyAllWindows()
```

#### Image Properties

```python
# Get image dimensions
height, width, channels = img_rgb.shape
print(f"Image size: {width}x{height}")
print(f"Channels: {channels}")
print(f"Data type: {img_rgb.dtype}")
print(f"Shape: {img_rgb.shape}")

# Get pixel value
pixel = img_rgb[100, 150]  # [row, col]
print(f"Pixel at (150, 100): RGB = {pixel}")

# Modify pixel
img_rgb[100, 150] = [255, 0, 0]  # Set to red

# Get image statistics
print(f"Min value: {img_rgb.min()}")
print(f"Max value: {img_rgb.max()}")
print(f"Mean value: {img_rgb.mean():.2f}")
print(f"Standard deviation: {img_rgb.std():.2f}")
```

#### Saving Images

```python
# Save with OpenCV
cv2.imwrite('output.jpg', img_bgr)
cv2.imwrite('output.png', img_bgr, [cv2.IMWRITE_PNG_COMPRESSION, 9])

# Save with PIL
img_pil.save('output.jpg', quality=95)
img_pil.save('output.png', compress_level=9)

# Save with matplotlib
plt.imsave('output.png', img_rgb)
```

### Working with Different Image Formats

```python
from PIL import Image
import cv2

def convert_image_format(input_path, output_path, quality=95):
    """Convert image between formats."""
    # Using PIL
    img = Image.open(input_path)
    
    # Convert mode if necessary
    if img.mode == 'RGBA' and output_path.endswith('.jpg'):
        img = img.convert('RGB')
    
    img.save(output_path, quality=quality)
    print(f"Converted {input_path} to {output_path}")
# Example conversions
convert_image_format('image.png', 'image.jpg')
convert_image_format('image.jpg', 'image.webp')
convert_image_format('image.bmp', 'image.png')

# Batch conversion
import os
from pathlib import Path

def batch_convert(input_dir, output_dir, output_format='jpg'):
    """Convert all images in directory to specified format."""
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    
    for filename in os.listdir(input_dir):
        if filename.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp', '.webp')):
            input_path = os.path.join(input_dir, filename)
            output_filename = Path(filename).stem + f'.{output_format}'
            output_path = os.path.join(output_dir, output_filename)
            
            convert_image_format(input_path, output_path)
# Convert all images to JPG
batch_convert('input_images/', 'output_images/', 'jpg')
```

### Image Coordinate Systems

```python
import numpy as np
import matplotlib.pyplot as plt

# Create sample image
img = np.zeros((400, 600, 3), dtype=np.uint8)

# OpenCV/NumPy coordinate system: (row, col) or (y, x)
# Origin (0,0) is at top-left corner

# Draw points at different locations
points = [
 (50, 100, 'Top-Left Region'),
 (200, 300, 'Center'),
 (350, 500, 'Bottom-Right Region')
]

for y, x, label in points:
    cv2.circle(img, (x, y), 5, (0, 255, 0), -1)
    cv2.putText(img, label, (x+10, y), cv2.FONT_HERSHEY_SIMPLEX, 
                0.5, (255, 255, 255), 1)
# Draw coordinate axes
cv2.line(img, (0, 0), (100, 0), (255, 0, 0), 2)  # X-axis (red)
cv2.line(img, (0, 0), (0, 100), (0, 0, 255), 2)  # Y-axis (blue)
cv2.putText(img, 'X', (105, 10), cv2.FONT_HERSHEY_SIMPLEX, 
            0.7, (255, 0, 0), 2)
cv2.putText(img, 'Y', (5, 115), cv2.FONT_HERSHEY_SIMPLEX, 
            0.7, (0, 0, 255), 2)
plt.figure(figsize=(10, 6))
plt.imshow(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
plt.title('Image Coordinate System')
plt.xlabel('X (columns)')
plt.ylabel('Y (rows)')
plt.grid(True, alpha=0.3)
plt.show()
```

### Region of Interest (ROI)

```python
import cv2

# Load image
img = cv2.imread('image.jpg')

# Extract ROI using slicing [y1:y2, x1:x2]
roi = img[100:300, 150:350]

# Display ROI
cv2.imshow('Region of Interest', roi)
cv2.waitKey(0)

# Modify ROI (changes original image)
roi[:] = [0, 255, 0]  # Set to green

# Copy ROI to another location
img[400:600, 150:350] = roi.copy()

# Extract ROI with boundary checking
def extract_roi(img, x, y, width, height):
    """Safely extract ROI with boundary checking."""
    h, w = img.shape[:2]
    
    # Ensure coordinates are within bounds
    x1 = max(0, x)
    y1 = max(0, y)
    x2 = min(w, x + width)
    y2 = min(h, y + height)
    
    return img[y1:y2, x1:x2]
# Extract with bounds checking
safe_roi = extract_roi(img, 100, 150, 200, 150)
```

### Image Channels

```python
import cv2
import numpy as np
import matplotlib.pyplot as plt

# Load color image
img = cv2.imread('image.jpg')
img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

# Split into channels
r, g, b = cv2.split(img_rgb)
# Or using NumPy indexing
r = img_rgb[:, :, 0]
g = img_rgb[:, :, 1]
b = img_rgb[:, :, 2]

# Display individual channels
fig, axes = plt.subplots(2, 2, figsize=(12, 10))

axes[0, 0].imshow(img_rgb)
axes[0, 0].set_title('Original Image')
axes[0, 0].axis('off')

axes[0, 1].imshow(r, cmap='Reds')
axes[0, 1].set_title('Red Channel')
axes[0, 1].axis('off')

axes[1, 0].imshow(g, cmap='Greens')
axes[1, 0].set_title('Green Channel')
axes[1, 0].axis('off')

axes[1, 1].imshow(b, cmap='Blues')
axes[1, 1].set_title('Blue Channel')
axes[1, 1].axis('off')

plt.tight_layout()
plt.show()

# Merge channels back
merged = cv2.merge([r, g, b])

# Create false color image (swap channels)
false_color = cv2.merge([b, r, g])  # BRG instead of RGB

# Set specific channel to zero
img_no_red = img_rgb.copy()
img_no_red[:, :, 0] = 0  # Remove red channel

img_no_green = img_rgb.copy()
img_no_green[:, :, 1] = 0  # Remove green channel

img_no_blue = img_rgb.copy()
img_no_blue[:, :, 2] = 0  # Remove blue channel
```

### Basic Image Arithmetic

```python
import cv2
import numpy as np

# Load images
img1 = cv2.imread('image1.jpg')
img2 = cv2.imread('image2.jpg')

# Ensure same size
img2 = cv2.resize(img2, (img1.shape[1], img1.shape[0]))

# Addition (with saturation)
added = cv2.add(img1, img2)

# NumPy addition (with wrapping)
added_np = img1 + img2  # May cause overflow

# Weighted addition (blending)
alpha = 0.7
beta = 0.3
blended = cv2.addWeighted(img1, alpha, img2, beta, 0)

# Subtraction
subtracted = cv2.subtract(img1, img2)

# Multiplication
multiplied = cv2.multiply(img1, img2)

# Division
divided = cv2.divide(img1, img2)

# Bitwise operations
bitwise_and = cv2.bitwise_and(img1, img2)
bitwise_or = cv2.bitwise_or(img1, img2)
bitwise_xor = cv2.bitwise_xor(img1, img2)
bitwise_not = cv2.bitwise_not(img1)

# Brightness adjustment
bright = cv2.add(img1, 50)  # Increase brightness
dark = cv2.subtract(img1, 50)  # Decrease brightness

# Contrast adjustment
contrast = cv2.multiply(img1, 1.5)  # Increase contrast

# Clipping
def adjust_brightness_contrast(img, brightness=0, contrast=1.0):
    """Adjust brightness and contrast."""
    adjusted = cv2.multiply(img, contrast)
    adjusted = cv2.add(adjusted, brightness)
    return np.clip(adjusted, 0, 255).astype(np.uint8)
result = adjust_brightness_contrast(img1, brightness=30, contrast=1.2)
```

## Content Sections (To Be Completed)

The following sections will be developed progressively:

### Color Spaces and Conversion

Content coming soon...

### Image Filtering and Enhancement

Content coming soon...

### Edge Detection

Content coming soon...

### Feature Detection and Description

Content coming soon...

### Object Detection

Content coming soon...

### Image Segmentation

Content coming soon...

### Face Detection and Recognition

Content coming soon...

### Optical Character Recognition (OCR)

Content coming soon...

### Video Processing

Content coming soon...

### 3D Vision and Depth Estimation

Content coming soon...

### Deep Learning for Computer Vision

Content coming soon...

### Real-World Applications

Content coming soon...

### Best Practices

Content coming soon...

## Related Topics

- [Deep Learning](~/docs/development/python/deep-learning/index.md)
- [Natural Language Processing](~/docs/development/python/nlp/index.md)
- [Machine Learning](~/docs/development/python/machine-learning/index.md)
