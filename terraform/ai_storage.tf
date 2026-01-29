# AI Foundry dedicated Storage Account
# Separate from Function App storage for better workload isolation
resource "azurerm_storage_account" "ai_foundry" {
  name                     = local.ai_storage_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Security configurations following Azure Storage Security Baseline
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true # Will be restricted via firewall rules

  # Enable blob encryption and infrastructure encryption
  infrastructure_encryption_enabled = true

  blob_properties {
    # Enable blob versioning for AI model artifacts
    versioning_enabled = true

    # Enable soft delete for blobs
    delete_retention_policy {
      days = 7
    }

    # Enable soft delete for containers
    container_delete_retention_policy {
      days = 7
    }
  }

  tags = local.common_tags
}

# AI Foundry Storage Account network rules (only when private networking is enabled)
resource "azurerm_storage_account_network_rules" "ai_foundry" {
  count = var.enable_private_networking ? 1 : 0

  storage_account_id = azurerm_storage_account.ai_foundry.id

  default_action             = "Deny"
  ip_rules                   = [chomp(data.http.current_ip.response_body)]
  virtual_network_subnet_ids = [azurerm_subnet.compute[0].id]
  bypass                     = ["AzureServices", "Metrics", "Logging"]
}

# Storage containers for AI Foundry workloads
resource "azurerm_storage_container" "ai_models" {
  name                  = "ai-models"
  storage_account_id    = azurerm_storage_account.ai_foundry.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "training_data" {
  name                  = "training-data"
  storage_account_id    = azurerm_storage_account.ai_foundry.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "search_indexes" {
  name                  = "search-indexes"
  storage_account_id    = azurerm_storage_account.ai_foundry.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "documents" {
  name                  = "documents"
  storage_account_id    = azurerm_storage_account.ai_foundry.id
  container_access_type = "private"
}