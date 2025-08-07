# Azure API Management Backup Script

Azure API Management backup script is a PowerShell utility that uses Azure ARM management APIs to backup API Management services to Azure Storage. The script provides secure authentication via Azure Entra ID and includes comprehensive error handling with colorful console output.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Prerequisites and Environment Setup
- **PowerShell 7.4+** is required and available as `pwsh`
- **Azure CLI 2.75+** is available as `az` (optional, for alternative backup operations)
- **Internet connectivity** to Azure endpoints is required for actual operations
- **Azure credentials** are required for real backup operations

### Script Validation and Testing
- Validate PowerShell syntax: `pwsh -Command "[System.Management.Automation.Language.Parser]::ParseFile('/home/runner/work/Apim-Backup-Script/Apim-Backup-Script/Backup-APIM.ps1', [ref]\$null, [ref]\$null)"`
- Test script help system: `pwsh -Command "Get-Help '/home/runner/work/Apim-Backup-Script/Apim-Backup-Script/Backup-APIM.ps1' -Examples"` -- **takes 0.3 seconds, always completes quickly**
- Get detailed parameter info: `pwsh -Command "Get-Help '/home/runner/work/Apim-Backup-Script/Apim-Backup-Script/Backup-APIM.ps1' -Detailed"` -- **takes 0.3 seconds, always completes quickly**
- Validate script structure: `pwsh -Command "Test-Path '/home/runner/work/Apim-Backup-Script/Apim-Backup-Script/Backup-APIM.ps1'"` -- **takes 0.1 seconds, always completes quickly**

### Running the Script (requires Azure credentials)
**IMPORTANT**: The main script requires valid Azure credentials and will fail without them. For testing without credentials, create a simplified test version.

- Basic execution (will fail authentication with dummy credentials):
  ```bash
  pwsh -File '/home/runner/work/Apim-Backup-Script/Apim-Backup-Script/Backup-APIM.ps1' \
    -TenantId "12345678-1234-1234-1234-123456789012" \
    -ClientId "87654321-4321-4321-4321-210987654321" \
    -ClientSecret "dummy-secret" \
    -SubscriptionId "11111111-1111-1111-1111-111111111111" \
    -ResourceGroupName "test-rg" \
    -ApimServiceName "test-apim" \
    -StorageAccountName "teststorage" \
    -StorageAccountKey "dummy-key" \
    -ContainerName "test-container" \
    -BackupName "test-backup"
  ```
  **TIMING**: Script startup and parameter validation complete in under 1 second. Authentication failure occurs within 5-10 seconds. **NEVER CANCEL** - always let authentication complete or fail.

### Alternative Azure CLI Method
- Backup using Azure CLI: `az apim backup --name <apim-name> -g <resource-group> --backup-name <backup-name> --storage-account-name <storage-name> --storage-account-container <container> --storage-account-key <key>`
- **TIMING**: Azure CLI backup operations are **long-running** and can take **15-45 minutes** depending on APIM service size. **NEVER CANCEL** - use `--no-wait` flag if needed and monitor separately.

## Validation Scenarios

### Always Test These After Making Changes:
1. **Script Syntax Validation**: 
   - Run PowerShell syntax parser to ensure no parse errors
   - Verify all functions are properly defined
   - Check parameter binding works correctly

2. **Help System Validation**:
   - Verify `Get-Help` commands work and display proper documentation
   - Test parameter examples from help output
   - Confirm all required parameters are documented

3. **Parameter Validation**:
   - Test script with missing parameters (should prompt or error appropriately)
   - Verify all mandatory parameters are enforced
   - Test with valid-format but dummy Azure GUIDs

4. **Error Handling**:
   - Test authentication failure with invalid credentials
   - Verify network error handling
   - Test with malformed parameters

### Manual Testing Commands:
```bash
# Quick syntax validation (< 1 second)
pwsh -Command "[System.Management.Automation.Language.Parser]::ParseFile('/home/runner/work/Apim-Backup-Script/Apim-Backup-Script/Backup-APIM.ps1', [ref]\$null, [ref]\$null)"

# Help system test (< 1 second)  
pwsh -Command "Get-Help '/home/runner/work/Apim-Backup-Script/Apim-Backup-Script/Backup-APIM.ps1' -Examples"

# Parameter validation test with dummy data (< 10 seconds, will fail authentication as expected)
timeout 30 pwsh -File '/home/runner/work/Apim-Backup-Script/Apim-Backup-Script/Backup-APIM.ps1' \
  -TenantId "12345678-1234-1234-1234-123456789012" \
  -ClientId "87654321-4321-4321-4321-210987654321" \
  -ClientSecret "test" -SubscriptionId "11111111-1111-1111-1111-111111111111" \
  -ResourceGroupName "test" -ApimServiceName "test" -StorageAccountName "test" \
  -StorageAccountKey "test" -ContainerName "test" -BackupName "test"
```

## Key Components

### Main Script Structure:
- **Parameter validation**: All 10 parameters are mandatory
- **Authentication**: Uses Azure Entra ID client credentials flow
- **API calls**: REST API calls to Azure ARM management endpoints
- **Error handling**: Comprehensive try/catch blocks with colored output
- **Progress reporting**: Colorful console output with emojis

### Important Functions:
- `Write-ColorOutput`: Handles console output with colors and emojis
- `Get-EntraToken`: Acquires Azure AD access tokens
- `Backup-ApiManagement`: Executes the actual backup operation

### Known Issues:
- **Terminal Compatibility**: Colored output may not work in all terminal environments. If you see color-related errors, the script logic is still valid.
- **Interactive Prompts**: Script will prompt for missing parameters in interactive mode, which doesn't work well in automated environments.

## Timing Expectations

| Operation | Expected Time | Timeout Recommendation |
|-----------|---------------|------------------------|
| Script startup | < 1 second | 10 seconds |
| Parameter validation | < 1 second | 5 seconds |
| Help commands | < 1 second | 5 seconds |
| Authentication (with valid credentials) | 2-5 seconds | 15 seconds |
| Authentication (failure) | 3-10 seconds | 15 seconds |
| APIM backup initiation | 5-15 seconds | 30 seconds |
| **APIM backup completion (Azure-side)** | **15-45 minutes** | **NEVER CANCEL - runs asynchronously** |

**CRITICAL**: The PowerShell script only initiates the backup operation. The actual backup runs asynchronously in Azure and can take 15-45 minutes. The script will complete quickly after submitting the backup request.

## Azure Resource Requirements

For real backup operations, you need:
- **Azure subscription** with API Management service
- **Service principal** with these roles:
  - `API Management Service Contributor` on the APIM service
  - `Storage Account Contributor` on the storage account
- **Azure Storage Account** with container for backups
- **Network connectivity** to Azure endpoints

### Setup Commands (requires Azure CLI authentication):
```bash
# Create service principal
az ad sp create-for-rbac --name "apim-backup-sp" --role contributor

# Assign APIM permissions
az role assignment create --assignee <service-principal-id> \
  --role "API Management Service Contributor" \
  --scope "/subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.ApiManagement/service/<apim-name>"

# Create storage account
az storage account create --name <storage-account-name> \
  --resource-group <resource-group> --location <location> --sku Standard_LRS

# Create container
az storage container create --name apim-backups --account-name <storage-account-name>
```

## Common Troubleshooting

### Script Validation Issues:
- **Syntax errors**: Use PowerShell parser to validate syntax
- **Missing parameters**: Review parameter binding in script help
- **Import errors**: Ensure PowerShell 7+ is available as `pwsh`

### Runtime Issues (with real credentials):
- **Authentication failures**: Verify service principal credentials and permissions
- **Network errors**: Check connectivity to `login.microsoftonline.com` and `management.azure.com`
- **Storage errors**: Verify storage account key and container existence
- **APIM not found**: Verify resource group and APIM service name

### Expected Error Messages:
- `Unable to match the identifier name * to a valid enumerator name` - Terminal color compatibility issue (script logic still works)
- `401 Unauthorized` - Invalid credentials (expected with dummy data)
- `404 Not Found` - Resource doesn't exist (expected with dummy data)

## Repository Structure

```
/home/runner/work/Apim-Backup-Script/Apim-Backup-Script/
├── Backup-APIM.ps1          # Main PowerShell backup script
├── README.md                # Comprehensive documentation
├── LICENSE                  # MIT license
└── .github/
    └── copilot-instructions.md  # This file
```

## Development Guidelines

- **Make minimal changes**: This is a production script used by others
- **Test thoroughly**: Always validate syntax and parameter handling
- **Preserve functionality**: Don't break existing parameter structure
- **Update documentation**: Keep README.md in sync with script changes
- **Validate help system**: Ensure Get-Help output remains accurate

Always run script validation commands before committing changes to ensure the script remains functional.