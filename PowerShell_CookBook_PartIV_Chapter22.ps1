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