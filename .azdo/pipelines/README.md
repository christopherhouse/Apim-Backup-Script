# Azure DevOps Pipeline Setup for APIM Backup

This directory contains Azure DevOps pipeline configuration for automated Azure API Management backups.

## 📋 Prerequisites

- Azure DevOps organization and project
- Azure subscription with API Management service
- Azure Storage Account for backup storage
- Service Principal with appropriate permissions

## 🔧 Setup Instructions

### 1. Service Principal Setup

Create a service principal with the required permissions:

```bash
# Create service principal
az ad sp create-for-rbac --name "apim-backup-sp" --role contributor --scopes /subscriptions/{subscription-id}

# Note down the output:
# - appId (Client ID)
# - password (Client Secret)  
# - tenant (Tenant ID)
```

### 2. Assign Required Permissions

```bash
# Assign API Management Service Contributor role
az role assignment create \
  --assignee {client-id} \
  --role "API Management Service Contributor" \
  --scope "/subscriptions/{subscription-id}/resourceGroups/{apim-rg}/providers/Microsoft.ApiManagement/service/{apim-name}"

# Assign Storage Account permissions if needed
az role assignment create \
  --assignee {client-id} \
  --role "Storage Account Contributor" \
  --scope "/subscriptions/{subscription-id}/resourceGroups/{storage-rg}/providers/Microsoft.Storage/storageAccounts/{storage-account}"
```

### 3. Azure DevOps Service Connection

1. Go to **Project Settings** → **Service connections**
2. Click **New service connection** → **Azure Resource Manager** → **Service principal (manual)**
3. Fill in the details:
   - **Subscription ID**: Your Azure subscription ID
   - **Subscription Name**: A friendly name
   - **Service Principal ID**: The `appId` from step 1
   - **Service Principal Key**: The `password` from step 1
   - **Tenant ID**: The `tenant` from step 1
4. Name it `apim-backup-service-connection`
5. Check **Grant access permission to all pipelines**

### 4. Variable Group Setup

1. Go to **Pipelines** → **Library** → **Variable groups**
2. Create a new variable group named `apim-backup-variables`
3. Add the following variables:

| Variable Name | Value | Secure |
|---------------|-------|---------|
| `azureServiceConnection` | `apim-backup-service-connection` | No |
| `tenantId` | Your Azure tenant ID | No |
| `clientId` | Service principal client ID | No |
| `clientSecret` | Service principal client secret | **Yes** |
| `subscriptionId` | Your Azure subscription ID | No |
| `apimResourceGroupName` | Resource group containing APIM | No |
| `storageResourceGroupName` | Resource group containing storage | No |
| `apimServiceName` | Name of your APIM service | No |
| `storageAccountName` | Name of your storage account | No |
| `managedIdentityClientId` | APIM managed identity client ID | No |
| `containerName` | Storage container name (e.g., `apim-backups`) | No |
| `backupName` | Base backup name (e.g., `daily-backup`) | No |

**Important**: Mark the `clientSecret` variable as secure by checking the lock icon.

### 5. Pipeline Setup

1. Go to **Pipelines** → **Pipelines** → **New pipeline**
2. Select **Azure Repos Git** (or your source)
3. Select your repository
4. Choose **Existing Azure Pipelines YAML file**
5. Select the path: `/.azdo/pipelines/apim-backup-pipeline.yml`
6. Click **Continue** and then **Save**

### 6. Enable Scheduled Runs

The pipeline is configured to run daily at 2 AM UTC. To modify the schedule:

1. Edit the pipeline YAML file
2. Update the `cron` expression in the `schedules` section:
   ```yaml
   schedules:
   - cron: "0 2 * * *"  # Daily at 2 AM UTC
   ```

## 🔐 Security Best Practices

- **Service Connection**: Use least privilege principle for service principal permissions
- **Variable Groups**: Always mark sensitive values (like client secrets) as secure
- **Access Control**: Restrict who can edit variable groups and pipelines
- **Key Rotation**: Regularly rotate service principal credentials

## 📊 Monitoring and Troubleshooting

### Pipeline Monitoring
- Monitor pipeline runs in **Pipelines** → **Pipelines** → Select your pipeline
- Check logs for detailed execution information
- Review artifacts for additional debugging information

### Common Issues

1. **Authentication Failures**
   - Verify service principal credentials in variable group
   - Check service connection configuration
   - Ensure service principal has required permissions

2. **APIM Backup Failures**
   - Verify APIM service name and resource group
   - Check if another backup is already in progress (409 conflict)
   - Verify managed identity configuration

3. **Storage Issues**
   - Verify storage account name and container
   - Check storage account permissions
   - Ensure container exists

### Useful Azure CLI Commands

```bash
# Check APIM backup status
az apim show --name {apim-name} --resource-group {resource-group} --query "restore"

# List recent backups in storage
az storage blob list --container-name {container} --account-name {storage-account}

# Check service principal permissions
az role assignment list --assignee {client-id} --output table
```

## 🔄 Pipeline Customization

### Changing Schedule
Edit the `cron` expression in `apim-backup-pipeline.yml`:
- `"0 2 * * *"` - Daily at 2 AM
- `"0 2 * * 1"` - Weekly on Monday at 2 AM  
- `"0 2 1 * *"` - Monthly on 1st at 2 AM

### Adding Notifications
Add notification tasks to the pipeline for success/failure alerts:

```yaml
- task: EmailReport@1
  displayName: 'Send backup completion email'
  condition: always()
  inputs:
    sendMailConditionConfig: 'Always'
    subject: 'APIM Backup Status: $(Agent.JobStatus)'
    to: 'admin@company.com'
```

## 📚 Additional Resources

- [Azure DevOps Pipeline documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/)
- [Azure API Management backup/restore](https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-disaster-recovery-backup-restore)
- [Azure service connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints)