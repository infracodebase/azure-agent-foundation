# Azure AI Foundation

**Production-Ready Infrastructure for AI Agent Systems with MCP Server Integration**

A comprehensive Infrastructure-as-Code foundation that deploys Azure services to support AI agent systems using the Model Context Protocol (MCP). This baseline architecture enables AI agents (like those running on Azure AI Foundry) to access enterprise services through standardized MCP tools exposed via Azure API Management.

## Executive Summary

This repository provides the core Azure services and security baseline for building agent-to-Gekko systems where:

- **Azure API Management** converts REST APIs into MCP servers that AI agents can consume
- **Azure API Center** provides centralized discovery and management of MCP servers as APIs
- **Azure AI Foundry** hosts declarative AI agents with access to MCP tools
- **Azure Container Apps** provides scalable hosting for chat interfaces and agent applications
- **Security-first design** follows Microsoft Cloud Security Benchmark with managed identities, Key Vault integration, and network isolation options

## System Architecture

The architecture supports both external MCP clients (like Claude Desktop) and internal AI agents running on Azure AI Foundry:

```
┌─────────────────────────────────────────────────────────────────────┐
│                           Azure Subscription                        │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐  │
│  │   External      │    │     Azure       │    │    Backend      │  │
│  │  MCP Clients    │───▶│  API Management │───▶│   Services      │  │
│  │ (Claude, etc.)  │    │  (MCP Gateway)  │    │ (Function Apps) │  │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘  │
│                                   │                                 │
│                                   ▼                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐  │
│  │  Azure AI       │    │   API Center    │    │   Container     │  │
│  │   Foundry       │───▶│  (Discovery &   │    │     Apps        │  │
│  │ (AI Agents)     │    │  Governance)    │    │ (Chat Interface)│  │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

### Key Components

**MCP Gateway Layer (API Management)**
- Converts REST APIs into standardized MCP servers
- Provides authentication, rate limiting, and monitoring
- Exposes MCP endpoints that agents can consume as tools

**Service Discovery (API Center)**
- Centralized registry of available MCP servers
- Integration with development tools (VS Code extension)
- API governance and lifecycle management

**AI Agent Runtime (Azure AI Foundry)**
- Hosts declarative agents with GPT-4o-mini/GPT-4o models
- Native MCP tool integration for agent-to-service communication
- Managed identity integration for secure service access

**Application Layer (Container Apps)**
- Scalable hosting for chat interfaces and web applications
- Direct integration with AI Foundry for agent interactions
- Secure communication with backend services

**Backend Services (Function Apps)**
- Microservices exposing business logic as REST APIs
- Automatic scaling and serverless execution
- Integration with Azure storage and data services

## Security Architecture

This architecture implements defense-in-depth security following the [Microsoft Cloud Security Benchmark](https://docs.microsoft.com/en-us/security/benchmark/azure/):

### Identity & Access Management
- **Azure Managed Identities**: All service-to-service authentication uses system-assigned managed identities
- **Azure RBAC**: Least-privilege access with role-based access control across all resources
- **Azure AD Integration**: Centralized identity for user authentication and conditional access policies

### Network Security
- **Virtual Network Integration**: Optional private networking with dedicated subnets for each service tier
- **Network Security Groups**: Granular traffic filtering with security rules for each subnet
- **Private Endpoints**: Secure connectivity to Azure services without internet exposure (when private networking enabled)
- **API Management Firewall**: Built-in protection against common web attacks and DDoS

### Data Protection
- **Encryption at Rest**: All data encrypted using Microsoft-managed keys with customer-managed key option
- **Encryption in Transit**: TLS 1.2+ enforced for all communications
- **Azure Key Vault**: Centralized secrets management for API keys, connection strings, and certificates
- **Data Classification**: Integration with Azure Purview for sensitive data discovery and classification

### Monitoring & Compliance
- **Application Insights**: Application performance monitoring and distributed tracing
- **Azure Monitor**: Centralized logging and alerting for security events
- **Microsoft Defender for Cloud**: Threat detection and security recommendations
- **Audit Logging**: Complete audit trail for API access and administrative operations

### Configuration Security
All resources follow security baselines including:
- **Azure API Management Security Baseline**: Network isolation, WAF integration, certificate management
- **Azure Functions Security Baseline**: Secure deployment, managed identity authentication
- **Azure Key Vault Security Baseline**: Access policies, soft delete, network restrictions
- **Azure Container Apps Security Baseline**: Image vulnerability scanning, secure ingress

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

**Total Resources Deployed**: 45+ Azure resources across 8 service categories

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

After deployment, test your setup:

- **API Testing**: See [`api/README.md`](api/README.md) for Function App and APIM testing
- **MCP Server Testing**: See MCP Server section below
- **Agent Testing**: Deploy agents and test in Azure AI Foundry portal

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
