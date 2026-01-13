locals {
  # Generate unique suffix for resources that need globally unique names
  name_suffix = random_id.this.hex

  # Common naming convention
  resource_group_name  = "${var.project_name}-${var.environment}-rg"
  key_vault_name       = "${var.project_name}-${var.environment}-kv-${local.name_suffix}"
  storage_account_name = "${replace(var.project_name, "-", "")}${var.environment}sa${local.name_suffix}"
  function_app_name    = "${var.project_name}-${var.environment}-func-${local.name_suffix}"
  api_management_name  = "${var.project_name}-${var.environment}-apim-${local.name_suffix}"
  ai_hub_name          = "${var.project_name}-${var.environment}-aihub-${local.name_suffix}"
  ai_project_name      = "${var.project_name}-${var.environment}-aiproj-${local.name_suffix}"
  api_center_name      = "${var.project_name}-${var.environment}-apicenter-${local.name_suffix}"
  container_env_name   = "${var.project_name}-${var.environment}-containerenv-${local.name_suffix}"
  container_app_name   = "${var.project_name}-${var.environment}-chat-${local.name_suffix}"
  vnet_name            = "${var.project_name}-${var.environment}-vnet"

  # Network configuration
  vnet_address_space      = ["10.0.0.0/16"]
  apim_subnet_prefix      = "10.0.1.0/24"
  func_subnet_prefix      = "10.0.2.0/24"
  container_subnet_prefix = "10.0.3.0/24"

  # Common tags with additional context
  common_tags = merge(var.tags, {
    Location = var.location
  })
}