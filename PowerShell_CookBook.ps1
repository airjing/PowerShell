# pipe example
Get-Process | where-object {$_.Name -like "M*"} | sort-object -desc WS | format-Table CPU
#The output, seems CPU wrong with Universal APP.
#Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName                                     
#-------  ------    -----      -----     ------     --  -- -----------                                     
#    229      27     3396       4200              3800   0 mDNSResponder                                   
#      0       0     5012     938356              2696   0 Memory Compression                              
#   1368      97    58952      12180      14.58  15704   1 Microsoft.VsHub.Server.HttpHost                 
#   5258     845 15696668     277008  10,371.25  10304   1 MicrosoftEdge
# return the process which name started by M and ending by CP.
Get-Process [M]*[CP] | Stop-Process -WhatIf
Get-Command *Azure* 
Get-History | ForEach-Object {$_.CommandLine} > "D:\CommandLine.txt"
Get-Content D:\CommandLine.txt
$webclient = New-Object System.Net.WebClient
$content = $webclient.DownloadString("https://blogs.msdn.com/PowerShell/rss.aspx")
$content.Substring(0,1000) >D:\xmlcontent.xml
$xmlcontent = [xml] $content
$xmlcontent.Save("D:\FullXMLContent.xml")
$xmlcontent.rss
$xmlcontent.rss.channel.Item | Select-Object title
Get-WmiObject WIN32_BIOS
#return installed software which name like Atom
Set-Location HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall
Get-ChildItem -Recurse | Where-Object {$_.Name -like "*Atom*"} | Select-Object $_.Property  
Set-Location Cert:\LocalMachine\ROOT
Get-ChildItem | Where-Object {$_.Subject -like "*MR*"} 

# list all possible colors
$colors = [System.Enum]::getvalues([System.ConsoleColor])
foreach ($color in $colors) {Write-Host -ForegroundColor $color "This is the color '$color'"}

#The Windows PowerShell Interactive Shell
# call external commandline:
# & 'notepad.exe' 'D:\FullXMLContent.xml'
attrib -R D:\FullXMLContent.xml
attrib D:\FullXMLContent.xml
Get-Acl D:\FullXMLContent.xml | Format-List
# --% verbatim syntax:
cmd.exe /c echo 'test'
# output:
#test

cmd.exe --% /c echo 'test'
# output:
#'test'

# Special character Meaning
# " The beginning (or end) of quoted text
# # The beginning of a comment
# $ The beginning of a variable
# & Reserved for future use
# ( ) Parentheses used for subexpressions
# ; Statement separator
# { } Script block
# | Pipeline separator
# ` Escape character
$commands = 'Get-Process'
# convert string type commands to Byte Array variable $bytes
$bytes = [System.Text.Encoding]::Unicode.GetBytes($commands)
write-host $bytes
$encodedstring = [Convert]::ToBase64String($bytes)
write-host $encodedstring
$inputbytes = 'RwBlAHQALQBQAHIAbwBjAGUAcwBzAA=='
$encodedbytes = [Convert]::FromBase64String($inputbytes)

foreach ($b in $encodedbytes) {
    write-host $b
}
$decodedstring = [System.Text.Encoding]::Unicode.GetString($encodedbytes)
write-host $decodedstring

# demos of Job releated command lets
$job = Start-Job -ScriptBlock {Get-EventLog -LogName System -Newest 100}
$job | Format-List -Property *
while ($job.JobStateInfo.State -eq 'Running') {
    $JobResult = Receive-Job -Job $job
    $JobResult
}
# $? return True or False of latest run.
# $LastExitCode return exit code.
$error[0] | Format-List -force
Get-History

# Store the Output of a command to a File
# Redirection Operators: > or >>
# Out-File cmdlet
$oFile='.\out.txt'
if (Test-Path $oFile)
{
    Remove-Item $oFile
    #Write-Host only redirect the output to console, so use Write-Output instead in order to save to a file.
    Write-Output 'Listing files in Folder C:\Windows\System32 by ' | Out-File $oFile -Encoding utf8
    Get-ChildItem C:\windows\system32 | Out-File -Append -Width 100 -Encoding utf8 .\out.txt
}

#PowerShell_CookBook_PartII_Chapter2 - Pipelines
#2-1. A PowerShell pipeline
Get-Process | Where-Object WorkingSet -gt 30Mb | Sort-Object -Descending Name
Get-Process | Where-Object{ $_.Handles -gt 2000} | Sort-Object -Descending Handles
# List all unresponding process
Get-Process | Where-Object {-not $_.Responding}

#2.2 Group and Pivot Data by Name
$h = Get-ChildItem | Group-Object -AsHashTable
$h
$p = Get-Process | Group-Object -AsHashTable -AsString Id
$p[31896]

#2.3 Simplify Most Where-Object Filters
Get-Process | Where-Object Handles -gt 20000

#2.4 Interactively Filter Lists of Objects
$script = Get-History | ForEach-Object CommandLine | Out-GridView -PassThru
$script | Set-Content C:\Windows\temp\script.ps1
Get-Content C:\Windows\temp\script.ps1

#2.5 Work with each item in a list or Command output
1..10 | ForEach-Object {$_ *2}
$array = 1..100
$sum = 0
$array | ForEach-Object {$sum += $_}
$sum

#2.7 Simplify most foreach-object pipelines
Get-Process | ForEach-Object {$_.Name}
Get-Process | % Name | % ToUpper

$edgeps = Get-Process | Where-Object {$_.Name -contains 'SVCHOST'}
$edgeps.Id


$ps = Get-Process Notepad | foreach-object {$_.kill()}

#2.8 Intercept Stages of the Pipeline

#2.9 Automatically Capture Pipeline Output

#2.10 Capture and Redirect Binary Process Output

#PowerShell_CookBook_PartII_Chapter2 - Variables and Objects
#3.1 Display the Properties of an item as a list
$currentError = $error[0]
#$currentError | Format-List -Force
Get-Process powershell | Format-List * -Force
#3.2 Display the Properties of an Item as a Table
# use * to dispaly all properties
# Format-Table *
# Get-Process | format-table *
# use -Autosize parameter to show the most readable way.
# Without -Autosize, Format-Table cmdlet can display items ASAP.
# With -Autosize, the cmdlet displays results only after it receives all the input.
# with a hashtable, can define custom table columns.
# three keys: The column;s label; a formatting expression; and alignment.
# The label must be string; the expression must be a script block, and the alignment be "Left","Center","Right"
# 

Get-Process | Format-Table Name,WS -AutoSize
$fields = "Name",@{label="WorkingSet (MB)"; Expression= {$_.WS /1Mb}; Align="Right"},@{label="Total Running Time"; Expression={(Get-Date) - $_.StartTime};alignment="Right"}
Get-Process | Format-Table $fields -AutoSize
#3.3 Store information in variables
$result = 2+2
$result
$pss = Get-Process
$pss.Count
$pss | Where-Object {$_.id -eq 0}
$ipinfo = ipconfig /all
$ipinfo | Select-String "Physical Address. . . . . . . . . :" -list | Select -First 3
#3.4 Access environment variables
#Get-ChildItem env:
$username = Get-ChildItem env:username
write-host $username.Value

#3.5 Program: Retain Changes to Environment Variables Set by a Batch File

#3.8 Work with .Net Objects
# Static methods
[System.Diagnostics.Process]::GetCurrentProcess().StartTime

# call Instance methods
& notepad.exe
$notepad = Get-Process notepad
$notepad.WaitForExit()

# Investigating PowerShell's method resolution
Trace-Command MemberResolution -PSHost {[System.Diagnostics.Process]::GetCurrentProcess()}

# Static properties
[System.DateTime]::Now

# Instance properties
$today = Get-Date
$today.DayOfWeek

#3.9 Create an Instance of a .Net Object
$generator = New-Object System.Random
$generator.NextDouble()
Add-Type -AssemblyName System.Windows.Forms

$startinfo = New-Object Diagnostics.ProcessStartInfo -Property @{'Filename'='Notepad.exe';'WorkingDirectory'='Env:\SystemRoot';'verb'='RunAs'}
[Diagnostics.Process]::Start($startinfo)
#$ms = New-Object System.IO.MemoryStream @(,$bytes)

#3.13 Learn About Types and Objects
Get-ChildItem | Get-Member

# ChAPTER 4 Looping and Flow Control
$temperature = 90
if($temperature -lt 0)
{
    "Balmy Canadian Summer"
}
elseif($temperature -le 32)
{
    "Freezing"
}
elseif ($temperature -le 50) 
{
    "Cold"    
}
elseif ($temperature -le 70) 
{
    "Warm"
}
else 
{
    "Hot"
}
$result = if(Get-Process powershell) {"running"} else {"Not running"}
$result

$temperature = 20
switch($temperature)
{
    {$_ -lt 32} {"Below Freezing";break}
    32 {"Exactly Freezing";break}
    {$_ -le 50} {"Cold";break}
    {$_ -le 70} {"Warm";break}
    default {"Hot"}
}
$input = Read-Host "Input"
if($input -contains "Q"){ Write-Host $input}

$LoopDelayMilliseconds = 650
while($true)
{
    $startTime = Get-Date
    & ping www.google.com 
    $endTime = Get-Date
    $loopLength = ($endTime-$startTime).TotalMilliseconds
    $timeRemaining = $LoopDelayMilliseconds - $loopLength
    if($timeRemaining -gt 0)
    {
        Start-Sleep -Milliseconds $timeRemaining
    }
}
#Chapter 5 Strings and Unstructured Text
#5.1 Creating a string
$myString = "Hello World!"
$myString
#5.2 A multiline string defiend by @""@
$mlString = @"
This is the first line.
This is the second line.
This is the third line.
This is the last line.
"@
Write-Host $mlString

#5.3 Place Special Characters in a String
# 'literal string (nonexpanding)', in a literal string, all the text between the single quotes becomes part of your string.
# "expanding strings", in an expanding string, PowerShell expands variable names with their values.
# ` for escape sequences, not a backslash character \
$extString = "$ENV:USERNAME"
$literalString = '$ENV:USERNAME'
$extString
$literalString

#5.4 Insert Dynamic Information in a String
$header = "Report for Today and Yesterday"
$str2 = 'Report for Today`n'
$report = "$header`n$('-' * $header.Length)"
$report

#5.5 Prevent a String from Including Dynamic Information
$mystring1 = 'Useful PowerShell characters include: $, `, " and { }'
$mystring1

#5.6 Place Formatted Information in a String
# {index,alignment:format}
$d = 12.345678
$i = 123446
$fs = "9876543210`n"
$fs += "xxxxxxxxxx`n"
$fs += "{0, -10:G}" -f $d + "`n"# format as general.
$fs += "{0, 10}" -f $d + "`n" # format as default, equals to general. 
$fs += "{0, -10:F4}" -f $d + "`n" # Fixed point, 4 dec places.
$fs += "{0, 10:F4}" -f $d + "`n" # Fixed point, 4 dec places.
$fs += "{0, -10:C}" -f $d + "`n" # left alighment, currency
$fs += "{0, -10:E3}" -f $d + "`n" # Sci. 3 dec places.
$fs += "{0, 10:x}" -f $i + "`n" # hexadecimal 
$fs
$formattedString = "{0, -10:D3} {1,4:C5}`n"
$formattedString -f 100,2.5567

#5.7 Searching a String for Text or a Pattern
"Hello World" -like "*ello W*" # returns True
"Hello World" -match '.*l[l-z]o W.*$' # returns True
"Hello World".Contains("World")
"Hello World".IndexOf("W")
# To work with the text-based representation of a PowerShell command, you can explicitly send it through the Out-String cmdlet.
$helpContent = Get-Help Get-ChildItem | Out-String -Stream
$helpContent -match "location"

#5.8 Replace Text in a String
"Hello World".Replace("World","PowerShell")
"Hello World".Replace('(.*) (.*)','$2 $1')
"Hello World" -replace '(.*) (.*)','$2 $1'
"Power[Shell]" -replace "[Shell]","ful" # returns Powfulr[fulfulfulfulful]
"Power[Shell]" -replace "\[Shell\]","ful"
"Power[Shell]" -replace ([Regex]::Escape("[Shell]")),"ful"
[Regex]::Replace("hello world",'\b(\w)', {$args[0].Value.ToUpper()}) # returns Hello World

#5.9 Split a String on Text or a Pattern
"a-b-c-d-e-f" -split "-"
"a-b-c-d-e-f" -split "-c-"
"a-b-c-d-e-f" -split "b|[d-e]"
-split "Hello World `t How `n are you?"

#5.10 Combine Strings into a Larger String
-join ("A","B","C")

$out = ""
foreach($s in $helpContent)
{
    $out += $s + "`n`n`n`n`n"
}
$out
#5.11 Convert a String to Uppercase or Lowercase
"Hello World".ToLower()
$helpContent.ToUpper()
$text1 = "Hello"
$text2 = "HELLO"
$text1 -eq $text2

#5.12 Trim a String
#Trim() method cleans all whitespace from the beginning and end of a string.
#TrimStart()
#TrimEnd()
$text = " `t Test String `t `t"
"|" + $text.Trim()+"|"

#5.13 Format a Date for Output
Get-Date -Format "yyyy-mm-dd - hh:mm:ss"
("{0:yyyy-mm-dd -*- hh:mm:ss}" -f (Get-Date)).ToString()

#5.14 Program:Convert Text Streams to Objects


#5.15 Generate Large Reports and Text Streams
# Best approach to generating a large amount of data is to take advantage of streaming behavior.
#Get-ChildItem C:\*.dll -Recurse | Out-File .\AllDllFiles.txt

# don't collect the output at each stage:
#$files = Get-ChildItem C:\*.txt -Recurse
#$files | Out-File C:\temp\alltxtfiles.txt
# If streaming is not an option, use the StringBuilder class:
$output = New-Object System.Text.StringBuilder
Get-ChildItem C:\Windows\System\*.dll -Recurse | ForEach-Object {[void] $output.AppendLine($_.FullName)}
$output.ToString()

# Creating large text reports
# An example of performance difference:
Measure-Command {
    $output = New-Object Text.StringBuilder
    1..10000 | ForEach-Object {$output.Append("Hello World!")}
}
Measure-Command{
    $output = ""
    1..10000 | ForEach-Object { $output += "Hello World!"}
}

#5.16 Generate Source Code and Other Repetitive Text

# Calculations and Math
#6.1 Perform Simple Arithmetic
# + Addition
# - Subtraction
# * Multiplication
# / Division
# % Modulus
# +=, -=, *=, /=, and %= Assignment variations of the previously listed operators
$result = 0
$result = 3/2
$result
$result = [int] (3/2)
$result
$result = 3/2
[Math]::Truncate($result)

#6.2 Perform Complex Arithmetic
[System.Math]::Abs(-10.6)
[System.Math]::Pow(123,6)
[System.Math]::Sqrt(123)
[System.Math]::Sin([System.Math]::PI /2)
[System.Math]::ASin(1)
function Get-Root($number,$root)
{
    [Math]::Pow($number,1/$root)
}
Get-Root 12345 123

#6.3 Measure Statistical Properties of a list
1..10 | Measure-Object -Average -Sum -Maximum -Minimum
Get-ChildItem | Measure-Object -Property Length -Maximum -Minimum -Sum -Average
Get-ChildItem > output.txt
Get-Content ./output.txt | Measure-Object -Character -Word -Line

$mt = Get-ChildItem | ForEach-Object {$_.LastWriteTime}
$results = $mt | Measure-Object Ticks -Average
$ag = $results.Average
New-Object Datetime $results.Average

#6.4 Work with Numbers as Binary
$hexNumber = 0x10 # hexadecimal by 0x
$hexNumber # output as decimal
[System.Convert]::ToString(1234,2)
[System.Convert]::ToInt32("10010001001",2)
$archive = [System.IO.FileAttributes] "Archive"
attrib +a .\output.txt
Get-ChildItem | Where-Object {$_.Attributes -band $archive} | Select-Object FullName
attrib -a .\output.txt
Get-ChildItem | Where-Object {$_.Attributes -band $archive} | Select-Object FullName

# Possible attributes of a file
#[Enum]::GetNames([System.IO.FileAttributes])
$attributes = [Enum]::GetValues([System.IO.FileAttributes])
$attributes | Select-Object `
@{"Name"="Property";"Expression"={$_}},
@{"Name"="Integer";"Expression"={[int] $_}},
@{"Name"="Hexadecimal";"Expression"={[Convert]::ToString([int] $_, 16) } },
@{"Name"="Binary";"Expression"={[Convert]::ToString([int] $_, 2)}} |
Format-Table -AutoSize

$colors = [Enum]::GetValues([System.ConsoleColor])
$colors | Select-Object `
@{"Name"="Color";"Expression"={$_}},
@{"Name"="Integer";"Expression"={[int] $_}},
@{"Name"="Hexadecimal";"Expression"={[Convert]::ToString([int]$_,16)}},
@{"Name"="Binary";"Expression"={[Convert]::ToString([int] $_, 2)}} |
Format-Table -AutoSize

#6.5 Simplify Math with Administrative Constants
10.18mb / 215kb

#6.6 Convert Numbers Between Bases
$errorCode = 0xFE4A
$errorCode
[System.Convert]::ToInt32("100000000000000000",2)
[System.Convert]::ToInt32("1234",8) # convert an octal number into its decimal representation, supply a base of 8.
[System.Convert]::ToString("1234",16)
"{0:x4}" -f 1234
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

#Utility Tasks
#8.1 Get the System Date and Time
$date = Get-Date
$date.AddDays(1)

#8.2 Measure the Duration of a Command
Measure-Command {Start-Sleep -Milliseconds 330}

#8.3 Read and Write from the Windows Clipboard

#8.4 Generate a Random Number or Object
$suits = "Hearts","Clubs","Spades","Diamonds"
$faces = (2..10) + "A","J","Q","K"
$cards = foreach($suit in $suits)
{
    foreach($face in $faces)
    {
        "$face of $suit"
    }
}
$cards.GetType | Get-Random

1..100 | ForEach-Object {(New-Object System.Random).Next(1,100000)} | Format-Table -AutoSize

#8.5 Program : Search the Windows Start Menu
$startMenuPath = [System.Environment]::GetFolderPath("StartMenu")
$shell = New-Object -ComObject WScript.Shell
$allStartMenu = $shell.SpecialFolders.Item("AllUsersStartMenu")
#$escapedMatch = [Regex]::Escape("$pattern")



#8.6 Program : Show Colorized Script Content
# Common Tasks | Simple File
#9.1 Get the content of the file.
measure-command {
    Write-Host "Get-content without -ReadCount"
    $content = Get-Content .\out.txt}
measure-command {
    Write-Host "Get-Content with -ReadCount to get best performance"
    $content = Get-Content .\out.txt -ReadCount 10000}
$content1 = ${.\out.txt}
measure-command {
    Write-Host "also better performace by .Net System.IO.File class"
    $contentLines = [System.IO.File]::ReadAllLines(".\out.txt")}

#$content

#9.2 Search a File for Text or a Pattern
# to search a file for an exact(but case-insensitive) match, use the -Simple
Select-String -SimpleMatch .dll .\out.txt
# show LineNumber and Line by Select-Object
$matches = Select-String ".dll" .\out.txt
$matches | Select-Object LineNumber,Line

Get-ChildItem *.ps1 -Recurse | Select-String pattern

#9.3 Parse and Manage Text-Based logfiles

#9.4 Parse and Manage Binary Files

#9.5 Create a Temporary File
$tmpfile = [System.IO.Path]::GetTempFileName()
$content > $tmpfile
Get-ChildItem $tmpfile
Remove-Item -Force $tmpfile

#9.6 Search and Replace Text in a File
$match = ".dll"
$replacement = "...Dymanic Line Library"
$content = $content -creplace $match, $replacement
$content >> $tmpfile
Get-content $tmpfile -ReadCount 100000

#9.7 Get the Encoding of a File

#9.8 Program: View the Hexadecimal Representation of Content

# CHAPTER 10 Structured Files
#10.1 Access information in an XML File
$filename = "$PWD\powershell_blog.XML"
if(!(Test-Path $filename) -or (Get-Item $filename).Length -eq 0)
{
    Invoke-WebRequest blogs.msdn.com/b/powershell/rss.aspx -OutFile $filename
}
[System.IO.Path]::GetFullPath($filename)

# Accessing properties of an XML document
$xml = [XML](Get-Content $filename)
$xml
#output by above line:
#   xml                            rss
#   ---                            ---
#   version="1.0" encoding="UTF-8" rss
$xml.xml
# output
#   version="1.0" encoding="UTF-8"
$xml.rss
# output by above line:
#   version : 2.0
#   content : http://purl.org/rss/1.0/modules/content/
#   wfw     : http://wellformedweb.org/CommentAPI/
#   dc      : http://purl.org/dc/elements/1.1/
#   atom    : http://www.w3.org/2005/Atom
#   sy      : http://purl.org/rss/1.0/modules/syndication/
#   slash   : http://purl.org/rss/1.0/modules/slash/
#   channel : channel
$xmlContent = $xml.rss.content
$xmlContentType = $xmlContent.GetType()
$xmlChannel = $xml.rss.channel
($xmlChannel.Item).Count
$item0 = ($xmlChannel.Item)[0]
$item0
$item1 = ($xml.rss.channel.item)[1]
$item1
$item2 = $xml.rss.channel.Item[2]
$item2.title
$item2.pubDate
$comment = Invoke-WebRequest $item2.commentRss
[xml]$commentItems = $comment.rss.channel

#10.2 Perform an XPath Query Against XML
$query = "/rss/channel/item[string-length(title) < 100]/title"
$query1 = "/rss/channel/item/title/link"
$a = Select-Xml -XPath $query1 -Path $filename | Select-Object -ExpandProperty Node
$xml = [xml](Get-Content $filename)
$xml | Select-Xml $query1

#10.3 Convert Objects to XML
$psXMLFile = "$PWD\psmetadata.xml"
if(!(Test-Path $psXMLFile))
{
    $ps = Get-Process | ConvertTo-Xml
    $ps.Save($psXMLFile)
}
$psXML = [xml](Get-Content $psXMLFile) 
$psXML | Select-Xml '//Property[@Name = "Name"]'

#10.4 Modify Data in an XML File

#10.5 Easily Import and Export Your Structured Data
$favorites = @{}
$favorites["VSPP"] = "D:\Databank\work\VSPP"
$favorites["OpenStack"] = "D:\Databank\Work\OpenStack"
$clixml = "$PWD\favorites.clixml"
$favorites | Export-Clixml $clixml

#10.6 Store the Output of a Command in a CSV or Delimited File
Get-Process | Export-Csv "$PWD\ps.csv"

#10.7 Import CSV and Delimited Data from a File
$header = "Date","Time","PID","TID","Component","Text"
$log = Import-Csv $env:windir\windowsupdate.log -Delimiter "`t" -Header $header
$log | Group-Object Component

#10.8 Manage JSON Data Streams
$object = [PSCustomObject] @{
    Name="Lee";
    Phone="123456"
}
$json = ConvertTo-Json $object
$json
$hstable = ConvertFrom-Json $json
$hstable

$edge = Get-Process MicrosoftEdge
$edge | ConvertTo-Json -Depth 2

$xmlUnattend = [xml] @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <WindowsDeploymentServices>
                <Login>
                    <Credentials>
                        <Domain>RNEA</Domain>
                        <Password>Esoteric$</Password>
                        <Username>tv2bot</Username>
                    </Credentials>
                </Login>
            </WindowsDeploymentServices>
            <EnableFirewall>false</EnableFirewall>
            <EnableNetwork>true</EnableNetwork>
            <Restart>Restart</Restart>
        </component>
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SetupUILanguage>
                <UILanguage>en-US</UILanguage>
            </SetupUILanguage>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-IE-ESC" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <IEHardenAdmin>false</IEHardenAdmin>
            <IEHardenUser>false</IEHardenUser>
        </component>
        <component name="Microsoft-Windows-ServerManager-SvrMgrNc" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <DoNotOpenServerManagerAtLogon>true</DoNotOpenServerManagerAtLogon>
        </component>
        <component name="Microsoft-Windows-UnattendedJoin" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <Identification>
                <Credentials>
                    <Domain>%USERDOMAIN%</Domain>
                    <Password>%USERPASSWORD%</Password>
                    <Username>%USERNAME%</Username>
                </Credentials>
                <JoinDomain>%MACHINEDOMAIN%</JoinDomain>
            </Identification>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <AutoLogon>
                <Password>
                    <Value>TQAxAGMAcgBvACQAbwBmAHQAUABhAHMAcwB3AG8AcgBkAA==</Value>
                    <PlainText>false</PlainText>
                </Password>
                <LogonCount>3</LogonCount>
                <Username>administrator</Username>
                <Enabled>true</Enabled>
            </AutoLogon>
            <ComputerName>%Machine%</ComputerName>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
            </OOBE>
            <TimeZone>China Standard Time</TimeZone>
            <RegisteredOwner>Mediaroom Beijing LAB</RegisteredOwner>
            <RegisteredOrganization>Ericsson</RegisteredOrganization>
            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add">
                    <CommandLine>cmd /c call C:\TV2OPS\Script\StartupStage0.bat</CommandLine>
                    <Order>1</Order>
                    <Description>Setup IP</Description>
                </SynchronousCommand>
            </FirstLogonCommands>
            <Display>
                <ColorDepth>32</ColorDepth>
                <HorizontalResolution>1024</HorizontalResolution>
                <VerticalResolution>768</VerticalResolution>
            </Display>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>0409:00000409</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UILanguageFallback>en-US</UILanguageFallback>
            <UserLocale>en-US</UserLocale>
        </component>
    </settings>
    <cpi:offlineImage cpi:source="wim:d:/hpse316.wim#Windows Server 2008 ENT x64 SP2 for HP SE316(V1.0.0)" xmlns:cpi="urn:schemas-microsoft-com:cpi" />
</unattend>
"@

$UnattendedJoin = $xmlUnattend.unattend.settings.component | Where-Object {$_.Name -eq "Microsoft-Windows-UnattendedJoin"}
$UnattendedJoinUserDomain = $UnattendedJoin.Identification.Credentials.Domain
$UnattendedJoinPassword = $UnattendedJoin.Identification.Credentials.Password
$UnattendedJoinUsername = $UnattendedJoin.Identification.Credentials.Username
$UnattendedJoinDomain = $UnattendedJoin.Identification.JoinDomain

$UnattendedJoin.Identification.Credentials.Domain = "RNEA"
$UnattendedJoin.Identification.Credentials.Password = "Esoteric$$"
$UnattendedJoin.Identification.Credentials.Username = "LabAgent"
$UnattendedJoin.Identification.JoinDomain = "RNEA.IPTV.MR.ERICSSON.SE"
$xmlUnattend.Save("D:\1.xml")

$oobe = $xmlUnattend.unattend.settings | Where-Object ($_.pass -eq "oobeSystem")
$str = ''
$oobe.component.Microsoft&#8211Windows&#8211Shell&#8211Setup'

Select-Xml '//unattend.settings[@pass='oobeSystem']' $xmlUnattend

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
#12.1 Download a File from an FTP or internet Site
$src = "http://www.microsoft.com"
$desc = "C:\windows\temp\src.txt"
Invoke-WebRequest $src -OutFile $desc
#notepad.exe $desc

#12.2 Upload a File to an FTP site
$ftpdest = "ftp://site.com/src.txt"
#$cred = Get-Credential
$wc = New-Object System.Net.WebClient
$wc.Credentials = $cred
#$wc.UploadFile($ftpdest,$src)
$wc.Dispose()
#[System.Net.WebRequestMethods+Ftp] | Get-Member
[System.Net.WebRequest] | Get-Member -MemberType Method

#12.3 Download a Web Page from the Internet
$123src = "http://www.bing.com/search?q=sqrt(2)"
#$result = [string](Invoke-WebRequest $123src)
$result = Invoke-WebRequest $123src

#12.4 Parse and Analyze a Web Page from the internet
$result.AllElements | Where-Object {$_.innerhtml -like "*=*"} | Sort-Object {$_.innerhtml.Length} | Select-Object innerText -First 5

#12.5 Script a Web Application Session
$artURI = 'http://musicbrainz.org/ws/2/artist/5b11f4ce-a62d-471e-81fc-a69a8278c7da?inc=aliases&fmt=json'
Invoke-WebRequest $artURI #| ConvertFrom-Json 

$recording = 'http://musicbrainz.org/ws/2/recording/fcbcdc39-8851-4efc-a02a-ab0e13be224f?inc=artist-credits+isrcs+releases&fmt=json'
Invoke-WebRequest $recording | ConvertFrom-Json | Select-Object -expand releases | Select-Object title, date, country,artist,name


# Demo of PowerShell process JSON object
$employees = '{"Employees":[
    {"FirstName":"John","LastName":"Doe"},
    {"FirstName":"Anna","LastName":"Smith"},
    {"FirstName":"Peter","LastName":"Jones"}
]}'

$employeesjs = ConvertFrom-Json -InputObject $employees
$employeesjs.Employees

$employeesjs | ConvertTo-Json

# Convert GregorianCalendar Object to a JSON_formatted string.
(Get-UICulture).Calendar | ConvertTo-Json

@{Account="User01";Domain="Domain01";Admin="True"} | ConvertTo-Json -Compress

# Convert an object to a JSON string and JSON object
Get-Date | Select-Object -Property * | ConvertTo-Json

# Ensures that Invoke-WebRequest uses TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$j = Invoke-WebRequest 'https://api.github.com/repos/PowerShell/PowerShell/issues' | ConvertFrom-Json
$j | ConvertTo-Json

$cred = Get-Credential
$login = Invoke-WebRequest http://www.facebook.com/login.php -SessionVariable fb

$login.Forms[0].Fields.email = $cred.UserName
$login.Forms[0].Fields.pass = $cred.GetNetworkCredential().Password
$mainpage = Invoke-WebRequest $login.Forms[0].Action -WebSession $fb -Body $login -Method Post
$mainpage.ParsedHtml.getElementById('notificationsCountValue').innerText

#12.6 Program: Get-PageUrls

#12.7 Interact with REST-Based Web APIs
$url = "https://api.stackexchange.com/2.0/questions/unanswered"
$result = Invoke-RestMethod $url
$result.Items | ForEach-Object {$_.Tittle;$_.Link;""}

#12.8 Connect to a Web Service
$url1 = "http://www.terraserver-usa.com/TerraService2.asmx"
$terraServer = New-WebServiceProxy $url -Namespace Cookbook
$place = New-Object Cookbook.Place
$place.City = "Redmond"
$place.State = "WA"
$place.Country = "USA"
$facts = $terraserver.GetPlaceFacts($place)
$facts.Center

#12.9 Export Command Output as a Web Page
$filename = "C:\windows\temp\help.html"
$commands = get-command | where {$_.CommandType -ne "Alias"}
$summary = $commands | Get-Help | Select-Object Name,Synopsis
$summary | ConvertTo-Html | select-content $filename

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

#CHAPTER14
#Debugging
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

#CHAPTER 17
#Extend the Reach of Windows PowerShell
#17.1 Automate Programs Using COM Scripting Interfaces
$shell = New-Object -ComObject "Shell.Application"
$shell.windows() | Format-Table LocationName,LocationUrl

#17.2 Program: Query a SQL Data Source

#17.3 Access Windows Performance Counters
$counter = get-counter "\System\System Up Time"
$uptime = $counter.countersamples[0].CookedValue
New-TimeSpan -Seconds $uptime
$counter
get-counter -list * | format-list CounterSetName, Description
Get-Counter -Continuous

#17.4 Access Windows API Functions
#Chapter18
#Security and Script Signing
#18.8 Securely Handle Sensitive Information
$secureInput = Read-Host -AsSecureString "Enter Your Private Key"
$secureInput

#18.9 Securely Request Usernames and Passwords
$credential = Get-Credential
$credential

#18.10 Program:Start a Process as Another User

#18.11 Program:Run a Temporarily Elevated Command

#18.12 Securely Store Credentials on Disk
$credPath = Join-Path (Split-Path $profile) CurrentScript.ps1.Credential
$credential | Export-Clixml $credPath

#18.13 Access User and Machine Certificates
Set-Location Cert:\CurrentUser\My
$certs = Get-ChildItem
$certs | Format-List Subject,Issuer,NotAfter,Thumbprint

#18.14 Program:Search the Certificate Store

#PART IV
#Administrator Tasks
#Chapter 20, Files and Directories
Get-ChildItem -Recurse | Sort-Object -Descending LastAccessTime | Select-Object -First 10 | Format-Table Mode,LastAccessTime,LastWriteTime,length,name

#20.1 Determine the Current Location
$currentLocation = (Get-Location).Path
$currentLocation

#20.2 Get the Files in a Directory
Get-ChildItem *.ps1
Get-ChildItem C:\windows\*.dmp -Recurse -ErrorAction SilentlyContinue
Get-ChildItem C:\windows\system32 -Attributes Directory -ErrorAction SilentlyContinue
Get-Item $PWD
Get-ChildItem -Attributes compressed
Get-ChildItem -Attributes !archive
Get-ChildItem -Attributes "Hidden,ReadOnly"
Get-ChildItem -Attributes "ReadOnly+Hidden"
Get-ChildItem C:\ -Attributes "ReadOnly,Hidden+!System"

#20.3 Find All Files Modified Before a Certain Date
$compareDate = (Get-Date).AddDays(-60)
$compareDate
Get-ChildItem C:\ -Recurse | Where-Object {$_.LastAccessTime -lt $compareDate}| Select-Object -First 100 | format-table Mode, LastAccessTime, LastWriteTime,Length,Name

#20.4 Clear the Content of a File
Get-Content .\powershell_blog.XML -ErrorAction SilentlyContinue
Clear-Content .\powershell_blog.XML
Get-Content .\powershell_blog.XML -ErrorAction SilentlyContinue
Get-Item .\powershell_blog.XML

#20.6 Manage and Change the Attributes of a File
$file = Get-Item .\powershell_blog.XML
$file.IsReadOnly = $true
$file = Get-Item .\powershell_blog.XML

$file.Attributes = "ReadOnly,NotContentIndexed,System"
$file.Mode
$file.Attributes
Get-Item $file

$ReadOnly = [System.IO.FileAttributes] "ReadOnly"
$file.Attributes = $file.Attributes -bor $ReadOnly
[Enum]::GetValues([System.IO.FileAttributes])

#20.6 Find Files That Match a Pattern
Get-ChildItem -Exclude *.xml
Get-ChildItem -Include *.txt -Recurse

#20.7 Manage Files That Include Special Characters
Get-ChildItem -LiteralPath '[My File].txt' -ErrorAction SilentlyContinue

#20.8 Program: Get Disk Usage Information

#20.9 Monitor a File for Changes
# -Wait parameter acts much like the traditional Unix tail command.
# if you provide the -Wait parameter, the Get-Content cmdlet read the content of the file but doesn't exit.
Get-Content .\powershell_blog.XML #-Wait

#20.10 Get the Version of a DLL or Executable
$psexe = Get-Item $PSHOME\powershell.exe
$psexe.VersionInfo

Get-ChildItem $env:windir | Select-Object -expand VersionInfo -ErrorAction SilentlyContinue

#20.21 Program: Get the MD5 or SHA1 Hash of a File

#20.12 Create a Directory
md newdirectory
Get-Item newdirectory
Test-Path newdirectory
rm newdirectory

#20.13 Remove a File or Directory
Test-Path newdirectory

#20.14 Rename a File or Directory
Rename-Item example.txt newname.txt

#20.15 Move a File or Directory
Move-Item .\powershell_blog.XML ..\
Move-Item ..\powershell_blog.XML .\

#20.16 Create and Map PowerShell Drives
$myDT = [Environment]::GetFolderPath("Desktop")
New-PSDrive -Name Desktop -Root $myDT -PSProvider FileSystem
Get-ChildItem Desktop:

#20.17 Access Long File and Directory Names
$upg = "\\bjfiles\Upgrades"
New-PSDrive -Name UpgradeBuilds -Root $upg -PSProvider FileSystem
Get-ChildItem UpgradeBuilds:\ -Recurse | Where-Object {$_.LastAccessTime -lt $compareDate}| Select-Object -First 100 | format-table Mode, LastAccessTime, LastWriteTime,Length,Name,Path

#20.18 Unblock a File
# when you download a file from the internet, many web browsers, email clients, and chat programs
# add a marker to the file that identifies it as having come from the internet.
# This marker is contained in the Zone.Identifier alternate data stream.
Get-Item "C:\Program Files\VSCode\Code.exe" -Stream *
Get-Content "C:\Program Files\VSCode\Code.exe" -Stream Zone.Identifier
Get-Item "C:\Program Files\VSCode\Code.exe" | Unblock-File

#20.19 Interact with Alternate Data Streams
Get-Item  "$Home\Downloads" -Stream Zone.Identifier -ErrorAction Ignore | Select-Object FileName,Length | Format-Table -AutoSize

#20.20 Program: Move or Remove a Locked File

#20.21 Get the ACL of a File or Directory
Get-Acl $Home

#20.22 Set the ACL of a File or Directory

#20.23 Program: Add Extended File Properties to Files

#20.24 Program: Create a Filesystem Hard Link

#20.25 Program: Create a ZIP Archive
#CHAPTER 21
#The Windows Registry
#21.0 Introduction

#21.1 Navigate the Registry
Set-Location HKCU:
Set-Location \software\Microsoft\Windows\CurrentVersion\Run
Get-Location

#21.2 View a Registry Key
Get-ItemProperty .

#21.4 Create a Registry Key Value
New-ItemProperty . -Name VSCode -Value "C:\Program Files\VSCode\Code.exe"
Get-ItemProperty .

#21.3 Modify or Remove a Registry Key Value
(Get-ItemProperty .).VSCode
Set-ItemProperty . VSCode "D:\Databank\Program Files\"
Get-ItemProperty .
Remove-ItemProperty . VSCode
Get-ItemProperty .

#21.5 Remove a Registry Key

#21.6 Safely Combine Related Registry Modifications

#21.7 Add a Site to an Internet Explorer Security Zone

#21.8 Modify Internet Explorer Settings

#21.9 Program: Search the Windows Registry

#21.10 Get the ACL of a Registry Key

#21.11 Set the ACL of a Registry Key

#21.12 Work with the Registry of a Remote Computer

#21.13 Program: Get Registry Items from Remote Machines

#21.14 Program: Get Properties of Remote Registry Keys

#21.15 Program: Set Properties of Remote Registry Keys

#21.16 Discover Registry Settings for Programs
#CHAPTER 22 Comparing Data
#22.0 Introduction

#22.1 Compare the Output of Two Commands
$ps = Get-Process
notepad.exe
$newps =Get-Process
Compare-Object $ps $newps

#22.2 Determine the Differences Between Two Files
Compare-Object (Get-content .\PowerShell_CookBook_PartII_Chapter1.ps1) (Get-content .\PowerShell_CookBook_PartII_Chapter2.ps1)

#22.3 Verify Integrity of File Sets
Get-ChildItem C:\windows\system32\windowspowershell\v1.0 | Get-FileHash | Export-Clixml .\powershellhashes.clixml 
$otherHashes = Import-Clixml .\powershellhashes.clixml 
#Chapter23
#Event Logs

#23.1 List All Event Logs
# List all classic event logs
Get-EventLog -List
Get-WinEvent -ListLog * | Select-Object LogName,RecordCount | Where-Object {$_.RecordCount -gt 0}

#23.2 Get the Newest Entries from an Event Log
Get-EventLog System -Newest 10 | Format-Table Index, Source, Message -AutoSize

#23.3 Find Event Log Entries with Specific Text
Get-EventLog Application | Where-Object {$_.Message -match "Code"}

#23.4 Retrieve and Filter Event Log Entries
Get-EventLog System | Where-Object {$_.Index -eq 14056}

#23.5 Find Event Log Entries by Their Frequency
Get-EventLog System | Group-Object Message | Sort-Object -desc Count | Format-Table
Get-EventLog Application | Group-Object Source | Sort-Object -Descending Count | Format-Table

#23.6 Back Up an Event Log
wevtutil.exe epl System $env:TEMP\system.bak.evtx
Get-WinEvent -FilterHashtable @{LogName="System";level=1,2} -MaxEvents 2 | Format-Table -AutoSize
Get-WinEvent -FilterHashtable @{Path = "$env:Temp\system.bak.evtx";level=1,2} -MaxEvents 2 | Format-Table -AutoSize

# If Get-WinEvent cmdlet is not available on some legacy OS, try Export-CliXml cmdlet
Get-EventLog System | Export-Clixml $env:temp\SystemLogBackup.clixml 

#23.7 Create or Remove an Event Log
# Use the New-EventLog and Remove-EventLog cmdlets to create and remove event logs.
New-EventLog -LogName AutoScript -Source PowerShellCookBook
Get-EventLog -List
#Remove-EventLog Security

#23.8 Write to an Event Log
Write-EventLog -LogName AutoScript -Source PowershellCookBook -EventID 65500 -Message "This Event from VSCode"
Get-EventLog -LogName AutoScript

#23.9 Run a PowerShell Script for Windows Event Log Entries

#23.10 Clear or Maintain an Event Log
Get-EventLog -List | Where-Object {$_.Log -eq "Application"}
Clear-EventLog Application
Get-EventLog -List | Where-Object {$_.Log -eq "Application"}

#23.11 Access Event Logs of a Remote Machine
Get-EventLog System -ComputerName abc
#Chapter 24
#Processes
Get-Process | Where-Object {$_.WorkingSet -gt 100MB} | Stop-Process -WhatIf
#24.1 List Currently Running Processes
Get-Process | Group-Object Company
Get-Process | Sort-Object -Descending StartTime | Select-Object -First 10 | Format-Table Name, Id, WorkingSet, StartTime

#24.2 Launch the Application Associated with a Document
#Start-Process http://blogs.msdn.com/powershell

#24.3 Launch a Process
#Start-Process mmc -Verb runas -WindowStyle Maximized

$processname = "PowerShell.exe"
##Prepare to invoke the process
$ProcessStartInfo = New-Object system.diagnostics.ProcessStartInfo
$ProcessStartInfo.FileName = (get-command $processname).Definition
$ProcessStartInfo.WorkingDirectory = (Get-Location).Path
if($argumentlist)
{
    $ProcessStartInfo.Arguments = $argumentlist
}
$ProcessStartInfo.UseShellExecute = $false
### Always redirect the input and output of the process.
### Sometimes we will capture it as binary, other times we will just treat it as strings.
$ProcessStartInfo.RedirectStandardOutput = $true
$ProcessStartInfo.RedirectStandardInput = $true
$process = [System.diagnostics.process]::Start($ProcessStartInfo)
$process.id,$process.Name

#24.4 Stop a Process
Stop-Process -id $process.Id

#24.5 Get the Onwer of a Process
$id = get-process -Name powershell | ForEach-Object Id
Get-CimInstance Win32_Process -Filter "ProcessID=$id" | Invoke-CimMethod -Name GetOwner

#24.6 Get the Parent Process of a Process
$process = get-process -Name powershell
$id = $process.Id
$instance = Get-CimInstance Win32_Process -Filter "ProcessID = '$id'"
$instance.ParentProcessId

#24.7 Debug a Process
#Chapter25
#System Services
#25.1 List All Running Services
Get-Service | Where-Object {$_.Status -eq "Running"}
Write-Host "Sort all services by dependentServices" -BackgroundColor Blue
get-service | Sort-Object -Descending {$_.DependentServices.Count}

#25.2 Manage a Running Service
Stop-Service LxpSvc -WhatIf

#25.3 Configure a Service
Set-Service LxpSvc -StartupType Automatic
Get-Service LxpSvc

#CHAPTER26
#Active Directory
Get-PSProvider

