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
