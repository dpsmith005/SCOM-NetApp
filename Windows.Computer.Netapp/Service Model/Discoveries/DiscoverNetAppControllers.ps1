param($sourceId,$managedEntityId,$controllers,$nodeName)

# Manual Testing section - put stuff here for manually testing script - typically parameters:
#=================================================================================
# $SourceId = '{00000000-0000-0000-0000-000000000000}'
# $ManagedEntityId = '{00000000-0000-0000-0000-000000000000}'
# $controllers = "nafscl1,nafscl502,nafscl901"
# $nodeName = "scomtst01.wellspan.org"
#==================================================================================

$api           = New-Object -ComObject 'MOM.ScriptAPI'
$discoveryData = $api.CreateDiscoveryData(0, $sourceId, $managedEntityId)

$Global:Error.Clear()
$script:ErrorView      = 'NormalView'
$ErrorActionPreference = 'Continue'
$StartTime = Get-Date
$whoami = whoami

$localComputerName     = $env:COMPUTERNAME
$localComputerDomain   = ([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()).Name
$localIPAddresses      = ([System.Net.Dns]::GetHostAddresses($localComputerName)) | Where-Object { $_.AddressFamily -eq 'interNetwork' } | Select-Object -ExpandProperty IPAddressToString | Select-Object -First 1
$scriptName = "DiscoverNetAppController.ps1"
$eventID = "3100"
	
$api.LogScriptEvent($ScriptName,$EventID,4,"Starting script $($scriptName)`nRunning as ($whoami)`nSource $($sourceId)`nManagedEntityId $($managedEntityId)`nControllers $($controllers)`nNodeName $($nodeName)`n")

# Load DataONTAP, get NetApp credentials, Get controller info
import-module DataONTAP
$cred =  Import-Clixml E:\scripts\Netapp\netapp.dat
# Controller registry values
#$regPath               = 'HKLM:\SOFTWARE\WSH\NetApp'
#$controllers           = Get-ItemProperty -Path $regPath | Select-Object -ExpandProperty Controllers

$servers = $controllers -split ","
foreach ($server in $servers) {
    # connect to NetApp server to get controller stats
    $NcControllerInfo = Connect-NcController -Name $server -Credential $cred 
	$ClusterName = (Resolve-DnsName $NcControllerInfo.Name).Name
	$comment = "Laste Updated " + (Get-Date).ToString()
	$keyC = $nodeName + "_"+ $ClusterName
	$displayName = 'NetappProxy:' + $nodeName + "_Cluster:"+ $ClusterName
	#Controller Values: ComputerName, KeyC, Ontapi, Version, Name, IpAddress, Comment
	$instance = $discoveryData.CreateClassInstance("$MPElement[Name='Windows.Computer.Netapp.Controller']$")	
	#$instance.AddProperty("$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$",$nodeName)   # Inherited Key Property
	$instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Controller']/KeyC$", $keyC)				  # Key propery
	$instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Controller']/ComputerName$", $nodeName)
	$instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Controller']/Ontapi$", $NcControllerInfo.Ontapi)
	$instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Controller']/Version$", $NcControllerInfo.Version)
	$instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Controller']/ClusterName$", $ClusterName)
	$instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Controller']/IpAddress$", $NcControllerInfo.Address.IPAddressToString)
	$instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Controller']/Comment$", $comment)
	$instance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)
	$discoveryData.AddInstance($instance)

	$api.LogScriptEvent($ScriptName,$EventID,4,"nodeName: $($nodeName)`nComputerName: $($nodeName)`nKeyC: $($keyC)`nOntapi: $($NcControllerInfo.Ontapi)`nVersion: $($NcControllerInfo.Version)`nClusterName: $($ClusterName)`nIpAddress: $($NcControllerInfo.Address.IPAddressToString)`nComment: $($comment)")
}

#Log an event for script ending and total execution time.
$EndTime = Get-Date
$ScriptTime = ($EndTime - $StartTime).TotalSeconds
$api.LogScriptEvent($ScriptName,$EventID,0,"`n $($scriptName) Script Completed in ($ScriptTime) seconds.  For key $keyC")

# Return Discovery Items Normally       $api.return($discoveryData)    
$discoveryData
