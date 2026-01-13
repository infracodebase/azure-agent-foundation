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

  # Virtual network configuration for secure connectivity
  virtual_network_type = "External"
  virtual_network_configuration {
    subnet_id = azurerm_subnet.apim.id
  }

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
        title       = "CRUD MCP Server"
        version     = "1.0.0"
        description = "Model Context Protocol server providing CRUD operations for AI agents"
        "x-mcp-server" = {
          name = "crud-mcp-server"
          version = "1.0.0"
          protocol_version = "2024-11-05"
        }
      }
      servers = [{
        url = "https://${azurerm_api_management.this.gateway_url}/api"
      }]
      paths = {
        # MCP Server Information Endpoint (required for MCP)
        "/mcp/info" = {
          get = {
            summary     = "Get MCP server information"
            description = "Returns server capabilities and metadata for MCP clients"
            operationId = "getMCPInfo"
            tags        = ["MCP"]
            responses = {
              "200" = {
                description = "Server information"
                content = {
                  "application/json" = {
                    schema = {
                      type = "object"
                      properties = {
                        name             = { type = "string" }
                        version          = { type = "string" }
                        protocol_version = { type = "string" }
                        capabilities = {
                          type = "object"
                          properties = {
                            resources = { type = "boolean" }
                            tools     = { type = "boolean" }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        # MCP Resources Endpoint
        "/mcp/resources" = {
          get = {
            summary     = "List available resources"
            description = "Returns list of resources available through this MCP server"
            operationId = "listMCPResources"
            tags        = ["MCP"]
            responses = {
              "200" = {
                description = "List of available resources"
                content = {
                  "application/json" = {
                    schema = {
                      type = "object"
                      properties = {
                        resources = {
                          type = "array"
                          items = {
                            type = "object"
                            properties = {
                              uri         = { type = "string" }
                              name        = { type = "string" }
                              description = { type = "string" }
                              mimeType    = { type = "string" }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        # MCP Tools Endpoint
        "/mcp/tools" = {
          get = {
            summary     = "List available tools"
            description = "Returns list of tools available through this MCP server"
            operationId = "listMCPTools"
            tags        = ["MCP"]
            responses = {
              "200" = {
                description = "List of available tools"
                content = {
                  "application/json" = {
                    schema = {
                      type = "object"
                      properties = {
                        tools = {
                          type = "array"
                          items = {
                            type = "object"
                            properties = {
                              name        = { type = "string" }
                              description = { type = "string" }
                              inputSchema = { type = "object" }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          post = {
            summary     = "Execute MCP tool"
            description = "Execute a tool through the MCP server"
            operationId = "executeMCPTool"
            tags        = ["MCP"]
            requestBody = {
              required = true
              content = {
                "application/json" = {
                  schema = {
                    type = "object"
                    properties = {
                      name      = { type = "string" }
                      arguments = { type = "object" }
                    }
                    required = ["name"]
                  }
                }
              }
            }
            responses = {
              "200" = {
                description = "Tool execution result"
                content = {
                  "application/json" = {
                    schema = {
                      type = "object"
                      properties = {
                        content = {
                          type = "array"
                          items = {
                            type = "object"
                            properties = {
                              type = { type = "string" }
                              text = { type = "string" }
                            }
                          }
                        }
                        isError = { type = "boolean" }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        # Standard CRUD operations (MCP tools)
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
    secret_id = azurerm_key_vault_secret.function_api_key.id
  }

  depends_on = [azurerm_role_assignment.apim_kv_access]
}

# Subscription for API access
resource "azurerm_api_management_subscription" "crud_api_subscription" {
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  display_name        = "CRUD API Subscription"
  api_id              = azurerm_api_management_api.crud_api.id
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

# Primary approach: Use direct REST API call to create MCP server
resource "azapi_resource" "mcp_server" {
  type      = "Microsoft.ApiManagement/service/mcpServers@2024-05-01"
  name      = "crud-mcp-server"
  parent_id = azurerm_api_management.this.id

  # Disable schema validation for preview features
  schema_validation_enabled = false

  body = jsonencode({
    properties = {
      displayName = "CRUD MCP Server"
      description = "MCP server exposing CRUD operations for AI agents"
      backendMcpServer = {
        apiId = azurerm_api_management_api.crud_api.id
        selectedOperations = [
          {
            operationId = "GetItems"
            displayName = "Get Items"
          },
          {
            operationId = "CreateItem"
            displayName = "Create Item"
          },
          {
            operationId = "GetItemById"
            displayName = "Get Item By ID"
          },
          {
            operationId = "UpdateItem"
            displayName = "Update Item"
          },
          {
            operationId = "DeleteItem"
            displayName = "Delete Item"
          }
        ]
      }
    }
  })

  depends_on = [azurerm_api_management_api.crud_api]

  lifecycle {
    ignore_changes = [
      # Ignore changes to body if the API evolves
      body
    ]
  }
}