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
<<<<<<< HEAD
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
=======
Get-ChildItem C:\*.dll -Recurse | ForEach-Object {[void] $output.AppendLine($_.FullName + " | " + $_.VersionInfo)}
$output.ToString()
>>>>>>> 8f1cdbd9e4f5f28ad08ad7b150fe69dbe56455a6
