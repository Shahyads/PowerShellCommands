[cmdletbinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try {
	Import-VstsLocStrings "$PSScriptRoot\Task.json" 
	[string]$Path = Get-VstsInput -Name Path
	[string]$CopyFromAgentMachine = Get-VstsInput -Name CopyFromAgentMachine 
	[string]$SourceMachineName = Get-VstsInput -Name SourceMachineName
	[string]$SourceMachineUserName = Get-VstsInput -Name SourceMachineUserName
	[string]$SourceMachinePassword = Get-VstsInput -Name SourceMachinePassword

	[string]$Destination = Get-VstsInput -Name Destination
	[string]$CopyToAgentMachine = Get-VstsInput -Name CopyToAgentMachine
	[string]$TargetMachineName = Get-VstsInput -Name TargetMachineName
	[string]$TargetMachineUserName = Get-VstsInput -Name TargetMachineUserName
	[string]$TargetMachinePassword = Get-VstsInput -Name TargetMachinePassword

	[string]$Container = Get-VstsInput -Name Container
	[string]$Force = Get-VstsInput -Name Force
	[string]$Filter = Get-VstsInput -Name Filter
	[string]$Include = Get-VstsInput -Name Include
	[string]$Exclude = Get-VstsInput -Name Exclude
	[string]$Recurse = Get-VstsInput -Name Recurse
	[string]$PassThru = Get-VstsInput -Name PassThru
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
	Write-Host "CopyFromAgentMachine: $($CopyFromAgentMachine)"
	Write-Host "SourceMachineName: $($SourceMachineName)"
	Write-Host "SourceMachineUsername: $($SourceMachineUserName)"
	Write-Host "SourceMachinePassword: [masked]"
   
	Write-Host "Destination: $($Destination)"
	Write-Host "CopyToAgentMachine: $($CopyToAgentMachine)"
	Write-Host "TargetMachineName: $($TargetMachineName)"
	Write-Host "TargetMachineUsername: $($TargetMachineUserName)"
	Write-Host "TargetMachinePassword: [masked]"

	Write-Host "Container: $($Container)"
	Write-Host "Force: $($Force)"
	Write-Host "Filter: $($Filter)"
	Write-Host "Include: $($Include)"
	Write-Host "Exclude: $($Exclude)"
	Write-Host "Recurse: $($Recurse)"
	Write-Host "PassThru: $($PassThru)"
	Write-Host "WhatIf: $($WhatIf)"
	
	Write-Host "PSVersion:" $psversiontable.PSVersion.Major

   # Stop the script on error
	$ErrorActionPreference = "Stop"

   # Convert to boolean
	[bool]$IsCopyFromAgentMachine= [System.Convert]::ToBoolean($CopyFromAgentMachine)
	[bool]$IsCopyToAgentMachine= [System.Convert]::ToBoolean($CopyToAgentMachine)
	[bool]$IsContainer= [System.Convert]::ToBoolean($Container)
	[bool]$IsForce= [System.Convert]::ToBoolean($Force)
	[bool]$IsRecurse= [System.Convert]::ToBoolean($Recurse)
	[bool]$IsPassThru= [System.Convert]::ToBoolean($PassThru)
	[bool]$IsWhatIf= [System.Convert]::ToBoolean($WhatIf)

	$params = @{}
	#$params.Add('Confirm', $false)

	if (!$IsCopyFromAgentMachine)
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
		$FromPasswd = ConvertTo-SecureString $SourceMachinePassword -AsPlainText -Force
		$FromCreds = New-Object System.Management.Automation.PSCredential ($SourceMachineUserName, $FromPasswd)
		$FromSession= new-pssession $SourceMachineName -credential $FromCreds
		if ($IsCopyToAgentMachine) # '-FromSession' and '-ToSession' are mutually exclusive and cannot be specified at the same time.
		{
			$params.Add('FromSession', $FromSession)
		}
	}
	if (!$IsCopyToAgentMachine)
	{
		Write-Host "creating remote session"
		# Preparing the credentials
		if (!$TargetMachineName)
		{
			Throw "Please provide target machine name"
		}
		if (!$TargetMachineUserName)
		{
			Throw "Please provide a username for target machine"
		}
		if (!$TargetMachinePassword)
		{
			Throw "Please provide a password for target machine"
		}
		if ($IsCopyFromAgentMachine) # '-FromSession' and '-ToSession' are mutually exclusive and cannot be specified at the same time.
		{
			$ToPasswd = ConvertTo-SecureString $TargetMachinePassword -AsPlainText -Force
			$ToCreds = New-Object System.Management.Automation.PSCredential ($TargetMachineUserName, $ToPasswd)
			$ToSession= new-pssession $TargetMachineName -credential $ToCreds
			$params.Add('ToSession', $ToSession)
		}
	}
	if ($IsForce)
	{
		$params.Add('Force', $true)
	}
	if ($IsContainer)
	{
		$params.Add('Container', $true)
	}
	if ($IsRecurse)
	{
		$params.Add('Recurse', $true)
	}
	if ($IsPassThru)
	{
		$params.Add('PassThru', $true)
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

	if ($IsCopyFromAgentMachine -or $IsCopyToAgentMachine)
	{
		Copy-Item @params -Path $Path -Destination $Destination -verbose
	}
	else # '-FromSession' and '-ToSession' are mutually exclusive and cannot be specified at the same time.
	{
		$Scriptblock = {
			param($Path,$Destination,$TargetMachineName,$TargetMachineUserName,$TargetMachinePassword,$params); 
			Write-Host "PSVersion:" $psversiontable.PSVersion.Major
			$to  =([System.Net.Dns]::GetHostAddresses($TargetMachineName) | where-object{$_.Address -ne $null} | sort-object{$_.Address} -Descending).IPAddressToString
			$here=([System.Net.Dns]::GetHostAddresses("$env:computername")| where-object{$_.Address -ne $null} | sort-object{$_.Address} -Descending).IPAddressToString
			Write-host "to:"
			Write-host $to
			Write-host "here:"
			Write-host $here
			if (($to -join "++++") -ne ($here -join "++++"))
			{
				$ToPasswd = ConvertTo-SecureString $TargetMachinePassword -AsPlainText -Force
				$ToCreds = New-Object System.Management.Automation.PSCredential ($TargetMachineUserName, $ToPasswd)
				
				$ToSession= new-pssession $TargetMachineName -credential $ToCreds 
				$params.Add('ToSession', $ToSession)
			}
			else 
			{
				Write-host "SourceMachine and TargetMachine are the same"
			}
			try
			{
				Copy-Item @params -Path $Path -Destination $Destination -verbose
			}
			catch
			{
				get-pssession | remove-pssession
				Write-Error $_.Exception.Message
				exit 1
			}
		}
		Invoke-Command -Session $FromSession -Scriptblock $Scriptblock -ArgumentList $Path,$Destination,$TargetMachineName,$TargetMachineUserName,$TargetMachinePassword,$params
	}
    get-pssession | remove-pssession
}
catch
{
    get-pssession | remove-pssession
    Write-Error $_.Exception.Message
    exit 1
}   