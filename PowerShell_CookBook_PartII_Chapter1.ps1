#The Windows PowerShell Interactive Shell
# call external commandline:
# & 'notepad.exe' 'D:\FullXMLContent.xml'
attrib -R D:\FullXMLContent.xml
attrib D:\FullXMLContent.xml
Get-Acl D:\FullXMLContent.xml | Format-List
# --% verbatim syntax:
cmd.exe /c echo 'test'
# output:
#test

cmd.exe --% /c echo 'test'
# output:
#'test'

# Special character Meaning
# " The beginning (or end) of quoted text
# # The beginning of a comment
# $ The beginning of a variable
# & Reserved for future use
# ( ) Parentheses used for subexpressions
# ; Statement separator
# { } Script block
# | Pipeline separator
# ` Escape character
$commands = 'Get-Process'
# convert string type commands to Byte Array variable $bytes
$bytes = [System.Text.Encoding]::Unicode.GetBytes($commands)
write-host $bytes
$encodedstring = [Convert]::ToBase64String($bytes)
write-host $encodedstring
$inputbytes = 'RwBlAHQALQBQAHIAbwBjAGUAcwBzAA=='
$encodedbytes = [Convert]::FromBase64String($inputbytes)

foreach ($b in $encodedbytes) {
    write-host $b
}
$decodedstring = [System.Text.Encoding]::Unicode.GetString($encodedbytes)
write-host $decodedstring

# demos of Job releated command lets
$job = Start-Job -ScriptBlock {Get-EventLog -LogName System -Newest 100}
$job | Format-List -Property *
while ($job.JobStateInfo.State -eq 'Running') {
    $JobResult = Receive-Job -Job $job
    $JobResult
}
# $? return True or False of latest run.
# $LastExitCode return exit code.
$error[0] | Format-List -force
Get-History

# Store the Output of a command to a File
# Redirection Operators: > or >>
# Out-File cmdlet
$oFile='.\out.txt'
if (Test-Path $oFile)
{
    Remove-Item $oFile
    #Write-Host only redirect the output to console, so use Write-Output instead in order to save to a file.
    Write-Output 'Listing files in Folder C:\Windows\System32 by ' | Out-File $oFile -Encoding utf8
    Get-ChildItem C:\windows\system32 | Out-File -Append -Width 100 -Encoding utf8 .\out.txt
}

