[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try {
	Import-VstsLocStrings "$PSScriptRoot\Task.json" 
	[string]$Action = Get-VstsInput -Name Action #"Start","Stop"
	[string]$ServiceName = Get-VstsInput -Name ServiceName
	[string]$UserName = Get-VstsInput -Name UserName
	[string]$Password = Get-VstsInput -Name Password
	[string]$MachineNameslist = Get-VstsInput -Name MachineNameslist
} 
finally 
{ 
     Trace-VstsLeavingInvocation $MyInvocation 
} 

	# Display vars
	Write-Host "ASSIGNED PARAMETER VALUES:"
	Write-Host "Action: $($Action)"
	Write-Host "ServiceName: $($ServiceName)"
	Write-Host "UserName: $($UserName)"
	Write-Host "Password: [masked]"
	Write-Host "MachineNameslist: $($MachineNameslist)"

   # Stop the script on error
	$ErrorActionPreference = "Stop"
$scriptBlock={
    param($Action,$ServiceName)

    $service = Get-Service $ServiceName

    if ($service -ne $null)
    {
        switch ($Action){
            "Start"   
			{
				if ($service.status -ne "Running") 
				{
					Start-Service -Name $ServiceName
					write-host "the service '$ServiceName' is started successfuly"
				}
				else
				{
					write-host "the service '$ServiceName' is already running"
				}
			}
            "Stop"    
			{
				if($service.status -ne "Stopped")
				{
					Stop-Service -Name $ServiceName
					write-host "the service '$ServiceName' is stopped successfuly"
				}
				else
				{
					write-host "the service '$ServiceName' is already stopped"
				}
			}
        }
    }    
    else
    {
        Write-Error "The Service '$ServiceName' is not found"
    }
}

$securePassword = "$Password" | ConvertTo-SecureString -AsPlainText -Force
$authCredentials = New-Object System.Management.Automation.PSCredential($UserName, $securePassword)

$MachineNameslist  = $MachineNameslist  -replace " ",""
$MachineNameslist  = $MachineNameslist  -replace ",",";"
$Machines = $MachineNameslist  -split ";"
foreach($machine in $Machines) 
{
	Invoke-Command -ComputerName $machine -Credential $authCredentials -ScriptBlock $scriptBlock -ArgumentList $Action, $ServiceName
}
