[Reflection.Assembly]::LoadFile("C:\Program Files\WindowsPowerShell\Modules\newtonsoft.json\1.0.1.141\libs\Newtonsoft.Json.dll")
<#
.SYNOPSIS

Deploy Infrasturcture for Medaroom.

.DESCRIPTION

Deploy Virtual Machines for Mediaroom. This Scirpt will Setup Hyper-V Host(Physical), then Deploy Virtual Machines.

.INPUTS

None.

.OUTPUTS

None.

.EXAMPLE
C:\PS> Deploy.MR.Infrastructure.ps1 -Environment .\Environments.JSON

.LINK

https://github.com/airjing/powershell


#>
#Get the path while script running
$ROOT = $PSCommandPath | Split-Path


#Set global variables
$GLOBAL:envs = $null
$Environments = "$ROOT\Environments.json"
$ValuesManifest = "$ROOT\ValuesManifest.json"
$serverlayout = "$ROOT\serverLayout.xml"

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
    Read-Host
    Exit
}

$dtScriptStarted = get-date -Format yyyymmdd_hhmmss
Start-Transcript -Path "$ROOT\Deploy.MR.Infrastructure_$dtScriptStarted.log"

if(Test-Path $Environments)
{    
    $envs = Get-Content -Raw -Path $Environments | ConvertFrom-Json
}

else {
    WriteErrorAndExit "$Environments doesn't exist, Exit!"
}
# 
function New-Environment {
    param (
        # Specifies the Lab Name, i.e. BJE11
        [Parameter(Mandatory = $true)]
        [string]
        $LabName,
        # Specifies the deployment type, allowed value: MM, AIO
        [Parameter(Mandatory = $true)]
        [string]
        $Template
    )
<#
.SYNOPSIS

When Planning a new lab, This function will create variables in Environments.json file. 


.EXAMPLE

C:\PS> Deploy.MR.Infrastructure.ps1; New-Environment -Lab "BJE11" -Template "MM"

#>
    $jsonlab = @"
{
    "Operator":  "LabTeam",
    "Customer":  "ServerTeam",
    "Name":  "$LabName",
    "Template":  "$Template",
    "ValuesManifest":  "$ROOT\\$LabName\\$($LabName)_ValuesManifest.json",
    "Description":  "",
    "Product":  "Mediaroom",
    "Branch":  "mr_tv2_3.0_staging",
    "flavor":  "installer_x64_ship",
    "Build":  "10065",
    "Status":  "Planning",
    "Serverlayout":  "$ROOT\\$LabName\\serverlayout.xml"    
}
"@
    $lab = $envs.Environments | Where-Object {$_.name -eq $LabName}
    if ($lab -ne $null)
    {
        WriteInfo "Updating Variables for $LabName"
    }
    else {
        WriteInfo "Initializing Variables for $LabName"
        $envs.Environments += $jsonlab | ConvertFrom-JSON

        


    }
    $envs | ConvertTo-Json -Depth 20 | Set-Content -Path $Environments
    New-ValuesManifest -LabName $LabName -Template $Template
}

function  New-ValuesManifest {
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $LabName,
        [Parameter(Mandatory=$true)]
        [string]
        $Template
    )    
    $jsonValuesManifestMain = @"
{    
    "Operator":"LabTeam",
    "Name":"$LabName",
    "Networks":
    [
        {
            "Network":  "ServerFunctionManagement",
            "NetworkDataSource": "$ROOT\\Networks\\ServerFunctionManagement.json"
        },
        {
            "Network":  "ServerFunctionLoadBalance",
            "NetworkDataSource": "$ROOT\\Networks\\ServerFunctionLoadBalance.json"
        },
        {
            "Network":"ServerIngress",
            "NetworkDataSource":"$ROOT\\Networks\\ServerIngress.json"
        },
        {
            "Network":"ServerEgress",
            "NetworkDataSource":"$ROOT\\Networks\\ServerEgress.json"
        }
    ]   
}
"@
    $jsonTemplateMM = @"
    "Components":  
    [
        {
            "LiveBackend":  "True",
            "Domain":  "SRVBE.RNEA.IPTV.MR.ERICSSON.SE"
        },
        {
            "VodBackend":  "True",
            "Domain":  "SRVBE.RNEA.IPTV.MR.ERICSSON.SE"
        },
        {
            "Branch":  "True",
            "Domain":  "SRVBRA.RNEA.IPTV.MR.ERICSSON.SE"
        },
        {
            "MDS":  "True",
            "Domain":  "SRVMDS.RNEA.IPTV.MR.ERICSSON.SE"
        },
        {
            "ASR":  "True",
            "Domain":  "SRVMDS.RNEA.IPTV.MR.ERICSSON.SE"
        }
    ]
"@    
$jsonComputers = @"
    "Computers":
    [
        {
            "Name":"",
            "VmSku":"HyperV-S2",
            "VmImageSku":"win2k12r2vlstd"
        }
    ]
"@
    WriteInfo "Initializing ValuesManifest for $LabName"
    $lab = $envs.Environments | Where-Object {$_.name -eq $LabName}
    if(!(Test-Path $lab.ValuesManifest))
    {
        New-Item -ItemType file -Path $lab.ValuesManifest -Force
    }    
    $jsonValuesManifestMain += $jsonTemplateMM
    $jsonValuesManifest | Set-Content -Path $lab.ValuesManifest -Force
}

function Get-ComputersFromServerlayout {
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $serverlayout
    )
    [System.Collections.ArrayList] $comps = $null

    if(Test-Path $serverlayout)
    {
        $xmlserverlayout = [xml](Get-Content $serverlayout)
        $computers = $xmlserverlayout.configuration.components.serverLayout.branch | % {$_.zones} | % {$_.zone} | % {$_.computers} | % {$_.computer} | Select-Object {$_.Name}
        #$xmlserverlayout.configuration.components.serverLayout.branch | % {$_.zones} | % {$_.zone} | % {$_.computers} | % {$_.computer} | $ {$_.Roles} | % {$_.role}
        return $computers
    }
    else {
        throw "$serverlayout doesn't exists! Exit..."
    }
}



function  Get-IPAddress {
    param (
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [string]
        $Network
    )
    $net = $env.Networks | Where-Object {$_.Network -eq $Network}
    $freeip = $net.ip | Where-Object {$_.Owner -eq ""} | Select-Object -First 1
    if($freeip -ne $null)
    {
        return $freeip
    }
    else {
        return -1
    }


    $env | ConvertTo-Json -Depth 20 | Set-Content -Path $ValuesManifest
}

function Add-IPAddress {
    param (
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [string]
        $Network,
        # Parameter help description
        [Parameter(Mandatory=$true)]
        [int]
        $First,
        [Parameter(Mandatory = $true)]
        [int]
        $Amount
    )
    for ($i =$First; $i -lt $Amount; $i++)
    {
        $dtCreated = Get-Date -Format g
        $ip = @"
{
    "Address":  "10.164.100.$i",
    "Owner":  "",
    "CreatedDate":  "$dtCreated",
    "UpdatedDate":  "2018-10-10",
    "CreatedBy":  "",
    "UpdatedBy":  ""
}
"@
            
            
        $net = $env.Networks | Where-Object {$_.Network -eq $Network}
        $net.IP += $ip | ConvertFrom-Json
    }
    $env | ConvertTo-Json -Depth 20 | Set-Content -Path $ValuesManifest
    
}

#Get-IPAddress -Network "Management"
#Get-IPAddress -Network "Ingress"
#Add-IPAddress -Network "Management" -First 11 -Amount 100
New-Environment "BJE12" "MM"




