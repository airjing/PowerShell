# Setup Environmental Variables
<<<<<<< HEAD
[environment]::SetEnvironmentVariable("VAGRANT_HOME","E:\ApplicationsData\.vagrant.d","Machine")
[environment]::SetEnvironmentVariable("VAGRANT_DOTFILE_PATH","E:\ApplicationsData\.vagrant-hyperv","Machine")
=======
[environment]::SetEnvironmentVariable("VAGRANT_HOME","F:\ApplicationsData\.vagrant.d","Machine")
[environment]::SetEnvironmentVariable("VAGRANT_DOTFILE_PATH","E:\VMHome\.vagrant-hyperv","Machine")
>>>>>>> c4171480efc5caefa01f2ed5be0ceb57facf5987
[environment]::SetEnvironmentVariable("JAVA_HOME","E:\Applications\Java\jdk-11.0.1","Machine")
$pChef = "E:\Applications\opscode\chef-workstation\bin\"
$pJava = "%JAVA_HOME%\bin"
$pVagrant = "E:\Applications\HashiCorp\Vagrant\bin"
<<<<<<< HEAD

=======
>>>>>>> c4171480efc5caefa01f2ed5be0ceb57facf5987
function InEnvPath {
    param (
        # Path name to test if already in ENV:Path
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )
    $paths = $env:Path.Split(";")
    if ($paths -contains $path)
    {
        return $true
    }
    else
    {
        return $false
    }
}

function Add-EnvPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path,       
        [Parameter(Mandatory = $false)]
        [string]
        $Target="Machine"
    )
    if (!(InEnvPath $Path))
    {
        $env:Path += $(";$Path")
        [Environment]::SetEnvironmentVariable("Path",$env:Path,$Target)
    }
}
Add-EnvPath $pJava
Add-EnvPath $pChef
<<<<<<< HEAD
Add-EnvPath $pVagrant
=======
Add-EnvPath $pVagrant
# show env:path
$env:path.split(";")

# Enable WSL fetures
$fnWSL = "Microsoft-Windows-Subsystem-Linux"
$f = "Ubuntu.appx"
$dst = "C:\Distros\Ubuntu"
$wsl = Get-WindowsOptionalFeature -Online -FeatureName $fnWSL
if ($wsl.State -eq "Disabled")
{
    Enable-WindowsOptionalFeature -Online -FeatureName $fnWSL
}

if(!(Test-Path $f))
{
    Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1804 -OutFile $f -UseBasicParsing
    Rename-Item $f Ubuntu.zip
    if(!(Test-Path $dst))
    {
        Expand-Archive Ubuntu.zip $dst
        Remove-Item .\Ubuntu.zip -Force
    }    
}
if(Test-Path $dst)
{
    & $dst\Ubuntu1804.exe
}




>>>>>>> c4171480efc5caefa01f2ed5be0ceb57facf5987
