# Common Tasks | Simple File
#9.1 Get the content of the file.
measure-command {
    Write-Host "Get-content without -ReadCount"
    $content = Get-Content .\out.txt}
measure-command {
    Write-Host "Get-Content with -ReadCount to get best performance"
    $content = Get-Content .\out.txt -ReadCount 10000}
$content1 = ${.\out.txt}
measure-command {
    Write-Host "also better performace by .Net System.IO.File class"
    $contentLines = [System.IO.File]::ReadAllLines(".\out.txt")}

#$content

#9.2 Search a File for Text or a Pattern
# to search a file for an exact(but case-insensitive) match, use the -Simple
Select-String -SimpleMatch .dll .\out.txt
# show LineNumber and Line by Select-Object
$matches = Select-String ".dll" .\out.txt
$matches | Select-Object LineNumber,Line

Get-ChildItem *.ps1 -Recurse | Select-String pattern

#9.3 Parse and Manage Text-Based logfiles

#9.4 Parse and Manage Binary Files

#9.5 Create a Temporary File
$tmpfile = [System.IO.Path]::GetTempFileName()
$content > $tmpfile
Get-ChildItem $tmpfile
Remove-Item -Force $tmpfile

#9.6 Search and Replace Text in a File
$match = ".dll"
$replacement = "...Dymanic Line Library"
$content = $content -creplace $match, $replacement
$content >> $tmpfile
Get-content $tmpfile -ReadCount 100000

#9.7 Get the Encoding of a File

#9.8 Program: View the Hexadecimal Representation of Content