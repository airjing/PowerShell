# Chapter7 Lists, Arrays, and Hashtables
# Create an Array or List of Items
$array = 1,2,"Hello World"
$array
foreach($a in $array)
{
    Write-Host $a  "`n`n"
}

$strArray = New-Object string[] 10
$strArray[5] = "Hello World"
#$strArray[5]
for($i=0;$i -lt $strArray.Length;$i++)
{
    Write-Host '$strArray'"[$i]" =  $strArray[$i] 
}

$list = New-Object Collections.Generic.List[int]
$list.add(10)
#$list.add("Hello World")
$list

$myArray = Get-Process
$myArray[$myArray.Length-10]

$myArray = New-Object System.Collections.ArrayList
[void]$myArray.Add("Hello")
[void]$myArray.AddRange(("World","How","Are","You"))
$myArray
$myArray.RemoveAt(1)
$myArray

$myArray = Get-Process Idle
$myArray.GetType() # System.Diagnostics.Process
$myArray = @(Get-Process Idle)
$myArray.GetType() # System.Object[]

#7.2 Create a jagged or Multidimensional Array
$jaggedArray = @(
    (1,2,3,4),
    (5,6,7,8)
)
$jaggedArray

$md = New-Object "int32[,]" 2,4
$md[0,1] = 2
$md[1,3] = 8
$md[0,1]
$md[1,3]

#7.3 Access Elements of an Array
$items = Get-Process OUTLOOK,powershell,MicrosoftEdge,MicrosoftEdgeCP
$items
$items | Format-Table
$items[2].ID

#7.4 Visit Each Element of an Array
$myArray = 1,2,3
$sum = 0
$myArray | ForEach-Object {$Sum += $_} 
$sum

