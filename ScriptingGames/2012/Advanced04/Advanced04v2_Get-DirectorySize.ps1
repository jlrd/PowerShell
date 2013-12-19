function Get-DirectorySize
{
<#
.Synopsis
   Get size of directory specified.
.DESCRIPTION
   Get-DirectorySize is a cmdlet that returns the size of the directory specificed 
   by parameter. By default it will recursively report the size of all sub-directories 
   as well. The path to a directory must be specified for this cmdlet.
.PARAMETER Path
   The Path parameter determines the starting ponint for reporting of directory 
   sizing. By default sub-directories are also reported on.
.PARAMETER NoRecurse
   The NoRecurse parameter can be specified to report on only the path specified. The 
   default is to recurse sub-directories.
.EXAMPLE
   Get-DirectorySize -Path C:\Users\joel\Documents

   Will output an object with three properties; fullname, display bytes, and raw bytes of C:\Users\joel\Documents 
   and all sub-directories. 
.EXAMPLE
   Get-DirectorySize -Path C:\PerfLogs -NoRecurse

   Will output an object with three properties; fullname, display bytes, and raw bytes for C:\PerfLogs only
   no sub-directories will be calculated.
.EXAMPLE
   Get-DirectorySize -Path C:\Users\jlrd\Dropbox | Sort-Object RawBytes -Descending

   Will output a size calculation for Dropbox and all enclosed sub-directories. The output is pipelined to the 
   Sort-Object cmdlet that performs a descending sort on the RawBytes property. Displaying largest directories 
   first and smallest directories last.
   
.LINK
Get-ChildItem
Sort-Object
#>
[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$true,
               Position=0,
               HelpMessage="Please enter a valid file system path to a directory.")]
      [ValidateScript({$(Get-Item -Path $_).PSIsContainer})]
    [string]$Path,
    [Parameter()]
    [switch]$NoRecurse
)
Begin { 
    #Establish some common variables and script blocks for re-use.
    $Report = @() 
    # Resolve path if path param is specified relative, output more effective.
    $Path = Resolve-Path -Path $Path
    
    # Common script to filter and create the DisplayBytes property
    $DisplayBytesScript = {
        ForEach-Object -Process {
            If($_ -gt 1GB)
            {
                "{0:N2}GB" -f [decimal]"$($_ / 1GB)"
            } 
            ElseIf($_ -gt 1MB) 
            {
                "{0:N2}MB" -f [decimal]"$($_ / 1MB)"
            }
            Else
            {
                "{0:N2}KB" -f [decimal]"$($_ / 1KB)"
            }
        }
    }
    
    # Common script to calculate the size of a directory, passed by param
    $GetBytesScript = {
        Param($FullName)
        $(Get-ChildItem -Path $FullName -Recurse | Where-Object {$_.Length} | 
            Measure-Object -Property Length -Sum).Sum
    }
}

Process {
    # Determine Size of choosen start directory using establish scriptblock
    $RawBytes = Invoke-Command -ScriptBlock $GetBytesScript -ArgumentList $Path
    Write-Verbose "Processing: $Path"
    
    # Establish properties based on returned values for reporting, add object to report 
    # collection.
    $Properties = @{'FullName' = $Path; 
                    'RawBytes' = $RawBytes;
                    'DisplayBytes' = $RawBytes | Invoke-Command -ScriptBlock $DisplayBytesScript
                   }
    $Report += New-Object -TypeName PSObject -Property $Properties

    # Proceed as above, by calculating all sub-directories, if the default 
    # to recurse remains chosen.
    If(!$NoRecurse){
        Get-ChildItem -Path $Path  -Recurse | Where-Object {$_.PSIsContainer} | 
        ForEach {
            $RawBytes = Invoke-Command -ScriptBlock $GetBytesScript -ArgumentList $_.FullName
            Write-Verbose "Processing: $($_.FullName)"

            $Properties = @{'FullName' = $_.FullName; 
                            'RawBytes' = $RawBytes;
                            'DisplayBytes' = $RawBytes | Invoke-Command -ScriptBlock $DisplayBytesScript
                           }
            $Report += New-Object -TypeName PSObject -Property $Properties
        }
    }
  }
# Output Report collection for viewing and further analysis via pipeline
End { Write-Output $Report }
}
