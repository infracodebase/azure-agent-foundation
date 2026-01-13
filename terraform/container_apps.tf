# Container Apps Environment
resource "azurerm_container_app_environment" "this" {
  name                       = local.container_env_name
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  # Security configurations following Azure Container Apps Security Baseline
  infrastructure_subnet_id = azurerm_subnet.container_apps.id

  tags = local.common_tags
}

# Container App for chat interface
resource "azurerm_container_app" "chat_interface" {
  name                         = local.container_app_name
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = azurerm_resource_group.this.name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    min_replicas = 1
    max_replicas = 3

    container {
      name   = "chat-interface"
      image  = "ghcr.io/your-org/ai-foundation-chat:latest" # Placeholder - will use GitHub Container Registry
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      env {
        name  = "AI_FOUNDRY_ENDPOINT"
        value = azurerm_cognitive_account.ai_foundry.endpoint
      }

      env {
        name  = "API_MANAGEMENT_URL"
        value = azurerm_api_management.this.gateway_url
      }

      env {
        name        = "API_SUBSCRIPTION_KEY"
        secret_name = "api-subscription-key"
      }

      env {
        name  = "AI_FOUNDRY_NAME"
        value = azurerm_cognitive_account.ai_foundry.name
      }

      # Startup and liveness probes
      startup_probe {
        transport = "HTTP"
        port      = 8080
        path      = "/health"
      }

      liveness_probe {
        transport     = "HTTP"
        port          = 8080
        path          = "/health"
        initial_delay = 30
      }

      readiness_probe {
        transport = "HTTP"
        port      = 8080
        path      = "/ready"
      }
    }
  }

  # Secrets configuration

  secret {
    name  = "api-subscription-key"
    value = azurerm_api_management_subscription.crud_api_subscription.primary_key
  }

  # Ingress configuration for external access
  ingress {
    external_enabled = true
    target_port      = 8080
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = local.common_tags
}

# Grant Container App managed identity access to Key Vault
resource "azurerm_role_assignment" "container_app_kv_access" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_container_app.chat_interface.identity[0].principal_id
}

# Grant Container App managed identity access to AI Foundry
resource "azurerm_role_assignment" "container_app_ai_access" {
  scope                = azurerm_cognitive_account.ai_foundry.id
  role_definition_name = "Cognitive Services User"
  principal_id         = azurerm_container_app.chat_interface.identity[0].principal_id
}

# Container App uses AI Hub directly for AI services - no additional role assignments needed

# Container App environment variables from Key Vault (using Dapr secret store)
resource "azurerm_container_app_environment_dapr_component" "keyvault_secret_store" {
  name                         = "keyvault-secret-store"
  container_app_environment_id = azurerm_container_app_environment.this.id
  component_type               = "secretstores.azure.keyvault"
  version                      = "v1"

  metadata {
    name  = "vaultName"
    value = azurerm_key_vault.this.name
  }

  metadata {
    name  = "azureClientId"
    value = azurerm_container_app.chat_interface.identity[0].principal_id
  }

  scopes = [azurerm_container_app.chat_interface.name]
}