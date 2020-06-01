[cmdletbinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try {
	Import-VstsLocStrings "$PSScriptRoot\Task.json" 
	[string]$Path = Get-VstsInput -Name Path
	[string]$RemoveFromAgentMachine = Get-VstsInput -Name RemoveFromAgentMachine
	[string]$SourceMachineName = Get-VstsInput -Name SourceMachineName
	[string]$SourceMachineUserName = Get-VstsInput -Name SourceMachineUserName
	[string]$SourceMachinePassword = Get-VstsInput -Name SourceMachinePassword

	[string]$Force = Get-VstsInput -Name Force
	[string]$Filter = Get-VstsInput -Name Filter
	[string]$Include = Get-VstsInput -Name Include
	[string]$Exclude = Get-VstsInput -Name Exclude
	[string]$Recurse = Get-VstsInput -Name Recurse
	[string]$WhatIf = Get-VstsInput -Name WhatIf
} 
finally 
{ 
     Trace-VstsLeavingInvocation $MyInvocation 
} 
try
{
	# Display vars
	Write-Host "ASSIGNED PARAMETER VALUES:"
	Write-Host "Path: $($Path)"
	Write-Host "RemoveFromAgentMachine: $($RemoveFromAgentMachine)"
	Write-Host "SourceMachineName: $($SourceMachineName)"
	Write-Host "SourceMachineUsername: $($SourceMachineUserName)"
	Write-Host "SourceMachinePassword: [masked]"
   

	Write-Host "Force: $($Force)"
	Write-Host "Filter: $($Filter)"
	Write-Host "Include: $($Include)"
	Write-Host "Exclude: $($Exclude)"
	Write-Host "Recurse: $($Recurse)"
	Write-Host "WhatIf: $($WhatIf)"
	
	Write-Host "PSVersion:" $psversiontable.PSVersion.Major

   # Stop the script on error
	$ErrorActionPreference = "Stop"

   # Convert to boolean
	[bool]$IsRemoveFromAgentMachine= [System.Convert]::ToBoolean($RemoveFromAgentMachine)
	[bool]$IsForce= [System.Convert]::ToBoolean($Force)
	[bool]$IsRecurse= [System.Convert]::ToBoolean($Recurse)
	[bool]$IsWhatIf= [System.Convert]::ToBoolean($WhatIf)

	$params = @{}
	#$params.Add('Confirm', $false)

	if (!$IsRemoveFromAgentMachine)
	{
		Write-Host "creating remote session"
		# Preparing the credentials
		if (!$SourceMachineName)
		{
			Throw "Please provide source machine name"
		}
		if (!$SourceMachineUserName)
		{
			Throw "Please provide a username for source machine"
		}
		if (!$SourceMachinePassword)
		{
			Throw "Please provide a password for source machine"
		}
		$machines = $SourceMachineName.split(',') | ForEach-Object { if ($_ -and $_.trim()) { $_.trim() } }
		$FromSessions = @()
		foreach($machine in $machines)
		{
			$FromPasswd = ConvertTo-SecureString $SourceMachinePassword -AsPlainText -Force
			$FromCreds = New-Object System.Management.Automation.PSCredential ($SourceMachineUserName, $FromPasswd)
			$FromSession= new-pssession $machine -credential $FromCreds
			$FromSessions += $FromSession
		}
	}
	if ($IsForce)
	{
		$params.Add('Force', $true)
	}
	if ($IsRecurse)
	{
		$params.Add('Recurse', $true)
	}
	if ($IsWhatIf)
	{
		$params.Add('WhatIf', $true)
	}
	if ($Filter -ne $null -and $Filter.Trim() -ne "")
	{
		$params.Add('Filter', $Filter)
	}
	if ($Include -ne $null -and $Include.Trim() -ne "")
	{
		$params.Add('Include', $Include)
	}
	if ($Exclude -ne $null -and $Exclude.Trim() -ne "")
	{
		$params.Add('Exclude', $Exclude)
	}
	
	if ($IsRemoveFromAgentMachine)
	{
		Remove-Item @params -Path $Path -verbose
	}
	else # '-FromSession' and '-ToSession' are mutually exclusive and cannot be specified at the same time.
	{
		$Scriptblock = {
			param($Path,$params); 
			Write-Host "PSVersion:" $psversiontable.PSVersion.Major
			try
			{
				Remove-Item @params -Path $Path -verbose
			}
			catch
			{
				Write-Error $_.Exception.Message
				exit 1
			}
		}
		foreach ($session in $FromSessions)
		{
			Invoke-Command -Session $session -Scriptblock $Scriptblock -ArgumentList $Path,$params
		}
		get-pssession | remove-pssession
	}
}
catch
{
    get-pssession | remove-pssession
    Write-Error $_.Exception.Message
    exit 1
}   
