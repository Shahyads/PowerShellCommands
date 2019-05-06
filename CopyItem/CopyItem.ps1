[cmdletbinding()]
param
(
   [Parameter(Mandatory=$false)][string] $Path,
   [Parameter(Mandatory=$false)][string] $CopyFromAgentMachine,
   [Parameter(Mandatory=$false)][string] $SourceMachineName,
   [Parameter(Mandatory=$false)][string] $SourceMachineUserName,
   [Parameter(Mandatory=$false)][string] $SourceMachinePassword,
   
   [Parameter(Mandatory=$false)][string] $Destination,
   [Parameter(Mandatory=$false)][string] $CopyToAgentMachine,
   [Parameter(Mandatory=$false)][string] $TargetMachineName,
   [Parameter(Mandatory=$false)][string] $TargetMachineUserName,
   [Parameter(Mandatory=$false)][string] $TargetMachinePassword,

   [Parameter(Mandatory=$false)][string] $Container,
   [Parameter(Mandatory=$false)][string] $Force,
   [Parameter(Mandatory=$false)][string] $Filter,
   [Parameter(Mandatory=$false)][string] $Include,
   [Parameter(Mandatory=$false)][string] $Exclude,
   [Parameter(Mandatory=$false)][string] $Recurse,
   [Parameter(Mandatory=$false)][string] $PassThru,
   [Parameter(Mandatory=$false)][string] $WhatIf
)
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