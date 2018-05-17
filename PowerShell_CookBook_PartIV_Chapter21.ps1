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
