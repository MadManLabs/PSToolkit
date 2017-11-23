# Generic module deployment.
#
# ASSUMPTIONS:
#
# * Nuget key in $env:NugetApiKey
# * Set-BuildEnvironment from BuildHelpers module has populated ENV:BHPSModulePath and related variables

Deploy LocalModule {
    By FileSystem ModuleCopy {
        FromSource $env:BHModulePath
        To $env:BHBuildOutput\$env:BHProjectName
        Tagged Local, AppVeyor, Build, ModuleCopy
        WithOptions @{
            Mirror = $true
        }
    }

    By platyPS docs {
        FromSource $env:BHProjectPath\docs\en-US
        To $env:BHBuildOutput\$env:BHProjectName\en-US
        Tagged Local, AppVeyor, Build, Docs
        WithOptions @{
            SourceIsAbsolute = $true
            Force = $true
        }
        DependingOn LocalModule-ModuleCopy
    }
}

Deploy Module {
    By PSGalleryModule {
        FromSource $env:BHBuildOutput\$env:BHProjectName
        To PSGallery
        Tagged AppVeyor-Deploy
        WithOptions @{
            ApiKey = $env:NugetApiKey
        }
        DependingOn LocalModule-docs
    }

    By AppVeyorModule {
        FromSource $env:BHBuildOutput\$env:BHProjectName
        To AppVeyor
        Tagged AppVeyor
        WithOptions @{
            Version = $env:APPVEYOR_BUILD_VERSION
        }
        DependingOn Module-platyPS
    }
}
