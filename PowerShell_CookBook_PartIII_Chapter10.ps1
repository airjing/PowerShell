# CHAPTER 10 Structured Files
#10.1 Access information in an XML File
$filename = "$PWD\powershell_blog.XML"
if(!(Test-Path $filename))
{
    Invoke-WebRequest blogs.msdn.com/b/powershell/rss.aspx -OutFile $filename
}
[System.IO.Path]::GetFullPath($filename)

# Accessing properties of an XML document
$xml = [XML](Get-Content $filename)
$xml
#output by above line:
#   xml                            rss
#   ---                            ---
#   version="1.0" encoding="UTF-8" rss
$xml.xml
# output
#   version="1.0" encoding="UTF-8"
$xml.rss
# output by above line:
#   version : 2.0
#   content : http://purl.org/rss/1.0/modules/content/
#   wfw     : http://wellformedweb.org/CommentAPI/
#   dc      : http://purl.org/dc/elements/1.1/
#   atom    : http://www.w3.org/2005/Atom
#   sy      : http://purl.org/rss/1.0/modules/syndication/
#   slash   : http://purl.org/rss/1.0/modules/slash/
#   channel : channel
$xmlContent = $xml.rss.content
$xmlContentType = $xmlContent.GetType()
$xmlChannel = $xml.rss.channel
($xmlChannel.Item).Count
$item0 = ($xmlChannel.Item)[0]
$item0
$item1 = ($xml.rss.channel.item)[1]
$item1
$item2 = $xml.rss.channel.Item[2]
$item2.title
$item2.pubDate
$comment = Invoke-WebRequest $item2.commentRss
[xml]$commentItems = $comment.rss.channel

#10.2 Perform an XPath Query Against XML
$query = "/rss/channel/item[string-length(title) < 100]/title"
$query1 = "/rss/channel/item/title/link"
$a = Select-Xml -XPath $query1 -Path $filename | Select-Object -ExpandProperty Node
$xml = [xml](Get-Content $filename)
$xml | Select-Xml $query1

#10.3 Convert Objects to XML
$psXMLFile = "$PWD\psmetadata.xml"
if(!(Test-Path $psXMLFile))
{
    $ps = Get-Process | ConvertTo-Xml
    $ps.Save($psXMLFile)
}
$psXML = [xml](Get-Content $psXMLFile) 
$psXML | Select-Xml '//Property[@Name = "Name"]'

#10.4 Modify Data in an XML File

#10.5 Easily Import and Export Your Structured Data
$favorites = @{}
$favorites["VSPP"] = "D:\Databank\work\VSPP"
$favorites["OpenStack"] = "D:\Databank\Work\OpenStack"
$clixml = "$PWD\favorites.clixml"
$favorites | Export-Clixml $clixml

#10.6 Store the Output of a Command in a CSV or Delimited File
Get-Process | Export-Csv "$PWD\ps.csv"

#10.7 Import CSV and Delimited Data from a File
$header = "Date","Time","PID","TID","Component","Text"
$log = Import-Csv $env:windir\windowsupdate.log -Delimiter "`t" -Header $header
$log | Group-Object Component