# Azure AI Foundation - Terraform Infrastructure

This directory contains the Terraform configuration for deploying the Azure AI Foundation infrastructure.

## 🏗️ Architecture

The infrastructure deploys a complete Azure AI Foundation with:

- **API Management** - Exposes Function App as MCP server
- **Function App** - CRUD REST service (MCP server implementation)
- **Azure AI Foundry** - Modern AI services for agent management
- **API Center** - API governance and discovery
- **Container Apps** - Chat interface application
- **Key Vault** - Secure secrets management
- **Storage Account** - Data persistence
- **Virtual Network** - Secure networking with 3 subnets
- **Application Insights & Log Analytics** - Monitoring

## 💰 Estimated Cost

**Monthly cost: ~$60-100** (primarily from API Management Developer tier)

## 🚀 Quick Start

1. **Authenticate with Azure**:
   ```bash
   az login
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Review the plan**:
   ```bash
   terraform plan
   ```

4. **Deploy infrastructure**:
   ```bash
   terraform apply
   ```

## ⚙️ Configuration

### Required Variables

The `terraform.tfvars` file contains all necessary configuration. Key settings:

- `api_management_sku = "Developer_1"` - Cost-optimized for testing
- `function_app_service_plan_sku = "Y1"` - Consumption pricing
- `container_apps_environment_type = "Consumption"` - Pay-per-use

### Optional Customization

- `admin_object_id` - Set to your Azure AD user ID for Key Vault access
- `location` - Azure region (default: "East US")
- `environment` - Environment suffix (default: "dev")

## 📝 Outputs

After deployment, Terraform provides these key outputs:

- `function_app_url` - Function App endpoint
- `api_management_gateway_url` - API Management gateway
- `mcp_server_endpoint` - MCP server endpoint for AI agents
- `container_app_url` - Chat interface URL
- `api_center_url` - API governance portal

## 🔧 Features

### MCP Server Support
- ✅ Automated MCP server creation (no manual steps)
- ✅ Full MCP protocol compliance (2024-11-05)
- ✅ CRUD operations exposed as MCP tools
- ✅ Streamable HTTP transport

### Security & Compliance
- ✅ Managed identities for secure authentication
- ✅ Key Vault integration for secrets
- ✅ Virtual network isolation
- ✅ RBAC with least privilege
- ✅ Security baseline compliance

### Governance
- ✅ API Center for discovery and governance
- ✅ Automatic API spec import
- ✅ Comprehensive monitoring and logging

## 🛡️ Security

The infrastructure follows Azure security baselines:
- All services use managed identities
- Secrets stored in Key Vault
- Network segmentation with NSGs
- TLS encryption in transit
- RBAC with least privilege principles

## 📊 Monitoring

Built-in monitoring with:
- Application Insights for application telemetry
- Log Analytics for centralized logging
- Azure Monitor for infrastructure metrics

## 🏃‍♂️ Next Steps

After infrastructure deployment:
1. Deploy the API code to the Function App
2. Deploy the chat interface to Container Apps
3. Test the MCP server endpoints
4. Configure AI agents to use the MCP server