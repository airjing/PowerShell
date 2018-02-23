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
$commands='Get-Process'
# convert string type commands to Byte Array variable $bytes
$bytes = [System.Text.Encoding]::Unicode.GetBytes($commands)
write-host $bytes
$encodedstring = [Convert]::ToBase64String($bytes)
write-host $encodedstring
$inputbytes = 'RwBlAHQALQBQAHIAbwBjAGUAcwBzAA=='
$encodedbytes = [Convert]::FromBase64String($inputbytes)

foreach($b in $encodedbytes)
{
    write-host $b
}
$decodedstring = [System.Text.Encoding]::Unicode.GetString($encodedbytes)
write-host $decodedstring