#12.1 Download a File from an FTP or internet Site
$src = "http://www.microsoft.com"
$desc = "C:\windows\temp\src.txt"
Invoke-WebRequest $src -OutFile $desc
#notepad.exe $desc

#12.2 Upload a File to an FTP site
$ftpdest = "ftp://site.com/src.txt"
#$cred = Get-Credential
$wc = New-Object System.Net.WebClient
$wc.Credentials = $cred
#$wc.UploadFile($ftpdest,$src)
$wc.Dispose()
#[System.Net.WebRequestMethods+Ftp] | Get-Member
[System.Net.WebRequest] | Get-Member -MemberType Method

#12.3 Download a Web Page from the Internet
$123src = "http://www.bing.com/search?q=sqrt(2)"
#$result = [string](Invoke-WebRequest $123src)
$result = Invoke-WebRequest $123src

#12.4 Parse and Analyze a Web Page from the internet
$result.AllElements | Where-Object {$_.innerhtml -like "*=*"} | Sort-Object {$_.innerhtml.Length} | Select-Object innerText -First 5

#12.5 Script a Web Application Session
$artURI = 'http://musicbrainz.org/ws/2/artist/5b11f4ce-a62d-471e-81fc-a69a8278c7da?inc=aliases&fmt=json'
Invoke-WebRequest $artURI #| ConvertFrom-Json 

$recording = 'http://musicbrainz.org/ws/2/recording/fcbcdc39-8851-4efc-a02a-ab0e13be224f?inc=artist-credits+isrcs+releases&fmt=json'
Invoke-WebRequest $recording | ConvertFrom-Json | Select-Object -expand releases | Select-Object title, date, country,artist,name


# Demo of PowerShell process JSON object
$employees = '{"Employees":[
    {"FirstName":"John","LastName":"Doe"},
    {"FirstName":"Anna","LastName":"Smith"},
    {"FirstName":"Peter","LastName":"Jones"}
]}'

$employeesjs = ConvertFrom-Json -InputObject $employees
$employeesjs.Employees

$employeesjs | ConvertTo-Json

# Convert GregorianCalendar Object to a JSON_formatted string.
(Get-UICulture).Calendar | ConvertTo-Json

@{Account="User01";Domain="Domain01";Admin="True"} | ConvertTo-Json -Compress

# Convert an object to a JSON string and JSON object
Get-Date | Select-Object -Property * | ConvertTo-Json

# Ensures that Invoke-WebRequest uses TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$j = Invoke-WebRequest 'https://api.github.com/repos/PowerShell/PowerShell/issues' | ConvertFrom-Json
$j | ConvertTo-Json

$cred = Get-Credential
$login = Invoke-WebRequest http://www.facebook.com/login.php -SessionVariable fb

$login.Forms[0].Fields.email = $cred.UserName
$login.Forms[0].Fields.pass = $cred.GetNetworkCredential().Password
$mainpage = Invoke-WebRequest $login.Forms[0].Action -WebSession $fb -Body $login -Method Post
$mainpage.ParsedHtml.getElementById('notificationsCountValue').innerText

#12.6 Program: Get-PageUrls

#12.7 Interact with REST-Based Web APIs
$url = "https://api.stackexchange.com/2.0/questions/unanswered"
$result = Invoke-RestMethod $url
$result.Items | ForEach-Object {$_.Tittle;$_.Link;""}

#12.8 Connect to a Web Service
$url1 = "http://www.terraserver-usa.com/TerraService2.asmx"
$terraServer = New-WebServiceProxy $url -Namespace Cookbook
$place = New-Object Cookbook.Place
$place.City = "Redmond"
$place.State = "WA"
$place.Country = "USA"
$facts = $terraserver.GetPlaceFacts($place)
$facts.Center

#12.9 Export Command Output as a Web Page
$filename = "C:\windows\temp\help.html"
$commands = get-command | where {$_.CommandType -ne "Alias"}
$summary = $commands | Get-Help | Select-Object Name,Synopsis
$summary | ConvertTo-Html | select-content $filename