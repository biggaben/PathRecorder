# PathRecorder
 
# Introduction to PathRecorder

PathRecorder is a handy PowerShell module designed to streamline your workflow by making it easy to manage frequently used file system paths.  It aims to save you time and effort as you navigate through your projects and tasks.

## Core Functions

* **Record Paths:** Save any path in your system along with an optional name for quick reference.
* **List Paths:** View a list of all your recorded paths for easy recall.
* **Select Paths:** Quickly switch to a saved path, either by choosing its number or its name.
* **Remove Paths:** Manage your list by deleting individual recorded paths.
* **Clear Paths:** Start with a clean slate by removing all recorded paths.

## Purpose

Pathfinder is especially useful in the following situations:

* **Frequent Path Changes:** If you find yourself switching between directories often during your work, PathRecorder will make these changes much more efficient.
* **Complex Projects:** Navigate large, intricate project structures with ease by recording key locations.
* **Repeatable Workflows:** Optimize tasks that involve repeatedly visiting specific directories across different projects.

## How to Use

1. **Import the Module:** In your PowerShell session, import the Pathfinder module using `Import-Module PathRecorder`.
2. **Explore the Menu:** To access PathRecorder's functions, execute the `Show-PathMenu` function.  This will display an interactive menu to guide your actions.

### Example:

1. Import PathRecorder: `Import-Module PathRecorder`
2. Start the menu: `Show-PathMenu`
3. Record a new path (the script will prompt you for an optional name)
4. List your saved paths
5. Select a path by its number to switch to that directory
