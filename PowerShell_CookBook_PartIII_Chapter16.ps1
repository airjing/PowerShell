#CHAPTER16
#Environmental Awareness
#16.1 View and Modify Environment Variables
$env:USERNAME
$?
Get-ChildItem env:
#16.2 Modify the User or System Path
$Scope = "User"
$pathElements = @([System.Environment]::GetEnvironmentVariable("Path",$Scope) -split ";")
$pathElements += "D:\Databank\Program Files"
$newPath = $pathElements -join ";"
[environment]::SetEnvironmentVariable("Path",$newPath,$Scope)

#16.3 Access Information About Your Command's Invocation
"Script's Path: $PSCommandPath"
"Script's location: $PSScriptRoot"
"You invoked this script by typing: " + $MyInvocation.Line

#16.4 Program: Investigate the InvocationInfo Variable

#16.5 Find Your Script's Name
# $PSCommandPath only available in PS 3.0
$scriptname = Split-Path -Leaf $PSCommandPath

#in PS2.0 try this one:
$scriptnamev2 = $MyInvocation.Path
$scriptnamev2

#16.6 Find Your Script's Location

#16.7 Find the Location of Common System Paths
[System.Environment]::GetFolderPath("System")
[enum]::GetValues([environment+SpecialFolder])

#16.8 Get the Current Location
Get-Location
$PWD

#16.9 Safely Build File Paths Out of Their Components

#16.10 Interact with PowerShell's Global Environment

#16.11 Determine PowerShell Version Information
$PSVersionTable.PSCompatibleVersions

#16.12 Test For Administrative Privileges
