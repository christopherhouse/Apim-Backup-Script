#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Backup Azure API Management service using ARM management API

.DESCRIPTION
    This script backs up an Azure API Management service to a storage account container.
    It first acquires an Entra token using client credentials flow, then calls the APIM backup API.

.PARAMETER TenantId
    The Azure AD tenant ID

.PARAMETER ClientId
    The client ID of the service principal with permissions to backup APIM

.PARAMETER ClientSecret
    The client secret for the service principal

.PARAMETER SubscriptionId
    The Azure subscription ID containing the APIM service

.PARAMETER ApimResourceGroupName
    The resource group name containing the APIM service

.PARAMETER StorageResourceGroupName
    The resource group name containing the storage account

.PARAMETER ApimServiceName
    The name of the API Management service to backup

.PARAMETER StorageAccountName
    The name of the storage account where backup will be stored

.PARAMETER ManagedIdentityClientId
    The client ID of the User Assigned Managed Identity (UAMI) that has Blob Data Contributor (or equivalent) access to the storage account. Used instead of storage account keys.

.PARAMETER ContainerName
    The name of the storage container for the backup

.PARAMETER BackupName
    The name for the backup file (without extension)

.EXAMPLE
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
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $true)]
    [string]$ClientId,
    
    [Parameter(Mandatory = $true)]
    [string]$ClientSecret,
    
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $true)]
    [string]$ApimResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$StorageResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$ApimServiceName,
    
    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory = $true)]
    [string]$ManagedIdentityClientId,
    
    [Parameter(Mandatory = $true)]
    [string]$ContainerName,
    
    [Parameter(Mandatory = $true)]
    [string]$BackupName
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write colored output with emojis
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [string]$Emoji = ""
    )
    
    $output = if ($Emoji) { "$Emoji $Message" } else { $Message }
    # Validate color to avoid errors if an invalid value slips through
    if (-not [Enum]::IsDefined([System.ConsoleColor], $Color)) {
        $Color = 'White'
    }
    Write-Host $output -ForegroundColor $Color
}

# Function to acquire Entra token using client credentials flow
function Get-EntraToken {
    param(
        [string]$TenantId,
        [string]$ClientId,
        [string]$ClientSecret
    )
    
    Write-ColorOutput "🔐 Acquiring Entra token..." "Cyan"
    
    try {
        # Prepare token request
        $tokenEndpoint = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
        $scope = "https://management.azure.com/.default"
        
        $body = @{
            client_id     = $ClientId
            client_secret = $ClientSecret
            scope         = $scope
            grant_type    = "client_credentials"
        }
        
        Write-ColorOutput "   📡 Sending token request to Microsoft Entra..." "Gray"
        
        $response = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
        
        Write-ColorOutput "   ✅ Token acquired successfully!" "Green"
        return $response.access_token
    }
    catch {
        Write-ColorOutput "   ❌ Failed to acquire token: $($_.Exception.Message)" "Red"
        throw
    }
}

# Function to backup APIM service
function Backup-ApiManagement {
    param(
        [string]$AccessToken,
        [string]$SubscriptionId,
        [string]$ApimResourceGroupName,
        [string]$ApimServiceName,
        [string]$StorageAccountName,
        [string]$ManagedIdentityClientId,
        [string]$ContainerName,
        [string]$BackupName
    )
    
    Write-ColorOutput "💾 Starting APIM backup operation..." "Cyan"
    
    try {
        # Prepare backup request
    # API version 2024-05-01 supports using a managed identity instead of a storage access key
    $apiVersion = "2024-05-01"
        $backupEndpoint = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ApimResourceGroupName/providers/Microsoft.ApiManagement/service/$ApimServiceName/backup?api-version=$apiVersion"
        
        $headers = @{
            "Authorization" = "Bearer $AccessToken"
            "Content-Type"  = "application/json"
        }
        
        $backupBodyHashtable = @{
            storageAccount          = $StorageAccountName
            containerName           = $ContainerName
            backupName              = $BackupName
            accessType              = "SystemAssignedManagedIdentity"
        }

        $backupBody = $backupBodyHashtable | ConvertTo-Json
        
        Write-ColorOutput "   📦 Service: $ApimServiceName" "Gray"
        Write-ColorOutput "   🗂️  Container: $ContainerName" "Gray"
        Write-ColorOutput "   📄 Backup name: $BackupName" "Gray"
        Write-ColorOutput "   📡 Sending backup request..." "Gray"

        # Pretty print the JSON body (informational only; contains no secrets)
        Write-ColorOutput "   🧾 Backup Request Body (JSON):" "Gray"
        Write-Host $backupBody -ForegroundColor DarkGray
        
        # DEBUG: Print everything for Postman testing
        Write-ColorOutput "   🔧 DEBUG INFO FOR POSTMAN OR SOME BULLSHIT LIKE THAT:" "Magenta"
        Write-ColorOutput "   URL: $backupEndpoint" "Yellow"
        
        # Redact token for security - show first 15 and last 15 chars
        $redactedToken = if ($AccessToken.Length -gt 30) {
            $AccessToken.Substring(0, 15) + "..." + $AccessToken.Substring($AccessToken.Length - 15)
        } else {
            "***REDACTED***"
        }
        Write-ColorOutput "   Authorization: Bearer $redactedToken" "Yellow"
        
        Write-ColorOutput "   Content-Type: application/json" "Yellow"
        Write-ColorOutput "   Body:" "Yellow"
        Write-Host $backupBody -ForegroundColor Yellow
        
        $response = Invoke-RestMethod -Uri $backupEndpoint -Method Post -Headers $headers -Body $backupBody
        
        Write-ColorOutput "   ✅ Backup request submitted successfully!" "Green"
        Write-ColorOutput "   📊 Operation Status: $($response.status)" "Yellow"
        
        if ($response.id) {
            Write-ColorOutput "   🆔 Operation ID: $($response.id)" "Gray"
        }
        
        return $response
    }
    catch {
        Write-ColorOutput "   ❌ Backup failed: $($_.Exception.Message)" "Red"
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode
            Write-ColorOutput "   📊 HTTP Status: $statusCode" "Red"
            
            # Try to read the response body for detailed error information
            try {
                $responseBody = $_.Exception.Response.GetResponseStream()
                if ($responseBody) {
                    $reader = New-Object System.IO.StreamReader($responseBody)
                    $errorContent = $reader.ReadToEnd()
                    $reader.Close()
                    
                    if (-not [string]::IsNullOrWhiteSpace($errorContent)) {
                        Write-ColorOutput "   📄 Error Response Body:" "Red"
                        Write-Host $errorContent -ForegroundColor DarkRed
                    }
                }
            }
            catch {
                Write-ColorOutput "   ⚠️  Could not read error response body" "Yellow"
            }
            
            if ($statusCode -eq 409) {
                $apimResourceId = "/subscriptions/$SubscriptionId/resourceGroups/$ApimResourceGroupName/providers/Microsoft.ApiManagement/service/$ApimServiceName"
                Write-ColorOutput "   🔁 A backup operation may already be in progress (409 Conflict)." "Yellow"
                Write-ColorOutput "   🔍 Check Azure Activity Log for existing backup operations." "Yellow"
                Write-ColorOutput "      Resource ID: $apimResourceId" "DarkGray"
                Write-ColorOutput "      Hint: az monitor activity-log list --offset 1h --resource-id $apimResourceId | Select-String backup" "DarkGray"
            }
        }
        throw
    }
}

# Main script execution
try {
    Write-ColorOutput "🚀 Starting Azure API Management Backup Script" "Magenta" "🎯"
    Write-ColorOutput ("=" * 60) "Magenta"
    
    # Display configuration
    Write-ColorOutput "📋 Backup Configuration:" "White"
    Write-ColorOutput "   🏢 Tenant ID: $TenantId" "Gray"
    Write-ColorOutput "   🔑 Client ID: $ClientId" "Gray"
    Write-ColorOutput "   📂 Subscription: $SubscriptionId" "Gray"
    Write-ColorOutput "   🏷️  APIM RG: $ApimResourceGroupName" "Gray"
    Write-ColorOutput "   🏷️  Storage RG: $StorageResourceGroupName" "Gray"
    Write-ColorOutput "   🌐 APIM Service: $ApimServiceName" "Gray"
    Write-ColorOutput "   💾 Storage Account: $StorageAccountName" "Gray"
    Write-ColorOutput "   🪪 Managed Identity Client Id: $ManagedIdentityClientId" "Gray"
    Write-ColorOutput "   📁 Container: $ContainerName" "Gray"
    Write-ColorOutput "   📄 Backup Name: $BackupName" "Gray"
    Write-ColorOutput ""
    
    # Step 1: Acquire token
    $accessToken = Get-EntraToken -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
    Write-ColorOutput ""
    
    # Step 2: Backup APIM
    $backupResult = Backup-ApiManagement -AccessToken $accessToken -SubscriptionId $SubscriptionId -ApimResourceGroupName $ApimResourceGroupName -ApimServiceName $ApimServiceName -StorageAccountName $StorageAccountName -ManagedIdentityClientId $ManagedIdentityClientId -ContainerName $ContainerName -BackupName $BackupName
    
    Write-ColorOutput ""
    Write-ColorOutput "🎉 APIM Backup Process Completed Successfully!" "Green" "✨"
    Write-ColorOutput ("=" * 60) "Green"
    Write-ColorOutput "📝 The backup operation has been initiated and is running in the background." "White"
    Write-ColorOutput "🔍 You can monitor the progress in the Azure portal or use Azure CLI/PowerShell to check the operation status." "White"
    
    exit 0
}
catch {
    Write-ColorOutput ""
    Write-ColorOutput "💥 APIM Backup Process Failed!" "Red" "❌"
    Write-ColorOutput ("=" * 60) "Red"
    Write-ColorOutput "❌ Error: $($_.Exception.Message)" "Red"
    Write-ColorOutput "🔍 Please check your configuration and try again." "Yellow"
    
    exit 1
}