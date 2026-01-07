---
title: "Python Automation - Comprehensive Guide"
description: "Master Python automation techniques for scripting, web scraping, task automation, and system administration"
tags: ["python", "automation", "scripting", "web-scraping", "devops"]
category: "development"
difficulty: "intermediate"
last_updated: "2026-01-04"
author: "Joseph Streeter"
ms.topic: "guide"
keywords: ["python automation", "scripting", "task automation", "web scraping", "process automation", "system administration"]
uid: docs.development.python.automation.index
---

Python has become the de facto language for automation due to its simplicity, extensive library ecosystem, and cross-platform capabilities. This comprehensive guide covers everything from basic scripting to advanced automation patterns, enabling you to automate repetitive tasks, integrate systems, and build robust automation workflows.

## Overview

Automation with Python allows you to eliminate manual, repetitive tasks and create reliable, scalable solutions for everything from file processing to complex system orchestration. Whether you're automating deployment pipelines, scraping data from websites, or managing infrastructure, Python provides the tools and flexibility needed for professional automation.

### Why Python for Automation?

**Simplicity and Readability**:

- Clean, English-like syntax reduces development time
- Minimal boilerplate code compared to Java or C#
- Easy to maintain and modify automation scripts

**Cross-Platform Compatibility**:

- Write once, run on Windows, macOS, and Linux
- Consistent behavior across operating systems
- Native support for system APIs on all platforms

**Extensive Library Ecosystem**:

- 400,000+ packages on PyPI for every automation need
- Battle-tested libraries for common automation tasks
- Active community providing solutions and support

**Integration Capabilities**:

- Native support for REST APIs, databases, and cloud services
- Excellent interoperability with other languages
- Bridges gaps between different systems and platforms

### Automation Use Cases

**Business Process Automation**:

- Report generation and distribution
- Data entry and migration
- Invoice processing and reconciliation
- Email management and filtering
- Scheduled backups and archiving

**DevOps and Infrastructure**:

- Deployment automation
- Configuration management
- Log analysis and monitoring
- Infrastructure provisioning
- CI/CD pipeline orchestration

**Data Operations**:

- ETL (Extract, Transform, Load) pipelines
- Web scraping and data collection
- Data validation and cleaning
- Database synchronization
- API integration and data aggregation

**System Administration**:

- User account management
- File system operations
- Network monitoring
- Security auditing
- Performance monitoring

**Testing and QA**:

- Automated testing frameworks
- Test data generation
- Performance testing
- Integration testing
- Continuous testing pipelines

## Core Automation Concepts

### Script vs. Program

Understanding the distinction helps design appropriate solutions:

**Scripts**:

```python
# Simple, focused automation
import os
import shutil
from datetime import datetime

# Backup script - single purpose
backup_dir = f"/backups/backup_{datetime.now().strftime('%Y%m%d')}"
os.makedirs(backup_dir, exist_ok=True)
shutil.copytree("/data", backup_dir)
print(f"Backup completed: {backup_dir}")
```

**Programs**:

```python
# Complex, structured automation
import argparse
import logging
from pathlib import Path
from typing import List

class BackupManager:
    """Enterprise backup management system"""
    
    def __init__(self, config_path: str):
        self.config = self._load_config(config_path)
        self.logger = self._setup_logging()
    
    def backup(self, sources: List[Path], destination: Path) -> bool:
        """Execute backup with validation and error handling"""
        try:
            self._validate_sources(sources)
            self._create_destination(destination)
            self._perform_backup(sources, destination)
            self._verify_backup(destination)
            return True
        except Exception as e:
            self.logger.error(f"Backup failed: {e}")
            return False

# Full program structure with CLI, config, logging, error handling
```

**When to Use Each**:

- **Scripts**: Quick tasks, one-off jobs, simple workflows
- **Programs**: Production systems, complex logic, enterprise use

### Automation Patterns

#### 1. Event-Driven Automation

Respond to system events or triggers:

```python
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import time

class FileProcessor(FileSystemEventHandler):
    """Process files as they arrive"""
    
    def on_created(self, event):
        if event.is_directory:
            return
        
        if event.src_path.endswith('.csv'):
            self.process_csv(event.src_path)
    
    def process_csv(self, filepath):
        print(f"Processing new file: {filepath}")
        # Perform data processing
        pass

# Monitor directory for new files
observer = Observer()
observer.schedule(FileProcessor(), path='/data/incoming', recursive=False)
observer.start()

try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    observer.stop()
observer.join()
```

#### 2. Scheduled Automation

Execute tasks on a defined schedule:

```python
import schedule
import time
from datetime import datetime

def backup_database():
    """Daily database backup"""
    print(f"Starting backup at {datetime.now()}")
    # Backup logic here
    pass

def send_reports():
    """Weekly report generation"""
    print(f"Generating reports at {datetime.now()}")
    # Report generation logic
    pass

def cleanup_logs():
    """Hourly log cleanup"""
    # Log rotation logic
    pass

# Schedule tasks
schedule.every().day.at("02:00").do(backup_database)
schedule.every().monday.at("08:00").do(send_reports)
schedule.every().hour.do(cleanup_logs)

# Run scheduler
while True:
    schedule.run_pending()
    time.sleep(60)
```

#### 3. Pipeline Automation

Chain multiple operations in sequence:

```python
from typing import Callable, Any
import logging

class Pipeline:
    """Data processing pipeline"""
    
    def __init__(self):
        self.steps: List[Callable] = []
        self.logger = logging.getLogger(__name__)
    
    def add_step(self, func: Callable) -> 'Pipeline':
        """Add processing step to pipeline"""
        self.steps.append(func)
        return self
    
    def execute(self, data: Any) -> Any:
        """Execute all pipeline steps"""
        result = data
        for i, step in enumerate(self.steps, 1):
            try:
                self.logger.info(f"Executing step {i}: {step.__name__}")
                result = step(result)
            except Exception as e:
                self.logger.error(f"Step {i} failed: {e}")
                raise
        return result

# Build and execute pipeline
pipeline = (Pipeline()
    .add_step(extract_data)
    .add_step(validate_data)
    .add_step(transform_data)
    .add_step(load_to_database))

pipeline.execute(input_source)
```

#### 4. Parallel Automation

Execute multiple tasks concurrently:

```python
from concurrent.futures import ThreadPoolExecutor, as_completed
import requests
from typing import List

def process_url(url: str) -> dict:
    """Fetch and process single URL"""
    response = requests.get(url, timeout=10)
    return {
        'url': url,
        'status': response.status_code,
        'size': len(response.content)
    }

def process_urls_parallel(urls: List[str], max_workers: int = 10) -> List[dict]:
    """Process multiple URLs in parallel"""
    results = []
    
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # Submit all tasks
        future_to_url = {executor.submit(process_url, url): url for url in urls}
        
        # Collect results as they complete
        for future in as_completed(future_to_url):
            url = future_to_url[future]
            try:
                result = future.result()
                results.append(result)
            except Exception as e:
                print(f"Error processing {url}: {e}")
    
    return results

# Process 100 URLs concurrently
urls = [f"https://api.example.com/data/{i}" for i in range(100)]
results = process_urls_parallel(urls)
```

## Essential Automation Libraries

### Standard Library Essentials

Python's standard library provides powerful automation capabilities without external dependencies:

#### os and pathlib

File system operations:

```python
import os
from pathlib import Path
import shutil

# Modern path handling with pathlib
data_dir = Path("/data/reports")
data_dir.mkdir(parents=True, exist_ok=True)

# Iterate over files
for file_path in data_dir.glob("*.csv"):
    print(f"Processing: {file_path.name}")
    
    # File operations
    if file_path.stat().st_size > 1_000_000:  # Over 1MB
        archive_path = Path("/archive") / file_path.name
        shutil.move(str(file_path), str(archive_path))

# Environment variables
api_key = os.getenv("API_KEY", "default_key")
os.environ["LOG_LEVEL"] = "DEBUG"
```

#### subprocess

Execute external commands:

```python
import subprocess
from subprocess import PIPE, CalledProcessError

def run_command(command: List[str], timeout: int = 30) -> str:
    """Execute command and return output"""
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=True
        )
        return result.stdout
    except CalledProcessError as e:
        print(f"Command failed: {e.stderr}")
        raise
    except subprocess.TimeoutExpired:
        print(f"Command timed out after {timeout}s")
        raise

# Execute system commands
output = run_command(["git", "status"])
print(output)

# Pipeline commands
result = subprocess.run(
    "ps aux | grep python",
    shell=True,
    capture_output=True,
    text=True
)
```

#### argparse

Command-line interface creation:

```python
import argparse
from pathlib import Path

def create_parser() -> argparse.ArgumentParser:
    """Create CLI argument parser"""
    parser = argparse.ArgumentParser(
        description="Automated backup utility",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        "source",
        type=Path,
        help="Source directory to backup"
    )
    
    parser.add_argument(
        "destination",
        type=Path,
        help="Destination backup directory"
    )
    
    parser.add_argument(
        "-c", "--compress",
        action="store_true",
        help="Compress backup archive"
    )
    
    parser.add_argument(
        "-v", "--verbose",
        action="count",
        default=0,
        help="Increase output verbosity"
    )
    
    parser.add_argument(
        "--exclude",
        nargs="+",
        default=[],
        help="Patterns to exclude from backup"
    )
    
    return parser

# Use the parser
parser = create_parser()
args = parser.parse_args()

if args.verbose > 0:
    print(f"Backing up {args.source} to {args.destination}")
```

#### logging

Robust logging framework:

```python
import logging
from logging.handlers import RotatingFileHandler, TimedRotatingFileHandler
from pathlib import Path

def setup_logging(log_dir: Path, level: str = "INFO") -> logging.Logger:
    """Configure application logging"""
    log_dir.mkdir(parents=True, exist_ok=True)
    
    # Create logger
    logger = logging.getLogger("automation")
    logger.setLevel(getattr(logging, level.upper()))
    
    # Console handler
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_format = logging.Formatter(
        '%(levelname)s: %(message)s'
    )
    console_handler.setFormatter(console_format)
    
    # File handler with rotation
    file_handler = RotatingFileHandler(
        log_dir / "automation.log",
        maxBytes=10*1024*1024,  # 10MB
        backupCount=5
    )
    file_handler.setLevel(logging.DEBUG)
    file_format = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    file_handler.setFormatter(file_format)
    
    logger.addHandler(console_handler)
    logger.addHandler(file_handler)
    
    return logger

# Use logging
logger = setup_logging(Path("/var/log/automation"))
logger.info("Starting automation task")
logger.debug("Processing file: data.csv")
logger.error("Failed to connect to database")
```

### Third-Party Libraries

#### requests

HTTP client for API integration:

```python
import requests
from typing import Dict, Any
import json

class APIClient:
    """Reusable API client"""
    
    def __init__(self, base_url: str, api_key: str):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json'
        })
    
    def get(self, endpoint: str, params: Dict = None) -> Dict[str, Any]:
        """GET request with error handling"""
        url = f"{self.base_url}/{endpoint}"
        response = self.session.get(url, params=params, timeout=10)
        response.raise_for_status()
        return response.json()
    
    def post(self, endpoint: str, data: Dict) -> Dict[str, Any]:
        """POST request"""
        url = f"{self.base_url}/{endpoint}"
        response = self.session.post(url, json=data, timeout=10)
        response.raise_for_status()
        return response.json()
    
    def download_file(self, url: str, filepath: Path) -> None:
        """Download file with progress"""
        response = self.session.get(url, stream=True)
        response.raise_for_status()
        
        with open(filepath, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)

# Use API client
client = APIClient("https://api.example.com", "your_api_key")
users = client.get("users", params={'page': 1, 'limit': 100})
```

#### BeautifulSoup4 and Selenium

Web scraping tools:

```python
from bs4 import BeautifulSoup
import requests
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Static content scraping with BeautifulSoup
def scrape_static_page(url: str) -> list:
    """Scrape data from static HTML page"""
    response = requests.get(url)
    soup = BeautifulSoup(response.content, 'html.parser')
    
    articles = []
    for article in soup.find_all('article', class_='post'):
        title = article.find('h2').text.strip()
        link = article.find('a')['href']
        date = article.find('time')['datetime']
        
        articles.append({
            'title': title,
            'link': link,
            'date': date
        })
    
    return articles

# Dynamic content scraping with Selenium
def scrape_dynamic_page(url: str) -> list:
    """Scrape JavaScript-rendered content"""
    options = webdriver.ChromeOptions()
    options.add_argument('--headless')
    driver = webdriver.Chrome(options=options)
    
    try:
        driver.get(url)
        
        # Wait for content to load
        wait = WebDriverWait(driver, 10)
        wait.until(EC.presence_of_element_located((By.CLASS_NAME, 'post')))
        
        # Extract data
        articles = []
        elements = driver.find_elements(By.CLASS_NAME, 'post')
        
        for element in elements:
            title = element.find_element(By.TAG_NAME, 'h2').text
            link = element.find_element(By.TAG_NAME, 'a').get_attribute('href')
            
            articles.append({'title': title, 'link': link})
        
        return articles
    
    finally:
        driver.quit()
```

#### pandas

Data manipulation and analysis:

```python
import pandas as pd
from pathlib import Path
from typing import List

def process_csv_files(directory: Path, output_file: Path) -> None:
    """Combine and process multiple CSV files"""
    
    # Read all CSV files
    dataframes: List[pd.DataFrame] = []
    for csv_file in directory.glob("*.csv"):
        df = pd.read_csv(csv_file)
        dataframes.append(df)
    
    # Combine dataframes
    combined = pd.concat(dataframes, ignore_index=True)
    
    # Data cleaning
    combined = combined.drop_duplicates()
    combined = combined.dropna(subset=['email', 'name'])
    
    # Data transformation
    combined['date'] = pd.to_datetime(combined['date'])
    combined['year'] = combined['date'].dt.year
    combined['email'] = combined['email'].str.lower()
    
    # Aggregation
    summary = combined.groupby('year').agg({
        'revenue': 'sum',
        'transactions': 'count'
    })
    
    # Export results
    combined.to_csv(output_file, index=False)
    summary.to_excel(output_file.with_suffix('.xlsx'))

# Process data files
process_csv_files(Path("/data/raw"), Path("/data/processed/output.csv"))
```

#### schedule

Task scheduling:

```python
import schedule
import time
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

class TaskScheduler:
    """Manage scheduled automation tasks"""
    
    def __init__(self):
        self.tasks = []
    
    def add_daily_task(self, time_str: str, func, *args, **kwargs):
        """Schedule daily task"""
        job = schedule.every().day.at(time_str).do(func, *args, **kwargs)
        self.tasks.append(job)
        logger.info(f"Scheduled daily task at {time_str}: {func.__name__}")
    
    def add_interval_task(self, minutes: int, func, *args, **kwargs):
        """Schedule interval-based task"""
        job = schedule.every(minutes).minutes.do(func, *args, **kwargs)
        self.tasks.append(job)
        logger.info(f"Scheduled task every {minutes} minutes: {func.__name__}")
    
    def run(self):
        """Run scheduler loop"""
        logger.info("Starting scheduler...")
        while True:
            schedule.run_pending()
            time.sleep(1)

# Create and configure scheduler
scheduler = TaskScheduler()
scheduler.add_daily_task("02:00", backup_database)
scheduler.add_daily_task("08:00", generate_reports)
scheduler.add_interval_task(15, check_system_health)
scheduler.run()
```

## Best Practices for Automation

### 1. Error Handling and Resilience

Build robust automation with proper error handling:

```python
import time
from functools import wraps
from typing import Callable, Any

def retry(max_attempts: int = 3, delay: int = 1, backoff: int = 2):
    """Retry decorator with exponential backoff"""
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs) -> Any:
            attempt = 1
            current_delay = delay
            
            while attempt <= max_attempts:
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_attempts:
                        logger.error(f"Failed after {max_attempts} attempts: {e}")
                        raise
                    
                    logger.warning(f"Attempt {attempt} failed: {e}. Retrying in {current_delay}s...")
                    time.sleep(current_delay)
                    current_delay *= backoff
                    attempt += 1
        
        return wrapper
    return decorator

@retry(max_attempts=3, delay=2)
def fetch_api_data(url: str) -> dict:
    """Fetch data with automatic retry"""
    response = requests.get(url, timeout=10)
    response.raise_for_status()
    return response.json()

# Graceful degradation
def process_with_fallback(primary_func, fallback_func, *args, **kwargs):
    """Try primary function, fall back to alternative"""
    try:
        return primary_func(*args, **kwargs)
    except Exception as e:
        logger.warning(f"Primary method failed: {e}. Using fallback...")
        return fallback_func(*args, **kwargs)
```

### 2. Configuration Management

Separate configuration from code:

```python
import yaml
import json
from pathlib import Path
from dataclasses import dataclass
from typing import List

@dataclass
class DatabaseConfig:
    host: str
    port: int
    database: str
    username: str
    password: str

@dataclass
class AutomationConfig:
    database: DatabaseConfig
    api_endpoints: List[str]
    log_level: str
    retry_attempts: int

class ConfigManager:
    """Manage application configuration"""
    
    @staticmethod
    def load_from_yaml(filepath: Path) -> AutomationConfig:
        """Load configuration from YAML file"""
        with open(filepath) as f:
            data = yaml.safe_load(f)
        
        db_config = DatabaseConfig(**data['database'])
        
        return AutomationConfig(
            database=db_config,
            api_endpoints=data['api']['endpoints'],
            log_level=data['logging']['level'],
            retry_attempts=data['retry']['max_attempts']
        )
    
    @staticmethod
    def load_from_env() -> AutomationConfig:
        """Load configuration from environment variables"""
        import os
        
        db_config = DatabaseConfig(
            host=os.getenv('DB_HOST', 'localhost'),
            port=int(os.getenv('DB_PORT', 5432)),
            database=os.getenv('DB_NAME'),
            username=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD')
        )
        
        return AutomationConfig(
            database=db_config,
            api_endpoints=os.getenv('API_ENDPOINTS', '').split(','),
            log_level=os.getenv('LOG_LEVEL', 'INFO'),
            retry_attempts=int(os.getenv('RETRY_ATTEMPTS', 3))
        )

# config.yaml
"""
database:
  host: localhost
  port: 5432
  database: automation_db
  username: admin
  password: ${DB_PASSWORD}  # From environment

api:
  endpoints:
    - https://api1.example.com
    - https://api2.example.com

logging:
  level: INFO

retry:
  max_attempts: 3
"""

config = ConfigManager.load_from_yaml(Path("config.yaml"))
```

### 3. Logging and Monitoring

Implement comprehensive logging:

```python
import logging
from contextlib import contextmanager
from datetime import datetime
from typing import Any
import json

class AutomationLogger:
    """Enhanced logging for automation tasks"""
    
    def __init__(self, name: str):
        self.logger = logging.getLogger(name)
        self.metrics = {
            'tasks_executed': 0,
            'tasks_succeeded': 0,
            'tasks_failed': 0,
            'execution_times': []
        }
    
    @contextmanager
    def log_task(self, task_name: str):
        """Context manager for task execution logging"""
        start_time = datetime.now()
        self.logger.info(f"Starting task: {task_name}")
        self.metrics['tasks_executed'] += 1
        
        try:
            yield
            execution_time = (datetime.now() - start_time).total_seconds()
            self.metrics['execution_times'].append(execution_time)
            self.metrics['tasks_succeeded'] += 1
            self.logger.info(f"Completed task: {task_name} ({execution_time:.2f}s)")
            
        except Exception as e:
            self.metrics['tasks_failed'] += 1
            self.logger.error(f"Failed task: {task_name} - {e}")
            raise
    
    def log_metrics(self):
        """Log collected metrics"""
        avg_time = sum(self.metrics['execution_times']) / len(self.metrics['execution_times'])
        
        self.logger.info(f"""
        Automation Metrics:
          Total Tasks: {self.metrics['tasks_executed']}
          Succeeded: {self.metrics['tasks_succeeded']}
          Failed: {self.metrics['tasks_failed']}
          Average Execution Time: {avg_time:.2f}s
        """)

# Use enhanced logger
logger = AutomationLogger("data_pipeline")

with logger.log_task("Extract data"):
    data = extract_from_source()

with logger.log_task("Transform data"):
    transformed = transform_data(data)

with logger.log_task("Load to database"):
    load_to_database(transformed)

logger.log_metrics()
```

### 4. Testing Automation Scripts

Write tests for automation code:

```python
import unittest
from unittest.mock import Mock, patch, MagicMock
from pathlib import Path
import tempfile

class TestBackupAutomation(unittest.TestCase):
    """Test backup automation functions"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.temp_dir = tempfile.mkdtemp()
        self.source_dir = Path(self.temp_dir) / "source"
        self.dest_dir = Path(self.temp_dir) / "destination"
        self.source_dir.mkdir()
        self.dest_dir.mkdir()
    
    def tearDown(self):
        """Clean up test environment"""
        shutil.rmtree(self.temp_dir)
    
    def test_backup_creates_archive(self):
        """Test that backup creates archive file"""
        # Create test files
        test_file = self.source_dir / "test.txt"
        test_file.write_text("test content")
        
        # Execute backup
        result = backup_directory(self.source_dir, self.dest_dir)
        
        # Assert
        self.assertTrue(result.exists())
        self.assertTrue(result.suffix == '.zip')
    
    @patch('requests.get')
    def test_api_fetch_with_retry(self, mock_get):
        """Test API fetch with retry logic"""
        # Mock failed then successful response
        mock_get.side_effect = [
            requests.exceptions.Timeout(),
            Mock(status_code=200, json=lambda: {'data': 'test'})
        ]
        
        # Execute
        result = fetch_api_data("https://api.example.com/data")
        
        # Assert
        self.assertEqual(mock_get.call_count, 2)
        self.assertEqual(result['data'], 'test')

if __name__ == '__main__':
    unittest.main()
```

### 5. Security Considerations

Protect sensitive data and credentials:

```python
import os
from cryptography.fernet import Fernet
import keyring
from pathlib import Path

class SecretManager:
    """Secure credential management"""
    
    def __init__(self):
        self.service_name = "automation_service"
    
    def store_credential(self, key: str, value: str) -> None:
        """Store credential in system keyring"""
        keyring.set_password(self.service_name, key, value)
    
    def get_credential(self, key: str) -> str:
        """Retrieve credential from system keyring"""
        return keyring.get_password(self.service_name, key)
    
    def delete_credential(self, key: str) -> None:
        """Remove credential from keyring"""
        keyring.delete_password(self.service_name, key)

class FileEncryptor:
    """Encrypt sensitive files"""
    
    def __init__(self, key_path: Path = None):
        if key_path and key_path.exists():
            self.key = key_path.read_bytes()
        else:
            self.key = Fernet.generate_key()
            if key_path:
                key_path.write_bytes(self.key)
        
        self.cipher = Fernet(self.key)
    
    def encrypt_file(self, input_path: Path, output_path: Path) -> None:
        """Encrypt file contents"""
        data = input_path.read_bytes()
        encrypted = self.cipher.encrypt(data)
        output_path.write_bytes(encrypted)
    
    def decrypt_file(self, input_path: Path, output_path: Path) -> None:
        """Decrypt file contents"""
        encrypted = input_path.read_bytes()
        decrypted = self.cipher.decrypt(encrypted)
        output_path.write_bytes(decrypted)

# Use secure credential management
secrets = SecretManager()
secrets.store_credential("api_key", os.getenv("API_KEY"))

# Later retrieval
api_key = secrets.get_credential("api_key")
```

## Real-World Automation Examples

### Example 1: Automated Report Generation

```python
import pandas as pd
from pathlib import Path
from datetime import datetime, timedelta
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication

class ReportGenerator:
    """Automated report generation and distribution"""
    
    def __init__(self, database_config: dict, email_config: dict):
        self.db_config = database_config
        self.email_config = email_config
    
    def generate_sales_report(self, start_date: datetime, end_date: datetime) -> Path:
        """Generate sales report for date range"""
        
        # Query database
        query = """
        SELECT 
            date,
            product_name,
            SUM(quantity) as units_sold,
            SUM(revenue) as total_revenue
        FROM sales
        WHERE date BETWEEN %s AND %s
        GROUP BY date, product_name
        ORDER BY date DESC, total_revenue DESC
        """
        
        # Fetch data
        import psycopg2
        conn = psycopg2.connect(**self.db_config)
        df = pd.read_sql_query(query, conn, params=(start_date, end_date))
        conn.close()
        
        # Generate summary statistics
        summary = {
            'total_revenue': df['total_revenue'].sum(),
            'total_units': df['units_sold'].sum(),
            'top_product': df.groupby('product_name')['total_revenue'].sum().idxmax(),
            'date_range': f"{start_date.date()} to {end_date.date()}"
        }
        
        # Create Excel report with multiple sheets
        output_path = Path(f"/reports/sales_report_{datetime.now():%Y%m%d}.xlsx")
        
        with pd.ExcelWriter(output_path, engine='openpyxl') as writer:
            df.to_excel(writer, sheet_name='Detailed Sales', index=False)
            
            summary_df = pd.DataFrame([summary])
            summary_df.to_excel(writer, sheet_name='Summary', index=False)
            
            # Top products sheet
            top_products = df.groupby('product_name')['total_revenue'].sum().nlargest(10)
            top_products.to_excel(writer, sheet_name='Top 10 Products')
        
        return output_path
    
    def send_report_email(self, report_path: Path, recipients: list) -> None:
        """Send report via email"""
        
        # Create message
        msg = MIMEMultipart()
        msg['From'] = self.email_config['from_address']
        msg['To'] = ', '.join(recipients)
        msg['Subject'] = f"Sales Report - {datetime.now():%Y-%m-%d}"
        
        # Email body
        body = """
        <html>
        <body>
        <h2>Weekly Sales Report</h2>
        <p>Please find attached the sales report for this week.</p>
        <p>This report was automatically generated by the sales automation system.</p>
        </body>
        </html>
        """
        msg.attach(MIMEText(body, 'html'))
        
        # Attach report
        with open(report_path, 'rb') as f:
            attachment = MIMEApplication(f.read(), _subtype='xlsx')
            attachment.add_header('Content-Disposition', 'attachment', 
                                 filename=report_path.name)
            msg.attach(attachment)
        
        # Send email
        with smtplib.SMTP(self.email_config['smtp_server'], 
                         self.email_config['smtp_port']) as server:
            server.starttls()
            server.login(self.email_config['username'], 
                       self.email_config['password'])
            server.send_message(msg)
    
    def run_weekly_report(self) -> None:
        """Generate and send weekly report"""
        end_date = datetime.now()
        start_date = end_date - timedelta(days=7)
        
        print(f"Generating report for {start_date.date()} to {end_date.date()}")
        
        report_path = self.generate_sales_report(start_date, end_date)
        print(f"Report generated: {report_path}")
        
        self.send_report_email(report_path, ['sales@example.com', 'management@example.com'])
        print("Report sent successfully")

# Schedule weekly report
import schedule

report_gen = ReportGenerator(db_config, email_config)
schedule.every().monday.at("08:00").do(report_gen.run_weekly_report)
```

### Example 2: Web Scraping and Data Aggregation

```python
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from bs4 import BeautifulSoup
import requests
from dataclasses import dataclass
from typing import List
import csv

@dataclass
class Product:
    name: str
    price: float
    url: str
    source: str
    timestamp: datetime

class PriceComparison Scraper:
    """Scrape prices from multiple e-commerce sites"""
    
    def __init__(self):
        options = webdriver.ChromeOptions()
        options.add_argument('--headless')
        options.add_argument('--no-sandbox')
        options.add_argument('--disable-dev-shm-usage')
        self.driver = webdriver.Chrome(options=options)
    
    def scrape_site_a(self, search_term: str) -> List[Product]:
        """Scrape products from Site A"""
        products = []
        url = f"https://sitea.com/search?q={search_term}"
        
        response = requests.get(url)
        soup = BeautifulSoup(response.content, 'html.parser')
        
        for item in soup.find_all('div', class_='product'):
            name = item.find('h3').text.strip()
            price_text = item.find('span', class_='price').text
            price = float(price_text.replace('$', '').replace(',', ''))
            product_url = item.find('a')['href']
            
            products.append(Product(
                name=name,
                price=price,
                url=f"https://sitea.com{product_url}",
                source="Site A",
                timestamp=datetime.now()
            ))
        
        return products
    
    def scrape_site_b(self, search_term: str) -> List[Product]:
        """Scrape products from Site B (JavaScript-rendered)"""
        products = []
        url = f"https://siteb.com/search?q={search_term}"
        
        self.driver.get(url)
        
        # Wait for products to load
        wait = WebDriverWait(self.driver, 10)
        wait.until(EC.presence_of_element_located((By.CLASS_NAME, 'product-card')))
        
        # Scroll to load all products
        self.driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
        time.sleep(2)
        
        # Extract products
        elements = self.driver.find_elements(By.CLASS_NAME, 'product-card')
        
        for element in elements:
            name = element.find_element(By.CLASS_NAME, 'title').text
            price_text = element.find_element(By.CLASS_NAME, 'price').text
            price = float(price_text.replace('$', '').replace(',', ''))
            product_url = element.find_element(By.TAG_NAME, 'a').get_attribute('href')
            
            products.append(Product(
                name=name,
                price=price,
                url=product_url,
                source="Site B",
                timestamp=datetime.now()
            ))
        
        return products
    
    def aggregate_prices(self, search_terms: List[str]) -> pd.DataFrame:
        """Aggregate prices across multiple sites"""
        all_products = []
        
        for term in search_terms:
            print(f"Searching for: {term}")
            
            try:
                products_a = self.scrape_site_a(term)
                all_products.extend(products_a)
            except Exception as e:
                print(f"Error scraping Site A: {e}")
            
            try:
                products_b = self.scrape_site_b(term)
                all_products.extend(products_b)
            except Exception as e:
                print(f"Error scraping Site B: {e}")
            
            time.sleep(2)  # Respectful scraping
        
        # Convert to DataFrame
        df = pd.DataFrame([vars(p) for p in all_products])
        
        # Find best prices
        best_prices = df.loc[df.groupby('name')['price'].idxmin()]
        
        return best_prices
    
    def close(self):
        """Clean up resources"""
        self.driver.quit()

# Use scraper
scraper = PriceComparisonScraper()
try:
    search_terms = ["laptop", "monitor", "keyboard"]
    results = scraper.aggregate_prices(search_terms)
    results.to_csv("/data/price_comparison.csv", index=False)
    print(f"Found {len(results)} best deals")
finally:
    scraper.close()
```

### Example 3: System Administration Automation

```python
import psutil
import subprocess
from dataclasses import dataclass
from typing import List, Dict
import json

@dataclass
class SystemHealth:
    cpu_percent: float
    memory_percent: float
    disk_usage: Dict[str, float]
    running_processes: int
    network_connections: int
    timestamp: datetime

class SystemMonitor:
    """Monitor and maintain system health"""
    
    def __init__(self, alert_threshold: Dict[str, float]):
        self.thresholds = alert_threshold
        self.history: List[SystemHealth] = []
    
    def collect_metrics(self) -> SystemHealth:
        """Collect current system metrics"""
        
        # CPU and memory
        cpu = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory().percent
        
        # Disk usage for all partitions
        disk_usage = {}
        for partition in psutil.disk_partitions():
            try:
                usage = psutil.disk_usage(partition.mountpoint)
                disk_usage[partition.mountpoint] = usage.percent
            except PermissionError:
                continue
        
        # Process and network stats
        processes = len(psutil.pids())
        connections = len(psutil.net_connections())
        
        metrics = SystemHealth(
            cpu_percent=cpu,
            memory_percent=memory,
            disk_usage=disk_usage,
            running_processes=processes,
            network_connections=connections,
            timestamp=datetime.now()
        )
        
        self.history.append(metrics)
        return metrics
    
    def check_alerts(self, metrics: SystemHealth) -> List[str]:
        """Check if metrics exceed thresholds"""
        alerts = []
        
        if metrics.cpu_percent > self.thresholds['cpu']:
            alerts.append(f"HIGH CPU: {metrics.cpu_percent}%")
        
        if metrics.memory_percent > self.thresholds['memory']:
            alerts.append(f"HIGH MEMORY: {metrics.memory_percent}%")
        
        for mount, usage in metrics.disk_usage.items():
            if usage > self.thresholds['disk']:
                alerts.append(f"HIGH DISK ({mount}): {usage}%")
        
        return alerts
    
    def cleanup_logs(self, max_age_days: int = 30) -> int:
        """Clean up old log files"""
        from datetime import timedelta
        
        log_dirs = ['/var/log', '/tmp']
        cutoff_time = time.time() - (max_age_days * 86400)
        removed_count = 0
        
        for log_dir in log_dirs:
            log_path = Path(log_dir)
            if not log_path.exists():
                continue
            
            for log_file in log_path.rglob('*.log*'):
                try:
                    if log_file.stat().st_mtime < cutoff_time:
                        log_file.unlink()
                        removed_count += 1
                except (PermissionError, FileNotFoundError):
                    continue
        
        return removed_count
    
    def restart_service(self, service_name: str) -> bool:
        """Restart a system service"""
        try:
            subprocess.run(
                ['systemctl', 'restart', service_name],
                check=True,
                capture_output=True,
                timeout=30
            )
            return True
        except subprocess.CalledProcessError as e:
            print(f"Failed to restart {service_name}: {e.stderr}")
            return False
    
    def generate_report(self) -> str:
        """Generate system health report"""
        if not self.history:
            return "No metrics collected"
        
        recent = self.history[-1]
        avg_cpu = sum(m.cpu_percent for m in self.history) / len(self.history)
        avg_mem = sum(m.memory_percent for m in self.history) / len(self.history)
        
        report = f"""
        System Health Report
        Generated: {datetime.now()}
        
        Current Status:
          CPU Usage: {recent.cpu_percent}%
          Memory Usage: {recent.memory_percent}%
          Running Processes: {recent.running_processes}
          Network Connections: {recent.network_connections}
        
        Averages (last {len(self.history)} checks):
          Average CPU: {avg_cpu:.1f}%
          Average Memory: {avg_mem:.1f}%
        
        Disk Usage:
        """
        
        for mount, usage in recent.disk_usage.items():
            report += f"  {mount}: {usage}%\n"
        
        return report

# Automated system maintenance
def automated_maintenance():
    """Run automated system maintenance tasks"""
    
    monitor = SystemMonitor({
        'cpu': 80.0,
        'memory': 85.0,
        'disk': 90.0
    })
    
    # Collect metrics
    metrics = monitor.collect_metrics()
    print(f"Collected metrics at {metrics.timestamp}")
    
    # Check for alerts
    alerts = monitor.check_alerts(metrics)
    if alerts:
        print("ALERTS DETECTED:")
        for alert in alerts:
            print(f"  - {alert}")
        
        # Send notification (email, Slack, etc.)
        send_alert_notification(alerts)
    
    # Cleanup old logs
    removed = monitor.cleanup_logs(max_age_days=30)
    print(f"Cleaned up {removed} old log files")
    
    # Generate report
    report = monitor.generate_report()
    Path("/var/reports/system_health.txt").write_text(report)

# Schedule maintenance
schedule.every().hour.do(automated_maintenance)
```

## Advanced Topics

### Asynchronous Automation

Use async/await for I/O-bound automation:

```python
import asyncio
import aiohttp
import aiofiles
from typing import List

async def fetch_url(session: aiohttp.ClientSession, url: str) -> dict:
    """Async HTTP request"""
    async with session.get(url) as response:
        return await response.json()

async def process_urls(urls: List[str]) -> List[dict]:
    """Process multiple URLs concurrently"""
    async with aiohttp.ClientSession() as session:
        tasks = [fetch_url(session, url) for url in urls]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        return [r for r in results if not isinstance(r, Exception)]

async def async_file_processing(input_files: List[Path], output_dir: Path):
    """Process multiple files asynchronously"""
    
    async def process_file(filepath: Path):
        async with aiofiles.open(filepath, 'r') as f:
            content = await f.read()
            processed = content.upper()  # Example processing
        
        output_path = output_dir / filepath.name
        async with aiofiles.open(output_path, 'w') as f:
            await f.write(processed)
    
    tasks = [process_file(fp) for fp in input_files]
    await asyncio.gather(*tasks)

# Run async automation
urls = [f"https://api.example.com/data/{i}" for i in range(100)]
results = asyncio.run(process_urls(urls))
```

### Distributed Automation with Celery

Scale automation across multiple workers:

```python
from celery import Celery
from celery.schedules import crontab

app = Celery('automation', broker='redis://localhost:6379/0')

@app.task(bind=True, max_retries=3)
def process_data_file(self, filepath: str):
    """Process data file as Celery task"""
    try:
        # Processing logic
        df = pd.read_csv(filepath)
        result = transform_data(df)
        save_result(result)
        return {'status': 'success', 'records': len(result)}
    except Exception as e:
        # Retry with exponential backoff
        raise self.retry(exc=e, countdown=60 * (2 ** self.request.retries))

@app.task
def cleanup_old_files():
    """Scheduled cleanup task"""
    removed = 0
    for filepath in Path("/tmp").glob("*.tmp"):
        if filepath.stat().st_mtime < time.time() - 86400:
            filepath.unlink()
            removed += 1
    return removed

# Configure periodic tasks
app.conf.beat_schedule = {
    'cleanup-every-day': {
        'task': 'automation.cleanup_old_files',
        'schedule': crontab(hour=2, minute=0),
    },
}

# Submit tasks
for file in data_files:
    process_data_file.delay(str(file))
```

## Tools and Resources

### Development Tools

**IDEs and Editors**:

- **PyCharm**: Full-featured Python IDE
- **VS Code**: Lightweight with excellent Python support
- **Jupyter Notebooks**: Interactive development and documentation

**Debugging**:

- **pdb**: Python debugger
- **ipdb**: Enhanced debugger with IPython
- **py-spy**: Sampling profiler

**Testing**:

- **pytest**: Modern testing framework
- **unittest**: Built-in testing framework
- **tox**: Test automation tool

### Deployment

**Containerization**:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "automation_script.py"]
```

**Systemd Service** (Linux):

```ini
[Unit]
Description=Python Automation Service
After=network.target

[Service]
Type=simple
User=automation
WorkingDirectory=/opt/automation
ExecStart=/usr/bin/python3 /opt/automation/main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Learning Resources

**Books**:

- "Automate the Boring Stuff with Python" by Al Sweigart
- "Python for DevOps" by Noah Gift et al.
- "Effective Python" by Brett Slatkin

**Online Resources**:

- [Real Python Automation Tutorials](https://realpython.com/tutorials/automation/)
- [Python Documentation](https://docs.python.org/)
- [Awesome Python Automation](https://github.com/vinta/awesome-python#automation)

**Community**:

- r/Python on Reddit
- Python Discord Server
- Stack Overflow Python community

## Conclusion

Python automation empowers you to build reliable, scalable solutions for a wide range of tasks. By following best practices, leveraging the rich ecosystem of libraries, and implementing robust error handling, you can create automation that saves time, reduces errors, and improves efficiency.

Remember:

- **Start simple** and iterate
- **Handle errors gracefully**
- **Log everything important**
- **Test thoroughly**
- **Document your automation**
- **Monitor production systems**

The examples and patterns in this guide provide a foundation for building professional automation solutions. Adapt them to your specific needs and continue learning as the Python ecosystem evolves.

## Next Steps

- [Scripting with Python](scripting.md) - Detailed scripting techniques
- [Web Scraping](web-scraping.md) - Advanced scraping strategies
- [Python Best Practices](../best-practices.md) - Code quality standards
- [Testing](../testing/index.md) - Testing automation code
- [Deployment](../deployment/index.md) - Deploying automation solutions
