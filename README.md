# VRTXautomation
This repository includes files and scripts for automating an Hyper-V Failover Cluster deployment on a DELLEMC VRTX blade system.
 
The autounattend.xml is used to deploy a Windows Server 2016 Standard (with Desktop) with english UI and german input locale. The partitioning is for UEFI boot.

Each PowerShell script is doing a specific task. Depending on your setup you have to customize these scripts.

Configure-WindowsServer.ps1 > Renaming of the server, adding Registry values, installation roles and features
Configure-WindowsServerNetwork.ps1 > Setting up two VMswitches mit embedded teaming and vNICs for the OS
Create-HyperVClusterDisks.ps1 > Creating two volumes for cluster qorum and data
Create-HyperVCluster.ps1 > Creating a Failover-Cluster

Again: Depending on your setup you have to customize these scripts!
