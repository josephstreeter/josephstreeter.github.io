# Conditions

## If Statement

```powershell
if (condition1) 
{
   # code to execute if condition1 is true
}
```

## If Else Statement

```powershell
if (condition1) 
{
   # code to execute if condition1 is true
}
else 
{
   # code to execute if all conditions are false
}
```

## If ElseIf Statement

```powershell
if (condition1) 
{
   # code to execute if condition1 is true
}
elseif (condition2) 
{
   # code to execute if condition2 is true
}
else 
{
   # code to execute if all conditions are false
}
```

## If Else Finally

```powershell

```

## Switch

```powershell
$color = "red"
switch ($color) 
{
    "red" { Write-Host "The color is red." }
    "blue" { Write-Host "The color is blue." }
    "green" { Write-Host "The color is green." }
    default { Write-Host "The color is not red, blue, or green." }
}
```
