# 🌐## ✨ Features

- 🔐 Secure authentication using Azure Entra ID (Azure AD) client credentials
- 🆔 Uses APIM's System Assigned Managed Identity for storage access (no storage keys required)
- 🎨 Colorful and engaging console output with emojis
- 📊 Detailed progress reporting and error messages with API response details
- ❌ Comprehensive error handling with 409 conflict detection and Activity Log guidance
- 🛡️ Secure token management with redacted debug output
- 📦 Automated backup to Azure Storage using API version 2024-05-01
- 🔧 Debug output for external testing tools (Postman, etc.)I Management Backup Script

A PowerShell script to backup Azure API Management (APIM) services using the ARM management API. This script uses APIM's System Assigned Managed Identity for secure storage access without requiring storage account keys, and provides an engaging, colorful console experience.

## ✨ Features

- 🔐 Secure authentication using Azure Entra ID (Azure AD) client credentials
- � Uses APIM's System Assigned Managed Identity for storage access (no storage keys required)
- �🎨 Colorful and engaging console output with emojis
- 📊 Detailed progress reporting and error messages
- ❌ Comprehensive error handling with API response details
- 🛡️ Secure token management with redacted debug output
- 📦 Automated backup to Azure Storage using API version 2024-05-01

## 🚀 Prerequisites

- PowerShell 5.1 or PowerShell Core 6+
- Azure subscription with API Management service
- Service Principal with appropriate permissions:
  - `API Management Service Contributor` role on the APIM service
- Azure Storage Account for backup storage
- APIM service with System Assigned Managed Identity enabled and granted access to storage

## 📋 Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `TenantId` | String | ✅ | Azure AD tenant ID |
| `ClientId` | String | ✅ | Service principal client ID |
| `ClientSecret` | String | ✅ | Service principal client secret |
| `SubscriptionId` | String | ✅ | Azure subscription ID |
| `ApimResourceGroupName` | String | ✅ | Resource group containing the APIM service |
| `StorageResourceGroupName` | String | ✅ | Resource group containing the storage account |
| `ApimServiceName` | String | ✅ | Name of the API Management service |
| `StorageAccountName` | String | ✅ | Storage account name for backup |
| `ManagedIdentityClientId` | String | ✅ | Client ID of the APIM's System Assigned Managed Identity (for reference/validation only) |
| `ContainerName` | String | ✅ | Storage container name |
| `BackupName` | String | ✅ | Backup file name (without extension) |

## 🔧 Usage

### Basic Usage

```powershell
.\Backup-APIM.ps1 -TenantId "12345678-1234-1234-1234-123456789012" `
                  -ClientId "87654321-4321-4321-4321-210987654321" `
                  -ClientSecret "your-client-secret" `
                  -SubscriptionId "11111111-1111-1111-1111-111111111111" `
                  -ApimResourceGroupName "rg-apim" `
                  -ApimServiceName "my-apim-service" `
                  -StorageAccountName "mystorageaccount" `
                  -StorageResourceGroupName "rg-storage" `
                  -ManagedIdentityClientId "00000000-0000-0000-0000-000000000000" `
                  -ContainerName "apim-backups" `
                  -BackupName "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
```

### Advanced Usage with Timestamp

```powershell
# Create a timestamped backup
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupName = "apim-prod-backup-$timestamp"

.\Backup-APIM.ps1 -TenantId $env:AZURE_TENANT_ID `
                  -ClientId $env:AZURE_CLIENT_ID `
                  -ClientSecret $env:AZURE_CLIENT_SECRET `
                  -SubscriptionId $env:AZURE_SUBSCRIPTION_ID `
                  -ApimResourceGroupName "rg-apim-production" `
                  -StorageResourceGroupName "rg-storage-production" `
                  -ApimServiceName "apim-prod" `
                  -StorageAccountName "prodbackupstorage" `
                  -ManagedIdentityClientId $env:UAMI_CLIENT_ID `
                  -ContainerName "apim-backups" `
                  -BackupName $backupName
```

## 🔒 Setting Up Service Principal for APIM Backup

1. **Create a Service Principal:**
   ```bash
   # Create service principal for APIM backup operations
   az ad sp create-for-rbac --name "apim-backup-sp" \
                           --role "API Management Service Contributor" \
                           --scopes "/subscriptions/<subscription-id>/resourceGroups/<apim-rg-name>/providers/Microsoft.ApiManagement/service/<apim-service-name>"
   
   # Note down the appId (clientId), password (clientSecret), and tenant values from output
   ```

2. **Alternative: Create SP with broader scope then assign specific role:**
   ```bash
   # Create service principal without role assignment
   az ad sp create-for-rbac --name "apim-backup-sp" --skip-assignment
   
   # Assign API Management Service Contributor role to specific APIM service
   az role assignment create --assignee <service-principal-client-id> \
                            --role "API Management Service Contributor" \
                            --scope "/subscriptions/<subscription-id>/resourceGroups/<apim-rg-name>/providers/Microsoft.ApiManagement/service/<apim-service-name>"
   ```

## 🏗️ Setting Up APIM System Assigned Managed Identity & Storage Access

1. **Create Storage Account:**
   ```bash
   az storage account create --name <storage-account-name> \
                            --resource-group <storage-resource-group> \
                            --location <location> \
                            --sku Standard_LRS
   ```

2. **Create Container:**
   ```bash
   az storage container create --name apim-backups \
                              --account-name <storage-account-name>
   ```

3. **Enable System Assigned Managed Identity on APIM:**
   ```bash
   # Enable system assigned managed identity on the APIM service
   az apim update --name <apim-service-name> \
                  --resource-group <apim-resource-group> \
                  --assign-identity
   ```

4. **Get APIM's System Managed Identity Principal ID:**
   ```bash
   # Get the principal ID of the system assigned managed identity
   APIM_PRINCIPAL_ID=$(az apim show --name <apim-service-name> \
                                    --resource-group <apim-resource-group> \
                                    --query identity.principalId -o tsv)
   
   echo "APIM System Managed Identity Principal ID: $APIM_PRINCIPAL_ID"
   ```

5. **Grant Storage Blob Data Contributor Access to APIM's System Managed Identity:**
   ```bash
   # Grant Storage Blob Data Contributor role to APIM's system managed identity
   az role assignment create \
     --assignee $APIM_PRINCIPAL_ID \
     --role "Storage Blob Data Contributor" \
     --scope "/subscriptions/<subscription-id>/resourceGroups/<storage-resource-group>/providers/Microsoft.Storage/storageAccounts/<storage-account-name>"
   
   # Verify the role assignment
   az role assignment list --assignee $APIM_PRINCIPAL_ID --scope "/subscriptions/<subscription-id>/resourceGroups/<storage-resource-group>/providers/Microsoft.Storage/storageAccounts/<storage-account-name>"
   ```

6. **Get the System Managed Identity Client ID for the script parameter:**
   ```bash
   # The ManagedIdentityClientId parameter uses the same value as the principal ID
   # This is used for reference/validation in the script
   az apim show --name <apim-service-name> \
               --resource-group <apim-resource-group> \
               --query identity.principalId -o tsv
   ```

## 🔥 Storage Account Firewall Configuration

**Critical:** If you enable the storage account firewall, you **MUST** configure it to allow access from APIM's System Assigned Managed Identity.

1. **Allow APIM Service through Storage Firewall:**
   ```bash
   # Add APIM service to storage account network rules using resource ID
   az storage account network-rule add \
     --account-name <storage-account-name> \
     --resource-group <storage-resource-group> \
     --resource-id "/subscriptions/<subscription-id>/resourceGroups/<apim-resource-group>/providers/Microsoft.ApiManagement/service/<apim-service-name>"
   ```

2. **Alternative: Enable "Allow trusted Microsoft services" (recommended):**
   ```bash
   # This allows trusted Azure services (including APIM with proper RBAC) to access storage
   az storage account update \
     --name <storage-account-name> \
     --resource-group <storage-resource-group> \
     --bypass AzureServices
   ```

3. **Configure Storage Account Default Action (if using firewall):**
   ```bash
   # Set default action to deny (firewall enabled)
   az storage account update \
     --name <storage-account-name> \
     --resource-group <storage-resource-group> \
     --default-action Deny
   ```

4. **Verify Network Access Rules:**
   ```bash
   # Check current network rules and bypass settings
   az storage account show --name <storage-account-name> \
                          --resource-group <storage-resource-group> \
                          --query networkRuleSet
   ```

**⚠️ Important Notes:**
- APIM's System Assigned Managed Identity **requires** either resource-specific network rules OR the "AzureServices" bypass
- Even with correct RBAC permissions, backup will fail if firewall blocks APIM access
- The "AzureServices" bypass is the simplest and most reliable approach for APIM backups## 📊 Sample Output

```
   🎯 🚀 Starting Azure API Management Backup Script
============================================================
📋 Backup Configuration:
   🏢 Tenant ID: 12345678-1234-1234-1234-123456789012
   🔑 Client ID: 87654321-4321-4321-4321-210987654321
   📂 Subscription: 11111111-1111-1111-1111-111111111111
   🏷️  APIM RG: rg-apim
   🏷️  Storage RG: rg-storage
   🌐 APIM Service: my-apim-service
   💾 Storage Account: mystorageaccount
   📁 Container: apim-backups
   🪪 Managed Identity Client Id: 00000000-0000-0000-0000-000000000000
   📄 Backup Name: backup-20250107-143052

🔐 Acquiring Entra token...
   📡 Sending token request to Microsoft Entra...
   ✅ Token acquired successfully!

💾 Starting APIM backup operation...
   📦 Service: my-apim-service
   🗂️  Container: apim-backups
   📄 Backup name: backup-20250107-143052
   📡 Sending backup request...
   ✅ Backup request submitted successfully!
   📊 Operation Status: InProgress
   🆔 Operation ID: /subscriptions/.../operations/...

✨ 🎉 APIM Backup Process Completed Successfully!
============================================================
📝 The backup operation has been initiated and is running in the background.
🔍 You can monitor the progress in the Azure portal or use Azure CLI/PowerShell to check the operation status.
```

## ❗ Error Handling

The script includes comprehensive error handling for common scenarios:

- ❌ Invalid credentials or insufficient permissions
- 🔒 Token acquisition failures
- 🌐 Network connectivity issues
- 📁 Storage account access problems
- 🚫 API Management service not found

## 🔄 CI/CD Automation

This repository includes pre-configured CI/CD pipelines for automated backups:

### 🔵 Azure DevOps Pipelines
- **Location**: `.azdo/pipelines/`
- **Schedule**: Daily at 2 AM UTC
- **Authentication**: Service Connection with Service Principal
- **Configuration**: Variable Groups for secure parameter management
- **Setup Guide**: [Azure DevOps README](.azdo/pipelines/README.md)

### 🟢 GitHub Actions
- **Location**: `.github/workflows/`
- **Schedule**: Daily at 2 AM UTC  
- **Authentication**: Federated Identity Credentials (recommended) or Service Principal
- **Configuration**: Repository Secrets and Variables
- **Setup Guide**: [GitHub Actions README](.github/workflows/README.md)

Both pipelines:
- ✅ Run automatically on cron schedules
- ✅ Support manual triggering
- ✅ Include PowerShell syntax validation
- ✅ Provide comprehensive logging and error handling
- ✅ Follow security best practices

Choose the platform that fits your organization's infrastructure and follow the respective setup guide for detailed configuration instructions.

## 🔍 Monitoring Backup Progress

After the script completes, you can monitor the backup progress using:

```bash
# Using Azure CLI
az apim backup show --service-name <apim-name> \
                   --resource-group <resource-group> \
                   --operation-id <operation-id>
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🆘 Support

If you encounter any issues or have questions, please open an issue on GitHub.