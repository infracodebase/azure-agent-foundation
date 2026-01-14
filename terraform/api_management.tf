# API Management instance with secure configuration
# Supports MCP server functionality for exposing REST APIs as Model Context Protocol servers
# MCP server creation is automated via AzAPI provider below
resource "azurerm_api_management" "this" {
  name                = local.api_management_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  publisher_name      = "AI Foundation"
  publisher_email     = "admin@company.com" # Should be updated to actual email
  sku_name            = var.api_management_sku

  # Security configurations following Azure API Management Security Baseline
  min_api_version = "2019-12-01"

  identity {
    type = "SystemAssigned"
  }

  # Virtual network configuration (only when private networking is enabled)
  virtual_network_type = var.enable_private_networking ? "External" : "None"

  dynamic "virtual_network_configuration" {
    for_each = var.enable_private_networking ? [1] : []
    content {
      subnet_id = azurerm_subnet.apim[0].id
    }
  }

  # APIM requires NSG to be associated with subnet before deployment (when using VNet)
  depends_on = [azurerm_subnet_network_security_group_association.apim]

  # Security and authentication settings
  sign_in {
    enabled = false
  }

  sign_up {
    enabled = false
    terms_of_service {
      enabled          = false
      consent_required = false
    }
  }

  # Policy will be configured via azurerm_api_management_policy resource

  # MCP compatibility: Ensure diagnostic settings don't interfere with response streaming
  # If global diagnostic logging is enabled, "Number of payload bytes to log" for
  # Frontend Response must be set to 0 to prevent response body logging interference

  tags = local.common_tags
}

# API Management global policy
# IMPORTANT: MCP servers require streamable responses - avoid accessing context.Response.Body
# which triggers response buffering and causes MCP server malfunction
resource "azurerm_api_management_policy" "global" {
  api_management_id = azurerm_api_management.this.id

  xml_content = <<XML
<policies>
  <inbound>
    <cors allow-credentials="false">
      <allowed-origins>
        <origin>*</origin>
      </allowed-origins>
      <allowed-methods>
        <method>GET</method>
        <method>POST</method>
        <method>PUT</method>
        <method>DELETE</method>
        <method>OPTIONS</method>
      </allowed-methods>
      <allowed-headers>
        <header>*</header>
      </allowed-headers>
    </cors>
    <set-header name="X-Forwarded-Host" exists-action="override">
      <value>@(context.Request.OriginalUrl.Host)</value>
    </set-header>
    <!-- MCP-compatible: Avoid response body access to maintain streaming capabilities -->
  </inbound>
  <backend>
    <forward-request />
  </backend>
  <outbound>
    <!-- MCP-compatible: No response body manipulation to preserve streaming -->
  </outbound>
  <on-error />
</policies>
XML
}

# Grant API Management access to Key Vault for storing certificates and secrets
resource "azurerm_role_assignment" "apim_kv_access" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_api_management.this.identity[0].principal_id
}

# API for the Function App CRUD service
# APIM's MCP server feature will expose these operations as MCP tools automatically
resource "azurerm_api_management_api" "crud_api" {
  name                  = "crud-api"
  resource_group_name   = azurerm_resource_group.this.name
  api_management_name   = azurerm_api_management.this.name
  revision              = "1"
  display_name          = "CRUD API"
  path                  = "api"
  protocols             = ["https"]
  service_url           = "https://${azurerm_linux_function_app.this.default_hostname}/api"
  subscription_required = true

  import {
    content_format = "openapi+json"
    content_value = jsonencode({
      openapi = "3.0.0"
      info = {
        title       = "CRUD API"
        version     = "1.0.0"
        description = "REST API providing CRUD operations - exposed as MCP tools via APIM"
      }
      servers = [{
        url = "https://${azurerm_api_management.this.gateway_url}/api"
      }]
      paths = {
        # CRUD operations - APIM MCP server exposes these as tools automatically
        "/items" = {
          get = {
            summary     = "Get all items"
            description = "MCP tool: Retrieve all items from the data store"
            operationId = "GetItems"
            tags        = ["Items", "MCP-Tools"]
            responses = {
              "200" = {
                description = "Success"
                content = {
                  "application/json" = {
                    schema = {
                      type = "array"
                      items = {
                        type = "object"
                        properties = {
                          id          = { type = "string" }
                          name        = { type = "string" }
                          description = { type = "string" }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          post = {
            summary     = "Create a new item"
            description = "MCP tool: Create a new item in the data store"
            operationId = "CreateItem"
            tags        = ["Items", "MCP-Tools"]
            requestBody = {
              required = true
              content = {
                "application/json" = {
                  schema = {
                    type = "object"
                    properties = {
                      name        = { type = "string" }
                      description = { type = "string" }
                    }
                    required = ["name"]
                  }
                }
              }
            }
            responses = {
              "201" = {
                description = "Created"
                content = {
                  "application/json" = {
                    schema = {
                      type = "object"
                      properties = {
                        id          = { type = "string" }
                        name        = { type = "string" }
                        description = { type = "string" }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        "/items/{id}" = {
          get = {
            summary     = "Get item by ID"
            description = "MCP tool: Retrieve a specific item by its ID"
            operationId = "GetItemById"
            tags        = ["Items", "MCP-Tools"]
            parameters = [{
              name     = "id"
              in       = "path"
              required = true
              schema   = { type = "string" }
            }]
            responses = {
              "200" = {
                description = "Success"
                content = {
                  "application/json" = {
                    schema = {
                      type = "object"
                      properties = {
                        id          = { type = "string" }
                        name        = { type = "string" }
                        description = { type = "string" }
                      }
                    }
                  }
                }
              }
            }
          }
          put = {
            summary     = "Update item"
            description = "MCP tool: Update an existing item in the data store"
            operationId = "UpdateItem"
            tags        = ["Items", "MCP-Tools"]
            parameters = [{
              name     = "id"
              in       = "path"
              required = true
              schema   = { type = "string" }
            }]
            requestBody = {
              required = true
              content = {
                "application/json" = {
                  schema = {
                    type = "object"
                    properties = {
                      name        = { type = "string" }
                      description = { type = "string" }
                    }
                  }
                }
              }
            }
            responses = {
              "200" = { description = "Updated" }
            }
          }
          delete = {
            summary     = "Delete item"
            description = "MCP tool: Remove an item from the data store"
            operationId = "DeleteItem"
            tags        = ["Items", "MCP-Tools"]
            parameters = [{
              name     = "id"
              in       = "path"
              required = true
              schema   = { type = "string" }
            }]
            responses = {
              "204" = { description = "Deleted" }
            }
          }
        }
      }
    })
  }
}

# API Operation policies for authentication
resource "azurerm_api_management_api_policy" "crud_api_policy" {
  api_name            = azurerm_api_management_api.crud_api.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name

  xml_content = <<XML
<policies>
  <inbound>
    <base />
    <set-header name="x-functions-key" exists-action="override">
      <value>{{function-api-key}}</value>
    </set-header>
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML
}

# Named value for Function App API key
resource "azurerm_api_management_named_value" "function_api_key" {
  name                = "function-api-key"
  resource_group_name = azurerm_resource_group.this.name
  api_management_name = azurerm_api_management.this.name
  display_name        = "Function-API-Key"
  secret              = true

  value_from_key_vault {
    # Use versionless_id so APIM always gets the latest secret version
    secret_id = azurerm_key_vault_secret.function_api_key.versionless_id
  }

  depends_on = [azurerm_role_assignment.apim_kv_access]
}

# Subscription for API access (service-wide scope for internal MCP server use)
# Omitting api_id and product_id gives service-wide scope
resource "azurerm_api_management_subscription" "crud_api_subscription" {
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  display_name        = "MCP Internal Subscription"
  state               = "active"
}

# MCP Server Creation using AzAPI provider
# Note: MCP servers are in preview and the exact API may evolve
# This configuration attempts to automate the creation through Azure REST API
#
# If this fails during deployment, it means the API endpoints aren't available yet.
# In that case, you can either:
# 1. Enable the fallback resource below by setting count = 1
# 2. Create the MCP server manually in Azure portal as documented
# 3. Wait for the API to become generally available

# MCP Server - exposes REST API as Model Context Protocol server for AI agents
# This creates an API with type="mcp" that references operations from the source API
resource "azapi_resource" "mcp_server" {
  type      = "Microsoft.ApiManagement/service/apis@2025-03-01-preview"
  name      = "crud-mcp"
  parent_id = azurerm_api_management.this.id

  schema_validation_enabled = false

  body = {
    properties = {
      displayName         = "CRUD MCP Server"
      path                = "crud-mcp"
      protocols           = ["https"]
      subscriptionRequired = false
      type                = "mcp"
      mcpTools = [
        {
          name        = "getAllItems"
          description = "Retrieve all items from the data store"
          operationId = "${azurerm_api_management.this.id}/apis/${azurerm_api_management_api.crud_api.name}/operations/GetItems"
        },
        {
          name        = "createItem"
          description = "Create a new item in the data store"
          operationId = "${azurerm_api_management.this.id}/apis/${azurerm_api_management_api.crud_api.name}/operations/CreateItem"
        },
        {
          name        = "getItemById"
          description = "Retrieve a specific item by its ID"
          operationId = "${azurerm_api_management.this.id}/apis/${azurerm_api_management_api.crud_api.name}/operations/GetItemById"
        },
        {
          name        = "updateItem"
          description = "Update an existing item in the data store"
          operationId = "${azurerm_api_management.this.id}/apis/${azurerm_api_management_api.crud_api.name}/operations/UpdateItem"
        },
        {
          name        = "deleteItem"
          description = "Remove an item from the data store"
          operationId = "${azurerm_api_management.this.id}/apis/${azurerm_api_management_api.crud_api.name}/operations/DeleteItem"
        }
      ]
    }
  }

  depends_on = [azurerm_api_management_api.crud_api]
}

# Named value for CRUD API subscription key - used by MCP server to call CRUD API
resource "azurerm_api_management_named_value" "crud_api_subscription_key" {
  name                = "crud-api-subscription-key"
  resource_group_name = azurerm_resource_group.this.name
  api_management_name = azurerm_api_management.this.name
  display_name        = "CRUD-API-Subscription-Key"
  secret              = true
  value               = azurerm_api_management_subscription.crud_api_subscription.primary_key
}

# Policy for MCP server to inject subscription key when calling CRUD API operations
resource "azurerm_api_management_api_policy" "mcp_server_policy" {
  api_name            = azapi_resource.mcp_server.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name

  xml_content = <<XML
<policies>
  <inbound>
    <base />
    <set-header name="Ocp-Apim-Subscription-Key" exists-action="override">
      <value>{{crud-api-subscription-key}}</value>
    </set-header>
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML

  depends_on = [azurerm_api_management_named_value.crud_api_subscription_key]
}