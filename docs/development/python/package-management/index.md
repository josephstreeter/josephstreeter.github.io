---
title: Python Package Management
description: Comprehensive guide to Python package management tools and best practices including pip, UV, conda, and virtual environments
author: Joseph Streeter
ms.date: 2026-01-05
ms.topic: article
---

Python package management is the process of installing, upgrading, configuring, and removing Python packages and their dependencies. With hundreds of thousands of packages available on PyPI and other repositories, effective package management is essential for productive Python development.

## Overview

Python's ecosystem offers multiple tools for managing packages and environments, each with distinct purposes and advantages. Understanding these tools and when to use them is crucial for maintaining reproducible, secure, and efficient Python projects.

### Core Concepts

**Packages** are distributions of Python code that can be installed and imported. They may include:

- Pure Python modules and packages
- Compiled extensions (C, Rust, etc.)
- Data files and resources
- Documentation and metadata

**Dependencies** are other packages required for a package to function. The dependency tree can become complex in real-world projects, requiring sophisticated resolution algorithms.

**Virtual Environments** are isolated Python environments that allow different projects to have separate dependencies, preventing version conflicts and enabling reproducible builds.

**Package Indexes** are repositories of packages. PyPI (Python Package Index) is the official repository, but private and alternative indexes are commonly used in enterprise environments.

## Package Management Tools

### pip - The Standard Package Installer

[pip](pip.md) is Python's official package installer, bundled with Python 3.4+. It's the most widely used tool for installing packages from PyPI.

**Key Features**:

- Direct installation from PyPI
- Requirements files for dependency specification
- Support for various installation sources (Git, local files, wheels)
- Integration with virtual environments
- Configuration via pip.conf or environment variables

**Best For**:

- Standard Python projects
- Simple dependency management
- General-purpose package installation
- CI/CD pipelines with established workflows

**Example Usage**:

```bash
pip install requests
pip install -r requirements.txt
pip freeze > requirements-lock.txt
```

**Learn More**: [pip Documentation](pip.md)

### UV - Extremely Fast Package Manager

[UV](uv.md) is a modern, Rust-based package installer designed as a drop-in replacement for pip and pip-tools, offering 10-100x performance improvements.

**Key Features**:

- 10-100x faster than pip
- Advanced caching with content-addressed storage
- Built-in virtual environment management
- PubGrub dependency resolution algorithm
- Drop-in replacement for pip commands

**Best For**:

- Large projects with many dependencies
- CI/CD pipelines where speed matters
- Development workflows requiring frequent installs
- Teams wanting pip compatibility with better performance

**Example Usage**:

```bash
uv pip install requests
uv pip compile requirements.in -o requirements.txt
uv pip sync requirements.txt
```

**Learn More**: [UV Documentation](uv.md)

### conda - Package and Environment Manager

[conda](conda.md) is a cross-platform package and environment manager that handles both Python and non-Python dependencies.

**Key Features**:

- Manages Python itself as a package
- Handles binary dependencies (C libraries, system tools)
- Cross-language package management
- Built-in environment management
- Conda channels for package distribution

**Best For**:

- Data science and scientific computing
- Projects requiring non-Python dependencies
- Managing multiple Python versions
- Windows users needing compiled packages

**Example Usage**:

```bash
conda create -n myenv python=3.11
conda activate myenv
conda install numpy pandas scikit-learn
```

**Learn More**: [conda Documentation](conda.md)

### virtualenv - Environment Isolation

[virtualenv](virtualenv.md) creates isolated Python environments, allowing different projects to have independent dependency sets.

**Key Features**:

- Creates isolated Python environments
- Prevents dependency conflicts between projects
- Works with any Python version
- Faster than venv in some scenarios
- Extensive configuration options

**Best For**:

- Isolating project dependencies
- Testing across multiple Python versions
- Legacy projects requiring older Python versions
- Development workflows requiring flexible environments

**Example Usage**:

```bash
virtualenv myenv
source myenv/bin/activate
pip install -r requirements.txt
```

**Learn More**: [virtualenv Documentation](virtualenv.md)

## Comparison Matrix

| Feature | pip | UV | conda | virtualenv |
| --- | --- | --- | --- | --- |
| **Speed** | Baseline | 10-100x faster | Moderate | N/A |
| **Package Source** | PyPI | PyPI | Conda channels | N/A |
| **Virtual Envs** | Via venv | Built-in | Built-in | Core purpose |
| **Binary Dependencies** | Limited | Limited | Excellent | N/A |
| **Python Management** | No | No | Yes | No |
| **Lock Files** | Manual | Via compile | environment.yml | N/A |
| **Cross-Platform** | Excellent | Excellent | Excellent | Excellent |
| **Learning Curve** | Low | Low | Moderate | Low |
| **Enterprise Support** | Community | Growing | Strong | Community |

## Choosing the Right Tool

### Decision Guide

**Use pip when**:

- Working on standard Python projects
- Following established team workflows
- Need maximum compatibility
- Working with legacy systems
- Simple dependency requirements

**Use UV when**:

- Speed is critical (CI/CD, large projects)
- Want pip compatibility with better performance
- Frequent package installations
- Large dependency trees
- Modern development workflow

**Use conda when**:

- Working with data science/scientific computing
- Need non-Python dependencies (NumPy, SciPy with optimized BLAS)
- Managing multiple Python versions
- Requiring binary compatibility guarantees
- Windows development with compiled packages

**Use virtualenv when**:

- Need environment isolation
- Working with multiple projects
- Testing across Python versions
- Want faster environment creation than venv
- Require advanced environment configuration

### Combining Tools

Many projects benefit from combining tools:

**pip + virtualenv**: Classic combination for isolated project environments

```bash
virtualenv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

**UV + virtualenv**: Speed with isolation

```bash
virtualenv .venv
source .venv/bin/activate
uv pip install -r requirements.txt
```

**conda + pip**: Handle binary dependencies with conda, Python packages with pip

```bash
conda create -n myenv python=3.11 numpy scipy
conda activate myenv
pip install -r requirements.txt
```

## Best Practices

### Virtual Environments

**Always use virtual environments** for project development:

```bash
# Create environment
python -m venv .venv
# or
virtualenv .venv
# or
conda create -n myproject python=3.11

# Activate
source .venv/bin/activate  # Unix/macOS
.venv\Scripts\activate     # Windows
```

**Benefits**:

- Isolated dependencies per project
- Prevents system Python pollution
- Reproducible environments
- Easy cleanup (delete directory)

### Requirements Management

**Separate direct and transitive dependencies**:

```text
# requirements.in - direct dependencies only
django>=4.2,<5.0
requests>=2.28.0
celery[redis]
```

```bash
# Generate locked requirements
pip freeze > requirements-lock.txt
# or with UV
uv pip compile requirements.in -o requirements.txt
```

**Use multiple requirement files**:

- `requirements.txt` - production
- `requirements-dev.txt` - development tools
- `requirements-test.txt` - testing frameworks

### Version Pinning

**Pin versions appropriately**:

```text
# Development - flexible
requests>=2.28.0

# Production - pinned
requests==2.31.0

# CI/CD - fully locked
requests==2.31.0 \
    --hash=sha256:abc123...
```

### Security

**Regularly scan for vulnerabilities**:

```bash
# Using pip-audit
pip install pip-audit
pip-audit

# Using safety
pip install safety
safety check

# Scan requirements file
pip-audit -r requirements.txt
```

**Use hash checking for production**:

```bash
pip install --require-hashes -r requirements.txt
```

### Dependency Updates

**Keep dependencies updated**:

```bash
# Check outdated packages
pip list --outdated

# Update specific package
pip install --upgrade package-name

# Or use UV for speed
uv pip compile requirements.in --upgrade
```

**Test updates thoroughly** before deploying to production.

## Common Workflows

### Starting a New Project

```bash
# 1. Create project directory
mkdir myproject && cd myproject

# 2. Create virtual environment
python -m venv .venv
source .venv/bin/activate

# 3. Create requirements.in
cat > requirements.in << EOF
django>=4.2
requests
EOF

# 4. Install and lock dependencies
pip install -r requirements.in
pip freeze > requirements.txt

# 5. Initialize version control
git init
echo ".venv/" >> .gitignore
git add .
git commit -m "Initial commit"
```

### Joining an Existing Project

```bash
# 1. Clone repository
git clone https://github.com/company/project.git
cd project

# 2. Create virtual environment
python -m venv .venv
source .venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Verify installation
python manage.py check
pytest
```

### CI/CD Pipeline

```yaml
# GitHub Actions example
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          cache: 'pip'
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
      
      - name: Run tests
        run: pytest
      
      - name: Security scan
        run: |
          pip install pip-audit
          pip-audit
```

### Data Science Project

```bash
# 1. Create conda environment
conda create -n datasci python=3.11 numpy pandas scipy scikit-learn matplotlib jupyter

# 2. Activate environment
conda activate datasci

# 3. Install additional packages
pip install seaborn plotly

# 4. Export environment
conda env export > environment.yml

# 5. Recreate elsewhere
conda env create -f environment.yml
```

## Troubleshooting

### Common Issues

#### Dependency Conflicts

**Problem**: Packages have incompatible dependency requirements

**Solution**:

```bash
# Check conflicts
pip check

# Show dependency tree
pip install pipdeptree
pipdeptree

# Use constraints file
pip install -c constraints.txt -r requirements.txt

# Try UV's better resolver
uv pip install -r requirements.txt
```

#### Slow Installations

**Problem**: Package installation takes too long

**Solutions**:

```bash
# Use UV for speed
pip install uv
uv pip install -r requirements.txt

# Use binary packages
pip install --only-binary :all: package-name

# Use faster index (if available)
pip install --index-url https://mirror.company.com/pypi/simple package-name
```

#### SSL/Certificate Errors

**Problem**: SSL certificate verification fails

**Solutions**:

```bash
# Update certificates
pip install --upgrade certifi

# Use custom certificate
pip install --cert /path/to/cert.pem package-name

# Last resort (not recommended)
pip install --trusted-host pypi.org package-name
```

#### Permission Errors

**Problem**: Cannot install packages due to permissions

**Solutions**:

```bash
# Use virtual environment (recommended)
python -m venv .venv
source .venv/bin/activate
pip install package-name

# User installation
pip install --user package-name
```

#### Package Not Found

**Problem**: Package cannot be found on PyPI

**Solutions**:

```bash
# Check package name on pypi.org

# Check available versions
pip index versions package-name

# Use alternative index
pip install --index-url https://alternative.pypi.org/simple package-name

# Install from Git
pip install git+https://github.com/user/repo.git
```

### Environment Issues

#### Wrong Python Version

```bash
# Specify Python explicitly
python3.11 -m venv .venv
python3.11 -m pip install package-name

# With conda
conda create -n myenv python=3.11
```

#### Environment Not Activating

```bash
# Use full path
source /full/path/to/.venv/bin/activate

# Check shell
echo $SHELL

# Try explicit activation
. .venv/bin/activate
```

## Advanced Topics

### Private Package Indexes

Host internal packages on private indexes:

```bash
# Configure in pip.conf
[global]
index-url = https://pypi.company.com/simple
extra-index-url = https://pypi.org/simple

# Or use environment variable
export PIP_INDEX_URL=https://pypi.company.com/simple

# Or use command flag
pip install --index-url https://pypi.company.com/simple package-name
```

### Editable Installations

Install packages in development mode:

```bash
# Install local package for development
pip install -e /path/to/package

# Install current directory
cd mypackage
pip install -e .

# With extras
pip install -e ".[dev,test]"
```

Changes to source code are immediately reflected without reinstalling.

### Custom Wheels

Build and distribute custom wheels:

```bash
# Build wheel
pip install build
python -m build

# Install wheel
pip install dist/package-1.0.0-py3-none-any.whl

# Host on private index
twine upload --repository-url https://pypi.company.com dist/*
```

### Multi-Python Projects

Manage projects requiring multiple Python versions:

```bash
# With conda
conda create -n py39 python=3.9
conda create -n py311 python=3.11

# With pyenv
pyenv install 3.9.18
pyenv install 3.11.7
pyenv local 3.11.7

# With virtualenv
virtualenv -p python3.9 .venv-py39
virtualenv -p python3.11 .venv-py311
```

### Monorepo Package Management

Handle multiple related packages:

```text
# monorepo structure
project/
├── packages/
│   ├── core/
│   │   └── setup.py
│   ├── api/
│   │   └── setup.py
│   └── client/
│       └── setup.py
└── requirements.txt
```

```bash
# Install all packages in editable mode
pip install -e packages/core
pip install -e packages/api
pip install -e packages/client
```

## Migration Guides

### From pip to UV

UV is a drop-in replacement:

```bash
# Install UV
pip install uv

# Replace pip commands
pip install requests    → uv pip install requests
pip freeze              → uv pip freeze
pip list               → uv pip list

# Compile requirements
uv pip compile requirements.in -o requirements.txt

# Sync environment
uv pip sync requirements.txt
```

### From requirements.txt to conda

```bash
# Create environment.yml from requirements.txt
conda create -n myenv --file requirements.txt

# Or manually create environment.yml
cat > environment.yml << EOF
name: myenv
channels:
  - conda-forge
  - defaults
dependencies:
  - python=3.11
  - numpy
  - pandas
  - pip:
    - requests
    - flask
EOF

conda env create -f environment.yml
```

### From system packages to virtual environments

```bash
# 1. List system packages
pip list > system-packages.txt

# 2. Create virtual environment
python -m venv .venv
source .venv/bin/activate

# 3. Install needed packages
pip install -r requirements.txt

# 4. Verify isolated environment
pip list  # Should only show project packages
```

## Performance Optimization

### Caching

Enable and configure caching:

```bash
# pip cache (enabled by default)
pip cache dir
pip cache info

# UV cache (very efficient)
uv cache dir
uv cache info

# Conda cache
conda clean --all --dry-run
```

### Parallel Installation

```bash
# UV installs packages in parallel automatically
uv pip install -r requirements.txt

# pip (single-threaded by default)
pip install -r requirements.txt
```

### Wheel Selection

```bash
# Prefer binary wheels
pip install --only-binary :all: package-name

# Build from source if needed
pip install --no-binary :all: package-name

# Specific platform
pip install --platform manylinux2014_x86_64 package-name
```

## Security and Compliance

### Vulnerability Scanning

Regularly scan dependencies:

```bash
# pip-audit (official tool)
pip install pip-audit
pip-audit

# safety (community tool)
pip install safety
safety check

# Scan requirements
pip-audit -r requirements.txt
safety check -r requirements.txt
```

### License Compliance

Check package licenses:

```bash
# Install pip-licenses
pip install pip-licenses

# List all licenses
pip-licenses

# Generate report
pip-licenses --format=markdown > licenses.md
```

### Supply Chain Security

Verify package integrity:

```bash
# Use hash checking
pip install --require-hashes -r requirements.txt

# Generate hashes
pip hash package-1.0.0.tar.gz

# Add to requirements.txt
package==1.0.0 \
    --hash=sha256:abc123...
```

## Environment Management Strategies

### Development vs Production

Maintain separate requirement sets:

```text
# requirements.in (production)
django>=4.2,<5.0
psycopg2-binary
gunicorn

# requirements-dev.in (development)
-r requirements.in
pytest
black
ruff
django-debug-toolbar
```

### Docker Integration

```dockerfile
FROM python:3.11-slim

# Install UV for speed
RUN pip install uv

WORKDIR /app

# Install dependencies (cached layer)
COPY requirements.txt .
RUN uv pip install --system -r requirements.txt

# Copy application
COPY . .

CMD ["gunicorn", "app:application"]
```

### Reproducible Environments

Ensure reproducibility:

```bash
# Pin all dependencies
pip freeze > requirements-lock.txt

# Include Python version
python --version > .python-version

# Document OS dependencies
# Ubuntu/Debian: apt-packages.txt
# macOS: brew-packages.txt
```

## Tools Ecosystem

### Complementary Tools

- **pip-tools**: Compile and sync requirements
- **pipenv**: All-in-one virtual environment and package manager
- **poetry**: Modern dependency management with lock files
- **pdm**: PEP 582 compliant package manager
- **hatch**: Modern project management
- **rye**: Experimental Rust-based tool
- **pipdeptree**: Visualize dependency trees
- **pip-audit**: Security vulnerability scanner
- **pip-review**: Manage package updates

### IDE Integration

**VS Code**:

- Automatic virtual environment detection
- Python extension support
- Integrated terminal
- Requirements.txt syntax highlighting

**PyCharm**:

- Built-in environment management
- Package management UI
- Dependency visualization
- Automatic requirements generation

## Documentation and Resources

### Official Documentation

- [pip Documentation](https://pip.pypa.io/)
- [UV Documentation](https://docs.astral.sh/uv/)
- [conda Documentation](https://docs.conda.io/)
- [virtualenv Documentation](https://virtualenv.pypa.io/)
- [Python Packaging User Guide](https://packaging.python.org/)

### Community Resources

- [PyPA (Python Packaging Authority)](https://www.pypa.io/)
- [PyPI (Python Package Index)](https://pypi.org/)
- [Python Packaging Discourse](https://discuss.python.org/c/packaging/)

### PEPs (Python Enhancement Proposals)

- [PEP 517: Build System Interface](https://peps.python.org/pep-0517/)
- [PEP 518: Build System Requirements](https://peps.python.org/pep-0518/)
- [PEP 621: Project Metadata](https://peps.python.org/pep-0621/)
- [PEP 660: Editable Installs](https://peps.python.org/pep-0660/)

## See Also

- [pip - Standard Package Installer](pip.md)
- [UV - Fast Package Manager](uv.md)
- [conda - Package and Environment Manager](conda.md)
- [virtualenv - Environment Isolation](virtualenv.md)
- [Python Best Practices](../best-practices.md)
- [Python Development Setup](../index.md)
