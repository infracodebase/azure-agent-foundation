# Network Security Groups for subnet-level security
# Following Azure security best practices with least privilege access

# NSG for API Management subnet
resource "azurerm_network_security_group" "apim" {
  name                = "${local.api_management_name}-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  # Allow HTTPS inbound for API Management
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

  # Allow HTTP inbound for API Management (can be disabled if HTTPS-only)
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

  # Allow API Management management endpoint
  security_rule {
    name                       = "AllowAPIMManagement"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3443"
    source_address_prefix      = "ApiManagement"
    destination_address_prefix = "*"
  }

  # Allow outbound to Function subnet
  security_rule {
    name                       = "AllowToFunctionSubnet"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = local.func_subnet_prefix
  }

  tags = local.common_tags
}

# NSG for Function App subnet
resource "azurerm_network_security_group" "func" {
  name                = "${local.function_app_name}-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  # Allow HTTPS inbound from APIM subnet
  security_rule {
    name                       = "AllowFromAPIM"
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

  # Allow outbound to Azure services and APIM
  security_rule {
    name                       = "AllowToAzureAndAPIM"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "*"
    destination_address_prefixes = ["AzureCloud", local.apim_subnet_prefix]
  }

  tags = local.common_tags
}

# Associate NSGs with subnets
resource "azurerm_subnet_network_security_group_association" "apim" {
  count                     = var.enable_private_networking ? 1 : 0
  subnet_id                 = azurerm_subnet.apim[0].id
  network_security_group_id = azurerm_network_security_group.apim.id
}

resource "azurerm_subnet_network_security_group_association" "func" {
  count                     = var.enable_private_networking ? 1 : 0
  subnet_id                 = azurerm_subnet.func[0].id
  network_security_group_id = azurerm_network_security_group.func.id
}

resource "azurerm_subnet_network_security_group_association" "container" {
  count                     = var.enable_private_networking ? 1 : 0
  subnet_id                 = azurerm_subnet.container[0].id
  network_security_group_id = azurerm_network_security_group.container.id
}