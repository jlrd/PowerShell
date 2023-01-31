$PowerShellFile = 'C:\Users\joelr\Repos\PowerShell\Liners\Get-RandomPassword.ps1'

Write-Output "Beginning processing the Abstract Syntax Tree for the PowerShell file $PowerShellFile `n" 

## Get the AST of a file
$AST = [System.Management.Automation.Language.Parser]::ParseFile($PowerShellFile, [ref]$null, [ref]$null)

## Get the value of the Requires statement within a PowerShell file
Write-Output 'The "#Requires" value (as an object) from the processed file via AST ...'
$AST.ScriptRequirements.RequiredPSVersion

Write-Output "`nGet a PowerShell object from AST for the Help contents of a PowerShell file ..."
$AST.GetHelpContent()

## Extract, in this case, a particular variable, in this case a hashtable, named 'ScriptMetadata'
$Metadata = $ast.findall({ $args[0].VariablePath -match 'ScriptMetadata' }, $true)

## "hydrate" the variable text so that it is a hashtable within the context of script doing the AST analysis
$LiveMetadataHashtable = Invoke-Expression -Command $Metadata.Extent.Text

Write-Output "`nThe Note property of the 'ScriptMetadata' hashtable : $($LiveMetadataHashtable.Note)"

Write-Output "`nValid Hashtable type for 'ScriptMetadata', aka the hashtable is now 'live' in our session..."
$LiveMetadataHashtable.GetType().FullName

Write-Output "`nFull contents of the 'ScriptMetadata' hashtable..."
$LiveMetadataHashtable | Format-Table