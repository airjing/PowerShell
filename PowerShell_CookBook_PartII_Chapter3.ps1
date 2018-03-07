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