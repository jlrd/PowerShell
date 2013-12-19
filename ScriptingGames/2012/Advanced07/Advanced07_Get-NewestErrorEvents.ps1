<# GetNewestErrorEvents - one liner
    1. Uses Get-WinEvent to list logs, filtered by enabled and non-zero quantity events
    2. Create empty array to contain found newest errors
    3. For each of the found logs, run Get-WinEvent again and filter on LogName, Errors,
        and sort and select the newest error.
    4. Output the filled array sorting newest to oldest, and select important properties.
#>
Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | 
    Where-Object {$_.IsEnabled -and $_.RecordCount -ge 1} |
    ForEach-Object -Begin { 
          $NewestErrors=@() 
      } -Process {
          $NewestErrors += Get-WinEvent -ErrorAction SilentlyContinue -FilterHashtable @{
                                                                        'LogName'=$_.LogName;
                                                                        'Level'=2} |
                              Sort-Object -Property TimeCreated -Descending | 
                              Select-Object -First 1
      } -End { $NewestErrors } |
Sort-Object -Property TimeCreated -Descending | 
Select-Object -Property TimeCreated,LogName,Id,Message
