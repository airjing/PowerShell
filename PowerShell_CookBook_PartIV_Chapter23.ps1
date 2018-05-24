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
