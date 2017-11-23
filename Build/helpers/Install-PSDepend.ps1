<#
.SYNOPSIS
    Bootstrap PSDepend

.DESCRIPTION
    Bootstrap PSDepend

    Why? No reliance on PowerShellGallery

        * Downloads nuget to your ~\ home directory
        * Creates $Path (and full path to it)
        * Downloads module to $Path\PSDepend
        * Moves nuget.exe to $Path\PSDepend (skips nuget bootstrap on initial PSDepend import)

.PARAMETER Path
    Module path to install PSDepend

    Defaults to Profile\Documents\WindowsPowerShell\Modules

.EXAMPLE
    .\Install-PSDepend.ps1 -Path C:\Modules

    # Installs to C:\Modules\PSDepend
#>
[CmdletBinding()]
param
(
    [Parameter()]
    [string]
    $Path = $(Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Modules')
)

$ExistingProgressPreference = $ProgressPreference
$ProgressPreference         = 'SilentlyContinue'

try
{
    # Bootstrap nuget if we don't have it
    if (-not($nugetPath = (Get-Command -Name 'nuget.exe' -ErrorAction SilentlyContinue).Path))
    {
        $nugetPath = Join-Path -Path $env:USERPROFILE nuget.exe

        if (-not (Test-Path -Path $nugetPath))
        {
            Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile $nugetPath
        }
    }

    # Bootstrap PSDepend, re-use nuget.exe for the module
    if ($path)
    {
        $null = New-Item -Path $path -ItemType 'Directory' -Force
    }

    $nugetParams = 'install', 'PSDepend', '-Source', 'https://www.powershellgallery.com/api/v2/',
                    '-ExcludeVersion', '-NonInteractive', '-OutputDirectory', $Path
    & $nugetPath @nugetParams

    Move-Item -Path $nugetPath -Destination "$(Join-Path -Path $Path PSDepend)\nuget.exe" -Force
}
catch
{
    Write-Error -Message $_
}
finally
{
    $ProgressPreference = $ExistingProgressPreference
}
