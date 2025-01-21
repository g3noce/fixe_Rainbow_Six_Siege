# Configuration
param (
    [int]$WaitTimeSeconds = 5,
    [string[]]$ProcessNames = @("RainbowSix_DX11", "scimitar_engine_win64_2022_flto_dx11"),
    [bool]$VerboseOutput = $true
)

# Fonction pour obtenir le masque d'affinité pour tous les processeurs
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
    
    if ($VerboseOutput) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] $Type : $Message"
    }
}

# Fonction pour vérifier et modifier l'affinité d'un processus
function Set-GameProcessAffinity {
    param (
        [string]$ProcessName,
        [int64]$AffinityMask = 1
    )
    
    try {
        $process = Get-Process $ProcessName -ErrorAction Stop
        $oldAffinity = $process.ProcessorAffinity.ToInt64()
        $process.ProcessorAffinity = [IntPtr]::new($AffinityMask)
        
        Write-LogMessage "$ProcessName : Affinité modifiée de $oldAffinity à $AffinityMask"
        return $process
    }
    catch {
        Write-LogMessage "Erreur pour $ProcessName : $_" -Type "ERROR"
        return $null
    }
}

# Fonction pour réinitialiser l'affinité d'un processus
function Reset-GameProcessAffinity {
    param (
        [System.Diagnostics.Process]$Process,
        [int64]$AllCpusMask
    )
    
    if ($null -eq $Process) { return }
    
    try {
        $oldAffinity = $Process.ProcessorAffinity.ToInt64()
        $Process.ProcessorAffinity = [IntPtr]::new($AllCpusMask)
        Write-LogMessage "$($Process.ProcessName) : Affinité réinitialisée de $oldAffinity à $AllCpusMask"
    }
    catch {
        Write-LogMessage "Erreur lors de la réinitialisation pour $($Process.ProcessName) : $_" -Type "ERROR"
    }
}

# Script principal
try {
    $startTime = Get-Date
    Write-LogMessage "Démarrage du script d'affinité CPU"
    
    $allCpusMask = Get-AllCpusMask
    Write-LogMessage "Masque pour tous les CPUs : $allCpusMask"
    
    # Stockage des processus modifiés
    $modifiedProcesses = @()
    
    # Définir l'affinité initiale pour tous les processus
    foreach ($processName in $ProcessNames) {
        $process = Set-GameProcessAffinity -ProcessName $processName
        if ($null -ne $process) {
            $modifiedProcesses += $process
        }
    }
    
    Write-LogMessage "Attente de $WaitTimeSeconds secondes..."
    Start-Sleep -Seconds $WaitTimeSeconds
    
    # Réinitialiser l'affinité pour tous les processus
    foreach ($process in $modifiedProcesses) {
        Reset-GameProcessAffinity -Process $process -AllCpusMask $allCpusMask
    }
    
    $duration = (Get-Date - $startTime).TotalSeconds
    Write-LogMessage "Script terminé en $($duration.ToString('0.00')) secondes"
}
catch {
    Write-LogMessage "Erreur fatale : $_" -Type "ERROR"
}
finally {
    # Nettoyage si nécessaire
    $modifiedProcesses = $null
}