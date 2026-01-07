---
title: UV - Extremely Fast Python Package Manager
description: Comprehensive guide to UV, the Rust-powered Python package installer and resolver that's 10-100x faster than pip
---

UV is an extremely fast Python package installer and resolver written in Rust by Astral, designed as a drop-in replacement for pip and pip-tools. It delivers 10-100x performance improvements while maintaining full compatibility with existing Python workflows.

## Overview

UV represents a paradigm shift in Python package management, leveraging Rust's performance and safety guarantees to dramatically accelerate dependency resolution and package installation. Unlike traditional Python-based tools, UV compiles to native code and employs sophisticated caching strategies, making it ideal for CI/CD pipelines, large projects, and development workflows where speed matters.

## Key Features

### Performance

- **10-100x faster** than pip for package installation
- **Parallel downloads** of packages with intelligent concurrency
- **Advanced caching** with content-addressed storage
- **Optimized dependency resolution** using PubGrub algorithm
- **Zero-copy installs** where possible

### Compatibility

- **Drop-in replacement** for pip and pip-tools commands
- **Requirements.txt support** with full syntax compatibility
- **Pyproject.toml integration** for modern Python projects
- **Virtual environment management** built-in
- **Platform wheels** for Linux, macOS, and Windows

### Developer Experience

- **Beautiful terminal output** with progress indicators
- **Detailed error messages** with actionable suggestions
- **Consistent behavior** across platforms
- **No Python dependency** - single binary installation

## Installation

### Using the Official Installer

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

For Windows PowerShell:

```powershell
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
```

### Using pip

```bash
pip install uv
```

### Using Homebrew (macOS/Linux)

```bash
brew install uv
```

### Using Cargo (Rust)

```bash
cargo install uv
```

### Verify Installation

```bash
uv --version
```

## Basic Usage

### Installing Packages

Replace `pip install` with `uv pip install`:

```bash
# Install a single package
uv pip install requests

# Install multiple packages
uv pip install requests numpy pandas

# Install from requirements.txt
uv pip install -r requirements.txt

# Install with specific version
uv pip install "django>=4.2,<5.0"
```

### Creating Virtual Environments

UV includes built-in virtual environment management:

```bash
# Create a new virtual environment
uv venv

# Create with specific Python version
uv venv --python 3.11

# Create in custom location
uv venv .venv-custom

# Activate (same as standard venv)
source .venv/bin/activate  # Linux/macOS
.venv\Scripts\activate     # Windows
```

### Package Resolution

```bash
# Compile dependencies (like pip-compile)
uv pip compile requirements.in -o requirements.txt

# Compile with specific Python version
uv pip compile requirements.in --python-version 3.11

# Upgrade all packages to latest versions
uv pip compile requirements.in --upgrade

# Upgrade specific package
uv pip compile requirements.in --upgrade-package requests
```

### Synchronizing Environments

```bash
# Sync environment to match requirements.txt exactly
uv pip sync requirements.txt

# Useful for ensuring reproducible environments
uv pip sync requirements-dev.txt requirements.txt
```

## Advanced Features

### Dependency Resolution Strategies

UV uses the **PubGrub algorithm** for dependency resolution, providing:

- **Faster resolution** compared to pip's backtracking
- **Better error messages** when conflicts occur
- **More predictable** behavior across runs

```bash
# Show resolution strategy
uv pip install --resolution highest requests

# Use lowest compatible versions
uv pip install --resolution lowest-direct requests
```

### Caching

UV implements sophisticated caching at multiple levels:

```bash
# View cache location
uv cache dir

# Clean cache
uv cache clean

# Show cache statistics
uv cache info
```

Cache locations:

- **Linux**: `~/.cache/uv`
- **macOS**: `~/Library/Caches/uv`
- **Windows**: `%LOCALAPPDATA%\uv\cache`

### Offline Mode

```bash
# Use only cached packages
uv pip install --offline -r requirements.txt
```

### Custom Index URLs

```bash
# Use private PyPI repository
uv pip install --index-url https://pypi.company.com/simple/ package-name

# Use additional index
uv pip install --extra-index-url https://pypi.company.com/simple/ package-name
```

## Integration with Existing Workflows

### Migration from pip

UV is designed as a drop-in replacement:

```bash
# Before
pip install -r requirements.txt

# After
uv pip install -r requirements.txt
```

### Migration from pip-tools

```bash
# Before (pip-compile)
pip-compile requirements.in

# After
uv pip compile requirements.in

# Before (pip-sync)
pip-sync requirements.txt

# After
uv pip sync requirements.txt
```

### CI/CD Integration

#### GitHub Actions

```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install UV
        run: curl -LsSf https://astral.sh/uv/install.sh | sh
        
      - name: Create virtual environment
        run: uv venv
        
      - name: Install dependencies
        run: uv pip install -r requirements.txt
        
      - name: Run tests
        run: |
          source .venv/bin/activate
          pytest
```

#### GitLab CI

```yaml
test:
  image: python:3.11
  before_script:
    - curl -LsSf https://astral.sh/uv/install.sh | sh
    - export PATH="$HOME/.cargo/bin:$PATH"
  script:
    - uv venv
    - uv pip install -r requirements.txt
    - source .venv/bin/activate
    - pytest
```

#### Docker

```dockerfile
FROM python:3.11-slim

# Install UV
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.cargo/bin:$PATH"

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN uv venv && \
    uv pip install -r requirements.txt

COPY . .

CMD ["python", "app.py"]
```

## Performance Benchmarks

### Installation Speed

Real-world benchmarks comparing UV to pip:

| Project | pip | UV | Speedup |
| --- | --- | --- | --- |
| Flask (fresh) | 4.2s | 0.3s | **14x** |
| Django (fresh) | 8.1s | 0.5s | **16x** |
| FastAPI (fresh) | 3.5s | 0.2s | **17x** |
| Data Science Stack | 45s | 2.1s | **21x** |
| Large Monorepo | 180s | 8.5s | **21x** |

### Resolution Speed

Dependency resolution benchmarks:

| Scenario | pip-compile | UV | Speedup |
| --- | --- | --- | --- |
| Simple project (10 deps) | 3.2s | 0.1s | **32x** |
| Medium project (50 deps) | 18s | 0.4s | **45x** |
| Complex project (200 deps) | 120s | 1.2s | **100x** |

### Cache Performance

With warm cache, UV achieves near-instant installations:

```bash
# First install (cold cache)
time uv pip install django  # 0.5s

# Second install (warm cache)
time uv pip install django  # 0.05s (10x faster)
```

## Best Practices

### Project Setup

1. **Use requirements.in for source dependencies**:

   ```text
   # requirements.in
   django>=4.2
   requests
   celery[redis]
   ```

2. **Generate locked requirements.txt**:

   ```bash
   uv pip compile requirements.in -o requirements.txt
   ```

3. **Commit both files** to version control

### Development vs Production

Create separate requirement files:

```text
# requirements.in (production)
django>=4.2
psycopg2-binary

# requirements-dev.in (development)
-r requirements.in
pytest
black
ruff
```

Compile both:

```bash
uv pip compile requirements.in -o requirements.txt
uv pip compile requirements-dev.in -o requirements-dev.txt
```

### Dependency Updates

```bash
# Update all dependencies
uv pip compile requirements.in --upgrade -o requirements.txt

# Update specific package
uv pip compile requirements.in --upgrade-package django -o requirements.txt

# Preview updates without writing
uv pip compile requirements.in --upgrade --dry-run
```

### Reproducible Builds

```bash
# Pin all dependencies including transitive ones
uv pip compile requirements.in -o requirements.txt

# Install exact versions
uv pip sync requirements.txt

# Verify installation
uv pip freeze
```

### Security Scanning

Integrate with security tools:

```bash
# Generate requirements for scanning
uv pip compile requirements.in -o requirements.txt

# Scan with safety
safety check -r requirements.txt

# Scan with pip-audit
pip-audit -r requirements.txt
```

## Comparison with Other Tools

### UV vs pip

| Feature | pip | UV |
| --- | --- | --- |
| **Speed** | Baseline | 10-100x faster |
| **Dependency Resolution** | Backtracking | PubGrub |
| **Caching** | Basic | Advanced multi-layer |
| **Parallel Downloads** | No | Yes |
| **Written In** | Python | Rust |
| **Virtual Env Management** | Separate tool | Built-in |

### UV vs pip-tools

| Feature | pip-tools | UV |
| --- | --- | --- |
| **Compile Speed** | Baseline | 10-100x faster |
| **Sync Command** | Yes | Yes |
| **Requirements.in** | Yes | Yes |
| **Upgrade Strategy** | Standard | Enhanced |
| **Cache Management** | Basic | Advanced |

### UV vs Poetry

| Feature | Poetry | UV |
| --- | --- | --- |
| **Speed** | Moderate | Very fast |
| **Lock File** | poetry.lock | requirements.txt |
| **Project Management** | Full featured | Focused on speed |
| **Virtual Env** | Built-in | Built-in |
| **Build System** | Yes | No |
| **Dependency Groups** | Yes | Via multiple files |

### UV vs PDM

| Feature | PDM | UV |
| --- | --- | --- |
| **Speed** | Fast | Very fast |
| **PEP 582** | Yes | No |
| **Lock File** | pdm.lock | requirements.txt |
| **Build Backend** | Yes | No |
| **Standards Compliance** | High | High |

## Troubleshooting

### Common Issues

#### SSL Certificate Errors

```bash
# Use system certificates
uv pip install --trusted-host pypi.org package-name

# Or set environment variable
export UV_CERT=/path/to/cert.pem
```

#### Package Not Found

```bash
# Check available versions
uv pip index versions package-name

# Use verbose output
uv pip install -v package-name
```

#### Dependency Conflicts

```bash
# Show dependency tree
uv pip tree

# Force specific resolution
uv pip install "package-a==1.0" "package-b==2.0"

# Use resolution strategy
uv pip install --resolution lowest package-name
```

#### Cache Issues

```bash
# Clear cache
uv cache clean

# Reinstall without cache
uv pip install --no-cache package-name
```

### Debug Mode

```bash
# Enable verbose output
uv pip install -v package-name

# Enable trace output
uv pip install -vv package-name

# Show full backtrace
RUST_BACKTRACE=1 uv pip install package-name
```

## Environment Variables

UV respects standard Python packaging environment variables plus its own:

### Standard Variables

- `PIP_INDEX_URL`: Default package index
- `PIP_EXTRA_INDEX_URL`: Additional package indexes
- `PIP_TRUSTED_HOST`: Trusted hosts for HTTP
- `PIP_CERT`: Certificate bundle path
- `PIP_NO_CACHE_DIR`: Disable caching

### UV-Specific Variables

- `UV_CACHE_DIR`: Custom cache directory
- `UV_NO_CACHE`: Disable UV cache (0 or 1)
- `UV_SYSTEM_PYTHON`: Use system Python (0 or 1)
- `UV_LINK_MODE`: Link mode for installs (copy, hardlink, symlink)
- `UV_CONCURRENT_DOWNLOADS`: Max concurrent downloads (default: 50)

Example:

```bash
# Use custom cache and limit downloads
export UV_CACHE_DIR=/tmp/uv-cache
export UV_CONCURRENT_DOWNLOADS=10
uv pip install -r requirements.txt
```

## Configuration

### Per-Project Configuration

Create `pyproject.toml`:

```toml
[tool.uv]
index-url = "https://pypi.org/simple"
extra-index-url = ["https://pypi.company.com/simple"]
no-cache = false
link-mode = "copy"

[tool.uv.pip]
timeout = 30
retries = 3
```

### Global Configuration

Create `~/.config/uv/uv.toml`:

```toml
[pip]
index-url = "https://pypi.org/simple"
timeout = 60

[cache]
directory = "~/.cache/uv"
```

## Real-World Use Cases

### Large Monorepo

```bash
# requirements.in with 500+ dependencies
uv pip compile requirements.in -o requirements.txt  # 2-3 seconds

# Install in CI
uv pip sync requirements.txt  # 5-10 seconds

# Time saved per CI run: 2-3 minutes
```

### Microservices

```dockerfile
# Base image with UV
FROM python:3.11-slim as base
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.cargo/bin:$PATH"

# Dependencies layer (cached)
FROM base as deps
COPY requirements.txt .
RUN uv venv && uv pip sync requirements.txt

# Application layer
FROM deps
COPY . .
CMD ["python", "main.py"]
```

### Data Science Workflow

```bash
# Install heavy data science stack quickly
uv pip install numpy pandas scikit-learn matplotlib jupyter

# Time saved: 40+ seconds on first install
# Time saved with cache: 90+ seconds
```

### Development Environment

```bash
# Fast environment setup for new developers
git clone project
cd project
uv venv
uv pip install -r requirements-dev.txt
source .venv/bin/activate

# Total time: <30 seconds (vs 2-3 minutes with pip)
```

## Future Roadmap

UV is actively developed by Astral. Planned features include:

- **Project management**: Full Poetry/PDM alternative
- **Build backend**: PEP 517 build system support
- **Lock file format**: Standardized lock file
- **Plugin system**: Extensibility for custom workflows
- **Workspace support**: Monorepo management
- **Enhanced security**: Built-in vulnerability scanning

## See Also

- [UV Official Documentation](https://docs.astral.sh/uv/)
- [UV GitHub Repository](https://github.com/astral-sh/uv)
- [Astral Blog](https://astral.sh/blog)
- [pip Documentation](pip.md)
- [Virtual Environments](virtualenv.md)
- [Package Management Overview](index.md)

## Additional Resources

### Community

- [Discord Community](https://discord.gg/astral-sh)
- [GitHub Discussions](https://github.com/astral-sh/uv/discussions)
- [Issue Tracker](https://github.com/astral-sh/uv/issues)

### Tutorials

- [Migrating from pip to UV](https://docs.astral.sh/uv/guides/migrate-from-pip/)
- [CI/CD with UV](https://docs.astral.sh/uv/guides/ci-cd/)
- [Docker Best Practices](https://docs.astral.sh/uv/guides/docker/)

### Related Tools by Astral

- [Ruff](https://github.com/astral-sh/ruff) - Extremely fast Python linter
- [Ruff Formatter](https://github.com/astral-sh/ruff) - Fast Python formatter
