# Table of Contents Creation Script

This is a PowerShell script that creates a Table of Contents file for earch directory.

The script recursivly grabs all of the directories under "./doc" and puts them in an array. It then loops through them all and queries the child objects for each directory, omitting files named "toc.yml" and directories named "media." The script was written to create ToC files for a Microsoft OneNote converted to Markdown. The "media" folders are where the conversion tool places the images.

Entries for the "toc.yml" file are created by looping through the child objects of the directory. The name of the file or directory is formated depending on type and written to a yml file in the directory.

## Code

```powershell
function New-Toc()
{
    Param
    (
        $Folder
    )

    $Contents = Get-Childitem -path $Folder | Where-Object {$_.name -ne "toc.yml" -and $_.name -ne "media"}
    
    foreach ($Content in $Contents)
    {
        if ($Content.Mode -like "d*")
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
        "$directory\toc.yml"
        $Toc | Out-File "$directory\toc.yml"
    }
}
```
