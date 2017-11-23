# Dot source this script in any Pester test script that requires the module to be imported.
if (-not $env:BHProjectPath)
{
    Set-BuildEnvironment -Path "$PSScriptRoot\.."
}
$PSVersion  = $PSVersionTable.PSVersion.Major
$ModuleName = $env:BHProjectName

Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
Import-Module (Join-Path -Path  $env:BHProjectPath $ModuleName) -Force

