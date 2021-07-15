param([string]$KeyV,$PercentWarn,[string]$ComputerName)

#=================================================================================
# Assign script name variable for use in event logging.
$ScriptName = "WSH.Netapp.Volume.Monitor.ps1"
$EventID = "3109"
$proxyServer = ($KeyV -split ";")[0]
$cluster =  ($KeyV -split ";")[1]
$vserver =  ($KeyV -split ";")[2]
$volName  =  ($KeyV -split ";")[3]
#=================================================================================

# Starting Script section - All scripts get this
#=================================================================================
# Gather the start time of the script
$StartTime = Get-Date
#Set variable to be used in logging events
$whoami = whoami
# Load MOMScript API
$momapi = New-Object -comObject MOM.ScriptAPI
# Load PropertyBag function
$bag = $momapi.CreatePropertyBag()
#Log script event that we are starting task
$momapi.LogScriptEvent($ScriptName,$EventID,0,"`n Script is starting. `n Running as ($whoami).")
#=================================================================================

# Begin MAIN script section
#=================================================================================
$whoami = whoami
$testedAt              = "Tested on: $(Get-Date -Format u) / $(([TimeZoneInfo]::Local).DisplayName)"
$localComputerName     = $env:COMPUTERNAME
$momapi.LogScriptEvent($ScriptName,$EventID,4,"Starting script $($scriptName)`nRunning as ($whoami)`n localComputer $($localComputerName)`n ComputerName $($ComputerName)`n KeyV $($KeyV)`nPercentWarn $($PercentWarn)`nPercentError $($PercentError)")

# Load DataONTAP, get NetApp credentials, Get controller info
import-module DataONTAP
$cred =  Import-Clixml E:\scripts\Netapp\netapp.dat

# connect to NetApp server to get controller stats
$NcControllerInfo = Connect-NcController -Name $cluster -Credential $cred 
$ControllerName = $NcControllerInfo.Name

# Get volume info from cluster
$navinfo = get-ncvol -name $volName -vserver $vserver
$item = $navinfo[0]

$available = $item.available
$total = $item.TotalSize
$Used = $item.Used
$key = $proxyServer +";"+ $item.NcController +";"+ $item.Vserver +";"+ $item.Name
$supplement = "Volume: $($key)`t$($KeyV) `n Available: $($available)`t `n Total: $($total)`n PercentUsed: $($Used)"
$FreeGB = [int]($item.available /1GB)

#Check the value of Used percent
if ($Used -lt $PercentWarn) {
	$momapi.LogScriptEvent($ScriptName,$EventID,0,"Good Condition Found")
	$bag.AddValue('Result','GoodCondition')
	$state = 'GoodCondition'
} ELSE {
	$momapi.LogScriptEvent($ScriptName,$EventID,0,"Bad Condition Found")
	$bag.AddValue('Result','BadCondition')
	$state = 'BadCondition'
}

$count = $navinfo.count
$supplement = "Keyv: $($keyV) PercentWarn: $($PercentWarn)  PercentError: $($PercentError) count ($count)"

$bag.AddValue("Volume",$volName)		
$bag.AddValue("State",$state)
$bag.AddValue("FreeSpace",$FreeGB)
$bag.AddValue("UsedPct", $Used)
$bag.AddValue("Supplement",$supplement)		
$bag.AddValue("TestedAt",$testedAt)	

# Return all bags
$bag
#=================================================================================
# End MAIN script section


# End of script section
#=================================================================================
#Log an event for script ending and total execution time.
$EndTime = Get-Date
$ScriptTime = ($EndTime - $StartTime).TotalSeconds
#$momapi.LogScriptEvent($ScriptName,$EventID,0,"`n Script Completed. `n Script Runtime: ($ScriptTime) seconds.")
#=================================================================================
# End of script

