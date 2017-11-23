@{
    # Some defaults for all dependencies
    PSDependOptions = @{
        Target = '$env:USERPROFILE\Documents\WindowsPowerShell\Modules'
        AddToPath = $true
    }

    # Grab some modules without depending on PowerShellGet
    'InvokeBuild' = @{
        DependencyType = 'PSGalleryNuget'
        Version = 'latest'
    }
    'PSDeploy' = @{
        DependencyType = 'PSGalleryNuget'
        Version = 'latest'
    }
    'BuildHelpers' = @{
        DependencyType = 'PSGalleryNuget'
        Version = 'latest'
    }
    'Pester' = @{
        DependencyType = 'PSGalleryNuget'
        Version = 'latest'
    }
    'PSScriptAnalyzer' = @{
        DependencyType = 'PSGalleryNuget'
        Version = 'latest'
    }
    'platyPS' = @{
        DependencyType = 'PSGalleryNuget'
        Version = 'latest'
    }
}
