# Azure Database for PostgreSQL - Flexible Server for Container App
# Managed PostgreSQL service with private endpoint integration

# Generate secure random password for PostgreSQL admin
resource "random_password" "postgres_admin" {
  length  = 32
  special = true
  upper   = true
  lower   = true
  numeric = true
}

resource "azurerm_postgresql_flexible_server" "app_database" {
  name                         = local.postgresql_server_name
  resource_group_name          = azurerm_resource_group.this.name
  location                     = azurerm_resource_group.this.location

  # Server configuration
  version                      = "16"         # Latest stable PostgreSQL version
  administrator_login          = local.postgres_admin_username
  administrator_password       = local.postgres_admin_password

  # SKU configuration for production workloads
  sku_name                     = "GP_Standard_D2s_v3"  # General Purpose, 2 vCores, 8GB RAM
  storage_mb                   = 32768                  # 32GB storage, can auto-grow
  storage_tier                 = "P10"                 # Premium SSD for better performance

  # Backup configuration
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false  # Can be enabled for higher availability needs

  # High availability (can be enabled for production)
  high_availability {
    mode = "SameZone"  # or "ZoneRedundant" for higher availability
  }

  # Security configurations
  public_network_access_enabled = false  # Only private access via private endpoint

  # Note: When using private endpoints (not VNet injection), we don't need
  # delegated_subnet_id. Access happens via private endpoint in the private endpoint subnet
  # VNet injection would require: delegated_subnet_id = azurerm_subnet.postgresql[0].id

  tags = local.common_tags

  depends_on = [
    azurerm_private_dns_zone.postgresql,
    azurerm_private_dns_zone_virtual_network_link.postgresql
  ]
}

# PostgreSQL Database for the application
resource "azurerm_postgresql_flexible_server_database" "app_database" {
  name      = local.app_database_name
  server_id = azurerm_postgresql_flexible_server.app_database.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Grant Container App managed identity access to PostgreSQL
# Note: This requires Azure AD authentication to be configured on the PostgreSQL server
resource "azurerm_postgresql_flexible_server_active_directory_administrator" "container_app" {
  count               = var.enable_private_networking ? 1 : 0
  server_name         = azurerm_postgresql_flexible_server.app_database.name
  resource_group_name = azurerm_resource_group.this.name
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = azurerm_container_app.chat_interface.identity[0].principal_id
  principal_name     = azurerm_container_app.chat_interface.name
  principal_type     = "ServicePrincipal"
}

# Store PostgreSQL connection string in Key Vault
resource "azurerm_key_vault_secret" "postgres_connection_string" {
  name         = "postgres-connection-string"
  value        = "postgresql://${local.postgres_admin_username}:${local.postgres_admin_password}@${azurerm_postgresql_flexible_server.app_database.fqdn}:5432/${local.app_database_name}?sslmode=require"
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [
    azurerm_key_vault_access_policy.terraform_deployment,
    azurerm_postgresql_flexible_server.app_database,
    azurerm_postgresql_flexible_server_database.app_database
  ]
}

# Store PostgreSQL admin password in Key Vault
resource "azurerm_key_vault_secret" "postgres_admin_password" {
  name         = "postgres-admin-password"
  value        = local.postgres_admin_password
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [
    azurerm_key_vault_access_policy.terraform_deployment
  ]
}