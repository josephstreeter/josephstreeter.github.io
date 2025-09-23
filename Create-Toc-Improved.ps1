<#
.SYNOPSIS
    Creates table of contents (toc.yml) files for DocFX documentation.
.DESCRIPTION
    This script recursively searches the docs directory for folders without toc.yml files
    and generates appropriate toc.yml files based on the contents of each folder.
.PARAMETER DocsRootPath
    The root path of the documentation files. Defaults to './docs'.
.EXAMPLE
    .\Create-Toc-Improved.ps1
    Creates toc.yml files in all subdirectories of the ./docs folder.
.EXAMPLE
    .\Create-Toc-Improved.ps1 -DocsRootPath './documentation'
    Creates toc.yml files in all subdirectories of the ./documentation folder.
.NOTES
    Author: Joseph Streeter
    Version: 1.0
#>
function New-Toc
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FolderPath
    )

    begin
    {
        Write-Verbose -Message "Starting to create TOC for folder: $FolderPath"
    }

    process
    {
        try
        {
            $Contents = Get-ChildItem -Path $FolderPath -ErrorAction Stop | 
                Where-Object { $_.Name -ne "toc.yml" -and $_.Name -ne "media" }
            
            $TocEntries = [System.Collections.Generic.List[string]]@()
            
            foreach ($Content in $Contents)
            {
                $FormattedName = $Content.Name.Replace("-", " ").Replace(".md", "")
                
                if ($Content.UnixMode -like "d*")
                {
                    $EntryText = "- name: $FormattedName`n  href: $($Content.Name)/toc.yml"
                    $TocEntries.Add($EntryText)
                }
                else 
                {
                    $EntryText = "- name: $FormattedName`n  href: $($Content.Name)"
                    $TocEntries.Add($EntryText)
                }
            }
            
            return $TocEntries
        }
        catch
        {
            Write-Error -Message "Error processing folder $FolderPath : $($_.Exception.Message)"
        }
    }

    end
    {
        Write-Verbose -Message "Completed TOC creation for folder: $FolderPath"
    }
}

function Update-DocFxTableOfContents
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$DocsRootPath = './docs'
    )

    begin
    {
        Write-Verbose -Message "Starting TOC generation for all directories in $DocsRootPath"
        
        if (-not (Test-Path -Path $DocsRootPath))
        {
            Write-Error -Message "The specified docs path does not exist: $DocsRootPath"
            return
        }
    }

    process
    {
        try
        {
            $Directories = Get-ChildItem -Path $DocsRootPath -Recurse -Directory -ErrorAction Stop | 
                Where-Object { $_.Name -ne "media" }
            
            $TocCreationCount = 0
            
            foreach ($Directory in $Directories)
            {
                if ((Get-ChildItem -Path $Directory).Name -notcontains "toc.yml")
                {
                    Write-Verbose -Message "Creating toc.yml for $($Directory.FullName)"
                    
                    $TocContent = New-Toc -FolderPath $Directory.FullName
                    
                    $TocPath = Join-Path -Path $Directory.FullName -ChildPath "toc.yml"
                    $TocContent | Out-File -FilePath $TocPath -Encoding utf8
                    
                    Write-Verbose -Message "Created toc.yml at $TocPath"
                    $TocCreationCount++
                }
            }
            
            Write-Output "TOC generation complete. Created $TocCreationCount new toc.yml files."
        }
        catch
        {
            Write-Error -Message "Error during TOC generation: $($_.Exception.Message)"
        }
    }

    end
    {
        Write-Verbose -Message "Completed TOC generation process"
    }
}

# Execute the main function to update the table of contents
Update-DocFxTableOfContents -Verbose