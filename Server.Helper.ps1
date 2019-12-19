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
            $DNSServers = @()
            $allproperties = $netAdapter | Get-NetAdapterAdvancedProperty
            $sendbuffers = ($allproperties | Where-Object {$_.DisplayName -eq "Transmit Buffers"}).DisplayValue
            $recbuffers = ($allproperties | Where-Object {$_.DisplayName -eq "Receive Buffers"}).DisplayValue
            $rss = ($allproperties | Where-Object {$_.DisplayName -eq "Receive Side Scaling"}).DisplayValue
            $vmq = ($allproperties | Where-Object {$_.DisplayName -eq "Virtual Machine Queues"}).DisplayValue
            foreach($dnsserver in $ipconfiguration.DNSServer.ServerAddresses)
            {
                $DNSServer = @{
                    "DNSServer" = $dnsserver
                }
                $DNSServers += $DNSServer
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
        $InputObj,
        # Parameter help description
        [Parameter(Mandatory = $false)]
        [string]
        $OutputFile
    )
    if(!$OutputFile)
        {
            $OutputFile = "output.xml"
        }
    if($InputObj)
    {        
        $xmlwriter = New-Object System.Xml.XmlTextWriter($OutputFile,$null)
        $xmlwriter.Formatting = "Indented"
        $xmlwriter.Indentation = 2
        $xmlwriter.IndentChar = ' '
        $xmlwriter.WriteStartDocument()
        #$xmlwriter.WriteProcessingInstruction("xml-stylesheet","type='text/xsl' herf='style.xsl'")            
        #Write root element
        $xmlwriter.WriteStartElement("Servers")
            $xmlwriter.WriteStartElement("Server")            
            $xmlwriter.WriteEndElement()
        $xmlwriter.WriteEndElement()
    $xmlwriter.WriteEndDocument()
    $xmlwriter.Flush()
    $xmlwriter.Close()
    }
}
function Write-Property{
    param(
        # Parameter help description
        [Parameter(Mandatory = $true,ValueFromPipeline = $true)]
        [PSObject.Properties]
        $Property,
        # Parameter help description
        [Parameter(Mandatory = $true,ValueFromPipeline = $true)]
        [System.Xml.XmlTextWriter]
        $XmlWriter
    )
    if($Property.TypeNameOfValue -ne "System.Collections.Hashtable")
    {
        $XmlWriter.WriteStartElement($Property.Name)
        $XmlWriter.WriteEndElement()
    }
    else{
        $XmlWriter.WriteElementString()
    }
    
    
    
    foreach($property in $properties)
            {
                if($property.TypeNameOfValue -ne "System.Collections.Hashtable")
                {
                    $xmlwriter.WriteElementString($property.Name,$property.Value)
                }
                else {
                    $xmlwriter.WriteStartElement($property.Name)
                    
                    $xmlwriter.WriteEndElement()
                }
            }
}
function Out-Xml{
$outputfile = "output.xml"
$xmlwriter = New-Object System.Xml.XmlTextWriter($outputfile,$null)
$xmlwriter.Formatting = "Indented"
$xmlwriter.Indentation = 2
$xmlwriter.IndentChar = ' '
$xmlwriter.WriteStartDocument()
#$xmlwriter.WriteProcessingInstruction("xml-stylesheet","type='text/xsl' herf='style.xsl'")
    $xmlwriter.WriteComment("Server Information")
    $xmlwriter.WriteStartElement("Servers")
        $xmlwriter.WriteStartElement("Server")
            $xmlwriter.WriteComment("General information")
            $info_computersystem = Get-WmiObject Win32_ComputerSystem
            $xmlwriter.WriteElementString("Hostname",$info_computersystem.Name)
            $xmlwriter.WriteElementString("Model",$info_computersystem.Model)
            $xmlwriter.WriteElementString("Manufacturer",$info_computersystem.Manufacturer)
            $info_bios = Get-WmiObject Win32_BIOS
            $xmlwriter.WriteElementString("SerialNumber",$info_bios.SerialNumber)
            $xmlwriter.WriteElementString("SMBIOSBIOSVersion",$info_bios.SMBIOSBIOSVersion)
            $info_os = Get-WmiObject Win32_OperatingSystem
            $xmlwriter.WriteElementString("OSCaption",$info_os.Caption)
            $xmlwriter.WriteElementString("BuildNumber",$info_os.BuildNumber)
            $xmlwriter.WriteElementString("BootDevice",$info_os.BootDevice)
            $xmlwriter.WriteElementString("",$info_os.CurrentTimeZone)
            $OSInstallDate = $info_os.ConvertToDateTime($info_os.InstallDate)
            $xmlwriter.WriteElementString("InstallDate",$OSInstallDate)
            $OSLiveTime = (Get-Date) - $OSInstallDate
            $strOSLiveTime = [string]$OSLiveTime.Days + ":" + [string]$OSLiveTime.Hours +":" + [string]$OSLiveTime.Minutes + ":" + [string]$OSLiveTime.Seconds + " - (DD:HH:MM:SS)"
            $xmlwriter.WriteElementString("OSLiveTime",$strOSLiveTime)
            $LastBootUpTime = $info_os.ConvertToDateTime($info_os.LastBootUpTime)
            $xmlwriter.WriteElementString("LastBootUpTime",$LastBootUpTime)
            $uptime = (Get-Date) - $LastBootUpTime
            $strUptime = [string]$uptime.Days + ":" + [string]$uptime.Hours +":" + [string]$uptime.Minutes + ":" + [string]$uptime.Seconds + " - (DD:HH:MM:SS)"
            $xmlwriter.WriteElementString("Uptime",$strUptime)
            $xmlwriter.WriteElementString("OSArchitecture",$info_os.OSArchitecture)
            $xmlwriter.WriteElementString("WindowsDirectory",$info_os.WindowsDirectory)
            # Hardware information
            $xmlwriter.WriteStartElement("Hardware")
                # Dump Net Adapters
                $netadapters = Get-NetAdapter | Sort-Object -Property MacAddress
                if($netadapters)                
                {
                    $xmlwriter.WriteStartElement("NetAdapters")
                    foreach($netadapter in $netadapters)
                    {
                        $xmlwriter.WriteStartElement("NetAdapter")
                        $xmlwriter.WriteElementString("Name",$netadapter.name)
                        $xmlwriter.WriteElementString("Status",$netadapter.Status)
                        $xmlwriter.WriteElementString("LinkSpeed",$netadapter.LinkSpeed)
                        $xmlwriter.WriteElementString("InterfaceDescription",$netadapter.InterfaceDescription)                        
                        $xmlwriter.WriteElementString("ifIndex",$netadapter.ifIndex)
                        $xmlwriter.WriteElementString("MacAddress",$netadapter.MacAddress)
                        $ipconfiguration = $netAdapter | Get-NetIPConfiguration -ErrorAction Ignore
                        $xmlwriter.WriteElementString("IPv4Address",$ipconfiguration.IPv4Address)
                        $xmlwriter.WriteElementString("IPv4DefaultGateway",$ipconfiguration.IPv4DefaultGateway.NextHop)
                        $xmlwriter.WriteStartElement("DNSServer")
                        foreach($dnsserver in $ipconfiguration.DNSServer.ServerAddresses)
                        {
                            $xmlwriter.WriteElementString("DNSServer",$dnsserver)
                        }
                        $xmlwriter.WriteEndElement()
                        $allproperties = $NetAdapter | Get-NetAdapterAdvancedProperty
                        $sendbuffers = ($allproperties | Where-Object {$_.DisplayName -eq "Transmit Buffers"}).DisplayValue
                        $recbuffers = ($allproperties | Where-Object {$_.DisplayName -eq "Receive Buffers"}).DisplayValue
                        $rss = ($allproperties | Where-Object {$_.DisplayName -eq "Receive Side Scaling"}).DisplayValue
                        $vmq = ($allproperties | Where-Object {$_.DisplayName -eq "Virtual Machine Queues"}).DisplayValue
                        $xmlwriter.WriteElementString("Transmit_Buffers",$sendbuffers)
                        $xmlwriter.WriteElementString("Recevie_Buffers",$recbuffers)
                        $xmlwriter.WriteElementString("Receive_Side_Scaling",$rss)
                        $xmlwriter.WriteElementString("Virtual_Machine_Queues",$vmq)                        
                        $xmlwriter.WriteEndElement()
                    }
                    $xmlwriter.WriteEndElement() 
                }
            $xmlwriter.WriteEndElement()
        $xmlwriter.WriteEndElement()
    $xmlwriter.WriteEndElement()
$xmlwriter.WriteEndDocument()
$xmlwriter.Flush()
$xmlwriter.Close()
}

$xml = Get-ComputerInfo | ConvertTo-Xml -NoTypeInformation -As Document
$xml.Save("1.xml")