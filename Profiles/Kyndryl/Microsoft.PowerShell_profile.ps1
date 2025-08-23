## ENV setup
[Environment]::SetEnvironmentVariable('FigletRoot',"$ENV:USERPROFILE\OneDrive - kyndryl\Documents\PowerShell\SpectreFonts")
[Environment]::SetEnvironmentVariable('POSH_THEMES_PATH',"$ENV:USERPROFILE\OneDrive - kyndryl\Documents\PowerShell\OhMyPoshThemes")

## Oh My Posh prompt setup
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\blue-owl.omp.json" | Invoke-Expression

## Encoding setup for best PwshSpectreConsole support
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

## PwshSpectreConsole MoTD setup
if (Get-Module -ListAvailable -Name PwshSpectreConsole) {
    Write-SpectreFigletText -Text "PowerShell" -Alignment Right -Color CornflowerBlue -FigletFontPath "$ENV:FigletRoot\3d.flf"
    $PSVersionTable | 
    Format-SpectreTable -Property PSVersion,PSEdition -Border Rounded -HeaderColor Yellow -Color CornflowerBlue -Width 80 |
    Format-SpectreAligned -HorizontalAlignment Right -VerticalAlignment Middle
}

function Start-Monitor
{
	[Cmdletbinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]$Minutes
	)

	Begin
	{
		Write-Verbose " [$($MyInvocation.InvocationName)] :: Start Process"
	}

	Process
	{
		Add-Type -AssemblyName System.Windows.Forms
		$shell = New-Object -com "Wscript.Shell"

		$pshost = Get-Host
		$pswindow = $pshost.ui.rawui
		$pswindow.windowtitle = 'Monitor'

        if(!$minutes)
        {
        $Minutes = Read-Host -Prompt "Enter minutes for monitoring: "
        }

		for ($i = 0; $i -lt $Minutes; $i++)
		{
			Clear-Host
			$timeleft = $Minutes - $i
			Write-Host (Get-Date -Format HH:mm:ss) -ForegroundColor Green
			Write-Host 'Monitor left: ' -NoNewline
			Write-Host "$timeleft" -ForegroundColor Red -NoNewline
			Write-Host ' Minutes'
			$shell.sendkeys(' ')
			for ($j = 0; $j -lt 6; $j++)
			{
				for ($k = 0; $k -lt 10; $k++)
				{
					Write-Progress -Activity 'Evaluating reality ...' -PercentComplete ($k * 10) -Status "Please ... don't disturb me."
					Start-Sleep -Seconds 1
				}
			}
			$Pos = [System.Windows.Forms.Cursor]::Position
			$x = ($pos.X % 500) + 1
			$y = ($pos.Y % 500) + 1
			[System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
		}
		## End of monitor awareness
		[console]::beep(500,500)
		[console]::beep(700,500)
		[console]::beep(900,500)
	}
	End
	{
		Write-Verbose " [$($MyInvocation.InvocationName)] :: End Process"
	}
}

function New-RDPFile {
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
}