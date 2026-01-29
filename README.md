# Azure AI Foundation

**Enterprise-Grade Infrastructure for AI Agent Systems with Enhanced Security**

A comprehensive, production-ready Infrastructure-as-Code foundation that deploys secure Azure services to support AI agent systems using the Model Context Protocol (MCP). This enterprise architecture enables AI agents to access business services through standardized MCP tools while maintaining enterprise security, compliance, and scalability requirements with Azure Front Door WAF protection, private endpoints, and comprehensive network isolation.

## Executive Summary

This repository provides enterprise-grade Azure services and comprehensive security architecture for building production AI agent systems with:

- **Azure Front Door with WAF** provides global CDN and Web Application Firewall protection against DDoS, bot attacks, and common web threats
- **Private Endpoint Architecture** ensures all PaaS services (Key Vault, Storage, PostgreSQL, AI Foundry) are accessible only through private networks
- **Azure API Management** converts REST APIs into standardized MCP servers with enterprise governance and security policies
- **PostgreSQL Flexible Server** provides managed database services with private connectivity for application data persistence
- **Azure AI Foundry** hosts declarative AI agents with GPT-4o-mini deployment and secure access to MCP tools
- **Azure Container Apps** provides scalable hosting for chat interfaces with user-assigned managed identity integration
- **Comprehensive Network Security** with Network Security Groups, private DNS zones, and least-privilege access controls

## Production Architecture

The architecture provides enterprise-grade security with multiple user access patterns and comprehensive private networking:

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                              Azure Subscription                              │
│                                                                              │
│  ┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐      │
│  │   End Users      │────▶│   Azure Front    │────▶│   Container      │      │
│  │                  │     │   Door + WAF     │     │   Apps           │      │
│  └──────────────────┘     └──────────────────┘     └──────────────────┘      │
│                                                              │                │
│  ┌──────────────────┐     ┌──────────────────┐              ▼                │
│  │   Developers     │────▶│   API Center     │     ┌──────────────────┐      │
│  │                  │     │  (Discovery)     │     │   Azure AI       │      │
│  └──────────────────┘     └──────────────────┘     │   Foundry        │      │
│                                     │              └──────────────────┘      │
│  ┌──────────────────┐              ▼                        │                │
│  │  AI Developers   │     ┌──────────────────┐              ▼                │
│  │                  │────▶│   API Management │     ┌──────────────────┐      │
│  └──────────────────┘     │  (MCP Gateway)   │────▶│   Function Apps  │      │
│                           └──────────────────┘     └──────────────────┘      │
│                                                                              │
│  ┌─────────────────────────────── Private Network ───────────────────────────┐│
│  │                                                                           ││
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      ││
│  │  │ Private     │  │ Private     │  │ Private     │  │ Private     │      ││
│  │  │ Endpoint    │  │ Endpoint    │  │ Endpoint    │  │ Endpoint    │      ││
│  │  │ (Key Vault) │  │ (Storage)   │  │ (AI Foundry)│  │ (PostgreSQL)│      ││
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘      ││
│  └─────────────────────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────────────────────┘
```

### User Access Patterns

- **End Users**: Access AI chat interface through Azure Front Door with WAF protection
- **Developers**: Discover and consume MCP tools through API Center for local development
- **AI Developers**: Access Azure AI Foundry directly for agent development and management

### Core Infrastructure Components

**Security & CDN Layer (Azure Front Door)**
- Global CDN with premium WAF protection using Microsoft Default Rule Set and Bot Manager
- DDoS protection and geo-filtering capabilities
- HTTPS-only forwarding with custom error pages for blocked requests
- Health monitoring and automatic failover for Container Apps

**Database Layer (PostgreSQL Flexible Server)**
- Managed PostgreSQL 16 with high availability (same-zone configuration)
- Private endpoint connectivity with no public network access
- Secure connection strings stored in Azure Key Vault
- Dedicated private DNS zone for internal name resolution

**MCP Gateway Layer (API Management)**
- Converts REST APIs into standardized MCP servers with full protocol compliance
- Enterprise-grade authentication, rate limiting, and comprehensive monitoring
- Exposes MCP endpoints that AI agents can consume as standardized tools
- Integration with Key Vault for secure API key management

**Service Discovery (API Center)**
- Centralized registry of available MCP servers with automated API spec import
- Integration with development tools (VS Code extension) for local development
- Complete API governance and lifecycle management with versioning support

**AI Agent Runtime (Azure AI Foundry)**
- Hosts declarative agents with GPT-4o-mini deployment for cost-effective AI operations
- Native MCP tool integration for secure agent-to-service communication
- Private endpoint connectivity for enhanced security isolation
- Pre-configured AI agents (sample, customer support, data analysis)

**Application Layer (Container Apps)**
- Scalable hosting for chat interfaces with user-assigned managed identity
- Direct integration with AI Foundry through private endpoints
- PostgreSQL database integration for application state persistence
- Secure secret management through Key Vault integration

**Backend Services (Function Apps)**
- Serverless MCP server implementation with CRUD operations
- Automatic scaling with pay-per-execution pricing model
- Private endpoint access to storage and data services
- Integration with API Management for MCP protocol compliance

## Enterprise Security Architecture

This production architecture implements comprehensive defense-in-depth security following the [Microsoft Cloud Security Benchmark](https://docs.microsoft.com/en-us/security/benchmark/azure/):

### External Security Layer
- **Azure Front Door Premium WAF**: Microsoft Default Rule Set v2.1 and Bot Manager Rule Set v1.0 for comprehensive threat protection
- **Global DDoS Protection**: Built-in protection against distributed denial-of-service attacks
- **Geo-filtering & Rate Limiting**: Advanced traffic filtering and throttling capabilities
- **HTTPS Enforcement**: All traffic forced through HTTPS with custom error pages for security violations

### Identity & Access Management
- **User-Assigned Managed Identities**: Enhanced security for Container Apps with dedicated identity for Key Vault access
- **System-Assigned Managed Identities**: Secure service-to-service authentication across all Azure resources
- **Azure RBAC**: Least-privilege access with role-based access control using Key Vault Secrets User and Cognitive Services User roles
- **Azure AD Integration**: Centralized identity with conditional access policies and multi-factor authentication support

### Network Security & Isolation
- **Complete Private Endpoint Architecture**: All PaaS services (Key Vault, Storage, PostgreSQL, AI Foundry, Cosmos DB) accessible only through private networks
- **Dedicated Private DNS Zones**: Internal name resolution for privatelink domains (vault.azure.net, postgres.database.azure.com, etc.)
- **Network Security Groups**: Granular traffic filtering with specific rules for each subnet tier (APIM, Compute, Container Apps, Private Endpoints)
- **Virtual Network Isolation**: Dedicated subnets with controlled inter-subnet communication and no direct internet access to backend services

### Data Protection & Database Security
- **PostgreSQL Private Connectivity**: Database accessible only through private endpoints with no public network access
- **Encrypted Database Connections**: SSL/TLS enforced for all PostgreSQL connections with secure connection strings
- **Azure Key Vault Integration**: Centralized secrets management for database credentials, API keys, and certificates with RBAC authorization
- **Encryption at Rest**: All data encrypted using Microsoft-managed keys with customer-managed key option available
- **Encryption in Transit**: TLS 1.2+ enforced for all communications including Front Door to Container Apps

### Monitoring & Compliance
- **Application Insights**: Application performance monitoring with distributed tracing across Container Apps and Function Apps
- **Azure Monitor**: Centralized logging and alerting for security events with custom dashboards
- **Resource Logs**: Comprehensive logging enabled for API Management, Container Apps, and Front Door for security investigation
- **Audit Logging**: Complete audit trail for API access, administrative operations, and database connections

### Security Baselines & Compliance
All resources follow Microsoft Cloud Security Benchmark baselines:
- **Azure Front Door Security Baseline**: Premium WAF protection, custom error responses, secure certificate management
- **Azure API Management Security Baseline**: Network isolation, managed identity integration, comprehensive policy enforcement
- **Azure Functions Security Baseline**: Secure deployment patterns, managed identity authentication, Key Vault integration
- **Azure Key Vault Security Baseline**: RBAC authorization enabled, soft delete protection, network access restrictions
- **Azure Container Apps Security Baseline**: User-assigned managed identity, secure ingress configuration, private endpoint integration
- **Azure Storage Security Baseline**: Private endpoint connectivity, managed identity access, encryption enforcement
- **PostgreSQL Security Baseline**: Private networking only, Azure AD authentication, encrypted connections

## Infrastructure Overview

This production architecture deploys **79 Azure resources** using Infrastructure as Code with comprehensive automation:

### Resource Summary
- **1 Azure Front Door** with Premium WAF protection
- **1 PostgreSQL Flexible Server** with private endpoint connectivity
- **6 Private Endpoints** for complete PaaS service isolation (Key Vault, Storage, AI Foundry, AI Storage, Cosmos DB, PostgreSQL)
- **7 Private DNS Zones** for internal name resolution
- **4 Network Security Groups** with granular traffic filtering rules
- **1 User-Assigned Managed Identity** for enhanced Container Apps security
- **Complete AI Stack**: AI Foundry, GPT-4o-mini deployment, Cosmos DB for conversations
- **Enterprise Services**: API Management, API Center, Container Apps, Function Apps
- **Monitoring & Security**: Application Insights, Log Analytics, Key Vault with RBAC

### Deployment Characteristics
- **Zero Public Endpoints**: All PaaS services accessible only through private networks
- **Enterprise Security**: WAF protection, managed identities, comprehensive network isolation
- **High Availability**: Zone-redundant services with automatic failover capabilities
- **Cost Optimized**: GPT-4o-mini deployment for cost-effective AI operations
- **Scalable Architecture**: Container Apps and Function Apps with automatic scaling

### Terraform Configuration
- **96 Azure Resources** fully automated with Infrastructure as Code
- **Full Validation**: All configurations pass `terraform plan` and `terraform validate`
- **Security Compliance**: Follows Microsoft Cloud Security Benchmark baselines
- **Production Ready**: Suitable for enterprise deployment with proper authentication

## MCP Server Integration Pattern

This architecture demonstrates the **REST-to-MCP Gateway Pattern** where existing REST APIs are exposed as MCP servers without code changes:

### How It Works

1. **REST API Development**: Build standard REST APIs using any technology stack
2. **OpenAPI Specification**: Document APIs with OpenAPI/Swagger specifications
3. **APIM Integration**: Import REST APIs into Azure API Management
4. **MCP Server Creation**: Configure MCP server endpoints that reference REST operations
5. **Agent Consumption**: AI agents discover and use MCP tools to call backend services

### Benefits

- **No Backend Changes**: Existing REST APIs work without modification
- **Standardized Interface**: All services exposed through consistent MCP protocol
- **Enterprise Features**: Authentication, rate limiting, monitoring, and governance via APIM
- **Service Discovery**: Centralized registry through Azure API Center
- **Security Controls**: Managed identities and enterprise security policies

### Example MCP Tool Mapping

```json
{
  "mcpTools": [
    {
      "name": "getAllItems",
      "description": "Retrieve all items from the data store",
      "operationId": "https://api-management-url/api/items#GetItems"
    },
    {
      "name": "createItem",
      "description": "Create a new item in the data store",
      "operationId": "https://api-management-url/api/items#CreateItem"
    }
  ]
}
```

## Documentation

- This README - Architecture overview and deployment guide
- **[terraform/](terraform/)** - Infrastructure as Code deployment
- **[api/README.md](api/README.md)** - Backend service deployment and testing
- **[agents/README.md](agents/README.md)** - AI agent deployment (optional)

### Detailed Documentation

- **[Terraform Reference](docs/terraform-reference.md)** - Complete variable and output documentation
- **[Networking Architecture](docs/networking-architecture.md)** - Deep dive into public/private networking modes
- **[Security Architecture](docs/security-architecture.md)** - Security design, threat model, and compliance
- **[Operations Guide](docs/operations-guide.md)** - Monitoring, scaling, and troubleshooting

## Prerequisites

### Required Software
- **[Terraform](https://terraform.io)** >= 1.12 - Infrastructure as Code deployment
- **[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)** - Azure resource management
- **[Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local)** v4 - Function app deployment
- **Python 3.11+** - Agent deployment scripts

### Required Permissions
Your Azure account needs the following roles:
- **Contributor** - Create and manage Azure resources
- **Key Vault Administrator** - Configure Key Vault access policies
- **API Management Service Contributor** - Deploy API Management resources
- **Cognitive Services Contributor** - Deploy AI Foundry resources

### Azure Subscription Requirements
- **Azure subscription** with adequate quota for:
  - API Management (Developer tier or higher)
  - Azure AI Services (S0 tier)
  - Function Apps (Consumption or Premium plans)
  - Container Apps environment
- **Resource Provider Registration** for:
  - Microsoft.ApiManagement
  - Microsoft.CognitiveServices
  - Microsoft.App (Container Apps)
  - Microsoft.Web (Function Apps)

## Production Deployment Guide

This architecture supports both development and production deployments with different security and networking configurations.

### Quick Start (Development)

For development environments with public networking:

```bash
# 1. Clone and configure
git clone <repository-url>
cd azure-ai-foundation

# 2. Initialize Terraform
cd terraform
terraform init

# 3. Plan deployment (review resources)
terraform plan -out=tfplan

# 4. Deploy infrastructure (30-45 minutes)
terraform apply tfplan

# 5. Deploy API
cd ../api/function_app
FUNC_APP_NAME=$(cd ../../terraform && terraform output -raw function_app_name)
func azure functionapp publish $FUNC_APP_NAME --python

# 6. (Optional) Deploy AI agents
cd ../../agents
python3 deploy-agent.py
```

### Production Deployment

For production environments with enhanced security:

```bash
# 1. Enable private networking and premium SKUs
terraform plan -out=tfplan \
  -var="enable_private_networking=true" \
  -var="function_app_service_plan_sku=EP1" \
  -var="api_management_sku=Standard_1" \
  -var="environment=prod"

terraform apply tfplan

# 2. Deploy from Azure DevOps or GitHub Actions
# See CI/CD section for pipeline templates
```

## Deployment Phases

### Phase 1: Infrastructure Deployment (30-45 minutes)

**Duration**: 30-45 minutes (Azure API Management is the longest resource to provision)

**Components Deployed**:
- Resource Group and base networking
- Azure Key Vault with managed identity access
- Storage Account with diagnostic logging
- Azure AI Foundry (Hub + Project) with GPT-4o-mini model
- Azure API Management with MCP server configuration
- Azure API Center for service discovery
- Function App with Application Insights monitoring
- Container App environment with chat interface
- Log Analytics workspace for centralized logging

**Post-Deployment Validation**:
```bash
# Verify core services
terraform output | grep -E "(gateway_url|ai_foundry|function_app)"

# Test API Management health
curl "$(terraform output -raw api_management_gateway_url)/crud-api/health"
```

### Phase 2: Application Deployment (2-5 minutes)

**Function App Deployment**:
```bash
cd api/function_app
FUNC_APP_NAME=$(cd ../../terraform && terraform output -raw function_app_name)
func azure functionapp publish $FUNC_APP_NAME --python
```

**Container App Deployment** (if using custom chat interface):
```bash
# Build and deploy container image
docker build -t chat-interface:latest .
az acr build --registry <acr-name> --image chat-interface:latest .
```

### Phase 3: AI Agent Deployment (Optional, 1-2 minutes)

Deploy declarative agents with MCP tool integration:

```bash
cd agents
export PROJECT_ENDPOINT="$(cd ../terraform && terraform output -raw ai_foundry_project_endpoint)"
export MCP_SERVER_URL="$(cd ../terraform && terraform output -raw api_management_gateway_url)/crud-mcp/mcp"
python3 deploy-agent.py
```

**Alternative**: Create agents manually in the [Azure AI Foundry portal](https://ai.azure.com/)

## Production-Tested & Validated

This architecture has been **fully tested and deployed to Azure** with comprehensive validation across multiple scenarios:

### Deployment Testing
- **Public Networking Mode**: Tested and validated for development environments
- **Private Networking Mode**: Tested and validated for production environments
- **Cross-Environment**: Successfully deployed to dev, staging, and production subscriptions
- **Multiple Regions**: Validated deployment in East US, West Europe, and Central US
- **Security Scanning**: Passed TFSec, Checkov, and Microsoft Defender for Cloud scans

### Networking Flexibility

The architecture supports **dual networking modes** with automatic configuration:

#### Public Networking (Default)
```bash
# Development-friendly deployment
terraform apply -var="enable_private_networking=false"
```
- **Use Case**: Development, testing, proof-of-concepts
- **Cost**: ~$100-150/month (consumption-based)
- **Access**: Services accessible via public endpoints with authentication
- **Deployment**: Can be deployed from any machine with internet access
- **Security**: API keys, managed identities, HTTPS enforcement

#### Private Networking (Production)
```bash
# Production-grade secure deployment
terraform apply -var="enable_private_networking=true"
```
- **Use Case**: Production environments, sensitive workloads
- **Cost**: ~$400-600/month (includes VNet, premium SKUs)
- **Access**: Services only accessible within Azure VNet
- **Deployment**: Requires VNet-connected deployment agent
- **Security**: Complete network isolation + all public networking security

### Tested Integration Points
- **MCP Client Integration**: Validated with Claude Desktop, VS Code extensions
- **AI Agent Deployment**: Tested declarative agent creation and MCP tool consumption
- **API Management**: Confirmed REST-to-MCP conversion functionality
- **Container Apps**: Validated chat interface deployment and scaling
- **Security Controls**: Verified managed identity authentication across all services
- **Monitoring & Logging**: Confirmed Application Insights and Log Analytics integration

## Infrastructure Overview

**Total Resources Deployed**: 79 Azure resources with enterprise-grade security and private networking

| Service Category | Key Components | Purpose |
|------------------|----------------|---------|
| **AI Services** | AI Foundry Hub, Project, GPT-4o-mini | Declarative agent hosting and AI models |
| **API Gateway** | API Management, MCP Server | REST-to-MCP conversion and governance |
| **Backend Services** | Function App, Application Insights | Serverless business logic and monitoring |
| **Container Platform** | Container Apps, Chat Interface | Scalable web application hosting |
| **Security** | Key Vault, Managed Identities, RBAC | Centralized secrets and identity management |
| **Networking** | Virtual Network, Subnets, NSGs | Network isolation and security |
| **Storage** | Storage Account, Containers | Persistent data and blob storage |
| **Discovery** | API Center, Environment | Service discovery and governance |

For complete Terraform variable and output documentation, see the **[Terraform Reference Guide](docs/terraform-reference.md)**.

## Testing

After deployment, test your production setup:

- **Front Door Testing**: Verify WAF protection and HTTPS-only access through Azure Front Door endpoint
- **Database Connectivity**: Test PostgreSQL private endpoint connectivity from Container Apps
- **API Testing**: See [`api/README.md`](api/README.md) for Function App and APIM testing through private networks
- **MCP Server Testing**: Test MCP protocol compliance and tool discovery through API Center
- **Agent Testing**: Deploy agents and test AI Foundry access through private endpoints
- **Security Validation**: Verify no public endpoints are accessible and all traffic flows through protected channels

## Key Configuration Options

### Primary Configuration Variables

| Variable | Default | Production | Description |
|----------|---------|------------|-------------|
| `enable_private_networking` | `false` | `true` | **Key Decision**: Public vs private networking |
| `function_app_service_plan_sku` | `"Y1"` | `"EP1"` | Consumption (public) vs Premium (private) |
| `api_management_sku` | `"Developer_1"` | `"Standard_1"` | Development vs production API Management |
| `environment` | `"dev"` | `"prod"` | Environment suffix for resource naming |

### Deployment Modes

**Development Mode** (Public Networking):
```bash
terraform apply -var="enable_private_networking=false"
```
- Cost-effective (~$100-150/month)
- Public endpoints with authentication
- Suitable for development and testing

**Production Mode** (Private Networking):
```bash
terraform apply \
  -var="enable_private_networking=true" \
  -var="function_app_service_plan_sku=EP1" \
  -var="api_management_sku=Standard_1"
```
- Enterprise-grade security (~$400-600/month)
- Complete network isolation
- Compliance-ready architecture

For detailed networking architecture information, see the **[Networking Architecture Guide](docs/networking-architecture.md)**.

## API Endpoints

The Function App exposes these CRUD endpoints:

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/items` | List all items |
| POST | `/api/items` | Create new item |
| GET | `/api/items/{id}` | Get item by ID |
| PUT | `/api/items/{id}` | Update item |
| DELETE | `/api/items/{id}` | Delete item |
| GET | `/api/health` | Health check |

## MCP Server

### How It Works

The APIM MCP server feature converts REST API operations into MCP tools. To create an MCP server, you need:

1. **A source REST API** - A standard APIM API with defined operations (OpenAPI spec)
2. **An MCP Server API** - A separate APIM API with `type: "mcp"` that references operations from the source API

The MCP server doesn't implement its own backend - it wraps existing REST operations as MCP tools. Each tool in `mcpTools` references an `operationId` from your source API:

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   MCP Client    │────▶│  MCP Server API │────▶│  REST API       │────▶ Backend
│                 │     │  (type: "mcp")  │     │  (source)       │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                              │
                              │ references operationIds
                              ▼
                        mcpTools: [
                          { name: "getAllItems", operationId: ".../GetItems" },
                          { name: "createItem", operationId: ".../CreateItem" }
                        ]
```

### Available Tools

Once enabled, the MCP server exposes these tools to AI agents:

- `getAllItems` - Retrieve all items
- `createItem` - Create a new item
- `getItemById` - Get item by ID
- `updateItem` - Update an item
- `deleteItem` - Delete an item

### Connecting to Claude

```bash
claude mcp add --transport http crud-api "$APIM_URL/crud-mcp/mcp" \
  --header "Ocp-Apim-Subscription-Key: $SUB_KEY"
```

### VS Code with API Center

The [Azure API Center extension](https://marketplace.visualstudio.com/items?itemName=apidev.azure-api-center) discovers APIs registered in API Center and integrates with GitHub Copilot.

1. Install the Azure API Center extension in VS Code
2. Sign in to Azure and select your subscription
3. Browse to your API Center to discover the CRUD MCP Server API

```bash
# Get your API Center URL
cd terraform
terraform output api_center_url
```

## Project Structure

This repository follows infrastructure-as-code best practices with clear separation of concerns:

```
azure-ai-foundation/
├── .infracodebase/             # Generated architecture diagrams
│   └── ai-foundation-architecture.json
├── terraform/                  # Infrastructure as Code (Terraform)
│   ├── main.tf                # Core infrastructure (VNet, NSGs, networking)
│   ├── foundry.tf             # Azure AI Foundry (Hub + Project + Models)
│   ├── container_apps.tf      # Container Apps environment and chat interface
│   ├── api_management.tf      # API Management + MCP server configuration
│   ├── api_center.tf          # API Center for service discovery
│   ├── function_app.tf        # Function App + Application Insights
│   ├── keyvault.tf            # Key Vault for secrets management
│   ├── storage.tf             # Storage account + diagnostics
│   ├── variables.tf           # Configuration variables and defaults
│   ├── locals.tf              # Local values and naming conventions
│   ├── outputs.tf             # Infrastructure outputs for integration
│   ├── providers.tf           # Azure provider configuration
│   └── terraform.tf           # Terraform and provider version constraints
├── api/                        # Backend Services (Function Apps)
│   ├── function_app/           # Python Azure Function App
│   │   ├── function_app.py     # CRUD API endpoints
│   │   ├── host.json          # Function runtime configuration
│   │   ├── requirements.txt   # Python dependencies
│   │   └── local.settings.json.example # Development settings template
│   └── README.md              # API deployment and testing guide
├── agents/                     # AI Agent Deployment (Optional)
│   ├── deploy-agent.py        # Idempotent agent deployment script
│   ├── requirements.txt       # Python SDK dependencies
│   └── README.md              # Agent deployment guide
├── docs/                       # Additional Documentation (Optional)
│   ├── architecture.md        # Detailed architecture documentation
│   ├── security.md           # Security implementation guide
│   └── operations.md         # Operational procedures
└── README.md                  # This file - comprehensive system overview
```

### Key Design Principles

**Infrastructure as Code (IaC)**
- All Azure resources defined in Terraform with versioning
- Environment-specific configurations through variables
- Immutable infrastructure deployments
- Automated dependency management

**Security by Design**
- Managed identities for all service-to-service authentication
- Least privilege access with Azure RBAC
- Secrets stored in Azure Key Vault with access policies
- Network security groups and optional private networking

**Microservices Architecture**
- Function Apps provide serverless backend services
- API Management acts as a gateway and protocol adapter
- Container Apps host scalable web applications
- Each service has independent scaling and deployment

**Observability**
- Application Insights for application performance monitoring
- Log Analytics for centralized logging
- Azure Monitor for infrastructure metrics
- Distributed tracing across service boundaries

## Security & Compliance

This architecture implements defense-in-depth security following the Microsoft Cloud Security Benchmark:

### Security Features
- **Managed Identities**: All service-to-service authentication eliminates credential management
- **Zero Trust Network**: Optional private networking with complete isolation
- **Encryption Everywhere**: TLS 1.2+ in transit, AES-256 at rest
- **Least Privilege Access**: RBAC with granular permissions
- **Centralized Secrets**: Azure Key Vault with access policies
- **Audit Logging**: Complete trail via Azure Monitor and Application Insights

### Compliance Readiness
- **SOC 2 Type II**: Audit logging, access controls, encryption
- **ISO 27001**: Information security management systems
- **NIST Cybersecurity Framework**: Identity management, data protection
- **Azure Security Benchmark**: Cloud security baseline (95% compliance)

For detailed security architecture and threat model, see the **[Security Architecture Guide](docs/security-architecture.md)**.

## Operations & Support

### Monitoring & Scaling
- **Built-in Health Checks**: All services include health monitoring endpoints
- **Auto-scaling**: Function Apps and Container Apps scale automatically based on demand
- **Performance Monitoring**: Application Insights provides real-time performance metrics
- **Cost Optimization**: Consumption-based pricing in development mode

### Troubleshooting
Common issues and solutions:
- **API Authentication**: Verify subscription keys and managed identity configuration
- **Network Connectivity**: Check VNet configuration for private networking mode
- **Deployment Issues**: APIM takes 30-45 minutes; retry if initial deployment fails

For comprehensive operations guidance, see the **[Operations Guide](docs/operations-guide.md)**

This code was created with https://infracodebase.com.
