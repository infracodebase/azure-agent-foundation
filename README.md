# Azure AI Foundation

Infrastructure-as-Code for Azure AI Foundry with MCP (Model Context Protocol) server integration.

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   MCP Client    │────▶│  Azure APIM     │────▶│  Function App   │
│ (Claude, etc.)  │     │  (MCP Server)   │     │  (CRUD API)     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                              │
                              ▼
                        ┌─────────────────┐
                        │  API Center     │
                        │  (Discovery)    │
                        └─────────────────┘
```

**Optional**: Azure AI Foundry agents can use the MCP server. See [`agents/`](agents/) for deployment scripts.

## Documentation

- This README - Overview and MCP server architecture
- **[terraform/](terraform/)** - Infrastructure deployment (Terraform)
- **[api/README.md](api/README.md)** - Function app deployment and testing
- **[agents/README.md](agents/README.md)** - Optional: AI agent deployment (Python SDK)

## Prerequisites

- [Terraform](https://terraform.io) >= 1.12
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local) v4
- Python 3.11+
- Azure subscription with appropriate permissions

## Deployment Overview

Complete deployment requires three steps:

```
1. Deploy Infrastructure  → Terraform (30-45 mins)
2. Deploy API            → Function App (2 mins) 
3. Deploy Agents         → Optional (1 min)
```

### 1. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

**Note**: Azure API Management takes 30-45 minutes to provision.

### 2. Deploy API (Function App)

Deploy the CRUD API backend:

```bash
cd api/function_app
FUNC_APP_NAME=$(cd ../../terraform && terraform output -raw function_app_name)
func azure functionapp publish $FUNC_APP_NAME --python
```

**See [`api/README.md`](api/README.md) for detailed instructions and testing.**

### 3. (Optional) Deploy AI Agents

Deploy agents using the Python SDK:

```bash
cd agents
python3 deploy-agent.py
```

**See [`agents/README.md`](agents/README.md) for detailed instructions.**

Alternatively, create agents manually in the Azure AI Foundry portal: https://ai.azure.com/

## Testing

After deployment, test your setup:

- **API Testing**: See [`api/README.md`](api/README.md) for Function App and APIM testing
- **MCP Server Testing**: See MCP Server section below
- **Agent Testing**: Deploy agents and test in Azure AI Foundry portal

## Configuration

### Public vs Private Networking

By default, resources are deployed with public networking. To enable private networking (VNet integration):

```bash
terraform apply \
  -var="enable_private_networking=true" \
  -var="function_app_service_plan_sku=EP1"
```

**Note**: Private networking requires:
- EP1 or higher Function App SKU (~$150/month)
- A VNet-connected deployment agent

### Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `enable_private_networking` | `false` | Enable VNet integration and firewalls |
| `function_app_service_plan_sku` | `Y1` | Function App SKU (Y1=Consumption, EP1+=Premium) |
| `api_management_sku` | `Developer_1` | APIM SKU |
| `environment` | `dev` | Environment name |
| `location` | `East US` | Azure region |

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

```
.
├── api/                        # Function App (CRUD API)
│   ├── function_app/           # Python Azure Function App
│   │   ├── function_app.py     # CRUD endpoints
│   │   ├── host.json
│   │   └── requirements.txt
│   └── README.md               # API deployment guide
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                # VNet, subnets, NSG
│   ├── foundry.tf             # Azure AI Foundry (Hub + Project)
│   ├── api_management.tf      # APIM + MCP server
│   ├── api_center.tf          # API Center for discovery
│   ├── function_app.tf        # Function App + App Insights
│   ├── keyvault.tf            # Key Vault for secrets
│   ├── storage.tf             # Storage account
│   └── variables.tf           # Configuration variables
├── agents/                     # Optional: AI agent deployment
│   ├── deploy-agent.py        # Idempotent agent deployment script
│   ├── requirements.txt       # Python dependencies
│   └── README.md              # Agent deployment guide
└── README.md                  # This file
```

## Schema Management

The API schema is defined inline in Terraform (`api_management.tf`). This approach:

- **Pros**: Single source of truth, no chicken-and-egg deployment problem
- **Cons**: Schema is duplicated (Terraform + Function App code must match)

Alternative approaches:
1. Function App exposes `/openapi.json` → APIM imports (requires 2-phase deploy)
2. Shared OpenAPI spec file referenced by both Terraform and Function App

## Troubleshooting

### APIM returns 401 Unauthorized
- Check subscription key is correct
- Verify the API subscription is active in Azure Portal

### Function App returns 401
- Include the function key: `?code=<function-key>`

### MCP Server not visible in Portal
- The MCP server is created via Terraform using preview APIs - it works even if not visible in Portal
- To see MCP servers in Portal UI, try: `https://portal.azure.com/?Microsoft_Azure_ApiManagement=mcp`
- You can verify MCP server exists via CLI: `az rest --method GET --uri "https://management.azure.com{apim-id}/apis?api-version=2025-03-01-preview"`

### Terraform errors during apply
- APIM takes 30-45 mins to deploy - be patient
- Some resources may fail on first apply if dependencies aren't ready - run `terraform apply` again
