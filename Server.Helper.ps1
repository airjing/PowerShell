<#
.SYNOPSIS
Server Management Helper.

.DESCRIPTION
Function collections for Server Management.

.EXAMPLE
C:\PS> Server.Helper.ps1

.LINK
https://dev.azure.com/mediakind/Toolbox/_git/BJLABOPS
https://www.itprotoday.com/powershell/powershell-basics-custom-objects

#>
function Get-ComputerInfo {
    param (
        [Parameter(Mandatory = $false)]
        [string]
        $ComputerName        
    )
    if(!$ComputerName)
    {
        $ComputerName = "localhost"
    }
    $wmi_computersystem = Get-WmiObject Win32_ComputerSystem -ComputerName $ComputerName
    $wmi_os = Get-WmiObject Win32_OperatingSystem -ComputerName $ComputerName
    $wmi_bios = Get-WmiObject Win32_BIOS -ComputerName $ComputerName
    $OSInstallDate = $wmi_os.ConvertToDateTime($wmi_os.InstallDate)
    $OSLiveTime = (Get-Date) - $OSInstallDate
    $LastBootUpTime = $wmi_os.ConvertToDateTime($wmi_os.LastBootUpTime)
    $UpTime = (Get-Date) - $LastBootUpTime
    $os = @{
        "OSCaption" = $wmi_os.Caption
        "BuildNumber" = $wmi_os.BuildNumber
        "BootDevice" = $wmi_os.BootDevice
        "CurrentTimeZone" = $wmi_os.CurrentTimeZone
        "OSArchitecture" = $wmi_os.OSArchitecture
        "WindowsDirectory" = $wmi_os.WindowsDirectory
        "OSInstallDate" = ("{0:s}" -f $OSInstallDate)
        "OSLiveTime" = ("{0:d}" -f [string]$OSLiveTime)
        "UpTime" = ("{0:d}" -f [string]$UpTime)
    }
    $netadapters = Get-NetAdapter | Sort-Object -Property MacAddress
    if($netadapters)
    {
        $info_netadapters = @()
        foreach($netadapter in $netadapters)
        {
            $ipconfiguration = $netAdapter | Get-NetIPConfiguration -ErrorAction Ignore
            $DNSServers = ""
            $allproperties = $netAdapter | Get-NetAdapterAdvancedProperty
            $sendbuffers = ($allproperties | Where-Object {$_.DisplayName -eq "Transmit Buffers"}).DisplayValue
            $recbuffers = ($allproperties | Where-Object {$_.DisplayName -eq "Receive Buffers"}).DisplayValue
            $rss = ($allproperties | Where-Object {$_.DisplayName -eq "Receive Side Scaling"}).DisplayValue
            $vmq = ($allproperties | Where-Object {$_.DisplayName -eq "Virtual Machine Queues"}).DisplayValue
            foreach($dnsserver in $ipconfiguration.DNSServer.ServerAddresses)
            {
                $DNSServers = $dnsserver + ";"
            }
            $info_netadapter = @{
                "Name" = $netadapter.Name
                "Status" = $netadapter.Status
                "LinkSpeed" = $netadapter.LinkSpeed
                "InterfaceDescription" = $netadapter.InterfaceDescription
                "ifIndex" = $netadapter.ifIndex
                "MacAddress" = $netadapter.MacAddress
                "IPv4Address" = $ipconfiguration.IPv4Address.IPAddress
                "IPv4DefaultGateway" = $ipconfiguration.IPv4DefaultGateway.NextHop
                "DNSServer" = $DNSServers
                "TransmitBuffers" = $sendbuffers
                "ReceiveBuffers" = $recbuffers
                "ReceiveSideScaling" = $rss
                "VirtualMachineQueues" = $vmq
            }
            $info_netadapters += $info_netadapter
        }
    }

    $info = @{
        "Hostname" = $wmi_computersystem.Name
        "Manufacturer" = $wmi_computersystem.Manufacturer
        "Model" = $wmi_computersystem.Model
        "SerialNumber" = $wmi_bios.SerialNumber
        "SMBIOSBIOSVersion" = $wmi_bios.SMBIOSBIOSVersion
        "OS" = $os
        "NetAdapters" = $info_netadapters        
    }
    
    
    $Server = New-Object -TypeName PSObject -Property $info
    return $Server
}
function DumpTo-Xml{
    param(
        # Parameter help description
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [psobject]
        $InputObject,
        # Parameter help description
        [Parameter(Mandatory = $false)]
        [int16]
        $Deepth,
        # Parameter help description
        [Parameter(Mandatory = $false)]
        [string]
        $OutputFile
    )
    if(!$OutputFile)
        {
            $OutputFile = "output.xml"
        }
    if(Test-Path $OutputFile)
    {
        $xmldoc = [xml](Get-Content $OutputFile)
    }
    else{
        $xmldoc = New-Object System.Xml.XmlDocument
        $root = $xmldoc.CreateElement("Servers")
        $xmldoc.AppendChild($root)
        $xmldoc.Save($OutputFile)
    }
    if($InputObject)
    {
        $strHostname = $InputObject.Hostname
        $xmlEleServer = $xmldoc.SelectSingleNode("//Servers/Server[Hostname='$strHostname']")
        if(!$xmlEleServer)
        {
            $xmlEleServer = $xmldoc.CreateElement("Server")
            foreach($property in $InputObject.PSObject.Properties)
            {
                if($property.TypeNameOfValue -eq "System.Collections.Hashtable")
                {
                    foreach($subProperty in $property.Value.GetEnumerator())
                    {
                        $xmlSub = $xmldoc.CreateElement($subProperty.Name)
                        $xmlSub.InnerText = $subProperty.Value
                        $xmlEleServer.AppendChild($xmlSub)
                    }
                }
                if($property.TypeNameOfValue -eq "System.Object[]")
                {
                    foreach($item in $property.Value)
                    {
                        $xmlSubEleServer = $xmldoc.CreateElement($property.Name.TrimEnd('s'))
                        foreach($subitem in $item.Keys)
                        {
                            $xmlSub = $xmldoc.CreateElement($subitem)
                            $xmlSub.InnerText = $item[$subitem]
                            $xmlSubEleServer.AppendChild($xmlSub)
                        }
                        $xmlEleServer.AppendChild($xmlSubEleServer)
                    }
                    
                }
                if($property.TypeNameOfValue -eq "System.String")
                {
                    $xmlSub = $xmldoc.CreateElement($property.Name)
                    $xmlSub.InnerText = $property.Value
                    $xmlEleServer.AppendChild($xmlSub)
                }
            }
            $xmldoc.AppendChild($xmlEleServer)
            $xmldoc.Save($OutputFile)
        }

    }


    
    if(!$InputObject)
    {        
        $xmlwriter = New-Object System.Xml.XmlTextWriter($OutputFile,$null)
        $xmlwriter.Formatting = "Indented"
        $xmlwriter.Indentation = 2
        $xmlwriter.IndentChar = ' '
        $xmlwriter.WriteStartDocument()
        #$xmlwriter.WriteProcessingInstruction("xml-stylesheet","type='text/xsl' herf='style.xsl'")            
        #Write root element
        try{
            $xmlwriter.WriteStartElement("Servers")
            $xmlwriter.WriteStartElement("Server")
            foreach($property in $InputObject.PSObject.Properties)
            {
                if($property.TypeNameOfValue -eq "System.Collections.Hashtable")
                {
                    $xmlwriter.WriteStartElement($property.Name)
                    foreach($subProperty in $property.Value.GetEnumerator())
                    {
                        $xmlwriter.WriteElementString($subProperty.Name,$subProperty.Value)
                    }
                    $xmlwriter.WriteEndElement()
                }
                if($property.TypeNameOfValue -eq "System.Object[]"){
                    $xmlwriter.WriteStartElement($property.Name)
                    foreach($item in $property.Value)
                    {
                        $xmlwriter.WriteStartElement($property.Name.TrimEnd('s'))
                        foreach($subitem in $item.Keys)
                        {
                            if(!$subitem.Value.Keys)
                            {
                                $xmlwriter.WriteElementString($subitem,$item[$subitem])
                            }
                            else {
                                $xmlwriter.WriteStartElement($subitem.Name)
                                foreach($childItem in $subitem.Keys)
                                {
                                    $xmlwriter.WriteElementString($childItem,$subitem[$childItem])
                                }
                                $xmlwriter.WriteEndElement()
                            }
                        }                        
                        $xmlwriter.WriteEndElement()
                    }
                    $xmlwriter.WriteEndElement()
                }
                if($property.TypeNameOfValue -eq "System.String")
                {
                    
                    $xmlwriter.WriteElementString($property.Name,$property.Value)
                }
            }
        }
        finally{
            $xmlwriter.WriteEndElement()
        $xmlwriter.WriteEndElement()
    $xmlwriter.WriteEndDocument()
    $xmlwriter.Flush()
    $xmlwriter.Close()
        }
        

    }
}
function Write-Xml{
#set the formatting
$xmlsetting = New-Object System.Xml.XmlWriterSettings
$xmlsetting.Indent = $true
$xmlsetting.IndentChars = ' '
$xmlwriter = [System.Xml.XmlWriter]::Create("example.xml",$xmlsetting)

$xmlwriter.WriteStartDocument()
$xmlwriter.WriteProcessingInstruction("xml-stylesheet","type='text/sxl' herf='style.xsl'")
$xmlwriter.WriteStartElement("ROOT")
    $xmlwriter.WriteStartElement("Object")
    $xmlwriter.WriteAttributeString("Current",$true)
    $xmlwriter.WriteAttributeString("Owner",$HOME)  
        $xmlwriter.WriteElementString("Property1","Value 1")        
        $xmlwriter.WriteElementString("Property2","Value 2")
            $xmlwriter.WriteStartElement("SubObject")
                $xmlwriter.WriteElementString("Property3", "Value 3")
            $xmlwriter.WriteEndElement()        
        $xmlwriter.WriteEndElement()
$xmlwriter.WriteEndElement()
$xmlwriter.WriteEndDocument()
$xmlwriter.Flush()
$xmlwriter.Close()
}

Get-ComputerInfo | DumpTo-Xml
#$xml.Save("1.xml")


