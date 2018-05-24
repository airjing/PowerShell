#Chapter18
#Security and Script Signing
#18.8 Securely Handle Sensitive Information
$secureInput = Read-Host -AsSecureString "Enter Your Private Key"
$secureInput

#18.9 Securely Request Usernames and Passwords
$credential = Get-Credential
$credential

#18.10 Program:Start a Process as Another User

#18.11 Program:Run a Temporarily Elevated Command

#18.12 Securely Store Credentials on Disk
$credPath = Join-Path (Split-Path $profile) CurrentScript.ps1.Credential
$credential | Export-Clixml $credPath

#18.13 Access User and Machine Certificates
Set-Location Cert:\CurrentUser\My
$certs = Get-ChildItem
$certs | Format-List Subject,Issuer,NotAfter,Thumbprint

#18.14 Program:Search the Certificate Store

