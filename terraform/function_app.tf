# App Service Plan for Function App
resource "azurerm_service_plan" "function_app" {
  name                = "${local.function_app_name}-plan"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  sku_name            = var.function_app_service_plan_sku

  tags = local.common_tags
}

# Function App with secure configuration
resource "azurerm_linux_function_app" "this" {
  name                       = local.function_app_name
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  service_plan_id            = azurerm_service_plan.function_app.id
  storage_account_name       = azurerm_storage_account.this.name
  storage_account_access_key = azurerm_storage_account.this.primary_access_key

  # Security configurations following Azure Functions Security Baseline
  https_only                    = true
  public_network_access_enabled = true

  # Enable virtual network integration (only when private networking is enabled)
  virtual_network_subnet_id = var.enable_private_networking ? azurerm_subnet.func.id : null

  identity {
    type = "SystemAssigned"
  }

  site_config {
    # Application insights integration
    application_insights_connection_string = azurerm_application_insights.this.connection_string
    application_insights_key               = azurerm_application_insights.this.instrumentation_key

    # Security settings
    minimum_tls_version     = "1.2"
    scm_minimum_tls_version = "1.2"
    ftps_state              = "FtpsOnly"

    # Runtime settings
    application_stack {
      python_version = "3.11"
    }

    # CORS settings for API access
    cors {
      allowed_origins     = ["*"] # Should be restricted in production
      support_credentials = false
    }

    # Enable authentication for the function app
    app_service_logs {
      disk_quota_mb         = 25
      retention_period_days = 7
    }
  }

  # Application settings with Key Vault references
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"  = "python"
    "WEBSITE_RUN_FROM_PACKAGE"  = "1"
    "AzureWebJobsFeatureFlags"  = "EnableWorkerIndexing"

    # Key Vault references for sensitive data
    "STORAGE_CONNECTION_STRING" = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.this.name};SecretName=storage-connection-string)"
    "API_KEY"                   = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.this.name};SecretName=function-api-key)"

    # Environment-specific settings
    "ENVIRONMENT" = var.environment

    # MCP Server Configuration
    # These environment variables configure the Function App as an MCP server
    # The Function App must implement the following MCP endpoints:
    # - GET /api/mcp/info: Returns server capabilities and metadata
    # - GET /api/mcp/resources: Lists available resources
    # - GET /api/mcp/tools: Lists available tools
    # - POST /api/mcp/tools: Executes MCP tools
    "MCP_SERVER_NAME"             = "crud-mcp-server"
    "MCP_SERVER_VERSION"          = "1.0.0"
    "MCP_PROTOCOL_VERSION"        = "2024-11-05"
    "MCP_CAPABILITIES_RESOURCES"  = "true"
    "MCP_CAPABILITIES_TOOLS"      = "true"

    # API Management integration
    "API_MANAGEMENT_URL"          = azurerm_api_management.this.gateway_url
    "API_CENTER_DISCOVERY_URL"    = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.this.name}/providers/Microsoft.ApiCenter/services/${local.api_center_name}/overview"
  }

  tags = local.common_tags
}

# Grant Function App managed identity access to Key Vault
resource "azurerm_role_assignment" "func_kv_access" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
}

# Grant Function App managed identity access to Storage Account
resource "azurerm_role_assignment" "func_storage_access" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
}

# Application Insights for monitoring
resource "azurerm_log_analytics_workspace" "this" {
  name                = "${local.function_app_name}-logs"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}

resource "azurerm_application_insights" "this" {
  name                = "${local.function_app_name}-insights"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"

  tags = local.common_tags
}