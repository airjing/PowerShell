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
