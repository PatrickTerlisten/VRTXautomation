<#
.SYNOPSIS
Dieses Skript bereitet die Daten- und Quorum-Disks vor.

.DESCRIPTION
Mit Hilfe diese Skriptes werden die beiden zuvor angelegten Shared SAS Disks
initialisiert und formatiert. Das Skript erwartet das Quorum als Disk 2 und die
Datendisk als Disk 3.


History
v1.0: First Release
 
.EXAMPLE
Create-HyperVClusterDisks.ps1

.NOTES
Author: Patrick Terlisten, p.terlisten@mlnetwork.de

This script is provided "AS IS" with no warranty expressed or implied. Run at your own risk.
This work is licensed under a Creative Commons Attribution NonCommercial ShareAlike 4.0
International License (https://creativecommons.org/licenses/by-nc-sa/4.0/).
.LINK
https://www.mlnetwork.de
#>

#Requires -Version 3.0

# Shared Disk vorbereiten
Write-Host -ForegroundColor Green "Initialisiere DELL Shared Disk..."
Get-Disk | ? {$_.FriendlyName -like 'DELL Shared*' -And $_.Size -match '^1\.*\s*' -And $_.PartitionStyle -eq 'RAW'} | Initialize-Disk -PartitionStyle GPT
Get-Disk | ? {$_.FriendlyName -like 'DELL Shared*' -And $_.Size -match '^2\.*\s*' -And $_.PartitionStyle -eq 'RAW'} | Initialize-Disk -PartitionStyle GPT
Write-Host `n 

# Erstelle Quorum Partition
Write-Host -ForegroundColor Green "Erstelle Quorum Disk - Q:"
Get-Disk | ? {$_.FriendlyName -like 'DELL Shared*' -And $_.Size -match '^1\.*\s*'} | New-Partition -UseMaximumSize -DriveLetter Q
Format-Volume -DriveLetter Q -FileSystem NTFS -NewFileSystemLabel Quorum -Confirm:$false

# Erstelle Daten Partition
Write-Host -ForegroundColor Green "Erstelle Daten Disk - H:"
Get-Disk | ? {$_.FriendlyName -like 'DELL Shared*' -And $_.Size -match '^2\.*\s*'} | New-Partition -UseMaximumSize -DriveLetter H
Format-Volume -DriveLetter H -FileSystem NTFS -NewFileSystemLabel Daten -Confirm:$false