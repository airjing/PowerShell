# Windows PowerShell Acript for AD DS Deployment
#https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/install-a-new-windows-server-2012-active-directory-child-or-tree-domain--level-200-#BKMK_PS
# Enable PSRemoting when need manage server remotely
# Enable-PSRemoting -force
# winrm s winrm/config/client '@{TrustedHosts="SEATTLE"}'
# winrm quickconfig

# Install Active Directory Service
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Install new Forest
Install-ADDSForest -DomainName "LinkedInAzure.com" -DomainNetBIOSName "LinkedInAzure" -ForestMode Win2012 -DomainMode Win2012 `
-InstallDNS -SkipAutoConfigureDNS -SafeModeAdministratorPassword (Read-Host -Prompt "Input SafeMode Admin Password:" -AsSecureString)
