((Get-Counter -List Processor).PathsWithInstances | 
    Get-Counter -MaxSamples 10 -SampleInterval 2).CounterSamples |
    select Timestamp,Path,CookedValue


(Get-Counter -List Processor).PathsWithInstances | 
    Get-Counter -MaxSamples 10 -SampleInterval 2 |
    Select-Object -ExpandProperty CounterSamples |
    Select-Object Timestamp,Path,CookedValue |
    Export-Csv -NoTypeInformation -Path data.csv


(Get-Counter -List Processor).PathsWithInstances | 
    Get-Counter -MaxSamples 10 -SampleInterval 2 |
    Select-Object -ExpandProperty CounterSamples |
    Select-Object Timestamp,Path,CookedValue | Group-Object Timestamp

$goData = (Get-Counter -List Processor).PathsWithInstances | 
    Get-Counter -MaxSamples 10 -SampleInterval 2 |
    Select-Object -ExpandProperty CounterSamples |
    Group-Object -AsHashTable -AsString



#$data = 
$data = (Get-Counter -List Processor).PathsWithInstances | 
    Get-Counter -MaxSamples 1 |
    Select-Object -ExpandProperty CounterSamples |
    Group-Object Timestamp |
    ForEach-Object -Begin { 
        $script:Properties = @{}
      } -Process {
        $_.Group | ForEach-Object {
                    $script:Properties.Add(($_.Path.ToString()),($_.CookedValue))
                   }      
      } -End {
        New-Object -TypeName PSObject -Property $script:Properties
        $script:Properties.Clear()
      }
