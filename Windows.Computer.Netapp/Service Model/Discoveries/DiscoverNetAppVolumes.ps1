param($sourceId,$managedEntityId,$KeyC,$cluster,$nodeName)

# Manual Testing section - put stuff here for manually testing script - typically parameters:
#=================================================================================
# $SourceId = '{00000000-0000-0000-0000-000000000000}'
# $ManagedEntityId = '{00000000-0000-0000-0000-000000000000}'
# $cluster = "nafscl502.wellspan.org"    #controllers: nafscl1,nafscl502,nafscl901
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
$scriptName = "DiscoverNetAppVolumes.ps1"
$eventID = "3102"

$api.LogScriptEvent($ScriptName,$EventID,4,"Starting script $($scriptName)`nRunning as ($whoami)`nSource $($sourceId)`n ManagedEntityId $($managedEntityId)`nController $($cluster)`nNodeName $($nodeName)")

# Load DataONTAP, get NetApp credentials, Get controller info
import-module DataONTAP
$cred =  Import-Clixml E:\scripts\Netapp\netapp.dat
# Controller registry values
#$regPath               = 'HKLM:\SOFTWARE\WSH\NetApp'
#$filePath              = Get-ItemProperty -Path $regPath | Select-Object -ExpandProperty FilePath
#$controllers           = Get-ItemProperty -Path $regPath | Select-Object -ExpandProperty Controllers
#$servers = $controllers -split ","

# connect to NetApp server to get controller stats
$NcControllerInfo = Connect-NcController -Name $cluster -Credential $cred 

# Get volume info from cluster
$navinfo = get-ncvol

$comment = "Laste Updated " + (Get-Date).ToString()

foreach ($item in $navinfo) {
	$instance = $DiscoveryData.CreateClassInstance("$MPElement[Name='Windows.Computer.Netapp.Volume']$")
     $instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Controller']/KeyC$", $keyC)
    $KeyV = $nodeName + ";" + $cluster + ";" + $item.Vserver + ";" + $item.Name
    $instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Volume']/KeyV$", $KeyV) # Volume Key
	$instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Volume']/Aggregate$", $item.Aggregate)
    if ([string]::IsNullOrEmpty($item.available)) {
        [int64]$available = 0
    } else {
        [int64]$available = $item.available / 1GB
    }
    $instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Volume']/Available$", $available.ToString())
    $instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Volume']/Dedupe$", $item.Dedupe)
    $instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Volume']/EncryptSpecified$", $item.EncryptSpecified)
    if ([string]::IsNullOrEmpty($item.FilesTotal)) {
        [int64]$filesTotal = 0
    } else {
        [int64]$filesTotal = $item.FilesTotal
    }
    $instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Volume']/FilesTotal$", $filesTotal.ToString())
    if ([string]::IsNullOrEmpty($item.FilesUsed)) {
        [int64]$filesUsed = 0
    } else {
        [int64]$filesUsed = $item.FilesUsed
    }
    $instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Volume']/FilesUsed$", $filesUsed.ToString())
    $instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Volume']/IsInfiniteVolume$", $item.IsInfiniteVolume)
    $instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Volume']/JunctionPath$", $item.JunctionPath)
    $instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Volume']/VolumeName$", $item.Name)
    $instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Volume']/NcController$", $item.NcController.Name)
    $instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Volume']/Node$", "Volume_$($item.Vserver):/vol/$($item.Name)")
    $instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Volume']/VolState$", $item.State)
    [int64]$totalSize =  $item.TotalSize / 1GB
    $instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Volume']/TotalSize$", $totalSize.ToString())
    [int64]$used = $totalSize - $available
    $instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Volume']/Used$", $used.ToString())
    $instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Volume']/Vserver$",$item.Vserver)
    $instance.AddProperty("$MPElement[Name='Windows.Computer.Netapp.Volume']/Comment$", $comment)
    #$displayName = 'NetappVolume:' + $nodeName + "_Cluster:"+ $cluster + "_Vserver:" + $item.Vserver + "_Volume:" + $item.Name
    $displayName = "Cluster:"+ $cluster + ";Vserver:" + $item.Vserver + ";Volume:" + $item.Name
    $instance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $displayName)
    $discoveryData.AddInstance($instance)
}

#Log an event for script ending and total execution time.
$EndTime = Get-Date
$ScriptTime = ($EndTime - $StartTime).TotalSeconds
$api.LogScriptEvent($ScriptName,$EventID,0,"`n $($scriptName) Script Completed in ($ScriptTime) seconds  for $cluster")

# Return Discovery Items Normally       $api.return($discoveryData)    
$discoveryData