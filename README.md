# CPU Affinity Manager for Game Processes

A PowerShell script designed to manage CPU affinity for game processes, with a specific focus on Rainbow Six Siege processes. This tool allows temporary CPU core allocation modifications to potentially improve game performance or system resource management.

## Features

- Temporary CPU affinity modification for specified processes
- Automatic restoration of original CPU affinity settings
- Configurable wait time between modifications
- Detailed logging with timestamps
- Error handling and process validation
- Support for multiple processes simultaneously

## Prerequisites

- Windows operating system
- PowerShell 5.1 or higher
- Administrative privileges (required for modifying process affinity)

## Installation

1. Clone this repository or download the script file:
```bash
git clone https://github.com/yourusername/cpu-affinity-manager.git
```

2. Make sure you have the necessary permissions to run PowerShell scripts:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Usage

### Basic Usage

Run the script with default settings:
```powershell
.\Set-GameAffinity.ps1
```

### Advanced Usage

Run the script with custom parameters:
```powershell
.\Set-GameAffinity.ps1 -WaitTimeSeconds 10 -ProcessNames @("RainbowSix_DX11", "CustomGameProcess") -VerboseOutput $true
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| WaitTimeSeconds | Integer | 5 | Duration to wait before resetting CPU affinity |
| ProcessNames | String[] | @("RainbowSix_DX11", "scimitar_engine_win64_2022_flto_dx11") | Array of process names to modify |
| VerboseOutput | Boolean | $true | Enable/disable detailed logging |

## How It Works

1. The script first calculates a mask for all available CPU cores
2. It then modifies the CPU affinity of specified processes to use only the first core
3. Waits for the specified duration
4. Automatically restores the original CPU affinity settings for all modified processes
5. Logs all operations with timestamps and detailed information

## Output Example

```
[2025-01-21 14:30:00] INFO : Starting CPU affinity script
[2025-01-21 14:30:00] INFO : CPU mask for all processors: 255
[2025-01-21 14:30:00] INFO : RainbowSix_DX11: Affinity changed from 255 to 1
[2025-01-21 14:30:00] INFO : Waiting for 5 seconds...
[2025-01-21 14:30:05] INFO : RainbowSix_DX11: Affinity reset from 1 to 255
[2025-01-21 14:30:05] INFO : Script completed in 5.00 seconds
```

## Error Handling

The script includes comprehensive error handling for common scenarios:
- Process not found
- Insufficient permissions
- Invalid affinity mask
- Process termination during execution

All errors are logged with timestamps and detailed error messages.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Common Issues and Solutions

1. **"Access Denied" Error**
   - Run PowerShell as Administrator
   - Verify you have the necessary permissions

2. **"Process Not Found" Error**
   - Verify the process name is correct (case-sensitive)
   - Ensure the process is running before executing the script

3. **Script Execution Policy Error**
   - Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
   - Or use `powershell.exe -ExecutionPolicy Bypass -File .\Set-GameAffinity.ps1`

## Disclaimer

Use this script at your own risk. Modifying CPU affinity can affect process performance and system stability. Always test in a safe environment first.

## Support

If you encounter any issues or have questions, please:
1. Check the common issues section above
2. Open an issue in the GitHub repository
3. Provide detailed information about your system and the error encountered
