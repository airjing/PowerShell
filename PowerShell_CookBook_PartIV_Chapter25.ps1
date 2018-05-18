#Chapter25
#System Services
#25.1 List All Running Services
Get-Service | Where-Object {$_.Status -eq "Running"}
Write-Host "Sort all services by dependentServices" -BackgroundColor Blue
get-service | Sort-Object -Descending {$_.DependentServices.Count}

#25.2 Manage a Running Service
Stop-Service LxpSvc -WhatIf

#25.3 Configure a Service
Set-Service LxpSvc -StartupType Automatic
Get-Service LxpSvc

