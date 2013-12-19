#This script supports either no parameters (report to file), or Path (alt file location), 
# or PassThru (object output). It also can be directly invoked or dot sourced. 
[CmdletBinding(DefaultParametersetName='FileBased')]
Param(
  [Parameter(ParameterSetName='FileBased')]
  [String]$Path,
  [Parameter(ParameterSetName='ObjectBased')]
  [Switch]$PassThru
)

Function Get-StatusReport {
<#
.SYNOPSIS
Gets report of user and computer status.

.DESCRIPTION
The Get-StatusReport cmdlet reports on several points of interest for systems 
and users.

The default is execute the report and save the report to the system drive under 
logonlog\logonstatus.txt, i.e. C:\logonlog\logonstatus.txt 

.PARAMETER Path 
The path, including file name, where the report is to be output to. The default 
is on the system drive at logonlog\logonstatus.txt.

.PARAMETER PassThru
Bypasses generation of the report to a file and output the objects directory. Ideal 
for further utilization on the pipeline.

.EXAMPLE
Get-StatusReport -Path D:\Reports\SystemUserStatus.txt

.EXAMPLE
Get-StatusReport -PassThru

#>

[CmdletBinding(DefaultParametersetName='FileBased')]
Param(
  [Parameter(ParameterSetName='FileBased')]
  [String]$Path = "$env:systemdrive\logonlog\logonstatus.txt",
  [Parameter(ParameterSetName='ObjectBased')]
  [Switch]$PassThru
)

PROCESS {
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
            New-Item -ItemType Directory -Path $(Split-Path -Path $Path -Parent) | 
                Out-Null
            $Report | Out-File -Append -FilePath $Path
        }
    }
  }
}

#Utilize the $MyInvocation automatic variable to determine the means by which 
# the script was executed direct invocation or dot sourcing and hand parameter 
# passing appropriately.
If($MyInvocation.InvocationName -ne '.')
{
    If($PSBoundParameters.ContainsKey('PassThru'))
    {
        Invoke-Expression -Command "Get-StatusReport -PassThru"
    }
    ElseIf($PSBoundParameters.ContainsKey('Path'))
    {
        Invoke-Expression -Command "Get-StatusReport -Path $($PSBoundParameters.Item('Path'))"
    }
    Else
    {
        Invoke-Expression -Command "Get-StatusReport" 
    }

}