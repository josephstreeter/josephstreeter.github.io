---
title: virtualenv - Python Virtual Environment Tool
description: Comprehensive guide to virtualenv for creating isolated Python environments, managing dependencies, and preventing package conflicts
---

virtualenv is a tool to create isolated Python environments, allowing different projects to have separate dependencies without conflicts. It's one of the most widely used tools in the Python ecosystem for dependency isolation and project management.

## Overview

virtualenv creates isolated Python environments by copying or linking the Python binary and creating a directory structure that houses separate installations of libraries and dependencies. This isolation prevents conflicts between project dependencies and protects the system Python installation from modifications.

Unlike the built-in `venv` module (available in Python 3.3+), virtualenv:

- Works with older Python versions (2.7+)
- Creates environments faster in many scenarios
- Offers more configuration options and features
- Provides better cross-platform consistency
- Supports discovery of different Python interpreters
- Has a more active development and feature set

## Key Features

### Environment Isolation

- **Separate package installations**: Each environment has its own site-packages
- **Python version control**: Different environments can use different Python versions
- **Dependency independence**: Projects don't interfere with each other
- **System protection**: System Python remains untouched

### Flexibility

- **Multiple Python versions**: Easily switch between Python 2.7, 3.x versions
- **Customizable environments**: Configure environment behavior extensively
- **Seed packages**: Pre-install packages during creation
- **Custom prompts**: Personalize shell prompts per environment

### Performance

- **Fast creation**: Optimized environment setup
- **Symlink support**: Option to symlink instead of copy for speed
- **App data integration**: Reuses pip and setuptools across environments

### Cross-Platform

- **Windows, macOS, Linux**: Consistent behavior across platforms
- **Shell support**: Works with bash, zsh, fish, PowerShell, cmd
- **Path handling**: Robust path management on all systems

## Installation

### Using pip

```bash
# Install virtualenv
pip install virtualenv

# Or install for user only
pip install --user virtualenv

# Install specific version
pip install virtualenv==20.25.0
```

### Using package managers

```bash
# Ubuntu/Debian
sudo apt-get install python3-virtualenv

# Fedora/RHEL
sudo dnf install python3-virtualenv

# macOS with Homebrew
brew install virtualenv

# Arch Linux
sudo pacman -S python-virtualenv
```

### Verify Installation

```bash
# Check version
virtualenv --version

# Show help
virtualenv --help
```

## Basic Usage

### Creating Virtual Environments

```bash
# Create environment with default Python
virtualenv myenv

# Create with specific Python version
virtualenv -p python3.11 myenv

# Create with full path to Python
virtualenv -p /usr/bin/python3.11 myenv

# Create in current directory
virtualenv .

# Create with custom name
virtualenv my-project-env
```

### Activating Environments

#### Linux/macOS

```bash
# Activate environment
source myenv/bin/activate

# Shorter alternative
. myenv/bin/activate

# Check activation (prompt changes)
which python
```

#### Windows

```cmd
# Command Prompt
myenv\Scripts\activate.bat

# PowerShell
myenv\Scripts\Activate.ps1
```

#### Fish Shell

```fish
# Fish shell activation
source myenv/bin/activate.fish
```

#### Csh/Tcsh

```csh
# Csh/tcsh activation
source myenv/bin/activate.csh
```

### Deactivating Environments

```bash
# Deactivate current environment (works on all platforms)
deactivate

# Shell returns to system Python
```

### Basic Workflow

```bash
# 1. Create environment
virtualenv myproject

# 2. Activate
source myproject/bin/activate

# 3. Install packages
pip install requests flask numpy

# 4. Work on project
python app.py

# 5. Freeze dependencies
pip freeze > requirements.txt

# 6. Deactivate when done
deactivate
```

## Advanced Features

### Python Version Selection

```bash
# Use specific Python version
virtualenv -p python3.9 env39
virtualenv -p python3.11 env311

# Use pyenv Python
virtualenv -p ~/.pyenv/versions/3.11.5/bin/python myenv

# Discover Python by version
virtualenv --python=3.11 myenv

# List available Python interpreters
virtualenv --python-list
```

### Environment Options

```bash
# No pip (minimal environment)
virtualenv --no-pip myenv

# No setuptools
virtualenv --no-setuptools myenv

# No wheel
virtualenv --no-wheel myenv

# Download packages
virtualenv --download myenv

# Never download (use bundled)
virtualenv --never-download myenv

# Copy files instead of symlink
virtualenv --always-copy myenv

# System site-packages access
virtualenv --system-site-packages myenv
```

### Custom Prompts

```bash
# Custom prompt prefix
virtualenv --prompt="[MyProject] " myenv

# Custom prompt with interpolation
virtualenv --prompt="({project_name}) " myenv

# Disable prompt modification
virtualenv --no-prompt myenv
```

### Seeding Packages

```bash
# Pre-install packages
virtualenv --seed-app-data=yes myenv

# Use specific pip version
virtualenv --pip=20.3.4 myenv

# Use specific setuptools version
virtualenv --setuptools=65.0.0 myenv
```

## Configuration

### Configuration Files

virtualenv reads configuration from:

1. **Environment variable**: `VIRTUALENV_CONFIG_FILE`
2. **Local config**: `$PWD/virtualenv.ini` or `$PWD/.virtualenv`
3. **User config** (Unix): `~/.config/virtualenv/virtualenv.ini`
4. **User config** (macOS): `~/Library/Application Support/virtualenv/virtualenv.ini`
5. **User config** (Windows): `%APPDATA%\virtualenv\virtualenv.ini`

### Example Configuration

Create `~/.config/virtualenv/virtualenv.ini`:

```ini
[virtualenv]
# Use Python 3.11 by default
python = /usr/bin/python3.11

# Always copy files
always-copy = true

# Custom prompt
prompt = ({project_name})

# Download packages
download = true

# Include system site-packages
system-site-packages = false

# Don't modify prompt
no-prompt = false
```

### Environment Variables

```bash
# Custom config file location
export VIRTUALENV_CONFIG_FILE=/path/to/config.ini

# Override Python version
export VIRTUALENV_PYTHON=/usr/bin/python3.11

# Set download behavior
export VIRTUALENV_DOWNLOAD=true

# Set prompt
export VIRTUALENV_PROMPT="[MyProject] "
```

## Project Workflows

### Starting a New Project

```bash
# 1. Create project directory
mkdir myproject
cd myproject

# 2. Initialize Git
git init

# 3. Create virtual environment
virtualenv .venv

# 4. Add to .gitignore
echo ".venv/" >> .gitignore

# 5. Activate environment
source .venv/bin/activate

# 6. Install dependencies
pip install flask requests sqlalchemy

# 7. Freeze requirements
pip freeze > requirements.txt

# 8. Commit
git add .gitignore requirements.txt
git commit -m "Initial project setup"
```

### Joining an Existing Project

```bash
# 1. Clone repository
git clone https://github.com/company/project.git
cd project

# 2. Create virtual environment
virtualenv .venv

# 3. Activate
source .venv/bin/activate

# 4. Install dependencies
pip install -r requirements.txt

# 5. Verify setup
python manage.py check
pytest
```

### Multiple Environments

```bash
# Create environments for different Python versions
virtualenv -p python3.9 .venv-py39
virtualenv -p python3.10 .venv-py310
virtualenv -p python3.11 .venv-py311

# Test across versions
source .venv-py39/bin/activate
pytest
deactivate

source .venv-py310/bin/activate
pytest
deactivate

source .venv-py311/bin/activate
pytest
deactivate
```

### Development vs Production

```bash
# Development environment
virtualenv .venv-dev
source .venv-dev/bin/activate
pip install -r requirements-dev.txt

# Production environment (minimal)
virtualenv .venv-prod
source .venv-prod/bin/activate
pip install -r requirements.txt
```

## virtualenv vs venv

### Feature Comparison

| Feature | virtualenv | venv |
| --- | --- | --- |
| **Python Version** | 2.7+ and 3.3+ | 3.3+ only |
| **Included with Python** | No (pip install) | Yes (built-in) |
| **Speed** | Faster (typically) | Moderate |
| **Python Discovery** | Advanced | Basic |
| **Configuration** | Extensive | Limited |
| **Multiple Python Versions** | Excellent | Limited |
| **Upgrade Path** | Regular updates | Python version tied |
| **Features** | More features | Minimal |

### When to Use virtualenv

**Use virtualenv when**:

- Supporting Python 2.7 or older Python 3.x
- Need faster environment creation
- Require advanced configuration options
- Working with multiple Python versions
- Want latest features and updates
- Need better cross-platform consistency
- Using tools that integrate with virtualenv

### When to Use venv

**Use venv when**:

- Python 3.3+ is sufficient
- Prefer built-in tools (no external dependencies)
- Want simpler, minimal setup
- Following official Python recommendations
- Don't need advanced features

### Command Comparison

```bash
# virtualenv
virtualenv myenv
source myenv/bin/activate

# venv
python -m venv myenv
source myenv/bin/activate

# Both have similar activation/deactivation
```

## Integration with Tools

### pip Integration

```bash
# Create and install in one step
virtualenv myenv && source myenv/bin/activate && pip install -r requirements.txt

# Upgrade pip in environment
pip install --upgrade pip

# Install editable packages
pip install -e /path/to/package
```

### IDE Integration

#### VS Code

```json
// .vscode/settings.json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
  "python.terminal.activateEnvironment": true
}
```

#### PyCharm

1. File → Settings → Project → Python Interpreter
2. Add Interpreter → Virtualenv Environment
3. Select existing environment or create new

#### Vim/Neovim

```vim
" Activate virtualenv in vim
let g:python3_host_prog = '/path/to/.venv/bin/python'
```

### Shell Integration

#### Bash/Zsh

```bash
# Add to ~/.bashrc or ~/.zshrc
# Auto-activate virtualenv when entering directory
function cd() {
  builtin cd "$@"
  if [[ -f .venv/bin/activate ]]; then
    source .venv/bin/activate
  fi
}
```

#### Fish Shell Alternative

```fish
# Add to ~/.config/fish/config.fish
function cd
  builtin cd $argv
  if test -f .venv/bin/activate.fish
    source .venv/bin/activate.fish
  end
end
```

### Docker Integration

```dockerfile
FROM python:3.11-slim

# Install virtualenv
RUN pip install virtualenv

WORKDIR /app

# Create virtual environment
RUN virtualenv /opt/venv

# Activate virtual environment
ENV PATH="/opt/venv/bin:$PATH"

# Install dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["python", "app.py"]
```

## Advanced Use Cases

### Relocatable Environments

```bash
# Create relocatable environment
virtualenv --relocatable myenv

# Move environment
mv myenv /new/location/myenv

# Reactivate
source /new/location/myenv/bin/activate
```

**Note**: Relocatable environments have limitations and aren't recommended for production use.

### Shared Environments

```bash
# Create environment in shared location
virtualenv /shared/envs/myproject

# Team members activate
source /shared/envs/myproject/bin/activate

# Better: Use requirements.txt instead
pip freeze > requirements.txt
# Share requirements.txt, everyone creates own environment
```

### Testing Multiple Python Versions

```bash
# Create test script
cat > test_versions.sh << 'EOF'
#!/bin/bash
for version in 3.9 3.10 3.11 3.12; do
  echo "Testing Python $version"
  virtualenv -p python$version .venv-$version
  source .venv-$version/bin/activate
  pip install -r requirements.txt
  pytest
  deactivate
  rm -rf .venv-$version
done
EOF

chmod +x test_versions.sh
./test_versions.sh
```

### Custom Python Builds

```bash
# Use custom compiled Python
virtualenv -p /opt/python-3.11-custom/bin/python myenv

# Use Python with optimizations
virtualenv -p /usr/local/bin/python3.11-optimized myenv
```

## Troubleshooting

### Common Issues

#### Environment Not Activating

**Problem**: `source myenv/bin/activate` doesn't work

**Solutions**:

```bash
# Check if file exists
ls -la myenv/bin/activate

# Use full path
source /full/path/to/myenv/bin/activate

# Check shell
echo $SHELL

# Try alternative activation
. myenv/bin/activate

# Windows PowerShell: Enable scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Wrong Python Version

**Problem**: Environment uses wrong Python version

**Solutions**:

```bash
# Check Python in environment
which python
python --version

# Recreate with specific Python
rm -rf myenv
virtualenv -p python3.11 myenv

# Verify
source myenv/bin/activate
python --version
```

#### Permission Errors

**Problem**: Cannot create environment due to permissions

**Solutions**:

```bash
# Use --user for virtualenv installation
pip install --user virtualenv

# Create in home directory
virtualenv ~/myenv

# Check directory permissions
ls -la /path/to/project

# Avoid sudo
# Don't use: sudo virtualenv myenv
```

#### pip Not Found

**Problem**: pip not available in environment

**Solutions**:

```bash
# Create with pip explicitly
virtualenv --pip myenv

# Install pip manually
source myenv/bin/activate
python -m ensurepip
python -m pip install --upgrade pip

# Verify
which pip
pip --version
```

#### SSL Certificate Errors

**Problem**: SSL errors when creating environment

**Solutions**:

```bash
# Use system certificates
virtualenv --never-download myenv

# Or update certificates
pip install --upgrade certifi

# Set certificate path
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
virtualenv myenv
```

### Debug Mode

```bash
# Verbose output
virtualenv -vvv myenv

# Show more information
virtualenv --verbose myenv

# Check system info
virtualenv --system
```

## Performance Optimization

### Fast Environment Creation

```bash
# Use symlinks (faster)
virtualenv myenv  # Default on Unix

# Explicit symlink
virtualenv --symlinks myenv

# Copy only when needed
virtualenv --always-copy myenv  # Slower but more portable
```

### Caching

```bash
# Check app data location
virtualenv --app-data

# Clear cache
rm -rf ~/.local/share/virtualenv/*

# Use specific app data
virtualenv --app-data /tmp/venv-cache myenv
```

### Parallel Environments

```bash
# Create multiple environments in parallel
virtualenv env1 & \
virtualenv env2 & \
virtualenv env3 & \
wait
```

## Best Practices

### Do's

✅ **Use descriptive environment names**: `.venv`, `venv`, or project-specific
✅ **Add to .gitignore**: Never commit environments to version control
✅ **Use requirements.txt**: Share dependencies, not environments
✅ **Activate before installing**: Always activate before `pip install`
✅ **Keep environments small**: Only install needed packages
✅ **Recreate when needed**: Environments are disposable
✅ **Document dependencies**: Maintain accurate requirements.txt
✅ **Use virtual environments**: Even for simple scripts

### Don'ts

❌ **Don't commit environments**: Add to .gitignore
❌ **Don't use sudo**: Install virtualenv with pip, not system package manager
❌ **Don't move environments**: Recreate instead
❌ **Don't share environments**: Each developer creates their own
❌ **Don't install globally**: Use virtual environments
❌ **Don't mix Python versions**: One version per environment
❌ **Don't activate base**: Keep system Python clean

### Project Structure

```text
myproject/
├── .venv/              # Virtual environment (in .gitignore)
├── .gitignore          # Includes .venv/
├── README.md           # Setup instructions
├── requirements.txt    # Production dependencies
├── requirements-dev.txt # Development dependencies
├── src/               # Source code
│   └── myproject/
├── tests/             # Tests
└── setup.py           # Package configuration
```

### .gitignore Template

```gitignore
# Virtual environments
.venv/
venv/
ENV/
env/
.virtualenv/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
```

## CI/CD Integration

### GitHub Actions

```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ['3.9', '3.10', '3.11']
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ matrix.python-version }}
      
      - name: Install virtualenv
        run: pip install virtualenv
      
      - name: Create virtual environment
        run: virtualenv .venv
      
      - name: Install dependencies
        run: |
          source .venv/bin/activate
          pip install -r requirements.txt
          pip install -r requirements-dev.txt
      
      - name: Run tests
        run: |
          source .venv/bin/activate
          pytest
          
      - name: Lint
        run: |
          source .venv/bin/activate
          ruff check .
```

### GitLab CI

```yaml
stages:
  - test

test:
  stage: test
  image: python:3.11
  before_script:
    - pip install virtualenv
    - virtualenv .venv
    - source .venv/bin/activate
    - pip install -r requirements.txt
  script:
    - pytest
    - coverage report
  cache:
    paths:
      - .venv/
```

### Jenkins

```groovy
pipeline {
  agent any
  
  stages {
    stage('Setup') {
      steps {
        sh 'pip install virtualenv'
        sh 'virtualenv .venv'
        sh 'source .venv/bin/activate && pip install -r requirements.txt'
      }
    }
    
    stage('Test') {
      steps {
        sh 'source .venv/bin/activate && pytest'
      }
    }
  }
}
```

## Migration Guides

### From System Python

```bash
# 1. Document current packages
pip freeze > old-requirements.txt

# 2. Create virtual environment
virtualenv .venv

# 3. Activate
source .venv/bin/activate

# 4. Install needed packages
pip install -r requirements.txt

# 5. Test application
python app.py

# 6. Document in README
echo "Setup: virtualenv .venv && source .venv/bin/activate && pip install -r requirements.txt" >> README.md
```

### From venv to virtualenv

```bash
# 1. Export from venv
source venv/bin/activate
pip freeze > requirements.txt
deactivate

# 2. Create with virtualenv
virtualenv .venv

# 3. Install dependencies
source .venv/bin/activate
pip install -r requirements.txt

# 4. Verify
python app.py

# 5. Remove old venv
rm -rf venv/
```

### From conda to virtualenv

```bash
# 1. Export conda environment
conda list --export > conda-packages.txt

# 2. Extract pip packages
conda list --export | grep pypi > requirements.txt

# 3. Create virtualenv
virtualenv .venv

# 4. Activate and install
source .venv/bin/activate
pip install -r requirements.txt

# 5. Add conda-specific packages manually
pip install numpy  # etc.
```

## Automation and Helpers

### Automatic Activation

#### direnv

```bash
# Install direnv
# Ubuntu/Debian: sudo apt-get install direnv
# macOS: brew install direnv

# Add to shell config
eval "$(direnv hook bash)"  # For bash
eval "$(direnv hook zsh)"   # For zsh

# Create .envrc in project
echo 'layout python' > .envrc

# Allow directory
direnv allow

# Auto-activates when entering directory
```

#### autoenv

```bash
# Install
pip install autoenv

# Add to ~/.bashrc
source ~/.autoenv/activate.sh

# Create .env file
echo 'source .venv/bin/activate' > .env

# Auto-activates when entering directory
```

### Wrapper Scripts

```bash
# Create activate.sh
cat > activate.sh << 'EOF'
#!/bin/bash
if [ ! -d ".venv" ]; then
  echo "Creating virtual environment..."
  virtualenv .venv
  source .venv/bin/activate
  pip install -r requirements.txt
else
  source .venv/bin/activate
fi
EOF

chmod +x activate.sh

# Use it
./activate.sh
```

### Make Targets

```makefile
# Makefile
.PHONY: venv install test clean

venv:
    virtualenv .venv
    source .venv/bin/activate && pip install --upgrade pip

install: venv
    source .venv/bin/activate && pip install -r requirements.txt

test:
    source .venv/bin/activate && pytest

clean:
    rm -rf .venv
    find . -type d -name __pycache__ -exec rm -rf {} +
    find . -type f -name "*.pyc" -delete
```

Usage:

```bash
make install  # Setup environment
make test     # Run tests
make clean    # Remove environment
```

## See Also

- [virtualenv Official Documentation](https://virtualenv.pypa.io/)
- [venv Documentation](https://docs.python.org/3/library/venv.html)
- [pip Documentation](pip.md)
- [conda Documentation](conda.md)
- [Package Management Overview](index.md)

## Additional Resources

### Official Documentation

- [virtualenv User Guide](https://virtualenv.pypa.io/en/latest/user_guide.html)
- [virtualenv CLI Reference](https://virtualenv.pypa.io/en/latest/cli_interface.html)
- [virtualenv Configuration](https://virtualenv.pypa.io/en/latest/user_guide.html#configuration-file)

### Community Resources

- [virtualenv GitHub Repository](https://github.com/pypa/virtualenv)
- [virtualenv Issue Tracker](https://github.com/pypa/virtualenv/issues)
- [Python Packaging User Guide](https://packaging.python.org/)
- [PyPA (Python Packaging Authority)](https://www.pypa.io/)

### Tutorials

- [Real Python: Virtual Environments](https://realpython.com/python-virtual-environments-a-primer/)
- [Python Packaging Guide: Virtual Environments](https://packaging.python.org/guides/installing-using-pip-and-virtual-environments/)

### Related Tools

- [virtualenvwrapper](https://virtualenvwrapper.readthedocs.io/) - Wrapper for managing multiple virtualenvs
- [pyenv](https://github.com/pyenv/pyenv) - Python version management
- [pipx](https://github.com/pypa/pipx) - Install Python applications in isolated environments
- [tox](https://tox.wiki/) - Test automation across environments
