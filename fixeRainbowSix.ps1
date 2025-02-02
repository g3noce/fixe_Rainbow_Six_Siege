# Configuration
param (
    [int]$WaitTimeSeconds = 2,
    [string[]]$ProcessNames = @("RainbowSix_DX11", "scimitar_engine_win64_2022_flto_dx11", "RainbowSix"),
    [bool]$VerboseOutput = $true,
    [ValidateSet("DEBUG", "INFO", "ERROR")] [string]$LogLevel = "INFO"
)

# Function to get the affinity mask for all CPUs
function Get-AllCpusMask {
    $processorCount = (Get-WmiObject -Class Win32_ComputerSystem).NumberOfLogicalProcessors
    return [int64]([math]::Pow(2, $processorCount) - 1)
}

# Function to log messages with a timestamp
function Write-LogMessage {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )
    
    if ($VerboseOutput -and (ShouldLogMessage -Type $Type)) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] $Type : $Message"
    }
}

# Function to determine if a message should be logged
function ShouldLogMessage {
    param([string]$Type)
    
    $logLevels = @{
        "DEBUG" = 1
        "INFO"  = 2
        "ERROR" = 3
    }
    
    return $logLevels[$Type] -ge $logLevels[$LogLevel]
}

# Function to check and modify the affinity of a process
function Set-GameProcessAffinity {
    param (
        [string]$ProcessName,
        [int64]$AffinityMask = 1
    )
    
    try {
        $process = Get-Process $ProcessName -ErrorAction Stop
        $oldAffinity = $process.ProcessorAffinity.ToInt64()
        $process.ProcessorAffinity = [IntPtr]::new($AffinityMask)
        
        Write-LogMessage "$ProcessName : Affinity changed from $oldAffinity to $AffinityMask"
        return $process
    }
    catch {
        Write-LogMessage "Error for $ProcessName : $_" -Type "ERROR"
        return $null
    }
}

# Function to reset the affinity of a process
function Reset-GameProcessAffinity {
    param (
        [System.Diagnostics.Process]$Process,
        [int64]$AllCpusMask
    )
    
    if ($null -eq $Process) { return }
    
    try {
        $oldAffinity = $Process.ProcessorAffinity.ToInt64()
        $Process.ProcessorAffinity = [IntPtr]::new($AllCpusMask)
        Write-LogMessage "$($Process.ProcessName) : Affinity reset from $oldAffinity to $AllCpusMask"
    }
    catch {
        Write-LogMessage "Error resetting affinity for $($Process.ProcessName) : $_" -Type "ERROR"
    }
}

# Main script
try {
    $startTime = Get-Date
    Write-LogMessage "Starting CPU affinity script"
    
    $allCpusMask = Get-AllCpusMask
    Write-LogMessage "Mask for all CPUs : $allCpusMask"
    
    # Retrieving processes
    $allProcesses = Get-Process | Where-Object { $ProcessNames -contains $_.ProcessName }
    $foundNames = $allProcesses.ProcessName | Select-Object -Unique
    
    # Detailed logging
    Write-LogMessage "Searching for processes..." -Type "DEBUG"
    foreach ($name in $ProcessNames) {
        if ($foundNames -contains $name) {
            Write-LogMessage "[Yes] Process found : $name" -Type "INFO"
        }
        else {
            Write-LogMessage "[No] Process not found : $name" -Type "ERROR"
        }
    }
    
    # Modifying affinity
    $modifiedProcesses = @()
    foreach ($process in $allProcesses) {
        $modifiedProcess = Set-GameProcessAffinity -ProcessName $process.ProcessName
        if ($modifiedProcess) { $modifiedProcesses += $modifiedProcess }
    }
    
    Write-LogMessage "Waiting for $WaitTimeSeconds seconds..."
    Start-Sleep -Seconds $WaitTimeSeconds
    
    # Resetting affinity
    foreach ($process in $modifiedProcesses) {
        Reset-GameProcessAffinity -Process $process -AllCpusMask $allCpusMask
    }
    
    $duration = (Get-Date - $startTime).TotalSeconds
    Write-LogMessage "Script completed in $($duration.ToString('0.00')) seconds"
}
catch {
    Write-LogMessage "Fatal error : $_" -Type "ERROR"
}
finally {
    $modifiedProcesses = $null
}
