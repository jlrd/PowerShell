## ENV setup
[Environment]::SetEnvironmentVariable('FigletRoot',"$ENV:USERPROFILE\Documents\PowerShell\Includes\FigletFonts")

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

