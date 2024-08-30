# Fixing Sysprep failure due to registry  HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\SysPrepExternal\Cleanup" 
# If you use this without an SME or Ops this is at your own risk! This is NOT VMware approved software! 


$global:LogFile = "C:\FixSysprepRegLog.log"

Function InitLogFile
{
    $DateTime = "{0:MMddyy}{0:HHmmss}" -f (Get-Date)

    $global:LogFile = [string]::Concat("C:\FixSysprepRegLog", $Datetime, ".log")

    $StartLog = "=== Starting Script to cleanup Sysprep registry ==="

    Write-Host $LogFile
    Write-Host $StartLog
    Add-content $LogFile -value $StartLog
}

Function WriteLog
{
    Param ([string]$LogString)
    $DateTime = "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)

    $LogMessage = "$Datetime $LogString"

    Write-Host $LogMessage
    Add-content $LogFile -value $LogMessage
}


Function FixSysprepCleanupRegistry
{

	WriteLog "=== Starting Script to configure desired state configuration ==="
    $DscRegKeyPath = 'HKLM:\SOFTWARE\Microsoft\DesiredStateConfiguration';

    if (!(Test-Path -Path $DscRegKeyPath))
    {
        New-Item -Path $DscRegKeyPath -Force | Out-Null;
    }

    try
    {
        Get-ItemProperty -Path $DscRegKeyPath;

    }
    catch
    {
        $errorMessage = $_.Exception.Message; echo 'Unable to get or create registry path. Reason:' $errorMessage;
    }

    try
    {
        Set-ItemProperty -Path $DscRegKeyPath -Name 'AgentId' -Value '';
    }
    catch
    {
        $errorMessage = $_.Exception.Message; echo 'Unable to set registry property. Reason:' $errorMessage;
    }


	WriteLog "=== Starting Script to cleanup sysprep external register keys ==="
    $RegistryPath = 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\SysPrepExternal\\Cleanup';

    $RegistryKey = Get-Item -LiteralPath $RegistryPath;

    if ($RegistryKey -ne $null)
    {
        $Files = Get-ItemProperty -Path $RegistryKey.PSPath | ForEach-Object { $_.PSObject.Properties | Where-Object { $_.Name -ne '(Default)' } }
        foreach ($File in $Files)
        {
            try
            {
                Remove-ItemProperty -Path $RegistryPath -Name $File.Name -ErrorAction Stop;
            }
            catch
            {
                $errorMessage = $_.Exception.Message; echo 'Unable to remove file' $File 'from registry location. Reason:' $errorMessage;
            }
        }
        
        WriteLog "=== Sysprep external registry keys successfully cleaned up ==="
    }
    else
    {
        Write-Host 'Registry key not found: $RegistryPath'

    }


}

InitLogFile

FixSysprepCleanupRegistry

WriteLog "=== Finished Script ==="