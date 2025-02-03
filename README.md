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

## Usage

### Basic Usage

Run the script with default settings:
```powershell
.\fixe_Rainbow_Six_Siege.ps1
```

## How It Works

1. The script first calculates a mask for all available CPU cores
2. It then modifies the CPU affinity of specified processes to use only the first core
3. Waits for the specified duration
4. Automatically restores the original CPU affinity settings for all modified processes
5. Logs all operations with timestamps and detailed information

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Disclaimer

Use this script at your own risk. Modifying CPU affinity can affect process performance and system stability. Always test in a safe environment first.

## Support

If you encounter any issues or have questions, please:
1. Check the common issues section above
2. Open an issue in the GitHub repository
3. Provide detailed information about your system and the error encountered
