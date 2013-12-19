function Get-UptimeReport {
<#
.Synopsis
   Reports on uptime of computer systems
.DESCRIPTION
   The Get-UptimeReport cmdlet reports, outputing csv by default, reports on the uptime 
   of systems from a standard time (8am by default). Systems with a boot time between 
   the 8am base time and report execution are reported as 0 uptime.
.PARAMETER ComputerName
   The ComputerName parameter is a mandatory parameter to provide the systems you wish 
   to return and uptime report for. 
.EXAMPLE
   Get-UptimeReport -ComputerName 'server01','server02','server05'

   Will return an uptime report in CSV format for the 3 servers to the users Documents 
   folder.
.EXAMPLE
   Get-UptimeReport -ComputerName $env:ComputerName

   Will return an uptime report for the local system.
#>
[CmdletBinding()]
Param
(
[Parameter(Mandatory=$true,
           ValueFromPipelineByPropertyName=$true,
           Position=0)]
[string[]]$ComputerName
)
  Begin
  {
    # This cmdlet is dependant on v3 features check and halt if not met.
    Try { 
      If ($PSVersionTable.PSVersion.Major -lt 3)
      { Throw "This cmdlet requires PowerShell version 3.0 or later." }       
    }
    Catch { Write-Warning $_.Exception.Message; Break }

    # Establish some base variables and values
    $OutputPath = $([Environment]::GetFolderPath("MyDocuments"))
    $OutputFile = "$(Get-Date -Format 'yyyyMMdd')_Uptime.csv"
    
    $UptimeBase = Get-Date -Hour 8 -Minute 0 -Second 0 
    $ReportName = Join-Path -Path $OutputPath -ChildPath $OutputFile
    $UptimeReport = @()
    $CurrentSystem = $null
  }
  Process
  {
    $ComputerName | 
    ForEach-Object -Process {
      $CurrentSystem = $_
      Try
      { 
        # Establish the needed WMI properties
        $WmiProperties = @{
            'Class' = 'Win32_OperatingSystem';
            'Property' = 'LastBootUptime';
            'ComputerName' = $_;
            'ErrorAction' = 'Stop';
        }

        # Utilize an empty object using the [WMI] accelerator to call the conversion method
        $Boot = ([WMI]'').ConvertToDateTime($(Get-WmiObject @WmiProperties).LastBootUpTime)
        Write-Verbose "$CurrentSystem > Last Boot: $($Boot.ToString())"
        
        # Esablish the Uptime based on the universal base time, 8am.
        $Uptime = $UptimeBase - $Boot
        Write-Verbose "$CurrentSystem > Uptime (d:h:m:s.ms): $($Uptime.ToString())"    

        If ($Uptime.TotalSeconds -gt 0)
        {
            $Days = $Uptime.Days
            $Hours = $Uptime.Hours
            $Minutes = $Uptime.Minutes
            $Seconds = $Uptime.Seconds
        }
        Else { $Days = $Hours = $Minutes = $Seconds = 0 }

        # Create a new-object with the various learned and calculated values and 
        #  add that object to the array for reporting.
        $BootProperties = @{
            'TypeName' = 'PSObject';
            'Property' = @{
                'ComputerName' = $_;
                'Days' = $Days;
                'Hours' = $Hours;
                'Minutes' = $Minutes;
                'Seconds' = $Seconds;
                'Date' = $Boot.ToShortDateString()
            }
        }
        $UptimeReport += New-Object @BootProperties
      }
      Catch { Write-Warning "$CurrentSystem > $($_.Exception.Message)" }
    }
  }
  End
  {
    # Output the report, since the append parameter is used, a catch is here 
    #  to prevent errors in the event the file is open while run again.
    Try
    {
      $UptimeReport | 
      Select-Object -Property ComputerName,Days,Hours,Minutes,Seconds,Date | 
      Export-Csv -Path $ReportName -Append -NoTypeInformation -ErrorAction Stop
    }
    Catch { Write-Warning $_.Exception.Message }
  }
}


