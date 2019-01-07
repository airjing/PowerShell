# https://docs.microsoft.com/en-us/powershell/azure/install-azurerm-ps?view=azurermps-6.0.0
# Step1 Install PowerShellGet
# This Script require elevated privileges.

$psGet = Get-Module -Name PowerShellGet -ListAvailable | Select-Object -First 1
$psGetVer = $psGet.Version
if ($psGetVer -lt "1.1.2.0")
{
    Install-Module PowerShellGet -Force
}
else {
    Write-Host "The current PowerShellGet version is $psGetVer not need to upgrade it."
}

# Step2
# Install the Azure Resource Manager modules from the PowerShell Gallery
# Answer 'Yes' or 'Yes to All' to continue with the installation.
$AzureRM = Get-Module -Name AzureRM -ListAvailable | Select-Object -First 1
if($AzureRM -ne $null)
{
    Write-Host "The AzureRM $AzureRMVersion has already installed."
    Write-Host "Recommend Uninstall AzureRM, then install module Az"
    Uninstall-AzureRm
}
#else {
#    Install-Module -Name AzureRM -AllowClobber
#    Import-Module -Name AzureRM
#}

# Cross-platform Az module will replacing AzureRM. 
# https://azure.microsoft.com/en-us/blog/azure-powershell-cross-platform-az-module-replacing-azurerm/
# https://docs.microsoft.com/en-us/powershell/azure/migrate-from-azurerm-to-az?view=azps-1.0.0
$Az = Get-InstalledModule -Name Az -AllVersions | Select-Object Name,Version
if($Az -ne $null)
{
    Write-Host "The module Az has already installed."
    Update-Module -Name Az
}
else {
    Install-Module -Name Az -AllowClobber
}

C:\Windows\System32\cmd.exe /E:ON /V:ON /K "C:\Program Files\Microsoft SDKs\Azure\.NET SDK\v2.9\\bin\setenv.cmd"
## Getting started with Azure PowerShell
#login to Azure
#Connect-AzureRmAccount
Connect-AzAccount
# Get a credential
$cred = get-credential -message "Enter the credential that will be used for new deployed VM"
$vmName = "DemoVM1"
$AzureRmVM = Get-AzureRmVM $vmName
if ($AzureRmVM -eq $null)
{
    New-AzureRmVM -Name $vmName -credential $cred
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

