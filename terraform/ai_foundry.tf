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

# Grant AI Hub managed identity access to storage account
resource "azurerm_role_assignment" "ai_hub_storage_access" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_cognitive_account.ai_foundry.identity[0].principal_id
}

# Grant AI Hub managed identity access to Key Vault
resource "azurerm_role_assignment" "ai_hub_kv_access" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_cognitive_account.ai_foundry.identity[0].principal_id
}

# Note: Azure OpenAI models are integrated directly into AI Foundry
# OpenAI models can be deployed through the AI Foundry portal or via API

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