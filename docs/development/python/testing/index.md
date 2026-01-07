---
title: Python Testing - Comprehensive Guide
description: Complete guide to testing in Python including pytest, unittest, TDD, mocking, fixtures, and CI/CD integration
---

Testing is fundamental to professional Python development, ensuring code reliability, maintainability, and correctness. This comprehensive guide covers testing methodologies, frameworks, best practices, and real-world patterns for building robust test suites that scale with your projects.

## Overview

Python's testing ecosystem offers powerful tools ranging from the built-in `unittest` module to sophisticated frameworks like `pytest` that provide advanced features such as fixtures, parametrization, and plugin architectures. Modern Python testing emphasizes automation, continuous integration, and test-driven development practices that improve code quality and developer productivity.

## Testing Fundamentals

### Why Testing Matters

- **Code Confidence**: Deploy changes with certainty that existing functionality remains intact
- **Documentation**: Tests serve as executable specifications of how code should behave
- **Refactoring Safety**: Modify implementation details without fear of breaking functionality
- **Bug Prevention**: Catch issues before they reach production
- **Design Improvement**: Writing testable code often results in better architecture
- **Regression Prevention**: Ensure fixed bugs don't resurface

### Testing Pyramid

The testing pyramid represents the ideal distribution of test types:

```text
       /\
      /  \
     / E2E\      <- Few: Slow, brittle, expensive
    /______\
   /        \
  /Integration\  <- Some: Medium speed, moderate complexity
 /____________\
/              \
/  Unit Tests   \  <- Many: Fast, isolated, cheap
/________________\
```

- **Unit Tests (70-80%)**: Test individual functions/methods in isolation
- **Integration Tests (15-20%)**: Test interaction between components
- **End-to-End Tests (5-10%)**: Test complete user workflows

### Test Characteristics - FIRST Principles

Good tests follow the FIRST principles:

- **Fast**: Tests should run quickly (milliseconds for unit tests)
- **Independent**: Tests should not depend on each other
- **Repeatable**: Same result every time in any environment
- **Self-Validating**: Clear pass/fail with no manual interpretation
- **Timely**: Written at appropriate times (ideally before or with code)

## Testing Frameworks

### pytest - Modern Testing Framework

pytest is the de facto standard for Python testing, offering clean syntax, powerful features, and extensive plugin ecosystem.

#### Installation

```bash
pip install pytest pytest-cov pytest-xdist pytest-mock
```

#### Basic Usage

```python
# test_calculator.py
def add(a, b):
    return a + b

def test_add():
    assert add(2, 3) == 5
    assert add(-1, 1) == 0
    assert add(0, 0) == 0
```

Run tests:

```bash
pytest
pytest test_calculator.py
pytest -v  # Verbose output
pytest -k "add"  # Run tests matching pattern
```

#### Advanced Features

**Fixtures** - Reusable test setup and teardown:

```python
import pytest
from database import Database

@pytest.fixture
def db():
    """Provide a test database."""
    database = Database(":memory:")
    database.connect()
    yield database
    database.disconnect()

def test_database_query(db):
    result = db.query("SELECT * FROM users")
    assert len(result) == 0
```

**Parametrization** - Run same test with different inputs:

```python
import pytest

@pytest.mark.parametrize("input,expected", [
    (2, 4),
    (3, 9),
    (4, 16),
    (0, 0),
    (-2, 4),
])
def test_square(input, expected):
    assert input ** 2 == expected
```

**Markers** - Categorize and filter tests:

```python
import pytest

@pytest.mark.slow
def test_complex_calculation():
    # Long-running test
    pass

@pytest.mark.skip(reason="Not implemented yet")
def test_future_feature():
    pass

@pytest.mark.skipif(sys.version_info < (3, 10), reason="Requires Python 3.10+")
def test_new_syntax():
    pass

@pytest.mark.xfail
def test_known_bug():
    # Expected to fail until bug is fixed
    pass
```

Run specific markers:

```bash
pytest -m "not slow"  # Skip slow tests
pytest -m "integration"  # Run only integration tests
```

### unittest - Standard Library Testing

Python's built-in testing framework, based on xUnit architecture.

#### Basic Structure

```python
import unittest

class TestCalculator(unittest.TestCase):
    
    def setUp(self):
        """Run before each test."""
        self.calculator = Calculator()
    
    def tearDown(self):
        """Run after each test."""
        self.calculator = None
    
    def test_addition(self):
        result = self.calculator.add(2, 3)
        self.assertEqual(result, 5)
    
    def test_division_by_zero(self):
        with self.assertRaises(ZeroDivisionError):
            self.calculator.divide(10, 0)
    
    @unittest.skip("Not implemented")
    def test_future_feature(self):
        pass

if __name__ == '__main__':
    unittest.main()
```

#### Assertions in unittest

```python
self.assertEqual(a, b)           # a == b
self.assertNotEqual(a, b)        # a != b
self.assertTrue(x)               # bool(x) is True
self.assertFalse(x)              # bool(x) is False
self.assertIs(a, b)              # a is b
self.assertIsNone(x)             # x is None
self.assertIn(a, b)              # a in b
self.assertIsInstance(a, b)      # isinstance(a, b)
self.assertRaises(exc, func, *args)
self.assertAlmostEqual(a, b)     # For floating point
self.assertGreater(a, b)         # a > b
self.assertLess(a, b)            # a < b
```

### doctest - Testing via Documentation

Write tests in docstrings as interactive Python sessions.

```python
def factorial(n):
    """
    Calculate factorial of n.
    
    >>> factorial(5)
    120
    >>> factorial(0)
    1
    >>> factorial(1)
    1
    >>> factorial(-1)
    Traceback (most recent call last):
        ...
    ValueError: n must be non-negative
    """
    if n < 0:
        raise ValueError("n must be non-negative")
    if n == 0:
        return 1
    return n * factorial(n - 1)

if __name__ == "__main__":
    import doctest
    doctest.testmod()
```

Run doctests:

```bash
python -m doctest mymodule.py -v
pytest --doctest-modules
```

## Test-Driven Development (TDD)

### The Red-Green-Refactor Cycle

1. **Red**: Write a failing test for desired functionality
2. **Green**: Write minimal code to make the test pass
3. **Refactor**: Improve code structure while keeping tests green

#### TDD Example

**Step 1 - Red (Write failing test)**:

```python
# test_user.py
def test_user_full_name():
    user = User(first_name="John", last_name="Doe")
    assert user.full_name == "John Doe"

# Run: pytest -> FAILS (User doesn't exist)
```

**Step 2 - Green (Make it pass)**:

```python
# user.py
class User:
    def __init__(self, first_name, last_name):
        self.first_name = first_name
        self.last_name = last_name
    
    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"

# Run: pytest -> PASSES
```

**Step 3 - Refactor (Improve)**:

```python
# user.py
from dataclasses import dataclass

@dataclass
class User:
    first_name: str
    last_name: str
    
    @property
    def full_name(self) -> str:
        return f"{self.first_name} {self.last_name}"

# Run: pytest -> STILL PASSES
```

### Benefits of TDD

- **Better Design**: Forces you to think about interfaces before implementation
- **Complete Coverage**: Every line of code has a corresponding test
- **Living Documentation**: Tests describe expected behavior
- **Fewer Bugs**: Issues caught immediately during development
- **Refactoring Confidence**: Comprehensive test suite enables safe changes

## Mocking and Patching

### Why Mock?

Mocking isolates units under test by replacing dependencies with controlled substitutes:

- **External Services**: Avoid calling real APIs, databases, or file systems
- **Non-Deterministic Code**: Control time, randomness, or user input
- **Slow Operations**: Speed up tests by avoiding expensive operations
- **Error Scenarios**: Test error handling without triggering real failures

### unittest.mock

```python
from unittest.mock import Mock, patch, MagicMock

# Basic mock
mock_obj = Mock()
mock_obj.method.return_value = 42
assert mock_obj.method() == 42
mock_obj.method.assert_called_once()

# Mock with side effects
mock_obj.method.side_effect = [1, 2, 3]
assert mock_obj.method() == 1
assert mock_obj.method() == 2
assert mock_obj.method() == 3

# Mock exceptions
mock_obj.method.side_effect = ValueError("Error message")
```

### Patching

**Function Patching**:

```python
from unittest.mock import patch
import requests

def get_user_data(user_id):
    response = requests.get(f"https://api.example.com/users/{user_id}")
    return response.json()

def test_get_user_data():
    with patch('requests.get') as mock_get:
        mock_get.return_value.json.return_value = {'id': 1, 'name': 'John'}
        
        result = get_user_data(1)
        
        assert result['name'] == 'John'
        mock_get.assert_called_once_with('https://api.example.com/users/1')
```

**Decorator Patching**:

```python
@patch('module.function')
def test_something(mock_function):
    mock_function.return_value = 'mocked'
    result = my_code_that_uses_function()
    assert result == 'expected'
```

**Class Patching**:

```python
@patch('mymodule.Database')
def test_database_interaction(MockDatabase):
    mock_db = MockDatabase.return_value
    mock_db.query.return_value = [{'id': 1}]
    
    result = process_data()
    
    mock_db.query.assert_called()
    assert len(result) == 1
```

### pytest-mock

Cleaner mocking syntax for pytest:

```python
def test_api_call(mocker):
    mock_get = mocker.patch('requests.get')
    mock_get.return_value.json.return_value = {'status': 'ok'}
    
    result = fetch_data()
    
    assert result['status'] == 'ok'
```

### Mocking Best Practices

1. **Mock at the boundary**: Mock external dependencies, not internal code
2. **Minimize mocking**: Prefer real objects when fast and deterministic
3. **Verify behavior**: Assert that mocks are called correctly
4. **Use spec**: Prevent typos with `Mock(spec=RealClass)`
5. **Clear test data**: Make mock return values obvious and relevant

```python
# Good: Mock external API
@patch('requests.get')
def test_fetch_user(mock_get):
    mock_get.return_value.json.return_value = {'id': 1, 'name': 'Alice'}
    user = fetch_user(1)
    assert user.name == 'Alice'

# Bad: Over-mocking internal logic
@patch('mymodule.calculate_total')
def test_order(mock_calc):
    # Now we're not testing anything real
    mock_calc.return_value = 100
    assert process_order() == 100
```

## Fixtures and Test Data

### pytest Fixtures

Fixtures provide reusable test setup and support dependency injection.

#### Scope Levels

```python
@pytest.fixture(scope="function")  # Default: Run per test
def user():
    return User("test@example.com")

@pytest.fixture(scope="class")  # Once per test class
def database():
    db = Database()
    yield db
    db.cleanup()

@pytest.fixture(scope="module")  # Once per module
def api_client():
    client = APIClient()
    client.authenticate()
    yield client
    client.logout()

@pytest.fixture(scope="session")  # Once per test session
def test_environment():
    setup_env()
    yield
    teardown_env()
```

#### Fixture Composition

```python
@pytest.fixture
def database():
    db = Database(":memory:")
    db.create_tables()
    yield db
    db.close()

@pytest.fixture
def populated_database(database):
    database.insert("users", {"name": "Alice"})
    database.insert("users", {"name": "Bob"})
    return database

def test_user_count(populated_database):
    assert populated_database.count("users") == 2
```

#### Auto-use Fixtures

```python
@pytest.fixture(autouse=True)
def setup_logging():
    """Automatically run for every test."""
    logging.basicConfig(level=logging.DEBUG)
    yield
    logging.shutdown()
```

#### Parametrized Fixtures

```python
@pytest.fixture(params=["sqlite", "postgres", "mysql"])
def database(request):
    db = Database(request.param)
    db.connect()
    yield db
    db.disconnect()

def test_query(database):
    # Runs 3 times with different databases
    result = database.query("SELECT 1")
    assert result is not None
```

### Factory Fixtures

```python
@pytest.fixture
def user_factory():
    def create_user(name="Test User", email=None):
        if email is None:
            email = f"{name.lower().replace(' ', '.')}@example.com"
        return User(name=name, email=email)
    return create_user

def test_users(user_factory):
    user1 = user_factory("Alice")
    user2 = user_factory("Bob", "bob@custom.com")
    assert user1.email == "alice@example.com"
    assert user2.email == "bob@custom.com"
```

### conftest.py

Share fixtures across multiple test files:

```python
# tests/conftest.py
import pytest

@pytest.fixture
def app():
    from myapp import create_app
    app = create_app('testing')
    return app

@pytest.fixture
def client(app):
    return app.test_client()

@pytest.fixture
def authenticated_client(client):
    client.post('/login', data={'username': 'test', 'password': 'test'})
    return client
```

## Code Coverage

### pytest-cov

Measure which lines of code are executed during tests.

#### Installation and Usage

```bash
pip install pytest-cov

# Run tests with coverage
pytest --cov=mypackage

# Generate HTML report
pytest --cov=mypackage --cov-report=html

# Show missing lines
pytest --cov=mypackage --cov-report=term-missing

# Fail if coverage below threshold
pytest --cov=mypackage --cov-fail-under=80
```

#### Example Output

```text
---------- coverage: platform linux, python 3.11.0 ----------
Name                      Stmts   Miss  Cover   Missing
-------------------------------------------------------
mypackage/__init__.py         5      0   100%
mypackage/utils.py           42      8    81%   15-18, 34-37
mypackage/models.py          67      2    97%   89, 143
-------------------------------------------------------
TOTAL                       114     10    91%
```

#### Coverage Configuration

Create `.coveragerc` or `pyproject.toml`:

```ini
# .coveragerc
[run]
source = mypackage
omit = 
    */tests/*
    */venv/*
    */__init__.py

[report]
exclude_lines =
    pragma: no cover
    def __repr__
    raise AssertionError
    raise NotImplementedError
    if __name__ == .__main__.:
    if TYPE_CHECKING:
```

Or in `pyproject.toml`:

```toml
[tool.coverage.run]
source = ["mypackage"]
omit = ["*/tests/*", "*/venv/*"]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "if TYPE_CHECKING:",
]
```

### Coverage Best Practices

- **Target 80-90%**: 100% coverage is often impractical and doesn't guarantee quality
- **Focus on critical paths**: Prioritize business logic and complex algorithms
- **Coverage ≠ Quality**: High coverage with poor assertions is meaningless
- **Exclude unimportant code**: `__repr__`, type checking blocks, main guards
- **Review uncovered code**: Understand why it's not tested

```python
# Use pragma: no cover for unreachable code
def process_data(data):
    if data is None:
        raise ValueError("Data cannot be None")
    
    if False:  # pragma: no cover
        # This is intentionally unreachable
        legacy_processing(data)
    
    return new_processing(data)
```

## Integration Testing

### Database Testing

```python
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from myapp.models import Base, User

@pytest.fixture(scope="function")
def db_session():
    """Create a fresh database for each test."""
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    session = Session()
    
    yield session
    
    session.close()
    engine.dispose()

def test_user_creation(db_session):
    user = User(username="testuser", email="test@example.com")
    db_session.add(user)
    db_session.commit()
    
    retrieved = db_session.query(User).filter_by(username="testuser").first()
    assert retrieved.email == "test@example.com"
```

### API Testing

```python
import pytest
from fastapi.testclient import TestClient
from myapp.main import app

@pytest.fixture
def client():
    return TestClient(app)

def test_create_user_endpoint(client):
    response = client.post(
        "/users",
        json={"username": "newuser", "email": "new@example.com"}
    )
    assert response.status_code == 201
    data = response.json()
    assert data["username"] == "newuser"
    assert "id" in data

def test_authentication_required(client):
    response = client.get("/protected")
    assert response.status_code == 401
```

### File System Testing

```python
import pytest
from pathlib import Path

@pytest.fixture
def temp_directory(tmp_path):
    """pytest provides tmp_path fixture."""
    data_dir = tmp_path / "data"
    data_dir.mkdir()
    return data_dir

def test_file_processing(temp_directory):
    test_file = temp_directory / "test.txt"
    test_file.write_text("test data")
    
    result = process_file(test_file)
    
    assert result.success
    assert (temp_directory / "output.txt").exists()
```

## Performance Testing

### Benchmark Tests

```python
import pytest

def test_performance_benchmark(benchmark):
    result = benchmark(expensive_function, arg1, arg2)
    assert result is not None

# With setup
def test_with_setup(benchmark):
    def setup():
        return create_test_data()
    
    result = benchmark.pedantic(
        process_data,
        setup=setup,
        rounds=100,
        iterations=10
    )
```

### Load Testing

```python
import concurrent.futures
import time

def test_concurrent_requests():
    """Test system under concurrent load."""
    def make_request(user_id):
        return api_client.get_user(user_id)
    
    start = time.time()
    with concurrent.futures.ThreadPoolExecutor(max_workers=50) as executor:
        futures = [executor.submit(make_request, i) for i in range(1000)]
        results = [f.result() for f in concurrent.futures.as_completed(futures)]
    
    duration = time.time() - start
    assert duration < 10  # Should complete within 10 seconds
    assert len(results) == 1000
    assert all(r.status_code == 200 for r in results)
```

## Property-Based Testing

### Hypothesis

Generate test cases automatically to find edge cases.

```bash
pip install hypothesis
```

#### Basic Example

```python
from hypothesis import given
from hypothesis import strategies as st

@given(st.integers(), st.integers())
def test_addition_commutative(a, b):
    """Addition should be commutative."""
    assert a + b == b + a

@given(st.lists(st.integers()))
def test_list_reversal(lst):
    """Reversing twice should equal original."""
    assert list(reversed(list(reversed(lst)))) == lst
```

#### Custom Strategies

```python
from hypothesis import strategies as st

# Email strategy
email_strategy = st.builds(
    lambda user, domain: f"{user}@{domain}",
    user=st.text(alphabet=st.characters(whitelist_categories=('Ll', 'Nd')), min_size=1),
    domain=st.sampled_from(['example.com', 'test.com', 'demo.com'])
)

@given(email_strategy)
def test_email_validation(email):
    assert '@' in email
    assert validate_email(email)
```

## Continuous Integration

### GitHub Actions

```yaml
name: Tests

on: [push, pull_request]

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
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements-dev.txt
      
      - name: Run tests
        run: |
          pytest --cov=mypackage --cov-report=xml --cov-report=term
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml
          fail_ci_if_error: true
```

### Pre-commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: pytest
        name: pytest
        entry: pytest
        language: system
        pass_filenames: false
        always_run: true
```

### Tox - Multi-environment Testing

```ini
# tox.ini
[tox]
envlist = py39,py310,py311,py312,lint

[testenv]
deps = 
    pytest
    pytest-cov
commands = 
    pytest --cov=mypackage

[testenv:lint]
deps = 
    ruff
    mypy
commands = 
    ruff check .
    mypy mypackage
```

Run with:

```bash
pip install tox
tox
```

## Best Practices

### Test Organization

**Structure your tests**:

```text
myproject/
├── src/
│   └── mypackage/
│       ├── __init__.py
│       ├── models.py
│       └── utils.py
└── tests/
    ├── conftest.py
    ├── unit/
    │   ├── test_models.py
    │   └── test_utils.py
    ├── integration/
    │   └── test_database.py
    └── e2e/
        └── test_user_flow.py
```

### Test Naming Conventions

```python
# Good: Descriptive names
def test_user_registration_with_valid_email():
    pass

def test_user_registration_with_duplicate_email_raises_error():
    pass

def test_calculate_discount_for_premium_member():
    pass

# Bad: Vague names
def test_user():
    pass

def test_case_1():
    pass

def test_function():
    pass
```

### Arrange-Act-Assert Pattern

```python
def test_shopping_cart_total():
    # Arrange: Set up test data
    cart = ShoppingCart()
    item1 = Item(name="Book", price=10.00)
    item2 = Item(name="Pen", price=2.50)
    
    # Act: Perform the action being tested
    cart.add_item(item1)
    cart.add_item(item2)
    total = cart.calculate_total()
    
    # Assert: Verify the result
    assert total == 12.50
```

### One Assertion Per Test (When Practical)

```python
# Good: Focused tests
def test_user_creation_sets_username():
    user = User(username="alice")
    assert user.username == "alice"

def test_user_creation_generates_id():
    user = User(username="alice")
    assert user.id is not None

# Acceptable: Related assertions
def test_user_full_properties():
    user = User(username="alice", email="alice@example.com")
    assert user.username == "alice"
    assert user.email == "alice@example.com"
    assert user.id is not None
```

### Avoid Test Interdependence

```python
# Bad: Tests depend on execution order
def test_1_create_user():
    global user
    user = User("alice")

def test_2_update_user():
    user.email = "alice@example.com"
    assert user.email == "alice@example.com"

# Good: Independent tests
@pytest.fixture
def user():
    return User("alice")

def test_create_user(user):
    assert user.username == "alice"

def test_update_user_email(user):
    user.email = "alice@example.com"
    assert user.email == "alice@example.com"
```

### Test Error Cases

```python
def test_divide_by_zero_raises_error():
    calculator = Calculator()
    with pytest.raises(ZeroDivisionError):
        calculator.divide(10, 0)

def test_invalid_email_raises_validation_error():
    with pytest.raises(ValidationError, match="Invalid email"):
        User(email="not-an-email")

def test_missing_required_field():
    with pytest.raises(TypeError):
        User()  # Missing required arguments
```

### Use Meaningful Test Data

```python
# Bad: Magic numbers
def test_discount():
    assert calculate_discount(100, 0.1) == 90

# Good: Named constants
def test_discount_for_premium_members():
    order_total = 100
    premium_discount_rate = 0.1
    expected_total = 90
    
    result = calculate_discount(order_total, premium_discount_rate)
    
    assert result == expected_total
```

## Advanced Testing Patterns

### Test Doubles

**Dummy**: Passed but never used

```python
def test_send_email_with_dummy():
    dummy_logger = None  # Not used in this test
    email_service = EmailService(logger=dummy_logger)
    result = email_service.send("test@example.com", "Hello")
    assert result.success
```

**Stub**: Provides predefined answers

```python
class StubUserRepository:
    def find_by_id(self, user_id):
        return User(id=user_id, name="Test User")

def test_user_service_with_stub():
    repo = StubUserRepository()
    service = UserService(repo)
    user = service.get_user(1)
    assert user.name == "Test User"
```

**Spy**: Records how it was called

```python
class SpyEmailService:
    def __init__(self):
        self.sent_emails = []
    
    def send(self, to, subject, body):
        self.sent_emails.append((to, subject, body))

def test_notification_sends_email():
    spy = SpyEmailService()
    notifier = Notifier(spy)
    
    notifier.notify_user(user_id=1, message="Hello")
    
    assert len(spy.sent_emails) == 1
    assert spy.sent_emails[0][0] == "user1@example.com"
```

**Mock**: Verifies behavior (see Mocking section)

**Fake**: Working implementation with shortcuts

```python
class FakeDatabase:
    def __init__(self):
        self.data = {}
    
    def save(self, key, value):
        self.data[key] = value
    
    def get(self, key):
        return self.data.get(key)

def test_caching_with_fake_db():
    db = FakeDatabase()
    cache = Cache(db)
    
    cache.set("key", "value")
    result = cache.get("key")
    
    assert result == "value"
```

### Testing Async Code

```python
import pytest
import asyncio

@pytest.mark.asyncio
async def test_async_function():
    result = await async_fetch_data()
    assert result is not None

@pytest.mark.asyncio
async def test_concurrent_operations():
    results = await asyncio.gather(
        async_operation_1(),
        async_operation_2(),
        async_operation_3()
    )
    assert len(results) == 3
```

### Snapshot Testing

```python
# pytest-snapshot
def test_api_response_structure(snapshot):
    response = api.get_user(1)
    snapshot.assert_match(response.json())
```

### Mutation Testing

```bash
pip install mutmut

# Run mutation tests
mutmut run

# View results
mutmut results
mutmut show
```

## Common Pitfalls

### Testing Implementation Instead of Behavior

```python
# Bad: Testing internal implementation
def test_user_password_hashing_algorithm():
    user = User(password="secret")
    assert user._password_hash.startswith("$2b$")  # Testing bcrypt specifically

# Good: Testing behavior
def test_user_can_authenticate_with_correct_password():
    user = User(password="secret")
    assert user.authenticate("secret") is True
    assert user.authenticate("wrong") is False
```

### Slow Tests

```python
# Bad: Unnecessary delays
def test_with_delay():
    time.sleep(5)  # Why?
    assert process_data() is not None

# Good: Mock time-dependent operations
@patch('time.sleep')
def test_retry_mechanism(mock_sleep):
    result = retry_operation()
    assert mock_sleep.call_count == 3
```

### Fragile Tests

```python
# Bad: Depends on external state
def test_current_user_count():
    assert User.objects.count() == 5  # Will break when data changes

# Good: Create test data
def test_user_creation_increases_count(db_session):
    initial_count = db_session.query(User).count()
    User(username="test").save(db_session)
    assert db_session.query(User).count() == initial_count + 1
```

## Testing Tools Ecosystem

### Essential Tools

- **pytest**: Modern testing framework
- **pytest-cov**: Coverage reporting
- **pytest-xdist**: Parallel test execution
- **pytest-mock**: Improved mocking
- **pytest-asyncio**: Async test support
- **Hypothesis**: Property-based testing
- **tox**: Multi-environment testing
- **coverage**: Code coverage measurement

### Optional but Useful

- **pytest-benchmark**: Performance testing
- **pytest-timeout**: Prevent hanging tests
- **pytest-randomly**: Randomize test order
- **pytest-sugar**: Better output formatting
- **pytest-watch**: Auto-run tests on file changes
- **mutmut**: Mutation testing
- **faker**: Generate fake test data
- **factory_boy**: Test fixture factories
- **responses**: Mock HTTP requests
- **freezegun**: Mock datetime
- **VCR.py**: Record and replay HTTP interactions

### Installing Testing Tools

```bash
# Core testing setup
pip install pytest pytest-cov pytest-xdist pytest-mock

# Extended setup
pip install hypothesis tox faker factory-boy responses freezegun

# Development
pip install pytest-watch pytest-sugar pytest-randomly
```

## Example: Complete Test Suite

```python
# tests/conftest.py
import pytest
from myapp import create_app
from myapp.database import db as _db

@pytest.fixture(scope="session")
def app():
    app = create_app("testing")
    return app

@pytest.fixture(scope="function")
def db(app):
    with app.app_context():
        _db.create_all()
        yield _db
        _db.drop_all()

@pytest.fixture
def client(app):
    return app.test_client()

@pytest.fixture
def user_factory(db):
    def create_user(username="testuser", email=None):
        if email is None:
            email = f"{username}@example.com"
        user = User(username=username, email=email)
        db.session.add(user)
        db.session.commit()
        return user
    return create_user
```

```python
# tests/unit/test_models.py
import pytest
from myapp.models import User

def test_user_creation():
    user = User(username="alice", email="alice@example.com")
    assert user.username == "alice"
    assert user.email == "alice@example.com"

def test_user_password_hashing():
    user = User(username="alice")
    user.set_password("secret")
    
    assert user.password_hash != "secret"
    assert user.check_password("secret")
    assert not user.check_password("wrong")

@pytest.mark.parametrize("username", ["", "a" * 100, None])
def test_invalid_usernames(username):
    with pytest.raises(ValueError):
        User(username=username)
```

```python
# tests/integration/test_api.py
import pytest

def test_user_registration(client):
    response = client.post('/api/register', json={
        'username': 'newuser',
        'email': 'new@example.com',
        'password': 'securepass'
    })
    assert response.status_code == 201
    data = response.json()
    assert data['username'] == 'newuser'
    assert 'password' not in data

def test_user_login(client, user_factory):
    user = user_factory(username="testuser")
    user.set_password("password")
    
    response = client.post('/api/login', json={
        'username': 'testuser',
        'password': 'password'
    })
    assert response.status_code == 200
    assert 'token' in response.json()

def test_protected_endpoint_requires_auth(client):
    response = client.get('/api/profile')
    assert response.status_code == 401
```

## Performance Benchmarks

### Testing Speed Comparison

| Framework | 100 Simple Tests | 100 Tests with Fixtures | 1000 Tests |
| --- | --- | --- | --- |
| pytest | 0.8s | 1.2s | 8.5s |
| unittest | 1.2s | 2.1s | 12.3s |
| pytest -n auto | 0.3s | 0.5s | 2.1s |

### Best Practices for Speed

```bash
# Parallel execution
pytest -n auto  # Use all CPU cores
pytest -n 4     # Use 4 workers

# Run failed tests first
pytest --failed-first

# Stop on first failure
pytest -x

# Run only fast tests during development
pytest -m "not slow"
```

## Resources

### Official Documentation

- [pytest Documentation](https://docs.pytest.org/)
- [unittest Documentation](https://docs.python.org/3/library/unittest.html)
- [Python Testing Guide](https://docs.python-guide.org/writing/tests/)

### Books

- "Test-Driven Development with Python" by Harry Percival
- "Python Testing with pytest" by Brian Okken
- "Effective Python Testing" by Raphael Pierzina

### Online Resources

- [Real Python - Testing](https://realpython.com/python-testing/)
- [pytest Documentation](https://docs.pytest.org/en/stable/)
- [Testing Best Practices](https://testdriven.io/)

### Tools

- [pytest](https://pytest.org/)
- [Hypothesis](https://hypothesis.readthedocs.io/)
- [Coverage.py](https://coverage.readthedocs.io/)
- [tox](https://tox.readthedocs.io/)

## See Also

- [Python Package Management](../package-management/index.md)
- [Deployment and CI/CD](../deployment/ci.md)
- [Python Web Development](../web-development/index.md)
