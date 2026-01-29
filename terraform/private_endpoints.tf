# Private Endpoints for secure access to Azure PaaS services
# Following Azure security best practices with private connectivity

# Private DNS Zones for Azure services
resource "azurerm_private_dns_zone" "key_vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "storage_file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "cosmos_db" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "ai_services" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "ai_foundry" {
  name                = "privatelink.services.ai.azure.com"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "postgresql" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

# Link DNS zones to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  count                 = var.enable_private_networking ? 1 : 0
  name                  = "kv-dns-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault.name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob" {
  count                 = var.enable_private_networking ? 1 : 0
  name                  = "storage-blob-dns-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_file" {
  count                 = var.enable_private_networking ? 1 : 0
  name                  = "storage-file-dns-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file.name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmos_db" {
  count                 = var.enable_private_networking ? 1 : 0
  name                  = "cosmos-dns-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos_db.name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "ai_services" {
  count                 = var.enable_private_networking ? 1 : 0
  name                  = "ai-services-dns-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.ai_services.name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "ai_foundry" {
  count                 = var.enable_private_networking ? 1 : 0
  name                  = "ai-foundry-dns-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.ai_foundry.name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  count                 = var.enable_private_networking ? 1 : 0
  name                  = "postgresql-dns-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  tags                  = local.common_tags
}

# Private Endpoint Subnet
resource "azurerm_subnet" "private_endpoints" {
  count                = var.enable_private_networking ? 1 : 0
  name                 = "private-endpoints-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [local.private_endpoint_prefix]

  # Disable network policies for private endpoints
  private_endpoint_network_policies = "Disabled"
}

# Key Vault Private Endpoint
resource "azurerm_private_endpoint" "key_vault" {
  count               = var.enable_private_networking ? 1 : 0
  name                = "${local.key_vault_name}-pe"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints[0].id

  private_service_connection {
    name                           = "${local.key_vault_name}-psc"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "kv-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault.id]
  }

  tags = local.common_tags
}

# Storage Account Private Endpoint (Function App storage)
resource "azurerm_private_endpoint" "storage_blob" {
  count               = var.enable_private_networking ? 1 : 0
  name                = "${local.storage_account_name}-blob-pe"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints[0].id

  private_service_connection {
    name                           = "${local.storage_account_name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "storage-blob-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_blob.id]
  }

  tags = local.common_tags
}

# AI Foundry Storage Account Private Endpoint
resource "azurerm_private_endpoint" "ai_storage_blob" {
  count               = var.enable_private_networking ? 1 : 0
  name                = "${local.ai_storage_name}-blob-pe"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints[0].id

  private_service_connection {
    name                           = "${local.ai_storage_name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.ai_foundry.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "ai-storage-blob-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_blob.id]
  }

  tags = local.common_tags
}

# Cosmos DB Private Endpoint
resource "azurerm_private_endpoint" "cosmos_db" {
  count               = var.enable_private_networking ? 1 : 0
  name                = "${local.cosmos_account_name}-pe"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints[0].id

  private_service_connection {
    name                           = "${local.cosmos_account_name}-psc"
    private_connection_resource_id = azurerm_cosmosdb_account.ai_foundry.id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "cosmos-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmos_db.id]
  }

  tags = local.common_tags
}

# AI Foundry Private Endpoint
resource "azurerm_private_endpoint" "ai_foundry" {
  count               = var.enable_private_networking ? 1 : 0
  name                = "${local.ai_hub_name}-pe"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints[0].id

  private_service_connection {
    name                           = "${local.ai_hub_name}-psc"
    private_connection_resource_id = azurerm_cognitive_account.ai_foundry.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "ai-foundry-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.ai_services.id, azurerm_private_dns_zone.ai_foundry.id]
  }

  tags = local.common_tags
}

# PostgreSQL Private Endpoint
resource "azurerm_private_endpoint" "postgresql" {
  count               = var.enable_private_networking ? 1 : 0
  name                = "${local.postgresql_server_name}-pe"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints[0].id

  private_service_connection {
    name                           = "${local.postgresql_server_name}-psc"
    private_connection_resource_id = azurerm_postgresql_flexible_server.app_database.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "postgresql-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.postgresql.id]
  }

  tags = local.common_tags

  depends_on = [
    azurerm_postgresql_flexible_server.app_database
  ]
}