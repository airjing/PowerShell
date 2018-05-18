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

