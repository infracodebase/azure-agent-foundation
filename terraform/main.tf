# Generate random ID for unique resource names
resource "random_id" "this" {
  byte_length = 4
}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Get current public IP for firewall rules (allows Terraform to access Key Vault)
data "http" "current_ip" {
  url = "https://api.ipify.org?format=text"
}

# Resource Group
resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Virtual Network for secure connectivity (only when private networking is enabled)
resource "azurerm_virtual_network" "this" {
  count               = var.enable_private_networking ? 1 : 0
  name                = local.vnet_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = local.vnet_address_space
  tags                = local.common_tags
}

# Subnet for API Management
resource "azurerm_subnet" "apim" {
  count                = var.enable_private_networking ? 1 : 0
  name                 = "apim-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [local.apim_subnet_prefix]
  service_endpoints    = ["Microsoft.KeyVault"]
}

# Subnet for Compute Services (Function Apps)
resource "azurerm_subnet" "compute" {
  count                = var.enable_private_networking ? 1 : 0
  name                 = "compute-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [local.compute_subnet_prefix]

  delegation {
    name = "Microsoft.Web.serverFarms"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
}

# Subnet for Container Apps
resource "azurerm_subnet" "container_apps" {
  count                = var.enable_private_networking ? 1 : 0
  name                 = "container-apps-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [local.container_subnet_prefix]
}

# Network Security Group for API Management subnet
resource "azurerm_network_security_group" "apim" {
  count               = var.enable_private_networking ? 1 : 0
  name                = "apim-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags

  security_rule {
    name                       = "apim-management"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3443"
    source_address_prefix      = "ApiManagement"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "apim-gateway"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with APIM subnet
resource "azurerm_subnet_network_security_group_association" "apim" {
  count                     = var.enable_private_networking ? 1 : 0
  subnet_id                 = azurerm_subnet.apim[0].id
  network_security_group_id = azurerm_network_security_group.apim[0].id
}