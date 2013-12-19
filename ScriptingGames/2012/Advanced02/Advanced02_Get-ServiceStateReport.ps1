Function Get-ServiceStateReport {
<#
.SYNOPSIS
Gets report of computer(s) service state.

.DESCRIPTION
The Get-ServiceStateReport cmdlet reports on the service state on local or remote 
computer systems. 

The default is to report on the local computer services state. Remote computers (or
a multiple of computers) can be reported on as well.

Remote systems may also be accessed with alternate credentials.

.PARAMETER ComputerName 
The name of the computer system to report on service state. Multiple computer 
systems can be specified. The default is the local system.

.PARAMETER Path
The file path where report file (Excel/CSV) will be generated too. The default is 
to the root of the 'My Documents' folder.

.PARAMETER Credential
The alternate username to use for remote access. The accepted formats are of 
domain\user or user@domain. If specified a dialog will appearing prompting for 
the password associated with that account.

.PARAMETER PassThru
The default is to output a Excel/CSV file. The PassThru parameter will only 
produce objects, useful for further pipeline manipulation. 

.EXAMPLE
Get-ServiceStateReport

Returns a report of local system services

.EXAMPLE
Get-ServiceStateReport -ComputerName @('Server01','Server02') -Credential joel@domain

Returns a report of system services from remote systems; Server01 and Server02. Also specifices
credential with access to remote system services.

.EXAMPLE
Get-ServiceStateReport -Path C:\Directory\For\ReportName.csv

Returns a local system services report to a non-default location. The default is the root 
of the 'My Documents' folder.

.EXAMPLE
Get-ServiceStateReport -PassThru

Returns the report data as PowerShell objects. Useful for troubleshooting or further 
manipulation on the pipeline.

.LINK
Get-Service
New-PSSession
Get-Credential
Get-WmiObject
#>

[CmdletBinding()]
Param(
  [Parameter()]
  [String[]]$ComputerName = $($env:ComputerName),
  [Parameter()]
  [String]$Path = "$([Environment]::GetFolderPath("MyDocuments"))\Rpt_$(Get-Date -Format 'yyyyMMdd-hhmm').csv",
  [Parameter()]
  [String]$Credential,
  [Parameter()]
  [Switch]$PassThru
)

PROCESS {
    # Common ScriptBlock and filter to generate report
    $ReportScript = {Get-WmiObject -Class Win32_Service}
    $ReportFilter = @{'Property' = 'SystemName','Name','StartMode','State','StartName'}
    
    If ($ComputerName -eq $($env:ComputerName))
    {
        # Invoke script locally if defaults kept
        $Properties = @{'ScriptBlock' = $ReportScript}

        $ReportData = Invoke-Command @Properties | Select-Object @ReportFilter
    }
    Else 
    {
        # Catch any access denied or connectivity issues
        Try {
            If ($Credential)
            {
                $Properties = @{'ComputerName' = $ComputerName;
                                'Credential' = $(Get-Credential -Credential $Credential);
                                'ErrorAction' = 'Stop'}

                $Session = New-PSSession @Properties
            }
            Else
            {
                $Properties = @{'ComputerName' = $ComputerName;
                                'ErrorAction' = 'Stop'}
                
                $Session = New-PSSession @Properties
            }
        }
        Catch
        {
            Write-Warning $_.Exception.Message
            Break
        }

        # Invoke script remotely with established session
        $Properties = @{'Session' = $Session;
                        'ScriptBlock' = $ReportScript}

        $ReportData = Invoke-Command @Properties | Select-Object @ReportFilter
    }

    # Write report to file or output for troubleshooting or further pipelining
    If (!$PassThru)
    {
        $ReportData | Export-Csv -Path $Path -NoTypeInformation
    }
    Else
    {
        Write-Output $ReportData
    }
  }
}