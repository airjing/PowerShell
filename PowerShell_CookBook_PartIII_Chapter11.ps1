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
