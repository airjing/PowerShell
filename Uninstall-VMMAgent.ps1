##############################################################################
## Uninstall System Center VMM Agent
##
##
##############################################################################

<#
.SYNOPSIS

Uninstall System Center VMM Agent on local host or array of servers.

.INPUTS
-ServerList - Multiple server names, split by ;

.EXAMPLE
PS > Powershell.exe . ./Uninstall-VMMAgent.ps1
PS > PowerShell.exe . ./Uninstall-VMMAgent.ps1 -ComputerList Server01,Server02,

.LINK
https://github.com/airjing/powershell
#>
param(
    # Parameter help description
    [Parameter(Mandatory=$false)]
    [System.Collections.ArrayList]
    $ServerList
)

if ($ServerList -eq $null)
{
    Uninstall-VMMAgent
}
else
{
    [System.Collections.ArrayList]$success = $null
    [System.Collections.ArrayList]$failed = $null
    [System.Collections.ArrayList]$novmmagt = $null
    foreach ($s in $ServerList)
    {
        Enter-PSSession $s
        $r = Uninstall-VMMAgent
        switch ($r) {
            0 { $success.Add($s)  }
            1 { $novmmagt.Add($s) }
            -1 {$failed.Add($s)}
        }
        Exit-PSSession
    }
    Write-Host "Successed - $success"
    Write-Host "Failed - $failed"
    Write-Host "NO VMM Agent - $novmmagt"  
}


function Uninstall-VMMAgent
{
<#
.SYNOPSIS
Uninstall System Center VMM Agent on local host

.OUTPUTS
-1: Failed
0: Success
1: No VMM Agent find
#>
    #$vmm2008r2 = "/X `"{A371D6FD-4635-4B65-84AE-D83FD91DF905}`" /norestart"
    #vmm2012 = "/X `"{5010A712-721E-4B45-8ED2-6AF5338EF697}`" /norestart"
    #$vmm2012r2 = "/X `"{79D092BB-62CC-43AB-BC8E-41E1778574D1}`" /norestart"
    $regkey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $regvmm = Get-ItemProperty $regkey | Where-Object {$_.DisplayName -like "*Microsoft System Center Virtual Machine Manager Agent*"}
    #VMM installed
    if ($regvmm -ne $null)
    {
        Write-Host "$($regvmm.DisplayName) Installed!"
        Write-Host "Version - $($regvmm.DisplayVersion)"
        Write-Host "Installed on - $($regvmm.InstallDate)"
        Write-Host "Product Guid - $($regvmm.PSChildName)"
        Write-Host "Uninstall - $($regvmm.UninstallString)"
        try{
            $p=Start-Process -FilePath "msiexec.exe" -ArgumentList $regvmm.UninstallString + " /norestart"
            $p.WaitForExit()
            if($p.ExitCode -eq 1603)
            return 0
        }
        Catch
        {
            Write-Error $_.Exception.Message
            return -1
        }
    }
    else
    {
        Write-Error "VMM Agent didn't installed!"
        return 1
    }    
}


