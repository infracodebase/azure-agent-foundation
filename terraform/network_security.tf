# Network Security Groups for subnet-level security
# Following Azure security best practices with least privilege access
# Note: APIM NSG is already defined in main.tf

# NSG for Compute subnet (Function Apps)
resource "azurerm_network_security_group" "compute" {
  name                = "${local.function_app_name}-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  # Allow inbound from APIM subnet
  security_rule {
    name                       = "AllowFromAPIManagement"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = local.apim_subnet_prefix
    destination_address_prefix = "*"
  }

  # Allow outbound to Azure services (Key Vault, Storage, etc.)
  security_rule {
    name                       = "AllowToAzureServices"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }

  tags = local.common_tags
}

# NSG for Container Apps subnet
resource "azurerm_network_security_group" "container" {
  name                = "${local.container_app_name}-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  # Allow HTTPS inbound for Container Apps
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow HTTP inbound for Container Apps
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow inbound from APIM subnet for MCP API calls
  security_rule {
    name                       = "AllowFromAPIManagement"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "8080"]
    source_address_prefix      = local.apim_subnet_prefix
    destination_address_prefix = "*"
  }

  # Allow outbound to private endpoints for database and AI services
  security_rule {
    name                       = "AllowToPrivateEndpoints"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "5432"] # HTTPS and PostgreSQL
    source_address_prefix      = "*"
    destination_address_prefix = local.private_endpoint_prefix
  }

  # Allow outbound to Azure services
  security_rule {
    name                       = "AllowToAzureServices"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }

  tags = local.common_tags
}

# NSG for Private Endpoint subnet
resource "azurerm_network_security_group" "private_endpoint" {
  name                = "${var.project_name}-${var.environment}-pe-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  # Allow inbound from compute and container subnets to private endpoints
  security_rule {
    name                       = "AllowFromCompute"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "5432"] # HTTPS and PostgreSQL
    source_address_prefixes    = [local.compute_subnet_prefix, local.container_subnet_prefix, local.apim_subnet_prefix]
    destination_address_prefix = "*"
  }

  # Allow outbound to Azure PaaS services
  security_rule {
    name                       = "AllowToAzurePaaS"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "5432"] # HTTPS and PostgreSQL
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }

  tags = local.common_tags
}

# Associate NSGs with subnets
# Note: APIM NSG association is already defined in main.tf

resource "azurerm_subnet_network_security_group_association" "compute" {
  count                     = var.enable_private_networking ? 1 : 0
  subnet_id                 = azurerm_subnet.compute[0].id
  network_security_group_id = azurerm_network_security_group.compute.id
}

resource "azurerm_subnet_network_security_group_association" "container" {
  count                     = var.enable_private_networking ? 1 : 0
  subnet_id                 = azurerm_subnet.container_apps[0].id
  network_security_group_id = azurerm_network_security_group.container.id
}

resource "azurerm_subnet_network_security_group_association" "private_endpoint" {
  count                     = var.enable_private_networking ? 1 : 0
  subnet_id                 = azurerm_subnet.private_endpoints[0].id
  network_security_group_id = azurerm_network_security_group.private_endpoint.id
}