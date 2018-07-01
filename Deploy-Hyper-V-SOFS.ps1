$LabConfig = @{Root = "$home\SCLAB"; DomainAdmin = 'LabAdmin';AdminPassword = 'P@ssword1!';Prefix = 'SC-'; `
                SwitchName = 'Lab';DCEdition = '4';AdditionalNetworksConfig=@(); DomainNetbiosName = "SCLABDemo";`
                DomainName = "SCLABDemo.INFRA.CORP"; ServerDCGUIVHD = "Win2016_DC_G2.vhdx";`
                ServerDCCoreVHD = "Win2016_DC_Core_G2.vhdx"; TimeZone = "China Standard Time"; VHDStore = "F:";`
                ISOStore = "E:\Software\ISO;D:\Databank\Software\ISO"; Win2K6VL = "en_windows_server_2016_vl_x64_dvd_11636701.iso"
                VMs = @()}

#Add DC's info
$LabConfig.VMs += @{VMName="SCLABDC01";MachineType="DomainController";ParentVHD = "Win2016Core_G2.vhdx";MemoryStartupBytes = 2GB;CpuCores = 4;}
1..4 | ForEach-Object {$VMNames="SOFS0"; $LabConfig.VMs += @{ VMName = "$VMNames$_" ; MachineType = "S2D" ;`
                        ParentVHD = "Win2016Core_G2.vhdx"; SSDNumber = 0; SSDSize = 800GB ; HDDNumber = 12; HDDSize = 4TB; MemoryStartupBytes = 512MB}}
1..4 | ForEach-Object {$VMNames="SCHOST0"; $LabConfig.VMs += @{ VMName = "$VMNames$_"; MachineType = "Hyper-V";`
                        ParentVHD = "Win2016Core_G2.vhdx"; SSDNumber =0; SSDSize = 800GB; HDDNumber = 0; HDDSize = 4TB; MemoryStartupBytes = 8192MB}}

# Verify Running as Admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).isInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (!($isAdmin))
{
    Write-Host "--- Restarting as Administrator" -ForegroundColor Cyan; Start-Sleep -Seconds 1
    # $PSCommandPath tells you the full path to the command from where you were being invoked
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

1..10 | % {write-host ""}

#region Output log Functions
function WriteInfo($message)
{
    Write-Host "INFO`t:"$message
}

function WriteInfoHighlighted($message)
{
    Write-Host "INFO`t:`t"$message -ForegroundColor Cyan
}

function WriteSuccess($message)
{
    write-host "Success`t:`t"$message -ForegroundColor Green
}

function WriteError($message)
{
    write-host "Error`t:`t"$message -ForegroundColor Red
}

function WriteErrorAndExit($message)
{
    Write-Host $message -ForegroundColor Red
    Write-Host "Please enter to Continue ..."
    Stop-Transcript
    $exit = Read-Host
    Exit
}

function Get-WindowsBuildNumber 
{
    $os = Get-WmiObject -Class Win32_OperatingSystem
    return [int]($os.BuildNumber)
}
#endregion

function Get-FileinMultiPath{
    param(
        [Parameter(Mandatory)]
        [string]
        $Path,
        [Parameter(Mandatory)]
        [string]
        $Filename
    )
    if (($Path -ne $null) -and ($Filename -ne $null))
    {
        $aryPath = $Path.Split(";")
        foreach($p in $aryPath)
        {
            $f = (Get-ChildItem -Path $p -Recurse $Filename).FullName
            return $f
        }
    }
}


#region Prerequest check
Start-Transcript -Path "$($LabConfig.Root)\Prereq.log"
$startDateTime = Get-Date
WriteInfo "Script Started at $startDateTime"

#checking for compatible OS
WriteInfoHighlighted "Checking if OS is Windows10 1511 / Server 2016 or newer"
$BuildNumber = Get-WindowsBuildNumber
if($BuildNumber -ge 10586)
{
    WriteSuccess "OS is Windows10 1511 / Server 2016 or newer"
}
else {
    WriteErrorAndExit "Windows Version $BuildNumber detected. Version 10586 and newer is needed. Exiting"
}

#checking folder structure
"ParentDisks",`
"Tools\DSC",`
"Tools\ToolsVHD\DiskSpd",`
"Tools\ToolsVHD\SCVMM\ADK",`
"Tools\ToolsVHD\SCVMM\SQL", `
"Tools\ToolsVHD\SCVMM\SCVMM\UpdateRollup",`
"Tools\ToolsVHD\VMFleet" | ForEach-Object{
    if(!(Test-Path "$($LabConfig.Root)\$_")) {New-Item -type Directory -Path "$($LabConfig.Root)\$_"}}

"Tools\ToolsVHD\SCVMM\ADK\Copy_ADK_with_adksetup.exe_here.txt", `
"Tools\ToolsVHD\SCVMM\SQL\copy_SQL2016_with_setup.exe_here.txt", `
"Tools\ToolsVHD\SCVMM\SCVMM\Copy_SCVMM_with_setup.exe_here.txt", `
"Tools\ToolsVHD\SCVMM\SCVMM\UpdateRollup\Copy_SCVMM_Update_Rollup_MSPs_here.txt" | ForEach-Object{
    if(!(Test-Path "$($LabConfig.Root)\$_")) {New-Item -type File -Path "$($LabConfig.Root)\$_";WriteInfo $_.FullName.Length}} 

if(!(Test-Path "$($LabConfig.VHDStore)\ParentDisks"))
{
    New-Item -ItemType Directory -Path "$($LabConfig.VHDStore)\ParentDisks"
}    
#Download conver-windowsimage into Tools and ToolsVHD
WriteInfoHighlighted "Testing convert-windowsimage presence in \Tools"
if(Test-Path "$($LabConfig.Root)\Tools\convert-windowsimage.ps1")
{
    WriteSuccess "`t convert-windowsimage.ps1 already exists in \Tools, skipping and download"    
}
else {
    WriteInfo "`t Downloading convert-windowsimage"
    try {
        Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/MicrosoftDocs/Virtualization-Documentation/live/hyperv-tools/Convert-WindowsImage/Convert-WindowsImage.ps1 `
        -OutFile "$($LabConfig.Root)\Tools\convert-windowsimage.ps1"
    }
    catch {
        WriteError "`t Failed to download convert-windowsimage.ps1"
    }
}
WriteInfoHighlighted "Testing convert-windowsimage presence in \Tools\ToolsVHD"
    if (!(Test-Path "$($LabConfig.Root)\Tools\ToolsVHD\convert-windowsimage.ps1"))
    {
        Copy-Item "$($LabConfig.Root)\Tools\convert-windowsimage.ps1" "$($LabConfig.Root)\Tools\ToolsVHD\convert-windowsimage.ps1"
        WriteSuccess "`t convert-windowsimage.ps1 copied into \Tools\ToolsVHD"
    }
    else {
        WriteSuccess "`t convert-windowsimage.ps1 already exists in \Tools\ToolsVHD"
    }

# Check Hyper-V Feature on HOST
WriteInfoHighlighted "Checking if Hyper-V is installed"
if ((Get-WmiObject -class Win32_OperatingSystem).Caption -contains "Server")
{
    WriteInfo "`tThis machine is running on Server based Windows edition"
    if ((Get-WindowsFeature Microsoft-Hyper-V,Microsoft-Hyper-V-Management-PowerShell).State -eq "Enabled")
    {
        WriteSuccess "`tHyper-V and Management Tools is installed"
    }
    else {
        WriteError "`tHyper-V isn't installed, Installing Hyper-V ..."
        try {
            Install-WindowsFeature Microsoft-Hyper-V,Microsoft-Hyper-V-Management-PowerShell
        }
        catch {
            WriteError "`tInstall Hyper-V failed"
        }        
    }
}
else {
    WriteInfo "`tThis machine is running on Clinet based Windows edition"
    if((Get-WindowsOptionalFeature -online -featurename Microsoft-Hyper-V).state -eq "Enabled")
    {
        WriteSuccess "`tHyper-V and Management Tools is insalled"
    }
    else
    {
        WriteError "`tHyper-V isn't installed, Installing Hyper-V ..."
        try
        {
            Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
        }
        catch
        {
            WriteError "`tInstall Hyper-V failed"
        }        
    }    
}

#Check vSwitch on Host
WriteInfoHighlighted "Getting vSwitch ..."
$vmSwitch = Get-VMSwitch
$vmSwitchCount = $vmSwitch.Count
if ($vmSwitch)
{
    WriteInfo "`t There are totally $vmSwitchCount Virtual Switch found"
    $vmSwitch | Format-Table -AutoSize
}
else {
    
    WriteInfo "`t Getting Physical NetAdapter"
    $pNic = Get-NetAdapter -Status "Up" -Physical
    WriteInfo "`t Creating virtual Switch - external"
    New-VMSwitch -Name "Lab" -NetAdapterName $pNIC[0].Name
    WriteInfo "`t Creating virtual Switch for Storage network"
    New-VMSwitch -Name "Storage" -SwitchType Internal
}

#Finishing
WriteInfo "Script Finished at $(Get-Date) and took $(((Get-date) - $startDatetime).TotalSeconds) Seconds"
Stop-Transcript
#endregion

#region ParentDisk Check and Generater
#Start Log
Start-Transcript -Path "$($LabConfig.Root)\ParentDisks.log"
$StartParentVHDDateTime = Get-Date
WriteInfo "Starting Create Parent Disks at $StartParentVHDDateTime"


function Convert-ISO2VHD{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ISOFullName,
        [Parameter(Mandatory=$true)]
        [int]
        $ImageIndex,
        [Parameter(Mandatory=$true)]
        [string]
        $VHDPath,
        [Parameter(Mandatory=$true)]
        [string]
        $VHDName,
        [Parameter(Mandatory=$true)]
        [int64]
        $VHDSize
    )
    if(Test-Path $ISOFullName)
    {
        WriteInfoHighlighted "Find ISO File $ISOFullName"
        WriteInfoHighlighted "Converting ISO Image to VHD Disks"
        $iso = Mount-DiskImage $ISOFullName -PassThru
        $isoDriverLetter = (Get-Volume -DiskImage $iso).DriveLetter
    }
    else {
        WriteError "The ISO File $ISOFullName doesn't exists, please dobule check"
    }
    WriteInfoHighlighted "Loading convert-WindowsImage.ps1 ..."
    . "$($LabConfig.Root)\tools\convert-windowsimage.ps1"
    
    if (!(Test-Path "$($isoDriverLetter):\sources\install.wim"))
    {
        WriteError "Install.wim no found in $($isoDriverLetter):\"
        WriteInfoHighlighted "Dismounting ISO file $ISOFullName"
        if ($iso -ne $null)
        {
            $iso | Dismount-DiskImage
        }
    }
    else {
        try {
            WriteInfo "Found install.wim file in $($isoDriverLetter):\"
            WriteInfo "Getting Image information from $($isoDriverLetter):\sources\install.wim"
            $images= Get-WindowsImage -ImagePath "$($isoDriverLetter):\sources\install.wim"
            foreach($image in $images)
            {
                WriteInfo ($image.ImageIndex.toString() + " - " + $image.ImageName)
            }            
            Convert-WindowsImage -SourcePath "$($isoDriverLetter):\sources\install.wim" -Edition $ImageIndex -VHDPath  "$VHDPath\$VHDName" `
            -SizeBytes $VHDSize -VHDFormat VHDX -Disklayout UEFI            
        }
        catch {
            WriteError $_.Exception.Message
        }
        Finally{
            $iso | Dismount-DiskImage
        }        
    }
}
#grab all parent disks 
$ParentDisks = (Get-ChildItem "$($LabConfig.VHDStore)\ParentDisks" -ErrorAction SilentlyContinue).Name

if($ParentDisks -eq $null)
{
    # 1 : Server 2016 Standard
    # 2 : Server 2016 Standard GUI
    # 3 : Server 2016 DataCenter
    # 4 : Server 2016 DataCenter GUI
    WriteInfo "There is nothing in VDHStore $($LabConfig.VHDStore)\ParentDisks"
    WriteInfo "Creating Parent disks in $($LabConfig.VHDStore)\ParentDisks"
    #$Win2K6ISO = Get-ChildItem -Path $($LabConfig.ISOStore) -Recurse "en_windows_server_2016_vl_x64_dvd_11636701.iso"
    $Win2K6ISO = Get-FileinMultiPath $($LabConfig.ISOStore) $($LabConfig.Win2K6VL)
    Convert-ISO2VHD -ISOFullName $Win2K6ISO -ImageIndex 3 -VHDPath "$($LabConfig.VHDStore)\ParentDisks" -VHDName "Win2016_DC_Core_G2.vhdx" -VHDSize 30GB
    Convert-ISO2VHD -ISOFullName $Win2K6ISO -ImageIndex 4 -VHDPath "$($LabConfig.VHDStore)\ParentDisks" -VHDName "Win2016_DC_G2.vhdx" -VHDSize 60GB
}
else
{
    WriteInfo "There are $($ParentDisks.Length) Perents Disks exists in $($LabConfig.VHDStore)\ParentDisks"
    foreach($d in $ParentDisks)
    {
        WriteInfo $d
    }    
}
WriteInfo "Script Finished at $(Get-Date) and took $(((Get-date) - $StartParentVHDDateTime).TotalSeconds) Seconds"
Stop-Transcript
#endregion

#region Unattend part

function CreateUnattendFile{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ComputerName,
        [Parameter(Mandatory=$true)]
        [string]
        $AdminPassword,        
        [Parameter(Mandatory=$true)]
        [string]
        $TimeZone,
        [Parameter(Mandatory=$false)]
        [boolean]
        $JoinDomain
    )
    if (Test-Path "$LabConfig.Root\unattend.xml")
    {
        Remove-Item "$LabConfig.Root\unattend.xml"
    }
    $unattendFile = New-Item "$($LabConfig.Root)\unattend.xml" -ItemType File
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

#Load variables from LabConfig


$UnattendedJoin = $xmlUnattend.unattend.settings.component | Where-Object {$_.Name -eq "Microsoft-Windows-UnattendedJoin"}
$UnattendedJoin.Identification.Credentials.Domain = $($LabConfig.DomainNetbiosName)
$UnattendedJoin.Identification.Credentials.Password = $($LabConfig.AdminPassword)
$UnattendedJoin.Identification.Credentials.Username = $($LabConfig.DomainAdmin)
$UnattendedJoin.Identification.JoinDomain = $($LabConfig.DomainName)

# Specialize - Microsoft-Windows-Shell-Setup
$UnattendedSpecShellSetup = $xmlUnattend.unattend.settings.component


    $xmlUnattend.Save($unattendFile)
    Return $unattendFile
    }
#regionend

#region Deploy DC
WriteInfo "Starting Deplooy DomainController"
WriteInfo "`tGetting DC's information from Variable"
$DCMetadata = $LabConfig.VMs | Where-Object {$_.MachineType -eq "DomainController"}
WriteInfo "`tINFO: $DCMetadata.VMName"
WriteInfo "`tINFO: $DCMetadata.CpuCores"
WriteInfo "Create unattend file"
$TimeZone = (Get-TimeZone).id
$uaf = CreateUnattendFile -ComputerName $DCMetadata.VMName -AdminPassword "P@ssword1!" -TimeZone $TimeZone -JoinDomain $true
