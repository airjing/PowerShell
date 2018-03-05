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