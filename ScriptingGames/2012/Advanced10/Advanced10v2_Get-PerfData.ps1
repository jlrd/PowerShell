
<# GetPerfData
    1. Use Get-Counter cmdlet to both get the list of Processor set counters, and then 
        gather 10 samples at 2 second interval.
    2. Use Export-Counter to output the gathered perf data to a CSV file under the 
        Documents folder.
#>
(Get-Counter -List Processor).PathsWithInstances | 
Get-Counter -MaxSamples 10 -SampleInterval 2 | 
Export-Counter -Path (
  "$([Environment]::GetFolderPath("MyDocuments"))\$($env:computername)_processorCounters.csv"
) -FileFormat CSV      
      
