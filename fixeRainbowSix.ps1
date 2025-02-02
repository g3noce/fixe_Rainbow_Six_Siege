# Configuration
param (
    [int]$WaitTimeSeconds = 2,
    [string[]]$ProcessNames = @("RainbowSix_DX11", "scimitar_engine_win64_2022_flto_dx11", "RainbowSix"),
    [bool]$VerboseOutput = $true,
    [ValidateSet("DEBUG", "INFO", "ERROR")] [string]$LogLevel = "INFO"
)

# Fonction pour obtenir le masque d'affinite pour tous les processeurs
function Get-AllCpusMask {
    $processorCount = (Get-WmiObject -Class Win32_ComputerSystem).NumberOfLogicalProcessors
    return [int64]([math]::Pow(2, $processorCount) - 1)
}

# Fonction pour logger les messages avec horodatage
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

# Fonction pour determiner si un message doit être logge
function ShouldLogMessage {
    param([string]$Type)
    
    $logLevels = @{
        "DEBUG" = 1
        "INFO"  = 2
        "ERROR" = 3
    }
    
    return $logLevels[$Type] -ge $logLevels[$LogLevel]
}

# Fonction pour verifier et modifier l'affinite d'un processus
function Set-GameProcessAffinity {
    param (
        [string]$ProcessName,
        [int64]$AffinityMask = 1
    )
    
    try {
        $process = Get-Process $ProcessName -ErrorAction Stop
        $oldAffinity = $process.ProcessorAffinity.ToInt64()
        $process.ProcessorAffinity = [IntPtr]::new($AffinityMask)
        
        Write-LogMessage "$ProcessName : Affinite modifiee de $oldAffinity a $AffinityMask"
        return $process
    }
    catch {
        Write-LogMessage "Erreur pour $ProcessName : $_" -Type "ERROR"
        return $null
    }
}

# Fonction pour reinitialiser l'affinite d'un processus
function Reset-GameProcessAffinity {
    param (
        [System.Diagnostics.Process]$Process,
        [int64]$AllCpusMask
    )
    
    if ($null -eq $Process) { return }
    
    try {
        $oldAffinity = $Process.ProcessorAffinity.ToInt64()
        $Process.ProcessorAffinity = [IntPtr]::new($AllCpusMask)
        Write-LogMessage "$($Process.ProcessName) : Affinite reinitialisee de $oldAffinity a $AllCpusMask"
    }
    catch {
        Write-LogMessage "Erreur lors de la reinitialisation pour $($Process.ProcessName) : $_" -Type "ERROR"
    }
}

# Script principal
try {
    $startTime = Get-Date
    Write-LogMessage "Demarrage du script d'affinite CPU"
    
    $allCpusMask = Get-AllCpusMask
    Write-LogMessage "Masque pour tous les CPUs : $allCpusMask"
    
    # Recuperation des processus
    $allProcesses = Get-Process | Where-Object { $ProcessNames -contains $_.ProcessName }
    $foundNames = $allProcesses.ProcessName | Select-Object -Unique
    
    # Journalisation detaillee
    Write-LogMessage "Recherche des processus..." -Type "DEBUG"
    foreach ($name in $ProcessNames) {
        if ($foundNames -contains $name) {
            Write-LogMessage "[Yes] Processus trouve : $name" -Type "INFO"
        }
        else {
            Write-LogMessage "[No] Processus non trouve : $name" -Type "ERROR"
        }
    }
    
    # Modification de l'affinite
    $modifiedProcesses = @()
    foreach ($process in $allProcesses) {
        $modifiedProcess = Set-GameProcessAffinity -ProcessName $process.ProcessName
        if ($modifiedProcess) { $modifiedProcesses += $modifiedProcess }
    }
    
    Write-LogMessage "Attente de $WaitTimeSeconds secondes..."
    Start-Sleep -Seconds $WaitTimeSeconds
    
    # Reinitialisation de l'affinite
    foreach ($process in $modifiedProcesses) {
        Reset-GameProcessAffinity -Process $process -AllCpusMask $allCpusMask
    }
    
    $duration = (Get-Date - $startTime).TotalSeconds
    Write-LogMessage "Script termine en $($duration.ToString('0.00')) secondes"
}
catch {
    Write-LogMessage "Erreur fatale : $_" -Type "ERROR"
}
finally {
    $modifiedProcesses = $null
}