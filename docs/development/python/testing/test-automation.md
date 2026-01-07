---
title: Python Test Automation - Complete Guide to Automated Testing
description: Comprehensive guide to Python test automation including pytest runners, CI/CD integration, parallel execution, test reporting, and continuous testing strategies
---

Python test automation is the practice of automatically executing tests throughout the development lifecycle to ensure code quality, catch regressions early, and enable continuous delivery. Modern test automation encompasses test discovery, execution, reporting, and integration with development workflows and CI/CD pipelines.

## Overview

Test automation transforms manual testing processes into automated workflows that run consistently and repeatedly without human intervention. In Python, this involves leveraging test frameworks like pytest, unittest, and specialized tools to discover, execute, and report on tests across different environments, configurations, and scales.

Effective test automation requires:

- **Test Discovery**: Automatically finding and organizing test files and functions
- **Test Execution**: Running tests efficiently with proper setup and teardown
- **Test Reporting**: Generating actionable reports and metrics
- **CI/CD Integration**: Integrating tests into continuous integration pipelines
- **Parallel Execution**: Running tests concurrently to reduce execution time
- **Environment Management**: Testing across multiple Python versions and dependencies

## Test Discovery and Execution

### pytest Test Discovery

pytest automatically discovers test files and functions following these conventions:

```python
# test_calculator.py - Automatically discovered by pytest
def test_addition():
    assert 1 + 1 == 2

def test_subtraction():
    assert 5 - 3 == 2

class TestCalculator:
    def test_multiplication(self):
        assert 2 * 3 == 6
    
    def test_division(self):
        assert 10 / 2 == 5
```

**Discovery Rules**:

- Files: `test_*.py` or `*_test.py`
- Functions: `test_*` or `*_test`
- Classes: `Test*` (no `__init__` method)
- Methods: `test_*`

**Custom Discovery**:

```ini
# pytest.ini
[pytest]
python_files = test_*.py check_*.py
python_classes = Test* Check*
python_functions = test_* check_*
testpaths = tests integration_tests
```

### Running Tests

```bash
# Run all tests
pytest

# Run specific test file
pytest tests/test_calculator.py

# Run specific test function
pytest tests/test_calculator.py::test_addition

# Run specific test class
pytest tests/test_calculator.py::TestCalculator

# Run specific test method
pytest tests/test_calculator.py::TestCalculator::test_multiplication

# Run tests matching pattern
pytest -k "addition or subtraction"

# Run tests with specific marker
pytest -m "slow"

# Run tests in directory
pytest tests/unit/
```

### Test Selection and Filtering

```python
# test_api.py
import pytest

@pytest.mark.slow
def test_large_dataset():
    """Test with large dataset - takes 30 seconds"""
    pass

@pytest.mark.integration
def test_database_connection():
    """Test database integration"""
    pass

@pytest.mark.skip(reason="Feature not implemented")
def test_future_feature():
    """Test for upcoming feature"""
    pass

@pytest.mark.skipif(sys.version_info < (3, 10), reason="Requires Python 3.10+")
def test_match_statement():
    """Test match statement syntax"""
    pass

@pytest.mark.xfail(reason="Known bug in external library")
def test_known_issue():
    """Test that is expected to fail"""
    pass
```

**Running Selected Tests**:

```bash
# Run only slow tests
pytest -m slow

# Run everything except slow tests
pytest -m "not slow"

# Run integration tests only
pytest -m integration

# Run multiple markers
pytest -m "slow or integration"

# Run with complex expression
pytest -m "not (slow or integration)"
```

## Test Runners

### pytest Runner

pytest is the most popular Python test runner with extensive features:

**Installation**:

```bash
pip install pytest pytest-cov pytest-html pytest-xdist
```

**Configuration**:

```ini
# pytest.ini
[pytest]
minversion = 7.0
addopts =
    -ra
    -q
    --strict-markers
    --strict-config
    --cov=src
    --cov-report=html
    --cov-report=term-missing
testpaths = tests
markers =
    slow: marks tests as slow (deselect with '-m "not slow"')
    integration: marks tests as integration tests
    unit: marks tests as unit tests
    smoke: marks tests as smoke tests
```

**Advanced Options**:

```bash
# Verbose output
pytest -v

# Very verbose output (show test docstrings)
pytest -vv

# Show local variables in tracebacks
pytest -l

# Stop on first failure
pytest -x

# Stop after N failures
pytest --maxfail=3

# Run last failed tests
pytest --lf

# Run last failed first, then others
pytest --ff

# Show extra test summary info
pytest -ra

# Disable capturing (print statements visible)
pytest -s

# Run in strict mode
pytest --strict-markers --strict-config
```

### unittest Runner

Python's built-in unittest framework:

```python
# test_calculator_unittest.py
import unittest

class TestCalculator(unittest.TestCase):
    def setUp(self):
        """Run before each test"""
        self.calc = Calculator()
    
    def tearDown(self):
        """Run after each test"""
        self.calc = None
    
    def test_addition(self):
        result = self.calc.add(2, 3)
        self.assertEqual(result, 5)
    
    def test_division_by_zero(self):
        with self.assertRaises(ZeroDivisionError):
            self.calc.divide(10, 0)

if __name__ == '__main__':
    unittest.main()
```

**Running unittest Tests**:

```bash
# Run all tests
python -m unittest discover

# Run specific module
python -m unittest tests.test_calculator

# Run specific test class
python -m unittest tests.test_calculator.TestCalculator

# Run specific test method
python -m unittest tests.test_calculator.TestCalculator.test_addition

# Verbose output
python -m unittest discover -v

# Start directory and pattern
python -m unittest discover -s tests -p "test_*.py"
```

### nose2 Runner

nose2 is a successor to nose with enhanced features:

```bash
# Install nose2
pip install nose2

# Run tests
nose2

# Verbose output
nose2 -v

# With plugins
nose2 --with-coverage
```

## Parallel Test Execution

### pytest-xdist

pytest-xdist enables parallel and distributed testing:

**Installation**:

```bash
pip install pytest-xdist
```

**Running in Parallel**:

```bash
# Use all CPU cores
pytest -n auto

# Use specific number of workers
pytest -n 4

# Distribute tests across multiple workers
pytest -n 8 --dist loadscope

# Distribute by file
pytest -n 4 --dist loadfile

# Distribute by test
pytest -n 4 --dist loadgroup
```

**Load Distribution Strategies**:

- `load`: Distribute tests evenly across workers (default)
- `loadscope`: Distribute by test scope (class, module, session)
- `loadfile`: Keep tests from same file together
- `loadgroup`: Distribute by group marker
- `worksteal`: Workers steal tests from each other

**Grouping Tests**:

```python
# test_api.py
import pytest

@pytest.mark.xdist_group(name="database")
def test_db_read():
    """Tests in same group run on same worker"""
    pass

@pytest.mark.xdist_group(name="database")
def test_db_write():
    """Ensures database tests don't conflict"""
    pass
```

**Performance Considerations**:

```python
# conftest.py
def pytest_collection_modifyitems(items):
    """Optimize test ordering for parallel execution"""
    # Run slow tests first to minimize total time
    items.sort(key=lambda x: x.get_closest_marker("slow") is None)
```

### Handling Shared Resources

```python
# conftest.py
import pytest
from filelock import FileLock

@pytest.fixture(scope="session")
def shared_resource(tmp_path_factory, worker_id):
    """Create shared resource once across all workers"""
    if worker_id == "master":
        # Single process mode
        return create_resource()
    
    # Parallel mode - use file lock
    root_tmp = tmp_path_factory.getbasetemp().parent
    resource_file = root_tmp / "resource.json"
    lock_file = root_tmp / "resource.lock"
    
    with FileLock(str(lock_file)):
        if resource_file.exists():
            return load_resource(resource_file)
        else:
            resource = create_resource()
            save_resource(resource, resource_file)
            return resource
```

## Test Reporting

### pytest HTML Reports

Generate comprehensive HTML reports:

**Installation**:

```bash
pip install pytest-html
```

**Usage**:

```bash
# Generate HTML report
pytest --html=report.html

# Self-contained report (includes CSS)
pytest --html=report.html --self-contained-html

# With extra summary information
pytest --html=report.html -ra
```

**Custom Report Content**:

```python
# conftest.py
import pytest
from datetime import datetime

@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """Add custom information to HTML report"""
    outcome = yield
    report = outcome.get_result()
    
    if report.when == "call":
        # Add extra information
        extra = getattr(report, "extra", [])
        if report.failed:
            # Add screenshot on failure
            extra.append(pytest_html.extras.image("screenshot.png"))
        report.extra = extra

def pytest_html_report_title(report):
    """Customize report title"""
    report.title = f"Test Report - {datetime.now().strftime('%Y-%m-%d %H:%M')}"
```

### JUnit XML Reports

Generate JUnit-compatible XML reports for CI systems:

```bash
# Generate JUnit XML
pytest --junitxml=junit.xml

# Customize test suite name
pytest --junitxml=junit.xml -o junit_suite_name="MyProject"

# Include test properties
pytest --junitxml=junit.xml -o junit_logging=all
```

**Custom JUnit Properties**:

```python
# conftest.py
def pytest_configure(config):
    """Add custom properties to JUnit XML"""
    config._metadata = {
        "Project": "MyProject",
        "Python": platform.python_version(),
        "Platform": platform.platform(),
        "Build": os.environ.get("BUILD_NUMBER", "local")
    }

@pytest.hookimpl(tryfirst=True)
def pytest_runtest_logreport(report):
    """Add custom data to each test result"""
    if report.when == "call":
        report.user_properties.append(("duration_ms", report.duration * 1000))
```

### Coverage Reports

Generate code coverage reports with pytest-cov:

**Installation**:

```bash
pip install pytest-cov
```

**Usage**:

```bash
# Run tests with coverage
pytest --cov=src

# HTML coverage report
pytest --cov=src --cov-report=html

# Terminal report with missing lines
pytest --cov=src --cov-report=term-missing

# Multiple report formats
pytest --cov=src --cov-report=html --cov-report=term --cov-report=xml

# Fail if coverage below threshold
pytest --cov=src --cov-fail-under=80

# Only show coverage for changed files
pytest --cov=src --cov-report=term-missing:skip-covered
```

**Configuration**:

```ini
# .coveragerc
[run]
source = src
omit =
    */tests/*
    */venv/*
    */__pycache__/*
    */site-packages/*

[report]
precision = 2
show_missing = True
skip_covered = False

[html]
directory = htmlcov
```

### Allure Reports

Generate rich, interactive Allure reports:

**Installation**:

```bash
pip install allure-pytest
# Install Allure command-line tool separately
```

**Usage**:

```python
# test_api.py
import allure

@allure.feature("Authentication")
@allure.story("Login")
@allure.severity(allure.severity_level.CRITICAL)
def test_login():
    """Test user login functionality"""
    with allure.step("Enter username"):
        enter_username("testuser")
    
    with allure.step("Enter password"):
        enter_password("password123")
    
    with allure.step("Click login button"):
        click_login()
    
    with allure.step("Verify login success"):
        assert is_logged_in()

@allure.feature("API")
@allure.story("User Management")
def test_create_user():
    """Test user creation API"""
    with allure.step("Send POST request"):
        response = create_user({"name": "John", "email": "john@example.com"})
    
    allure.attach(str(response.json()), "API Response", allure.attachment_type.JSON)
    assert response.status_code == 201
```

**Generating Reports**:

```bash
# Run tests and generate Allure data
pytest --alluredir=allure-results

# Generate and serve HTML report
allure serve allure-results

# Generate HTML report to directory
allure generate allure-results -o allure-report
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: Test Suite

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.9", "3.10", "3.11", "3.12"]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
      
      - name: Cache dependencies
        uses: actions/cache@v4
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
          restore-keys: |
            ${{ runner.os }}-pip-
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements-dev.txt
      
      - name: Run tests
        run: |
          pytest -v --cov=src --cov-report=xml --cov-report=term-missing
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          file: ./coverage.xml
          flags: unittests
          name: codecov-${{ matrix.python-version }}
      
      - name: Archive test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results-${{ matrix.python-version }}
          path: |
            htmlcov/
            junit.xml
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - test
  - report

variables:
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.cache/pip"

cache:
  paths:
    - .cache/pip
    - .venv/

test:
  stage: test
  image: python:3.11
  parallel:
    matrix:
      - PYTHON_VERSION: ["3.9", "3.10", "3.11", "3.12"]
  before_script:
    - python -m venv .venv
    - source .venv/bin/activate
    - pip install --upgrade pip
    - pip install -r requirements-dev.txt
  script:
    - pytest -v --junitxml=junit.xml --cov=src --cov-report=xml --cov-report=html
  coverage: '/TOTAL.*\s+(\d+%)$/'
  artifacts:
    when: always
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
    paths:
      - htmlcov/
    expire_in: 30 days

pages:
  stage: report
  dependencies:
    - test
  script:
    - mkdir -p public
    - cp -r htmlcov/* public/
  artifacts:
    paths:
      - public
  only:
    - main
```

### Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any
    
    environment {
        PYTHON_VERSION = '3.11'
        VENV_DIR = '.venv'
    }
    
    stages {
        stage('Setup') {
            steps {
                sh '''
                    python${PYTHON_VERSION} -m venv ${VENV_DIR}
                    . ${VENV_DIR}/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements-dev.txt
                '''
            }
        }
        
        stage('Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh '''
                            . ${VENV_DIR}/bin/activate
                            pytest tests/unit -v --junitxml=junit-unit.xml
                        '''
                    }
                }
                stage('Integration Tests') {
                    steps {
                        sh '''
                            . ${VENV_DIR}/bin/activate
                            pytest tests/integration -v --junitxml=junit-integration.xml
                        '''
                    }
                }
            }
        }
        
        stage('Coverage') {
            steps {
                sh '''
                    . ${VENV_DIR}/bin/activate
                    pytest --cov=src --cov-report=xml --cov-report=html --cov-fail-under=80
                '''
            }
        }
        
        stage('Reports') {
            steps {
                junit '**/junit-*.xml'
                publishHTML(target: [
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'htmlcov',
                    reportFiles: 'index.html',
                    reportName: 'Coverage Report'
                ])
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        failure {
            emailext(
                subject: "Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "Check console output at ${env.BUILD_URL}",
                to: "${env.CHANGE_AUTHOR_EMAIL}"
            )
        }
    }
}
```

### Azure Pipelines

```yaml
# azure-pipelines.yml
trigger:
  - main
  - develop

pool:
  vmImage: 'ubuntu-latest'

strategy:
  matrix:
    Python39:
      python.version: '3.9'
    Python310:
      python.version: '3.10'
    Python311:
      python.version: '3.11'
    Python312:
      python.version: '3.12'

steps:
  - task: UsePythonVersion@0
    inputs:
      versionSpec: '$(python.version)'
    displayName: 'Use Python $(python.version)'
  
  - script: |
      python -m pip install --upgrade pip
      pip install -r requirements-dev.txt
    displayName: 'Install dependencies'
  
  - script: |
      pytest -v --junitxml=junit/test-results.xml --cov=src --cov-report=xml --cov-report=html
    displayName: 'Run tests'
  
  - task: PublishTestResults@2
    condition: always()
    inputs:
      testResultsFiles: '**/test-results.xml'
      testRunTitle: 'Python $(python.version)'
  
  - task: PublishCodeCoverageResults@1
    inputs:
      codeCoverageTool: Cobertura
      summaryFileLocation: '$(System.DefaultWorkingDirectory)/**/coverage.xml'
      reportDirectory: '$(System.DefaultWorkingDirectory)/**/htmlcov'
```

## Test Automation with tox

tox automates testing across multiple environments:

**Installation**:

```bash
pip install tox
```

**Configuration**:

```ini
# tox.ini
[tox]
envlist = py39,py310,py311,py312,lint,type

[testenv]
deps =
    pytest
    pytest-cov
    pytest-xdist
commands =
    pytest {posargs:-v --cov=src --cov-report=term-missing}

[testenv:lint]
deps =
    ruff
    black
commands =
    ruff check src tests
    black --check src tests

[testenv:type]
deps =
    mypy
    pytest
commands =
    mypy src

[testenv:docs]
deps =
    sphinx
    sphinx-rtd-theme
commands =
    sphinx-build -b html docs docs/_build/html

[testenv:security]
deps =
    bandit
    safety
commands =
    bandit -r src
    safety check
```

**Running tox**:

```bash
# Run all environments
tox

# Run specific environment
tox -e py311

# Run multiple environments
tox -e py310,py311,lint

# Recreate environments
tox -r

# Run in parallel
tox -p auto

# Pass arguments to pytest
tox -- -k test_specific
```

**Advanced tox Usage**:

```ini
# tox.ini
[tox]
envlist = py{39,310,311,312}-{unit,integration}

[testenv]
deps =
    pytest
    pytest-cov
    unit: pytest-mock
    integration: requests
    integration: docker
commands =
    unit: pytest tests/unit {posargs}
    integration: pytest tests/integration {posargs}

[testenv:py311-integration]
# Environment-specific overrides
passenv = DATABASE_URL
setenv =
    TESTING = true
```

## Continuous Testing Strategies

### Pre-commit Hooks

Automate testing before commits:

**Installation**:

```bash
pip install pre-commit
```

**Configuration**:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: pytest-check
        name: pytest-check
        entry: pytest
        language: system
        pass_filenames: false
        always_run: true
        args: ["-x", "-v", "-m", "not slow"]
      
      - id: pytest-coverage
        name: pytest-coverage
        entry: pytest
        language: system
        pass_filenames: false
        always_run: true
        args: ["--cov=src", "--cov-fail-under=80"]
```

**Setup and Usage**:

```bash
# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files

# Update hooks
pre-commit autoupdate
```

### Watch Mode

Automatically run tests on file changes:

**Using pytest-watch**:

```bash
# Install
pip install pytest-watch

# Run in watch mode
ptw

# With specific options
ptw -- -v -x

# Watch specific directory
ptw tests/unit
```

**Using pytest-testmon**:

```bash
# Install
pip install pytest-testmon

# Run only tests affected by changes
pytest --testmon

# Show testmon coverage
pytest --testmon-nocov
```

### Smoke Testing

Run quick smoke tests after deployment:

```python
# tests/smoke/test_smoke.py
import pytest
import requests

@pytest.mark.smoke
def test_api_health():
    """Verify API is responding"""
    response = requests.get("https://api.example.com/health")
    assert response.status_code == 200

@pytest.mark.smoke
def test_database_connection():
    """Verify database is accessible"""
    from app.database import db
    assert db.ping()

@pytest.mark.smoke
def test_critical_endpoints():
    """Verify critical endpoints are working"""
    endpoints = ["/api/users", "/api/products", "/api/orders"]
    for endpoint in endpoints:
        response = requests.get(f"https://api.example.com{endpoint}")
        assert response.status_code in [200, 401, 403]
```

**Running Smoke Tests**:

```bash
# Run only smoke tests
pytest -m smoke -v

# Run smoke tests with timeout
pytest -m smoke --timeout=30

# Run smoke tests in production
pytest -m smoke --base-url=https://prod.example.com
```

## Test Fixtures and Setup

### Session-Scoped Fixtures

```python
# conftest.py
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

@pytest.fixture(scope="session")
def db_engine():
    """Create database engine once per test session"""
    engine = create_engine("postgresql://localhost/testdb")
    yield engine
    engine.dispose()

@pytest.fixture(scope="session")
def db_tables(db_engine):
    """Create database tables once per test session"""
    Base.metadata.create_all(db_engine)
    yield
    Base.metadata.drop_all(db_engine)

@pytest.fixture
def db_session(db_engine, db_tables):
    """Create new database session for each test"""
    Session = sessionmaker(bind=db_engine)
    session = Session()
    yield session
    session.rollback()
    session.close()
```

### Autouse Fixtures

```python
# conftest.py
import pytest
import logging

@pytest.fixture(autouse=True)
def setup_logging():
    """Configure logging for all tests"""
    logging.basicConfig(level=logging.DEBUG)
    yield
    logging.shutdown()

@pytest.fixture(autouse=True)
def reset_environment():
    """Reset environment before each test"""
    import os
    original_env = os.environ.copy()
    yield
    os.environ.clear()
    os.environ.update(original_env)
```

## Performance Testing Automation

### pytest-benchmark

Automate performance benchmarks:

**Installation**:

```bash
pip install pytest-benchmark
```

**Usage**:

```python
# test_performance.py
import pytest

def test_algorithm_performance(benchmark):
    """Benchmark algorithm performance"""
    result = benchmark(my_algorithm, input_data)
    assert result == expected_output

def test_with_setup(benchmark):
    """Benchmark with setup phase"""
    data = setup_data()
    result = benchmark(process_data, data)
    assert result is not None

@pytest.mark.benchmark(
    min_rounds=100,
    max_time=5.0,
    warmup=True
)
def test_optimized_function(benchmark):
    """Run with custom benchmark settings"""
    benchmark(optimized_function)
```

**Running Benchmarks**:

```bash
# Run benchmarks
pytest --benchmark-only

# Compare with previous runs
pytest --benchmark-compare

# Save results
pytest --benchmark-save=baseline

# Compare with baseline
pytest --benchmark-compare=baseline

# Generate HTML report
pytest --benchmark-only --benchmark-autosave
```

### Load Testing Integration

```python
# test_load.py
import pytest
from locust import HttpUser, task, between

@pytest.mark.load
class WebsiteUser(HttpUser):
    wait_time = between(1, 3)
    
    @task(3)
    def view_homepage(self):
        self.client.get("/")
    
    @task(1)
    def view_product(self):
        self.client.get("/products/1")

def test_load_scenario():
    """Run load test scenario"""
    import subprocess
    result = subprocess.run([
        "locust",
        "-f", "test_load.py",
        "--headless",
        "--users", "100",
        "--spawn-rate", "10",
        "--run-time", "1m",
        "--host", "https://example.com"
    ], capture_output=True)
    assert result.returncode == 0
```

## Test Data Management

### Factories

```python
# factories.py
import factory
from app.models import User, Product

class UserFactory(factory.Factory):
    class Meta:
        model = User
    
    username = factory.Sequence(lambda n: f"user{n}")
    email = factory.LazyAttribute(lambda obj: f"{obj.username}@example.com")
    is_active = True

class ProductFactory(factory.Factory):
    class Meta:
        model = Product
    
    name = factory.Faker("word")
    price = factory.Faker("pydecimal", left_digits=4, right_digits=2, positive=True)
    stock = factory.Faker("pyint", min_value=0, max_value=1000)

# test_users.py
def test_user_creation():
    """Test user creation with factory"""
    user = UserFactory()
    assert user.username.startswith("user")
    assert "@example.com" in user.email

def test_multiple_users():
    """Create multiple test users"""
    users = UserFactory.create_batch(10)
    assert len(users) == 10
```

### Fixtures with faker

```python
# conftest.py
import pytest
from faker import Faker

@pytest.fixture
def fake():
    """Provide faker instance for test data generation"""
    return Faker()

@pytest.fixture
def fake_user(fake):
    """Generate fake user data"""
    return {
        "name": fake.name(),
        "email": fake.email(),
        "address": fake.address(),
        "phone": fake.phone_number()
    }

# test_api.py
def test_create_user(fake_user):
    """Test user creation with fake data"""
    response = create_user(fake_user)
    assert response["email"] == fake_user["email"]
```

## Best Practices

### Test Organization

```text
tests/
├── conftest.py          # Shared fixtures and configuration
├── unit/                # Unit tests
│   ├── conftest.py      # Unit test fixtures
│   ├── test_models.py
│   ├── test_utils.py
│   └── test_services.py
├── integration/         # Integration tests
│   ├── conftest.py      # Integration test fixtures
│   ├── test_api.py
│   └── test_database.py
├── functional/          # Functional tests
│   ├── conftest.py
│   └── test_workflows.py
└── smoke/               # Smoke tests
    └── test_smoke.py
```

### Test Naming Conventions

```python
# Good test names
def test_user_creation_with_valid_data():
    """Test that user is created successfully with valid data"""
    pass

def test_user_creation_fails_with_duplicate_email():
    """Test that user creation fails when email already exists"""
    pass

def test_password_hashing_uses_bcrypt():
    """Test that password is hashed using bcrypt algorithm"""
    pass

# Avoid vague names
def test_user():  # What about user?
    pass

def test_edge_case():  # Which edge case?
    pass
```

### Test Independence

```python
# Good - tests are independent
def test_create_user(db_session):
    """Each test gets fresh database session"""
    user = User(username="testuser")
    db_session.add(user)
    db_session.commit()
    assert User.query.count() == 1

def test_update_user(db_session):
    """This test doesn't depend on previous test"""
    user = User(username="testuser")
    db_session.add(user)
    db_session.commit()
    user.username = "newname"
    db_session.commit()
    assert user.username == "newname"

# Avoid - tests depend on each other
class TestUserWorkflow:
    user_id = None
    
    def test_1_create_user(self):
        """Creates user for later tests"""
        user = create_user()
        self.user_id = user.id  # Bad - shared state
    
    def test_2_update_user(self):
        """Depends on test_1 running first"""
        user = get_user(self.user_id)  # Fails if test_1 skipped
        update_user(user)
```

### Appropriate Test Scope

```python
# Unit test - fast, isolated
def test_calculate_total():
    """Test calculation logic only"""
    items = [{"price": 10, "quantity": 2}, {"price": 15, "quantity": 1}]
    total = calculate_total(items)
    assert total == 35

# Integration test - tests multiple components
def test_order_processing(db_session, payment_service):
    """Test order processing with database and payment service"""
    order = create_order(items=[{"id": 1, "quantity": 2}])
    result = process_order(order, payment_service)
    assert result.status == "completed"
    assert db_session.query(Order).filter_by(id=order.id).first().paid is True

# End-to-end test - tests full workflow
def test_complete_purchase_workflow(browser):
    """Test complete purchase from UI to database"""
    browser.get("/products")
    browser.find_element_by_id("product-1").click()
    browser.find_element_by_id("add-to-cart").click()
    browser.find_element_by_id("checkout").click()
    # ... complete checkout process
    assert "Order Confirmed" in browser.page_source
```

### Meaningful Assertions

```python
# Good - specific assertions
def test_user_api_response():
    """Test user API returns correct data"""
    response = api.get_user(1)
    assert response.status_code == 200
    assert response.json()["username"] == "testuser"
    assert response.json()["email"] == "test@example.com"
    assert response.json()["is_active"] is True

# Avoid - vague assertions
def test_user_api_response():
    """Test user API"""
    response = api.get_user(1)
    assert response  # What are we testing?
```

## Troubleshooting

### Common Issues

#### Tests Pass Locally but Fail in CI

```python
# Problem: Tests depend on local environment
def test_file_processing():
    with open("/tmp/test.txt") as f:  # Hardcoded path
        data = f.read()

# Solution: Use fixtures with proper paths
@pytest.fixture
def test_file(tmp_path):
    """Create test file in temporary directory"""
    file_path = tmp_path / "test.txt"
    file_path.write_text("test data")
    return file_path

def test_file_processing(test_file):
    with open(test_file) as f:
        data = f.read()
```

#### Flaky Tests

```python
# Problem: Test depends on timing
def test_async_operation():
    start_operation()
    time.sleep(1)  # Fragile timing
    assert operation_complete()

# Solution: Use proper synchronization
def test_async_operation():
    start_operation()
    wait_for_condition(lambda: operation_complete(), timeout=5)
    assert operation_complete()
```

#### Test Isolation Issues

```python
# Problem: Tests share mutable state
USERS = []

def test_add_user():
    USERS.append("user1")
    assert len(USERS) == 1  # Fails if other tests run first

# Solution: Use fixtures or reset state
@pytest.fixture(autouse=True)
def reset_users():
    global USERS
    USERS = []
    yield
    USERS = []
```

### Debug Strategies

```bash
# Run with verbose output and show locals
pytest -vv -l

# Run with pdb on failure
pytest --pdb

# Run with pdb on first failure
pytest -x --pdb

# Drop to pdb at start of test
pytest --trace

# Show print statements
pytest -s

# Disable output capturing
pytest --capture=no

# Show warnings
pytest -W all
```

## See Also

- [pytest Documentation](https://docs.pytest.org/)
- [pytest-xdist for Parallel Testing](https://github.com/pytest-dev/pytest-xdist)
- [tox for Test Automation](https://tox.wiki/)
- [GitHub Actions CI/CD](https://docs.github.com/en/actions)
- [Python Testing Overview](index.md)
- [Unit Testing Guide](unit-testing.md)
- [Integration Testing Guide](integration-testing.md)

## Additional Resources

### Documentation

- [pytest Documentation](https://docs.pytest.org/en/stable/)
- [unittest Documentation](https://docs.python.org/3/library/unittest.html)
- [tox Documentation](https://tox.wiki/en/latest/)
- [pytest-cov Documentation](https://pytest-cov.readthedocs.io/)

### Tools and Plugins

- [pytest-xdist](https://github.com/pytest-dev/pytest-xdist) - Parallel test execution
- [pytest-html](https://github.com/pytest-dev/pytest-html) - HTML test reports
- [pytest-benchmark](https://github.com/ionelmc/pytest-benchmark) - Performance benchmarking
- [pytest-testmon](https://github.com/tarpas/pytest-testmon) - Smart test selection
- [pytest-watch](https://github.com/joeyespo/pytest-watch) - Continuous testing

### Best Practices Guides

- [Python Testing Best Practices](https://docs.pytest.org/en/latest/goodpractices.html)
- [Test Automation Patterns](https://martinfowler.com/articles/practical-test-pyramid.html)
- [CI/CD Best Practices](https://www.jenkins.io/doc/book/pipeline/)
