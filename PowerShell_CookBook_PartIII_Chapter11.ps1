# CHAPTER 11 Code Reuse

#11.1 Write a script
Get-ChildItem $env:windir\system32\*.exe | Select-Object Name
#Get-Command | Select-Object Name

#11.2 Write a Function
## Convert Fahrenheit to Celsius
function ConvertFahrenheitToCelsius([double] $fahrenheit)
{
    $celsius = $fahrenheit - 32
    $celsius = $celsius / 1.8
    $celsius
}
$celsius = ConvertFahrenheitToCelsius $fahrenheit

#11.3 Find a Verb Appropriate for a Command Name
Get-Verb In* | Format-Table -AutoSize

#11.4 Write a Script Block

#11.5 Return Data from a Script, Function, or Script Block
function Get-Tomorrow
{
    function GetDate
    {
        Get-Date
    }
    $tomorrow = (GetDate).AddDays(1)
    $tomorrow
}

# Some .Net methods - such as the System.Collections.ArrayList class produce output, even though you may not expect them to. To provent these methods from sending data to the output pipeline, either captuer the data or cast it to [void]:
$collection = New-Object System.Collections.ArrayList
[void]$collection.add("Hello World")

#
function WritesObjects
{
    $arraylist = New-Object System.Collections.ArrayList
    [void]$arraylist.Add("Hello")
    [void]$arraylist.add("World!!!")
    
    $arraylist
}
function WritesArrayList
{
    $arraylist = New-Object System.Collections.ArrayList
    [void]$arraylist.add("Hello")
    [void]$arraylist.Add("World")
    
    ,$arraylist
}
$objOutput = WritesObjects

#throw "Collection was of a fixed size" error
#$objOutput.add("Python")

$al = WritesArrayList

$al.add("Python")

#11.6 Package Common Commands in a Module
## Convert Fahrenheit to Celcius
function Convert-FahrenheitToCelcius([double] $fahrenheit)
{
    $celsius = $fahrenheit -32
    $celsius = $celsius /1.8
    $celsius
}
## Convert Celcius to Fahrenheit
function Convert-CelciusToFahrenheit([double] $celcius)
{
    $fahrenheit = $celcius * 1.8
    $fahrenheit = $fahrenheit +32
    $fahrenheit   
}

#11.7 Write Commands That Maintain State

#11.8 Selectively Export Commands from a Module

#11.9 Diagnose and Interact with Internal Module State

#11.10 Handle Cleanup Tasks When a Module Is Removed

#11.11 Access Arguments of a Script, Function, or Script Block

#11.12 Add Validation to Parameters
function Demo-Param{
    param
    (
    [Parameter(
        Mandatory = $true,
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true)]
        [string[]] $Name
    )
}
#11.13 Accept Script Block Parameters with Local Variables
<#
.SYNOPSIS
Demonstrates the GetNewClosure() method on a scirpt block that pulls variable in from the user's session.

.EXAMPLE
PS>$name="Hello There"
PS>Invoke-ScriptBlockClosure {$name}
Hello There
Hello World
Hello There

#>
param(
    ##The Script block to invoke
    [scriptblock] $ScriptBlock
)
Set-StrictMode -Version 3
## Create a new script block that pulls variables
## from the user's scope
$closedScriptBlock = $ScriptBlock.GetNewClosure()

## Invoke the script block normally. The contents of 
## the $name variable will be from the user's session.
& $ScriptBlock

## Define a new variable
$name = "Hello World"

## Invoke the script block normaly. the contents of 
## the $name variable will be "Hello World", now from
## our scope.
& $ScriptBlock

## Invoke the "closed" script block. The contents of
## the $name variable will still be whatever was in the user's session
& $closedScriptBlock

#11.14 Dynamically Compose Command Parameters
$1114par = @{
        Name = "PowerShell";
        Whatif = $true
}
Stop-Process @1114par

#11.15 Provide -WhatIf, -Confirm, and Other Cmdlet Features
function Invoke-MyAdvancedFunction
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    if($PSCmdlet.ShouldProcess("test.txt","Remove Item"))
    {
        "Removing test.txt"
    }
    Write-Verbose "Verbose Message"
}
function Invoke-MyDangerousFunction
{
    [CmdletBinding()]
    param(
        [Switch] $Force
    )
    if($Force -or $PSCmdlet.ShouldContinue(
        "Do you with to invoke this dangerous operation?
        Changes can not be undone.","Invoke dangerous action?"))
    {
        "Invoking dangerous action"
    }

}
#11.16 Add Help to Scripts or Functions

#11.17 Add Custom Tags to a Function or Script Block

#11.18 Access Pipeline Input
function InputCounter
{
    $count = 0
    ##############################
    #.SYNOPSIS
    # Go through each element in the pipeline, and add up
    # how many elements there were.
    #.DESCRIPTION
    #Long description
    #
    #.EXAMPLE
    #An example
    #
    #.NOTES
    #General notes
    ##############################
    foreach($element in $input)
    {
        $count++
    }
    $count    
}
function ReverseInput
{
    $inputArray = @($input)
    $inputEnd = $inputArray.Count - 1
    $inputArray[$inputEnd..0]
}
Get-ChildItem C:\
Get-ChildItem C:\ | ReverseInput

$Array1 = 1,2,3,4,5
$array2 = $Array1[4..0]
$array2

#11.19 Write Pipeline-Oriented Scripts with Cmdlet Keywords

#11.20 Write a Pipeline-Oriented Function

#11.21 Organize Scripts for Improved Readability

#11.22 Invoke Dynamically Named Commands

#11.23 Program:Enhance or Extend an Existing Cmdlet
