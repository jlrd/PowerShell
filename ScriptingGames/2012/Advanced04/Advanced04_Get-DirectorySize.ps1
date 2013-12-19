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

   Will output an object with two properties; fullname and size of C:\Users\joel\Documents 
   and all sub-directories.
.EXAMPLE
   Get-DirectorySize -Path C:\PerfLogs -NoRecurse

   Will output an object with two properties; fullname and size for C:\PerfLogs
.LINK
Get-ChildItem
#>
[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$true,
               Position=0)]
    [string]$Path,
    [Parameter()]
    [switch]$NoRecurse
)
Begin { 
    $Report = @() 
    $Path = Resolve-Path -Path $Path
    $SizeScript = {
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
}

Process {
    $Properties = @{'FullName' = $Path; 
                    'Size' = $(Get-ChildItem -Path $Path -Recurse | 
                                Measure-Object -Property length -Sum).Sum | 
                                Invoke-Command -ScriptBlock $SizeScript
                   }
    $Report += New-Object -TypeName PSObject -Property $Properties

    If(!$NoRecurse){
        Get-ChildItem -Path $Path  -Recurse | Where {$_.PSIsContainer} | 
        ForEach {
            Write-Verbose "Processing: $($_.FullName)"
            $Properties = @{'FullName' = $_.FullName; 
                            'Size' = $(Get-ChildItem -Path $_.FullName -Recurse | 
                                        Measure-Object -property length -Sum).Sum | 
                                        Invoke-Command -ScriptBlock $SizeScript
                           }
            $Report += New-Object -TypeName PSObject -Property $Properties
        }
    }
  }
End { Write-Output $Report }
}
