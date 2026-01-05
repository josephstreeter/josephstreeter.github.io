---
title: Python Package Management
description: Overview of package managers and dependency management in Python
author: Joseph Streeter
date: 2026-01-04
tags: [python, package-management, pip, conda, uv, virtualenv]
---

## Overview

Effective package management is essential for Python development. This guide covers tools for managing dependencies, virtual environments, and package distribution.

## Package Managers

### UV

Modern, fast Python package installer. See [UV Guide](package-management/uv.md) for details.

### pip

Standard Python package installer. See [pip Guide](package-management/pip.md) for details.

### conda

Package and environment manager for data science. See [conda Guide](package-management/conda.md) for details.

## Virtual Environments

### virtualenv

Tool for creating isolated Python environments. See [virtualenv Guide](package-management/virtualenv.md) for details.

### venv

Built-in Python module for virtual environments.

```bash
# Create virtual environment
python -m venv myenv

# Activate (Linux/Mac)
source myenv/bin/activate

# Activate (Windows)
myenv\Scripts\activate

# Deactivate
deactivate
```

## Dependency Management

### requirements.txt

```bash
# Generate requirements file
pip freeze > requirements.txt

# Install from requirements
pip install -r requirements.txt
```

### pyproject.toml

Modern Python project configuration:

```toml
[project]
name = "myproject"
version = "0.1.0"
dependencies = [
    "requests>=2.28.0",
    "pandas>=2.0.0"
]
```

## Topics

- [Package Management Overview](package-management/index.md)
- [UV](package-management/uv.md)
- [pip](package-management/pip.md)
- [conda](package-management/conda.md)
- [virtualenv](package-management/virtualenv.md)

## See Also

- [Best Practices](best-practices/index.md)
- [Deployment](deployment/index.md)
