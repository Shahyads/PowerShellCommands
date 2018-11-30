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
		$params.Add('FromSession', $FromSession)
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
		$ToPasswd = ConvertTo-SecureString $TargetMachinePassword -AsPlainText -Force
		$ToCreds = New-Object System.Management.Automation.PSCredential ($TargetMachineUserName, $ToPasswd)
		$ToSession= new-pssession $TargetMachineName -credential $ToCreds
		$params.Add('ToSession', $ToSession)
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
	
	Copy-Item @params -Path $Path -Destination $Destination -Confirm
}
catch
{
    Write-Error $_.Exception.Message
    exit 1
}   