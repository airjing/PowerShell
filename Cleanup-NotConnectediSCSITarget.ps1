$cred = Get-Credential -Message "Enter the credential"
$iSCSI = Get-IscsiServerTarget -ComputerName BJFILES -Credential $cred | Where-Object {$_.Status -eq "NotConnected"}
$objISCSI = @{}
ForEach($i in $iSCSI)
{


}

$DCPromo = @"
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName  -DomainNetBIOSName  -ForestMode Win2012 -DomainMode Win2012 -InstallDNS -SkipAutoConfigureDNS -SafeModeAdministratorPassword
"@