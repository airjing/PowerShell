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

#7.5 Sort an Array or List of Items
Get-ChildItem | Sort-Object -Descending Length
#Get-ChildItem $HOME -Recurse -Force | Where-Object $_.Length -gt 10MB |Sort-Object -Descending LastWriteTime
#Get-ChildItem D:\ -Recurse | Where-Object $_.Length -gt 1MB | Sort-Object -Descending LastAccessTime

$list = "Hello","World","And","PowerShell"
$list = $list | Sort-Object
$list
[Array]::Sort($list)
$list

#7.6 Determine Whether an Array Contains an Item
"Hello","World" -contains "Hello"
"Hello","World" -contains "PowerShell"
"Hello" -in "Hello","World","PowerShell"

#7.7 Combin two arrays
$firstArray = "Element 1","Element 2","Element 3","Element 4"
$secondArray = 1,2,3,4
$result = $firstArray + $secondArray
$result.GetType()

#7.8 Find Items in an Array that match a Value
$array = "Item1","Item2","Item3","Item4","Item12"
$array -eq "Item1"
$array -like "*em*"
$array -match "Item.."
array | Where-Object {$_.Length -gt 5}
Get-Process MicrosoftEdgeCP | Where-Object {$_.Id}
Get-Process MicrosoftEdgeCP | ForEach-Object{$_.Id}

#7.9 Compare Two Lists
$array1 = "array1.item1","array2.item2","array3.item3"
$array2 = "array2.item1","array2.item2","array2.item3"
Compare-Object $array1 $array2

#7.10 Remove Elements from an Array
$array710 = "Item1","Item2","Item3","item4","item5","item6"
$array -ne "Item1"

#7.11 Find Items in an Array Greater or Less Than a value
$array710 -ge "Item3"
$array710 -lt "Item3"
$array710 | Sort-Object

#7.12 Use the ArrayList Class for Advanced Array Tasks
$array712 = New-Object System.Collections.ArrayList
[void]$array712.Add("Hello")
[void]$array712.AddRange(("World!","PowerShell",".Net","C#"))
$array712

# Remove element from a particular position
$array712.RemoveAt(2)
$array712

#7.13 Create a Hashtable or Associative Array
$myHashTable = @{
    Key1 = "Value1"
    Key2 = "Value2"
    "Key 2" = 1,2,3
}
$myHashTable["Key3"] = 5

$myHashTable713 = @{}

$myHashTable713["Name"] = "EDFHILB-PC"
$myHashTable713.Model = "Z440 WorkStation"

#7.14 Sort a hashtable by key or value
Write-Host "Demo 7.14 Sort hashtable"
foreach($item in $myHashTable713.GetEnumerator() | Sort-Object Name)
{
    $item.value
}
$myHashTable714 = @{}
$myHashTable714["Hello"] = 3
$myHashTable714["Ali"] = 2
$myHashTable714["Alien"] = 4
$myHashTable714["Duck"] = 1
$myHashTable714["Hectic"] = 11
$myHashTable714.GetEnumerator() | Sort-Object Name
$myHashTable714.GetEnumerator() | Sort-Object Value