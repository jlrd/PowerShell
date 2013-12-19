function Get-JLRDRandomPassword{
	[CmdletBinding()]
	param (
		[parameter()]
		[int]$Length = 32,
		[parameter()]
		[int]$CharRepeatMax = 3,
		[parameter()]
		[int]$Generate = 1
	)
	
	For($i=0; $i -lt $Generate; $i++) {
		New-Object PSObject -Property @{ Password = $( ( $([char[]]@(48..57) * (Get-Random -Minimum 1 -Maximum ($CharRepeatMax + 1)) | Get-Random -Count ([int]::MaxValue)) + 
		                                                 $([char[]]@(65..90) * (Get-Random -Minimum 1 -Maximum ($CharRepeatMax + 1)) | Get-Random -Count ([int]::MaxValue)) + 
														 $([char[]]@(97..122) * (Get-Random -Minimum 1 -Maximum ($CharRepeatMax + 1)) | Get-Random -Count([int]::MaxValue)) | Get-Random -Count $Length) -join "" )}
	}
}