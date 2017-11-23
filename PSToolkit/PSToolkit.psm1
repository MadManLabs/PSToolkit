[CmdletBinding()]
param
(
    [bool]$DebugModule = $false
)

# Get public and private function definition files
$Enums       = @( Get-ChildItem -Path $PSScriptRoot\Enums\*.ps1 -ErrorAction SilentlyContinue )
$Classes     = @( Get-ChildItem -Path $PSScriptRoot\Classes\*.ps1 -ErrorAction SilentlyContinue )
$Public      = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private     = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )
$FilesToLoad = @([object[]]$Enums + [object[]]$Classes + [object[]]$Public + [object[]]$Private) | Where-Object {$_}
$ModuleRoot  = $PSScriptRoot

# Dot source the files
# Thanks to Bartek, Constatine
# https://becomelotr.wordpress.com/2017/02/13/expensive-dot-sourcing/
foreach ($file in $FilesToLoad)
{
    try
    {
        if ($DebugModule)
        {
            . $file.FullName
        }
        else
        {
            . ([scriptblock]::Create([io.file]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)))
        }
    }
    catch
    {
        Write-Error -Message "Failed to import function $($file.fullname)"
        Write-Error $_
    }
}

Export-ModuleMember -Function $Public.Basename
