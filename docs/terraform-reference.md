# Terraform Configuration Reference

This document provides comprehensive reference information for the Azure AI Foundation Terraform configuration.

## Requirements & Providers

| Component | Version | Purpose |
|-----------|---------|---------|
| **Terraform** | >= 1.12.0 | Infrastructure as Code engine |
| **Azure Provider** | ~> 4.57 | Primary Azure resource management |
| **Azure API Provider** | ~> 2.1 | Preview APIs (AI Foundry, API Center, MCP) |
| **Azure AD Provider** | ~> 3.0 | Identity and access management |
| **HTTP Provider** | ~> 3.4 | External data sources (IP detection) |
| **Random Provider** | ~> 3.7 | Unique resource naming |

## Complete Variable Reference

### Core Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `project_name` | `string` | `"ai-foundation"` | Base name for all resources (affects naming convention) |
| `environment` | `string` | `"dev"` | Environment suffix (`dev`, `staging`, `prod`) |
| `location` | `string` | `"East US"` | Azure region for resource deployment |

### Networking Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_private_networking` | `bool` | `false` | **CRITICAL**: Enable VNet integration and private endpoints |
| `vnet_address_space` | `list(string)` | `["10.0.0.0/16"]` | Virtual network address space |

### Compute Configuration
| Variable | Type | Default | Production Recommended | Description |
|----------|------|---------|------------------------|-------------|
| `function_app_service_plan_sku` | `string` | `"Y1"` | `"EP1"` or higher | Function App hosting plan |
| `api_management_sku` | `string` | `"Developer_1"` | `"Standard_1"` or higher | API Management tier |
| `container_apps_environment_type` | `string` | `"Consumption"` | `"Consumption"` | Container Apps billing model |

### AI Services Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ai_model_deployment` | `string` | `"gpt-4o-mini"` | Default model deployment |
| `ai_model_capacity` | `number` | `10` | Tokens per minute (thousands) |

### Security Configuration
| Variable | Type | Default | Production Value | Description |
|----------|------|---------|------------------|-------------|
| `admin_object_id` | `string` | `null` | User/SP Object ID | Specific user for Key Vault admin access |
| `tags` | `map(string)` | See defaults | Custom tags | Common resource tags for governance |

## Complete Output Reference

| Output | Description | Example Value |
|--------|-------------|---------------|
| `api_management_gateway_url` | **Primary API endpoint** | `https://ai-foundation-dev-apim-abc123.azure-api.net` |
| `mcp_server_endpoint` | **MCP server URL for AI agents** | `https://.../crud-mcp/mcp` |
| `ai_foundry_endpoint` | **AI Foundry project endpoint** | `https://ai-foundation-dev-aihub-abc123.services.ai.azure.com` |
| `function_app_url` | **Backend service URL** | `https://ai-foundation-dev-func-abc123.azurewebsites.net` |
| `container_app_url` | **Chat interface URL** | `https://ai-foundation-dev-chat-abc123.azurecontainerapps.io` |
| `api_center_url` | **API governance portal** | Portal link to API Center |
| `api_subscription_key` | **Primary API access key** | `********************************` |
| `key_vault_uri` | **Secrets management endpoint** | `https://ai-foundation-dev-kv-abc123.vault.azure.net` |

## Resource Architecture

**Total Resources Deployed**: 45+ Azure resources across 8 categories

| Category | Resources | Purpose |
|----------|-----------|---------|
| **Core Infrastructure** | Resource Group, Virtual Network, Subnets, NSGs | Foundational networking and organization |
| **AI Services** | AI Foundry Hub, Project, GPT-4o-mini Deployment | Declarative agent hosting and AI models |
| **API Gateway** | API Management, MCP Server, Named Values | REST-to-MCP conversion and API governance |
| **Backend Services** | Function App, Service Plan, Application Insights | Serverless business logic and monitoring |
| **Container Platform** | Container Apps Environment, Chat App, Dapr Components | Scalable web application hosting |
| **Data & Storage** | Storage Account, Containers, Network Rules | Persistent data and blob storage |
| **Security** | Key Vault, Secrets, 10+ Role Assignments | Centralized secrets and identity management |
| **Discovery** | API Center, Environment, API Registrations | Service discovery and governance |

## Environment Examples

### Development Environment
```bash
terraform apply \
  -var="environment=dev" \
  -var="enable_private_networking=false" \
  -var="function_app_service_plan_sku=Y1" \
  -var="api_management_sku=Developer_1"
```
- **Cost**: ~$100-150/month
- **Security**: Basic (public endpoints with authentication)
- **Features**: Full functionality for development and testing

### Production Environment
```bash
terraform apply \
  -var="environment=prod" \
  -var="enable_private_networking=true" \
  -var="function_app_service_plan_sku=EP1" \
  -var="api_management_sku=Standard_1"
```
- **Cost**: ~$400-600/month
- **Security**: Enhanced (private networking, advanced monitoring)
- **Features**: Production-grade security and scalability