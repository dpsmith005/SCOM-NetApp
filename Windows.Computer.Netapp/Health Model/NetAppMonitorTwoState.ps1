param($sourceId,$managedEntityId,$MonitorItem,$key,$Threshold,$IntervalSeconds,$PercentError,$SampleCount,$WithinSeconds,$TimeoutSeconds)

$Threshold       = [int]::Parse($Threshold)
$IntervalSeconds = [int]::Parse($IntervalSeconds)
$PercentError      = [int]::Parse($PercentError)
$SampleCount     = [int]::Parse($SampleCount)
$WithinSeconds   = [int]::Parse($WithinSeconds)
$TimeoutSeconds  = [int]::Parse($TimeoutSeconds)

$PercentError    = [int]::Parse($PercentError)
$PercentWarn     = [int]::Parse($PercentWarn)

$api           = New-Object -ComObject 'MOM.ScriptAPI'
$discoveryData = $api.CreateDiscoveryData(0, $sourceId, $managedEntityId)

$Global:Error.Clear()
$script:ErrorView      = 'NormalView'
$ErrorActionPreference = 'Continue'
$StartTime = Get-Date
$whoami = whoami
$testedAt              = "Tested on: $(Get-Date -Format u) / $(([TimeZoneInfo]::Local).DisplayName)"
$localComputerName     = $env:COMPUTERNAME
$localComputerDomain   = ([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()).Name
$localIPAddresses      = ([System.Net.Dns]::GetHostAddresses($localComputerName)) | Where-Object { $_.AddressFamily -eq 'interNetwork' } | Select-Object -ExpandProperty IPAddressToString	| Select-Object -First 1
$scriptName = "NetAppMonitorThreeState.ps1"
$server = ($key -split "_")[0]
testedAt        = "Tested on: $(Get-Date -Format u) / $(([TimeZoneInfo]::Local).DisplayName)"
$EventID = 3111

$api.LogScriptEvent($ScriptName,$EventID,4,"Starting script $($scriptName)`nRunning as ($whoami)`nSource $($sourceId)`n ManagedEntityId $($managedEntityId)`nKey $($key)`nThreshold $($Threshold)")
		 
if ($Threshod -le $Threshod) {
	$state       = 'Good'						
} else {
	$state       = 'Bad'
}

$bag = $api.CreatePropertybag()								
$bag.AddValue("Key",$key)		
$bag.AddValue("State",$state)				
$bag.AddValue("Supplement",$supplement)		
$bag.AddValue("TestedAt",$testedAt)			
$bag
