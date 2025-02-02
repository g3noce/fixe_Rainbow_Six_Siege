# Configuration
param (
    [int]$WaitTimeSeconds = 2,
    [ValidateNotNullOrEmpty()]
    [string[]]$ProcessNames = @("RainbowSix_DX11", "scimitar_engine_win64_2022_flto_dx11", "RainbowSix"),
    [int64]$TempAffinityMask = 1,
    [bool]$VerboseOutput = $true,
    [ValidateSet("DEBUG", "INFO", "ERROR")][string]$LogLevel = "INFO",
    [string]$LogFile = ""
)

# Elevation Check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires Administrator privileges. Please run as Admin."
    exit 1
}

# CPU Functions
function Get-AllCpusMask {
    $processorCount = (Get-CimInstance -ClassName Win32_ComputerSystem).NumberOfLogicalProcessors
    return [int64]([math]::Pow(2, $processorCount) - 1)
}

# Logging System
function ShouldLogMessage {
    param([string]$Type)
    $logLevels = @{"DEBUG"=1; "INFO"=2; "ERROR"=3}
    return $logLevels[$Type] -ge $logLevels[$LogLevel]
}

function Write-LogMessage {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )
    
    if (-not (ShouldLogMessage -Type $Type)) { return }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] $Type : $Message"
    
    if ($VerboseOutput) { Write-Host $logLine }
    if ($LogFile) { Add-Content -Path $LogFile -Value $logLine -Force }
}

# Affinity Management
function Set-ProcessAffinity {
    param (
        [System.Diagnostics.Process]$Process,
        [int64]$AffinityMask
    )
    
    try {
        if ($Process.HasExited) {
            Write-LogMessage "Process $($Process.Name) no longer exists" -Type "WARN"
            return $null
        }
        
        $oldAffinity = $Process.ProcessorAffinity.ToInt64()
        $Process.ProcessorAffinity = [IntPtr]::new($AffinityMask)
        Write-LogMessage "$($Process.Name) affinity changed: $oldAffinity → $AffinityMask" -Type "DEBUG"
        
        return $Process
    }
    catch {
        Write-LogMessage "Error modifying $($Process.Name): $_" -Type "ERROR"
        return $null
    }
}

# Main Execution
try {
    $startTime = Get-Date
    Write-LogMessage "Starting CPU Affinity Manager" -Type "INFO"
    
    # Get System Information
    $allCpusMask = Get-AllCpusMask
    Write-LogMessage "System CPU Mask: $allCpusMask" -Type "DEBUG"

    # Process Discovery
    $targetProcesses = @()
    foreach ($name in $ProcessNames) {
        try {
            $processes = Get-Process -Name $name -ErrorAction Stop
            foreach ($process in $processes) {
                $targetProcesses += $process
                Write-LogMessage "Found process: $($process.Name) (ID: $($process.Id))" -Type "INFO"
            }
        }
        catch {
            Write-LogMessage "Process not found: $name" -Type "WARN"
        }
    }

    # Apply Temporary Affinity
    $modifiedProcesses = @()
    foreach ($process in $targetProcesses) {
        if ($modified = Set-ProcessAffinity -Process $process -AffinityMask $TempAffinityMask) {
            $modifiedProcesses += $modified
        }
    }

    # Wait Period
    if ($modifiedProcesses.Count -gt 0) {
        Write-LogMessage "Applying $WaitTimeSeconds second delay..." -Type "INFO"
        Start-Sleep -Seconds $WaitTimeSeconds
    }
    else {
        Write-LogMessage "No processes modified, exiting early" -Type "WARN"
        exit
    }

    # Restore Original Affinity
    foreach ($process in $modifiedProcesses) {
        if (-not $process.HasExited) {
            Set-ProcessAffinity -Process $process -AffinityMask $allCpusMask | Out-Null
        }
        else {
            Write-LogMessage "Skipping exited process: $($process.Name)" -Type "DEBUG"
        }
    }

    # Performance Metrics
    $duration = (Get-Date) - $startTime
    Write-LogMessage "Operation completed in $($duration.TotalSeconds.ToString('0.00'))s" -Type "INFO"
}
catch {
    Write-LogMessage "Fatal error: $_" -Type "ERROR"
    exit 1
}
finally {
    if ($LogFile) { Write-LogMessage "Log saved to: $LogFile" -Type "INFO" }
}
