$LabConfig = @{Root = "$home\SCLAB"; 
                DomainAdmin = 'Administrator';
                AdminPassword = 'P@ssword1!';
                Prefix = 'SC-';
                SwitchName = 'Lab';
                DCEdition = '4';
                DomainNetbiosName = "SCLABDemo";
                DomainName = "SCLABDemo.INFRA.CORP";
                VHDTemplates = @{
                    ServerDCGUIVHD = "Win2016_DC_G2.vhdx";
                    ServerDCCoreVHD = "Win2016_DC_Core_G2.vhdx";
                    }                
                TimeZone = "China Standard Time";
                VHDStore = "D:;F:";
                ISOStore = "D:;E:\Software\ISO;D:\Databank\Software\ISO";
                Win2K6VL = "en_windows_server_2016_vl_x64_dvd_11636701.iso";
                VMHome = "D:\VMs;F:\VMs";
                VMs = @()}

#Add DC's info
$LabConfig.VMs += @{
    VMName = "SCLABDC01"; 
    Role="DomainController"; 
    ParentVHD = "Win2016_DC_G2.vhdx"; 
    OSVHDSize = 100GB; 
    MemoryStartupBytes = 2GB; 
    CpuCores = 4;
    NIC0 =@{
        Switch = "External";
        DHCP = "Enabled"}
    NIC1 =@{
        Switch = "Lab"; 
        IPAddr = "192.168.1.11"; 
        PrefixLength = "24"; 
        GateWay = "192.168.1.1"; 
        DNS = "192.168.1.11"}    
    }
$LabConfig.VMs += @{
    VMName = "SCWAC"; 
    Role = "WindowsAdminCenter"; 
    ParentVHD = "Win2016_DC_G2.vhdx"; 
    OSVHDSize = 100GB; 
    MemoryStartupBytes = 4GB; 
    CpuCores =4; 
    NIC0 = @{
        Switch = "Lab"; 
        IPAddr = "192.168.1.12"; 
        PrefixLength = "24"; 
        GateWay = "192.168.1.1"; 
        DNS = "192.168.1.11"}
    NIC1 = @{
        Switch = "External";
        DHCP = "Enabled"}
    }
1..4 | ForEach-Object {$VMNames="SOFS0"; $LabConfig.VMs += @{ VMName = "$VMNames$_" ; Role = "ScaleOutFileServer" ;`
                        ParentVHD = "Win2016_DC_Core_G2.vhdx"; OSVHDSize = 50GB; MemoryStartupBytes = 2GB; CpuCores = 4; SSDNumber = 6; SSDSize = 800GB;`
                        HDDNumber = 12; HDDSize = 4TB; NIC0 = @{Switch = "Lab"; DHCP = "Enabled"};NIC1 = @{Switch = "Cluster"; DHCP = "Enabled"}}}
1..4 | ForEach-Object {$VMNames="SCHOST0"; $LabConfig.VMs += @{ VMName = "$VMNames$_"; Role = "Hyper-V-Host";`
                        ParentVHD = "Win2016_DC_Core_G2.vhdx"; OSVHDSize = 50GB; MemoryStartupBytes = 2GB; CpuCores = 4; SSDNumber =0; SSDSize = 800GB;`
                        HDDNumber = 0; HDDSize = 4TB; NIC0 = @{Switch = "Lab"; DHCP = "Enabled"};NIC1 = @{Switch = "Cluster"; DHCP = "Enabled"}}}

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
function GetFirstFileItem {
    param (
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [string]
        $Path,
        [Parameter(Mandatory = $true)]
        [string]
        $FileName
    )
    foreach ($p in $Path.Split(";"))
    {
        if(Test-Path $p)
        {
            $f = Get-Item $p\$FileName -ErrorAction SilentlyContinue
            if($f -ne $null)
            {
                return $f
            }
            else
            {
                WriteError "Cannot Find file $FileName in $p"    
            }            
        }
        else
        {
            WriteError "The given path $Path doesn't exists!"    
        }
    }    
}
function CreateVHDTemplate{
   param(
       # Parameter help description
       [Parameter(Mandatory = $true)]
       [string]
       $Path,
       # Parameter help description
       [Parameter(Mandatory = $true)]
       [string]
       $TemplateName,
       # Parameter help description
       [Parameter(Mandatory = $false)]
       [string]
       $VHDSize
   ) 
   if(Test-Path $Path)
   {
       # 1 : Server 2016 Standard
       # 2 : Server 2016 Standard GUI
       # 3 : Server 2016 DataCenter
       # 4 : Server 2016 DataCenter GUI       
       WriteInfo "Creating VHD Template File $TemplateName in $Path"
       #$Win2K6ISO = Get-ChildItem -Path $($LabConfig.ISOStore) -Recurse "en_windows_server_2016_vl_x64_dvd_11636701.iso"
       #$Win2K6ISO = Get-FileinMultiPath $($LabConfig.ISOStore) $($LabConfig.Win2K6VL)
       #$Win2K6ISO = Get-ChildItem -Path $p -Recurse $($LabConfig.Win2K6VL)
       $Win2K6ISO = GetFirstFileItem -Path $($LabConfig.ISOStore) -FileName $($LabConfig.Win2K6VL)
       if (Test-Path $Win2K6ISO)
       {
           #Convert-ISO2VHD -ISOFullName $Win2K6ISO -ImageIndex 3 -VHDPath "$($LabConfig.VHDStore)\ParentDisks" -VHDName "Win2016_DC_Core_G2.vhdx" -VHDSize 30GB
           #Convert-ISO2VHD -ISOFullName $Win2K6ISO -ImageIndex 4 -VHDPath "$($LabConfig.VHDStore)\ParentDisks" -VHDName "Win2016_DC_G2.vhdx" -VHDSize 60GB
           switch ($TemplateName) {
                "Win2016_STD_Core_G2.vhdx" { $imageIndex = 1 }
                "Win2016_STD_G2.vhdx" { $imageIndex = 2 }
                "Win2016_DC_Core_G2.vhdx" { $imageIndex = 3 }
                "Win2016_DC_G2.vhdx.vhdx" { $imageIndex = 4 }
               Default { $imageIndex = 4}
           }
           if ($VHDSize -eq $null)
           {
               $VHDSize = "60GB"
           }

           Convert-ISO2VHD -ISOFullName $Win2K6ISO -ImageIndex $imageIndex -VHDPath $Path -VHDName $TemplateName -VHDSize $VHDSize
           exit
       }
       else
       {
           WriteErrorAndExit "Cannot find $Win2k6ISO in $($LabConfig.ISOStore)"
       }         
   }
   else
   {
       WriteErrorAndExit "The given path $Path doesn't exists!"
         
   }
}

function GetVHDTemplate{
    param(
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [string]
        $Path,
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [string]
        $TemplateName
    )
    foreach ($p in $Path.Split(";"))
    {
        $freeSpace = (Get-Item $p).PSDrive.Free/1GB
        if ($freeSpace -gt 50)
        {
            if (!(Test-Path "$p\ParentDisks"))
            {
                New-Item -ItemType Directory -Path "$p\ParentDisks"
            }
            $t = GetFirstFileItem -Path "$p\ParentDisks" -FileName $TemplateName
            if($t -ne $null)
            {
                WriteInfo "Find Template File $TemplateName";
                return $t
            }
            else
            {
                WriteError "Cannot find $TemplateName in given path $p"                
                return CreateVHDTemplate -Path "$p\ParentDisks" -TemplateName $TemplateName -VHDSize $VMMetadata.OSVHDSize
            }
        }
        else
        {
            WriteError "Free Disk Space is insufficient in $p, try next path...!"  
        }
    }
}

function GetVMHome
{
    foreach($p in $($LabConfig.VMHome).Split(";"))
    {
        if(!(Test-Path $p))
        {
            $v = New-Item -ItemType Directory -Path $p -ErrorAction SilentlyContinue
            $freeSpace = (Get-Item $p -ErrorAction SilentlyContinue).PSDrive.Free/1GB
            if ($v -ne $null)
            {
                if ($freeSpace -gt 100)
                {
                    return $v.FullName
                    exit
                }
                else
                {
                    WriteError "VMHome error: Free Disk Space is insufficient in $p, try next part...!"
                }                
            }
            else
            {
                WriteError "The given path $p inaccessible, try next part..."
            }
        }
        else
        {
            $v = Get-Item $p -ErrorAction SilentlyContinue
            $freeSpace = $v.PSDrive.Free/1GB
            if ($freeSpace -gt 100)
            {
                return $v.FullName
                exit
            }
            else
            {
                WriteError "VMHome error: Free Disk Space is insufficient in $p, try next part...!"
            }     
        }
    }    
}
function BuildVM
{
    param(
        # Parameter help description
        [Parameter(Mandatory=$true)]
        [hashtable]
        $VMMetadata
    )
    Start-Transcript -Path "$($LabConfig.Root)\$($VMMetadata.VMName)_Deployment.log"
    $dtVMDeployStart = Get-Date
    WriteInfo "The virtual machine deployment started at - $dtVMDeployStart"
    
    # extract variable from $VMMetadata hashtable
    $vmName = $VMMetadata.VMName
    $vmServerRole = $VMMetadata.Role
    $vmParentVHD = $VMMetadata.ParentVHD
    #$VMParentVHDFullName = "$($LabConfig.VHDStore)\ParentDisks\$vmParentVHD"
    $vmParentVHDFullName = GetVHDTemplate -Path $($LabConfig.VHDStore) -TemplateName $vmParentVHD
    #$vmHome = "$($LabConfig.VMHome)\$vmName"
    $vmHome = GetVMHome
    $vmHome += "\" + $vmName
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
    $vmSetIPScriptFile = CreateSetIPScriptFile -VMMetadata $VMMetadata

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
            [System.Array]
            $ScriptFiles,
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
            foreach ($f in $ScriptFiles)
            {
                WriteInfo "Injecting $f to $VHDFile"
                Copy-Item $f.FullName $dst
                WriteSuccess "Injected $f to $VHDFile"
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
    $vmScriptFiles = Get-ChildItem $($LabConfig.Root) *.ps1
    InjectVHD -UnattendFile $vmUaf -ScriptFiles $vmScriptFiles -VHDFile $vmOSVhdFullName

    # code block for VM create
    try
    {
        $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
        if ($vm -eq $null)
        {
            $vm = New-VM -Name $vmName -MemoryStartupBytes $vmMemoryStartupBytes -SwitchName $($VMMetadata.NIC0.switch) -Path $vmHome -Generation 2 -VHDPath $vmOSVhdFullName
            WriteInfo "The Deployment of Virtual Machine $vmName Successed"
            $vm | Set-VM -ProcessorCount $vmCpuCores -CheckpointType Disabled
            
            if($VMMetadata.Role -eq "Hyper-V-Host")
            {
                $vm | Set-VMProcessor -ExposeVirtualizationExtensions $true
            }
            
            $vm | Get-VMNetworkAdapter | Rename-VMNetworkAdapter -NewName $($VMMetadata.NIC0.switch)

            # Add 2rd NIC as cluster network if required
            if ($VMMetadata.NIC1 -ne $null)
            {
                $vm | Add-VMNetworkAdapter -Name $($VMMetadata.Nic1.switch) -SwitchName $($VMMetadata.Nic1.switch)
            }
            

            WriteInfo "Attaching $vmOSVhdFullName to Virtual Machine $vmName"
            Add-VMHardDiskDrive -VMName $vmName -ControllerType SCSI -Path $vmOSVhdFullName -ErrorAction SilentlyContinue

            WriteInfo "Attached $vmOSVhdFullName to Virtual Machine $vmName"

            # Create VHDs for SSD and HDDs then attach to VM
            Attach-VhdToVM -VMMetadata $VMMetadata
            Start-VM -Name $vmName
        }
        else
        {
            WriteInfo "Virtual Machine $vmName already exists on Host"
        }    
    }
    catch
    {
        WriteError "The deployment of Virtual Machine $vmName failed."
        Stop-Transcript
        WriteErrorAndExit $_.Exception.Message
    }
    WriteInfo "Script Finished at $(Get-Date) and took $(((Get-date) - $dtVMDeployStart).TotalSeconds) Seconds"
    Stop-Transcript
    
}

function CreateUnattendFile
{
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
    #
    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/
    #
    $unattendFile = New-Item "$($LabConfig.Root)\unattend.xml" -ItemType File
    $xmlUnattend = [xml]@"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <WindowsDeploymentServices>
                <Login>
                    <Credentials>
                        <Domain></Domain>
                        <Password></Password>
                        <Username></Username>
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
                    <Value>UABAAHMAcwB3AG8AcgBkADEAIQBQAGEAcwBzAHcAbwByAGQA</Value>
                    <PlainText>false</PlainText>
                </Password>
                <Enabled>true</Enabled>
                <LogonCount>2</LogonCount>
                <Username>administrator</Username>
            </AutoLogon>
            <ComputerName>%ComputerName%</ComputerName>
        </component>       
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <UserAccounts>
                <AdministratorPassword>
                    <Value>UABAAHMAcwB3AG8AcgBkADEAIQBBAGQAbQBpAG4AaQBzAHQAcgBhAHQAbwByAFAAYQBzAHMAdwBvAHIAZAA=</Value>
                    <PlainText>false</PlainText>
                </AdministratorPassword>
            </UserAccounts>            
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
            </OOBE>
            <TimeZone>China Standard Time</TimeZone>
            <RegisteredOwner>SCLAB</RegisteredOwner>
            <RegisteredOrganization>SCLAB</RegisteredOrganization>
            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add">
                    <CommandLine>cmd /c call C:\SetIP.ps1</CommandLine>
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
    "Hyper-V-Host" {$cmdline = "PowerShell.exe C:\Hyper-V-Host_Deploy.ps1"}

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
. C:\SetIP.ps1
Install-WindowsFeature -Name DHCP,AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName $($Labconfig.DomainName) -DomainNetBIOSName $($Labconfig.DomainNetbiosName) -ForestMode Win2012 -DomainMode Win2012 -InstallDNS -SkipAutoConfigureDNS -SafeModeAdministratorPassword (ConvertTo-SecureString -string "P@ssword" -AsPlainText -Force) -Force
Add-DhcpServerInDC
Add-DhcpServerv4Scope -Name "Lab Network" -StartRange "192.168.1.200" -EndRange "192.168.1.250" -SubnetMask "255.255.255.0"
Add-DhcpServerv4Scope -Name "Cluster Network" -StartRange "10.10.10.200" -EndRange "10.10.10.250" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ScopeId "192.168.1.0" -DnsServer $($LabConfig.VMs[0].Nic1.IPAddr) -Router 192.168.1.1
Set-DhcpServerv4OptionValue -ScopeId "10.10.10.0" -DnsServer $($LabConfig.VMs[0].Nic1.IPAddr) -Router 10.10.10.1
Set-DhcpServerv4Binding -InterfaceAlias $($LabConfig.VMs[0].Nic1.Switch)
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
. C:\SetIP.ps1
Install-WindowsFeature -Name FileAndStorage-Services,File-Services,FS-FileServer,RSAT,RSAT-Role-Tools,RSAT-Hyper-V-Tools
`$wacUrl = "http://aka.ms/WACDownload"
`$wacMsi = "C:\WACInstaller.msi"
(New-Object System.Net.WebClient).DownloadFile(`$wacUrl,`$wacMsi)
msiexec /i `$wacMsi /qn /L*v C:\WACInstall.txt SME_PORT=443 SSL_CERTIFICATE_OPTION=generate
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
. C:\SetIP.ps1
Install-WindowsFeature -Name File-Services,Failover-Clustering -IncludeManagementTools
"@
        Set-Content -Path $SOFSDeployScriptFile -Value $SOFSDeployScriptFileContent
        return $SOFSDeployScriptFile
    }
    if($Role -eq "Hyper-V-Host")
    {
        $HyperVHostDeployScriptFile = "$($Labconfig.Root)\Hyper-V-Host_Deploy.ps1"
        if (Test-Path $HyperVHostDeployScriptFile)
        {
            Remove-Item $HyperVHostDeployScriptFile
        }
        $HyperVHostDeployScriptFileContent = @"
. C:\SetIP.ps1
Install-WindowsFeature -Name Hyper-V,File-Services,Failover-Clustering -IncludeManagementTools
"@
        Set-Content -Path $HyperVHostDeployScriptFile -Value $HyperVHostDeployScriptFileContent
        return $HyperVHostDeployScriptFile
    }
}

function CreateSetIPScriptFile
{
    param(
        # Parameter help description        
        [Parameter(Mandatory = $true)]
        [hashtable]
        $VMMetadata
    )
    $SetIPScriptFile = "$($LabConfig.Root)\SetIP.ps1"
    if(Test-Path $SetIPScriptFile)
    {
        Remove-Item $SetIPScriptFile
    }

    # If Nic0 require Static IP
    if (($VMMetadata.Nic0.DHCP -eq "Disabled") -or ($VMMetadata.Nic0.IPAddr -ne $null))
    {
        $SetIPScriptFileContent = @"
`$nics = Get-NetAdapter | Sort-Object -Property MacAddress
New-NetIPAddress -InterfaceIndex `$nics[0].ifIndex -IPAddress $($VMMetadata.Nic0.IPAddr) -DefaultGateway $($VMMetadata.Nic0.Gateway) -PrefixLength $($VMMetadata.Nic0.PrefixLength)
`$nics[0] | Rename-NetAdapter -NewName $($VMMetadata.Nic0.Switch)
`$nics[0] | Set-DnsClientServerAddress -ServerAddresses ("$($VMMetadata.Nic0.DNS)")`n
"@
    }
    else
    {
        $SetIPScriptFileContent = @"
`$nics = Get-NetAdapter | Sort-Object -Property MacAddress
`$nics[0] | Set-NetIpInterface -Dhcp Enabled
`$nics[0] | Rename-NetAdapter -NewName $($VMMetadata.Nic0.Switch)`n
"@      
    }
    
    # If Nic1 require Static IP    
    if (($VMMetadata.NIC1.DHCP -eq "Disabled") -or ($VMMetadata.NIC1.IPAddr -ne $null))
    {
        $SetIPScriptFileContent += @"

New-NetIPAddress -InterfaceIndex `$nics[1].ifIndex -IPAddress $($VMMetadata.NIC1.IPAddr) -DefaultGateway $($VMMetadata.NIC1.Gateway) -PrefixLength $($VMMetadata.NIC1.PrefixLength)
`$nics[1] | Rename-NetAdapter -NewName $($VMMetadata.Nic1.Switch) -ErrorAction SilentlyContinue      
"@
    }
    else
    {
        $SetIPScriptFileContent += @"

`$nics[1] | Set-NetIpInterface -Dhcp Enabled
`$nics[1] | Rename-NetAdapter -NewName $($VMMetadata.Nic1.Switch)
"@      
    }
    Set-Content -Path $SetIPScriptFile -Value $SetIPScriptFileContent
    return $SetIPScriptFile
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
$vms = Get-VMSwitch
$extSwitch = $vms | Where-Object {($_.SwitchType -eq "External") -and ($_.Name -eq "External")}
$labSwitch = $vms | Where-Object {($_.SwitchType -eq "Internal") -and ($_.Name -eq "Lab")}
$cluSwitch = $vms | Where-Object {($_.SwitchType -eq "Internal") -and ($_.Name -eq "Cluster")}

if ($extSwitch)
{
    WriteInfo "`t Listing External vSwitch which for VM external access"
    $extSwitch | Format-Table -AutoSize
}
else {
    
    WriteInfo "`t Getting Physical NetAdapter"
    $pNic = Get-NetAdapter -Physical | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
    WriteInfo "`t Creating virtual Switch - external"
    $extSwitch = New-VMSwitch -Name "External" -NetAdapterName $pNIC.Name -AllowManagementOS $true
    $extSwitch | Format-Table -AutoSize
}

if($labSwitch)
{
    WriteInfo "`t Listing Internal vSwtich for Lab"
    $labSwitch | Format-Table -AutoSize
}
else
{
    WriteInfo "`t Creating vSwitch for Lab network"
    $labSwitch = New-VMSwitch -Name "Lab" -SwitchType Internal
    $labSwitch | Format-Table -AutoSize
}

if ($cluSwitch)
{
    WriteInfo "`t Listing Internal vSwitch for Cluster"
    $cluSwitch | Format-Table -AutoSize
}
else
{
    WriteInfo "`t Creating vSwitch for Cluster network"
    $cluSwitch = New-VMSwitch -Name "Cluster" -SwitchType Internal
    $cluSwitch | Format-Table -AutoSize
}

#Finishing
WriteInfo "Script Finished at $(Get-Date) and took $(((Get-date) - $startDatetime).TotalSeconds) Seconds"
Stop-Transcript
#endregion

#region Deploy Domain Controller
WriteInfo "Starting Deploy Domain Controller"
WriteInfo "`t Getting Domain Controller information from Variable"
$DCMetadata = $LabConfig.VMs | Where-Object {$_.Role -eq "DomainController"}
foreach ($dc in $DCMetadata)
{
    BuildVM -VMMetadata $dc
}
WriteInfo "Slepping 300 seconds wait Domain Controller getting online!"
#sleep -Seconds 300
#endregion

$wacMetadata = $LabConfig.VMs | Where-Object {$_.Role -eq "WindowsAdminCenter"}
foreach ($wac in $wacMetadata)
{
    BuildVM -VMMetadata $wac
}

#region Deploy Scale-Out File Server
WriteInfo "Starting Deploy Scale-Out File Server"
WriteInfo "`tGetting Scale-Out File Servers information from Variable"
$SOFSMetadata = $LabConfig.VMs | Where-Object {$_.Role -eq "ScaleOutFileServer"}
foreach($SOFS in $SOFSMetadata)
{
    BuildVM -VMMetadata $SOFS
}
#endregion

$HyperVHostMetadata = $LabConfig.VMs | Where-Object {$_.Role -eq "Hyper-V-Host"}
foreach($vhost in $HyperVHostMetadata)
{
    BuildVM -VMMetadata $vhost
}

