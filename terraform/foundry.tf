# Azure AI Foundry Resource (Modern approach using AIServices)
resource "azurerm_cognitive_account" "ai_foundry" {
  name                = local.ai_hub_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  kind                = "AIServices"
  sku_name            = "S0" # Required for stateful development including agent service

  # Security configurations following Azure AI Foundry Security Baseline
  public_network_access_enabled = true # Can be restricted based on requirements
  custom_subdomain_name         = local.ai_hub_name
  project_management_enabled    = true # Enables AI Foundry project creation capabilities

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}


# Grant AI Hub managed identity access to Key Vault
resource "azurerm_role_assignment" "ai_hub_kv_access" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_cognitive_account.ai_foundry.identity[0].principal_id
}

# Grant AI Hub managed identity access to storage account (for AI Search integration)
resource "azurerm_role_assignment" "ai_hub_storage_access" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_cognitive_account.ai_foundry.identity[0].principal_id
}

# Create Storage connection in AI Foundry project using AzAPI
# This enables integration with Azure AI Search for RAG scenarios
resource "azapi_resource" "storage_connection" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  name      = "storage-connection"
  parent_id = azapi_resource.ai_foundry_project.id

  body = {
    properties = {
      category = "AzureBlob"
      target   = azurerm_storage_account.this.primary_blob_endpoint
      authType = "AAD"  # Use Azure AD authentication
      metadata = {
        ResourceId = azurerm_storage_account.this.id
      }
    }
  }

  depends_on = [
    azurerm_storage_account.this,
    azapi_resource.ai_foundry_project,
    azurerm_role_assignment.ai_hub_storage_access
  ]
}

# Grant Azure AI User role to current user principal for agents access
# Required for data actions like Microsoft.CognitiveServices/accounts/AIServices/agents/read
resource "azurerm_role_assignment" "current_user_ai_user" {
  scope                = azurerm_cognitive_account.ai_foundry.id
  role_definition_name = "Azure AI User"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Grant Azure AI User role to project's managed identity for agents access
resource "azurerm_role_assignment" "project_ai_user" {
  scope                = azurerm_cognitive_account.ai_foundry.id
  role_definition_name = "Azure AI User"
  principal_id         = azapi_resource.ai_foundry_project.identity[0].principal_id
  
  depends_on = [azapi_resource.ai_foundry_project]
}

# AI Foundry Project
resource "azapi_resource" "ai_foundry_project" {
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name      = "${var.project_name}-${var.environment}-project"
  parent_id = azurerm_cognitive_account.ai_foundry.id
  location  = azurerm_resource_group.this.location

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      displayName = "AI Foundation Project"
      description = "AI Foundry project for ${var.project_name}"
    }
  }

  tags = local.common_tags
}

# Deploy GPT-4o-mini model (cost-effective for development)
resource "azurerm_cognitive_deployment" "gpt4o_mini" {
  name                 = "gpt-4o-mini"
  cognitive_account_id = azurerm_cognitive_account.ai_foundry.id

  model {
    format  = "OpenAI"
    name    = "gpt-4o-mini"
    version = "2024-07-18"
  }

  sku {
    name     = "Standard"
    capacity = 10 # Tokens per minute in thousands
  }
}

# Compute instance for development (optional - commented out)
# Uncomment and provide valid SSH public key when needed
# resource "azurerm_machine_learning_compute_instance" "dev_instance" {
#   name                          = "dev-instance"
#   machine_learning_workspace_id = azurerm_machine_learning_workspace.ai_hub.id
#   virtual_machine_size          = "Standard_DS3_v2"
#   authorization_type            = "personal"
#
#   ssh {
#     public_key = "ssh-rsa AAAAB3... # Replace with actual SSH public key"
#   }
#
#   identity {
#     type = "SystemAssigned"
#   }
#
#   tags = local.common_tags
# }