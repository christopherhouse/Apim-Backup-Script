# GitHub Actions Workflow Setup for APIM Backup

This directory contains GitHub Actions workflow configuration for automated Azure API Management backups.

## 📋 Prerequisites

- GitHub repository with Actions enabled
- Azure subscription with API Management service
- Azure Storage Account for backup storage
- Azure App Registration with federated identity credentials

## 🔧 Setup Instructions

### 1. Azure App Registration Setup

Create an app registration with federated identity credentials for secure authentication:

```bash
# Create app registration
az ad app create --display-name "apim-backup-github-actions"

# Note the Application (client) ID from the output
# Get the tenant ID
az account show --query tenantId -o tsv

# Create service principal
az ad sp create --id {app-id}

# Get the object ID of the service principal
az ad sp show --id {app-id} --query id -o tsv
```

### 2. Configure Federated Identity Credentials

```bash
# Create federated credential for main branch
az ad app federated-credential create \
  --id {app-id} \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:{github-org}/{repo-name}:ref:refs/heads/main",
    "description": "GitHub Actions federated credential for main branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Create federated credential for workflow dispatch (optional)
az ad app federated-credential create \
  --id {app-id} \
  --parameters '{
    "name": "github-actions-workflow",
    "issuer": "https://token.actions.githubusercontent.com", 
    "subject": "repo:{github-org}/{repo-name}:environment:{environment-name}",
    "description": "GitHub Actions federated credential for workflow dispatch",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### 3. Assign Required Permissions

```bash
# Assign API Management Service Contributor role
az role assignment create \
  --assignee {app-id} \
  --role "API Management Service Contributor" \
  --scope "/subscriptions/{subscription-id}/resourceGroups/{apim-rg}/providers/Microsoft.ApiManagement/service/{apim-name}"

# Assign Storage Account permissions if needed  
az role assignment create \
  --assignee {app-id} \
  --role "Storage Account Contributor" \
  --scope "/subscriptions/{subscription-id}/resourceGroups/{storage-rg}/providers/Microsoft.Storage/storageAccounts/{storage-account}"
```

### 4. GitHub Repository Secrets

Navigate to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

#### Repository Secrets
Create the following secrets (these are sensitive and encrypted):

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AZURE_CLIENT_ID` | App registration client ID | Application (client) ID from step 1 |
| `AZURE_TENANT_ID` | Azure tenant ID | Your Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID | Target Azure subscription |
| `AZURE_CLIENT_SECRET` | Service principal secret | **Only needed if not using federated identity** |

#### Repository Variables  
Create the following variables (these are not encrypted but are configurable):

| Variable Name | Value | Description |
|---------------|-------|-------------|
| `APIM_RESOURCE_GROUP_NAME` | Resource group name | Resource group containing APIM service |
| `STORAGE_RESOURCE_GROUP_NAME` | Resource group name | Resource group containing storage account |
| `APIM_SERVICE_NAME` | APIM service name | Name of your API Management service |
| `STORAGE_ACCOUNT_NAME` | Storage account name | Name of your storage account |
| `MANAGED_IDENTITY_CLIENT_ID` | Managed identity client ID | Client ID of APIM's managed identity |
| `CONTAINER_NAME` | Container name | Storage container name (e.g., `apim-backups`) |
| `BACKUP_NAME` | Base backup name | Base name for backups (e.g., `daily-backup`) |

### 5. Workflow Configuration

The workflow is already configured in `.github/workflows/apim-backup.yml`. It will:

- Run daily at 2 AM UTC via cron schedule
- Allow manual triggering with optional backup name suffix
- Use federated identity for secure Azure authentication
- Execute the PowerShell backup script with parameters from secrets/variables

### 6. Enable Workflow

1. Go to your repository → **Actions** tab
2. Find the "APIM Backup Workflow"
3. If prompted, click **Enable workflow**

## 🔐 Security Best Practices

### Federated Identity (Recommended)
- Use federated identity credentials instead of client secrets
- Configure subject claims to restrict to specific branches/environments
- Regularly review and rotate credentials

### Secrets Management
- Use repository secrets for sensitive values (client IDs, tenant IDs, subscription IDs)
- Use repository variables for non-sensitive configuration
- Consider using environment-specific secrets for multi-environment setups

### Access Control
- Restrict who can modify secrets and variables
- Use environment protection rules for production workloads
- Enable branch protection rules

## 📊 Monitoring and Troubleshooting

### Workflow Monitoring
- Monitor workflow runs in **Actions** tab
- Check logs for detailed execution information
- Review job summaries and artifacts

### Common Issues

1. **Authentication Failures**
   ```
   Error: AADSTS70021: No matching federated identity record found
   ```
   - Verify federated identity credential configuration
   - Check subject claim format: `repo:{org}/{repo}:ref:refs/heads/{branch}`
   - Ensure audience is set to `api://AzureADTokenExchange`

2. **Permission Errors**
   ```
   Error: Insufficient privileges to complete the operation
   ```
   - Verify app registration has required role assignments
   - Check subscription and resource group permissions
   - Ensure service principal is active

3. **APIM Backup Failures**
   - Check APIM service name and resource group in variables
   - Verify managed identity configuration
   - Look for 409 conflicts (backup already in progress)

### Useful Troubleshooting Commands

```bash
# Verify app registration
az ad app show --id {app-id}

# Check role assignments
az role assignment list --assignee {app-id} --output table

# Test federated credential
az login --service-principal --username {app-id} --tenant {tenant-id} --federated-token {token}

# Check APIM status
az apim show --name {apim-name} --resource-group {resource-group}
```

## 🔄 Workflow Customization

### Changing Schedule
Edit the `cron` expression in `apim-backup.yml`:

```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC
    # - cron: '0 2 * * 1'  # Weekly on Monday at 2 AM
    # - cron: '0 2 1 * *'  # Monthly on 1st at 2 AM
```

### Adding Multiple Schedules
```yaml
on:
  schedule:
    - cron: '0 2 * * *'    # Daily at 2 AM
    - cron: '0 14 * * 0'   # Weekly on Sunday at 2 PM
```

### Adding Notifications
Add notification steps to the workflow:

```yaml
- name: 'Send Teams notification'
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: failure
    webhook_url: ${{ secrets.TEAMS_WEBHOOK }}
```

### Environment-Specific Configuration
Use environments for different deployment stages:

```yaml
jobs:
  backup-apim:
    environment: production  # or staging, development
    runs-on: ubuntu-latest
```

## 🌍 Environment-Specific Setup

For multiple environments (dev, staging, production):

### 1. Create Environments
1. Go to repository **Settings** → **Environments**
2. Create environments: `development`, `staging`, `production`
3. Configure protection rules and required reviewers

### 2. Environment Secrets/Variables
Set environment-specific values in each environment:
- `APIM_SERVICE_NAME`: Different for each environment
- `STORAGE_ACCOUNT_NAME`: Different for each environment
- Environment-specific resource groups

### 3. Multi-Environment Workflow
```yaml
strategy:
  matrix:
    environment: [development, staging, production]
jobs:
  backup-apim:
    environment: ${{ matrix.environment }}
    runs-on: ubuntu-latest
```

## 📚 Additional Resources

- [GitHub Actions documentation](https://docs.github.com/en/actions)
- [Azure login action](https://github.com/Azure/login)
- [OpenID Connect with GitHub Actions](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Azure API Management backup/restore](https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-disaster-recovery-backup-restore)

## 🚀 Quick Start

1. Create Azure app registration with federated identity
2. Assign APIM permissions to the app registration
3. Add secrets and variables to GitHub repository
4. Commit workflow file to `.github/workflows/`
5. Enable workflow in Actions tab
6. Test with manual trigger using "Run workflow" button