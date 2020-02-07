<#
.SYNOPSIS
Dieses Skript konfiguriert einen VRTX Hyper-V Node.

.DESCRIPTION
Mit Hilfe diese Skriptes eine Windows Server 2016 Standardinstallation auf einer DELLEMC
VRTX für ein Microsoft Hyper-V Failover-Cluster vorbereitet.


History
v1.0: First Release
 
.EXAMPLE
Configure-WindowsServer.ps1

.NOTES
Author: Patrick Terlisten, p.terlisten@mlnetwork.de

This script is provided "AS IS" with no warranty expressed or implied. Run at your own risk.
This work is licensed under a Creative Commons Attribution NonCommercial ShareAlike 4.0
International License (https://creativecommons.org/licenses/by-nc-sa/4.0/).
.LINK
https://www.mlnetwork.de
#>

#Requires -Version 3.0

# Variablen
$ServerName = Read-Host "Bitte Computernamen eingeben"

# Computer umbenennen
Rename-Computer -NewName $ServerName -Confirm:$false

# Notwendige Windows Features installieren
Install-WindowsFeature -Name Hyper-V,Failover-Clustering –IncludeAllSubFeature -IncludeManagementTools -Confirm:$false

# Füge RegKey hinzu
Write-Host -ForegroundColor Green "Erstelle AllowBusTypeRAID DWORD in Registry..."
REG ADD HKLM\SYSTEM\CurrentControlSet\Services\ClusDisk\Parameters /f /v AllowBusTypeRAID /t REG_DWORD /d 1

# Laufwerksbuchstabe DVD ändern
Get-WmiObject -Class Win32_volume -Filter 'DriveType=5' | Select-Object -First 1 | Set-WmiInstance -Arguments @{DriveLetter='Z:'}

# Server neustarten
Restart-Computer -Confirm:$false -Force