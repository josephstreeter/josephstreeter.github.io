# Loops

## For Loop

```powershell
for ($var = 1; $var -le 5 -and $var -ne 3; $var++) 
{
    Write-Output The value of Var is: $var
}
```

## Foreach Loop

```powershell
$collection = 1..15

foreach ($item in $collection) 
{
    Write-Output The value of Item is: $item
}
```

```powershell
foreach ($service in (Get-Service | Select-Object -First 5)) 
{
    Write-Output "Service name is: $service.name and status is $service.status"
}
```

## While Loop and Do Loop

While Loop

```powershell
$var = 1
while ($var -le 5)
{
    Write-Output The value of Var is: $var
    $var++
}
```

Do Loop

```Powershell
do {
  if ($x[$a] -lt 0) { continue }
  Write-Host $x[$a]
}
while (++$a -lt 10)
```