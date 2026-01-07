---
title: "Python Packaging"
description: "Comprehensive guide to Python packaging, distribution, and publishing packages to PyPI"
tags: ["python", "packaging", "pypi", "setuptools", "distribution", "deployment"]
category: "development"
difficulty: "intermediate"
last_updated: "2026-01-04"
---

Python packaging is the process of organizing and distributing Python code so it can be easily installed and used by others. This comprehensive guide covers modern packaging practices, from creating a simple package to publishing on PyPI.

## Overview

Python packaging allows developers to:

- Share code with the community
- Manage dependencies systematically
- Version and distribute applications
- Simplify installation and updates
- Create reusable libraries

Modern Python packaging has evolved significantly with the introduction of `pyproject.toml` and improved tooling. This guide focuses on current best practices using the latest standards.

## Package Structure

A well-organized package structure is fundamental to successful packaging:

```text
MyPackage/
├── pyproject.toml          # Build system configuration
├── README.md               # Project description
├── LICENSE                 # License information
├── .gitignore             # Git ignore file
├── src/                   # Source code (recommended layout)
│   └── mypackage/
│       ├── __init__.py    # Package initialization
│       ├── module1.py     # Module files
│       ├── module2.py
│       └── py.typed       # Type checking marker (optional)
├── tests/                 # Test directory
│   ├── __init__.py
│   ├── test_module1.py
│   └── test_module2.py
└── docs/                  # Documentation
    ├── index.md
    └── api.md
```

### Flat vs Src Layout

**Flat Layout:**

```text
MyPackage/
├── pyproject.toml
├── mypackage/
│   └── __init__.py
└── tests/
```

**Src Layout (Recommended):**

```text
MyPackage/
├── pyproject.toml
├── src/
│   └── mypackage/
│       └── __init__.py
└── tests/
```

The src layout is recommended because it:

- Prevents accidental imports from the source directory during development
- Ensures tests run against the installed package
- Makes it impossible to forget to include files in distribution
- Provides better isolation between development and installed code

## pyproject.toml

The `pyproject.toml` file is the modern standard for Python project configuration, replacing `setup.py` and `setup.cfg`.

### Basic Configuration

```toml
[build-system]
requires = ["setuptools>=68.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "mypackage"
version = "0.1.0"
description = "A short description of your package"
readme = "README.md"
requires-python = ">=3.9"
license = {text = "MIT"}
authors = [
    {name = "Your Name", email = "you@example.com"}
]
maintainers = [
    {name = "Maintainer Name", email = "maintainer@example.com"}
]
keywords = ["example", "package", "python"]
classifiers = [
    "Development Status :: 3 - Alpha",
    "Intended Audience :: Developers",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.9",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
    "Programming Language :: Python :: 3.12",
]

dependencies = [
    "requests>=2.31.0",
    "pydantic>=2.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "pytest-cov>=4.0.0",
    "black>=23.0.0",
    "ruff>=0.1.0",
    "mypy>=1.0.0",
]
docs = [
    "sphinx>=7.0.0",
    "sphinx-rtd-theme>=1.3.0",
]

[project.urls]
Homepage = "https://github.com/username/mypackage"
Documentation = "https://mypackage.readthedocs.io"
Repository = "https://github.com/username/mypackage"
Issues = "https://github.com/username/mypackage/issues"
Changelog = "https://github.com/username/mypackage/blob/main/CHANGELOG.md"

[project.scripts]
mypackage-cli = "mypackage.cli:main"

[tool.setuptools.packages.find]
where = ["src"]

[tool.setuptools.package-data]
mypackage = ["py.typed", "data/*.json"]
```

### Dynamic Versioning

Instead of hardcoding version, you can manage it dynamically:

```toml
[project]
name = "mypackage"
dynamic = ["version"]

[tool.setuptools.dynamic]
version = {attr = "mypackage.__version__"}
```

Then in `src/mypackage/__init__.py`:

```python
"""MyPackage - A Python package for doing awesome things."""

__version__ = "0.1.0"
```

### Entry Points and CLI Scripts

```toml
[project.scripts]
# Creates a CLI command
mycommand = "mypackage.cli:main"

[project.gui-scripts]
# Creates a GUI application launcher
myapp = "mypackage.gui:run"

[project.entry-points."plugin_system"]
# Custom entry points for plugin systems
myplugin = "mypackage.plugins:MyPlugin"
```

## Dependencies Management

### Specifying Dependencies

Use semantic versioning for dependency specifications:

```toml
dependencies = [
    "requests>=2.31.0,<3.0.0",     # Compatible release
    "pandas~=2.0.0",                # Approximately equal to
    "numpy>=1.24.0",                # Minimum version
    "flask==3.0.0",                 # Exact version (avoid unless necessary)
    "django>=4.2,<5.0",            # Version range
]
```

### Version Specifiers

- `>=1.0.0`: Greater than or equal to
- `<=1.0.0`: Less than or equal to
- `~=1.2.3`: Compatible release (>=1.2.3, <1.3.0)
- `==1.0.0`: Exact version
- `!=1.0.0`: Exclude specific version
- `>=1.0,<2.0`: Version range

### Optional Dependencies

```toml
[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "black>=23.0.0",
]
ml = [
    "scikit-learn>=1.3.0",
    "tensorflow>=2.14.0",
]
all = [
    "mypackage[dev,ml]",  # Include all optional groups
]
```

Install with: `pip install mypackage[dev]` or `pip install mypackage[all]`

## Building Distributions

### Build Tools

Modern Python packaging uses build tools that read `pyproject.toml`:

```bash
# Install build tools
pip install build twine

# Build the package
python -m build

# This creates:
# dist/mypackage-0.1.0.tar.gz       (source distribution)
# dist/mypackage-0.1.0-py3-none-any.whl  (wheel distribution)
```

### Source Distribution (sdist)

A source distribution contains:

- Source code
- pyproject.toml
- README, LICENSE
- Any included data files

```bash
# Build only source distribution
python -m build --sdist
```

### Wheel Distribution

A wheel is a built package format that's faster to install:

```bash
# Build only wheel
python -m build --wheel
```

**Wheel Types:**

- **Universal wheel**: `py2.py3-none-any.whl` - works on Python 2 and 3
- **Pure Python wheel**: `py3-none-any.whl` - Python 3 only, no C extensions
- **Platform wheel**: `cp311-cp311-manylinux_2_17_x86_64.whl` - compiled for specific platform

### Including Data Files

```toml
[tool.setuptools.package-data]
mypackage = [
    "data/*.json",
    "templates/*.html",
    "static/**/*",
]
```

Or use MANIFEST.in for source distributions:

```text
include README.md
include LICENSE
recursive-include src/mypackage/data *.json
recursive-include src/mypackage/templates *.html
exclude tests/*
global-exclude *.pyc
```

## Version Management

### Semantic Versioning

Follow semantic versioning (SemVer): `MAJOR.MINOR.PATCH`

- **MAJOR**: Incompatible API changes
- **MINOR**: Add functionality (backwards-compatible)
- **PATCH**: Bug fixes (backwards-compatible)

Examples:

- `1.0.0`: Initial stable release
- `1.1.0`: New features added
- `1.1.1`: Bug fixes
- `2.0.0`: Breaking changes

### Version Bumping

```bash
# Manual version bump
# Edit pyproject.toml or __init__.py

# Using bump2version (deprecated, use bump-my-version)
pip install bump-my-version
bump-my-version bump patch  # 1.0.0 -> 1.0.1
bump-my-version bump minor  # 1.0.1 -> 1.1.0
bump-my-version bump major  # 1.1.0 -> 2.0.0
```

Configuration in `pyproject.toml`:

```toml
[tool.bumpversion]
current_version = "0.1.0"
commit = true
tag = true

[[tool.bumpversion.files]]
filename = "src/mypackage/__init__.py"
search = "__version__ = \"{current_version}\""
replace = "__version__ = \"{new_version}\""

[[tool.bumpversion.files]]
filename = "pyproject.toml"
search = "version = \"{current_version}\""
replace = "version = \"{new_version}\""
```

### Pre-release Versions

```text
1.0.0a1    # Alpha release 1
1.0.0b1    # Beta release 1
1.0.0rc1   # Release candidate 1
1.0.0      # Final release
```

### Development Versions

```text
1.0.0.dev0
1.0.0.dev1
```

## Publishing to PyPI

### Setup PyPI Account

1. Create account at <https://pypi.org/account/register/>
2. Enable two-factor authentication (required)
3. Generate API token at <https://pypi.org/manage/account/token/>

### TestPyPI

Always test on TestPyPI first:

1. Create account at <https://test.pypi.org/account/register/>
2. Generate API token

### Uploading with Twine

```bash
# Install twine
pip install twine

# Check distribution files
twine check dist/*

# Upload to TestPyPI
twine upload --repository testpypi dist/*

# Test installation from TestPyPI
pip install --index-url https://test.pypi.org/simple/ mypackage

# Upload to PyPI
twine upload dist/*
```

### Configuration with .pypirc

Create `~/.pypirc`:

```ini
[distutils]
index-servers =
    pypi
    testpypi

[pypi]
username = __token__
password = pypi-AgEIcHlwaS5vcmc...

[testpypi]
repository = https://test.pypi.org/legacy/
username = __token__
password = pypi-AgENdGVzdC5weXBpLm9yZw...
```

**Security Note**: Use API tokens, not username/password. Tokens can be scoped and revoked.

### Automated Publishing with GitHub Actions

```yaml
name: Publish to PyPI

on:
  release:
    types: [published]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.11'
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install build twine
    
    - name: Build package
      run: python -m build
    
    - name: Publish to PyPI
      env:
        TWINE_USERNAME: __token__
        TWINE_PASSWORD: ${{ secrets.PYPI_API_TOKEN }}
      run: twine upload dist/*
```

## Package Metadata

### Trove Classifiers

Classifiers help users find your package:

```toml
classifiers = [
    # Development status
    "Development Status :: 4 - Beta",
    
    # Intended audience
    "Intended Audience :: Developers",
    "Intended Audience :: Science/Research",
    
    # License
    "License :: OSI Approved :: MIT License",
    
    # Python versions
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.9",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
    "Programming Language :: Python :: 3.12",
    
    # Operating systems
    "Operating System :: OS Independent",
    
    # Topics
    "Topic :: Software Development :: Libraries :: Python Modules",
    "Topic :: Scientific/Engineering :: Artificial Intelligence",
    
    # Typing
    "Typing :: Typed",
]
```

Full list: <https://pypi.org/classifiers/>

### README and Long Description

```toml
[project]
readme = "README.md"
```

Your README.md becomes the PyPI project description. Use proper Markdown:

```markdown
# MyPackage

[![PyPI version](https://badge.fury.io/py/mypackage.svg)](https://badge.fury.io/py/mypackage)
[![Python versions](https://img.shields.io/pypi/pyversions/mypackage.svg)](https://pypi.org/project/mypackage/)
[![License](https://img.shields.io/github/license/username/mypackage.svg)](https://github.com/username/mypackage/blob/main/LICENSE)

One-line description of your package.

## Features

- Feature 1
- Feature 2
- Feature 3

## Installation

\`\`\`bash
pip install mypackage
\`\`\`

## Quick Start

\`\`\`python
import mypackage

# Example usage
result = mypackage.do_something()
\`\`\`

## Documentation

Full documentation available at: https://mypackage.readthedocs.io

## Contributing

Contributions are welcome! Please read CONTRIBUTING.md for details.

## License

This project is licensed under the MIT License - see LICENSE file.
```

## Modern Build Backends

### Setuptools (Traditional)

```toml
[build-system]
requires = ["setuptools>=68.0", "wheel"]
build-backend = "setuptools.build_meta"
```

### Hatchling (Modern)

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/mypackage"]
```

### Poetry

```toml
[build-system]
requires = ["poetry-core>=1.0.0"]
build-backend = "poetry.core.masonry.api"

[tool.poetry]
name = "mypackage"
version = "0.1.0"
description = ""
authors = ["Your Name <you@example.com>"]
```

### Flit

```toml
[build-system]
requires = ["flit_core >=3.2,<4"]
build-backend = "flit_core.buildapi"

[project]
name = "mypackage"
authors = [{name = "Your Name", email = "you@example.com"}]
dynamic = ["version", "description"]
```

## Package Types

### Library Package

A reusable library for other developers:

```python
# src/mypackage/__init__.py
"""MyPackage - A utility library."""

__version__ = "0.1.0"

from mypackage.core import main_function
from mypackage.utils import helper_function

__all__ = ["main_function", "helper_function"]
```

### Application Package

An installable application with CLI:

```python
# src/mypackage/cli.py
import argparse
from mypackage import __version__

def main():
    parser = argparse.ArgumentParser(description="MyPackage CLI")
    parser.add_argument("--version", action="version", version=f"%(prog)s {__version__}")
    parser.add_argument("input", help="Input file")
    
    args = parser.parse_args()
    # Application logic here
    
if __name__ == "__main__":
    main()
```

```toml
[project.scripts]
mypackage = "mypackage.cli:main"
```

### Namespace Package

For organizing related packages under a common namespace:

```text
mycompany-core/
└── src/
    └── mycompany/
        └── core/
            └── __init__.py

mycompany-utils/
└── src/
    └── mycompany/
        └── utils/
            └── __init__.py
```

Both can be installed separately but imported as:

```python
from mycompany.core import something
from mycompany.utils import helper
```

## Testing Packages

### Test Installation Locally

```bash
# Install in editable mode for development
pip install -e .

# Install with optional dependencies
pip install -e .[dev]

# Build and test the built package
python -m build
pip install dist/mypackage-0.1.0-py3-none-any.whl

# Verify installation
python -c "import mypackage; print(mypackage.__version__)"

# Check package metadata
pip show mypackage
```

### Test with Tox

Create `tox.ini`:

```ini
[tox]
envlist = py39,py310,py311,py312
isolated_build = True

[testenv]
deps =
    pytest>=7.0.0
    pytest-cov>=4.0.0
commands =
    pytest tests/ --cov=mypackage --cov-report=term-missing

[testenv:lint]
deps =
    ruff
    black
    mypy
commands =
    ruff check src/
    black --check src/
    mypy src/
```

Run tests:

```bash
pip install tox
tox
```

### Validate Package

```bash
# Check package metadata
python -m build
twine check dist/*

# Validate README renders correctly
pip install readme_renderer
python -m readme_renderer README.md -o /tmp/README.html
```

## Best Practices

### Project Organization

1. **Use src layout** for better isolation
2. **Include comprehensive README** with badges, examples, and documentation links
3. **Add LICENSE file** with clear licensing terms
4. **Create CHANGELOG.md** to track version changes
5. **Write CONTRIBUTING.md** for contributor guidelines
6. **Include .gitignore** for Python projects

### Dependency Management

1. **Pin exact versions** in requirements.txt for applications
2. **Use loose version constraints** in pyproject.toml for libraries
3. **Specify minimum Python version** that you test against
4. **Keep dependencies minimal** for libraries
5. **Use optional dependencies** for non-core features

### Version Control

1. **Tag releases** in git: `git tag v0.1.0`
2. **Follow semantic versioning** strictly
3. **Maintain changelog** with version history
4. **Use pre-release versions** for testing (alpha, beta, rc)

### Documentation

1. **Write docstrings** for all public APIs
2. **Include type hints** for better IDE support
3. **Add py.typed marker** for typed packages
4. **Host documentation** on Read the Docs or GitHub Pages
5. **Include examples** in README and docs

### Security

1. **Use API tokens** instead of passwords for PyPI
2. **Enable 2FA** on PyPI account
3. **Scan dependencies** for vulnerabilities (safety, pip-audit)
4. **Sign releases** with GPG when possible
5. **Include security policy** (SECURITY.md)

### Testing

1. **Test multiple Python versions** with tox
2. **Achieve high test coverage** (aim for >90%)
3. **Test the built package** not just source code
4. **Use CI/CD** for automated testing and publishing
5. **Test on TestPyPI** before publishing to PyPI

### Package Size

1. **Exclude unnecessary files** from distribution
2. **Use .gitignore** and MANIFEST.in appropriately
3. **Split large packages** into multiple packages
4. **Consider wheel size** for faster installation

## Advanced Topics

### Binary Extensions

For packages with C/C++ extensions:

```toml
[build-system]
requires = ["setuptools>=68.0", "wheel", "Cython>=3.0.0"]
build-backend = "setuptools.build_meta"

[tool.setuptools]
ext-modules = [
    {name = "mypackage._speedups", sources = ["src/mypackage/_speedups.c"]}
]
```

### Platform-Specific Wheels

Use cibuildwheel for building wheels across platforms:

```yaml
# .github/workflows/wheels.yml
name: Build Wheels

on: [push, pull_request]

jobs:
  build_wheels:
    name: Build wheels on ${{ matrix.os }}
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Build wheels
      uses: pypa/cibuildwheel@v2.16.0
      
    - uses: actions/upload-artifact@v3
      with:
        path: ./wheelhouse/*.whl
```

### Plugin Systems

Create extensible packages with entry points:

```toml
[project.entry-points."mypackage.plugins"]
default_plugin = "mypackage.plugins.default:DefaultPlugin"
```

Load plugins:

```python
from importlib.metadata import entry_points

def load_plugins():
    discovered_plugins = entry_points(group='mypackage.plugins')
    return {ep.name: ep.load() for ep in discovered_plugins}
```

### Metadata from Version Control

Use setuptools_scm for automatic versioning from git tags:

```toml
[build-system]
requires = ["setuptools>=68.0", "setuptools-scm>=8.0"]
build-backend = "setuptools.build_meta"

[project]
dynamic = ["version"]

[tool.setuptools_scm]
write_to = "src/mypackage/_version.py"
```

### Type Checking Support

For typed packages:

```python
# src/mypackage/py.typed
# This file marks the package as typed
```

```toml
[tool.setuptools.package-data]
mypackage = ["py.typed"]
```

### Data Files and Resources

Modern resource handling:

```python
from importlib.resources import files

def load_config():
    config_file = files('mypackage').joinpath('data/config.json')
    return config_file.read_text()
```

## Common Issues and Solutions

### Import Errors After Installation

**Problem**: Package installs but imports fail

**Solutions:**

- Ensure `__init__.py` exists in package directory
- Check package name matches import name
- Use src layout to catch issues during development
- Verify PYTHONPATH isn't interfering

### Missing Files in Distribution

**Problem**: Files not included in wheel/sdist

**Solutions:**

- Add files to `package-data` in pyproject.toml
- Create MANIFEST.in for source distribution
- Use `python -m build` and inspect generated archives
- Check `include_package_data = True` setting

### Version Conflicts

**Problem**: Dependency version conflicts

**Solutions:**

- Use compatible release specifiers (`~=`)
- Test with minimum and maximum supported versions
- Document known conflicts
- Use virtual environments for testing

### Platform-Specific Issues

**Problem**: Package works on one OS but not others

**Solutions:**

- Test on multiple platforms (use CI/CD)
- Avoid platform-specific paths (use pathlib)
- Document platform requirements
- Use conditional dependencies if needed

```toml
[project]
dependencies = [
    "pywin32>=305; platform_system=='Windows'",
    "uvloop>=0.19.0; platform_system!='Windows'",
]
```

### Large Package Size

**Problem**: Package is too large for comfortable installation

**Solutions:**

- Split into multiple packages
- Exclude test files and docs from wheel
- Use proper MANIFEST.in
- Consider data hosting separately

### Broken Dependencies

**Problem**: Users report installation failures due to dependencies

**Solutions:**

- Use loose version constraints
- Test with oldest supported versions
- Document optional dependencies clearly
- Provide lockfiles for reproducible installs

## Tools Ecosystem

### Available Build Tools

- **build**: Modern build frontend (recommended)
- **pip**: Can build but not recommended
- **setuptools**: Traditional backend
- **hatchling**: Modern alternative backend
- **poetry**: All-in-one dependency and build tool
- **flit**: Simple packaging for pure Python

### Publishing Tools

- **twine**: Upload packages to PyPI (recommended)
- **Poetry**: Built-in publishing
- **Flit**: Built-in publishing

### Dependency Management Tools

- **pip**: Standard package installer
- **pip-tools**: Compile and sync requirements
- **poetry**: Full dependency management
- **pipenv**: Application dependency management
- **uv**: Ultra-fast Python package installer

### Testing Tools

- **tox**: Test across Python versions and environments
- **nox**: Flexible test automation (Python-based)
- **pytest**: Testing framework
- **coverage.py**: Code coverage measurement

### Version Management Tools

- **bump-my-version**: Version bumping tool
- **setuptools_scm**: Version from VCS tags
- **versioneer**: Automatic version strings from VCS

### Quality Tools

- **ruff**: Fast Python linter and formatter
- **black**: Code formatter
- **mypy**: Static type checker
- **pylint**: Code analyzer
- **bandit**: Security linter
- **safety**: Dependency vulnerability scanner

## Example: Complete Package

Here's a complete example of a well-structured package:

### Project Structure

```text
awesome-tool/
├── .github/
│   └── workflows/
│       ├── test.yml
│       └── publish.yml
├── src/
│   └── awesome_tool/
│       ├── __init__.py
│       ├── core.py
│       ├── utils.py
│       ├── cli.py
│       ├── py.typed
│       └── data/
│           └── config.json
├── tests/
│   ├── __init__.py
│   ├── test_core.py
│   └── test_utils.py
├── docs/
│   ├── index.md
│   └── api.md
├── .gitignore
├── README.md
├── LICENSE
├── CHANGELOG.md
├── CONTRIBUTING.md
├── pyproject.toml
└── tox.ini
```

### Example pyproject.toml

```toml
[build-system]
requires = ["setuptools>=68.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "awesome-tool"
version = "1.0.0"
description = "An awesome tool for doing awesome things"
readme = "README.md"
requires-python = ">=3.9"
license = {text = "MIT"}
authors = [
    {name = "Your Name", email = "you@example.com"}
]
keywords = ["awesome", "tool", "utility"]
classifiers = [
    "Development Status :: 4 - Beta",
    "Intended Audience :: Developers",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.9",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
    "Programming Language :: Python :: 3.12",
    "Typing :: Typed",
]

dependencies = [
    "requests>=2.31.0",
    "click>=8.1.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "pytest-cov>=4.0.0",
    "black>=23.0.0",
    "ruff>=0.1.0",
    "mypy>=1.0.0",
    "tox>=4.0.0",
]

[project.urls]
Homepage = "https://github.com/username/awesome-tool"
Documentation = "https://awesome-tool.readthedocs.io"
Repository = "https://github.com/username/awesome-tool"
Issues = "https://github.com/username/awesome-tool/issues"
Changelog = "https://github.com/username/awesome-tool/blob/main/CHANGELOG.md"

[project.scripts]
awesome = "awesome_tool.cli:main"

[tool.setuptools.packages.find]
where = ["src"]

[tool.setuptools.package-data]
awesome_tool = ["py.typed", "data/*.json"]

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
addopts = "--cov=awesome_tool --cov-report=term-missing"

[tool.black]
line-length = 100
target-version = ['py39']

[tool.ruff]
line-length = 100
target-version = "py39"
select = ["E", "F", "I", "N", "W"]

[tool.mypy]
python_version = "3.9"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
```

### Example Package Init File

```python
"""Awesome Tool - A Python package for doing awesome things."""

__version__ = "1.0.0"
__author__ = "Your Name"
__email__ = "you@example.com"

from awesome_tool.core import AwesomeClass, awesome_function
from awesome_tool.utils import helper_function

__all__ = [
    "AwesomeClass",
    "awesome_function",
    "helper_function",
    "__version__",
]
```

### Publishing Workflow

```yaml
# .github/workflows/publish.yml
name: Publish to PyPI

on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      id-token: write  # For trusted publishing
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.11'
    
    - name: Install build tools
      run: |
        python -m pip install --upgrade pip
        pip install build twine
    
    - name: Build package
      run: python -m build
    
    - name: Check package
      run: twine check dist/*
    
    - name: Publish to PyPI
      uses: pypa/gh-action-pypi-publish@release/v1
```

## Resources

### Official Documentation

- [Python Packaging User Guide](https://packaging.python.org/) - Authoritative guide
- [PyPA Specifications](https://packaging.python.org/specifications/) - Technical specifications
- [PEP 517](https://peps.python.org/pep-0517/) - Build system specification
- [PEP 518](https://peps.python.org/pep-0518/) - pyproject.toml specification
- [PEP 621](https://peps.python.org/pep-0621/) - Project metadata in pyproject.toml
- [PyPI Help](https://pypi.org/help/) - PyPI documentation

### Tools Documentation

- [setuptools Documentation](https://setuptools.pypa.io/)
- [build Documentation](https://build.pypa.io/)
- [twine Documentation](https://twine.readthedocs.io/)
- [Poetry Documentation](https://python-poetry.org/docs/)
- [Hatch Documentation](https://hatch.pypa.io/)
- [Flit Documentation](https://flit.pypa.io/)

### Community Resources

- [Python Discord](https://discord.gg/python) - #packaging channel
- [Python Packaging Authority GitHub](https://github.com/pypa)
- [Real Python Packaging Tutorial](https://realpython.com/python-application-layouts/)
- [Packaging Python Projects Tutorial](https://packaging.python.org/tutorials/packaging-projects/)

### Best Practices Guides

- [PyPA Packaging Guide](https://packaging.python.org/guides/)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Choose a License](https://choosealicense.com/)

## See Also

- [pip - Package Installation](../package-management/pip.md)
- [Virtual Environments](../package-management/virtualenv.md)
- [Python Best Practices](../best-practices.md)
- [CI/CD for Python](ci.md)
- [Cloud Deployment](cloud-deployment.md)
