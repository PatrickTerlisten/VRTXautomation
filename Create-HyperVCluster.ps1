<#
.SYNOPSIS
Dieses Skript kkonfiguriert das Hyper-V Failover-Cluster.

.DESCRIPTION
Mit Hilfe diese Skriptes wird ein 2-Node Windows Server 2016 Hyper-V Failover Cluster
konfiguriert.


History
v1.0: First Release
 
.EXAMPLE
Create-HyperVCluster.ps1

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
$HyperVNode1 = Read-Host "Computername Hyper-V Node 1"
$HyperVNode2 = Read-Host "Computername Hyper-V Node 2"
$CluNet1 = "Cluster Network 1"
$CluNet2 = "Cluster Network 2"
$CluNet3 = "Cluster Network 3"
$NewCluNet1 = "Management-VLAN150"
$NewCluNet2 = "ClusterHeartbeat-VLAN150"
$NewCluNet3 = "LiveMigration-VLAN150"
[string]$LiveMigration = Read-Host "Subnetz für VM Live Migration"

# Cluster Validation Test
Write-Host -ForegroundColor Green "Führe Test-Cluster aus..."
Test-Cluster -Node "$HyperVNode1", "$HyperVNode2"
Write-Host -ForegroundColor Green "Bitte prüfen Sie den Cluster Validation Report unter C:\Users\%USERNAME%\AppData\Local\Temp"
Write-Host `n

# Auf Rückmeldung warten
Pause
Write-Host `n

# Erstelle Failover Cluster
Write-Host -ForegroundColor Green "Erstelle Failover-Cluster..."
$HyperVCluster = Read-Host "Name des Clusters"
[string]$HyperVClusterIP = Read-Host "IP-Adresse des Clusters"
New-Cluster –Name "$HyperVCluster" –Node "$HyperVNode1","$HyperVNode2" -StaticAddress $HyperVClusterIP

# Ändere Namen der Cluster-Netzwerke
Write-Host -ForegroundColor Green "Anpassung Cluster-Netzwerke..."
(Get-ClusterNetwork -Name $CluNet1).Name = $NewCluNet1
(Get-ClusterNetwork -Name $CluNet2).Name = $NewCluNet2
(Get-ClusterNetwork -Name $CluNet3).Name = $NewCluNet3

# Füge Disks hinzu
Write-Host -ForegroundColor Green "Füge Cluster-Disks hinzu..."
Get-ClusterAvailableDisk | Add-ClusterDisk

# Benenne Cluster Disks um
$ClusterDisks =  Get-CimInstance -ClassName MSCluster_Resource -Namespace root/mscluster -Filter "type = 'Physical Disk'"

foreach ($Disk in $ClusterDisks) {
$DiskResource = Get-CimAssociatedInstance -InputObject $Disk -ResultClass MSCluster_DiskPartition
    if (-not ($DiskResource.VolumeLabel -eq $Disk.Name)) {
    Invoke-CimMethod -InputObject $Disk -MethodName Rename -Arguments @{newName = $DiskResource.VolumeLabel}
    }
}

# Setze Disk-Quorum
Write-Host -ForegroundColor Green "Konfiguriere DiskWitness..."
Set-ClusterQuorum -DiskWitness "Quorum"

# Erstelle Cluster Shared Volume
Write-Host -ForegroundColor Green "Erstelle CSV..."
Add-ClusterSharedVolume –Name "Daten"

# Ändere VirtualHardDiskPath und VirtualMachinePath
Write-Host -ForegroundColor Green "Setze VirtualHardDiskPath und VirtualMachinePath..."
Set-VMHost -VirtualHardDiskPath "C:\ClusterStorage\Volume1" -VirtualMachinePath "C:\ClusterStorage\Volume1" -ComputerName $HyperVNode1
Set-VMHost -VirtualHardDiskPath "C:\ClusterStorage\Volume1" -VirtualMachinePath "C:\ClusterStorage\Volume1" -ComputerName $HyperVNode2

# Ändere Namen der Cluster-Netzwerke
Write-Host -ForegroundColor Green "Konfiguriere VM Live Migration..."
Enable-VMMigration -ComputerName $HyperVNode1
Enable-VMMigration -ComputerName $HyperVNode2
Add-VMMigrationNetwork $LiveMigration -ComputerName $HyperVNode1
Add-VMMigrationNetwork $LiveMigration -ComputerName $HyperVNode2
Write-Host -ForegroundColor Green "Subnetz Live Migration ist $LiveMigration."
Write-Host `n
Write-Host -ForegroundColor Green "Erstellung Hyper-V Cluster abgeschlossen. Bitte testen und in den SCVMM importieren."