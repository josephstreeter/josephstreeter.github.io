---
title: conda - Package and Environment Manager
description: Comprehensive guide to conda, the cross-platform package and environment management system for Python and beyond
---

conda is an open-source package and environment management system that runs on Windows, macOS, and Linux. It was created for Python programs but can package and distribute software for any language. conda is the package manager used by Anaconda distributions.

## Overview

conda is unique among Python package managers because it manages not just Python packages but also Python itself, along with non-Python dependencies like C libraries, R packages, and system tools. This makes it particularly valuable for data science, scientific computing, and cross-platform development where complex binary dependencies are common.

Unlike pip, which only installs Python packages, conda can:

- Install and manage multiple Python versions
- Handle binary dependencies outside the Python ecosystem
- Create isolated environments with different Python versions
- Resolve complex dependency chains across languages
- Provide pre-compiled binaries for faster installation
- Manage packages from multiple channels (repositories)

## Key Features

### Universal Package Management

- **Multi-language support**: Python, R, Ruby, C/C++, Fortran, and more
- **Binary package distribution**: Pre-compiled packages for speed and reliability
- **System-level dependencies**: Handles libraries like BLAS, LAPACK, CUDA
- **Cross-platform**: Consistent behavior across Windows, macOS, Linux

### Environment Management

- **Multiple Python versions**: Run different Python versions per environment
- **Complete isolation**: Separate dependencies per project
- **Easy switching**: Quick activation/deactivation
- **Environment export**: Share exact environments via YAML files

### Package Resolution

- **Sophisticated solver**: SAT solver for complex dependency resolution
- **Compatibility guarantees**: Ensures binary compatibility
- **Rollback capability**: Revert to previous environment states
- **Update strategies**: Flexible upgrade policies

### Enterprise Features

- **Anaconda.org**: Public and private package hosting
- **Custom channels**: Private package repositories
- **Mirror support**: Local package caching
- **Security scanning**: Package vulnerability detection (commercial)

## Installation

### Anaconda Distribution

Full distribution with 1,500+ packages for data science:

```bash
# Download from https://www.anaconda.com/products/distribution
# Linux/macOS
bash Anaconda3-2024.02-Linux-x86_64.sh

# Follow installer prompts
# Initializes conda in shell profile
```

**Size**: ~3GB
**Includes**: Python, Jupyter, NumPy, pandas, matplotlib, scikit-learn, and more
**Best for**: Data science, scientific computing, beginners

### Miniconda

Minimal installer with conda, Python, and essential packages:

```bash
# Download from https://docs.conda.io/en/latest/miniconda.html
# Linux
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

# macOS
curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh
bash Miniconda3-latest-MacOSX-x86_64.sh

# Windows: Download and run .exe installer
```

**Size**: ~100MB
**Includes**: conda, Python, pip, and essential packages
**Best for**: Minimal installations, advanced users, CI/CD

### Mambaforge

Faster conda alternative with mamba solver:

```bash
# Download from https://github.com/conda-forge/miniforge
# Linux
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"
bash Mambaforge-$(uname)-$(uname -m).sh
```

**Features**: Faster package resolution with mamba
**Default channel**: conda-forge (community-driven)
**Best for**: Speed-focused workflows

### Verify Installation

```bash
# Check conda version
conda --version

# Check conda info
conda info

# Update conda
conda update conda
```

## Basic Usage

### Managing Environments

#### Creating Environments

```bash
# Create environment with default Python
conda create -n myenv

# Create with specific Python version
conda create -n myenv python=3.11

# Create with packages
conda create -n myenv python=3.11 numpy pandas

# Create from environment.yml
conda env create -f environment.yml

# Create with specific channel
conda create -n myenv -c conda-forge python=3.11
```

#### Activating and Deactivating

```bash
# Activate environment
conda activate myenv

# Deactivate current environment
conda deactivate

# Return to base environment
conda activate base
```

#### Listing Environments

```bash
# List all environments
conda env list

# Or
conda info --envs

# Show active environment
conda info --envs | grep '*'
```

#### Removing Environments

```bash
# Remove environment
conda remove -n myenv --all

# Or
conda env remove -n myenv

# Confirm removal
conda env list
```

### Managing Packages

#### Installing Packages

```bash
# Install package in active environment
conda install numpy

# Install specific version
conda install numpy=1.24.0

# Install multiple packages
conda install numpy pandas matplotlib

# Install from specific channel
conda install -c conda-forge package-name

# Install from multiple channels
conda install -c conda-forge -c bioconda package-name

# Install in specific environment
conda install -n myenv numpy
```

#### Updating Packages

```bash
# Update single package
conda update numpy

# Update all packages in environment
conda update --all

# Update conda itself
conda update conda

# Update in specific environment
conda update -n myenv numpy
```

#### Removing Packages

```bash
# Remove package
conda remove numpy

# Remove multiple packages
conda remove numpy pandas

# Remove from specific environment
conda remove -n myenv numpy
```

#### Listing Packages

```bash
# List packages in active environment
conda list

# List packages in specific environment
conda list -n myenv

# Search for package
conda search numpy

# Show package info
conda info numpy
```

### Environment Export and Reproduction

#### Export Environment

```bash
# Export to environment.yml (recommended)
conda env export > environment.yml

# Export with exact versions
conda env export --no-builds > environment.yml

# Export cross-platform compatible
conda env export --from-history > environment.yml
```

#### Create from environment.yml

```bash
# Create environment from file
conda env create -f environment.yml

# Update existing environment
conda env update -f environment.yml

# Create with different name
conda env create -f environment.yml -n newname
```

#### Example environment.yml

```yaml
name: myproject
channels:
  - conda-forge
  - defaults
dependencies:
  - python=3.11
  - numpy=1.24
  - pandas=2.0
  - scikit-learn=1.3
  - pip
  - pip:
    - requests>=2.28.0
    - flask==3.0.0
```

## Advanced Features

### Channels

Channels are repositories where conda looks for packages.

#### Default Channels

```bash
# Show configured channels
conda config --show channels

# Add channel
conda config --add channels conda-forge

# Add channel with priority
conda config --prepend channels conda-forge

# Remove channel
conda config --remove channels conda-forge
```

#### Channel Priority

```bash
# Set strict channel priority
conda config --set channel_priority strict

# Set flexible priority
conda config --set channel_priority flexible

# Show current priority
conda config --show channel_priority
```

#### Popular Channels

- **defaults**: Anaconda's official channel
- **conda-forge**: Community-driven, 20,000+ packages
- **bioconda**: Bioinformatics packages
- **pytorch**: PyTorch and related packages
- **nvidia**: NVIDIA CUDA and GPU packages

```bash
# Install from conda-forge
conda install -c conda-forge package-name

# Install from multiple channels with priority
conda install -c pytorch -c conda-forge package-name
```

### Mixing conda and pip

conda environments work with pip:

```bash
# Activate conda environment
conda activate myenv

# Install conda packages first
conda install numpy pandas

# Then install pip packages
pip install package-not-in-conda

# Export includes pip packages
conda env export > environment.yml
```

**Best Practices**:

1. Install as much as possible with conda first
2. Use pip only for packages not available in conda
3. Export environment to capture both conda and pip packages
4. Avoid `pip install` in base environment

### Environment Cloning

```bash
# Clone environment
conda create -n myenv-clone --clone myenv

# Verify clone
conda list -n myenv-clone
```

### Package Caching

```bash
# Show cache location
conda info

# Clean package cache
conda clean --all

# Remove index cache
conda clean --index-cache

# Remove unused packages
conda clean --packages

# Dry run
conda clean --all --dry-run
```

### Revision History

```bash
# List revisions
conda list --revisions

# Revert to specific revision
conda install --revision 2

# Useful for undoing problematic updates
```

## Configuration

### Configuration File

conda reads configuration from `.condarc`:

**Locations**:

- User: `~/.condarc`
- System: `$CONDA_ROOT/.condarc`
- Environment: `$CONDA_PREFIX/.condarc`

#### Example .condarc

```yaml
channels:
  - conda-forge
  - defaults

channel_priority: strict

auto_activate_base: false

show_channel_urls: true

always_yes: false

pip_interop_enabled: true

env_prompt: '({name}) '
```

### Configuration Commands

```bash
# Show all configuration
conda config --show

# Show specific setting
conda config --show channels

# Set configuration value
conda config --set auto_activate_base false

# Add to list
conda config --add channels conda-forge

# Remove from list
conda config --remove channels conda-forge

# Set in specific file
conda config --file ~/.condarc --set always_yes true
```

### Common Configuration Options

```bash
# Disable base environment auto-activation
conda config --set auto_activate_base false

# Enable pip interoperability
conda config --set pip_interop_enabled true

# Set strict channel priority
conda config --set channel_priority strict

# Always show channel URLs
conda config --set show_channel_urls true

# Set default channels
conda config --add channels conda-forge
conda config --add channels defaults
```

## Environment Management Best Practices

### Project Organization

```bash
# Create project-specific environment
conda create -n myproject python=3.11

# Install dependencies
conda activate myproject
conda install numpy pandas matplotlib
pip install custom-package

# Export for team
conda env export > environment.yml

# Document in README
echo "conda env create -f environment.yml" >> README.md
```

### Development Workflow

```bash
# Development environment
conda create -n myproject-dev python=3.11
conda activate myproject-dev
conda install numpy pandas pytest black ruff jupyter

# Production environment (minimal)
conda create -n myproject-prod python=3.11
conda install numpy pandas

# Testing environment
conda create -n myproject-test python=3.11
conda install pytest coverage
```

### Version Pinning

```yaml
# environment.yml with version constraints
name: myproject
channels:
  - conda-forge
  - defaults
dependencies:
  # Exact versions for stability
  - python=3.11.5
  - numpy=1.24.3
  - pandas=2.0.3
  
  # Compatible versions
  - scikit-learn>=1.3,<1.4
  
  # Latest minor version
  - matplotlib=3.7
```

### Cross-Platform Compatibility

```bash
# Export without builds (cross-platform)
conda env export --from-history > environment.yml

# Or manually specify
dependencies:
  - python=3.11
  - numpy  # No version, gets latest compatible
  - pandas>=2.0
```

## Data Science Workflows

### Jupyter Integration

```bash
# Install Jupyter in base
conda install -n base jupyter

# Install kernel for environment
conda activate myenv
conda install ipykernel
python -m ipykernel install --user --name myenv --display-name "Python (myenv)"

# Launch Jupyter
jupyter notebook

# Select "Python (myenv)" kernel
```

### Complete Data Science Environment

```bash
# Create comprehensive data science environment
conda create -n datascience python=3.11 \
  numpy pandas matplotlib seaborn \
  scikit-learn scipy statsmodels \
  jupyter jupyterlab ipython \
  plotly bokeh \
  sqlalchemy psycopg2

# Activate and extend
conda activate datascience
pip install streamlit kedro mlflow
```

### GPU Computing

```bash
# Create environment with CUDA support
conda create -n gpu-env python=3.11
conda activate gpu-env

# Install PyTorch with CUDA
conda install pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia

# Or TensorFlow with GPU
conda install tensorflow-gpu

# Verify GPU access
python -c "import torch; print(torch.cuda.is_available())"
```

## Troubleshooting

### Common Issues

#### Slow Package Resolution

**Problem**: conda takes too long to resolve dependencies

**Solutions**:

```bash
# Use mamba (much faster)
conda install -n base mamba
mamba install numpy pandas

# Or use libmamba solver
conda install -n base conda-libmamba-solver
conda config --set solver libmamba

# Reduce channels
conda config --set channel_priority strict
```

#### Environment Activation Not Working

**Problem**: `conda activate` doesn't work

**Solutions**:

```bash
# Initialize conda for your shell
conda init bash  # or zsh, fish, powershell

# Restart shell or source
source ~/.bashrc

# Manual activation
source /path/to/conda/etc/profile.d/conda.sh
conda activate myenv
```

#### Package Conflicts

**Problem**: Conflicting package requirements

**Solutions**:

```bash
# Show detailed conflict information
conda install package-name --verbose

# Use specific versions
conda install "package-a=1.0" "package-b=2.0"

# Try conda-forge
conda install -c conda-forge package-name

# Use mamba for better resolution
mamba install package-name

# Create fresh environment
conda create -n newenv python=3.11 package-name
```

#### Corrupted Environment

**Problem**: Environment is broken or inconsistent

**Solutions**:

```bash
# List revisions
conda list --revisions

# Revert to working revision
conda install --revision 5

# Or recreate from environment.yml
conda env remove -n myenv
conda env create -f environment.yml

# Nuclear option: remove and reinstall
rm -rf ~/miniconda3/envs/myenv
conda create -n myenv python=3.11
```

#### pip and conda Conflicts

**Problem**: Packages conflict between pip and conda

**Solutions**:

```bash
# Install conda packages first
conda install numpy pandas matplotlib

# Then pip packages
pip install package-not-in-conda

# Verify no conflicts
conda list | grep pypi

# If issues, recreate environment
conda env export > backup.yml
conda env remove -n myenv
conda env create -f backup.yml
```

### Debug Mode

```bash
# Verbose output
conda install --verbose package-name

# Very verbose
conda install -vv package-name

# Debug mode
conda install --debug package-name

# Show configuration
conda config --show
conda config --show-sources
```

## Performance Optimization

### Using mamba

mamba is a drop-in replacement for conda with much faster solving:

```bash
# Install mamba
conda install -n base mamba

# Use mamba instead of conda
mamba install numpy pandas
mamba create -n myenv python=3.11
mamba env create -f environment.yml

# All conda commands work with mamba
mamba list
mamba update --all
```

**Speed improvements**: 10-100x faster dependency resolution

### Using libmamba Solver

```bash
# Install libmamba solver
conda install -n base conda-libmamba-solver

# Configure conda to use it
conda config --set solver libmamba

# Now conda uses fast libmamba solver
conda install numpy  # Much faster
```

### Caching Strategies

```bash
# Check cache size
conda clean --all --dry-run

# Clean strategically
conda clean --packages  # Remove unused packages
conda clean --tarballs  # Remove package archives

# Configure cache
conda config --set pkgs_dirs /path/to/cache
```

## CI/CD Integration

### GitHub Actions

```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: conda-incubator/setup-miniconda@v3
        with:
          auto-activate-base: false
          activate-environment: myenv
          environment-file: environment.yml
          python-version: 3.11
      
      - name: Run tests
        shell: bash -l {0}
        run: |
          conda info
          conda list
          pytest
```

### GitLab CI

```yaml
test:
  image: continuumio/miniconda3
  before_script:
    - conda env create -f environment.yml
    - source activate myenv
  script:
    - pytest
    - conda list
```

### Docker

```dockerfile
FROM continuumio/miniconda3

WORKDIR /app

# Create environment
COPY environment.yml .
RUN conda env create -f environment.yml

# Activate environment
SHELL ["conda", "run", "-n", "myenv", "/bin/bash", "-c"]

# Install application
COPY . .

# Run application
CMD ["conda", "run", "-n", "myenv", "python", "app.py"]
```

### Optimized Docker

```dockerfile
FROM continuumio/miniconda3

# Install mamba for speed
RUN conda install -n base mamba

WORKDIR /app

# Create environment with mamba
COPY environment.yml .
RUN mamba env create -f environment.yml && \
    conda clean --all --yes

# Use environment
SHELL ["conda", "run", "-n", "myenv", "/bin/bash", "-c"]

COPY . .

CMD ["conda", "run", "--no-capture-output", "-n", "myenv", "python", "app.py"]
```

## Comparison with Other Tools

### conda vs pip

| Feature | conda | pip |
| --- | --- | --- |
| **Language Support** | Multi-language | Python only |
| **Binary Dependencies** | Excellent | Limited |
| **Environment Management** | Built-in | External (venv) |
| **Python Version Management** | Built-in | No |
| **Package Resolution** | SAT solver | Backtracking |
| **Speed** | Moderate (fast with mamba) | Moderate |
| **Package Count** | ~20,000 (conda-forge) | 500,000+ (PyPI) |
| **Best For** | Data science, compiled code | Pure Python packages |

### conda vs virtualenv

| Feature | conda | virtualenv |
| --- | --- | --- |
| **Purpose** | Package + environment manager | Environment only |
| **Python Management** | Manages Python versions | Uses existing Python |
| **Package Installation** | Built-in | Requires pip |
| **Binary Dependencies** | Yes | No |
| **Cross-Platform** | Excellent | Excellent |
| **Speed** | Environment creation slower | Faster |

### conda vs Poetry

| Feature | conda | Poetry |
| --- | --- | --- |
| **Package Management** | Yes | Yes |
| **Dependency Resolution** | SAT solver | Modern resolver |
| **Lock Files** | environment.yml | poetry.lock |
| **Build System** | No | Yes |
| **Binary Dependencies** | Excellent | Limited |
| **Python Management** | Built-in | External (pyenv) |
| **Best For** | Data science | Python development |

## Best Practices Summary

### Do's

✅ **Use environment.yml** for reproducibility
✅ **Install conda packages first**, then pip
✅ **Use conda-forge** for more packages and updates
✅ **Pin Python version** in environment.yml
✅ **Use mamba** for faster operations
✅ **Export with --from-history** for cross-platform
✅ **Create separate environments** per project
✅ **Use descriptive environment names**

### Don'ts

❌ **Don't install packages in base** environment
❌ **Don't mix pip and conda** without care
❌ **Don't use `pip install --user`** in conda environments
❌ **Don't ignore environment.yml** in version control
❌ **Don't use `sudo` with conda**
❌ **Don't install conda in system Python**

## Advanced Topics

### Building Custom Packages

```bash
# Install conda-build
conda install conda-build

# Build package
conda build my-package/

# Install local package
conda install --use-local my-package

# Upload to channel
anaconda upload /path/to/package.tar.bz2
```

### Private Channels

```bash
# Add private channel
conda config --add channels https://conda.company.com

# Use authentication
conda config --set channel_alias https://user:password@conda.company.com

# Or use token
conda config --set anaconda_upload token
```

### Custom Environments Path

```bash
# Set custom envs directory
conda config --add envs_dirs /path/to/envs

# Create environment there
conda create -p /path/to/envs/myenv python=3.11

# Activate by path
conda activate /path/to/envs/myenv
```

## Migration Guides

### From pip to conda

```bash
# 1. Export pip requirements
pip freeze > requirements.txt

# 2. Create conda environment
conda create -n myenv python=3.11

# 3. Install available packages with conda
conda activate myenv
conda install numpy pandas matplotlib

# 4. Install remaining with pip
pip install -r remaining-requirements.txt

# 5. Export conda environment
conda env export > environment.yml
```

### From virtualenv to conda

```bash
# 1. Export virtualenv packages
pip freeze > requirements.txt

# 2. Create conda environment
conda create -n myenv python=3.11

# 3. Install packages
conda activate myenv
conda install --file requirements.txt

# 4. Or convert to environment.yml
cat > environment.yml << EOF
name: myenv
channels:
  - conda-forge
dependencies:
  - python=3.11
  - pip
  - pip:
    $(cat requirements.txt | sed 's/^/    - /')
EOF
```

## See Also

- [conda Official Documentation](https://docs.conda.io/)
- [conda-forge](https://conda-forge.org/)
- [Anaconda Distribution](https://www.anaconda.com/products/distribution)
- [Miniconda](https://docs.conda.io/en/latest/miniconda.html)
- [mamba Documentation](https://mamba.readthedocs.io/)
- [pip Documentation](pip.md)
- [Package Management Overview](index.md)

## Additional Resources

### Official Resources

- [conda Cheat Sheet](https://docs.conda.io/projects/conda/en/latest/user-guide/cheatsheet.html)
- [conda-forge Documentation](https://conda-forge.org/docs/)
- [Anaconda Package Repository](https://anaconda.org/)
- [conda GitHub](https://github.com/conda/conda)

### Community

- [conda Discourse](https://conda.discourse.group/)
- [conda-forge Gitter](https://gitter.im/conda-forge/conda-forge.github.io)
- [Stack Overflow conda tag](https://stackoverflow.com/questions/tagged/conda)

### Tutorials

- [Getting Started with conda](https://docs.conda.io/projects/conda/en/latest/user-guide/getting-started.html)
- [Managing Environments](https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html)
- [Creating Packages](https://docs.conda.io/projects/conda-build/en/latest/)

### Related Tools

- [mamba](https://mamba.readthedocs.io/) - Fast conda alternative
- [micromamba](https://mamba.readthedocs.io/en/latest/user_guide/micromamba.html) - Standalone conda replacement
- [conda-lock](https://github.com/conda/conda-lock) - Generate lock files
- [pixi](https://github.com/prefix-dev/pixi) - Modern package management
