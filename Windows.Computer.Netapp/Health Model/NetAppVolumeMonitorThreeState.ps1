param([string]$KeyV,$PercentError,$PercentWarn,[string]$ComputerName)
#param($KeyV,$PercentError,$PercentWarn)

# For testing
# $KeyV = "SCOMTST01.wellspan.org_nafscl502.wellspan.org_svm_pna501_vol_pna527"
# $PercentError = 97
# $PercentWarn = 93

$PercentError    = [int]::Parse($PercentError)
$PercentWarn     = [int]::Parse($PercentWarn)

# Load MOMScript API
$api           = New-Object -ComObject 'MOM.ScriptAPI'

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
$proxyServer = ($KeyV -split ";")[0]
$cluster =  ($KeyV -split ";")[1]
$vserver =  ($KeyV -split ";")[2]
$volName  =  ($KeyV -split ";")[3]

testedAt        = "Tested on: $(Get-Date -Format u) / $(([TimeZoneInfo]::Local).DisplayName)"
$EventID = 3110

$api.LogScriptEvent($ScriptName,$EventID,4,"Starting script $($scriptName)`nRunning as ($whoami)`nKey $($KeyV)`nPercentError $($PercentError)`nPercentWarn $($PercentWarn)`nProxy Server $($proxyServer)`nCluster $($cluster) `n vServer $($vserver) `n Volume $($volName)")

# Load DataONTAP, get NetApp credentials, Get controller info
import-module DataONTAP
$cred =  Import-Clixml E:\scripts\Netapp\netapp.dat

# connect to NetApp server to get controller stats
$NcControllerInfo = Connect-NcController -Name $cluster -Credential $cred 
$ControllerName = $NcControllerInfo.Name

# Get volume info from cluster
$navinfo = get-ncvol -name $volName -vserver $vserver

$KeysAll = @()
foreach ($item in $navinfo) {
	$available = $item.available
	$total = $item.TotalSize
	$Used = $item.Used
	$key = $proxyServer +";"+ $item.NcController +";"+ $item.Vserver +";"+ $item.Name
	$KeysAll += $key
	$supplement = "Volume: $($key)`t$($KeyV) `n Available: $($available)`t `n Total: $($total)`n PercentUsed: $($Used)"

	if ($key -eq $KeyV) {
		$FreeGB = [int]($item.available /1GB)
		if ($Used -lt $PercentWarn) {
			$state       = 'GoodCondition'
			$supplement += "`nPercent below warn level $($PercentWarn)"
		} elseif ($Used -ge $PercentError) {
			$state       = 'ErrorCondition'
			$supplement += "`nPercent above error level $($PercentError)"
		} else {
			$state       = 'WarnCondition'
			$supplement += "`nPercent between warn and error level $($PercentWarn) - $($PercentError)"
		}																						

		#$api.LogScriptEvent($ScriptName,3111,4,"Key matched $key.  State is $state. $testedAt")

		$bag = $api.CreatePropertybag()								
		$bag.AddValue("Key",$KeyV)		
		$bag.AddValue("State",$state)				
		$bag.AddValue("Volume",$volName)
		$bag.AddValue("FreeSpace",$FreeGB)
		$bag.AddValue("UsedPct", $Used)
		$bag.AddValue("Supplement",$supplement)		
		$bag.AddValue("TestedAt",$testedAt)			
		$bag					
	}
}

$Allkeys = $KeysAll -join "`n"
$VolumeCounts = $navinfo.count
$api.LogScriptEvent($ScriptName,3112,4,"`n Controller Name: $ControllerName `n Volume count: $VolumeCounts `n Key: $($KeyV) All Keys: `n $($Allkeys) `n State: $($state) `n Supplement: $($supplement)")