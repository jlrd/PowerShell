Function Get-ErrorReport {
<#
 .Synopsis
    Short description
 .DESCRIPTION
    Long description
 .EXAMPLE
    Example of how to use this cmdlet
 .EXAMPLE
    Another example of how to use this cmdlet
 #>
[CmdletBinding()]
Param
(
[Parameter()]
[string[]]$ComputerName = @("$env:computername")
)
  Begin {
    $Script:JLRDSystem = $null
    $Script:JLRDCurrentLogName = $null
  }
  Process
  {
   $ComputerName | ForEach-Object -Process {
   
   $Script:JLRDSystem = $_
   Write-Verbose "System: $_"
   
    Get-EventLog -List |
    ForEach-Object -Process {
        $Script:JLRDCurrentLogName = $_.Log
        Write-Verbose "Current Log: $($_.Log)"
   Try {
        
        Get-EventLog -LogName $_.Log -EntryType Error -ErrorAction SilentlyContinue | 
        Group-Object -Property Source | 
        Sort-Object -Property Count -Descending 
        <#
        | 
        Select-Object -Property @{Name="ErrorCount";Expression={$_.Count}},
                                @{Name="Log Source";Expression={$_.Name}} 
        #>
   }
   Catch {
    Write-Verbose "$($Script:JLRDSystem) -> $($Script:JLRDCurrentLogName)"
    Write-Warning $_.Exception.Message
    Continue
   
    }
   }
  }
  
  }
}