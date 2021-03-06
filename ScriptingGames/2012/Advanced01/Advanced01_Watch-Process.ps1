Function Watch-Process {
<#
.SYNOPSIS
Gets information about a process for a specified period of time.

.DESCRIPTION
The Watch-Process cmdlet monitors a selected process for a period of time. The 
monitored process name is specified as a parameter to the cmdlet. 

The default is to monitor the selected process for 10 seconds, a different 
duration can be optionally specified as a parameter. 

The monitoring output consists of typical Get-Process cmdlet output.

.PARAMETER Name 
The name of the running system process to be monitored.

.PARAMETER Duration
The amount of time in seconds to monitor the process. If specified the value
must be at least 1 second. The default is 10 seconds.

.EXAMPLE
Watch-Process -Name Notepad

.EXAMPLE
Watch-Process -Name Notepad -Duration 30

.LINK
Get-Process
#>

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,
             Position=0,
             HelpMessage='Please specify a running system process to monitor.')]
    [ValidateScript({Get-Process -Name $_})]
  [String]$Name,
  [Parameter()]
    [ValidateScript({$_ -ge 1})]
  [Int]$Duration = 10
)

PROCESS { 

    For ($i = 1 ; $i -le $Duration ; $i++)
    {
        $Process = Get-Process -Name $Name
        Write-Output $Process
        Start-Sleep -Seconds 1
    }
  }
}


