---
title: "PowerShell Classes"
description: "Complete guide to PowerShell classes, object-oriented programming, and advanced PowerShell development"
author: "Joseph Streeter"
ms.date: "2025-09-08"
ms.topic: "article"
---

## Overview

PowerShell classes were introduced in PowerShell 5.0, bringing object-oriented programming capabilities to PowerShell. Classes allow you to create custom objects with properties, methods, and inheritance, making PowerShell scripts more structured and reusable.

## Basic Class Definition

### Simple Class Structure

Creating a basic PowerShell class:

```powershell
class Person {
    # Properties
    [string]$FirstName
    [string]$LastName
    [datetime]$BirthDate
    
    # Constructor
    Person([string]$firstName, [string]$lastName, [datetime]$birthDate) {
        $this.FirstName = $firstName
        $this.LastName = $lastName
        $this.BirthDate = $birthDate
    }
    
    # Method
    [string] GetFullName() {
        return "$($this.FirstName) $($this.LastName)"
    }
    
    # Method with calculation
    [int] GetAge() {
        return (Get-Date).Year - $this.BirthDate.Year
    }
}

# Usage
$person = [Person]::new("John", "Doe", [datetime]"1985-05-15")
Write-Output $person.GetFullName()
Write-Output "Age: $($person.GetAge())"
```

### Property Types and Validation

Using different property types and validation:

```powershell
class Employee {
    # String property with validation
    [ValidateNotNullOrEmpty()]
    [string]$Name
    
    # Numeric properties
    [int]$EmployeeID
    [decimal]$Salary
    
    # Enum property
    [EmployeeStatus]$Status
    
    # Array property
    [string[]]$Skills
    
    # Hidden property (not shown in default output)
    hidden [string]$SSN
    
    # Static property (shared across all instances)
    static [string]$CompanyName = "Contoso Corp"
}

enum EmployeeStatus {
    Active
    Inactive
    OnLeave
    Terminated
}
```

## Constructors

### Multiple Constructors

Defining multiple constructors for flexibility:

```powershell
class Computer {
    [string]$Name
    [string]$Model
    [int]$RAM
    [string]$OS
    
    # Default constructor
    Computer() {
        $this.Name = "Unknown"
        $this.Model = "Generic"
        $this.RAM = 8
        $this.OS = "Windows 11"
    }
    
    # Constructor with name only
    Computer([string]$name) {
        $this.Name = $name
        $this.Model = "Generic"
        $this.RAM = 8
        $this.OS = "Windows 11"
    }
    
    # Full constructor
    Computer([string]$name, [string]$model, [int]$ram, [string]$os) {
        $this.Name = $name
        $this.Model = $model
        $this.RAM = $ram
        $this.OS = $os
    }
    
    # Copy constructor
    Computer([Computer]$other) {
        $this.Name = $other.Name
        $this.Model = $other.Model
        $this.RAM = $other.RAM
        $this.OS = $other.OS
    }
}

# Usage examples
$computer1 = [Computer]::new()
$computer2 = [Computer]::new("Server01")
$computer3 = [Computer]::new("Workstation01", "Dell OptiPlex", 16, "Windows 10")
$computer4 = [Computer]::new($computer3)  # Copy constructor
```

## Methods

### Instance Methods

Creating methods that operate on instance data:

```powershell
class BankAccount {
    [string]$AccountNumber
    [string]$Owner
    [decimal]$Balance
    [datetime]$LastTransaction
    
    BankAccount([string]$accountNumber, [string]$owner) {
        $this.AccountNumber = $accountNumber
        $this.Owner = $owner
        $this.Balance = 0
        $this.LastTransaction = Get-Date
    }
    
    # Method to deposit money
    [void] Deposit([decimal]$amount) {
        if ($amount -le 0) {
            throw "Deposit amount must be positive"
        }
        $this.Balance += $amount
        $this.LastTransaction = Get-Date
        Write-Output "Deposited $amount. New balance: $($this.Balance)"
    }
    
    # Method to withdraw money
    [bool] Withdraw([decimal]$amount) {
        if ($amount -le 0) {
            throw "Withdrawal amount must be positive"
        }
        
        if ($amount -gt $this.Balance) {
            Write-Warning "Insufficient funds. Current balance: $($this.Balance)"
            return $false
        }
        
        $this.Balance -= $amount
        $this.LastTransaction = Get-Date
        Write-Output "Withdrew $amount. New balance: $($this.Balance)"
        return $true
    }
    
    # Method to get account summary
    [hashtable] GetAccountSummary() {
        return @{
            AccountNumber = $this.AccountNumber
            Owner = $this.Owner
            Balance = $this.Balance
            LastTransaction = $this.LastTransaction
        }
    }
}
```

### Static Methods

Methods that don't require an instance:

```powershell
class MathUtilities {
    # Static method for calculating factorial
    static [long] Factorial([int]$number) {
        if ($number -lt 0) {
            throw "Factorial is not defined for negative numbers"
        }
        
        if ($number -eq 0 -or $number -eq 1) {
            return 1
        }
        
        $result = 1
        for ($i = 2; $i -le $number; $i++) {
            $result *= $i
        }
        
        return $result
    }
    
    # Static method for checking prime numbers
    static [bool] IsPrime([int]$number) {
        if ($number -lt 2) {
            return $false
        }
        
        for ($i = 2; $i -le [Math]::Sqrt($number); $i++) {
            if ($number % $i -eq 0) {
                return $false
            }
        }
        
        return $true
    }
}

# Usage
$factorial5 = [MathUtilities]::Factorial(5)
$isPrime17 = [MathUtilities]::IsPrime(17)
```

## Inheritance

### Basic Inheritance

Creating derived classes:

```powershell
# Base class
class Vehicle {
    [string]$Make
    [string]$Model
    [int]$Year
    [string]$Color
    
    Vehicle([string]$make, [string]$model, [int]$year, [string]$color) {
        $this.Make = $make
        $this.Model = $model
        $this.Year = $year
        $this.Color = $color
    }
    
    [string] GetDescription() {
        return "$($this.Year) $($this.Make) $($this.Model) in $($this.Color)"
    }
    
    [void] Start() {
        Write-Output "Starting the $($this.Make) $($this.Model)"
    }
}

# Derived class
class Car : Vehicle {
    [int]$Doors
    [string]$FuelType
    
    Car([string]$make, [string]$model, [int]$year, [string]$color, [int]$doors, [string]$fuelType) : base($make, $model, $year, $color) {
        $this.Doors = $doors
        $this.FuelType = $fuelType
    }
    
    # Override parent method
    [string] GetDescription() {
        $baseDescription = ([Vehicle]$this).GetDescription()
        return "$baseDescription with $($this.Doors) doors ($($this.FuelType))"
    }
    
    # Additional method specific to cars
    [void] Honk() {
        Write-Output "Beep beep!"
    }
}

# Usage
$myCar = [Car]::new("Toyota", "Camry", 2023, "Blue", 4, "Gasoline")
Write-Output $myCar.GetDescription()
$myCar.Start()
$myCar.Honk()
```

### Abstract Classes and Interfaces

PowerShell doesn't have true abstract classes, but you can simulate them:

```powershell
class Shape {
    [string]$Name
    
    Shape([string]$name) {
        $this.Name = $name
    }
    
    # "Abstract" method - should be overridden
    [double] GetArea() {
        throw "GetArea() must be implemented in derived class"
    }
    
    # "Abstract" method - should be overridden
    [double] GetPerimeter() {
        throw "GetPerimeter() must be implemented in derived class"
    }
    
    # Concrete method
    [string] GetInfo() {
        return "Shape: $($this.Name), Area: $($this.GetArea()), Perimeter: $($this.GetPerimeter())"
    }
}

class Rectangle : Shape {
    [double]$Width
    [double]$Height
    
    Rectangle([double]$width, [double]$height) : base("Rectangle") {
        $this.Width = $width
        $this.Height = $height
    }
    
    [double] GetArea() {
        return $this.Width * $this.Height
    }
    
    [double] GetPerimeter() {
        return 2 * ($this.Width + $this.Height)
    }
}

class Circle : Shape {
    [double]$Radius
    
    Circle([double]$radius) : base("Circle") {
        $this.Radius = $radius
    }
    
    [double] GetArea() {
        return [Math]::PI * $this.Radius * $this.Radius
    }
    
    [double] GetPerimeter() {
        return 2 * [Math]::PI * $this.Radius
    }
}
```

## Advanced Features

### Properties with Getters and Setters

Custom property behavior:

```powershell
class Temperature {
    hidden [double]$_celsius
    
    # Property with custom getter and setter
    [double] $Celsius
    
    Temperature([double]$celsius) {
        $this.Celsius = $celsius
    }
    
    # Custom setter for Celsius
    [void] set_Celsius([double]$value) {
        if ($value -lt -273.15) {
            throw "Temperature cannot be below absolute zero (-273.15°C)"
        }
        $this._celsius = $value
    }
    
    # Custom getter for Celsius
    [double] get_Celsius() {
        return $this._celsius
    }
    
    # Calculated property for Fahrenheit
    [double] GetFahrenheit() {
        return ($this._celsius * 9/5) + 32
    }
    
    # Calculated property for Kelvin
    [double] GetKelvin() {
        return $this._celsius + 273.15
    }
    
    [void] SetFahrenheit([double]$fahrenheit) {
        $this.Celsius = ($fahrenheit - 32) * 5/9
    }
}
```

### Implementing Interfaces

PowerShell doesn't have formal interfaces, but you can use conventions:

```powershell
# "Interface" convention - methods that implementing classes should have
class IComparable {
    [int] CompareTo([object]$other) {
        throw "CompareTo must be implemented"
    }
}

class Version : IComparable {
    [int]$Major
    [int]$Minor
    [int]$Build
    
    Version([int]$major, [int]$minor, [int]$build) {
        $this.Major = $major
        $this.Minor = $minor
        $this.Build = $build
    }
    
    [int] CompareTo([object]$other) {
        if ($other -isnot [Version]) {
            throw "Can only compare to another Version object"
        }
        
        $otherVersion = [Version]$other
        
        if ($this.Major -ne $otherVersion.Major) {
            return $this.Major - $otherVersion.Major
        }
        
        if ($this.Minor -ne $otherVersion.Minor) {
            return $this.Minor - $otherVersion.Minor
        }
        
        return $this.Build - $otherVersion.Build
    }
    
    [string] ToString() {
        return "$($this.Major).$($this.Minor).$($this.Build)"
    }
}
```

## Real-World Examples

### Configuration Management Class

```powershell
class ConfigurationManager {
    hidden [hashtable]$_settings
    [string]$ConfigFile
    
    ConfigurationManager([string]$configFile) {
        $this.ConfigFile = $configFile
        $this._settings = @{}
        $this.LoadConfiguration()
    }
    
    [void] LoadConfiguration() {
        if (Test-Path $this.ConfigFile) {
            try {
                $content = Get-Content $this.ConfigFile -Raw | ConvertFrom-Json
                $this._settings = @{}
                
                $content.PSObject.Properties | ForEach-Object {
                    $this._settings[$_.Name] = $_.Value
                }
                
                Write-Verbose "Configuration loaded from $($this.ConfigFile)"
            }
            catch {
                Write-Warning "Failed to load configuration: $($_.Exception.Message)"
                $this._settings = @{}
            }
        }
        else {
            Write-Warning "Configuration file not found: $($this.ConfigFile)"
            $this._settings = @{}
        }
    }
    
    [void] SaveConfiguration() {
        try {
            $this._settings | ConvertTo-Json -Depth 3 | Set-Content $this.ConfigFile
            Write-Verbose "Configuration saved to $($this.ConfigFile)"
        }
        catch {
            Write-Error "Failed to save configuration: $($_.Exception.Message)"
        }
    }
    
    [object] GetSetting([string]$key, [object]$defaultValue = $null) {
        if ($this._settings.ContainsKey($key)) {
            return $this._settings[$key]
        }
        return $defaultValue
    }
    
    [void] SetSetting([string]$key, [object]$value) {
        $this._settings[$key] = $value
    }
    
    [hashtable] GetAllSettings() {
        return $this._settings.Clone()
    }
}

# Usage
$config = [ConfigurationManager]::new("C:\Config\app.json")
$config.SetSetting("DatabaseConnectionString", "Server=localhost;Database=MyApp")
$config.SetSetting("LogLevel", "Information")
$config.SaveConfiguration()

$dbConnection = $config.GetSetting("DatabaseConnectionString")
```

### Logger Class

```powershell
enum LogLevel {
    Debug = 0
    Information = 1
    Warning = 2
    Error = 3
    Critical = 4
}

class Logger {
    [string]$LogFile
    [LogLevel]$MinimumLevel
    [bool]$ConsoleOutput
    
    Logger([string]$logFile, [LogLevel]$minimumLevel = [LogLevel]::Information, [bool]$consoleOutput = $true) {
        $this.LogFile = $logFile
        $this.MinimumLevel = $minimumLevel
        $this.ConsoleOutput = $consoleOutput
        
        # Ensure log directory exists
        $logDir = Split-Path $this.LogFile -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
    }
    
    [void] Log([LogLevel]$level, [string]$message, [string]$category = "General") {
        if ($level -lt $this.MinimumLevel) {
            return
        }
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$level] [$category] $message"
        
        # Write to file
        try {
            Add-Content -Path $this.LogFile -Value $logEntry
        }
        catch {
            Write-Warning "Failed to write to log file: $($_.Exception.Message)"
        }
        
        # Write to console if enabled
        if ($this.ConsoleOutput) {
            switch ($level) {
                ([LogLevel]::Debug) { Write-Host $logEntry -ForegroundColor Gray }
                ([LogLevel]::Information) { Write-Host $logEntry -ForegroundColor White }
                ([LogLevel]::Warning) { Write-Host $logEntry -ForegroundColor Yellow }
                ([LogLevel]::Error) { Write-Host $logEntry -ForegroundColor Red }
                ([LogLevel]::Critical) { Write-Host $logEntry -ForegroundColor Magenta }
            }
        }
    }
    
    [void] Debug([string]$message, [string]$category = "General") {
        $this.Log([LogLevel]::Debug, $message, $category)
    }
    
    [void] Information([string]$message, [string]$category = "General") {
        $this.Log([LogLevel]::Information, $message, $category)
    }
    
    [void] Warning([string]$message, [string]$category = "General") {
        $this.Log([LogLevel]::Warning, $message, $category)
    }
    
    [void] Error([string]$message, [string]$category = "General") {
        $this.Log([LogLevel]::Error, $message, $category)
    }
    
    [void] Critical([string]$message, [string]$category = "General") {
        $this.Log([LogLevel]::Critical, $message, $category)
    }
}

# Usage
$logger = [Logger]::new("C:\Logs\application.log", [LogLevel]::Debug)
$logger.Information("Application started")
$logger.Warning("Configuration file not found, using defaults")
$logger.Error("Database connection failed", "Database")
```

## Best Practices

### Class Design Principles

1. **Single Responsibility** - Each class should have one reason to change
2. **Encapsulation** - Hide internal implementation details
3. **Inheritance** - Use inheritance for "is-a" relationships
4. **Composition** - Prefer composition over inheritance when appropriate

```powershell
# Good: Single responsibility
class EmailValidator {
    static [bool] IsValidEmail([string]$email) {
        return $email -match '^[^@\s]+@[^@\s]+\.[^@\s]+$'
    }
}

class PasswordValidator {
    static [bool] IsStrongPassword([string]$password) {
        return $password.Length -ge 8 -and 
               $password -cmatch '[A-Z]' -and 
               $password -cmatch '[a-z]' -and 
               $password -cmatch '\d' -and 
               $password -cmatch '[^A-Za-z\d]'
    }
}

# Good: Proper encapsulation
class SecureString {
    hidden [string]$_value
    
    SecureString([string]$value) {
        $this._value = $value
    }
    
    [string] GetMasked() {
        return "*" * $this._value.Length
    }
    
    [bool] ValidatePassword([string]$password) {
        return $this._value -ceq $password
    }
}
```

## Related Documentation

- **[PowerShell Modules](modules.md)** - Creating and organizing PowerShell modules
- **[PowerShell Testing](testing.md)** - Testing PowerShell code and classes
- **[PowerShell Functions](functions.md)** - Advanced function development
- **[PowerShell Best Practices](index.md)** - General PowerShell development guidelines

---

*This guide covers PowerShell classes from basic concepts to advanced implementations. Classes enable object-oriented programming in PowerShell, making code more maintainable and reusable.*
