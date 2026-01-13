---
title: "MIM 2016 Rule Extensions Development"
description: "Comprehensive guide to developing custom rule extensions for Microsoft Identity Manager 2016 Synchronization Service"
tags: ["MIM", "rule extensions", ".NET", "development", "customization"]
category: "services"
difficulty: "advanced"
last_updated: "2025-07-05"
---

Rule Extensions in Microsoft Identity Manager 2016 Synchronization Service provide the ability to implement custom business logic using .NET code. This guide covers the development, deployment, and best practices for creating robust rule extensions that extend the synchronization capabilities beyond the built-in functionality.

## Overview

Rule Extensions allow developers to:

- Implement complex attribute transformations
- Perform external system integrations
- Execute custom validation logic
- Handle specialized business requirements
- Integrate with third-party APIs and services

## Development Environment Setup

### Prerequisites

- **Visual Studio** (2019 or later recommended)
- **.NET Framework 4.5.2** or higher
- **MIM 2016 Synchronization Service** installed
- **Microsoft.MetadirectoryServices** assemblies

### Project Configuration

1. **Create a Class Library Project**

   ```csharp
   // Target Framework: .NET Framework 4.5.2 or higher
   // Platform: x64 (to match MIM Sync Service)
   ```

2. **Add Required References**

   ```text
   Microsoft.MetadirectoryServices.dll
   System.DirectoryServices.dll (if needed)
   System.Data.dll (for database operations)
   ```

3. **Configure Build Output**

   ```text
   Output Path: C:\Program Files\Microsoft Forefront Identity Manager\2010\Synchronization Service\Extensions\
   ```

## Rule Extension Types

### 1. Attribute Flow Rules

Control how attributes flow between connector spaces and the metaverse.

```csharp
using Microsoft.MetadirectoryServices;

public class AttributeFlowExtensions : IMAExtensible2CallIn
{
    public void MapAttributesForImport(
        string FlowRuleName,
        CSEntry csentry,
        MVEntry mventry)
    {
        switch (FlowRuleName)
        {
            case "FormatDisplayName":
                FormatDisplayName(csentry, mventry);
                break;
                
            case "GenerateEmployeeID":
                GenerateEmployeeID(csentry, mventry);
                break;
        }
    }
    
    private void FormatDisplayName(CSEntry csentry, MVEntry mventry)
    {
        string firstName = csentry["givenName"].StringValue;
        string lastName = csentry["sn"].StringValue;
        
        if (!string.IsNullOrEmpty(firstName) && !string.IsNullOrEmpty(lastName))
        {
            mventry["displayName"].StringValue = $"{lastName}, {firstName}";
        }
    }
    
    private void GenerateEmployeeID(CSEntry csentry, MVEntry mventry)
    {
        // Custom logic to generate employee ID
        string department = csentry["department"].StringValue;
        string lastName = csentry["sn"].StringValue;
        
        if (!string.IsNullOrEmpty(department) && !string.IsNullOrEmpty(lastName))
        {
            string employeeID = $"{department.Substring(0, 3).ToUpper()}{lastName.Substring(0, 4).ToUpper()}{DateTime.Now.Year}";
            mventry["employeeID"].StringValue = employeeID;
        }
    }
}
```

### 2. Object Processing Rules

Handle object-level operations during import and export.

```csharp
public void MapAttributesForExport(
    string FlowRuleName,
    MVEntry mventry,
    CSEntry csentry)
{
    switch (FlowRuleName)
    {
        case "SetAccountStatus":
            SetAccountStatus(mventry, csentry);
            break;
            
        case "ConfigureGroupMembership":
            ConfigureGroupMembership(mventry, csentry);
            break;
    }
}

private void SetAccountStatus(MVEntry mventry, CSEntry csentry)
{
    string employeeStatus = mventry["employeeStatus"].StringValue;
    
    switch (employeeStatus?.ToLower())
    {
        case "active":
            csentry["userAccountControl"].IntegerValue = 512; // Normal account
            break;
        case "disabled":
            csentry["userAccountControl"].IntegerValue = 514; // Disabled account
            break;
        case "terminated":
            // Don't export - let deprovisioning rule handle
            break;
    }
}
```

### 3. Provisioning Rules

Control object provisioning and deprovisioning logic.

```csharp
public DeprovisionAction ShouldDeleteFromMV(
    CSEntry csentry,
    MVEntry mventry)
{
    // Don't delete if other connectors have the object
    if (mventry.ConnectedMAs.Count > 1)
    {
        return DeprovisionAction.ExplicitDisconnector;
    }
    
    // Check if object should be preserved
    string objectType = mventry["objectType"].StringValue;
    if (objectType == "criticalAccount")
    {
        return DeprovisionAction.ExplicitDisconnector;
    }
    
    return DeprovisionAction.Delete;
}

public bool ShouldProjectToMV(CSEntry csentry, out string MVObjectType)
{
    MVObjectType = "";
    
    // Only project if required attributes are present
    if (csentry["employeeID"].IsPresent && 
        csentry["mail"].IsPresent)
    {
        MVObjectType = "person";
        return true;
    }
    
    return false;
}
```

## Advanced Scenarios

### 1. External API Integration

```csharp
using System.Net.Http;
using System.Threading.Tasks;
using Newtonsoft.Json;

public class ExternalAPIIntegration
{
    private static readonly HttpClient httpClient = new HttpClient();
    
    public async Task<string> GetUserDataFromAPI(string employeeId)
    {
        try
        {
            string apiUrl = $"https://api.company.com/users/{employeeId}";
            
            var response = await httpClient.GetAsync(apiUrl);
            response.EnsureSuccessStatusCode();
            
            string jsonResponse = await response.Content.ReadAsStringAsync();
            dynamic userData = JsonConvert.DeserializeObject(jsonResponse);
            
            return userData.department;
        }
        catch (Exception ex)
        {
            // Log error and handle gracefully
            WriteLog($"API call failed: {ex.Message}");
            return null;
        }
    }
}
```

### 2. Database Lookups

```csharp
using System.Data.SqlClient;

public class DatabaseLookup
{
    private string connectionString = "Server=dbserver;Database=HR;Integrated Security=true;";
    
    public string LookupManagerInfo(string employeeId)
    {
        using (var connection = new SqlConnection(connectionString))
        {
            connection.Open();
            
            string query = @"
                SELECT m.EmployeeID 
                FROM Employees e 
                INNER JOIN Employees m ON e.ManagerID = m.EmployeeID 
                WHERE e.EmployeeID = @EmployeeID";
            
            using (var command = new SqlCommand(query, connection))
            {
                command.Parameters.AddWithValue("@EmployeeID", employeeId);
                
                object result = command.ExecuteScalar();
                return result?.ToString();
            }
        }
    }
}
```

### 3. Complex Attribute Transformations

```csharp
public void TransformPhoneNumber(CSEntry csentry, MVEntry mventry)
{
    string rawPhone = csentry["telephoneNumber"].StringValue;
    
    if (!string.IsNullOrEmpty(rawPhone))
    {
        // Remove all non-numeric characters
        string digitsOnly = new string(rawPhone.Where(char.IsDigit).ToArray());
        
        // Format based on length
        switch (digitsOnly.Length)
        {
            case 7:
                mventry["telephoneNumber"].StringValue = $"{digitsOnly.Substring(0, 3)}-{digitsOnly.Substring(3)}";
                break;
            case 10:
                mventry["telephoneNumber"].StringValue = $"({digitsOnly.Substring(0, 3)}) {digitsOnly.Substring(3, 3)}-{digitsOnly.Substring(6)}";
                break;
            case 11 when digitsOnly.StartsWith("1"):
                string domestic = digitsOnly.Substring(1);
                mventry["telephoneNumber"].StringValue = $"+1 ({domestic.Substring(0, 3)}) {domestic.Substring(3, 3)}-{domestic.Substring(6)}";
                break;
            default:
                mventry["telephoneNumber"].StringValue = rawPhone; // Keep original if can't format
                break;
        }
    }
}
```

## Error Handling and Logging

### 1. Exception Management

```csharp
public void MapAttributesForImport(
    string FlowRuleName,
    CSEntry csentry,
    MVEntry mventry)
{
    try
    {
        switch (FlowRuleName)
        {
            case "ComplexTransformation":
                ComplexTransformation(csentry, mventry);
                break;
        }
    }
    catch (UnexpectedDataException ex)
    {
        // Log specific data issues
        WriteLog($"Data validation failed for {csentry.DN}: {ex.Message}");
        throw new EntryPointNotImplementedException($"Data validation error: {ex.Message}");
    }
    catch (Exception ex)
    {
        // Log general errors
        WriteLog($"Unexpected error in {FlowRuleName}: {ex.Message}");
        throw;
    }
}
```

### 2. Logging Implementation

```csharp
using System.IO;

public static class Logger
{
    private static readonly object lockObject = new object();
    private static readonly string logPath = @"C:\Program Files\Microsoft Forefront Identity Manager\2010\Synchronization Service\Logs\RuleExtensions.log";
    
    public static void WriteLog(string message)
    {
        lock (lockObject)
        {
            try
            {
                string logEntry = $"{DateTime.Now:yyyy-MM-dd HH:mm:ss} - {message}";
                File.AppendAllText(logPath, logEntry + Environment.NewLine);
            }
            catch
            {
                // Fail silently - don't break sync for logging issues
            }
        }
    }
}
```

## Testing and Debugging

### 1. Unit Testing Framework

```csharp
using Microsoft.VisualStudio.TestTools.UnitTesting;

[TestClass]
public class RuleExtensionTests
{
    [TestMethod]
    public void TestDisplayNameFormatting()
    {
        // Arrange
        var extension = new AttributeFlowExtensions();
        var mockCSEntry = CreateMockCSEntry();
        var mockMVEntry = CreateMockMVEntry();
        
        mockCSEntry["givenName"].StringValue = "John";
        mockCSEntry["sn"].StringValue = "Doe";
        
        // Act
        extension.MapAttributesForImport("FormatDisplayName", mockCSEntry, mockMVEntry);
        
        // Assert
        Assert.AreEqual("Doe, John", mockMVEntry["displayName"].StringValue);
    }
}
```

### 2. Debug Configuration

```csharp
#if DEBUG
    public static void WriteDebugLog(string message)
    {
        string debugLogPath = @"C:\Temp\MIMDebug.log";
        File.AppendAllText(debugLogPath, $"{DateTime.Now:HH:mm:ss} - {message}\n");
    }
#endif
```

## Deployment and Configuration

### 1. Assembly Deployment

1. **Build the Project** in Release mode
2. **Copy the Assembly** to Extensions folder:

   ```text
   C:\Program Files\Microsoft Forefront Identity Manager\2010\Synchronization Service\Extensions\
   ```

3. **Restart the Synchronization Service**
4. **Configure Rules** in Synchronization Service Manager

### 2. Rule Configuration

1. **Open Synchronization Service Manager**
2. **Navigate to Management Agents**
3. **Configure Attribute Flow Rules**
4. **Specify Rule Extension Method Names**
5. **Test with Preview**

### 3. Version Management

```csharp
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]
[assembly: AssemblyInformationalVersion("1.0.0")]
```

## Performance Considerations

### 1. Efficient Code Patterns

```csharp
// Use static variables for expensive operations
private static readonly Regex phoneRegex = new Regex(@"[^\d]", RegexOptions.Compiled);

// Cache frequently accessed data
private static readonly Dictionary<string, string> departmentCache = new Dictionary<string, string>();

public void OptimizedTransformation(CSEntry csentry, MVEntry mventry)
{
    // Minimize object creation
    string employeeId = csentry["employeeID"].StringValue;
    
    if (string.IsNullOrEmpty(employeeId))
        return;
    
    // Use cached data when possible
    if (departmentCache.TryGetValue(employeeId, out string cachedDepartment))
    {
        mventry["department"].StringValue = cachedDepartment;
        return;
    }
    
    // Fetch and cache if not found
    string department = LookupDepartment(employeeId);
    departmentCache[employeeId] = department;
    mventry["department"].StringValue = department;
}
```

### 2. Resource Management

```csharp
public void ManageResources()
{
    using (var connection = new SqlConnection(connectionString))
    {
        connection.Open();
        // Database operations
    } // Connection automatically disposed
}
```

## Security Best Practices

### 1. Secure Configuration

```csharp
public class SecureConfiguration
{
    private static string GetEncryptedConnectionString()
    {
        // Use Windows DPAPI or similar for sensitive data
        string encryptedValue = ConfigurationManager.AppSettings["EncryptedConnectionString"];
        return DecryptString(encryptedValue);
    }
}
```

### 2. Input Validation

```csharp
public void ValidateInput(CSEntry csentry)
{
    string email = csentry["mail"].StringValue;
    
    if (!string.IsNullOrEmpty(email))
    {
        if (!IsValidEmail(email))
        {
            throw new InvalidDataException($"Invalid email format: {email}");
        }
    }
}

private bool IsValidEmail(string email)
{
    try
    {
        var addr = new System.Net.Mail.MailAddress(email);
        return addr.Address == email;
    }
    catch
    {
        return false;
    }
}
```

## Troubleshooting Common Issues

### 1. Assembly Loading Issues

**Problem**: Rule extension not found
**Solution**:

- Verify assembly is in correct folder
- Check assembly dependencies
- Restart synchronization service

### 2. Performance Problems

**Problem**: Slow synchronization
**Solution**:

- Profile rule extension code
- Optimize database queries
- Implement caching strategies

### 3. Memory Leaks

**Problem**: Increasing memory usage
**Solution**:

- Dispose resources properly
- Avoid static collections that grow indefinitely
- Monitor object lifecycle

## Best Practices

### 1. Design Principles

- **Keep it Simple**: Implement only necessary complexity
- **Fail Fast**: Validate inputs early
- **Be Defensive**: Handle unexpected scenarios
- **Log Appropriately**: Balance detail with performance

### 2. Code Organization

- **Separate Concerns**: One class per responsibility
- **Use Interfaces**: Enable testability
- **Document Code**: Include XML documentation
- **Version Control**: Track all changes

### 3. Testing Strategy

- **Unit Tests**: Test individual methods
- **Integration Tests**: Test with MIM components
- **Performance Tests**: Validate under load
- **Regression Tests**: Prevent breaking changes

## Conclusion

Rule Extensions provide powerful capabilities for customizing MIM 2016 Synchronization Service behavior. By following the patterns, practices, and guidelines outlined in this document, developers can create robust, maintainable, and performant extensions that meet complex business requirements while maintaining system stability and security.

## Related Topics

- **[MIM 2016 Synchronization Service Overview](index.md)**: Main service architecture
- **[SQL Synchronization Guide](sql-sync-guide.md)**: Implementation examples
- **[Troubleshooting Guide](troubleshooting.md)**: Common issues and solutions
- **[Performance Tuning](performance-tuning.md)**: Optimization strategies
