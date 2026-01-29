# Cosmos DB for Azure AI Foundry Agent Service
# Required for BYO (Bring Your Own) Thread Storage in Agent Service
resource "azurerm_cosmosdb_account" "ai_foundry" {
  name                = local.cosmos_account_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = azurerm_resource_group.this.location
    failover_priority = 0
  }

  # Security configurations
  public_network_access_enabled     = true # Can be restricted based on requirements
  is_virtual_network_filter_enabled = false

  tags = local.common_tags
}

# Database for Azure AI Agent Service
# This specific database name is required by the Agent Service
resource "azurerm_cosmosdb_sql_database" "enterprise_memory" {
  name                = "enterprise_memory"
  resource_group_name = azurerm_resource_group.this.name
  account_name        = azurerm_cosmosdb_account.ai_foundry.name

  # Shared throughput across containers (minimum 3000 RU/s total)
  throughput = 3000
}

# Container for end-user conversation messages
resource "azurerm_cosmosdb_sql_container" "thread_message_store" {
  name                  = "thread-message-store"
  resource_group_name   = azurerm_resource_group.this.name
  account_name          = azurerm_cosmosdb_account.ai_foundry.name
  database_name         = azurerm_cosmosdb_sql_database.enterprise_memory.name
  partition_key_paths   = ["/id"]
  partition_key_version = 1

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }
  }
}

# Container for internal system messages
resource "azurerm_cosmosdb_sql_container" "system_thread_message_store" {
  name                  = "system-thread-message-store"
  resource_group_name   = azurerm_resource_group.this.name
  account_name          = azurerm_cosmosdb_account.ai_foundry.name
  database_name         = azurerm_cosmosdb_sql_database.enterprise_memory.name
  partition_key_paths   = ["/id"]
  partition_key_version = 1

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }
  }
}

# Container for model inputs and outputs
resource "azurerm_cosmosdb_sql_container" "agent_entity_store" {
  name                  = "agent-entity-store"
  resource_group_name   = azurerm_resource_group.this.name
  account_name          = azurerm_cosmosdb_account.ai_foundry.name
  database_name         = azurerm_cosmosdb_sql_database.enterprise_memory.name
  partition_key_paths   = ["/id"]
  partition_key_version = 1

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }
  }
}

# Grant AI Foundry project managed identity access to Cosmos DB
resource "azurerm_role_assignment" "ai_project_cosmos_access" {
  scope                = azurerm_cosmosdb_account.ai_foundry.id
  role_definition_name = "DocumentDB Account Contributor"
  principal_id         = azapi_resource.ai_foundry_project.identity[0].principal_id

  depends_on = [azapi_resource.ai_foundry_project]
}

# Create Cosmos DB connection in AI Foundry project using AzAPI
# This is the special connection that enables BYO Thread Storage
resource "azapi_resource" "cosmos_db_connection" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  name      = "cosmos-db-connection"
  parent_id = azapi_resource.ai_foundry_project.id

  body = {
    properties = {
      category = "CosmosDB"
      target   = azurerm_cosmosdb_account.ai_foundry.endpoint
      authType = "AAD" # Use Azure AD authentication
      metadata = {
        ResourceId   = azurerm_cosmosdb_account.ai_foundry.id
        DatabaseName = azurerm_cosmosdb_sql_database.enterprise_memory.name
      }
    }
  }

  depends_on = [
    azurerm_cosmosdb_account.ai_foundry,
    azurerm_cosmosdb_sql_database.enterprise_memory,
    azapi_resource.ai_foundry_project,
    azurerm_role_assignment.ai_project_cosmos_access
  ]
}