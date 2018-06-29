# CHAPTER 10 Structured Files
#10.1 Access information in an XML File
$filename = "$PWD\powershell_blog.XML"
if(!(Test-Path $filename) -or (Get-Item $filename).Length -eq 0)
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

#10.8 Manage JSON Data Streams
$object = [PSCustomObject] @{
    Name="Lee";
    Phone="123456"
}
$json = ConvertTo-Json $object
$json
$hstable = ConvertFrom-Json $json
$hstable

$edge = Get-Process MicrosoftEdge
$edge | ConvertTo-Json -Depth 2

$xmlUnattend = [xml] @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <WindowsDeploymentServices>
                <Login>
                    <Credentials>
                        <Domain>RNEA</Domain>
                        <Password>Esoteric$</Password>
                        <Username>tv2bot</Username>
                    </Credentials>
                </Login>
            </WindowsDeploymentServices>
            <EnableFirewall>false</EnableFirewall>
            <EnableNetwork>true</EnableNetwork>
            <Restart>Restart</Restart>
        </component>
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SetupUILanguage>
                <UILanguage>en-US</UILanguage>
            </SetupUILanguage>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-IE-ESC" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <IEHardenAdmin>false</IEHardenAdmin>
            <IEHardenUser>false</IEHardenUser>
        </component>
        <component name="Microsoft-Windows-ServerManager-SvrMgrNc" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <DoNotOpenServerManagerAtLogon>true</DoNotOpenServerManagerAtLogon>
        </component>
        <component name="Microsoft-Windows-UnattendedJoin" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <Identification>
                <Credentials>
                    <Domain>%USERDOMAIN%</Domain>
                    <Password>%USERPASSWORD%</Password>
                    <Username>%USERNAME%</Username>
                </Credentials>
                <JoinDomain>%MACHINEDOMAIN%</JoinDomain>
            </Identification>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <AutoLogon>
                <Password>
                    <Value>TQAxAGMAcgBvACQAbwBmAHQAUABhAHMAcwB3AG8AcgBkAA==</Value>
                    <PlainText>false</PlainText>
                </Password>
                <LogonCount>3</LogonCount>
                <Username>administrator</Username>
                <Enabled>true</Enabled>
            </AutoLogon>
            <ComputerName>%Machine%</ComputerName>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
            </OOBE>
            <TimeZone>China Standard Time</TimeZone>
            <RegisteredOwner>Mediaroom Beijing LAB</RegisteredOwner>
            <RegisteredOrganization>Ericsson</RegisteredOrganization>
            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add">
                    <CommandLine>cmd /c call C:\TV2OPS\Script\StartupStage0.bat</CommandLine>
                    <Order>1</Order>
                    <Description>Setup IP</Description>
                </SynchronousCommand>
            </FirstLogonCommands>
            <Display>
                <ColorDepth>32</ColorDepth>
                <HorizontalResolution>1024</HorizontalResolution>
                <VerticalResolution>768</VerticalResolution>
            </Display>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>0409:00000409</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UILanguageFallback>en-US</UILanguageFallback>
            <UserLocale>en-US</UserLocale>
        </component>
    </settings>
    <cpi:offlineImage cpi:source="wim:d:/hpse316.wim#Windows Server 2008 ENT x64 SP2 for HP SE316(V1.0.0)" xmlns:cpi="urn:schemas-microsoft-com:cpi" />
</unattend>
"@

$UnattendedJoin = $xmlUnattend.unattend.settings.component | Where-Object {$_.Name -eq "Microsoft-Windows-UnattendedJoin"}
$UnattendedJoinUserDomain = $UnattendedJoin.Identification.Credentials.Domain
$UnattendedJoinPassword = $UnattendedJoin.Identification.Credentials.Password
$UnattendedJoinUsername = $UnattendedJoin.Identification.Credentials.Username
$UnattendedJoinDomain = $UnattendedJoin.Identification.JoinDomain

$UnattendedJoin.Identification.Credentials.Domain = "RNEA"
$UnattendedJoin.Identification.Credentials.Password = "Esoteric$$"
$UnattendedJoin.Identification.Credentials.Username = "LabAgent"
$UnattendedJoin.Identification.JoinDomain = "RNEA.IPTV.MR.ERICSSON.SE"
$xmlUnattend.Save("D:\1.xml")

$oobe = $xmlUnattend.unattend.settings | Where-Object ($_.pass -eq "oobeSystem")
$str = ''
$oobe.component.Microsoft&#8211Windows&#8211Shell&#8211Setup'

Select-Xml '//unattend.settings[@pass='oobeSystem']' $xmlUnattend