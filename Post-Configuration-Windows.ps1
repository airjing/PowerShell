# Setup Environmental Variables
[environment]::SetEnvironmentVariable("VAGRANT_HOME","E:\Applications\.vagrant.d")
[environment]::SetEnvironmentVariable("VAGRANT_DOTFILE_PATH","E:\Applications\.vagrant-hyperv")
[environment]::SetEnvironmentVariable("JAVA_HOME","E:\Applications\Java\jdk-11.0.1","Machine")
$pChef = "E:\Applications\opscode\chef-workstation\bin\"
$pJava = "%JAVA_HOME%\bin"

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