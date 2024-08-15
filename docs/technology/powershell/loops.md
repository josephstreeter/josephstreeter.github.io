# Loops

## For Loop

```powershell
for ($var = 1; $var -le 5 -and $var -ne 3; $var++) 
{
    Write-Host The value of Var is: $var
}

Write-Host End of for loop.
```

## Foreach Loop

```powershell
$collection = 1..5
foreach ($item in $collection) 
{
    Write-Host The value of Item is: $item
}

Write-Host End of foreach loop
```

```powershell
foreach ($service in (Get-Service | Select-Object -First 5)) 
{
    Write-Host Service name is: $service.name and status is $service.status
}
```

## While Loop

```powershell
$var = 1
while ($var -le 5)
{
    Write-Host The value of Var is: $var
    $var++
}

Write-Host End of While loop.
```
