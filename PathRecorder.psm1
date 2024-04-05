$RecordedPathsFile = Join-Path $PSScriptRoot "recorded_paths.json"
# Module Scoped Variable
#$recordedPaths = @()

function Invoke-LoadRecordedPaths {
    # Directly manipulate the module-scoped variable
    if (Test-Path $RecordedPathsFile) {
        Get-Content $RecordedPathsFile | ConvertFrom-Json
    } else {
        @() # Return an empty array if the file doesn't exist
    }
}

# Initial load of paths from file
#Invoke-LoadRecordedPaths

function Add-RecordedPath {
    param (
        [string]$Path,
        [string]$Name = $null
    )

    $pathObject = [PSCustomObject]@{
        Path = $Path
        Name = $Name
    }

    $recordedPaths += $pathObject
    Save-RecordedPaths # Assuming there's a function to save these
}

function Save-RecordedPaths {
    $recordedPaths | ConvertTo-Json | Set-Content $RecordedPathsFile
}


<#
.SYNOPSIS
Records the current path with an optional name. Alias: createpath, path-create

.DESCRIPTION
The New-RecordedPath function records the current path with an optional name. This is useful for quickly returning to a specific location in the file system. The recorded paths are stored in a file for persistence across sessions.

.PARAMETER pattern
This parameter is not used in the function and can be ignored.

.PARAMETER name
The optional name to associate with the recorded path. If a name is provided, you can return to the recorded path with 'repath <name>'. If a name is not provided, you can return to the recorded path with 'repath'.

.INPUTS
String. You can pipe a string that contains the name to New-RecordedPath.

.OUTPUTS
String. Outputs a message to the console indicating that the path has been recorded and how to return to it.

.EXAMPLE
PS> New-RecordedPath -name "MyPath"
Records the current path with the name "MyPath". You can return to this path with 'repath MyPath'.

.EXAMPLE
PS> New-RecordedPath
Records the current path without a name. You can return to this path with 'spath'.
#>
function New-RecordedPath {
    param (
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, HelpMessage="Optional name to associate with the recorded path. If not provided, the path is recorded without a name.")]
        [string]$name = $null
    )

    $recordedPaths = @()
    if (Test-Path $RecordedPathsFile) {
        try {
            $jsonContent = Get-Content $RecordedPathsFile | Out-String
            $tempPaths = ConvertFrom-Json -InputObject $jsonContent
            if ($null -ne $tempPaths) {
                $recordedPaths = @($tempPaths)
            }
        } catch {
            Write-Warning "Failed to parse paths from $RecordedPathsFile. Starting fresh."
        }
    }
    
    # Calculate the next index value
    $index = $recordedPaths.Count + 1
    $pathValue = (Get-Location).Path

    $pathObject = New-Object PSObject -Property @{
        'No'  = $index 
        'Name' = $name 
        'Path' = $pathValue
    }
    
    $recordedPaths += $pathObject

    # Convert the updated array back to JSON and save
    try {
        $recordedPaths | ConvertTo-Json | Set-Content $RecordedPathsFile 
    } catch {
        Write-Error "Error saving paths to ${RecordedPathsFile}: $_"
    } 

    if ($name) {
        Write-Host "Path '$name -> $pathValue' recorded" -ForegroundColor Green
        Write-Host "Return to this path with 'path-set $name'" -ForegroundColor Yellow
    } else {
        Write-Host "Path '$pathValue' recorded" -ForegroundColor Green
        Write-Host "Return to this path with 'path-set'" -ForegroundColor Blue
    }
}


<# 
.SYNOPSIS
Sets the last path that was accessed. Alias: lastPath, rePath

.DESCRIPTION
The Set-LastPath function sets the last path that was accessed. This is useful for keeping track of the last location that was accessed for any purpose like auditing, logging, or returning to a previous location.

.PARAMETER path
The path to set as the last accessed path. This parameter is required.

.INPUTS
String. You can pipe a string that contains the path to Set-LastPath.

.OUTPUTS
None. This function does not output any data.

.EXAMPLE
PS> lastPath -path "C:\MyFolder"
PS> rePath -path "C:\MyFolder"
Sets "C:\MyFolder" as the last accessed path.

#>
function Set-LastPath {
    param( [string]$path )

    if (Test-Path $RecordedPathsFile) {
        $jsonContent = Get-Content $RecordedPathsFile | ConvertFrom-Json

        # Check for empty content
        if (-not $jsonContent -or $jsonContent.Count -eq 0) {
            Write-Host "The recorded paths list is empty. Record new path with 'path-create'." -ForegroundColor Yellow
            return  # Exit if no paths are recorded
        }

        # Update the "Last" property
        $recordedPaths | ForEach-Object { 
            $_.Last = ($_.Path -eq $path) 
        }

        # Save the changes back to the file
        $recordedPaths | ConvertTo-Json | Set-Content $RecordedPathsFile

    } else {
        Write-Host "No recorded paths file found." -ForegroundColor Red
    }
}


<# .SYNOPSIS
Retrieves the paths that have been recorded. Alias: listPaths, lPath

.DESCRIPTION
The Get-RecordedPaths function retrieves the paths that have been recorded. This is useful for reviewing the paths that have been recorded for any purpose like auditing, logging, or further processing.

.PARAMETER None
This function does not take any parameters.

.INPUTS
None. You cannot pipe inputs to Get-RecordedPaths.

.OUTPUTS
String. Outputs the recorded paths to the console.

.EXAMPLE
PS> Get-RecordedPaths
Retrieves all the recorded paths.

#>
function Get-RecordedPaths {
    $recordedPaths = Invoke-LoadRecordedPaths

    if (-not $recordedPaths) { 
        Invoke-LoadRecordedPaths  # Load data if it's not already present
    } 

    # Check if loading was successful
    if (-not $recordedPaths) {
        Write-Host "The recorded paths list is empty. Create new path with 'path-create'." -ForegroundColor Yellow
        return 
    } 

    # List available paths
    Write-Host "Available paths:" -ForegroundColor Green
    $recordedPaths | ForEach-Object { 
        $index = $_.No; $name = $_.Name; $path = $_.Path; 
        Write-Host "$index`: $name - $path" -ForegroundColor Blue
    }
}



<#
.SYNOPSIS
Selects a recorded path by its index or name. Alias: , SelectPath sPath

.DESCRIPTION
The Select-RecordedPath function selects a recorded path by its index or name. This is useful for quickly returning to a specific location in the file system. The recorded paths are retrieved from a file for persistence across sessions.

.PARAMETER indexOrName
The index or name of the recorded path to select. If an index is provided, it selects the recorded path at that index. If a name is provided, it selects the recorded path with that name. This parameter is optional and defaults to the last recorded path.

.INPUTS
String, Int. You can pipe a string that contains the name or an integer for the index to Select-RecordedPath.

.OUTPUTS
String. Outputs the selected path to the console when the location is changed.

.EXAMPLE
PS> SelectPath -indexOrName 2
Selects the recorded path at index 2 and sets the current location to that path.

.EXAMPLE
PS> sPath -indexOrName "MyPath"
Selects the recorded path with the name "MyPath" and sets the current location to that path.
#>
function Select-RecordedPath {
    param (
        [Parameter(Mandatory=$false, HelpMessage="The index or name of the recorded path to select. If not provided, the user is prompted to select a path.")]
        [string]$indexOrName = $null
    )

    if (-not $indexOrName) { 
        Write-Host "Available paths:" -ForegroundColor Green

        $menuItems = $recordedPaths | ForEach-Object { "$($_.No): $($_.Name) - $($_.Path)" }
        $selectedPath = Show-InteractivePathMenu "Select a Path" $menuItems
    }

    $recordedPaths = if (Test-Path $RecordedPathsFile) {
        $jsonContent = Get-Content $RecordedPathsFile | ConvertFrom-Json
        # Check if the content is null or the count is 0 for an array
        if (-not $jsonContent -or $jsonContent.Count -eq 0) {
            Write-Host "The recorded paths list is empty. Record new path with 'path-create'." -ForegroundColor Yellow
            @() # Return an empty array to avoid further null checks
            return
        } else {
            $jsonContent
        }
    } else {
        Write-Host "No recorded paths file found." -ForegroundColor Red
        @() # Return an empty array to avoid further null checks
    }

    if (-not $indexOrName) {
        # List available paths
        Write-Host "Available paths:" -ForegroundColor Green
        $recordedPaths | ForEach-Object { $index = $_.'No'; $name = $_.Name; $path = $_.Path; Write-Host "$index`: $name - $path" -ForegroundColor Blue}

        # Prompt user to select by name or index
        $selection = Read-Host "Please select a path by Name or Index"
        if ($selection -match '^\d+$') {
            # If selection is a number, attempt to select by index
            $selectedPath = $recordedPaths[$selection - 1].Path
        } else {
            # Otherwise, attempt to select by name
            $selectedPath = $recordedPaths | Where-Object { $_.Name -eq $selection } | Select-Object -First 1 -ExpandProperty Path
        }
    } elseif ($indexOrName -match '^\d+$') {
        # If an index is specified, select by index
        $selectedPath = $recordedPaths[$indexOrName - 1].Path
    } else {
        # If a name is specified, select by name
        $selectedPath = $recordedPaths | Where-Object { $_.Name -eq $indexOrName } | Select-Object -First 1 -ExpandProperty Path
    }

    if ($selectedPath -and (Test-Path $selectedPath)) {
        Set-Location $selectedPath
        Write-Host "Navigated to $selectedPath." -ForegroundColor Green
    } else {
        Write-Host "The selected path does not exist or was not found. Use 'path-set' to select from available paths" -ForegroundColor Red
    }
}


<#
.SYNOPSIS
Removes a recorded path by its index or name. Alias: RemovePath, rmpath

.DESCRIPTION
The Remove-RecordedPath function removes a recorded path by its index or name. This is useful for managing the list of recorded paths. The recorded paths are retrieved from a file for persistence across sessions.

.PARAMETER indexOrName
The index or name of the recorded path to remove. If an index is provided, it removes the recorded path at that index. If a name is provided, it removes the recorded path with that name. This parameter is optional and defaults to the last recorded path.

.INPUTS
String, Int. You can pipe a string that contains the name or an integer for the index to Remove-RecordedPath.

.OUTPUTS
String. Outputs a message to the console indicating that the path has been removed.

.EXAMPLE
PS> RemovePath -indexOrName 2
Removes the recorded path at index 2 and outputs a message to the console.

.EXAMPLE
PS> rmpath -indexOrName "MyPath"
Removes the recorded path with the name "MyPath" and outputs a message to the console.
#>
function Remove-RecordedPath {
    param (
        [Parameter(Mandatory=$false, HelpMessage="The index or name of the recorded path to remove. If not provided, the user is prompted to select a path.")]
        [string]$indexOrName = $null
    )
    # Load recorded paths
    $recordedPaths = if (Test-Path $RecordedPathsFile) {
        Get-Content $RecordedPathsFile | ConvertFrom-Json
    } else {
        Write-Host "No recorded paths file found." -ForegroundColor Red
        return
    }

    # Check if the list is empty
    if (-not $recordedPaths -or $recordedPaths.Count -eq 0) {
        Write-Host "The recorded paths list is empty." -ForegroundColor Yellow
        return
    }

    if (-not $indexOrName) {
        # List available paths for selection
        Write-Host "Available paths:" -ForegroundColor Green
        foreach ($i in 0..($recordedPaths.Count - 1)) {
            Write-Host "$($i + 1): $(script:$recordedPaths[$i].Name) - $($recordedPaths[$i].Path)" -ForegroundColor Blue
        }
        $indexOrName = Read-Host "Please select a path to remove by Name or Index"
    }

    # Determine the path to remove
    $pathToRemove = $null
    if ($indexOrName -match '^\d+$') {
        # Convert to zero-based index
        $index = [int]$indexOrName - 1
        if ($index -lt $recordedPaths.Count) {
            $pathToRemove = $recordedPaths[$index]
        }
    } else {
        $pathToRemove = $recordedPaths | Where-Object { $_.Name -eq $indexOrName } | Select-Object -First 1
    }

    # Remove the selected path
    if ($pathToRemove) {
        $recordedPaths = $recordedPaths | Where-Object { $_.Path -ne $pathToRemove.Path }
        script:$recordedPaths | ConvertTo-Json | Set-Content $RecordedPathsFile -Force
        Write-Host "Removed path: $($pathToRemove.Name) : $($pathToRemove.Path)" -ForegroundColor Green
    } else {
        Write-Host "The specified path was not found." -ForegroundColor Red
    }
}



<#
.SYNOPSIS
Clears all the recorded paths. Alias: path-clear, clearpaths

.DESCRIPTION 
The Clear-RecordedPaths function clears all the recorded paths. This is useful for resetting the list of recorded paths for any purpose like starting a new session, cleaning up after a task, or preparing for a new task.

.PARAMETER None
This function does not take any parameters.

.INPUTS 
None. You cannot pipe inputs to Clear-RecordedPaths.

.OUTPUTS
None. This function does not output any data.

.EXAMPLE
PS> path-clear
Clears all the recorded paths.

#>
function Clear-RecordedPaths {
    # Explicitly create an empty array and convert it to JSON
    $emptyArray = @()
    $json = $emptyArray | ConvertTo-Json -Depth 5
    Set-Content $RecordedPathsFile -Value $json
    Write-Host "All recorded paths have been cleared." -ForegroundColor Green
}


<#
.SYNOPSIS
Helper function to Remove-RecordedPath. Removes the currently selected path.

.DESCRIPTION
The Remove-SelectedPath function removes the currently selected path. This is useful for managing the list of recorded paths, especially when the current path is no longer needed. The recorded paths are retrieved from a file for persistence across sessions.

.INPUTS
None. You do not need to provide any input to Remove-SelectedPath.

.OUTPUTS
String. Outputs a message to the console indicating that the selected path has been removed.

.EXAMPLE
PS> Remove-SelectedPath
Removes the currently selected path and outputs a message to the console.
#>
function Remove-SelectedPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $SelectedPath,
        [Parameter(Mandatory=$true)]
        [ref]$Paths
    )

    # Filter out the selected path
    $Paths.Value = $Paths.Value | Where-Object { $_.Path -ne $SelectedPath.Path }

    # Convert the updated paths list to JSON and save
    $jsonContent = $Paths.Value | ConvertTo-Json
    $jsonPath = "C:\Users\$env:USERNAME\Documents\PowerShell\RecordedPaths.json"
    $jsonContent | Set-Content -Path $jsonPath

    Write-Host "The selected path '$($SelectedPath.Name) : $($SelectedPath.Path)' has been removed."
}

# Main menu for path management
# Note: This function is a placeholder and should be replaced with actual functionality
function Show-PathMenu {
    do {
        Clear-Host
        Write-Host "Recorded Paths Menu" -ForegroundColor Cyan

        Write-Host "1. Record New Path"
        Write-Host "2. List Recorded Paths"
        Write-Host "3. Select Path"
        Write-Host "4. Remove Path"
        Write-Host "5. Clear All Paths"
        Write-Host "6. Advanced Options" -ForegroundColor Green
        Write-Host "X. Exit"

        $choice = Read-Host -Prompt "Enter your choice"

        switch ($choice) {
            "1" { New-RecordedPath }
            "2" { Get-RecordedPaths }
            "3" { Select-RecordedPath }
            "4" { Remove-RecordedPath }
            "5" { Clear-RecordedPaths }
            "6" { Show-AdvancedMenu } 
            "X" { break } 
            default { Write-Warning "Invalid choice. Please try again." } 
        }
    } while($true)
}


# Advanced menu for additional options 
# Example: Manage Paths JSON
# Note: This function is a placeholder and should be replaced with actual functionality
function Show-AdvancedMenu {
    do {
        # ... (rest of your advanced menu)

        Write-Host "1. Manage Paths JSON"
        Write-Host "2. ... (Additional Options)" 
        Write-Host "B. Back to Main Menu"

        $choice = Read-Host -Prompt "Enter your choice"

        switch ($choice) {
            "1" { Manage-PathsData } 
            "2" { Other-Advanced-Feature }
            "B" { break } 
            default { Write-Warning "Invalid choice. Please try again." } 
        }
    } while($true)
}

function Invoke-PathsDataManagement {
    do {
        # ...

        Write-Host "1. Edit a Path"
        Write-Host "2. View JSON Data"
        Write-Host "3. Export Paths"
        Write-Host "4. Change JSON File Location" 
        Write-Host "B. Back to Advanced Menu"

        $choice = Read-Host -Prompt "Enter your choice"

        switch ($choice) {
            "1" { Edit-RecordedPath }
            "2" { View-JSON }
            # ... and so on 
            "B" { break }  
            # ... default case for invalid choices 
        }
    } while ($true)
}


function Show-InteractivePathMenu($title, $menuItems) {
    Clear-Host
    Write-Host $title -ForegroundColor Cyan
    Write-Host "" # Add a blank line

    $selectedItem = 0 # Initially select the first item

    do {
        for ($i = 0; $i -lt $menuItems.Count; $i++) {
            if ($i -eq $selectedItem) {
                Write-Host " > " -NoNewline -ForegroundColor Yellow
            } else {
                Write-Host "   " -NoNewline  # Just spacing
            }
            Write-Host $menuItems[$i] 
        }

        $input = $Host.UI.RawUI.ReadKey('IncludeKeyDown') 

        switch ($input.VirtualKeyCode) {
            38 { # Up arrow
                if ($selectedItem -gt 0) { $selectedItem-- } 
            }
            40 { # Down arrow
                if ($selectedItem -lt $menuItems.Count - 1) { $selectedItem++ }
            }
            13 { # Enter key - confirms selection
                return $menuItems[$selectedItem]
            }
        }

    } while ($true) # Keep looping until the user presses Enter
}


Set-Alias -Name "selectpath" -Value Select-RecordedPath
Set-Alias -Name "path-set" -Value Select-RecordedPath

Set-Alias -Name "createpath" -Value New-RecordedPath
Set-Alias -Name "path-create" -Value New-RecordedPath

Set-Alias -Name "setlastpath" -Value Set-LastPath
Set-Alias -Name "path-reset" -Value Set-LastPath

Set-Alias -Name "removepath" -Value Remove-RecordedPath
Set-Alias -Name "path-remove" -Value Remove-RecordedPath

Set-Alias -Name "clearpaths" -Value Clear-RecordedPaths
Set-Alias -Name "path-clear" -Value Clear-RecordedPaths

Set-Alias -Name "listpaths" -Value Get-RecordedPaths
Set-Alias -Name "path-list" -Value Get-RecordedPaths
