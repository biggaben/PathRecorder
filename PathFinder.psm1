# ---------------------------
# Paths Bookmarking Management
# ---------------------------

# Path of the JSON file to store recorded paths
# Get the directory path of the current script

# Construct the path to the JSON file
$recordedPathsFile = "C:\\Users\\David\\PowerShellProfile\\Modules\\PathRecorder\\recorded_paths.json" 

# --- CORE FUNCTIONS ---
function New-RecordedPath {
    [CmdletBinding()]
    param(
        [string]$name
    )
    
    $currentPath = Get-Location

    # Get name if not provided
    if (!$name) {
        $name = Read-Host "Enter a name for this path" 
    }

    # Load paths from file (if it exists)
    $recordedPaths = Get-RecordedPaths 

    $newPath = @{
        Name = $name
        Path = $currentPath.ProviderPath
        IsQuickPath = $false  # Initialize as not a quick path
    }

    # Update and save

    $recordedPaths = @(Get-RecordedPaths)  # Ensure $recordedPaths is an array initially
    $recordedPaths += ,$newPath  # Comma creates a single-element array 
    $recordedPaths | ConvertTo-Json | Out-File $recordedPathsFile
    Write-Host "Path recorded successfully!"
}

function Get-RecordedPaths {
    Write-Host $functionName
    if (Test-Path $recordedPathsFile) {
        (Get-Content $recordedPathsFile | ConvertFrom-Json)
    } else {
        Write-Host "No saved paths found."
        return @()
    }
}

function Get-PathSelection {
    Write-Host $functionName
    $recordedPaths = Get-RecordedPaths

    if ($recordedPaths.Count -eq 0) {
        Write-Warning "No recorded paths to display."
        return $null
    }

    Write-Host "Select Path:"
    for ($i = 0; $i -lt $recordedPaths.Count; $i++) {
        Write-Host "$($i + 1). $($recordedPaths[$i].Name) - $($recordedPaths[$i].Path)"
    }

    $selection = Read-Host -Prompt "Enter index or name of path"

    # Index/Name Validity
    if (($selection -notmatch '^\d+$' -and !$recordedPaths.Name.Contains($selection)) -or 
        ([int]$selection -lt 1 -or [int]$selection -gt $recordedPaths.Count)) {
        Write-Warning "Invalid selection. Please enter a valid index or name."
    } else {
        # Path Existence
        $selectedPath = Get-RecordedPaths | Where-Object { $_.Name -eq $selection }
        if (-not (Test-Path $selectedPath.Path)) {
            Write-Warning "The selected path does not exist. Please choose again."
        } else {
            Set-Location $selectedPath.Path 
        }
    }
}

function Select-RecordedPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]  
        [ValidateScript({($_ -is [int]) -or ($recordedPaths.Name -contains $_)})]
        [string]$indexOrName
    )
    Write-Host $functionName

    $recordedPaths = Get-RecordedPaths

    if (!$indexOrName) { 
        $selection = Get-PathSelection
        $selectedPath = $recordedPaths | Where-Object { $_.Name -eq $selection } 
    } elseif ($indexOrName -is [int]) {
        $selectedPath = $recordedPaths[$indexOrName - 1] # Adjust for zero-based indexing
    } else {
        $selectedPath = $recordedPaths | Where-Object { $_.Name -eq $indexOrName }
    }

    if ($selectedPath) {
        Write-Host "Selected Path: $($selectedPath.Name)" # Display for confirmation 
        Set-Location $selectedPath.Path # Return the selected path object 
    } else {
        Write-Error "Path not found."
    }
}

function Remove-RecordedPath{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]  
        [ValidateScript({($_ -is [int]) -or ($recordedPaths.Name -contains $_)})]
        [string]$indexOrName
    )
    Write-Host $functionName

    $recordedPaths = Get-RecordedPaths

    if (!$indexOrName) { 
        $selection = Get-PathSelection 
        $pathToRemove = $recordedPaths | Where-Object { $_.Name -eq $selection }
        $recordedPaths = $recordedPaths | Where-Object { $_.Name -ne $selection }
    } elseif ($indexOrName -is [int]) {
        $pathToRemove = $recordedPaths.RemoveAt($indexOrName)
    } else {
        $pathToRemove = $recordedPaths | Where-Object { $_.Name -eq $indexOrName }
        $recordedPaths = $recordedPaths | Where-Object { $_.Name -ne $indexOrName }
    }

    if ($pathToRemove) {
        $recordedPaths | ConvertTo-Json | Out-File $recordedPathsFile 
        Write-Host "Path removed!"
    } else {
        Write-Error "Path not found."
    }
}

function Clear-RecordedPaths {
    Write-Host $functionName
    Remove-Item $recordedPathsFile -ErrorAction SilentlyContinue
    Write-Host "All recorded paths cleared!"
}

function Set-QuickPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]  
        [ValidateScript({($_ -is [int]) -or ($recordedPaths.Name -contains $_)})]
        [string]$indexOrName
    )
    Write-Host $functionName

    $recordedPaths = Get-RecordedPaths 

    if (!$indexOrName) { 
        $selection = Get-PathSelection 
        $pathToModify = $recordedPaths | Where-Object { $_.Name -eq $selection }
    } elseif ($indexOrName -is [int]) {
        $pathToModify = $recordedPaths[$indexOrName]
    } else {
        $pathToModify = $recordedPaths | Where-Object { $_.Name -eq $indexOrName }
    }

    if ($pathToModify) {
        $pathToModify.IsQuickPath = $true
        $recordedPaths | ConvertTo-Json | Out-File $recordedPathsFile
        Write-Host "Path marked as quick path!"
    } else {
        Write-Error "Path not found."
    }
}

function Get-QuickPath {
    $QuickPath = Get-RecordedPaths | Where-Object {$_.IsQuickPath}
    Set-Location $QuickPath.Path
}

# --- MENU FUNCTIONS ---

function Show-MainMenu {
    Write-Host $functionName
    Write-Host "Recorded Paths Menu:"
    Write-Host "1. Record New Path"
    Write-Host "2. List Recorded Paths"
    Write-Host "3. Select Recorded Path"
    Write-Host "4. Manage Quick Paths"
    Write-Host "5. Remove Recorded Path"
    Write-Host "6. Clear All Paths"
    Write-Host "7. Exit"

    [int]$choice = Read-Host -Prompt "Enter your choice"

    return $choice
}

function Show-SelectPathMenu {
    Write-Host $functionName
    $recordedPaths = Get-RecordedPaths

    if ($recordedPaths.Count -eq 0) {
        Write-Warning "No recorded paths to display."
        return
    }

    Write-Host "Select Path:"
    for ($i = 0; $i -lt $recordedPaths.Count; $i++) {
        Write-Host "$($i + 1). $($recordedPaths[$i].Name) - $($recordedPaths[$i].Path)"
    }

    $selection = Read-Host -Prompt "Enter index or name of path"

    # Validate selection (you can customize this if needed)
    while (($selection -notmatch '^\d+$' -and !$recordedPaths.Name.Contains($selection)) -or 
    ([int]$selection -lt 1 -or [int]$selection -gt $recordedPaths.Count)) {
        Write-Warning "Invalid selection. Please try again."
        $selection = Read-Host -Prompt "Enter index or name of path"
    }

    return $selection 
}

function Show-QuickPathsMenu {
    Write-Host $functionName
    Write-Host "Quick Paths Menu:"
    Write-Host "1. List Quick Paths"
    Write-Host "2. Set Quick Path"
    Write-Host "3. Go to Quick Path"
    Write-Host "4. Back to Main Menu"

    [int]$choice = Read-Host -Prompt "Enter your choice"

    return $choice
}

# --- MAIN SCRIPT LOGIC ---

function Invoke-MainMenu {
    $choice = Show-MainMenu

    switch ($choice) {
        1 { New-RecordedPath }
        2 { Get-RecordedPaths | Format-Table -AutoSize Name, Path }
        3 { 
            $selectedPath = Select-RecordedPath  
            if ($selectedPath) {
                Write-Host "Selected Path (Name):" $selectedPath.Name
                Write-Host "Selected Path (Path):" $selectedPath.Path
                Set-Location $selectedPath.Path
            }
        }
        4 { 
            do {
                $quickPathChoice = Show-QuickPathsMenu
                switch ($quickPathChoice) {
                    1 { Get-QuickPath | Format-Table -AutoSize Name, Path }
                    2 { Set-QuickPath }
                    3 { Select-RecordedPath (Get-QuickPath) }
                }
            } until ($quickPathChoice -eq 4) # Back to main menu
        }
        5 { 
            $selection = Show-SelectPathMenu
            Remove-RecordedPath $selection 
        }
        6 { Clear-RecordedPaths }
        7 { Write-Host "Exiting..." }
        default { Write-Warning "Invalid choice. Please try again." }
    }
}

# --- ALIASES ---
Set-Alias -Name "mpath" -Value Invoke-MainMenu
Set-Alias -Name "cpath" -Value New-RecordedPath
Set-Alias -Name "lpath" -Value Get-RecordedPaths
Set-Alias -Name "spath" -Value Select-RecordedPath 
Set-Alias -Name "rmpath" -Value Remove-RecordedPath 
Set-Alias -Name "clrpath" -Value Clear-RecordedPaths 
Set-Alias -Name "sqpath" -Value Set-QuickPath
Set-Alias -Name "qpath" -Value Get-QuickPath