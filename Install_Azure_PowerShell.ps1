# https://docs.microsoft.com/en-us/powershell/azure/install-azur


erm-ps?view=azurermps-6.0.0
# Step1 Install PowerShellGet
# This Script require elevated privileges.

$psGetVer = (Get-Module -Name PowerShellGet -ListAvailable).Version
if ($psGetVer -lt "1.1.2.0")
{
    Install-Module PowerShellGet -Force
}
else {
    {Write-Host "The current PowerShellGet version is {0}, not need to upgrade it." $psGetVer}
}

# Step2
# Install the Azure Resource Manager modules from the PowerShell Gallery
# Answer 'Yes' or 'Yes to All' to continue with the installation.
Install-Module -Name AzureRM -AllowClobber

# Step3
# Import the AzureRM module
Import-Module -Name AzureRM

# Step4
# Check the Version
$azrm = Get-Module -name AzureRM -ListAvailable | Select-Object -Property Name,Version,Path
$version = $azrm.version

## Getting started with Azure PowerShell
#login to Azure
Connect-AzureRmAccount
# Get a credential
$cred = get-credential -message "Enter the credential that will be used for new deployed VM"
$vmName = "DemoVM1"
New-AzureRmVM -Name $vmName -credential $cred

$rgs = Get-AzureRmResourceGroupn| Select-Object ResourceGroupName,Location

Write-Host "There are totally {0} resource groups were created", $rgs.count()
foreach $rg in $rgs
{
    
    Get-AzureRmResource | where-object ResourceGroupName -eq $rg | Select-Object ResourceGroupName,Location,ResourceType,Name

}

Get-AzureRmVm -Name $vmName -resourcegroupname $rg[0]
    | Select-Object -ExpandProperty StorageProfile
    | Select-Object -ExpandProperty ImageReference


