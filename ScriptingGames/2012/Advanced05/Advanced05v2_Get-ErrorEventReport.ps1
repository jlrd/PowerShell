Function Get-ErrorEventReport {
<#
 .SYNOPSIS
    Report on error events from the various available event logs.
 .DESCRIPTION
    The Get-ErrorEventReport cmdlet inspects the various available event logs on one 
    or more computer system, groups the sources of error events on the system and 
    ranks them from greatest to least.
 .EXAMPLE
    Get-ErrorEventReport
    
    Displays to the screen a listing of each found log and a ranking (greatest to least) 
    of the sources of errors for those logs. The default is to check the local system.
    
    ErrorCount Application Log Source [SERVER01]
    ---------- ---------------------------------
        14 WinMgmt
         3 Software Protection Platform Service
    
    In this example the Application event log on Server01 contains 14 WinMgmt errors 
    and 3 Software Protection Platform Service errors.

 .EXAMPLE
    Get-ErrorEventReport -ComputerName server01,server02
    
    Displays the same report as would be returned locally, but returns the report with 
    information about error events from server01 and server02.
 .LINK
    Get-EventLog
    Group-Object
    Sort-Object
 #>
[CmdletBinding()]
Param
(
[Parameter()]
[string[]]$ComputerName = @("$env:computername")
)
  Begin {
    # Set common variables and re-useable script blocks
    $Script:System = $null
    $Script:CurrentLogName = $null
    
    # ScriptBlock to parse and display ordered error report
    $Script:LogCountScript = {
        param($SystemName,$LogName)
        Try 
        {
            $Properties = @{'ComputerName' = $SystemName;
                            'LogName' = $LogName;
                            'EntryType' = 'Error';
                            'ErrorAction' = 'SilentlyContinue'
            }
            Get-EventLog @Properties | 
            Group-Object -Property Source | 
            Sort-Object -Property Count -Descending |
            Select-Object -Property @{Name="ErrorCount";
                                       Expression={$_.Count}},
                                    @{Name="$($LogName) Log Source [$($SystemName)]";
                                       Expression={$_.Name}} | 
            Out-String
            # Out-String keeps individual log reports from object-merging on output !?@#
            # If Write-Host kills puppies, does Out-String kill goldfish ?? ;)                        
        }
        Catch
        {
                Write-Warning "$SystemName > $LogName > $($_.Exception.Message)"
                Continue
        }
    }
  
  }
  Process
  {
   # Pipe string array of 1 or more computer names through script
   $ComputerName | 
   ForEach-Object -Process {
        $Script:System = $_
        Write-Verbose "System: $Script:System"
        
        # Generate list of available Event Logs
        Get-EventLog -ComputerName $Script:System -List |
        ForEach-Object -Process {
            $Script:CurrentLogName = $_.Log
            Write-Verbose "Current Log: $Script:CurrentLogName"
            
            # Determine if the available log has >1 error present within
            Try 
            {
                $Properties = @{
                    'ComputerName' = $Script:System;
                    'LogName' = $Script:CurrentLogName;
                    'EntryType' = 'Error';
                    'Newest' = 1;
                    'ErrorAction' = 'Stop'
                }
                $ErrorsPresent = Get-EventLog @Properties
                
                # If >1 error are present call main ScriptBlock for display
                If ($ErrorsPresent)
                {
                   $Properties = @{
                        'ScriptBlock' = $Script:LogCountScript;
                        'ArgumentList' = "$($Script:System)","$($Script:CurrentLogName)"
                    }
                    Invoke-Command @Properties
                }
            }
            Catch 
            { 
              Write-Warning "$Script:System > $Script:CurrentLogName > $($_.Exception.Message)"
            }
        }
    }
  }
}

