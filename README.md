# 🌐 Azure API Management Backup Script

A PowerShell script to backup Azure API Management (APIM) services using the ARM management API. This script provides an engaging, colorful console experience while securely backing up your APIM configuration to Azure Storage.

## ✨ Features

- 🔐 Secure authentication using Azure Entra ID (Azure AD) client credentials
- 🎨 Colorful and engaging console output with emojis
- 📊 Detailed progress reporting
- ❌ Comprehensive error handling
- 🛡️ Secure token management
- 📦 Automated backup to Azure Storage

## 🚀 Prerequisites

- PowerShell 5.1 or PowerShell Core 6+
- Azure subscription with API Management service
- Service Principal with appropriate permissions:
  - `API Management Service Contributor` role on the APIM service
  - `Storage Account Contributor` role on the storage account
- Azure Storage Account for backup storage

## 📋 Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `TenantId` | String | ✅ | Azure AD tenant ID |
| `ClientId` | String | ✅ | Service principal client ID |
| `ClientSecret` | String | ✅ | Service principal client secret |
| `SubscriptionId` | String | ✅ | Azure subscription ID |
| `ResourceGroupName` | String | ✅ | Resource group containing the APIM service |
| `ApimServiceName` | String | ✅ | Name of the API Management service |
| `StorageAccountName` | String | ✅ | Storage account name for backup |
| `StorageAccountKey` | String | ✅ | Storage account access key |
| `ContainerName` | String | ✅ | Storage container name |
| `BackupName` | String | ✅ | Backup file name (without extension) |

## 🔧 Usage

### Basic Usage

```powershell
.\Backup-APIM.ps1 -TenantId "12345678-1234-1234-1234-123456789012" `
                  -ClientId "87654321-4321-4321-4321-210987654321" `
                  -ClientSecret "your-client-secret" `
                  -SubscriptionId "11111111-1111-1111-1111-111111111111" `
                  -ResourceGroupName "rg-apim" `
                  -ApimServiceName "my-apim-service" `
                  -StorageAccountName "mystorageaccount" `
                  -StorageAccountKey "storage-account-key" `
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
                  -ResourceGroupName "rg-production" `
                  -ApimServiceName "apim-prod" `
                  -StorageAccountName "prodbackupstorage" `
                  -StorageAccountKey $env:STORAGE_KEY `
                  -ContainerName "apim-backups" `
                  -BackupName $backupName
```

## 🔒 Setting Up Service Principal

1. **Create a Service Principal:**
   ```bash
   az ad sp create-for-rbac --name "apim-backup-sp" --role contributor
   ```

2. **Assign Required Permissions:**
   ```bash
   # API Management Service Contributor
   az role assignment create --assignee <service-principal-id> \
                            --role "API Management Service Contributor" \
                            --scope "/subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.ApiManagement/service/<apim-name>"
   
   # Storage Account Contributor  
   az role assignment create --assignee <service-principal-id> \
                            --role "Storage Account Contributor" \
                            --scope "/subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.Storage/storageAccounts/<storage-name>"
   ```

## 🏗️ Setting Up Storage Account

1. **Create Storage Account:**
   ```bash
   az storage account create --name <storage-account-name> \
                            --resource-group <resource-group> \
                            --location <location> \
                            --sku Standard_LRS
   ```

2. **Create Container:**
   ```bash
   az storage container create --name apim-backups \
                              --account-name <storage-account-name>
   ```

3. **Get Access Key:**
   ```bash
   az storage account keys list --account-name <storage-account-name> \
                               --resource-group <resource-group> \
                               --query '[0].value' -o tsv
   ```

## 📊 Sample Output

```
🎯 🚀 Starting Azure API Management Backup Script
============================================================
📋 Backup Configuration:
   🏢 Tenant ID: 12345678-1234-1234-1234-123456789012
   🔑 Client ID: 87654321-4321-4321-4321-210987654321
   📂 Subscription: 11111111-1111-1111-1111-111111111111
   🏷️  Resource Group: rg-apim
   🌐 APIM Service: my-apim-service
   💾 Storage Account: mystorageaccount
   📁 Container: apim-backups
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