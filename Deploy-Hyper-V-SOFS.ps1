$LabConfig = @{Root = "$home\SCLAB"; DomainAdmin = 'LabAdmin';AdminPassword = 'P@ssword1!';Prefix = 'SC-'; `
                SwitchName = 'Lab';DCEdition = '4';AdditionalNetworksConfig=@(); DomainNetbiosName = "SCLABDemo";`
                DomainName = "SCLABDemo.INFRA.CORP"; ServerDCGUIVHD = "Win2016_DC_G2.vhdx";`
                ServerDCCoreVHD = "Win2016_DC_Core_G2.vhdx"; TimeZone = "China Standard Time"; VHDStore = "F:";`
                ISOStore = "E:\Software\ISO;D:\Databank\Software\ISO"; Win2K6VL = "en_windows_server_2016_vl_x64_dvd_11636701.iso";`
                VMHome = "F:\VMs";
                VMs = @()}

#Add DC's info
$LabConfig.VMs += @{VMName = "SCLABDC01"; Role="DomainController"; ParentVHD = "Win2016_DC_Core_G2.vhdx"; OSVHDSize = 100GB; MemoryStartupBytes = 2GB; CpuCores = 4;}
$LabConfig.VMs += @{VMName = "SCWAC"; Role = "WindowsAdminCenter"; ParentVHD = "Win2016_DC_G2.vhdx"; OSVHDSize = 100GB; MemoryStartupBytes = 4GB; CpuCores =4; Nic0Switch = "Lab"; Nic1Switch = "Cluster"}
1..4 | ForEach-Object {$VMNames="SOFS0"; $LabConfig.VMs += @{ VMName = "$VMNames$_" ; Role = "ScaleOutFileServer" ;`
                        ParentVHD = "Win2016_DC_Core_G2.vhdx"; OSVHDSize = 50GB; MemoryStartupBytes = 2GB; CpuCores = 4; SSDNumber = 6; SSDSize = 800GB;`
                        HDDNumber = 12; HDDSize = 4TB}}
1..4 | ForEach-Object {$VMNames="SCHOST0"; $LabConfig.VMs += @{ VMName = "$VMNames$_"; Role = "Hyper-VHost";`
                        ParentVHD = "Win2016_DC_Core_G2.vhdx"; OSVHDSize = 50GB; MemoryStartupBytes = 2GB; CpuCores = 4; SSDNumber =0; SSDSize = 800GB;`
                        HDDNumber = 0; HDDSize = 4TB}}

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

#region Helper functions
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


# Add remote server to TrustedHosts on local computer.
function Prepare-PSRemoting {
    param(
        [Parameter(Mandatory)]
        [string]
        $RemoteHost
    )
    WriteInfo "Strating WinRM Service"
    Start-Service WinRM
    winrm quickconfig
    $WinRMSrv = Get-Service WinRM
    WriteInfo "The WinRM Service is in $($WinRMSrv.Status) Status"
    $curHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts).Value
    if ($curHosts -eq "")
    {
        WriteInfo "There are not any TrustedHosts on this machine."
        Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$RemoteHost" -Force
    }
    elseif($curHosts -ne $RemoteHost) {
        Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$curHosts,$RemoteHost" -Force
    }   
    
    $curHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts).Value
    WriteInfo "The Current Trusted Hosts is $curHosts"
     
    
}

function BuildVM
{
    param(
        # Parameter help description
        [Parameter(Mandatory=$true)]
        [hashtable]
        $VMMetadata
    )
    # extract variable from $VMMetadata hashtable
    $vmName = $VMMetadata.VMName
    $vmServerRole = $VMMetadata.Role
    $vmParentVHD = $VMMetadata.ParentVHD
    $VMParentVHDFullName = "$($LabConfig.VHDStore)\ParentDisks\$vmParentVHD"
    $vmHome = "$($LabConfig.VMHome)\$vmName"
    $vmCpuCores = $VMMetadata.CpuCores
    $vmMemoryStartupBytes = $VMMetadata.MemoryStartupBytes
    $vmOSVhd = "$vmName.vhdx"
    $vmOSVhdFullName = "$vmHome\$vmOSVhd"
    $vmOSVhdSizeGB = $VMMetadata.OSVHDSize
    $TimeZone = (Get-TimeZone).id
    $SSD_Count = $VMMetadata.SSDNumber
    $SSD_Size = $VMMetadata.SSDSize
    $HDD_Count = $VMMetadata.HDDNumber
    $HDD_Size = $VMMetadata.HDDSize
    $vmUaf = CreateUnattendFile -ComputerName $vmName -AdminPassword $($LabConfig.AdminPassword) -TimeZone $TimeZone -Role $vmServerRole -JoinDomain $true
    $vmFirstLogonScriptFile = CreateFirstLogonScriptFile -Role $vmServerRole

    # functions within BuildVM
    function CreateVHD
    {
        param(
            [Parameter(Mandatory = $true)]
            [string]
            $Path,
            [Parameter(Mandatory = $true)]
            [string]
            $VHDName,
            [Parameter(Mandatory = $true)]
            [int64]
            $Size
        )
        if (!(Test-Path "$Path\$VHDName"))
        {
            New-VHD -Path "$Path\$VHDName" -SizeBytes $Size
            WriteInfo "Created $VHDName in folder $Path"
        }
        else {
            WriteInfo "VHD $VHDName exists in in Folder $Path, skip creating."
        }
    }

    function InjectVHD
    {
        param(
            # Parameter help description
            [Parameter(Mandatory = $true)]
            [System.IO.FileSystemInfo]
            $UnattendFile,
            # Parameter help description
            [Parameter(Mandatory = $false)]
            [string]
            $ScriptFile,
            # Parameter help description
            [Parameter(Mandatory = $true)]
            [string]
            $VHDFile)

        try
        {
            WriteInfo "Copying unattend file to $VMOSVhd"
            WriteInfo "Mounting VHD File $VMOSVhd to file system"
            $v = Mount-VHD -Path $VHDFile -Passthru -ErrorAction SilentlyContinue | Get-Disk | Get-Partition | Get-Volume | Where-Object {$_.FileSystemType -eq "NTFS"}
            $dst = "$($v.DriveLetter):\"
            Copy-Item $UnattendFile $dst
            WriteSuccess "Copied unattend file $UnattendFile to $VHDFile"
            if (Test-Path $ScriptFile)
            {
                WriteInfo "Injecting $ScriptFile to $VHDFile"
                Copy-Item $ScriptFile $dst
                WriteSuccess "Injected $ScriptFile to $VHDFile"
            }
        }
        Catch
        {
            WriteError $_.Exception.Message
        }
        Finally
        {
            WriteInfo "Dismounting $VHDFile"
            Dismount-VHD $VHDFile -ErrorAction SilentlyContinue
            WriteInfo "Dismounted $VHDFile"
        }
    }     
    function Attach-VhdToVM
    {
        param
        (
            # Parameter help description
            [Parameter(mandatory = $true)]
            [hashtable]
            $VMMetadata
        )
        $vm =Get-VM -Name $vmName -ErrorAction SilentlyContinue
        if (!$vm)
        {
            WriteError "The Virtual Machine $vmName doesn't exist, please create that VM first."
            return -1
        }
        else
        {
            # Create SSD and HDD VHD files         
            if (($SSD_Count -eq "0") -or ($SSD_Count -eq $null))
            {
                WriteInfo "This VM doesn't require SSD Drivers"
            }
            else
            {
                WriteInfo "SSD Drivers = $SSD_Count"
                1..$SSD_Count | foreach-object{
                        $SSDName = "$vmName" + "_SSD_" + "$_.vhdx"
                        WriteInfo "Creating $SSDName in folder $vmHome"                        
                        $ssd = CreateVHD -Path $vmHome -VHDName $SSDName -Size $SSD_Size
                        #Add-VMHardDiskDrive -VMName $vmName -ControllerType SCSI -Path $ssd -ErrorAction SilentlyContinue
                        if($ssd -ne $null)
                        {
                            $vm | Add-VMHardDiskDrive -ControllerType SCSI -Path $ssd.Path -ErrorAction SilentlyContinue
                        }
                        
                    }
            }
            
            if (($HDD_Count -eq "0") -or ($HDD_Count -eq $null))
            {
                WriteInfo "This VM doesn't require HDD Drivers"
            }
            else
            {
                WriteInfo "HDD Drivers = $HDD_Count"
                1..$HDD_Count | ForEach-Object{
                    $HDDName = "$vmName" + "_HDD_" + "$_.vhdx"
                    WriteInfo "Creating $HDDName in folder $vmHome"
                    $hdd = CreateVHD -Path $vmHome -VHDName $HDDName -Size $HDD_Size
                    if($hdd -ne $null)
                    {
                        $vm | Add-VMHardDiskDrive -ControllerType SCSI -Path $hdd.Path -ErrorAction SilentlyContinue
                    }
                    
                }
            }
        }
    }
    # end fuctions

    WriteInfo "Starting Deploy $vmName"
    WriteInfo "Server role - $vmServerRole"
    WriteInfo "CPU Cores are - $vmCpuCores"
    WriteInfo "VM with RAM - $vmMemoryStartupBytes"
    WriteInfo "Parent VHD - $vmParentVHD"
    WriteInfo "VM Home folder - $vmHome"
    WriteInfo "VM OS Disk - $VMOSVhd"
    WriteInfo "VM OS VHD Size - $($VMOSVhdSizeGB/1GB) GB"
    WriteInfo "SSD Disks - $SSD_Count"
    WriteInfo "SSD Size  - $($SSD_Size/1GB) GB"
    WriteInfo "HDD Disks - $HDD_Count"
    WriteInfo "HDD Size  - $($HDD_Size/1GB) GB"


    # Create a different VHD file from parent VHD to resides OS
    WriteInfo "Starting Create a VHD file from parent disk - $vmParentVHDFullName"
    try
    {
        if(!(Test-Path $vmOSVhdFullName))
        {
            WriteInfo "Creating $vmOSVhd from $vmParentVHD"
            New-VHD -ParentPath $VMParentVHDFullName -Path $vmOSVhdFullName -SizeBytes $vmOSVhdSizeGB -Differencing
            WriteInfo "$vmOSVhdFullName created"
        }
        else
        {
            WriteInfo "$vmOSVhdFullName already exists"    
        }
    }
    catch
    {
        WriteError "Create $vmOSVhdFullName failed"
        WriteError $_.Exception.Message   
    }
    
    # Inject unattend and script files into vmOSVhd
    InjectVHD -UnattendFile $vmUaf -ScriptFile $vmFirstLogonScriptFile -VHDFile $vmOSVhdFullName

    # code block for VM create
    try
    {
        $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
        if ($vm -eq $null)
        {
            New-VM -Name $vmName -MemoryStartupBytes $vmMemoryStartupBytes -SwitchName "Lab" -Path $vmHome -Generation 2 -VHDPath $vmOSVhdFullName
            WriteInfo "The Deployment of Virtual Machine $vmName Successed"
            Set-VM -Name $vmName -ProcessorCount $vmCpuCores -CheckpointType Disabled

            # Add 2rd NIC as cluster network
            Add-VMNetworkAdapter -VMName $vmName -Name "Cluster" -SwitchName "Cluster"

            WriteInfo "Attaching $vmOSVhdFullName to Virtual Machine $vmName"
            Add-VMHardDiskDrive -VMName $vmName -ControllerType SCSI -Path $vmOSVhdFullName -ErrorAction SilentlyContinue

            WriteInfo "Attached $vmOSVhdFullName to Virtual Machine $vmName"
        }
        else
        {
            WriteInfo "Virtual Machine $vmName already exists on Host"
        }    
    }
    catch
    {
        WriteError "The deployment of Virtual Machine $vmName failed."
        WriteError $_.Exception.Message
    }
    # Create VHDs for SSD and HDDs then attach to VM
    Attach-VhdToVM -VMMetadata $VMMetadata
    Start-VM -Name $vmName
}

#endregion

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
$LabSwitch = Get-VMSwitch | Where-Object {($_.SwitchType -eq "External") -and ($_.Name -eq "Lab")}
$cluSwitch = Get-VMSwitch | Where-Object {($_.SwitchType -eq "Internal") -and ($_.Name -eq "Cluster")}

if ($LabSwitch)
{
    WriteInfo "`t Listing External vSwitch"
    $LabSwitch | Format-Table -AutoSize
}
else {
    
    WriteInfo "`t Getting Physical NetAdapter"
    $pNic = Get-NetAdapter -Physical | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
    WriteInfo "`t Creating virtual Switch - external"
    $LabSwitch = New-VMSwitch -Name "Lab" -NetAdapterName $pNIC.Name
}
if ($cluSwitch)
{
    WriteInfo "`t Listing Internal vSwitch"
    $cluSwitch | Format-Table -AutoSize
}
else
{
    WriteInfo "`t Creating virtual Switch for Cluster network"
    $cluSwitch = New-VMSwitch -Name "Cluster" -SwitchType Internal
    $cluSwitch | Format-Table -AutoSize
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
$ParentDisks = Get-ChildItem "$($LabConfig.VHDStore)\ParentDisks" -ErrorAction SilentlyContinue -Include "*.vhdx" -Recurse

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
    WriteInfo "There are $($ParentDIsks.Count) Perents Disks exists in $($LabConfig.VHDStore)\ParentDisks"
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
        [Parameter(Mandatory=$true)]
        [string]
        $Role,
        [Parameter(Mandatory=$false)]
        [boolean]
        $JoinDomain
    )
    if (Test-Path "$($LabConfig.Root)\unattend.xml")
    {
        Remove-Item "$($LabConfig.Root)\unattend.xml"
    }
    $unattendFile = New-Item "$($LabConfig.Root)\unattend.xml" -ItemType File
    $xmlUnattend = [xml]@"
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
                <JoinWorkgroup>%JoinWorkgroup%</JoinWorkgroup>
            </Identification>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <AutoLogon>
                <Password>
                    <Value>UABAAHMAcwB3AG8AcgBkAFAAYQBzAHMAdwBvAHIAZAA=</Value>
                    <PlainText>false</PlainText>
                </Password>
                <Enabled>true</Enabled>
                <Username>administrator</Username>
            </AutoLogon>
            <ComputerName>%ComputerName%</ComputerName>
        </component>       
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
            </OOBE>
            <TimeZone>China Standard Time</TimeZone>
            <RegisteredOwner>SCLAB</RegisteredOwner>
            <RegisteredOrganization>SCLAB</RegisteredOrganization>
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
if($JoinDomain) 
{
    $UnattendedJoin.Identification.JoinDomain = $($LabConfig.DomainName)
    $UnattendedJoin.Identification.JoinWorkgroup = ""
}
else
{
    $UnattendedJoin.Identification.JoinDomain = ""
    $UnattendedJoin.Identification.JoinWorkgroup = "WorkGroup"
}
# Specialize - Microsoft-Windows-Shell-Setup
$UnattendSpecialize = $xmlUnattend.unattend.settings | Where-Object {$_.pass -eq "specialize"}
$UnattendSpecializeShellSetup = $UnattendSpecialize.component | Where-Object {$_.Name -eq "Microsoft-Windows-Shell-Setup"}
$UnattendSpecializeShellSetup.ComputerName = $ComputerName

# oobeSystem - Microsoft-Windows-Shell-Setup
switch($Role)
{
    "DomainController" {$cmdline = "Powershell.exe C:\DCPromo.ps1"}
    "WindowsAdminCenter" {$cmdline = "Powershell.exe C:\WAC_Deploy.ps1"}
    "ScaleOutFileServer" {$cmdline = "PowerShell.exe C:\SOFS_Deploy.ps1"}
    "Hyper-VHost" {$cmdline = "PowerShell.exe C:\Hyper-VHost_Deploy.ps1"}

}

$Unattendoobe = $xmlUnattend.unattend.settings | Where-Object {$_.pass -eq "oobeSystem"}
$UnattendoobeWindowsShellSetup = $Unattendoobe.component | Where-Object {$_.Name -eq "Microsoft-Windows-Shell-Setup"}
$UnattendoobeWindowsShellSetup.FirstLogonCommands.SynchronousCommand.CommandLine = $cmdline

$xmlUnattend.Save($unattendFile)
Return $unattendFile
}

function CreateFirstLogonScriptFile
{
    param(
        # Parameter help description
        [Parameter(Mandatory=$true)]
        [string]
        $Role
    )
    if ($Role -eq "DomainController")
    {
        $DCPromoScriptFile = "$($LabConfig.Root)\DCPromo.ps1"
        if (Test-Path $DCPromoScriptFile)
        {
            Remove-Item $DCPromoScriptFile
        }
        $DCPromo = @"
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName $($Labconfig.DomainName) -DomainNetBIOSName $($Labconfig.DomainNetbiosName) -ForestMode Win2012 -DomainMode Win2012 -InstallDNS -SkipAutoConfigureDNS -SafeModeAdministratorPassword (ConvertTo-SecureString -string "P@ssword" -AsPlainText -Force) -Force
"@
        Set-Content -Path $DCPromoScriptFile -Value $DCPromo
        return $DCPromoScriptFile
    }
    if($Role -eq "WindowsAdminCenter")
    {
        $wacDeployScriptFile = "$($Labconfig.Root)\WAC_Deploy.ps1"
        if (Test-Path $wacDeployScriptFile)
        {
            Remove-Item $wacDeployScriptFile
        }
        $wacDeployScriptFileContent = @"
Install-WindowsFeature -Name FileAndStorage-Services,File-Services,FS-FileServer,RSAT,RSAT-Role-Tools,RSAT-Hyper-V-Tools
"@
        Set-Content -Path $wacDeployScriptFile -Value $wacDeployScriptFileContent
        return $wacDeployScriptFile
    }
    if($Role -eq "ScaleOutFileServer")
    {
        $SOFSDeployScriptFile = "$($Labconfig.Root)\SOFS_Deploy.ps1"
        if (Test-Path $SOFSDeployScriptFile)
        {
            Remove-Item $SOFSDeployScriptFile
        }
        $SOFSDeployScriptFileContent = @"
Install-WindowsFeature -Name File-Services,Failover-Clustering -IncludeManagementTools
"@
        Set-Content -Path $SOFSDeployScriptFile -Value $SOFSDeployScriptFileContent
        return $SOFSDeployScriptFile
    }
}

#endregion

#region Deploy Domain Controller
WriteInfo "Starting Deploy Domain Controller"
WriteInfo "`t Getting Domain Controller information from Variable"
$DCMetadata = $LabConfig.VMs | Where-Object {$_.Role -eq "DomainController"}
foreach ($dc in $DCMetadata)
{
    BuildVM -VMMetadata $dc
}
#endregion

$wacMetadata = $LabConfig.VMs | Where-Object {$_.Role -eq "WindowsAdminCenter"}
foreach ($wac in $wacMetadata)
{
    BuildVM -VMMetadata $wac
}

#region Deploy Scale-Out File Server
WriteInfo "Starting Deploy Scale-Out File Server"
WriteInfo "`tGetting Scale-Out File Servers information from Variable"
#$SOFSMetadata = $LabConfig.VMs | Where-Object {$_.Role -eq "ScaleOutFileServer"}
#foreach($SOFS in $SOFSMetadata)
#{
#    BuildVM -VMMetadata $SOFS
#}
#endregion

