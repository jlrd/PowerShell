function Switch-NetworkAdapter
{
<#
.Synopsis
   Swap enabled network interfaces to prevent bridging.
.DESCRIPTION
   The Switch-NetworkAdapter cmdlet has no parameters and simply enables one interface 
   and disables the other interface. Preventing the bridging of networks from wireless to 
   wired or vice-versa.
.EXAMPLE
   Switch-NetworkAdapter
#>
[CmdletBinding()]
Param
()
  Begin
  {
    # Check to see whether user/session excuting cmdlet is admin level
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()  
    $principal = new-object Security.Principal.WindowsPrincipal $identity 
    $elevated = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    If(!$elevated)
    {
        Write-Warning "This cmdlet requires administrator rights. Please re-run the cmdlet as Administrator."
        Return
    }
    
    # Check to see that it is being executed on a laptop
    If((Get-WmiObject -class Win32_SystemEnclosure).ChassisTypes -ne 10)
    {
        Write-Warning "This cmdlet is intended to be used only on laptops."
        Return  
    }   

    # Get the inital data set
    $EnabledSet = Get-WmiObject Win32_NetworkAdapter | Where {$_.PhysicalAdapter -and $_.NetEnabled}
    $DisabledSet = Get-WmiObject Win32_NetworkAdapter | Where {$_.PhysicalAdapter -and !$_.NetEnabled}
    
    # Initalize some common scriptblocks for reuseable code
    $Prompt = {
        param([string]$fromState,[string]$toState)
        $prompt = "From the list of $fromState devices please select which interface you "
        $prompt += "wish $toState. Choose a DeviceId to be $toState"    
        Read-Host -Prompt $prompt
    }
    $NetAdapter = {
        param([int]$deviceId)
        Get-WmiObject -Class Win32_NetworkAdapter | Where { $_.DeviceID -eq $deviceId }
    }
  }
  Process
  {
    # Handle the default condition of a straight 1 to 1 flip/flop
    If(($EnabledSet | Measure-Object).Count -eq 1 -and ($DisabledSet | Measure-Object).Count -eq 1)
    {
        Write-Verbose "Enabled Set: $($EnabledSet.Name)" 
        $EnabledSet.Disable()
        Write-Verbose "Disabled Set: $($DisabledSet.Name)"
        $DisabledSet.Enable()
    }
    # Handle when more than 1 option exist for enabled or disabled interfaces
    ElseIf(($EnabledSet | Measure-Object).Count -gt 1)
    {
        Write-Verbose "Enabled Prompt"
        $EnabledSet | 
            ForEach-Object -Process { $_ | Select-Object Name,DeviceID } | 
            Format-List
        [int]$DisabledChoice = Invoke-Command -ScriptBlock $Prompt -ArgumentList 'enabled','disabled'
        Write-Verbose "Disabled Choice: $($DisabledChoice)"
       
        $Interface = Invoke-Command -ScriptBlock $NetAdapter -ArgumentList $DisabledChoice
        Write-Verbose "Disabled $($Interface.Name)"
        $Interface.Disable()
    }
    ElseIf(($DisabledSet | Measure-Object).Count -gt 1)
    {
        Write-Verbose "Disabled Prompt"
        $DisabledSet | 
            ForEach-Object -Process { $_ | Select-Object Name,DeviceID } | 
            Format-List
        [int]$EnabledChoice = Invoke-Command -ScriptBlock $Prompt -ArgumentList 'disabled','enabled'
        Write-Verbose "Enabled Choice: $($EnabledChoice)"
 
        $Interface = Invoke-Command -ScriptBlock $NetAdapter -ArgumentList $EnabledChoice
        Write-Verbose "Enabled $($Interface.Name)"
        $Interface.Enable()
    }
  }
}