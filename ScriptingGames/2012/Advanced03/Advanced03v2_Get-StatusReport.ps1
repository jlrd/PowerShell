[CmdletBinding(DefaultParametersetName='FileBased')]
Param(
  [Parameter(ParameterSetName='FileBased')]
  [String]$Path = "$env:systemdrive\logonlog\logonstatus.txt",
  [Parameter(ParameterSetName='ObjectBased')]
  [Switch]$PassThru
)

# Acquire various environment variable and WMI properties and methods for reporting
$LoggedOnUser = "$env:userdomain\$env:username"

$ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem | 
                        Select-Object DNSHostName,Domain,BootupState
$OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem
$NetworkConnection = Get-WmiObject -Class Win32_NetworkConnection | 
                            Select-Object LocalName,RemoteName

$DefaultPrinter = Get-WmiObject -Class Win32_Printer | Where-Object {$_.Default}

# Specify and combine the data properties for the report
$Properties = @{
    'CurrentLog' = $(Get-Date);
    'TypeOfBoot' = $ComputerSystem.BootupState
    'LastReboot' = $OperatingSystem.ConvertToDateTime($OperatingSystem.LastBootUpTime) 
    'ComputerName' = "$($ComputerSystem.DNSHostName).$($ComputerSystem.Domain)"
    'UserName' = $LoggedOnUser
    'OperatingSystemVersion' = $OperatingSystem.Version
    'OperatingSystemServicePack' = $OperatingSystem.CSDVersion 
    'DefaultPrinter' = $DefaultPrinter.Name
    'Drive' = $NetworkConnection
}

#Create a new object containing the combined properties, output based on
# parameters chosen.
$Report = New-Object -TypeName PSObject -Property $Properties

If($PassThru)
{
    Write-Output $Report
}
Else
{
    # Test for and handle if parent directory of path does not exist
    If(Test-Path -Path $(Split-Path -Path $Path -Parent))
    {
        $Report | Out-File -Append -FilePath $Path
    }
    Else
    {
        New-Item -ItemType Directory -Path $(Split-Path -Path $Path -Parent) | Out-Null
        $Report | Out-File -Append -FilePath $Path
    }
}

