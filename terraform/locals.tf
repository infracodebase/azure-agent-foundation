locals {
  # Generate unique suffix for resources that need globally unique names
  name_suffix = random_id.this.hex

  # Common naming convention
  resource_group_name    = "${var.project_name}-${var.environment}-rg"
  key_vault_name         = "aif-${var.environment}-kv-${local.name_suffix}" # Must be 3-24 chars
  storage_account_name   = "aif${var.environment}st${local.name_suffix}"    # Must be 3-24 chars, lowercase alphanumeric only
  ai_storage_name        = "aif${var.environment}ai${local.name_suffix}"    # AI Foundry dedicated storage
  function_app_name      = "${var.project_name}-${var.environment}-func-${local.name_suffix}"
  api_management_name    = "${var.project_name}-${var.environment}-apim-${local.name_suffix}"
  ai_hub_name            = "${var.project_name}-${var.environment}-aihub-${local.name_suffix}"
  ai_project_name        = "${var.project_name}-${var.environment}-aiproj-${local.name_suffix}"
  api_center_name        = "${var.project_name}-${var.environment}-apicenter-${local.name_suffix}"
  container_env_name     = "${var.project_name}-${var.environment}-containerenv-${local.name_suffix}"
  container_app_name     = "${var.project_name}-${var.environment}-chat-${local.name_suffix}"
  cosmos_account_name    = "${var.project_name}-${var.environment}-cosmos-${local.name_suffix}"
  postgresql_server_name = "${var.project_name}-${var.environment}-postgres-${local.name_suffix}"
  front_door_name        = "${var.project_name}-${var.environment}-fd-${local.name_suffix}"
  vnet_name              = "${var.project_name}-${var.environment}-vnet"

  # Network configuration
  vnet_address_space      = ["10.0.0.0/16"]
  apim_subnet_prefix      = "10.0.1.0/24"
  compute_subnet_prefix   = "10.0.2.0/24" # For Function Apps and Container Apps
  container_subnet_prefix = "10.0.4.0/23" # Container Apps requires at least /23
  private_endpoint_prefix = "10.0.6.0/24" # For all private endpoints

  # PostgreSQL configuration
  postgres_admin_username = "aifadmin"
  postgres_admin_password = random_password.postgres_admin.result
  app_database_name       = "${var.project_name}_${var.environment}_db"

  # Common tags with additional context
  common_tags = merge(var.tags, {
    Location = var.location
  })
}