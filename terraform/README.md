# Azure AI Foundation - Terraform Infrastructure

This directory contains the Terraform configuration for deploying the Azure AI Foundation infrastructure.

## 🏗️ Architecture

The infrastructure deploys a complete Azure AI Foundation with:

- **Azure Front Door** - CDN with Web Application Firewall (WAF) protection
- **API Management** - Exposes Function App as MCP server
- **Function App** - CRUD REST service (MCP server implementation)
- **Azure AI Foundry** - Modern AI services with hub, project, and agent management
  - GPT-4o-mini model deployment for cost-effective development
  - Pre-configured AI agents (sample, customer support, data analysis)
- **API Center** - API governance and discovery
- **Container Apps** - Chat interface application
- **PostgreSQL Flexible Server** - Managed database with private endpoints
- **Key Vault** - Secure secrets management
- **Storage Account** - Data persistence
- **Virtual Network** - Secure networking with private endpoints
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

### AI Agents
- ✅ Azure AI Foundry hub and project configuration
- ✅ GPT-4o-mini model deployment (cost-effective)
- ✅ Pre-configured agents using azapi provider:
  - Sample Agent - General-purpose AI assistant
  - Customer Support Agent - Specialized for customer interactions
  - Data Analysis Agent - Focused on data processing and insights
- ✅ Code interpreter and retrieval tools enabled
- ✅ Customizable agent instructions and parameters

### MCP Server Support
- ✅ Automated MCP server creation (no manual steps)
- ✅ Full MCP protocol compliance (2024-11-05)
- ✅ CRUD operations exposed as MCP tools
- ✅ Streamable HTTP transport

### Security & Compliance
- ✅ Azure Front Door with WAF protection
- ✅ Managed identities for secure authentication
- ✅ Private endpoints for all PaaS services
- ✅ Network Security Groups (NSGs) on all subnets
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
4. Access AI Foundry agents in Azure Portal or via SDK
5. Customize agent configurations in `foundry-agents.tf`

## 📁 File Structure

- `main.tf` - Core infrastructure (resource group, networking)
- `foundry.tf` - Azure AI Foundry hub, project, and model deployment
- `foundry-agents.tf` - AI agent definitions using azapi provider
- `function_app.tf` - Azure Function App for MCP server
- `api_management.tf` - API Management gateway configuration
- `api_center.tf` - API governance and discovery
- `container_apps.tf` - Container Apps for chat interface
- `keyvault.tf` - Key Vault and secrets management
- `storage.tf` - Storage account configuration
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `providers.tf` - Provider configurations
- `terraform.tf` - Terraform and provider version constraints
- `locals.tf` - Local values and naming conventions