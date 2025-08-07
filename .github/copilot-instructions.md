# Azure API Management Backup Script

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Repository Current State

This repository is currently minimal, containing only LICENSE and README.md files. The intended purpose is to create scripts for backing up Azure API Management (APIM) instances.

## Working Effectively

### Initial Setup and Validation
- Run `ls -la` to confirm repository contents (should show: LICENSE, README.md, .github/)
- Run `git status` to verify you're on the correct branch
- Run `git log --oneline` to see commit history

### Expected Development Patterns
Based on the repository name "Apim-Backup-Script", this codebase will likely contain:
- PowerShell scripts (`.ps1`) for Azure integration
- Python scripts (`.py`) as an alternative implementation
- Bash scripts (`.sh`) for Linux environments
- Configuration files (`.json`, `.yaml`) for APIM settings
- Documentation and usage examples

### Prerequisites for Development
- Install Azure CLI: `curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash`
  - **TIMING**: Installation takes 2-3 minutes. NEVER CANCEL - wait for completion.
  - **TIMEOUT**: Use 300+ second timeout for installation commands.
- Verify Azure CLI: `az --version` (should show version info, takes ~1 second)
- Install PowerShell Core (if developing .ps1 scripts): `sudo snap install powershell --classic`
  - **TIMING**: Installation takes 1-2 minutes. NEVER CANCEL - wait for completion.
  - **TIMEOUT**: Use 180+ second timeout for snap installation.
- Verify PowerShell: `pwsh --version` (should show version info, takes <1 second)
- Install Python 3.8+ (if developing .py scripts): `sudo apt-get update && sudo apt-get install python3 python3-pip`
  - **TIMING**: Installation takes 30-60 seconds. NEVER CANCEL - wait for completion.
  - **TIMEOUT**: Use 120+ second timeout for apt-get commands.
- Verify Python: `python3 --version` (should show version 3.8+, takes <1 second)

### Development Workflow

#### For PowerShell Scripts
- Validate syntax: `pwsh -NoProfile -Command "& { . './script.ps1'; exit 0 }"` for each .ps1 file
- Run script help: `pwsh -Command "Get-Help ./script.ps1 -Full"`
- Test script execution: `pwsh -Command "./script.ps1 -WhatIf"` (if WhatIf parameter exists)

#### For Python Scripts  
- Install dependencies: `pip3 install -r requirements.txt` (when requirements.txt exists)
  - **TIMING**: 30 seconds - 2 minutes. **NEVER CANCEL** - set timeout to 180+ seconds
- Install Azure SDK (required for APIM scripts): `pip3 install azure-mgmt-apimanagement azure-identity`
  - **TIMING**: 30-60 seconds. **NEVER CANCEL** - set timeout to 120+ seconds
- Validate syntax: `python3 -m py_compile script.py` for each .py file (takes <5 seconds)
- Run linting: `python3 -m flake8 script.py` (install with `pip3 install flake8`, takes 10-20 seconds)
- Run script help: `python3 script.py --help`

#### For Bash Scripts
- Validate syntax: `bash -n script.sh` for each .sh file
- Make executable: `chmod +x script.sh`
- Run script help: `./script.sh --help` or `./script.sh -h`

### Testing and Validation

#### Pre-commit Validation
- Always run syntax validation for the script type you're working with
- Verify all help/usage documentation works correctly
- Test that scripts fail gracefully with appropriate error messages
- Ensure all required parameters are documented

#### Azure Integration Testing
- Set up test environment variables (when scripts are implemented):
  - `export AZURE_SUBSCRIPTION_ID="test-subscription-id"`
  - `export AZURE_RESOURCE_GROUP="test-resource-group"`  
  - `export AZURE_APIM_NAME="test-apim-instance"`
- Run dry-run/WhatIf mode first: append `-WhatIf` or `--dry-run` parameters
- Test authentication: `az login` and verify `az account show`
- Validate APIM access: `az apim show --name $AZURE_APIM_NAME --resource-group $AZURE_RESOURCE_GROUP`

#### Manual Testing Scenarios
When scripts are implemented, always test these scenarios:
1. **Help Documentation**: Run `script --help` and verify complete usage information is displayed
2. **Parameter Validation**: Run script with missing required parameters and verify appropriate error messages  
3. **Authentication Check**: Run script without Azure login and verify authentication prompts/errors
4. **Dry Run Mode**: Execute script in dry-run/WhatIf mode and verify it shows intended actions without executing them
5. **Configuration Validation**: Test with invalid APIM instance names and verify error handling

### Build and Deployment

#### No Build Process Required
- This repository contains scripts that do not require compilation
- Validation is done through syntax checking and linting only
- No build artifacts are generated

#### Deployment Process
- Scripts are deployed by copying to target environment
- Ensure executable permissions: `chmod +x *.sh` for bash scripts
- Verify all dependencies are documented in README.md

### Time Expectations
- Syntax validation: < 10 seconds per script  
- Azure CLI installation: 2-3 minutes. **NEVER CANCEL** - set timeout to 300+ seconds
- PowerShell installation: 1-2 minutes. **NEVER CANCEL** - set timeout to 180+ seconds  
- Python dependency installation: 30 seconds - 2 minutes. **NEVER CANCEL** - set timeout to 180+ seconds
- Authentication setup: 1-2 minutes (interactive, requires user input)
- Manual testing per scenario: 1-2 minutes each
- Azure CLI commands: 1-10 seconds each (depending on network and Azure response time)

### Common Issues and Solutions

#### Azure CLI Issues
- If `az login` fails with browser issues, use: `az login --use-device-code`
- If Azure CLI is not found, add to PATH: `export PATH=$PATH:/usr/local/bin`

#### PowerShell Issues  
- If PowerShell scripts fail to execute, check execution policy: `pwsh -Command "Get-ExecutionPolicy"`
- Set execution policy if needed: `pwsh -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"`

#### Python Issues
- If modules not found, use virtual environment: `python3 -m venv apim-backup-env && source apim-backup-env/bin/activate`
- Install Azure SDK: `pip3 install azure-mgmt-apimanagement azure-identity`

### Directory Structure (Expected)
```
.
├── README.md                 # Usage documentation
├── LICENSE                   # MIT License
├── .github/                  # GitHub configuration
│   ├── copilot-instructions.md
│   └── workflows/           # CI/CD workflows (when implemented)
├── scripts/                 # Main script directory (when implemented)
│   ├── powershell/         # PowerShell implementations
│   ├── python/             # Python implementations  
│   └── bash/               # Bash implementations
├── config/                 # Configuration files (when implemented)
├── examples/               # Usage examples (when implemented)
└── tests/                  # Test scripts (when implemented)
```

### Key Files to Monitor
- Always check README.md after making changes to ensure documentation is updated
- Update LICENSE file if adding third-party dependencies
- Monitor .gitignore for excluding temporary files, credentials, and build artifacts

### Validation Commands Summary
Run these commands before committing any changes:

```bash
# Repository structure validation
ls -la
git status

# Script syntax validation (run for each script type present)
bash -n *.sh                    # Bash scripts
python3 -m py_compile *.py      # Python scripts  
pwsh -NoProfile -Command "& { . './script.ps1'; exit 0 }"  # PowerShell scripts

# Documentation validation
./script --help                 # Verify help documentation works
```

### Critical Reminders
- NEVER commit Azure credentials or subscription IDs to the repository
- ALWAYS test scripts in dry-run mode before executing against production APIM instances
- ALWAYS validate that scripts handle authentication failures gracefully
- Document all required Azure permissions in README.md when implementing scripts
- Include examples of all required environment variables and configuration