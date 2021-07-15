param($sourceId,$managedEntityId,$controllers,$nodeName,$computerName)

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
$scriptName = "DiscoverNetAppControllerRelationships.ps1"
$eventID = "3101"

$api.LogScriptEvent($ScriptName,$EventID,4,"Starting script $($scriptName)`nRunning as ($whoami)`nSource $($sourceId)`nManagedEntityId $($managedEntityId)`nControllers $($controllers)`nFilePath $($filePath)`nodeName $($nodeName)")

# Load DataONTAP, get NetApp credentials, Get controller info
import-module DataONTAP
$cred =  Import-Clixml E:\scripts\Netapp\netapp.dat
# Controller registry values
#$regPath               = 'HKLM:\SOFTWARE\WSH\NetApp'
#$controllers           = Get-ItemProperty -Path $regPath | Select-Object -ExpandProperty Controllers

$srcInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Windows.Computer.Netapp.Computer']$")		
$srcInstance.AddProperty("$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$", $nodeName)	
#$srcInstance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Computer']/NodeName$", $nodeName)
$discoveryData.AddInstance($srcInstance)
		
$healthInstance = $discoveryData.CreateClassInstance("$MPElement[Name='SC!Microsoft.SystemCenter.HealthService']$")		
$healthInstance.AddProperty("$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$", $computerName)			
$discoveryData.AddInstance($healthInstance)

$servers = $controllers -split ","
foreach ($server in $servers) {
	# connect to NetApp server to get controller stats
    $NcControllerInfo = Connect-NcController -Name $server -Credential $cred 
	$ClusterName = (resolve-dnsname $NcControllerInfo.Name).Name
	$keyC = $nodeName + "_"+ $ClusterName
	$displayName = 'NetappProxy:' + $nodeName + "_Cluster:"+ $ClusterName
	$comment = "Laste Updated " + (Get-Date).ToString()

	#Controller Values: ComputerName, KeyC, Ontapi, Version, Name, IpAddress, Comment
	$targetInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Windows.Computer.Netapp.Controller']$")
	#$targetinstance.AddProperty("$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$",$nodeName)   # Inherited Key Property
	$targetInstance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Controller']/ComputerName$", $nodeName)
	$targetInstance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Controller']/KeyC$", $keyC)
	$targetInstance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Controller']/Ontapi$", $NcControllerInfo.Ontapi)
	$targetInstance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Controller']/Version$", $NcControllerInfo.Version)
	$targetInstance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Controller']/ClusterName$", $ClusterName)
	$targetInstance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Controller']/IpAddress$", $NcControllerInfo.Address.IPAddressToString)
	$targetInstance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Controller']/Comment$", $comment)
	$instance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)

	$discoveryData.AddInstance($targetInstance)

	$relHealthInstance        = $discoveryData.CreateRelationShipInstance("$MPElement[Name='SC!Microsoft.SystemCenter.HealthServiceShouldManageEntity']$")
	$relHealthInstance.Source = $healthInstance
	$relHealthInstance.Target = $targetInstance									
	$discoveryData.AddInstance($relHealthInstance)
					
	$relInstance        = $discoveryData.CreateRelationShipInstance("$MPElement[Name='Windows.Computer.Netapp.Controllers.Relationship']$")
	$relInstance.Source = $srcInstance
	$relInstance.Target = $targetInstance									
	$discoveryData.AddInstance($relInstance)
}

#Log an event for script ending and total execution time.
$EndTime = Get-Date
$ScriptTime = ($EndTime - $StartTime).TotalSeconds
$api.LogScriptEvent($ScriptName,$EventID,0,"`n $($scriptName) Script Completed in ($ScriptTime) seconds.")

# Return Discovery Items Normally            $api.return($discoveryData)
$discoveryData