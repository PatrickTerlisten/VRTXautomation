<#
.SYNOPSIS
Dieses Skript konfiguriert Switches und vNICs für einen VRTX Hyper-V Node.

.DESCRIPTION
Mit Hilfe diese Skriptes wird ein Windows Server 2016 Converged Network Seup mit
zwei vSwitches und vNICs für Management, Live Migration und Heartbeat implementiert.


History
v1.0: First Release
 
.EXAMPLE
Configure-WindowsServerNetwork.ps1

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
$vSwitchManagement = "MgmtSwitch"
$vSwitchManagementNICs = "NIC1","NIC2"
$vSwitchVMs = "VMSwitch"
$vSwitchVMsNICs = "NIC3","NIC4"
$ManagementvNIC = "Management-VLAN150"
$ManagementVLAN = 150
$HeartbeatvNIC = "ClusterHeartbeat-VLAN150"
$HeartbeatVLAN = 150
$LiveMigvNIC = "LiveMigration-VLAN150"
$LiveMigVLAN = 150
$ManagementIP = Read-Host "Management IP-Adresse"
$DefaultGateway = Read-Host "Default-Gateway"
$HeartbeatIP = Read-Host "Heartbeat IP-Adresse"
$LiveMigIP = Read-Host "LiveMigration IP-Adresse"
$DNS = "8.8.8.8","8.8.4.4"
$ADDomain = "domain.local"

# Team und Switch für OS Management erstellen
Write-Host -ForegroundColor Green "Erstelle vSwitch $vSwitchManagement..."
New-VMSwitch -Name $vSwitchManagement -AllowManagementOS $False -NetAdapterName $vSwitchManagementNICs -EnableEmbeddedTeaming $True -MinimumBandwidthMode Weight
Set-VMSwitchTeam -Name $vSwitchManagement -LoadBalancingAlgorithm Dynamic
Write-Host `n

# Team und Switch für VMs erstellen
Write-Host -ForegroundColor Green "Erstelle vSwitch $vSwitchVMs..."
New-VMSwitch -Name $vSwitchVMs -AllowManagementOS $False -NetAdapterName $vSwitchVMsNICs -EnableEmbeddedTeaming $True -MinimumBandwidthMode Weight
Set-VMSwitchTeam -Name $vSwitchVMs -LoadBalancingAlgorithm HyperVPort
Write-Host `n

# Kurz die Luft anhalten...
Start-Sleep -Seconds 5

# vNICs erstellen
Write-Host -ForegroundColor Green "Erstelle vNIC $ManagementvNIC..."
Add-VMNetworkAdapter -ManagementOS -SwitchName MgmtSwitch -Name $ManagementvNIC
Write-Host -ForegroundColor Green "Erstelle vNIC $HeartbeatvNIC..."
Add-VMNetworkAdapter -ManagementOS -SwitchName MgmtSwitch -Name $HeartbeatvNIC
Write-Host -ForegroundColor Green "Erstelle vNIC $LiveMigvNIC..."
Add-VMNetworkAdapter -ManagementOS -SwitchName MgmtSwitch -Name $LiveMigvNIC
Write-Host `n

# VLANs setzen
Write-Host -ForegroundColor Green "Setze VLAN ID $ManagementVLAN für vNIC $ManagementvNIC..."
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName $ManagementvNIC -Access -VlanId $ManagementVLAN
Write-Host -ForegroundColor Green "Setze VLAN ID $HeartbeatVLAN für vNIC $HeartbeatvNIC..."
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName $HeartbeatvNIC -Access -VlanId $HeartbeatVLAN
Write-Host -ForegroundColor Green "Setze VLAN ID $LiveMigVLAN für vNIC $LiveMigvNIC..."
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName $LiveMigvNIC -Access -VlanId $LiveMigVLAN
Write-Host `n

# Bandbreite für Management-Team
Write-Host -ForegroundColor Green "Setze MinimumBandwidthWeight für vNIC $ManagementvNIC..."
Set-VMNetworkAdapter -ManagementOS -Name $ManagementvNIC -MinimumBandwidthWeight 40
Write-Host -ForegroundColor Green "Setze MinimumBandwidthWeight für vNIC $HeartbeatvNIC..."
Set-VMNetworkAdapter -ManagementOS -Name $HeartbeatvNIC -MinimumBandwidthWeight 40
Write-Host -ForegroundColor Green "Setze MinimumBandwidthWeight für vNIC $LiveMigvNIC..."
Set-VMNetworkAdapter -ManagementOS -Name $LiveMigvNIC -MinimumBandwidthWeight 20
Write-Host `n

# NICs verteilen
Write-Host -ForegroundColor Green "Mappe $ManagementvNIC und $LiveMigvNIC auf NIC1..."
Set-VMNetworkAdapterTeamMapping –VMNetworkAdapterName $ManagementvNIC –ManagementOS –PhysicalNetAdapterName NIC1
Set-VMNetworkAdapterTeamMapping –VMNetworkAdapterName $LiveMigvNIC –ManagementOS –PhysicalNetAdapterName NIC1
Write-Host -ForegroundColor Green "Mappe $HeartbeatvNIC auf NIC2..."
Set-VMNetworkAdapterTeamMapping –VMNetworkAdapterName $HeartbeatvNIC –ManagementOS –PhysicalNetAdapterName NIC2
Write-Host `n

# IP-Adressen konfigurieren
Write-Host -ForegroundColor Green "Deaktivieren DHCP..."
Set-NetIPInterface -InterfaceAlias "vEthernet (Management-VLAN150)" -dhcp Disabled
Set-DnsClientServerAddress -InterfaceAlias "vEthernet (Management-VLAN150)" -ServerAddresses $DNS
Set-NetIPInterface -InterfaceAlias "vEthernet (ClusterHeartbeat-VLAN150)" -dhcp Disabled
Set-NetIPInterface -InterfaceAlias "vEthernet (LiveMigration-VLAN150)" -dhcp Disabled

Write-Host -ForegroundColor Green "Setze IP-Adressen..."
New-NetIPAddress -AddressFamily IPv4 -PrefixLength 24 -InterfaceAlias "vEthernet (Management-VLAN150)" -IPAddress $ManagementIP -DefaultGateway $DefaultGateway
New-NetIPAddress -AddressFamily IPv4 -PrefixLength 30 -InterfaceAlias "vEthernet (ClusterHeartbeat-VLAN150)" -IPAddress $HeartbeatIP
New-NetIPAddress -AddressFamily IPv4 -PrefixLength 30 -InterfaceAlias "vEthernet (LiveMigration-VLAN150)" -IPAddress $LiveMigIP

Write-Host -ForegroundColor Green "Deaktiviere DNS Registrierung für LiveMig und Heartbeat..."
Set-DnsClient -InterfaceAlias "vEthernet (ClusterHeartbeat-VLAN150)" -RegisterThisConnectionsAddress $false
Set-DnsClient -InterfaceAlias "vEthernet (LiveMigration-VLAN150)" -RegisterThisConnectionsAddress $false

# Domain Join
Add-Computer -DomainName $ADDomain -Credential $(Get-Credential)

# Server neustarten
Restart-Computer -Confirm:$false -Force