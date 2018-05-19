# https://docs.microsoft.com/en-us/powershell/azure/install-azurerm-ps?view=azurermps-6.0.0
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