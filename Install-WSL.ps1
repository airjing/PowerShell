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




