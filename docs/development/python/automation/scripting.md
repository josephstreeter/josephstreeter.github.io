---
title: "Python Scripting and Automation"
description: "Comprehensive guide to Python scripting, automation, command-line tools, file operations, system integration, and best practices"
tags: ["python", "scripting", "automation", "cli", "devops", "system-administration"]
category: "development"
difficulty: "intermediate"
last_updated: "2026-01-04"
---

## Python Scripting and Automation

Python is one of the most powerful and popular languages for scripting and automation tasks. Its clean syntax, extensive standard library, and cross-platform compatibility make it ideal for system administration, DevOps, data processing, and workflow automation. This guide covers essential concepts, patterns, and best practices for creating robust Python scripts.

## Why Python for Scripting?

### Advantages

- **Readability**: Clear, expressive syntax that's easy to write and maintain
- **Cross-Platform**: Write once, run on Windows, macOS, and Linux
- **Rich Standard Library**: Built-in modules for file I/O, networking, system operations, and more
- **Extensive Ecosystem**: Third-party packages for virtually any automation task
- **Error Handling**: Robust exception handling mechanisms
- **Integration**: Easy to integrate with other languages and tools
- **Rapid Development**: Quick prototyping and deployment

### Common Use Cases

- System administration and configuration management
- File and data processing automation
- Web scraping and API interaction
- Log file analysis and monitoring
- Backup and maintenance scripts
- Database operations and ETL processes
- Cloud infrastructure automation
- CI/CD pipeline scripts

## Script Structure and Best Practices

### Basic Script Structure

Every well-designed Python script should follow this structure:

```python
#!/usr/bin/env python3
"""
Script description and purpose.

This script performs automated tasks including...
"""

import sys
import os
from pathlib import Path
import argparse
import logging

# Constants
VERSION = "1.0.0"
DEFAULT_CONFIG = "/etc/myapp/config.ini"

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('script.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Script description",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        '-i', '--input',
        required=True,
        help='Input file path'
    )
    parser.add_argument(
        '-o', '--output',
        default='output.txt',
        help='Output file path (default: output.txt)'
    )
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Enable verbose output'
    )
    parser.add_argument(
        '--version',
        action='version',
        version=f'%(prog)s {VERSION}'
    )
    return parser.parse_args()


def validate_input(input_path):
    """Validate input file exists and is readable."""
    if not os.path.exists(input_path):
        raise FileNotFoundError(f"Input file not found: {input_path}")
    if not os.access(input_path, os.R_OK):
        raise PermissionError(f"Cannot read input file: {input_path}")


def process_data(input_path, output_path):
    """Main processing logic."""
    logger.info(f"Processing {input_path}")
    
    try:
        # Your processing logic here
        with open(input_path, 'r', encoding='utf-8') as f:
            data = f.read()
        
        # Process data...
        result = data.upper()  # Example transformation
        
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(result)
        
        logger.info(f"Results written to {output_path}")
        return True
    except Exception as e:
        logger.error(f"Error processing data: {e}")
        raise


def main():
    """Main entry point for the script."""
    try:
        args = parse_arguments()
        
        if args.verbose:
            logger.setLevel(logging.DEBUG)
        
        logger.info("Script started")
        
        validate_input(args.input)
        process_data(args.input, args.output)
        
        logger.info("Script completed successfully")
        return 0
    
    except KeyboardInterrupt:
        logger.warning("Script interrupted by user")
        return 130
    except Exception as e:
        logger.error(f"Script failed: {e}", exc_info=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())
```

### Shebang Line

Always include a shebang line for Unix-like systems:

```python
#!/usr/bin/env python3
```

This allows the script to be executed directly (e.g., `./script.py`) after setting execute permissions:

```bash
chmod +x script.py
```

### Docstrings

Include a module-level docstring at the top of your script:

```python
"""
Module name and brief description.

Detailed description of what the script does, its purpose,
and any important usage notes.

Usage:
    python script.py --input data.txt --output result.txt

Author: Your Name
Date: 2026-01-04
Version: 1.0.0
"""
```

## Command-Line Argument Parsing

### Using argparse

The `argparse` module is the standard way to handle command-line arguments:

```python
import argparse

def parse_arguments():
    parser = argparse.ArgumentParser(
        description='Process files and generate reports',
        epilog='Example: python script.py -i input.txt -o output.txt'
    )
    
    # Positional argument
    parser.add_argument(
        'filename',
        help='Input filename to process'
    )
    
    # Optional argument
    parser.add_argument(
        '-o', '--output',
        default='result.txt',
        help='Output filename (default: result.txt)'
    )
    
    # Flag argument
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Enable verbose output'
    )
    
    # Numeric argument with validation
    parser.add_argument(
        '-n', '--number',
        type=int,
        default=10,
        help='Number of iterations (default: 10)'
    )
    
    # Choices
    parser.add_argument(
        '--format',
        choices=['json', 'xml', 'csv'],
        default='json',
        help='Output format'
    )
    
    # Multiple values
    parser.add_argument(
        '--files',
        nargs='+',
        help='Multiple input files'
    )
    
    return parser.parse_args()
```

### Advanced argparse Features

#### Mutually Exclusive Groups

```python
parser = argparse.ArgumentParser()
group = parser.add_mutually_exclusive_group(required=True)
group.add_argument('--start', action='store_true', help='Start service')
group.add_argument('--stop', action='store_true', help='Stop service')
group.add_argument('--restart', action='store_true', help='Restart service')
```

#### Subcommands

```python
parser = argparse.ArgumentParser()
subparsers = parser.add_subparsers(dest='command', help='Available commands')

# Create subcommand
create_parser = subparsers.add_parser('create', help='Create new item')
create_parser.add_argument('name', help='Item name')

# Delete subcommand
delete_parser = subparsers.add_parser('delete', help='Delete item')
delete_parser.add_argument('id', type=int, help='Item ID')

# List subcommand
list_parser = subparsers.add_parser('list', help='List all items')

args = parser.parse_args()

if args.command == 'create':
    create_item(args.name)
elif args.command == 'delete':
    delete_item(args.id)
elif args.command == 'list':
    list_items()
```

### Alternative: click Library

For more complex CLI tools, consider the `click` library:

```python
import click

@click.command()
@click.option('--count', default=1, help='Number of greetings')
@click.option('--name', prompt='Your name', help='The person to greet')
@click.option('--verbose', '-v', is_flag=True, help='Verbose output')
def hello(count, name, verbose):
    """Simple program that greets NAME for a total of COUNT times."""
    for _ in range(count):
        click.echo(f'Hello {name}!')
    if verbose:
        click.echo('Verbose mode enabled')

if __name__ == '__main__':
    hello()
```

## File and Directory Operations

### Using pathlib (Modern Approach)

The `pathlib` module provides object-oriented filesystem paths:

```python
from pathlib import Path

# Create Path object
current_dir = Path.cwd()
home_dir = Path.home()
config_file = Path('/etc/config.ini')

# Check existence
if config_file.exists():
    print("Config file found")

# Check type
if config_file.is_file():
    print("It's a file")
elif config_file.is_dir():
    print("It's a directory")

# Read file
text = config_file.read_text(encoding='utf-8')
data = config_file.read_bytes()

# Write file
output_file = Path('output.txt')
output_file.write_text('Hello, World!', encoding='utf-8')

# Create directory
new_dir = Path('data/processed')
new_dir.mkdir(parents=True, exist_ok=True)

# Iterate over files
data_dir = Path('data')
for txt_file in data_dir.glob('*.txt'):
    print(txt_file.name)

# Recursive glob
for py_file in data_dir.rglob('*.py'):
    print(py_file)

# Join paths
full_path = data_dir / 'subdir' / 'file.txt'

# Get parts
print(full_path.name)        # file.txt
print(full_path.stem)        # file
print(full_path.suffix)      # .txt
print(full_path.parent)      # data/subdir
print(full_path.parts)       # ('data', 'subdir', 'file.txt')
```

### File Operations

```python
import shutil
from pathlib import Path

# Copy file
shutil.copy('source.txt', 'destination.txt')
shutil.copy2('source.txt', 'dest.txt')  # Preserves metadata

# Copy directory tree
shutil.copytree('source_dir', 'dest_dir')

# Move/rename
shutil.move('old_name.txt', 'new_name.txt')

# Remove file
Path('file.txt').unlink(missing_ok=True)  # missing_ok=True prevents error if not exists

# Remove directory
Path('empty_dir').rmdir()  # Only works for empty directories

# Remove directory tree
shutil.rmtree('directory_tree')

# Create temporary files
import tempfile

with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp:
    temp.write('temporary data')
    temp_path = temp.name

# Create temporary directory
with tempfile.TemporaryDirectory() as temp_dir:
    print(f"Working in {temp_dir}")
    # Directory automatically deleted after with block
```

### Safe File Operations

```python
import os
import errno
from pathlib import Path

def safe_create_directory(path):
    """Create directory, handling race conditions."""
    try:
        Path(path).mkdir(parents=True, exist_ok=False)
    except FileExistsError:
        # Already exists, verify it's a directory
        if not Path(path).is_dir():
            raise
    except OSError as e:
        if e.errno != errno.EEXIST:
            raise

def safe_write_file(path, content):
    """Write file atomically using temp file and rename."""
    import tempfile
    
    path = Path(path)
    temp_fd, temp_path = tempfile.mkstemp(
        dir=path.parent,
        prefix=f'.{path.name}.'
    )
    
    try:
        with os.fdopen(temp_fd, 'w', encoding='utf-8') as f:
            f.write(content)
        
        # Atomic rename
        os.replace(temp_path, path)
    except:
        # Clean up temp file on error
        try:
            os.unlink(temp_path)
        except OSError:
            pass
        raise

def read_file_with_fallback(paths, encoding='utf-8'):
    """Read first existing file from list of paths."""
    for path in paths:
        try:
            return Path(path).read_text(encoding=encoding)
        except FileNotFoundError:
            continue
    raise FileNotFoundError(f"None of the files exist: {paths}")
```

### Working with CSV Files

```python
import csv
from pathlib import Path

# Reading CSV
def read_csv(file_path):
    """Read CSV file and return list of dictionaries."""
    with open(file_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        return list(reader)

# Writing CSV
def write_csv(file_path, data, fieldnames):
    """Write list of dictionaries to CSV file."""
    with open(file_path, 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data)

# Example usage
data = [
    {'name': 'Alice', 'age': 30, 'city': 'New York'},
    {'name': 'Bob', 'age': 25, 'city': 'San Francisco'}
]

write_csv('people.csv', data, ['name', 'age', 'city'])
people = read_csv('people.csv')
```

### Working with JSON Files

```python
import json
from pathlib import Path

# Read JSON
def read_json(file_path):
    """Read and parse JSON file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)

# Write JSON
def write_json(file_path, data, indent=2):
    """Write data to JSON file with formatting."""
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=indent, ensure_ascii=False)

# Pretty print JSON
def pretty_print_json(data):
    """Print JSON data in readable format."""
    print(json.dumps(data, indent=2, ensure_ascii=False))
```

## Running System Commands

### Using subprocess Module

```python
import subprocess
import shlex

# Simple command execution
def run_command(command):
    """Run shell command and return output."""
    try:
        result = subprocess.run(
            shlex.split(command),
            capture_output=True,
            text=True,
            check=True,
            timeout=30
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Command failed with exit code {e.returncode}")
        print(f"Error: {e.stderr}")
        raise
    except subprocess.TimeoutExpired:
        print(f"Command timed out after 30 seconds")
        raise

# Run command with shell=True (use cautiously)
def run_shell_command(command):
    """Run command through shell (security risk with untrusted input)."""
    result = subprocess.run(
        command,
        shell=True,
        capture_output=True,
        text=True
    )
    return result.stdout, result.stderr, result.returncode

# Real-time output
def run_with_output(command):
    """Run command and print output in real-time."""
    process = subprocess.Popen(
        shlex.split(command),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=1,
        universal_newlines=True
    )
    
    # Read output line by line
    for line in process.stdout:
        print(line.rstrip())
    
    process.wait()
    return process.returncode

# Pipe commands
def pipe_commands(cmd1, cmd2):
    """Pipe output from one command to another."""
    p1 = subprocess.Popen(
        shlex.split(cmd1),
        stdout=subprocess.PIPE
    )
    p2 = subprocess.Popen(
        shlex.split(cmd2),
        stdin=p1.stdout,
        stdout=subprocess.PIPE
    )
    p1.stdout.close()
    output, _ = p2.communicate()
    return output.decode('utf-8')
```

### Platform-Specific Commands

```python
import platform
import subprocess

def get_disk_usage():
    """Get disk usage using platform-specific command."""
    system = platform.system()
    
    if system == "Windows":
        result = subprocess.run(
            ['wmic', 'logicaldisk', 'get', 'size,freespace,caption'],
            capture_output=True,
            text=True
        )
    elif system == "Linux" or system == "Darwin":
        result = subprocess.run(
            ['df', '-h'],
            capture_output=True,
            text=True
        )
    else:
        raise NotImplementedError(f"Unsupported platform: {system}")
    
    return result.stdout
```

## Error Handling and Logging

### Exception Handling Best Practices

```python
import sys
import traceback
import logging

logger = logging.getLogger(__name__)

def process_file(file_path):
    """Process file with comprehensive error handling."""
    try:
        with open(file_path, 'r') as f:
            data = f.read()
        
        # Process data
        result = transform_data(data)
        
        return result
    
    except FileNotFoundError:
        logger.error(f"File not found: {file_path}")
        raise
    
    except PermissionError:
        logger.error(f"Permission denied: {file_path}")
        raise
    
    except UnicodeDecodeError as e:
        logger.error(f"Encoding error in {file_path}: {e}")
        raise
    
    except Exception as e:
        logger.error(f"Unexpected error processing {file_path}: {e}")
        logger.debug(traceback.format_exc())
        raise

def safe_divide(a, b):
    """Divide with error handling."""
    try:
        return a / b
    except ZeroDivisionError:
        logger.warning("Division by zero attempted")
        return None
    except TypeError as e:
        logger.error(f"Invalid types for division: {e}")
        return None

# Context managers for cleanup
class ManagedResource:
    """Example resource with proper cleanup."""
    
    def __init__(self, resource_name):
        self.resource_name = resource_name
        self.resource = None
    
    def __enter__(self):
        logger.info(f"Acquiring {self.resource_name}")
        self.resource = self._acquire_resource()
        return self.resource
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        logger.info(f"Releasing {self.resource_name}")
        if self.resource:
            self._release_resource(self.resource)
        
        if exc_type is not None:
            logger.error(f"Error in context: {exc_val}")
        
        return False  # Don't suppress exceptions
    
    def _acquire_resource(self):
        # Acquire resource logic
        return "resource_handle"
    
    def _release_resource(self, resource):
        # Release resource logic
        pass
```

### Logging Configuration

```python
import logging
import logging.handlers
from pathlib import Path

def setup_logging(log_file='script.log', level=logging.INFO):
    """Configure comprehensive logging."""
    
    # Create logs directory if needed
    log_path = Path(log_file)
    log_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Create logger
    logger = logging.getLogger()
    logger.setLevel(level)
    
    # Console handler with color support
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_format = logging.Formatter(
        '%(levelname)s - %(message)s'
    )
    console_handler.setFormatter(console_format)
    
    # File handler with detailed format
    file_handler = logging.handlers.RotatingFileHandler(
        log_file,
        maxBytes=10*1024*1024,  # 10MB
        backupCount=5
    )
    file_handler.setLevel(logging.DEBUG)
    file_format = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(funcName)s:%(lineno)d - %(message)s'
    )
    file_handler.setFormatter(file_format)
    
    # Add handlers
    logger.addHandler(console_handler)
    logger.addHandler(file_handler)
    
    return logger

# Usage
logger = setup_logging('app.log', logging.DEBUG)
logger.info("Application started")
logger.debug("Debug information")
logger.warning("Warning message")
logger.error("Error occurred")
logger.critical("Critical issue")
```

### Custom Exceptions

```python
class ScriptError(Exception):
    """Base exception for script errors."""
    pass

class ConfigurationError(ScriptError):
    """Raised when configuration is invalid."""
    pass

class DataProcessingError(ScriptError):
    """Raised when data processing fails."""
    
    def __init__(self, message, data=None):
        super().__init__(message)
        self.data = data

class ValidationError(ScriptError):
    """Raised when input validation fails."""
    
    def __init__(self, field, value, message):
        self.field = field
        self.value = value
        super().__init__(f"Validation failed for {field}: {message}")

# Usage
def validate_config(config):
    """Validate configuration dictionary."""
    if 'api_key' not in config:
        raise ConfigurationError("Missing required 'api_key' in configuration")
    
    if not config['api_key']:
        raise ValidationError('api_key', config['api_key'], "API key cannot be empty")
```

## Configuration Management

### Using ConfigParser for INI Files

```python
import configparser
from pathlib import Path

class ConfigManager:
    """Manage application configuration."""
    
    def __init__(self, config_file='config.ini'):
        self.config_file = Path(config_file)
        self.config = configparser.ConfigParser()
        self.load()
    
    def load(self):
        """Load configuration from file."""
        if self.config_file.exists():
            self.config.read(self.config_file)
        else:
            self._create_default_config()
    
    def _create_default_config(self):
        """Create default configuration."""
        self.config['DEFAULT'] = {
            'debug': 'False',
            'log_level': 'INFO'
        }
        self.config['Database'] = {
            'host': 'localhost',
            'port': '5432',
            'database': 'myapp'
        }
        self.config['API'] = {
            'endpoint': 'https://api.example.com',
            'timeout': '30'
        }
        self.save()
    
    def save(self):
        """Save configuration to file."""
        with open(self.config_file, 'w') as f:
            self.config.write(f)
    
    def get(self, section, option, fallback=None):
        """Get configuration value."""
        return self.config.get(section, option, fallback=fallback)
    
    def get_int(self, section, option, fallback=0):
        """Get integer configuration value."""
        return self.config.getint(section, option, fallback=fallback)
    
    def get_bool(self, section, option, fallback=False):
        """Get boolean configuration value."""
        return self.config.getboolean(section, option, fallback=fallback)
    
    def set(self, section, option, value):
        """Set configuration value."""
        if not self.config.has_section(section):
            self.config.add_section(section)
        self.config.set(section, option, str(value))
        self.save()

# Usage
config = ConfigManager('app.ini')
db_host = config.get('Database', 'host')
api_timeout = config.get_int('API', 'timeout')
debug_mode = config.get_bool('DEFAULT', 'debug')
```

### Using Environment Variables

```python
import os
from pathlib import Path

def get_env_var(name, default=None, required=False, var_type=str):
    """Get environment variable with type conversion and validation."""
    value = os.environ.get(name, default)
    
    if required and value is None:
        raise EnvironmentError(f"Required environment variable '{name}' is not set")
    
    if value is None:
        return None
    
    # Type conversion
    try:
        if var_type == bool:
            return value.lower() in ('true', '1', 'yes', 'on')
        elif var_type == int:
            return int(value)
        elif var_type == float:
            return float(value)
        elif var_type == Path:
            return Path(value)
        else:
            return var_type(value)
    except (ValueError, TypeError) as e:
        raise ValueError(f"Cannot convert env var '{name}' to {var_type}: {e}")

# Load from .env file
def load_env_file(env_file='.env'):
    """Load environment variables from .env file."""
    env_path = Path(env_file)
    if not env_path.exists():
        return
    
    with open(env_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                key, value = line.split('=', 1)
                os.environ[key.strip()] = value.strip()

# Usage
load_env_file()
api_key = get_env_var('API_KEY', required=True)
debug = get_env_var('DEBUG', default='False', var_type=bool)
port = get_env_var('PORT', default='8000', var_type=int)
data_dir = get_env_var('DATA_DIR', default='./data', var_type=Path)
```

## Scheduled Tasks and Automation

### Using schedule Library

```python
import schedule
import time
import logging

logger = logging.getLogger(__name__)

def job_backup():
    """Perform backup task."""
    logger.info("Running backup...")
    # Backup logic here
    logger.info("Backup completed")

def job_cleanup():
    """Clean up old files."""
    logger.info("Running cleanup...")
    # Cleanup logic here
    logger.info("Cleanup completed")

def job_with_params(name, count):
    """Job that accepts parameters."""
    logger.info(f"Processing {name} with count {count}")

# Schedule jobs
schedule.every(10).minutes.do(job_backup)
schedule.every().hour.do(job_cleanup)
schedule.every().day.at("10:30").do(job_backup)
schedule.every().monday.at("13:15").do(job_cleanup)
schedule.every().wednesday.at("21:00").do(job_with_params, "weekly", 7)

# Run scheduler
def run_scheduler():
    """Run the scheduler loop."""
    logger.info("Scheduler started")
    try:
        while True:
            schedule.run_pending()
            time.sleep(60)
    except KeyboardInterrupt:
        logger.info("Scheduler stopped by user")

if __name__ == "__main__":
    run_scheduler()
```

### Using Cron (Linux/macOS)

Create a Python script and add to crontab:

```bash
# Edit crontab
crontab -e

# Add entry (runs every day at 2:30 AM)
30 2 * * * /usr/bin/python3 /path/to/script.py >> /var/log/script.log 2>&1

# Cron syntax: minute hour day month weekday command
# Examples:
# */15 * * * *        # Every 15 minutes
# 0 * * * *           # Every hour
# 0 0 * * *           # Every day at midnight
# 0 0 * * 0           # Every Sunday at midnight
# 0 0 1 * *           # First day of every month
```

### Using Windows Task Scheduler

```python
import win32com.client

def create_windows_task(task_name, script_path, trigger_time='09:00'):
    """Create Windows scheduled task using COM interface."""
    scheduler = win32com.client.Dispatch('Schedule.Service')
    scheduler.Connect()
    
    root_folder = scheduler.GetFolder('\\')
    task_def = scheduler.NewTask(0)
    
    # Set task settings
    task_def.RegistrationInfo.Description = 'Python automation task'
    task_def.Settings.Enabled = True
    task_def.Settings.StopIfGoingOnBatteries = False
    
    # Create trigger (daily)
    trigger = task_def.Triggers.Create(2)  # 2 = TASK_TRIGGER_DAILY
    trigger.StartBoundary = f'2026-01-04T{trigger_time}:00'
    trigger.Enabled = True
    
    # Create action
    action = task_def.Actions.Create(0)  # 0 = TASK_ACTION_EXEC
    action.Path = 'python.exe'
    action.Arguments = script_path
    
    # Register task
    root_folder.RegisterTaskDefinition(
        task_name,
        task_def,
        6,  # TASK_CREATE_OR_UPDATE
        None,
        None,
        3  # TASK_LOGON_INTERACTIVE_TOKEN
    )
```

## Working with APIs

### Using requests Library

```python
import requests
import json
from typing import Dict, Any

class APIClient:
    """Generic API client with error handling and retries."""
    
    def __init__(self, base_url, api_key=None, timeout=30):
        self.base_url = base_url.rstrip('/')
        self.timeout = timeout
        self.session = requests.Session()
        
        if api_key:
            self.session.headers.update({'Authorization': f'Bearer {api_key}'})
        
        self.session.headers.update({
            'Content-Type': 'application/json',
            'User-Agent': 'Python-Automation-Script/1.0'
        })
    
    def get(self, endpoint, params=None):
        """Make GET request."""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        
        try:
            response = self.session.get(
                url,
                params=params,
                timeout=self.timeout
            )
            response.raise_for_status()
            return response.json()
        
        except requests.exceptions.HTTPError as e:
            logger.error(f"HTTP error: {e}")
            logger.error(f"Response: {response.text}")
            raise
        
        except requests.exceptions.ConnectionError:
            logger.error(f"Connection error to {url}")
            raise
        
        except requests.exceptions.Timeout:
            logger.error(f"Request timeout after {self.timeout} seconds")
            raise
        
        except requests.exceptions.RequestException as e:
            logger.error(f"Request failed: {e}")
            raise
    
    def post(self, endpoint, data=None, json_data=None):
        """Make POST request."""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        
        response = self.session.post(
            url,
            data=data,
            json=json_data,
            timeout=self.timeout
        )
        response.raise_for_status()
        return response.json()
    
    def put(self, endpoint, data=None, json_data=None):
        """Make PUT request."""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        
        response = self.session.put(
            url,
            data=data,
            json=json_data,
            timeout=self.timeout
        )
        response.raise_for_status()
        return response.json()
    
    def delete(self, endpoint):
        """Make DELETE request."""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        
        response = self.session.delete(url, timeout=self.timeout)
        response.raise_for_status()
        return response.status_code == 204 or response.json()

# Usage
api = APIClient('https://api.example.com', api_key='your_key')
users = api.get('/users', params={'page': 1, 'limit': 10})
new_user = api.post('/users', json_data={'name': 'John', 'email': 'john@example.com'})
```

### Retry Logic with Exponential Backoff

```python
import time
import requests
from functools import wraps

def retry_with_backoff(max_retries=3, backoff_factor=2, exceptions=(Exception,)):
    """Decorator to retry function with exponential backoff."""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            retry_count = 0
            delay = 1
            
            while retry_count < max_retries:
                try:
                    return func(*args, **kwargs)
                except exceptions as e:
                    retry_count += 1
                    if retry_count >= max_retries:
                        logger.error(f"Max retries ({max_retries}) exceeded")
                        raise
                    
                    wait_time = delay * (backoff_factor ** (retry_count - 1))
                    logger.warning(f"Attempt {retry_count} failed: {e}. Retrying in {wait_time}s...")
                    time.sleep(wait_time)
            
            return func(*args, **kwargs)
        return wrapper
    return decorator

# Usage
@retry_with_backoff(max_retries=3, exceptions=(requests.exceptions.RequestException,))
def fetch_data(url):
    """Fetch data from URL with automatic retries."""
    response = requests.get(url, timeout=10)
    response.raise_for_status()
    return response.json()
```

## Database Operations

### SQLite Database

```python
import sqlite3
from contextlib import contextmanager
from typing import List, Dict, Any

class DatabaseManager:
    """Manage SQLite database operations."""
    
    def __init__(self, db_path='app.db'):
        self.db_path = db_path
        self.initialize_database()
    
    @contextmanager
    def get_connection(self):
        """Context manager for database connection."""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row  # Enable column access by name
        try:
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()
    
    def initialize_database(self):
        """Create database tables."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    username TEXT UNIQUE NOT NULL,
                    email TEXT NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
    
    def insert_user(self, username, email):
        """Insert new user."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                'INSERT INTO users (username, email) VALUES (?, ?)',
                (username, email)
            )
            return cursor.lastrowid
    
    def get_user(self, user_id):
        """Get user by ID."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT * FROM users WHERE id = ?', (user_id,))
            row = cursor.fetchone()
            return dict(row) if row else None
    
    def get_all_users(self):
        """Get all users."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT * FROM users ORDER BY created_at DESC')
            return [dict(row) for row in cursor.fetchall()]
    
    def update_user(self, user_id, username=None, email=None):
        """Update user information."""
        updates = []
        params = []
        
        if username:
            updates.append('username = ?')
            params.append(username)
        if email:
            updates.append('email = ?')
            params.append(email)
        
        if not updates:
            return
        
        params.append(user_id)
        
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                f"UPDATE users SET {', '.join(updates)} WHERE id = ?",
                params
            )
    
    def delete_user(self, user_id):
        """Delete user."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('DELETE FROM users WHERE id = ?', (user_id,))

# Usage
db = DatabaseManager('myapp.db')
user_id = db.insert_user('john_doe', 'john@example.com')
user = db.get_user(user_id)
all_users = db.get_all_users()
```

## Performance Optimization

### Multiprocessing

```python
from multiprocessing import Pool, cpu_count
import time

def process_item(item):
    """Process single item (CPU-intensive task)."""
    # Simulate processing
    result = sum(i * i for i in range(item))
    return result

def parallel_processing(items):
    """Process items in parallel using all CPU cores."""
    with Pool(processes=cpu_count()) as pool:
        results = pool.map(process_item, items)
    return results

# Usage
items = list(range(1000, 2000))
results = parallel_processing(items)
```

### Threading for I/O Operations

```python
from concurrent.futures import ThreadPoolExecutor, as_completed
import requests

def fetch_url(url):
    """Fetch single URL."""
    try:
        response = requests.get(url, timeout=10)
        return url, response.status_code, len(response.content)
    except Exception as e:
        return url, None, str(e)

def fetch_multiple_urls(urls, max_workers=10):
    """Fetch multiple URLs concurrently."""
    results = []
    
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_to_url = {executor.submit(fetch_url, url): url for url in urls}
        
        for future in as_completed(future_to_url):
            results.append(future.result())
    
    return results

# Usage
urls = [
    'https://example.com',
    'https://example.org',
    'https://example.net'
]
results = fetch_multiple_urls(urls)
```

### Caching

```python
from functools import lru_cache
import time

@lru_cache(maxsize=128)
def expensive_computation(n):
    """Cache results of expensive computation."""
    time.sleep(1)  # Simulate expensive operation
    return n * n

# First call is slow
result1 = expensive_computation(10)  # Takes 1 second

# Subsequent calls are instant
result2 = expensive_computation(10)  # Returns immediately from cache
```

## Testing Scripts

### Unit Testing

```python
import unittest
from pathlib import Path
import tempfile
import shutil

class TestFileOperations(unittest.TestCase):
    """Test file operation functions."""
    
    def setUp(self):
        """Set up test environment."""
        self.test_dir = tempfile.mkdtemp()
        self.test_file = Path(self.test_dir) / 'test.txt'
    
    def tearDown(self):
        """Clean up test environment."""
        shutil.rmtree(self.test_dir)
    
    def test_file_creation(self):
        """Test file creation."""
        self.test_file.write_text('test content')
        self.assertTrue(self.test_file.exists())
        self.assertEqual(self.test_file.read_text(), 'test content')
    
    def test_file_not_found(self):
        """Test handling of missing file."""
        with self.assertRaises(FileNotFoundError):
            Path('nonexistent.txt').read_text()
    
    def test_directory_creation(self):
        """Test directory creation."""
        new_dir = Path(self.test_dir) / 'subdir' / 'nested'
        new_dir.mkdir(parents=True, exist_ok=True)
        self.assertTrue(new_dir.is_dir())

if __name__ == '__main__':
    unittest.main()
```

## Security Best Practices

### Input Validation

```python
import re
from pathlib import Path

def validate_email(email):
    """Validate email address format."""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None

def validate_filename(filename):
    """Validate filename for security."""
    # No path traversal
    if '..' in filename or filename.startswith('/'):
        raise ValueError("Invalid filename: path traversal detected")
    
    # Only alphanumeric, dash, underscore, and dot
    if not re.match(r'^[\w\-\.]+$', filename):
        raise ValueError("Invalid filename: contains illegal characters")
    
    return True

def sanitize_path(base_dir, user_path):
    """Ensure path is within base directory."""
    base = Path(base_dir).resolve()
    target = (base / user_path).resolve()
    
    if not target.is_relative_to(base):
        raise ValueError("Path traversal detected")
    
    return target
```

### Secure Password Handling

```python
import hashlib
import secrets
import getpass

def hash_password(password, salt=None):
    """Hash password with salt."""
    if salt is None:
        salt = secrets.token_hex(32)
    
    pwd_hash = hashlib.pbkdf2_hmac(
        'sha256',
        password.encode('utf-8'),
        salt.encode('utf-8'),
        100000
    )
    
    return pwd_hash.hex(), salt

def verify_password(password, stored_hash, salt):
    """Verify password against stored hash."""
    pwd_hash, _ = hash_password(password, salt)
    return pwd_hash == stored_hash

# Secure password input
password = getpass.getpass("Enter password: ")
```

## Complete Example: Log Analyzer Script

```python
#!/usr/bin/env python3
"""
Log Analyzer Script

Analyzes web server log files and generates reports.
"""

import argparse
import logging
import re
from pathlib import Path
from collections import Counter, defaultdict
from datetime import datetime
import json

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class LogAnalyzer:
    """Analyze web server log files."""
    
    def __init__(self, log_file):
        self.log_file = Path(log_file)
        self.entries = []
        self.stats = {
            'total_requests': 0,
            'status_codes': Counter(),
            'ip_addresses': Counter(),
            'user_agents': Counter(),
            'endpoints': Counter(),
            'errors': []
        }
    
    def parse_log_line(self, line):
        """Parse single log line (Apache Common Log Format)."""
        pattern = r'(\S+) \S+ \S+ \[(.*?)\] "(\S+) (\S+) (\S+)" (\d+) (\S+)'
        match = re.match(pattern, line)
        
        if match:
            return {
                'ip': match.group(1),
                'timestamp': match.group(2),
                'method': match.group(3),
                'endpoint': match.group(4),
                'protocol': match.group(5),
                'status': int(match.group(6)),
                'size': match.group(7)
            }
        return None
    
    def analyze(self):
        """Analyze log file."""
        logger.info(f"Analyzing {self.log_file}")
        
        if not self.log_file.exists():
            raise FileNotFoundError(f"Log file not found: {self.log_file}")
        
        with open(self.log_file, 'r', encoding='utf-8', errors='ignore') as f:
            for line_num, line in enumerate(f, 1):
                try:
                    entry = self.parse_log_line(line.strip())
                    if entry:
                        self.entries.append(entry)
                        self._update_stats(entry)
                except Exception as e:
                    logger.warning(f"Error parsing line {line_num}: {e}")
        
        logger.info(f"Analyzed {len(self.entries)} log entries")
    
    def _update_stats(self, entry):
        """Update statistics with entry data."""
        self.stats['total_requests'] += 1
        self.stats['status_codes'][entry['status']] += 1
        self.stats['ip_addresses'][entry['ip']] += 1
        self.stats['endpoints'][entry['endpoint']] += 1
        
        if entry['status'] >= 400:
            self.stats['errors'].append(entry)
    
    def generate_report(self, output_file=None):
        """Generate analysis report."""
        report = []
        report.append("=" * 60)
        report.append("WEB SERVER LOG ANALYSIS REPORT")
        report.append("=" * 60)
        report.append(f"Total Requests: {self.stats['total_requests']}")
        report.append("")
        
        report.append("Top 10 IP Addresses:")
        for ip, count in self.stats['ip_addresses'].most_common(10):
            report.append(f"  {ip}: {count}")
        report.append("")
        
        report.append("Status Code Distribution:")
        for status, count in sorted(self.stats['status_codes'].items()):
            percentage = (count / self.stats['total_requests']) * 100
            report.append(f"  {status}: {count} ({percentage:.1f}%)")
        report.append("")
        
        report.append("Top 10 Endpoints:")
        for endpoint, count in self.stats['endpoints'].most_common(10):
            report.append(f"  {endpoint}: {count}")
        report.append("")
        
        report.append(f"Total Errors (4xx/5xx): {len(self.stats['errors'])}")
        report.append("=" * 60)
        
        report_text = "\n".join(report)
        
        if output_file:
            Path(output_file).write_text(report_text)
            logger.info(f"Report saved to {output_file}")
        
        return report_text

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Analyze web server log files'
    )
    parser.add_argument(
        'log_file',
        help='Path to log file'
    )
    parser.add_argument(
        '-o', '--output',
        help='Output report file (optional)'
    )
    parser.add_argument(
        '--json',
        action='store_true',
        help='Output in JSON format'
    )
    
    args = parser.parse_args()
    
    try:
        analyzer = LogAnalyzer(args.log_file)
        analyzer.analyze()
        
        if args.json:
            output = json.dumps(analyzer.stats, indent=2, default=str)
            if args.output:
                Path(args.output).write_text(output)
            else:
                print(output)
        else:
            report = analyzer.generate_report(args.output)
            if not args.output:
                print(report)
        
        return 0
    
    except Exception as e:
        logger.error(f"Analysis failed: {e}", exc_info=True)
        return 1

if __name__ == "__main__":
    import sys
    sys.exit(main())
```

## Additional Resources

- [Python Official Documentation](https://docs.python.org/3/)
- [Python argparse Module](https://docs.python.org/3/library/argparse.html)
- [Python pathlib Module](https://docs.python.org/3/library/pathlib.html)
- [Python subprocess Module](https://docs.python.org/3/library/subprocess.html)
- [Python logging Module](https://docs.python.org/3/library/logging.html)
- [Python configparser Module](https://docs.python.org/3/library/configparser.html)
- [Requests Library Documentation](https://requests.readthedocs.io/)
- [Click CLI Framework](https://click.palletsprojects.com/)
- [Schedule Library](https://schedule.readthedocs.io/)
- [Real Python Tutorials](https://realpython.com/)

## Summary

Python's rich ecosystem and intuitive syntax make it the ideal choice for automation and scripting tasks. This guide covered:

- Proper script structure and organization
- Command-line argument parsing with argparse
- File and directory operations using pathlib
- System command execution with subprocess
- Comprehensive error handling and logging
- Configuration management techniques
- Task scheduling approaches
- API integration patterns
- Database operations
- Performance optimization strategies
- Security best practices
- Complete real-world examples

By following these patterns and best practices, you can create robust, maintainable automation scripts that handle errors gracefully, log appropriately, and integrate seamlessly into production environments.
