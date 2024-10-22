# Variables

[https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_variables?view=powershell-7.4](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_variables?view=powershell-7.4)

```powershell
$a = 93                         # System.Int32
$a = "string"                   # System.String
$a = "string", 120              # array of System.Int32, System.String
$a = Get-ChildItem C:\Windows   # FileInfo and DirectoryInfo types
```

```powershell
[int]$count = 256         # Creates a variable that will only contain an int
$count = 1024             # Sets the variable to another int
$count = "256"            # Converts the string to an int
$count = "String"         # Throws an error "Cannot convert value "String" to type "System.Int32". Error: "Input string was not in a correct format."
```
