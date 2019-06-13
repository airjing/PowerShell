# This script file will install Az PowerShell on local computers. It require elevated privileges.
# By Default, will Query all installed VM's information.
# https://docs.microsoft.com/en-us/powershell/azure/overview?view=azps-2.2.0

function Install-AzPowerShell
{
    if($PSVersionTable.PSVersion -lt "5.1.0.0")
    {
        Write-Error "Az PowerShell require PowerShell version 5.1"
        Exit
    }    
    $psGet = Get-Module -Name PowerShellGet -ListAvailable | Select-Object -First 1    
    if ($psGet.Version -lt "1.1.2.0")
    {
        Install-Module PowerShellGet -Force
    }
    else {
        Write-Host "The current PowerShellGet version is $($psGet.Version) not need to upgrade it."
    }
    
    # Step2
    # Install the Azure Resource Manager modules from the PowerShell Gallery
    # Answer 'Yes' or 'Yes to All' to continue with the installation.
    $AzureRM = Get-Module -Name AzureRM -ListAvailable | Select-Object -First 1
    if($AzureRM)
    {
        Write-Host "The AzureRM $AzureRMVersion has already installed."
        Write-Host "Recommend Uninstall AzureRM, then install module Az"
        Uninstall-AzureRm
    }    
    # Cross-platform Az module will replacing AzureRM. 
    # https://azure.microsoft.com/en-us/blog/azure-powershell-cross-platform-az-module-replacing-azurerm/
    # https://docs.microsoft.com/en-us/powershell/azure/migrate-from-azurerm-to-az?view=azps-1.0.0
    $Az = Get-InstalledModule -Name Az -AllVersions | Select-Object Name,Version
    if($Az)
    {
        Write-Host "The module Az has already installed, version is $($Az.Version)"
        Update-Module -Name Az
    }
    else {
        Install-Module -Name Az -AllowClobber
    }    
}

function Connect-Az{
    $az = Get-AzContext
    if(!$az)
    {
        Connect-AzAccount
    }
}
function Stop-VM
{
    Connect-Az
    Get-AzVM | Stop-AzVM -Force -AsJob | Wait-Job | Receive-Job
}
function Start-VM
{
    Connect-Az
    Get-AzVM | Start-AzVM -AsJob | Wait-Job | Receive-Job    
    Get-AzPublicIpAddress | Format-List -Property Name,ResourceGroupName,Location,IpAddress,ProvisioningState
}

function New-VM{
    $cred = get-credential -message "Enter the credential that will be used for new deployed VM"
    $vmName = "DemoVM1"
    $AzureRmVM = Get-AzureRmVM $vmName
    if (!$AzureRmVM)
    {
        New-AzVM -Name $vmName -credential $cred
    }
    else
    {
        Write-host "The VM $vmName has already deployed on Azure"
        "Name:" + $AzureRmVM.Name
        "ProvisionState:" + $AzureRmVM.ProvisioningState
        "StatusCode:" + $AzureRmVM.StatusCode
        "AdminUserName:" + $AzureRmVM.OSProfile.AdminUsername
        "Resource Group Name:" + $AzureRmVM.ResourceGroupName
        "Id:" + $AzureRmVM.ID
        "VmID:" + $AzureRmVM.VmID
        "Type:" + $AzureRmVM.Type
        "Location:" + $AzureRmVM.Location
        "LicenseType:" + $AzureRmVM.LicenseType
        "VmSize:" + $AzureRmVM.HardwareProfile.VmSize
        "Image Publisher:" + $AzureRmVM.StorageProfile.ImageReference.PUblisher
        "Image Offer:" + $AzureRmVM.StorageProfile.ImageReference.Offer
        "Image Sku:" + $AzureRmVM.StorageProfile.ImageReference.Sku
        "OS Type:" + $AzureRmVM.StorageProfile.OSDisk.OsType
        "DiskSizeGB:" + $AzureRmVM.StorageProfile.OSDisk.DiskSizeGB
        "StorageAccountType:" + $AzureRmVM.StorageProfile.OSDIsk.ManagedDisk.StorageAccountType
    }
    
    $rgs = Get-AzureRmResourceGroup | Select-Object ResourceGroupName,Location
    
    foreach ($rg in $rgs)
    {    
        Get-AzureRmResource | where-object ResourceGroupName -eq $rg | Select-Object ResourceGroupName,Location,ResourceType,Name
    
    }
}
#Stop-VM
Start-VM


