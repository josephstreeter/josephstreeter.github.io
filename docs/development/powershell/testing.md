---
title: "PowerShell Testing"
description: "Comprehensive guide to testing PowerShell code with Pester and test-driven development practices"
author: "Joseph Streeter"
ms.date: "2025-09-08"
ms.topic: "article"
---

## Overview

Testing is crucial for reliable PowerShell code. Pester is the primary testing framework for PowerShell, providing capabilities for unit testing, integration testing, and test-driven development (TDD). This guide covers testing strategies from basic unit tests to advanced mocking scenarios.

## Getting Started with Pester

### Installing Pester

```powershell
# Install latest version of Pester
Install-Module -Name Pester -Force -SkipPublisherCheck

# Check installed version
Get-Module Pester -ListAvailable

# Import Pester module
Import-Module Pester
```

### Basic Test Structure

A simple Pester test file structure:

```powershell
# MyFunction.Tests.ps1
BeforeAll {
    # Setup code that runs once before all tests
    . $PSScriptRoot\MyFunction.ps1
}

Describe "MyFunction Tests" {
    BeforeEach {
        # Setup code that runs before each test
        $testData = "Sample data"
    }
    
    Context "When valid input is provided" {
        It "Should return expected result" {
            # Arrange
            $input = "test"
            $expected = "TEST"
            
            # Act
            $result = MyFunction -InputString $input
            
            # Assert
            $result | Should -Be $expected
        }
    }
    
    Context "When invalid input is provided" {
        It "Should throw an error" {
            # Arrange & Act & Assert
            { MyFunction -InputString $null } | Should -Throw
        }
    }
    
    AfterEach {
        # Cleanup code that runs after each test
        Remove-Variable testData -ErrorAction SilentlyContinue
    }
}

AfterAll {
    # Cleanup code that runs once after all tests
    # Remove any test artifacts
}
```

## Writing Effective Tests

### Test Organization

Organize tests using Describe, Context, and It blocks:

```powershell
# UserManager.Tests.ps1
BeforeAll {
    . $PSScriptRoot\UserManager.ps1
}

Describe "Get-UserInformation" {
    Context "When user exists in Active Directory" {
        BeforeEach {
            # Mock AD cmdlets for testing
            Mock Get-ADUser {
                return @{
                    Name = "John Doe"
                    SamAccountName = "jdoe"
                    EmailAddress = "john.doe@contoso.com"
                    Enabled = $true
                }
            }
        }
        
        It "Should return user information" {
            $result = Get-UserInformation -Username "jdoe"
            
            $result.Name | Should -Be "John Doe"
            $result.EmailAddress | Should -Be "john.doe@contoso.com"
            $result.Enabled | Should -Be $true
        }
        
        It "Should call Get-ADUser with correct parameters" {
            Get-UserInformation -Username "jdoe"
            
            Should -Invoke Get-ADUser -Exactly 1 -Scope It -ParameterFilter {
                $Identity -eq "jdoe"
            }
        }
    }
    
    Context "When user does not exist" {
        BeforeEach {
            Mock Get-ADUser {
                throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]::new()
            }
        }
        
        It "Should return null" {
            $result = Get-UserInformation -Username "nonexistent"
            $result | Should -BeNullOrEmpty
        }
        
        It "Should handle the exception gracefully" {
            { Get-UserInformation -Username "nonexistent" } | Should -Not -Throw
        }
    }
}
```

### Assertion Types

Pester provides various assertion operators:

```powershell
Describe "Assertion Examples" {
    It "Should demonstrate different assertion types" {
        # Basic equality
        $result = "Hello World"
        $result | Should -Be "Hello World"
        $result | Should -BeExactly "Hello World"  # Case-sensitive
        
        # Numeric comparisons
        $number = 42
        $number | Should -Be 42
        $number | Should -BeGreaterThan 40
        $number | Should -BeLessThan 50
        $number | Should -BeGreaterOrEqual 42
        $number | Should -BeLessOrEqual 42
        
        # String operations
        $text = "PowerShell Testing"
        $text | Should -Match "PowerShell"
        $text | Should -BeLike "*Testing"
        $text | Should -BeIn @("PowerShell Testing", "Other Text")
        
        # Type checking
        $object = Get-Date
        $object | Should -BeOfType [DateTime]
        $object | Should -HaveType [DateTime]
        
        # Null/Empty checking
        $null | Should -BeNullOrEmpty
        "" | Should -BeNullOrEmpty
        @() | Should -BeNullOrEmpty
        
        # Collection testing
        $array = @(1, 2, 3, 4, 5)
        $array | Should -Contain 3
        $array | Should -HaveCount 5
        
        # File system testing
        $testFile = "C:\temp\test.txt"
        New-Item -Path $testFile -ItemType File -Force
        $testFile | Should -Exist
        $testFile | Should -FileContentMatch "pattern"
        
        # Exception testing
        { throw "Test error" } | Should -Throw
        { throw "Test error" } | Should -Throw "Test error"
        { throw [ArgumentException]::new() } | Should -Throw -ExceptionType ([ArgumentException])
    }
}
```

## Mocking and Test Doubles

### Basic Mocking

Replace external dependencies with controlled behavior:

```powershell
Describe "Service Integration Tests" {
    Context "When external service is available" {
        BeforeEach {
            # Mock external web service call
            Mock Invoke-RestMethod {
                return @{
                    Status = "Success"
                    Data = @{
                        Users = @(
                            @{ Name = "User1"; Active = $true },
                            @{ Name = "User2"; Active = $false }
                        )
                    }
                }
            }
        }
        
        It "Should process service response correctly" {
            $result = Get-ExternalUserData -ServiceUrl "https://api.example.com/users"
            
            $result.Users | Should -HaveCount 2
            $result.Users[0].Name | Should -Be "User1"
            
            Should -Invoke Invoke-RestMethod -Exactly 1 -Scope It
        }
    }
    
    Context "When external service returns error" {
        BeforeEach {
            Mock Invoke-RestMethod {
                throw [System.Net.WebException]::new("Service unavailable")
            }
        }
        
        It "Should handle service errors gracefully" {
            $result = Get-ExternalUserData -ServiceUrl "https://api.example.com/users"
            
            $result | Should -BeNullOrEmpty
            Should -Invoke Invoke-RestMethod -Exactly 1 -Scope It
        }
    }
}
```

### Advanced Mocking Scenarios

```powershell
Describe "Advanced Mocking Examples" {
    Context "Parameter-specific mocks" {
        BeforeEach {
            # Different behavior based on parameters
            Mock Get-Content {
                return "Config content"
            } -ParameterFilter { $Path -eq "config.txt" }
            
            Mock Get-Content {
                return "Log content"
            } -ParameterFilter { $Path -eq "log.txt" }
            
            # Default mock for other cases
            Mock Get-Content {
                return "Default content"
            }
        }
        
        It "Should return different content based on file path" {
            $configContent = Get-Content "config.txt"
            $logContent = Get-Content "log.txt"
            $otherContent = Get-Content "other.txt"
            
            $configContent | Should -Be "Config content"
            $logContent | Should -Be "Log content"
            $otherContent | Should -Be "Default content"
        }
    }
    
    Context "Mock verification" {
        BeforeEach {
            Mock Write-EventLog { } -Verifiable
            Mock Send-MailMessage { } -Verifiable
        }
        
        It "Should call all required logging methods" {
            # Function that should call both mocked cmdlets
            Write-ApplicationLog -Message "Test" -SendEmail
            
            # Verify mocks were called
            Should -InvokeVerifiable
            
            # Verify specific mock calls
            Should -Invoke Write-EventLog -Exactly 1 -Scope It
            Should -Invoke Send-MailMessage -Exactly 1 -Scope It
        }
    }
}
```

### Mocking Classes and Methods

```powershell
# Mocking custom classes
Describe "Class Mocking Examples" {
    BeforeAll {
        class DatabaseConnection {
            [string]$ConnectionString
            
            DatabaseConnection([string]$connectionString) {
                $this.ConnectionString = $connectionString
            }
            
            [hashtable] ExecuteQuery([string]$query) {
                # Actual database logic would go here
                return @{ Results = @() }
            }
        }
    }
    
    Context "Database operations" {
        BeforeEach {
            # Mock the class constructor and methods
            Mock New-Object {
                $mockDb = [PSCustomObject]@{
                    ConnectionString = $ArgumentList[1]
                    ExecuteQuery = {
                        param($query)
                        return @{
                            Results = @(
                                @{ Name = "Test User"; ID = 1 }
                            )
                        }
                    }
                }
                return $mockDb
            } -ParameterFilter { $TypeName -eq "DatabaseConnection" }
        }
        
        It "Should execute database query successfully" {
            $db = New-Object DatabaseConnection "Server=test;Database=test"
            $result = & $db.ExecuteQuery "SELECT * FROM Users"
            
            $result.Results | Should -HaveCount 1
            $result.Results[0].Name | Should -Be "Test User"
        }
    }
}
```

## Test-Driven Development (TDD)

### Red-Green-Refactor Cycle

Implementing TDD with Pester:

```powershell
# Step 1: Write failing test (RED)
Describe "Calculate-BMI" {
    It "Should calculate BMI correctly for metric units" {
        $result = Calculate-BMI -Weight 70 -Height 1.75 -Unit "Metric"
        $result | Should -Be 22.86
    }
    
    It "Should calculate BMI correctly for imperial units" {
        $result = Calculate-BMI -Weight 154 -Height 69 -Unit "Imperial"
        $result | Should -Be 22.75
    }
    
    It "Should throw error for invalid weight" {
        { Calculate-BMI -Weight -10 -Height 1.75 } | Should -Throw
    }
}

# Step 2: Write minimal code to pass (GREEN)
function Calculate-BMI {
    param(
        [Parameter(Mandatory)]
        [double]$Weight,
        
        [Parameter(Mandatory)]
        [double]$Height,
        
        [ValidateSet("Metric", "Imperial")]
        [string]$Unit = "Metric"
    )
    
    if ($Weight -le 0 -or $Height -le 0) {
        throw "Weight and height must be positive values"
    }
    
    if ($Unit -eq "Imperial") {
        # Convert imperial to metric
        $Weight = $Weight * 0.453592  # pounds to kg
        $Height = $Height * 0.0254    # inches to meters
    }
    
    $bmi = $Weight / ($Height * $Height)
    return [Math]::Round($bmi, 2)
}

# Step 3: Refactor (REFACTOR)
# Improve the code while keeping tests green
function Calculate-BMI {
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ $_ -gt 0 })]
        [double]$Weight,
        
        [Parameter(Mandatory)]
        [ValidateScript({ $_ -gt 0 })]
        [double]$Height,
        
        [ValidateSet("Metric", "Imperial")]
        [string]$Unit = "Metric"
    )
    
    # Conversion constants
    $POUNDS_TO_KG = 0.453592
    $INCHES_TO_METERS = 0.0254
    
    $weightKg = $Weight
    $heightM = $Height
    
    if ($Unit -eq "Imperial") {
        $weightKg = $Weight * $POUNDS_TO_KG
        $heightM = $Height * $INCHES_TO_METERS
    }
    
    $bmi = $weightKg / ($heightM * $heightM)
    return [Math]::Round($bmi, 2)
}
```

## Integration Testing

### Testing with Real Systems

```powershell
Describe "Integration Tests" -Tag "Integration" {
    BeforeAll {
        # Setup test environment
        $testDatabase = "TestDB_$(Get-Random)"
        $testConnectionString = "Server=localhost;Database=$testDatabase;Integrated Security=true"
        
        # Create test database
        Invoke-Sqlcmd -Query "CREATE DATABASE [$testDatabase]" -ServerInstance "localhost"
    }
    
    Context "Database operations" {
        It "Should create and retrieve user records" {
            # Arrange
            $userData = @{
                FirstName = "Test"
                LastName = "User"
                Email = "test@example.com"
            }
            
            # Act
            $userId = New-DatabaseUser @userData -ConnectionString $testConnectionString
            $retrievedUser = Get-DatabaseUser -UserId $userId -ConnectionString $testConnectionString
            
            # Assert
            $retrievedUser.FirstName | Should -Be $userData.FirstName
            $retrievedUser.LastName | Should -Be $userData.LastName
            $retrievedUser.Email | Should -Be $userData.Email
        }
    }
    
    AfterAll {
        # Cleanup test environment
        Invoke-Sqlcmd -Query "DROP DATABASE [$testDatabase]" -ServerInstance "localhost"
    }
}
```

### API Testing

```powershell
Describe "REST API Tests" -Tag "Integration" {
    BeforeAll {
        $baseUrl = "https://api.example.com/v1"
        $apiKey = $env:TEST_API_KEY
        
        if (-not $apiKey) {
            throw "TEST_API_KEY environment variable is required for API tests"
        }
    }
    
    Context "User management endpoints" {
        It "Should create a new user" {
            $newUser = @{
                name = "Test User"
                email = "test.user@example.com"
                role = "standard"
            }
            
            $response = Invoke-RestMethod -Uri "$baseUrl/users" -Method POST -Body ($newUser | ConvertTo-Json) -Headers @{
                "Authorization" = "Bearer $apiKey"
                "Content-Type" = "application/json"
            }
            
            $response.id | Should -Not -BeNullOrEmpty
            $response.name | Should -Be $newUser.name
            $response.email | Should -Be $newUser.email
            
            # Store for cleanup
            $script:testUserId = $response.id
        }
        
        It "Should retrieve the created user" {
            $response = Invoke-RestMethod -Uri "$baseUrl/users/$script:testUserId" -Method GET -Headers @{
                "Authorization" = "Bearer $apiKey"
            }
            
            $response.id | Should -Be $script:testUserId
            $response.name | Should -Be "Test User"
        }
        
        AfterEach {
            # Cleanup created users
            if ($script:testUserId) {
                try {
                    Invoke-RestMethod -Uri "$baseUrl/users/$script:testUserId" -Method DELETE -Headers @{
                        "Authorization" = "Bearer $apiKey"
                    }
                }
                catch {
                    Write-Warning "Failed to cleanup test user: $($_.Exception.Message)"
                }
            }
        }
    }
}
```

## Performance Testing

### Measuring Execution Time

```powershell
Describe "Performance Tests" -Tag "Performance" {
    Context "Algorithm performance" {
        It "Should complete within acceptable time limits" {
            $maxExecutionTime = [TimeSpan]::FromMilliseconds(100)
            
            $executionTime = Measure-Command {
                # Code under test
                $result = Get-LargeDataSet | Sort-Object Name | Select-Object -First 1000
            }
            
            $executionTime | Should -BeLessOrEqual $maxExecutionTime
        }
        
        It "Should handle large datasets efficiently" {
            $largeDataset = 1..10000
            
            $executionTime = Measure-Command {
                $result = $largeDataset | Where-Object { $_ % 2 -eq 0 } | ForEach-Object { $_ * 2 }
            }
            
            # Should complete within 1 second
            $executionTime.TotalSeconds | Should -BeLessOrEqual 1
            
            # Result should be correct
            $result | Should -HaveCount 5000
        }
    }
    
    Context "Memory usage" {
        It "Should not consume excessive memory" {
            $initialMemory = [GC]::GetTotalMemory($false)
            
            # Execute memory-intensive operation
            $data = 1..100000 | ForEach-Object { "String number $_" }
            
            $finalMemory = [GC]::GetTotalMemory($false)
            $memoryUsed = $finalMemory - $initialMemory
            
            # Should use less than 50MB
            $memoryUsed | Should -BeLessOrEqual 50MB
        }
    }
}
```

## Code Coverage

### Analyzing Test Coverage

```powershell
# Run tests with code coverage
$coverageResult = Invoke-Pester -Path ".\Tests\" -CodeCoverage ".\Source\*.ps1" -PassThru

# Display coverage summary
Write-Host "Code Coverage Summary:" -ForegroundColor Green
Write-Host "Total Lines: $($coverageResult.CodeCoverage.NumberOfCommandsAnalyzed)"
Write-Host "Covered Lines: $($coverageResult.CodeCoverage.NumberOfCommandsExecuted)"
Write-Host "Coverage Percentage: $([Math]::Round($coverageResult.CodeCoverage.NumberOfCommandsExecuted / $coverageResult.CodeCoverage.NumberOfCommandsAnalyzed * 100, 2))%"

# Show uncovered lines
if ($coverageResult.CodeCoverage.MissedCommands) {
    Write-Host "`nUncovered Lines:" -ForegroundColor Yellow
    $coverageResult.CodeCoverage.MissedCommands | ForEach-Object {
        Write-Host "  $($_.File):$($_.Line) - $($_.Command)"
    }
}

# Generate coverage report
$coverageResult.CodeCoverage | Export-Clixml -Path "coverage-report.xml"
```

## Continuous Testing

### Test Automation Scripts

```powershell
# TestRunner.ps1 - Automated test execution
param(
    [string]$TestPath = ".\Tests\",
    [string[]]$Tags = @(),
    [switch]$CodeCoverage,
    [string]$OutputPath = ".\TestResults\"
)

# Ensure output directory exists
New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null

# Configure test parameters
$testParams = @{
    Path = $TestPath
    PassThru = $true
    OutputFile = Join-Path $OutputPath "test-results.xml"
    OutputFormat = "NUnitXml"
}

if ($Tags.Count -gt 0) {
    $testParams.Tag = $Tags
}

if ($CodeCoverage) {
    $testParams.CodeCoverage = ".\Source\*.ps1"
}

# Run tests
Write-Host "Running tests..." -ForegroundColor Green
$result = Invoke-Pester @testParams

# Generate summary report
$summary = @{
    Timestamp = Get-Date
    TotalTests = $result.TotalCount
    PassedTests = $result.PassedCount
    FailedTests = $result.FailedCount
    SkippedTests = $result.SkippedCount
    ExecutionTime = $result.Time
    Success = $result.FailedCount -eq 0
}

if ($CodeCoverage -and $result.CodeCoverage) {
    $summary.CodeCoverage = @{
        CoveredLines = $result.CodeCoverage.NumberOfCommandsExecuted
        TotalLines = $result.CodeCoverage.NumberOfCommandsAnalyzed
        Percentage = [Math]::Round($result.CodeCoverage.NumberOfCommandsExecuted / $result.CodeCoverage.NumberOfCommandsAnalyzed * 100, 2)
    }
}

# Save summary
$summary | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $OutputPath "test-summary.json")

# Display results
Write-Host "`nTest Summary:" -ForegroundColor Green
Write-Host "Total: $($summary.TotalTests), Passed: $($summary.PassedTests), Failed: $($summary.FailedTests), Skipped: $($summary.SkippedTests)"
Write-Host "Execution Time: $($summary.ExecutionTime)"

if ($summary.CodeCoverage) {
    Write-Host "Code Coverage: $($summary.CodeCoverage.Percentage)%"
}

if (-not $summary.Success) {
    Write-Host "Tests failed!" -ForegroundColor Red
    exit 1
}

Write-Host "All tests passed!" -ForegroundColor Green
```

## Best Practices

### Project Structure

```powershell
# Directory structure
# Project/
# ├── Source/
# │   ├── Module.psm1
# │   └── Public/
# │       └── Get-Something.ps1
# ├── Tests/
# │   ├── Unit/
# │   │   └── Get-Something.Tests.ps1
# │   ├── Integration/
# │   │   └── Module.Integration.Tests.ps1
# │   └── Performance/
# │       └── Module.Performance.Tests.ps1
# └── TestData/
#     └── sample-data.json
```

### Testing Guidelines

1. **Test Naming Conventions**
   - Use descriptive test names
   - Follow "Should_ExpectedBehavior_When_StateUnderTest" pattern
   - Group related tests in Context blocks

2. **Test Independence**
   - Each test should be independent
   - Use BeforeEach/AfterEach for setup/cleanup
   - Avoid shared state between tests

3. **Mock Strategically**
   - Mock external dependencies
   - Don't mock the system under test
   - Use parameter filters for specific scenarios

4. **Assert Meaningfully**
   - Use specific assertions
   - Test both positive and negative cases
   - Verify behavior, not implementation

## Related Documentation

- **[PowerShell Modules](modules.md)** - Creating testable PowerShell modules
- **[PowerShell Classes](classes.md)** - Testing object-oriented PowerShell code
- **[PowerShell Functions](functions.md)** - Writing testable functions
- **[Development Best Practices](index.md)** - General PowerShell development guidelines

---

*This guide provides comprehensive coverage of PowerShell testing with Pester, from basic unit tests to advanced testing scenarios. Proper testing ensures reliable and maintainable PowerShell code.*
