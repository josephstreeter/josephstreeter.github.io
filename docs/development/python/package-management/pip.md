---
title: pip - Python Package Installer
description: Comprehensive guide to pip, the standard package installer for Python, covering installation, package management, requirements files, and best practices
---

pip is the standard package installer for Python, used to install and manage software packages from the Python Package Index (PyPI) and other package indexes. It's the most widely used Python package management tool and comes pre-installed with Python 3.4+.

## Overview

pip (Package Installer for Python) is the official tool for installing Python packages from PyPI, the Python Package Index. With over 500,000 packages available, pip serves as the gateway to the vast Python ecosystem. It handles dependency resolution, version management, and package installation, making it an essential tool for every Python developer.

## Key Features

### Package Management

- **Install packages** from PyPI or other sources
- **Uninstall packages** cleanly with dependency tracking
- **Upgrade packages** to latest versions
- **List installed packages** with version information
- **Show package information** including dependencies
- **Search for packages** on PyPI (deprecated but alternatives exist)

### Requirements Management

- **Requirements files** for reproducible environments
- **Constraint files** for version restrictions
- **Editable installs** for local development
- **Multiple package sources** with index URLs
- **Hash checking** for security verification

### Platform Support

- **Cross-platform**: Windows, macOS, Linux, BSD
- **Multiple Python versions**: Python 2.7+ and Python 3.4+
- **Virtual environment integration**: Works seamlessly with venv, virtualenv
- **System integration**: User and system-wide installations

## Installation

### Python 3.4+ (Pre-installed)

pip comes pre-installed with Python 3.4 and later:

```bash
# Verify pip installation
pip --version

# Or use python -m pip
python -m pip --version
```

### Installing pip on Older Python Versions

If pip is not installed:

```bash
# Download get-pip.py
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py

# Install pip
python get-pip.py
```

### Upgrading pip

Always keep pip up to date:

```bash
# Upgrade pip (Unix/macOS)
python -m pip install --upgrade pip

# Upgrade pip (Windows)
python -m pip install --upgrade pip

# Specific version
python -m pip install pip==24.0
```

### Using python -m pip

It's recommended to use `python -m pip` instead of just `pip`:

```bash
# Ensures you're using the pip associated with your Python
python -m pip install package-name

# Avoids PATH issues with multiple Python installations
python3 -m pip install package-name
```

## Basic Usage

### Installing Packages

```bash
# Install latest version
pip install requests

# Install specific version
pip install requests==2.31.0

# Install minimum version
pip install "requests>=2.28.0"

# Install version range
pip install "requests>=2.28.0,<3.0.0"

# Install multiple packages
pip install requests flask django

# Install from requirements file
pip install -r requirements.txt
```

### Uninstalling Packages

```bash
# Uninstall single package
pip uninstall requests

# Uninstall multiple packages
pip uninstall requests flask django

# Uninstall without confirmation
pip uninstall -y package-name

# Uninstall from requirements file
pip uninstall -r requirements.txt -y
```

### Upgrading Packages

```bash
# Upgrade single package
pip install --upgrade requests

# Upgrade multiple packages
pip install --upgrade requests flask django

# Upgrade pip itself
pip install --upgrade pip

# Upgrade all packages (requires pip-review or similar)
pip list --outdated
pip install --upgrade package1 package2 package3
```

### Listing Packages

```bash
# List all installed packages
pip list

# List outdated packages
pip list --outdated

# List in requirements format
pip freeze

# Show specific package details
pip show requests

# Show package dependencies
pip show requests --verbose
```

## Requirements Files

Requirements files specify which packages should be installed, enabling reproducible environments.

### Basic Requirements File

Create `requirements.txt`:

```text
# Core dependencies
requests==2.31.0
flask==3.0.0
django>=4.2,<5.0

# Development dependencies
pytest==7.4.0
black==23.7.0
```

Install from requirements:

```bash
pip install -r requirements.txt
```

### Generating Requirements Files

```bash
# Export all installed packages
pip freeze > requirements.txt

# Better: manually maintain requirements.txt
# Only list direct dependencies, not transitive ones
```

### Requirements File Syntax

```text
# Comments start with #

# Exact version
requests==2.31.0

# Minimum version
requests>=2.28.0

# Version range
requests>=2.28.0,<3.0.0

# Compatible release
requests~=2.31.0  # Same as >=2.31.0,<2.32.0

# Exclude specific version
requests!=2.30.0

# Install from Git
git+https://github.com/user/repo.git@v1.0#egg=package-name

# Install from Git branch
git+https://github.com/user/repo.git@main#egg=package-name

# Install from local directory
/path/to/package

# Editable install (development mode)
-e /path/to/package

# Include another requirements file
-r base-requirements.txt

# Install from specific index
--index-url https://pypi.org/simple
--extra-index-url https://pypi.company.com/simple

# Install with specific options
package-name[extra1,extra2]
```

### Multiple Requirements Files

Organize requirements by environment:

```text
# requirements.txt (production)
django==4.2
psycopg2-binary==2.9.9
gunicorn==21.2.0

# requirements-dev.txt (development)
-r requirements.txt
pytest==7.4.0
pytest-django==4.5.2
black==23.7.0
ruff==0.0.292

# requirements-test.txt (testing)
-r requirements.txt
pytest==7.4.0
coverage==7.3.0
```

Install based on environment:

```bash
# Production
pip install -r requirements.txt

# Development
pip install -r requirements-dev.txt

# Testing
pip install -r requirements-test.txt
```

## Constraints Files

Constraints files limit package versions without requiring installation:

```text
# constraints.txt
requests<3.0.0
urllib3<2.0.0
certifi>=2023.0.0
```

Use constraints:

```bash
pip install -c constraints.txt package-name

# Or in requirements file
pip install -r requirements.txt -c constraints.txt
```

## Advanced Features

### Installing from Different Sources

#### From PyPI (Default)

```bash
pip install package-name
```

#### From Git Repository

```bash
# From Git URL
pip install git+https://github.com/user/repo.git

# From specific branch
pip install git+https://github.com/user/repo.git@develop

# From specific tag
pip install git+https://github.com/user/repo.git@v1.0.0

# From specific commit
pip install git+https://github.com/user/repo.git@abc123

# With subdirectory
pip install git+https://github.com/user/repo.git#subdirectory=pkg_dir
```

#### From Local Directory

```bash
# Regular install
pip install /path/to/package

# Editable install (development mode)
pip install -e /path/to/package

# Editable install current directory
pip install -e .
```

#### From Wheel File

```bash
pip install package-1.0.0-py3-none-any.whl
```

#### From Source Distribution

```bash
pip install package-1.0.0.tar.gz
```

### Custom Package Indexes

```bash
# Use custom index
pip install --index-url https://pypi.company.com/simple package-name

# Use additional index
pip install --extra-index-url https://pypi.company.com/simple package-name

# No index (offline install)
pip install --no-index --find-links=/local/dir package-name
```

### Package Extras

Many packages offer optional extras:

```bash
# Install with single extra
pip install requests[security]

# Install with multiple extras
pip install flask[async,dotenv]

# Common examples
pip install "celery[redis,msgpack]"
pip install "django[argon2,bcrypt]"
pip install "sqlalchemy[postgresql,mysql]"
```

### Editable Installs

For local package development:

```bash
# Install package in editable mode
pip install -e /path/to/package

# Install current directory in editable mode
cd /path/to/package
pip install -e .

# With extras
pip install -e ".[dev,test]"
```

Changes to source code are immediately reflected without reinstalling.

### Hash Checking

Ensure package integrity with hash verification:

Generate hashes:

```bash
pip hash package-1.0.0.tar.gz
```

Use in requirements:

```text
requests==2.31.0 \
    --hash=sha256:abc123... \
    --hash=sha256:def456...
```

Install with hash checking:

```bash
pip install --require-hashes -r requirements.txt
```

## Configuration

### Configuration File Locations

pip reads configuration from:

1. **Per-project**: `<project>/pip.conf` or `<project>/pip.ini`
2. **Per-user** (Unix): `~/.config/pip/pip.conf`
3. **Per-user** (macOS): `~/Library/Application Support/pip/pip.conf`
4. **Per-user** (Windows): `%APPDATA%\pip\pip.ini`
5. **System-wide** (Unix): `/etc/pip.conf`
6. **System-wide** (Windows): `C:\ProgramData\pip\pip.ini`

### Configuration File Format

Create `~/.config/pip/pip.conf` (Unix/macOS):

```ini
[global]
timeout = 60
index-url = https://pypi.org/simple
trusted-host = pypi.org
               pypi.python.org

[install]
no-cache-dir = false
compile = no

[list]
format = columns
```

Or `%APPDATA%\pip\pip.ini` (Windows):

```ini
[global]
timeout = 60
index-url = https://pypi.org/simple
```

### Common Configuration Options

```ini
[global]
# Connection timeout (seconds)
timeout = 60

# Default package index
index-url = https://pypi.org/simple

# Additional indexes
extra-index-url = https://pypi.company.com/simple

# Trusted hosts (no SSL verification)
trusted-host = internal-pypi.company.com

# Proxy settings
proxy = http://user:password@proxy.company.com:8080

[install]
# Don't compile .pyc files
compile = no

# User installation by default
user = true

# Don't use binary packages
no-binary = :all:

# Only use binary packages
only-binary = :all:

[list]
# Output format
format = columns
```

### Environment Variables

Override configuration with environment variables:

```bash
# Package index
export PIP_INDEX_URL=https://pypi.org/simple

# Additional index
export PIP_EXTRA_INDEX_URL=https://pypi.company.com/simple

# Timeout
export PIP_DEFAULT_TIMEOUT=60

# Cache directory
export PIP_CACHE_DIR=/tmp/pip-cache

# Disable cache
export PIP_NO_CACHE_DIR=1

# Trusted host
export PIP_TRUSTED_HOST="pypi.org pypi.python.org"

# Proxy
export PIP_PROXY=http://proxy.company.com:8080

# Require virtualenv
export PIP_REQUIRE_VIRTUALENV=true
```

## Virtual Environments

pip works best with virtual environments to isolate project dependencies.

### Using venv (Built-in)

```bash
# Create virtual environment
python -m venv myenv

# Activate (Unix/macOS)
source myenv/bin/activate

# Activate (Windows)
myenv\Scripts\activate

# Install packages
pip install requests flask

# Deactivate
deactivate
```

### Using virtualenv

```bash
# Install virtualenv
pip install virtualenv

# Create virtual environment
virtualenv myenv

# Activate and use (same as venv)
source myenv/bin/activate
pip install requests
deactivate
```

### Project Workflow

```bash
# Create project directory
mkdir myproject
cd myproject

# Create virtual environment
python -m venv .venv

# Activate
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Work on project
python manage.py runserver

# Freeze dependencies
pip freeze > requirements.txt

# Deactivate when done
deactivate
```

## Caching

pip caches downloaded packages to speed up repeated installations.

### Cache Location

- **Unix/macOS**: `~/.cache/pip`
- **Windows**: `%LocalAppData%\pip\Cache`

### Cache Commands

```bash
# Show cache location
pip cache dir

# Show cache info
pip cache info

# List cached files
pip cache list

# Remove specific package from cache
pip cache remove package-name

# Clear entire cache
pip cache purge
```

### Disable Cache

```bash
# Temporarily
pip install --no-cache-dir package-name

# Permanently (config file)
[install]
no-cache-dir = true

# Or environment variable
export PIP_NO_CACHE_DIR=1
```

## Dependency Resolution

### How pip Resolves Dependencies

pip uses a backtracking resolver (since version 20.3):

1. Reads direct requirements
2. Fetches package metadata
3. Identifies all dependencies (transitive)
4. Finds compatible versions for all packages
5. Backtracks if conflicts occur
6. Installs resolved packages

### Handling Dependency Conflicts

```bash
# Show dependency tree (requires pipdeptree)
pip install pipdeptree
pipdeptree

# Check for conflicts
pip check

# Force specific versions
pip install "package-a==1.0" "package-b==2.0"

# Use constraints file
pip install -r requirements.txt -c constraints.txt
```

### Dependency Resolution Strategies

```bash
# Default: eager upgrade
pip install --upgrade package-name

# Only upgrade if needed
pip install --upgrade-strategy only-if-needed package-name

# Eager upgrade (upgrade all dependencies)
pip install --upgrade-strategy eager package-name
```

## Security Best Practices

### Verify Package Integrity

```bash
# Use hash checking
pip install --require-hashes -r requirements.txt

# Verify SSL certificates (default)
pip install package-name

# Trust specific host (avoid if possible)
pip install --trusted-host pypi.org package-name
```

### Scan for Vulnerabilities

```bash
# Install pip-audit
pip install pip-audit

# Scan installed packages
pip-audit

# Scan requirements file
pip-audit -r requirements.txt

# Or use safety
pip install safety
safety check
```

### Use Virtual Environments

Always use virtual environments to isolate dependencies:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Pin Dependencies

```bash
# Pin exact versions in requirements.txt
requests==2.31.0
flask==3.0.0

# Generate pinned requirements
pip freeze > requirements-lock.txt
```

### Regular Updates

```bash
# Check for outdated packages
pip list --outdated

# Update packages regularly
pip install --upgrade package-name

# Use automated tools
pip install pip-review
pip-review --auto
```

## Troubleshooting

### Common Issues

#### Permission Errors

```bash
# Use user installation
pip install --user package-name

# Or use virtual environment (recommended)
python -m venv .venv
source .venv/bin/activate
pip install package-name
```

#### SSL Certificate Errors

```bash
# Update certificates
pip install --upgrade certifi

# Use system certificates
pip install --cert /etc/ssl/certs/ca-certificates.crt package-name

# Temporarily disable SSL (not recommended)
pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org package-name
```

#### Package Not Found

```bash
# Check package name spelling
pip search package-name  # Note: search is disabled on PyPI

# Search on pypi.org website instead

# Use verbose output
pip install -v package-name

# Check available versions
pip index versions package-name
```

#### Dependency Conflicts

```bash
# Show conflict details
pip install package-name

# Check installed packages
pip check

# Show dependency tree
pip install pipdeptree
pipdeptree

# Use constraints
pip install -c constraints.txt package-name
```

#### Build Failures

```bash
# Install build dependencies
pip install build setuptools wheel

# Use binary packages only
pip install --only-binary :all: package-name

# Install build tools (Ubuntu/Debian)
sudo apt-get install python3-dev build-essential

# Install build tools (macOS)
xcode-select --install

# Install build tools (Windows)
# Download Visual Studio Build Tools
```

#### Slow Installation

```bash
# Use cache
pip install package-name  # Uses cache by default

# Increase timeout
pip install --timeout=300 package-name

# Use faster mirror (if available)
pip install --index-url https://mirrors.company.com/pypi/simple package-name

# Consider using uv (much faster)
pip install uv
uv pip install package-name
```

### Debug Mode

```bash
# Verbose output
pip install -v package-name

# Very verbose output
pip install -vv package-name

# Extremely verbose output
pip install -vvv package-name

# Show debug information
pip debug
```

## Best Practices

### Project Setup

1. **Always use virtual environments**

   ```bash
   python -m venv .venv
   source .venv/bin/activate
   ```

2. **Maintain clean requirements files**

   ```text
   # requirements.txt - only direct dependencies
   django==4.2
   requests>=2.28.0
   celery[redis]
   ```

3. **Separate requirements by environment**

   - `requirements.txt` - production
   - `requirements-dev.txt` - development
   - `requirements-test.txt` - testing

4. **Pin versions for production**

   ```bash
   pip freeze > requirements-lock.txt
   ```

### Dependency Management

1. **List only direct dependencies** in requirements.txt
2. **Use `pip freeze`** for complete environment snapshot
3. **Update dependencies regularly** but test thoroughly
4. **Use version constraints** wisely:
   - `==` for production stability
   - `>=` with upper bound for compatibility
   - `~=` for compatible releases

### Security

1. **Enable hash checking** for production:

   ```bash
   pip install --require-hashes -r requirements.txt
   ```

2. **Scan for vulnerabilities** regularly:

   ```bash
   pip-audit -r requirements.txt
   ```

3. **Keep pip updated**:

   ```bash
   pip install --upgrade pip
   ```

4. **Avoid `--trusted-host`** when possible

### Performance

1. **Use pip cache** (enabled by default)
2. **Use binary packages** when available
3. **Consider faster alternatives** like [uv](uv.md) for CI/CD
4. **Use `--no-deps`** when you control dependencies manually

### CI/CD

```yaml
# GitHub Actions example
- name: Set up Python
  uses: actions/setup-python@v4
  with:
    python-version: '3.11'
    cache: 'pip'

- name: Install dependencies
  run: |
    python -m pip install --upgrade pip
    pip install -r requirements.txt
```

## Comparison with Other Tools

| Feature | pip | pip-tools | Poetry | uv |
| --- | --- | --- | --- | --- |
| **Package Installation** | ✓ | ✓ | ✓ | ✓ |
| **Dependency Resolution** | Basic | Advanced | Advanced | Advanced |
| **Lock Files** | Manual | ✓ | ✓ | ✓ |
| **Virtual Env Management** | External | External | Built-in | Built-in |
| **Project Management** | No | No | ✓ | Limited |
| **Speed** | Baseline | Baseline | Moderate | 10-100x faster |
| **Maturity** | Very High | High | High | Growing |

## Alternatives and Complementary Tools

### pip-tools

Compile and sync requirements:

```bash
pip install pip-tools

# Create requirements.in
echo "django" > requirements.in

# Compile to requirements.txt
pip-compile requirements.in

# Sync environment
pip-sync requirements.txt
```

### Poetry

Full-featured dependency management:

```bash
pip install poetry
poetry new myproject
poetry add requests
poetry install
```

### uv

Extremely fast pip replacement:

```bash
pip install uv
uv pip install requests
```

See [UV documentation](uv.md) for details.

### Pipenv

Combines pip and virtualenv:

```bash
pip install pipenv
pipenv install requests
pipenv shell
```

## pip Commands Reference

### Installation Commands

| Command | Description |
| --- | --- |
| `pip install package` | Install package |
| `pip install -r requirements.txt` | Install from requirements |
| `pip install -e .` | Editable install |
| `pip install --upgrade package` | Upgrade package |
| `pip uninstall package` | Uninstall package |

### Information Commands

| Command | Description |
| --- | --- |
| `pip list` | List installed packages |
| `pip list --outdated` | Show outdated packages |
| `pip show package` | Show package details |
| `pip freeze` | Output installed packages |
| `pip check` | Verify dependencies |

### Cache Management Commands

| Command | Description |
| --- | --- |
| `pip cache dir` | Show cache location |
| `pip cache info` | Show cache information |
| `pip cache list` | List cached files |
| `pip cache purge` | Clear cache |

### Configuration Commands

| Command | Description |
| --- | --- |
| `pip config list` | List configuration |
| `pip config get key` | Get config value |
| `pip config set key value` | Set config value |
| `pip config unset key` | Unset config value |

### Debug Commands

| Command | Description |
| --- | --- |
| `pip debug` | Show debug information |
| `pip --version` | Show pip version |
| `pip help` | Show help |
| `pip help install` | Show command help |

## See Also

- [pip Official Documentation](https://pip.pypa.io/)
- [Python Packaging Guide](https://packaging.python.org/)
- [PyPI - Python Package Index](https://pypi.org/)
- [uv - Fast pip Alternative](uv.md)
- [Virtual Environments](virtualenv.md)
- [Package Management Overview](index.md)

## Additional Resources

### Official Documentation

- [pip User Guide](https://pip.pypa.io/en/stable/user_guide/)
- [pip Reference Guide](https://pip.pypa.io/en/stable/reference/)
- [Requirements File Format](https://pip.pypa.io/en/stable/reference/requirements-file-format/)
- [pip Configuration](https://pip.pypa.io/en/stable/topics/configuration/)

### Community Resources

- [Python Packaging Authority](https://www.pypa.io/)
- [pip GitHub Repository](https://github.com/pypa/pip)
- [pip Issue Tracker](https://github.com/pypa/pip/issues)
- [Python Packaging Discourse](https://discuss.python.org/c/packaging/)

### Related Tools

- [pip-tools](https://github.com/jazzband/pip-tools) - Requirements compilation
- [pip-audit](https://github.com/pypa/pip-audit) - Security scanning
- [pipdeptree](https://github.com/tox-dev/pipdeptree) - Dependency tree visualization
- [pip-review](https://github.com/jgonggrijp/pip-review) - Update management
