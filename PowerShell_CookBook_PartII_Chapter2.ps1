#PowerShell_CookBook_PartII_Chapter2 - Pipelines
#Example 2-1. A PowerShell pipeline
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

#2.8 Intercept Stages of the Pipeline
