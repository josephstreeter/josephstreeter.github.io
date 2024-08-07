
function New-Toc()
{
    Param
    (
        $Folder
    )

    $Contents = get-childitem -path $Folder | Where-Object {$_.name -ne "toc.yml" -and $_.name -ne "media"}
    
    foreach ($Content in $Contents)
    {
        if ($Content.UnixMode -like "d*")
        {
            "- name: {0}`n  href: {1}/toc.yml" -f ($Content.name).Replace("-"," ").Replace(".md",""), $Content.Name
        }
        else 
        {
            "- name: {0}`n  href: {1}" -f ($Content.name).Replace("-"," ").Replace(".md",""), $Content.name
        }
    }
}

$directories = Get-ChildItem ./docs -Recurse -Directory | Where-Object {$_.name -ne "media"}

foreach ($directory in $directories)
{
    if ((Get-ChildItem -Path $directory).name -notcontains "toc.yml")
    {
        $Toc = New-Toc -Folder $directory
        "$directory/toc.yml"
        $Toc | Out-File "$directory/toc.yml"
    }
}
