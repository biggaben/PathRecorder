$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
$manifestPath = Join-Path $scriptDirectory "PathFinder.psd1" 
$functions = (Get-Command -Module PathFinder).Name

$manifestParams = @{
    Path = $manifestPath
    RootModule       = 'PathFinder.psm1'
    Author           = 'David Holmertz'
    ModuleVersion    = '1.0.0'
    FunctionsToExport = $functions 
    Description      = 'Provides tools for managing and navigating frequently used file system paths.' 
}

New-ModuleManifest @manifestParams