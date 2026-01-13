# Storage Account for Function App and general storage needs
resource "azurerm_storage_account" "this" {
  name                     = local.storage_account_name
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
    # Enable blob versioning
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

# Storage Account network rules
resource "azurerm_storage_account_network_rules" "this" {
  storage_account_id = azurerm_storage_account.this.id

  default_action             = "Deny"
  ip_rules                   = []
  virtual_network_subnet_ids = [azurerm_subnet.func.id]
  bypass                     = ["AzureServices", "Metrics", "Logging"]
}

# Storage containers for different purposes
resource "azurerm_storage_container" "function_app" {
  name                 = "function-app"
  storage_account_id   = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "api_data" {
  name                 = "api-data"
  storage_account_id   = azurerm_storage_account.this.id
  container_access_type = "private"
}