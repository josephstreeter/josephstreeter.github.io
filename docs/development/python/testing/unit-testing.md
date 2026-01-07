---
title: Python Unit Testing - Complete Guide to Testing Individual Components
description: Comprehensive guide to Python unit testing with unittest and pytest frameworks, including fixtures, mocking, assertions, test patterns, and best practices
---

Unit testing is the practice of testing individual components, functions, or methods in isolation from the rest of the application. It forms the foundation of a robust testing strategy by verifying that each piece of code works correctly on its own before integration with other components.

## Overview

Unit tests are small, fast, and focused tests that verify the behavior of a single unit of code. They run in isolation, typically with dependencies mocked or stubbed, ensuring that failures point directly to the problematic code. Well-written unit tests serve as executable documentation, facilitate refactoring, and catch bugs early in the development cycle.

**Key Characteristics of Unit Tests**:

- **Fast**: Execute in milliseconds, enabling rapid feedback
- **Isolated**: Test one thing at a time without external dependencies
- **Repeatable**: Produce consistent results regardless of execution order
- **Self-validating**: Pass or fail without manual interpretation
- **Timely**: Written alongside or before the code they test

**Benefits**:

- Early bug detection during development
- Confidence when refactoring code
- Living documentation of code behavior
- Simplified debugging with focused test scope
- Reduced cost of fixing defects

## Python Testing Frameworks

### unittest Framework

Python's built-in `unittest` framework follows the xUnit architecture, providing a comprehensive testing infrastructure based on classes and methods.

**Basic Structure**:

```python
# test_calculator.py
import unittest
from calculator import Calculator

class TestCalculator(unittest.TestCase):
    """Test suite for Calculator class"""
    
    def setUp(self):
        """Run before each test method"""
        self.calc = Calculator()
    
    def tearDown(self):
        """Run after each test method"""
        self.calc = None
    
    def test_addition(self):
        """Test addition operation"""
        result = self.calc.add(2, 3)
        self.assertEqual(result, 5)
    
    def test_subtraction(self):
        """Test subtraction operation"""
        result = self.calc.subtract(10, 4)
        self.assertEqual(result, 6)
    
    def test_multiplication(self):
        """Test multiplication operation"""
        result = self.calc.multiply(3, 4)
        self.assertEqual(result, 12)
    
    def test_division(self):
        """Test division operation"""
        result = self.calc.divide(15, 3)
        self.assertEqual(result, 5.0)
    
    def test_division_by_zero(self):
        """Test that division by zero raises appropriate error"""
        with self.assertRaises(ZeroDivisionError):
            self.calc.divide(10, 0)

if __name__ == '__main__':
    unittest.main()
```

**Class Hierarchy**:

```python
import unittest

class TestBasicMath(unittest.TestCase):
    """Base test class with common setup"""
    
    @classmethod
    def setUpClass(cls):
        """Run once before all tests in this class"""
        cls.calculator = Calculator()
        print("Setting up TestBasicMath")
    
    @classmethod
    def tearDownClass(cls):
        """Run once after all tests in this class"""
        cls.calculator = None
        print("Tearing down TestBasicMath")
    
    def setUp(self):
        """Run before each test"""
        self.test_data = [1, 2, 3, 4, 5]
    
    def tearDown(self):
        """Run after each test"""
        self.test_data = None

class TestAdvancedMath(TestBasicMath):
    """Inherit setup from base class"""
    
    def test_power(self):
        """Test exponentiation"""
        result = self.calculator.power(2, 3)
        self.assertEqual(result, 8)
```

### pytest Framework

pytest is a modern, feature-rich testing framework that emphasizes simplicity and scalability. It uses plain functions and assert statements instead of classes and special assertion methods.

**Basic Structure**:

```python
# test_calculator_pytest.py
import pytest
from calculator import Calculator

@pytest.fixture
def calculator():
    """Provide a Calculator instance for tests"""
    return Calculator()

def test_addition(calculator):
    """Test addition operation"""
    result = calculator.add(2, 3)
    assert result == 5

def test_subtraction(calculator):
    """Test subtraction operation"""
    result = calculator.subtract(10, 4)
    assert result == 6

def test_multiplication(calculator):
    """Test multiplication operation"""
    result = calculator.multiply(3, 4)
    assert result == 12

def test_division(calculator):
    """Test division operation"""
    result = calculator.divide(15, 3)
    assert result == 5.0

def test_division_by_zero(calculator):
    """Test that division by zero raises appropriate error"""
    with pytest.raises(ZeroDivisionError):
        calculator.divide(10, 0)
```

**Parametrized Tests**:

```python
import pytest

@pytest.mark.parametrize("a,b,expected", [
    (2, 3, 5),
    (0, 0, 0),
    (-1, 1, 0),
    (10, -5, 5),
    (100, 200, 300),
])
def test_addition_parametrized(calculator, a, b, expected):
    """Test addition with multiple input combinations"""
    result = calculator.add(a, b)
    assert result == expected

@pytest.mark.parametrize("numerator,denominator,expected", [
    (10, 2, 5.0),
    (7, 2, 3.5),
    (9, 3, 3.0),
    (-10, 2, -5.0),
])
def test_division_parametrized(calculator, numerator, denominator, expected):
    """Test division with various inputs"""
    result = calculator.divide(numerator, denominator)
    assert result == expected
```

## Assertions

### unittest Assertions

unittest provides numerous assertion methods for different comparison types:

**Equality Assertions**:

```python
import unittest

class TestAssertions(unittest.TestCase):
    def test_equality(self):
        """Test value equality"""
        self.assertEqual(5, 5)
        self.assertNotEqual(5, 3)
    
    def test_identity(self):
        """Test object identity"""
        x = [1, 2, 3]
        y = x
        self.assertIs(x, y)
        self.assertIsNot(x, [1, 2, 3])
    
    def test_boolean(self):
        """Test boolean values"""
        self.assertTrue(1 < 2)
        self.assertFalse(1 > 2)
    
    def test_none(self):
        """Test None values"""
        x = None
        self.assertIsNone(x)
        self.assertIsNotNone([])
```

**Comparison Assertions**:

```python
class TestComparisons(unittest.TestCase):
    def test_ordering(self):
        """Test numerical ordering"""
        self.assertGreater(10, 5)
        self.assertGreaterEqual(10, 10)
        self.assertLess(5, 10)
        self.assertLessEqual(5, 5)
    
    def test_almost_equal(self):
        """Test floating point equality with tolerance"""
        self.assertAlmostEqual(1.0, 1.0000001, places=5)
        self.assertNotAlmostEqual(1.0, 1.1, places=1)
```

**Collection Assertions**:

```python
class TestCollections(unittest.TestCase):
    def test_membership(self):
        """Test item in collection"""
        self.assertIn(3, [1, 2, 3, 4])
        self.assertNotIn(5, [1, 2, 3, 4])
    
    def test_isinstance(self):
        """Test instance type"""
        self.assertIsInstance("hello", str)
        self.assertNotIsInstance("hello", int)
    
    def test_sequence_equal(self):
        """Test sequence equality"""
        self.assertListEqual([1, 2, 3], [1, 2, 3])
        self.assertTupleEqual((1, 2), (1, 2))
        self.assertSetEqual({1, 2, 3}, {3, 2, 1})
        self.assertDictEqual({"a": 1}, {"a": 1})
    
    def test_count_equal(self):
        """Test elements match regardless of order"""
        self.assertCountEqual([1, 2, 3], [3, 1, 2])
```

**Exception Assertions**:

```python
class TestExceptions(unittest.TestCase):
    def test_raises_exception(self):
        """Test that exception is raised"""
        with self.assertRaises(ValueError):
            int("not a number")
    
    def test_raises_with_message(self):
        """Test exception with specific message"""
        with self.assertRaisesRegex(ValueError, "invalid literal"):
            int("not a number")
    
    def test_warns(self):
        """Test that warning is issued"""
        with self.assertWarns(DeprecationWarning):
            warnings.warn("deprecated", DeprecationWarning)
    
    def test_logs(self):
        """Test log messages"""
        with self.assertLogs("mylogger", level="INFO") as cm:
            logging.getLogger("mylogger").info("Test message")
        self.assertIn("Test message", cm.output[0])
```

### pytest Assertions

pytest uses Python's native `assert` statement with intelligent introspection:

**Basic Assertions**:

```python
def test_assertions():
    """Test various assertion types"""
    # Equality
    assert 5 == 5
    assert 5 != 3
    
    # Boolean
    assert True
    assert not False
    
    # Comparisons
    assert 10 > 5
    assert 10 >= 10
    assert 5 < 10
    assert 5 <= 5
    
    # Membership
    assert 3 in [1, 2, 3, 4]
    assert 5 not in [1, 2, 3, 4]
    
    # Identity
    assert None is None
    assert [] is not None
    
    # Type checking
    assert isinstance("hello", str)
```

**Advanced Assertions**:

```python
import pytest

def test_exception_info():
    """Test exception with detailed inspection"""
    with pytest.raises(ValueError) as exc_info:
        int("not a number")
    
    assert "invalid literal" in str(exc_info.value)
    assert exc_info.type is ValueError

def test_approximate_equality():
    """Test floating point approximate equality"""
    assert 0.1 + 0.2 == pytest.approx(0.3)
    assert [1.0, 2.0, 3.0] == pytest.approx([1.0001, 2.0001, 3.0001], rel=1e-3)

def test_string_matching():
    """Test string patterns"""
    text = "Hello, World!"
    assert "World" in text
    assert text.startswith("Hello")
    assert text.endswith("!")
```

**Custom Assertion Messages**:

```python
def test_with_messages():
    """Test with custom failure messages"""
    value = calculate_result()
    assert value > 0, f"Expected positive value, got {value}"
    
    items = get_items()
    assert len(items) == 5, f"Expected 5 items, got {len(items)}: {items}"
```

## Test Fixtures

### unittest Fixtures

unittest provides method-level and class-level setup/teardown hooks:

```python
import unittest
import tempfile
import os

class TestFileOperations(unittest.TestCase):
    """Test file operations with proper setup/teardown"""
    
    @classmethod
    def setUpClass(cls):
        """Create temporary directory for all tests"""
        cls.test_dir = tempfile.mkdtemp()
        print(f"Created test directory: {cls.test_dir}")
    
    @classmethod
    def tearDownClass(cls):
        """Remove temporary directory after all tests"""
        import shutil
        shutil.rmtree(cls.test_dir)
        print(f"Removed test directory: {cls.test_dir}")
    
    def setUp(self):
        """Create test file before each test"""
        self.test_file = os.path.join(self.test_dir, f"test_{self.id()}.txt")
        with open(self.test_file, 'w') as f:
            f.write("test content")
    
    def tearDown(self):
        """Clean up test file after each test"""
        if os.path.exists(self.test_file):
            os.remove(self.test_file)
    
    def test_file_read(self):
        """Test reading file content"""
        with open(self.test_file) as f:
            content = f.read()
        self.assertEqual(content, "test content")
    
    def test_file_write(self):
        """Test writing to file"""
        with open(self.test_file, 'a') as f:
            f.write(" appended")
        
        with open(self.test_file) as f:
            content = f.read()
        self.assertEqual(content, "test content appended")
```

### pytest Fixtures

pytest fixtures provide a flexible dependency injection system:

**Basic Fixtures**:

```python
import pytest
import tempfile
import os

@pytest.fixture
def temp_file():
    """Create temporary file for test"""
    fd, path = tempfile.mkstemp()
    yield path
    os.close(fd)
    os.remove(path)

@pytest.fixture
def temp_dir():
    """Create temporary directory for test"""
    path = tempfile.mkdtemp()
    yield path
    import shutil
    shutil.rmtree(path)

def test_file_operations(temp_file):
    """Test with temporary file"""
    with open(temp_file, 'w') as f:
        f.write("test data")
    
    with open(temp_file) as f:
        content = f.read()
    
    assert content == "test data"
```

**Fixture Scopes**:

```python
@pytest.fixture(scope="function")
def function_fixture():
    """New instance for each test function (default)"""
    return {"data": "function"}

@pytest.fixture(scope="class")
def class_fixture():
    """One instance for all tests in a class"""
    return {"data": "class"}

@pytest.fixture(scope="module")
def module_fixture():
    """One instance for all tests in a module"""
    db = Database()
    db.connect()
    yield db
    db.disconnect()

@pytest.fixture(scope="session")
def session_fixture():
    """One instance for entire test session"""
    config = load_configuration()
    yield config
    save_configuration(config)
```

**Fixture Composition**:

```python
@pytest.fixture
def database_connection():
    """Provide database connection"""
    conn = create_connection("test_db")
    yield conn
    conn.close()

@pytest.fixture
def database_session(database_connection):
    """Provide database session using connection fixture"""
    session = database_connection.create_session()
    yield session
    session.rollback()
    session.close()

@pytest.fixture
def populated_database(database_session):
    """Provide database with test data"""
    database_session.add(User(name="test_user"))
    database_session.commit()
    yield database_session

def test_user_query(populated_database):
    """Test using composed fixtures"""
    user = populated_database.query(User).first()
    assert user.name == "test_user"
```

**Parametrized Fixtures**:

```python
@pytest.fixture(params=[1, 2, 3, 4, 5])
def number(request):
    """Fixture that provides different values"""
    return request.param

def test_is_positive(number):
    """Test runs 5 times with different numbers"""
    assert number > 0

@pytest.fixture(params=["sqlite", "postgresql", "mysql"])
def database_type(request):
    """Test with different database types"""
    return request.param

def test_database_connection(database_type):
    """Test runs with each database type"""
    conn = create_connection(database_type)
    assert conn.is_connected()
```

**Autouse Fixtures**:

```python
@pytest.fixture(autouse=True)
def reset_state():
    """Automatically run before each test"""
    global_state.reset()
    yield
    global_state.cleanup()

@pytest.fixture(autouse=True, scope="module")
def module_setup():
    """Automatically run once per module"""
    setup_module_resources()
    yield
    cleanup_module_resources()
```

## Mocking and Test Doubles

### unittest.mock

Python's built-in `unittest.mock` module provides powerful mocking capabilities:

**Basic Mocking**:

```python
from unittest.mock import Mock, MagicMock, patch
import unittest

class TestUserService(unittest.TestCase):
    def test_get_user_with_mock(self):
        """Test using mock object"""
        # Create mock database
        mock_db = Mock()
        mock_db.get_user.return_value = {"id": 1, "name": "John"}
        
        # Use mock in service
        service = UserService(mock_db)
        user = service.get_user(1)
        
        # Verify results
        self.assertEqual(user["name"], "John")
        mock_db.get_user.assert_called_once_with(1)
    
    def test_get_user_not_found(self):
        """Test when user doesn't exist"""
        mock_db = Mock()
        mock_db.get_user.return_value = None
        
        service = UserService(mock_db)
        user = service.get_user(999)
        
        self.assertIsNone(user)
```

**Patching**:

```python
class TestEmailService(unittest.TestCase):
    @patch('smtplib.SMTP')
    def test_send_email(self, mock_smtp):
        """Test email sending with patched SMTP"""
        # Configure mock
        mock_smtp.return_value.__enter__.return_value.send_message.return_value = {}
        
        # Test email service
        service = EmailService()
        result = service.send_email("test@example.com", "Hello")
        
        # Verify SMTP was called correctly
        self.assertTrue(result)
        mock_smtp.assert_called_once()
    
    @patch('requests.get')
    def test_api_call(self, mock_get):
        """Test API call with mocked requests"""
        # Setup mock response
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"data": "test"}
        mock_get.return_value = mock_response
        
        # Make API call
        api = APIClient()
        result = api.get_data()
        
        # Verify
        self.assertEqual(result["data"], "test")
        mock_get.assert_called_once_with("https://api.example.com/data")
```

**Context Manager Patching**:

```python
import unittest
from unittest.mock import patch, mock_open

class TestFileOperations(unittest.TestCase):
    def test_read_file(self):
        """Test reading file with mocked open"""
        mock_data = "file content"
        with patch("builtins.open", mock_open(read_data=mock_data)):
            content = read_file("test.txt")
            self.assertEqual(content, mock_data)
    
    def test_write_file(self):
        """Test writing file with mocked open"""
        m = mock_open()
        with patch("builtins.open", m):
            write_file("test.txt", "new content")
            m.assert_called_once_with("test.txt", 'w')
            m().write.assert_called_once_with("new content")
```

**Multiple Patches**:

```python
class TestMultiplePatches(unittest.TestCase):
    @patch('module.function_c')
    @patch('module.function_b')
    @patch('module.function_a')
    def test_with_multiple_patches(self, mock_a, mock_b, mock_c):
        """Test with multiple patched functions (reverse order)"""
        mock_a.return_value = "A"
        mock_b.return_value = "B"
        mock_c.return_value = "C"
        
        result = complex_operation()
        
        mock_a.assert_called_once()
        mock_b.assert_called_once()
        mock_c.assert_called_once()
```

**patch.object**:

```python
class TestPatchObject(unittest.TestCase):
    def test_patch_method(self):
        """Test patching specific method on object"""
        obj = MyClass()
        with patch.object(obj, 'method', return_value="mocked"):
            result = obj.method()
            self.assertEqual(result, "mocked")
    
    def test_patch_class_attribute(self):
        """Test patching class attribute"""
        with patch.object(MyClass, 'CLASS_ATTR', "new_value"):
            self.assertEqual(MyClass.CLASS_ATTR, "new_value")
```

### pytest Mocking

pytest works seamlessly with unittest.mock and provides additional plugins:

**Using pytest-mock**:

```python
import pytest

def test_with_mocker(mocker):
    """Test using pytest-mock's mocker fixture"""
    # Create mock
    mock_db = mocker.Mock()
    mock_db.get_user.return_value = {"id": 1, "name": "John"}
    
    # Use in test
    service = UserService(mock_db)
    user = service.get_user(1)
    
    assert user["name"] == "John"
    mock_db.get_user.assert_called_once_with(1)

def test_patch_function(mocker):
    """Test patching with mocker"""
    mock_get = mocker.patch('requests.get')
    mock_get.return_value.status_code = 200
    mock_get.return_value.json.return_value = {"data": "test"}
    
    api = APIClient()
    result = api.get_data()
    
    assert result["data"] == "test"

def test_spy(mocker):
    """Test with spy that wraps real function"""
    spy = mocker.spy(math, 'sqrt')
    
    result = calculate_distance(3, 4)
    
    assert result == 5
    spy.assert_called_once_with(25)
```

**Monkeypatch Fixture**:

```python
def test_with_monkeypatch(monkeypatch):
    """Test using monkeypatch for attributes and env vars"""
    # Patch function
    def mock_get_user(user_id):
        return {"id": user_id, "name": "Mocked"}
    
    monkeypatch.setattr("mymodule.get_user", mock_get_user)
    
    # Patch environment variable
    monkeypatch.setenv("API_KEY", "test_key")
    
    # Patch dictionary
    monkeypatch.setitem(config, "debug", True)
    
    # Test code
    result = perform_operation()
    assert result is not None
```

## Test Organization Patterns

### Arrange-Act-Assert (AAA)

The AAA pattern structures tests into three clear sections:

```python
def test_user_creation():
    """Test user creation with AAA pattern"""
    # Arrange - Setup test data and dependencies
    username = "testuser"
    email = "test@example.com"
    user_service = UserService()
    
    # Act - Execute the operation being tested
    user = user_service.create_user(username, email)
    
    # Assert - Verify the results
    assert user.username == username
    assert user.email == email
    assert user.id is not None
    assert user.created_at is not None
```

### Given-When-Then (GWT)

BDD-style structure that emphasizes behavior:

```python
def test_user_login():
    """Test user login process
    
    Given a registered user with valid credentials
    When the user attempts to log in
    Then the user should be authenticated successfully
    """
    # Given
    user = create_test_user(username="testuser", password="password123")
    auth_service = AuthenticationService()
    
    # When
    result = auth_service.login("testuser", "password123")
    
    # Then
    assert result.success is True
    assert result.user_id == user.id
    assert result.token is not None
```

### Test Classes for Grouping

```python
import pytest

class TestUserAuthentication:
    """Group of tests for user authentication"""
    
    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup for all tests in this class"""
        self.auth_service = AuthenticationService()
        self.test_user = create_test_user()
    
    def test_successful_login(self):
        """Test login with valid credentials"""
        result = self.auth_service.login(
            self.test_user.username,
            "password123"
        )
        assert result.success is True
    
    def test_failed_login_wrong_password(self):
        """Test login with incorrect password"""
        result = self.auth_service.login(
            self.test_user.username,
            "wrongpassword"
        )
        assert result.success is False
    
    def test_failed_login_nonexistent_user(self):
        """Test login with nonexistent username"""
        result = self.auth_service.login(
            "nonexistent",
            "password123"
        )
        assert result.success is False

class TestUserRegistration:
    """Group of tests for user registration"""
    
    @pytest.fixture(autouse=True)
    def setup(self):
        self.user_service = UserService()
    
    def test_register_new_user(self):
        """Test registering a new user"""
        user = self.user_service.register(
            username="newuser",
            email="new@example.com",
            password="password123"
        )
        assert user.id is not None
    
    def test_register_duplicate_username(self):
        """Test that duplicate username is rejected"""
        self.user_service.register("duplicate", "first@example.com", "pass")
        
        with pytest.raises(DuplicateUsernameError):
            self.user_service.register("duplicate", "second@example.com", "pass")
```

## Code Coverage

### Using coverage.py

Measure code coverage to identify untested code:

**Installation**:

```bash
pip install coverage
```

**Basic Usage**:

```bash
# Run tests with coverage
coverage run -m pytest

# Generate report to terminal
coverage report

# Generate HTML report
coverage html

# View HTML report
open htmlcov/index.html
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

[report]
precision = 2
show_missing = True
skip_covered = False

[html]
directory = htmlcov
```

### pytest-cov Plugin

Integrate coverage with pytest:

```bash
# Install plugin
pip install pytest-cov

# Run tests with coverage
pytest --cov=src

# Generate HTML report
pytest --cov=src --cov-report=html

# Show missing lines
pytest --cov=src --cov-report=term-missing

# Fail if coverage below threshold
pytest --cov=src --cov-fail-under=80
```

**Configuration in pytest.ini**:

```ini
[pytest]
addopts =
    --cov=src
    --cov-report=html
    --cov-report=term-missing
    --cov-fail-under=80
```

### Branch Coverage

Test both branches of conditional statements:

```python
def calculate_discount(price, customer_type):
    """Calculate discount based on customer type"""
    if customer_type == "premium":
        return price * 0.8  # 20% discount
    else:
        return price * 0.95  # 5% discount

# Tests for branch coverage
def test_premium_discount():
    """Test premium customer discount"""
    result = calculate_discount(100, "premium")
    assert result == 80

def test_regular_discount():
    """Test regular customer discount"""
    result = calculate_discount(100, "regular")
    assert result == 95
```

**Enable branch coverage**:

```bash
pytest --cov=src --cov-branch
```

## Test-Driven Development (TDD)

### Red-Green-Refactor Cycle

TDD follows a disciplined cycle of writing tests first:

**1. Red - Write failing test**:

```python
def test_string_reverser():
    """Test string reversal function"""
    reverser = StringReverser()
    result = reverser.reverse("hello")
    assert result == "olleh"
```

**2. Green - Write minimal code to pass**:

```python
class StringReverser:
    def reverse(self, text):
        return text[::-1]
```

**3. Refactor - Improve code while keeping tests green**:

```python
class StringReverser:
    def reverse(self, text: str) -> str:
        """Reverse the input string
        
        Args:
            text: String to reverse
            
        Returns:
            Reversed string
        """
        if not isinstance(text, str):
            raise TypeError("Input must be a string")
        return text[::-1]

# Add tests for edge cases
def test_string_reverser_empty():
    """Test reversing empty string"""
    reverser = StringReverser()
    assert reverser.reverse("") == ""

def test_string_reverser_single_char():
    """Test reversing single character"""
    reverser = StringReverser()
    assert reverser.reverse("a") == "a"

def test_string_reverser_type_error():
    """Test type validation"""
    reverser = StringReverser()
    with pytest.raises(TypeError):
        reverser.reverse(123)
```

### Example TDD Session

**Requirement**: Implement a shopping cart that calculates totals with tax.

```python
# Step 1: Write first test (RED)
def test_empty_cart_total():
    """Empty cart should have zero total"""
    cart = ShoppingCart()
    assert cart.total() == 0

# Step 2: Minimal implementation (GREEN)
class ShoppingCart:
    def total(self):
        return 0

# Step 3: Add more tests (RED)
def test_cart_with_single_item():
    """Cart with one item should return item price"""
    cart = ShoppingCart()
    cart.add_item("Apple", 1.50)
    assert cart.total() == 1.50

# Step 4: Implement (GREEN)
class ShoppingCart:
    def __init__(self):
        self.items = []
    
    def add_item(self, name, price):
        self.items.append({"name": name, "price": price})
    
    def total(self):
        return sum(item["price"] for item in self.items)

# Step 5: Add tax calculation test (RED)
def test_cart_total_with_tax():
    """Cart should calculate total with tax"""
    cart = ShoppingCart(tax_rate=0.10)
    cart.add_item("Apple", 1.00)
    assert cart.total() == 1.10

# Step 6: Implement tax (GREEN)
class ShoppingCart:
    def __init__(self, tax_rate=0.0):
        self.items = []
        self.tax_rate = tax_rate
    
    def add_item(self, name, price):
        self.items.append({"name": name, "price": price})
    
    def total(self):
        subtotal = sum(item["price"] for item in self.items)
        return subtotal * (1 + self.tax_rate)

# Step 7: Refactor (GREEN)
from dataclasses import dataclass
from typing import List

@dataclass
class CartItem:
    name: str
    price: float

class ShoppingCart:
    def __init__(self, tax_rate: float = 0.0):
        self.items: List[CartItem] = []
        self.tax_rate = tax_rate
    
    def add_item(self, name: str, price: float) -> None:
        """Add item to cart"""
        self.items.append(CartItem(name, price))
    
    def subtotal(self) -> float:
        """Calculate subtotal without tax"""
        return sum(item.price for item in self.items)
    
    def total(self) -> float:
        """Calculate total with tax"""
        return self.subtotal() * (1 + self.tax_rate)
```

## Testing Edge Cases

### Boundary Value Testing

Test at the boundaries of valid input ranges:

```python
def test_age_validation():
    """Test age validation at boundaries"""
    validator = AgeValidator(min_age=18, max_age=120)
    
    # Below minimum
    assert validator.is_valid(17) is False
    
    # At minimum boundary
    assert validator.is_valid(18) is True
    
    # Within valid range
    assert validator.is_valid(50) is True
    
    # At maximum boundary
    assert validator.is_valid(120) is True
    
    # Above maximum
    assert validator.is_valid(121) is False
```

### Null and Empty Values

```python
def test_string_processor_edge_cases():
    """Test string processor with edge cases"""
    processor = StringProcessor()
    
    # None value
    with pytest.raises(TypeError):
        processor.process(None)
    
    # Empty string
    assert processor.process("") == ""
    
    # Whitespace only
    assert processor.process("   ") == ""
    
    # Single character
    assert processor.process("a") == "A"
```

### Large and Small Values

```python
import sys

def test_integer_operations_extreme_values():
    """Test with extreme integer values"""
    calc = Calculator()
    
    # Very large numbers
    large = sys.maxsize
    result = calc.add(large, 1)
    assert result > large
    
    # Very small numbers (negative)
    small = -sys.maxsize - 1
    result = calc.add(small, -1)
    assert result < small
    
    # Zero
    assert calc.multiply(1000000, 0) == 0
```

### Special Characters and Unicode

```python
def test_text_processor_special_characters():
    """Test with special characters and unicode"""
    processor = TextProcessor()
    
    # Special characters
    assert processor.clean("hello@world#2023") == "helloworld2023"
    
    # Unicode characters
    assert processor.clean("Café") == "Caf"
    
    # Emojis
    assert processor.clean("Hello 👋 World 🌍") == "Hello  World "
    
    # Mixed
    assert processor.clean("Test-123_abc!@#") == "Test123abc"
```

## Best Practices

### Test Naming Conventions

```python
# Good test names - describe what is being tested
def test_user_creation_with_valid_data_succeeds():
    """Test that user is created successfully with valid input"""
    pass

def test_user_creation_with_duplicate_email_raises_error():
    """Test that creating user with existing email raises error"""
    pass

def test_calculate_discount_for_premium_customer_returns_twenty_percent():
    """Test premium customer receives 20% discount"""
    pass

# Avoid vague names
def test_user():  # What about user?
    pass

def test_edge_case():  # Which edge case?
    pass

def test_1():  # No descriptive information
    pass
```

### One Assertion Per Test (When Practical)

```python
# Good - focused test with single logical assertion
def test_user_has_correct_username():
    """Test user username is set correctly"""
    user = User(username="testuser")
    assert user.username == "testuser"

def test_user_has_correct_email():
    """Test user email is set correctly"""
    user = User(email="test@example.com")
    assert user.email == "test@example.com"

# Acceptable - multiple assertions for same logical concept
def test_user_initialization():
    """Test user is initialized with all required fields"""
    user = User(
        username="testuser",
        email="test@example.com",
        age=25
    )
    assert user.username == "testuser"
    assert user.email == "test@example.com"
    assert user.age == 25
```

### Test Independence

```python
# Good - tests are independent
def test_create_user(db_session):
    """Each test gets fresh database session"""
    user = create_user("user1")
    assert user.username == "user1"

def test_delete_user(db_session):
    """This test doesn't depend on previous test"""
    user = create_user("user2")
    delete_user(user.id)
    assert get_user(user.id) is None

# Bad - tests depend on execution order
class TestUserWorkflow:
    user_id = None
    
    def test_01_create_user(self):
        """Creates user for later tests"""
        user = create_user("user1")
        self.user_id = user.id  # Shared state
    
    def test_02_update_user(self):
        """Depends on test_01 running first"""
        update_user(self.user_id, name="updated")  # Fails if test_01 skipped
```

### Keep Tests Fast

```python
# Good - fast unit test with mocked dependencies
def test_send_notification(mock_email_service):
    """Test notification logic without actual email"""
    notifier = Notifier(mock_email_service)
    result = notifier.send("test@example.com", "Hello")
    assert result is True
    mock_email_service.send.assert_called_once()

# Bad - slow test with real external service
def test_send_notification_real():
    """Slow test using real email service"""
    notifier = Notifier(RealEmailService())
    result = notifier.send("test@example.com", "Hello")  # Takes 2-3 seconds
    assert result is True
```

### Test Public Interface Only

```python
class ShoppingCart:
    def __init__(self):
        self._items = []  # Private attribute
    
    def add_item(self, item):
        """Public method"""
        self._items.append(item)
    
    def _calculate_discount(self, price):
        """Private method"""
        return price * 0.9
    
    def total(self):
        """Public method"""
        return sum(self._calculate_discount(item.price) for item in self._items)

# Good - test public interface
def test_shopping_cart_total():
    """Test cart total through public interface"""
    cart = ShoppingCart()
    cart.add_item(Item(name="Apple", price=1.00))
    cart.add_item(Item(name="Banana", price=0.50))
    assert cart.total() == 1.35

# Bad - test private implementation
def test_shopping_cart_private_method():
    """Testing private method directly"""
    cart = ShoppingCart()
    result = cart._calculate_discount(10.0)  # Don't test private methods
    assert result == 9.0
```

### Use Descriptive Variable Names

```python
# Good - clear variable names
def test_order_total_calculation():
    """Test order total with multiple items"""
    order = Order()
    first_item = OrderItem(name="Laptop", price=999.99, quantity=1)
    second_item = OrderItem(name="Mouse", price=29.99, quantity=2)
    
    order.add_item(first_item)
    order.add_item(second_item)
    
    expected_total = 999.99 + (29.99 * 2)
    assert order.total() == expected_total

# Bad - unclear variable names
def test_order():
    o = Order()
    i1 = OrderItem("Laptop", 999.99, 1)
    i2 = OrderItem("Mouse", 29.99, 2)
    o.add_item(i1)
    o.add_item(i2)
    t = 999.99 + (29.99 * 2)
    assert o.total() == t
```

### Document Test Intent

```python
def test_password_reset_link_expires():
    """Test password reset link expires after 24 hours
    
    When a user requests a password reset, they receive a link
    that should only be valid for 24 hours. After that time,
    attempting to use the link should result in an error.
    """
    # Arrange
    user = create_test_user()
    reset_link = generate_reset_link(user)
    
    # Act - simulate 24 hours passing
    with freeze_time(timezone.now() + timedelta(hours=24, minutes=1)):
        result = validate_reset_link(reset_link)
    
    # Assert
    assert result.valid is False
    assert result.error == "Link expired"
```

## Common Pitfalls

### Testing Implementation Instead of Behavior

```python
# Bad - tests implementation details
def test_user_storage_uses_dictionary():
    """Test that user storage uses dictionary internally"""
    storage = UserStorage()
    storage.add_user(User(id=1, name="John"))
    assert isinstance(storage._users, dict)  # Testing implementation
    assert 1 in storage._users  # Testing internal structure

# Good - tests behavior
def test_user_storage_retrieves_stored_user():
    """Test that stored user can be retrieved"""
    storage = UserStorage()
    user = User(id=1, name="John")
    storage.add_user(user)
    retrieved = storage.get_user(1)
    assert retrieved.name == "John"
```

### Overly Complex Tests

```python
# Bad - complex test with loops and conditionals
def test_batch_processing():
    """Test batch processing"""
    items = generate_test_items()
    processor = BatchProcessor()
    
    for item in items:
        if item.type == "A":
            result = processor.process_type_a(item)
            if result.success:
                assert result.value > 0
        else:
            result = processor.process_type_b(item)
            assert result.error is None

# Good - simple, focused tests
def test_batch_processing_type_a_items():
    """Test processing of type A items"""
    item = create_test_item(type="A")
    processor = BatchProcessor()
    result = processor.process_type_a(item)
    assert result.success is True
    assert result.value > 0

def test_batch_processing_type_b_items():
    """Test processing of type B items"""
    item = create_test_item(type="B")
    processor = BatchProcessor()
    result = processor.process_type_b(item)
    assert result.error is None
```

### Not Cleaning Up Resources

```python
# Bad - leaves resources unclosed
def test_file_processing():
    """Test file processing"""
    f = open("test.txt", "w")
    f.write("test data")
    # File not closed - resource leak

# Good - properly clean up
def test_file_processing_with_context():
    """Test file processing with proper cleanup"""
    with open("test.txt", "w") as f:
        f.write("test data")
    # File automatically closed

# Good - using fixture
@pytest.fixture
def test_file(tmp_path):
    """Provide test file with automatic cleanup"""
    file_path = tmp_path / "test.txt"
    yield file_path
    # Cleanup happens automatically with tmp_path
```

## See Also

- [unittest Documentation](https://docs.python.org/3/library/unittest.html)
- [pytest Documentation](https://docs.pytest.org/)
- [unittest.mock Documentation](https://docs.python.org/3/library/unittest.mock.html)
- [Test Automation Guide](test-automation.md)
- [Integration Testing](integration-testing.md)
- [Python Testing Overview](index.md)

## Additional Resources

### Documentation

- [pytest Documentation](https://docs.pytest.org/en/stable/)
- [unittest Documentation](https://docs.python.org/3/library/unittest.html)
- [coverage.py Documentation](https://coverage.readthedocs.io/)
- [pytest-mock Documentation](https://pytest-mock.readthedocs.io/)

### Books

- "Test-Driven Development with Python" by Harry Percival
- "Python Testing with pytest" by Brian Okken
- "Unit Testing Principles, Practices, and Patterns" by Vladimir Khorikov

### Tools

- [pytest](https://pytest.org/) - Modern testing framework
- [pytest-cov](https://pytest-cov.readthedocs.io/) - Coverage plugin for pytest
- [pytest-mock](https://pytest-mock.readthedocs.io/) - Mocking plugin for pytest
- [hypothesis](https://hypothesis.readthedocs.io/) - Property-based testing
- [faker](https://faker.readthedocs.io/) - Test data generation

### Style Guides and References

- [Python Testing Style Guide](https://docs.python-guide.org/writing/tests/)
- [pytest Good Integration Practices](https://docs.pytest.org/en/stable/goodpractices.html)
- [Google Python Style Guide - Testing](https://google.github.io/styleguide/pyguide.html#38-testing)
