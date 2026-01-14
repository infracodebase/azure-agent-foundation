# Azure API Center using AzAPI provider for full functionality
# This provides proper API discovery and governance capabilities

# API Center resource using AzAPI provider
resource "azapi_resource" "api_center" {
  type      = "Microsoft.ApiCenter/services@2024-03-01"
  name      = local.api_center_name
  location  = azurerm_resource_group.this.location
  parent_id = azurerm_resource_group.this.id

  body = {
    properties = {}
  }

  tags = local.common_tags
}

# Use the default workspace that Azure API Center creates automatically
# Azure API Center has a limit of 1 workspace per service, and it creates "default" automatically
data "azapi_resource" "api_center_workspace" {
  type      = "Microsoft.ApiCenter/services/workspaces@2024-03-01"
  name      = "default"
  parent_id = azapi_resource.api_center.id
}

# API Center environment for different deployment stages
resource "azapi_resource" "api_center_environment" {
  type      = "Microsoft.ApiCenter/services/workspaces/environments@2024-03-01"
  name      = "development"
  parent_id = data.azapi_resource.api_center_workspace.id

  body = {
    properties = {
      title       = "Development Environment"
      description = "Development environment for AI Foundation APIs"
      kind        = "development"
      server = {
        type = "Azure API Management"
        managementPortalUri = [
          "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${azurerm_api_management.this.id}/overview"
        ]
      }
      onboarding = {
        instructions = "Connect to the development environment for testing and development of AI Foundation APIs"
        developerPortalUri = [
          azurerm_api_management.this.developer_portal_url
        ]
      }
    }
  }
}

# Register the CRUD MCP API in API Center
resource "azapi_resource" "crud_mcp_api" {
  type      = "Microsoft.ApiCenter/services/workspaces/apis@2024-03-01"
  name      = "crud-mcp-server"
  parent_id = data.azapi_resource.api_center_workspace.id

  body = {
    properties = {
      title       = "CRUD MCP Server API"
      kind        = "rest"
      description = "MCP (Model Context Protocol) server providing CRUD operations for AI Foundation"
      summary     = "REST API that functions as an MCP server for AI agents to perform CRUD operations on data"

      # Terms of service
      termsOfService = {
        url = "https://company.com/api-terms"
      }

      # License information - using correct schema
      license = {
        name       = "MIT"
        identifier = "MIT"
        url        = "https://opensource.org/licenses/MIT"
      }

      # Contact information - using correct schema
      contacts = [{
        name  = "AI Foundation Team"
        email = "ai-team@company.com"
        url   = "https://company.com/ai-foundation"
      }]

      # External documentation - using correct array format
      externalDocumentation = [{
        title       = "MCP Server Documentation"
        description = "Comprehensive documentation for the CRUD MCP server implementation"
        url         = "https://github.com/company/ai-foundation/docs"
      }]
    }
  }
}

# API version for the CRUD MCP API
resource "azapi_resource" "crud_api_version" {
  type      = "Microsoft.ApiCenter/services/workspaces/apis/versions@2024-03-01"
  name      = "v1-0"
  parent_id = azapi_resource.crud_mcp_api.id

  body = {
    properties = {
      title          = "Version 1.0"
      lifecycleStage = "development"
    }
  }
}

# Create API definition resource first
resource "azapi_resource" "crud_api_definition" {
  type      = "Microsoft.ApiCenter/services/workspaces/apis/versions/definitions@2024-03-01"
  name      = "openapi"
  parent_id = azapi_resource.crud_api_version.id

  body = {
    properties = {
      title       = "OpenAPI Definition"
      description = "OpenAPI 3.0 specification for CRUD MCP Server API"
    }
  }
}

# Import API specification from API Management (updates the definition)
# DISABLED: API Center can't reach APIM gateway URL from Azure's infrastructure
# Import spec manually via Azure Portal after deployment
resource "azapi_resource_action" "import_api_spec" {
  count = 0

  type        = "Microsoft.ApiCenter/services/workspaces/apis/versions/definitions@2024-03-01"
  resource_id = azapi_resource.crud_api_definition.id
  action      = "importSpecification"
  method      = "POST"

  body = {
    format = "link"
    value  = "${azurerm_api_management.this.gateway_url}/apis/${azurerm_api_management_api.crud_api.name}?export=true&format=openapi+json-link"
    specification = {
      name    = "openapi"
      version = "3.0.1"
    }
  }

  depends_on = [
    azurerm_api_management.this,
    azurerm_api_management_api.crud_api,
    azapi_resource.crud_api_definition
  ]
}

# API deployment linking to API Management
resource "azapi_resource" "crud_api_deployment" {
  type      = "Microsoft.ApiCenter/services/workspaces/apis/deployments@2024-03-01"
  name      = "dev-deployment"
  parent_id = azapi_resource.crud_mcp_api.id

  body = {
    properties = {
      title         = "Development Deployment"
      description   = "CRUD MCP server deployed in development environment"
      environmentId = "/workspaces/${data.azapi_resource.api_center_workspace.name}/environments/${azapi_resource.api_center_environment.name}"
      definitionId  = "/workspaces/${data.azapi_resource.api_center_workspace.name}/apis/${azapi_resource.crud_mcp_api.name}/versions/${azapi_resource.crud_api_version.name}/definitions/${azapi_resource.crud_api_definition.name}"
      server = {
        runtimeUri = [
          "${azurerm_api_management.this.gateway_url}/api"
        ]
      }
    }
  }

  depends_on = [azapi_resource.crud_api_definition]
}

# Output the API Center information
output "api_center_id" {
  description = "ID of the Azure API Center"
  value       = azapi_resource.api_center.id
}

output "api_center_url" {
  description = "URL to access the API Center in Azure Portal"
  value       = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${azapi_resource.api_center.id}/overview"
}

output "mcp_api_registration" {
  description = "MCP API registration details in API Center"
  value = {
    api_name      = azapi_resource.crud_mcp_api.name
    api_id        = azapi_resource.crud_mcp_api.id
    version       = azapi_resource.crud_api_version.name
    environment   = azapi_resource.api_center_environment.name
    deployment_id = azapi_resource.crud_api_deployment.id
    mcp_endpoint  = "${azurerm_api_management.this.gateway_url}/api"
    discovery_url = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${azapi_resource.api_center.id}/overview"
  }
}