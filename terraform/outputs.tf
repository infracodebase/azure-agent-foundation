output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.this.name
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.this.vault_uri
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.this.name
}

output "function_app_name" {
  description = "Name of the Function App"
  value       = azurerm_linux_function_app.this.name
}

output "function_app_url" {
  description = "Default URL of the Function App"
  value       = "https://${azurerm_linux_function_app.this.default_hostname}"
}

output "api_management_name" {
  description = "Name of the API Management instance"
  value       = azurerm_api_management.this.name
}

output "api_management_gateway_url" {
  description = "Gateway URL of the API Management instance"
  value       = azurerm_api_management.this.gateway_url
}

output "api_management_portal_url" {
  description = "Developer portal URL of the API Management instance"
  value       = azurerm_api_management.this.developer_portal_url
}

# API Center outputs are now in api_center.tf

output "ai_foundry_name" {
  description = "Name of the Azure AI Foundry resource"
  value       = azurerm_cognitive_account.ai_foundry.name
}

output "ai_foundry_id" {
  description = "ID of the Azure AI Foundry resource"
  value       = azurerm_cognitive_account.ai_foundry.id
}

output "ai_foundry_endpoint" {
  description = "Endpoint of the Azure AI Foundry resource"
  value       = azurerm_cognitive_account.ai_foundry.endpoint
}

output "container_app_name" {
  description = "Name of the Container App"
  value       = azurerm_container_app.chat_interface.name
}

output "container_app_url" {
  description = "URL of the Container App chat interface"
  value       = "https://${azurerm_container_app.chat_interface.latest_revision_fqdn}"
}

output "virtual_network_name" {
  description = "Name of the virtual network (only when private networking is enabled)"
  value       = var.enable_private_networking ? azurerm_virtual_network.this[0].name : null
}

output "api_subscription_key" {
  description = "Primary subscription key for API access"
  value       = azurerm_api_management_subscription.crud_api_subscription.primary_key
  sensitive   = true
}

output "mcp_server_endpoint" {
  description = "MCP server endpoint URL for AI agents"
  value       = "${azurerm_api_management.this.gateway_url}/crud-mcp/mcp"
}