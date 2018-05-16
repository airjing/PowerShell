#Chapter18
#Security and Script Signing
#18.8 Securely Handle Sensitive Information
$secureInput = Read-Host -AsSecureString "Enter Your Private Key"
$secureInput

#18.9 Securely Request Usernames and Passwords
$credential = Get-Credential
$credential