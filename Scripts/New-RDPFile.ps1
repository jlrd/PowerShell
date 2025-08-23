[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Path = "$ENV:OneDrive\Documents\RemoteDesktops\",
    [Parameter()]
    [string]
    $ComputerName,
    [Parameter()]
    [string]
    $IpAddress,
    [Parameter()]
    [string]
    $UserName
)

# Import the StringBuilder class

# Add-Type -AssemblyName "System.Text"

# Create a new StringBuilder object
$RdpFileBuilder = [System.Text.StringBuilder]::new()

# Append strings
[void]$RdpFileBuilder.AppendLine("alternate full address:s:${ComputerName}")
[void]$RdpFileBuilder.AppendLine("full address:s:${IpAddress}")
[void]$RdpFileBuilder.AppendLine("prompt for credentials:i:1")
[void]$RdpFileBuilder.AppendLine("administrative session:i:1")
[void]$RdpFileBuilder.AppendLine("username:s:${UserName}")

$OutputPath = Join-Path -Path $Path -ChildPath "${ComputerName}.rdp"

$RdpFileBuilder.ToString() | Out-File -FilePath $OutputPath -Force
