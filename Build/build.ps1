[CmdletBinding()]
param
(
    [Parameter()]
    [bool]
    $NoClean = $true,

    [Parameter()]
    [string]
    $Environment = 'Local',

    [Parameter()]
    [string]
    $BuildOutput
)

Set-BuildEnvironment -BuildOutput $BuildOutput -Path "$PSScriptRoot\.." -Force

if ($env:BHProjectPath)
{
    $ProjectRoot = $env:BHProjectPath
    $BuildOutput = $env:BHBuildOutput
    "Build variables:" | Out-Host
    Get-Item ENV:BH* | Out-Host
}
else
{
    $ProjectRoot = (Resolve-Path -Path "$PSScriptRoot/..").Path

    if (-not $BuildOutput)
    {
        $BuildOutput = Join-Path -Path $ProjectRoot BuildOutput
    }
}
$PesterOutput = Join-Path -Path $BuildOutput Pester

$lines = '----------------'

$verbose = @{}

if ($env:BHCommitMessage -match "!verbose")
{
    $verbose = @{ Verbose = $true }
}

# Runs tests, returns path of test output files
function Invoke-Tests
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $TestPath,

        [Parameter()]
        [string]
        $PesterOutput = $PesterOutput
    )

    $PSVersion = $PSVersionTable.PSVersion.Major
    "`n`tSTATUS: Testing with PowerShell $PSVersion"

    # Gather test results. Store them in a variable and file
    $timestamp   = Get-Date -uformat "%Y%m%d-%H%M%S"
    $testFile    = "TestResults_PS$PSVersion`_$timeStamp.xml"
    $testResults = Invoke-Pester -Path $TestPath -PassThru -OutputFormat NUnitXml -OutputFile "$ProjectRoot\$testFile"

    # In Appveyor?  Upload our tests! #Abstract this into a function?
    if ($env:BHBuildSystem -eq 'AppVeyor')
    {
        Add-TestResultToAppveyor -TestFile "$ProjectRoot\$testFile"
    }

    # Failed tests?
    # Need to tell psake or it will proceed to the deployment. Danger!
    if ($testResults.FailedCount -gt 0)
    {
        Write-Error -Message "Failed '$($testResults.FailedCount)' tests, build failed"
    }
} # Invoke-Tests

# Default task is 'deploy'
Task . Test

Task Init {
    $lines
    Set-Location -Path $ProjectRoot
    $null = New-Item -Path $BuildOutput -ItemType Directory -Force

    if ($verbose.Verbose)
    {
        Get-BuildEnvironmentDetail -KillKittens
    }
    "`n"
}

Task Clean {
    if (-not $NoClean)
    {
        Remove-Item -Path $BuildOutput -Force -Recurse -ErrorAction SilentlyContinue
    }
}

Task Build {
    $lines
    Invoke-PSDeploy -Path "$ProjectRoot\Build" -Force $true -Tags 'Build'
    Set-ModuleFunctions -Name "$env:BHBuildOutput\$env:BHProjectName"

    # Bump the module version
    try
    {
        $version = Get-NextPSGalleryVersion -Name $env:BHProjectName -ErrorAction Stop
        #TODO: If Version is less than current, skip
        $metaParam = @{
            Path         = "$env:BHBuildOutput\$env:BHProjectName\$env:BHProjectName.psd1"
            PropertyName = 'ModuleVersion'
            Value        = $version
            ErrorAction  = 'Stop'
        }
        Update-Metadata @metaParam
    }
    catch
    {
        "Failed to update version for '$env:BHProjectName': $_.`nContinuing with existing version"
    }
}

Task Test Init, Build, {
    $lines
    Invoke-Tests -TestPath "$ProjectRoot\Test\" -PesterOutput $BuildOutput
    "`n"
}, Clean

Task Deploy Init, Build, Test, {
    $lines

    $skipNotice = "Deploying items tagged [$tag]" +
                  "    `$env:APPVEYOR_PROJECT_NAME:            $env:APPVEYOR_PROJECT_NAME" +
                  "    `$env:BHBuildSystem -eq 'AppVeyor':     $($env:BHBuildSystem -eq 'AppVeyor')" +
                  "    `$env:BHBranchName -eq 'master':        $($env:BHBranchName -eq "master")" +
                  "    `$env:BHCommitMessage -match '!deploy': $($env:BHCommitMessage -match '!deploy')"

    if ($env:APPVEYOR_PROJECT_NAME)
    {
        $tag = 'AppVeyor'

        if ( $env:BHBuildSystem -eq 'AppVeyor' -and # you might gate deployments to your build system
             $env:BHBranchName -eq "master" -and    # you might have another deployment for dev, or use tagged deployments based on branch
             $env:BHCommitMessage -match '!deploy'  # you might add a trigger via commit message
        )
        {
            $tag = 'AppVeyor-Deploy'
        }
        else
        {
            $tag = 'AppVeyor'
            $skipNotice
        }
    }
    else
    {
        $tag = 'Local'
        $skipNotice
    }

    $params = @{
        Path  = $ProjectRoot
        Force = $true
        Tags  = $tag
    }
    $deployOutput = Invoke-PSDeploy @verbose @params

    if ($verbose.Verbose)
    {
        $deployOutput
    }
    "`n"
}, Clean
