# CHAPTER 13
# User Interaction
#13.1 Read a Line of User Input
#$dir = Read-Host "Enter a directory name to get content"
#Get-childitem $dir

#13.2 Read a Key of User Input
# $true parameter to tell the method to not dispaly the character on the screen, and only to return it to us.
#$key = [console]::ReadKey($true)
$key
#$key1 = $host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
$key1

#13.3 Program : Display a Menu to the User
$caption = "Please specify a task"
$message = "Specify a task to run"
$option = "&Clean Temporary Files", "&Defragment Hard Drive"
$helptext = "Clean the Tehmporary files from the computer","Run the Defragment task"
$default = 1
Read-Host $caption $message $option $helptext $default
param(
    $caption = $null,
    $message = $null,
    [Parameter(Mandatory = $true)]
        $option,
    $helptext = $null,
    $default = 0
)
Set-StrictMode -Version 3
$choices = New-Object Collections.ObjectModel.Collections[Management.Automation.Host.ChoiceDescription]
for($counter = 0;$counter -lt $option.Length;$counter++)
{
    $choice = New-Object Management.Automation.Host.ChoiceDescription $option[$counter]
    if($helptext -and $helptext[$counter])
    {
        $choice.HelpMessage = $helptext[$counter]
    }
    $choices.add($choice)
}

#13.4 Display Messages and Output to the User
function  Get-Information
{
    "Hello World"
    Write-Output (1+1)
}
$result = Get-Information
#$result
$result[1],$result[0]

function Get-DirectorySize
{
    $size = (Get-ChildItem | Measure-Object -Sum Length).Sum
    Write-Debug "Current Directory: $(Get-Location)"
    Write-Verbose "Getting size"
    write-verbose ("Directory size:{0:N0} bytes" -f $size)
    Write-Verbose "Got size: $size"
}
$DebugPreference = "continue"
Get-DirectorySize