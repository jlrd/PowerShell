<#
.SYNOPSIS
	A simple random password generation function
.DESCRIPTION
	Just a simple random password generating function.
.NOTES
	This is a basic function with 3 parameters which all have default values. No parameters necessary.
.LINK
	No link needed for a simple function...
.EXAMPLE
	Get-JLRDRandomPassword
	Using defaults to generates 1 password of 32 characters and no character repeating a max of 3 times
.EXAMPLE
	Get-JLRDRandomPassword -Generate 3
	Using defaults to generates 1 password of 32 characters and no character repeating a max of 3 times
#>

#Requires -Version 7.1

$ScriptMetadata = @{
	Note              = 'This Thing'
	Context           = 'Somewhere'
	PowerShellVersion = '7.1'
}
$ScriptMetadata | Out-Null

function Get-JLRDRandomPassword {
	[CmdletBinding()]
	param (
		[parameter()]
		[int]$Length = 32,
		[parameter()]
		[int]$CharRepeatMax = 3,
		[parameter()]
		[int]$Generate = 1
	)
	
	For ($i = 0; $i -lt $Generate; $i++) {
		New-Object PSObject -Property @{ Password = $( ( $([char[]]@(48..57) * (Get-Random -Minimum 1 -Maximum ($CharRepeatMax + 1)) | Get-Random -Count ([int]::MaxValue)) + 
					$([char[]]@(65..90) * (Get-Random -Minimum 1 -Maximum ($CharRepeatMax + 1)) | Get-Random -Count ([int]::MaxValue)) + 
					$([char[]]@(97..122) * (Get-Random -Minimum 1 -Maximum ($CharRepeatMax + 1)) | Get-Random -Count([int]::MaxValue)) | Get-Random -Count $Length) -join '' )
  }
	}
}