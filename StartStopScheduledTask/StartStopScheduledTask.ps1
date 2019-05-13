[CmdletBinding()]
param(
    [ValidateSet("Start","Stop")][String] $Action,
    [Parameter(Mandatory=$true)][String] $TaskName,
    [Parameter(Mandatory=$true)][string] $UserName,
    [Parameter(Mandatory=$true)][string] $Password,
    [Parameter(Mandatory=$true)][string] $MachineNameslist
)

	# Display vars
	Write-Host "ASSIGNED PARAMETER VALUES:"
	Write-Host "Action: $($Action)"
	Write-Host "TaskName: $($TaskName)"
	Write-Host "UserName: $($UserName)"
	Write-Host "Password: [masked]"
	Write-Host "MachineNameslist: $($MachineNameslist)"

   # Stop the script on error
	$ErrorActionPreference = "Stop"
$scriptBlock={
    param($Action,$TaskName)

	$scheduledTask = Get-ScheduledTask $TaskName
	write-host "resolved task name: $($scheduledTask.TaskName)"
	write-host "resolved task state: $($scheduledTask.state)"
    if ($scheduledTask -ne $null)
    {
        switch ($Action){
            "Start"   
			{
				if ($scheduledTask.state -ne "Running") 
				{
					Start-ScheduledTask -TaskName $TaskName
					write-host "the scheduled task '$TaskName' is started successfuly"
				}
				else
				{
					write-host "the scheduled task '$TaskName' is already running"
				}
			}
            "Stop"    
			{
				if($scheduledTask.state -ne "Ready")
				{
					Stop-ScheduledTask -TaskName $TaskName
					write-host "the scheduled task '$TaskName' is stopped successfuly"
				}
				else
				{
					write-host "the scheduled task '$TaskName' has already been stopped"
				}
			}
        }
    }    
    else
    {
        Write-Error "The scheduled task '$TaskName' is not found."
    }
}

$securePassword = "$Password" | ConvertTo-SecureString -AsPlainText -Force
$authCredentials = New-Object System.Management.Automation.PSCredential($UserName, $securePassword)

$MachineNameslist  = $MachineNameslist  -replace " ",""
$Machines = $MachineNameslist  -split ";"
foreach($machine in $Machines) 
{
	Invoke-Command -ComputerName $machine -Credential $authCredentials -ScriptBlock $scriptBlock -ArgumentList $Action, $TaskName
}