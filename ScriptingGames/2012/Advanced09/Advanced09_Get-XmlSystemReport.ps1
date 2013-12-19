function Get-XmlSystemReport {
<#
.Synopsis
   Writes XML based report of several important system values.
.DESCRIPTION
   The Get-XmlSystemReport by default writes an xml file containing a number 
   of important system values to the file system. If the values cannot be 
   retrieved then 'N/A' is returned as validation of attempt but no value. 
   The users documents directory is the location by default. This output path 
   can be overridden using the -FilePath parameter.
.PARAMETER FilePath
   The FilePath parameter specifies the path to a directory location for the 
   report. By default that path is the users Documents folder.
.PARAMETER PassThru
   The PassThru parameter outputs the XML formatted report to output for 
   further processing on the pipeline.
.EXAMPLE
   Get-XmlSystemReport
   
   Returns the XML outputted report to users Documents folder.
.EXAMPLE
   Get-XmlSystemReport -FilePath D:\Reporting
   
   Returns the XML formatted reprot to the D:\Reporting directory.
.EXAMPLE
   Get-XmlSystemReport -PassThru
   
   Returns the XML formatted report to the output for further processing on 
   the pipeline.    
#>
[CmdletBinding(DefaultParametersetName='FileBased')]
Param(
[Parameter(Position=0,
           ParameterSetName='FileBased')]
[string]$FilePath = $([Environment]::GetFolderPath("MyDocuments")),
[Parameter(ParameterSetName='ObjectBased')]
[switch]$PassThru
)
  Begin
  {
    $report = @()
    
    # Get basic properties for Xml system report, ErrorAction is SilentlyContinue as individual 
    #  properties are checked later.
    $win32Comp = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue | 
                  Select-Object -Property Manufacturer,Model,DNSHostName,Domain,TotalPhysicalMemory
    $win32OS = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction SilentlyContinue | 
                Select-Object -Property Version,CSDVersion
    $win32Proc = Get-WmiObject -Class Win32_Processor -ErrorAction SilentlyContinue
    $win32Net = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue | 
                 Where-Object {$_.IPAddress -and $_.MACAddress -and $_.DefaultIPGateway} |
                 Select-Object -Property MACAddress
  
    # Re-useable scriptblock to test an InputObject from parameter for $null 
    #  if the value is null, return "Empty" so it's clear in the report that a 
    #  value was not available.
    $NullNotify = 'N/A'
    $ValueNull = {
        param($InputObject)
        If($InputObject)
        {
            return $InputObject
        }
        Else
        {
            return $NullNotify
        }
    }
    
    # Rather than test for $null and return 'Empty', go "out-of-band" for properties necessary 
    #  for file name generation.
    If($win32Comp.DNSHostName -and $win32Comp.Domain)
    {
      $ReportFileName = "$($win32Comp.DNSHostName).$($win32Comp.Domain).$(Get-Date -Format 'yyyyMMdd').xml"
    } 
    Else
    {
      $ReportFileName = "$env:computername.$env:userdomain.$(Get-Date -Format 'yyyyMMdd').xml"
    }
    
    # Build path from file name and default (or selected) output path.
    If(!$PassThru){ $OutputPath = Join-Path -Path $FilePath -ChildPath $ReportFileName }

  }
  Process
  {
    # Build a property hastable for splatting to a new-object
    # Also each property is checked for null using the & 'call' operator 
    #  to execute the scriptblock built above with the intended property as a parameter.
    #  Some properties require a little more validation or manipulation for an appropriate 
    #  return.
    $Properties = @{
        'TypeName' = 'PSObject';
        'Property' = @{
            'ComputerName' = &$ValueNull $win32Comp.DNSHostName;
            'Domain' = &$ValueNull $win32Comp.Domain;
            'Manufacturer' = &$ValueNull $win32Comp.Manufacturer;
            'Model' = &$ValueNull $win32Comp.Model;
            'NumberOfProcs' = &$ValueNull $($win32Proc | Measure-Object).Count;
            'NumberOfCores' = &$ValueNull $($win32Proc | 
                                            ForEach-Object -Begin {
                                              $Cores = $null
                                             } -Process {
                                              $Cores += [int]$($_.NumberOfCores)
                                             } -End {
                                              $Cores
                                             }
                                          ); 
            'SpeedOfProcs' = &$ValueNull $win32Proc.MaxClockSpeed;
            'ProcID' = &$ValueNull $win32Proc.ProcessorID;
            'MACAddress' = &$ValueNull $win32Net.MACAddress;
            'OSVersionAndServicePack' = "$(&$ValueNull $win32OS.Version) $(&$ValueNull $win32OS.CSDVersion)";
            'PhysicalMemory' = &{ If($(&$ValueNull $win32Comp.TotalPhysicalMemory) -ne $NullNotify)
                                  {
                                    "{0:N2}GB" -f $($win32Comp.TotalPhysicalMemory / 1GB)
                                  }
                                  Else
                                  {
                                    &$ValueNull $win32Comp.TotalPhysicalMemory
                                  }
                                };
        }
    }        
    $report += New-Object @Properties

  }
  End
  {
      # Create a hastable for splatting to fix display order
      $Ordered = @{'Property' = 'ComputerName',
                                'Domain',
                                'Manufacturer',
                                'Model',
                                'NumberOfProcs',
                                'NumberOfCores',
                                'SpeedOfProcs',
                                'ProcID',
                                'MACAddress',
                                'OSVersionAndServicePack',
                                'PhysicalMemory'
                  }

      # Handle either disposition of the object either filebased (the default) or 
      #  passthru. Either way an XML document is returned containing the report values.
      If($PassThru)
      {
        Write-Output $report | Select-Object @Ordered | 
            ConvertTo-Xml -As Document -NoTypeInformation 
      }
      Else
      {
        $report | Select-Object @Ordered | 
            ConvertTo-Xml -As String -NoTypeInformation | Out-File -FilePath $OutputPath
      }
  }
}


