# Azure AI Foundation

Infrastructure and API for exposing REST APIs as MCP (Model Context Protocol) servers using Azure API Management.

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

## Prerequisites

- [Terraform](https://terraform.io) >= 1.12
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local) v4
- Python 3.11

## Deployment

### 1. Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Review and save the plan
terraform plan -out=tfplan

# Apply the saved plan (takes ~30-45 mins for APIM)
terraform apply tfplan
```

**Note**: Azure API Management takes 30-45 minutes to provision.

### 2. Deploy Function App Code

After infrastructure is deployed:

```bash
cd api/function_app

# Get your function app name from Terraform output
FUNC_APP_NAME=$(cd ../../terraform && terraform output -raw function_app_name)

# Deploy the code
func azure functionapp publish $FUNC_APP_NAME --python
```

### 3. Enable MCP Server Feature (Portal)

The MCP server feature requires manual enablement:

1. Go to Azure Portal → API Management instance
2. Navigate to **Deployment + Infrastructure** → **Service update settings**
3. Change **Update group** to **"AI Gateway Early (GenAI release channel)"**
4. Wait ~2 hours for propagation

Or access directly with feature flag:
```
https://portal.azure.com/?Microsoft_Azure_ApiManagement=mcp
```

### 4. Test Your Deployment

After deployment, test at each layer to verify everything is working.

#### Get Credentials

```bash
cd terraform

# Function App name and key
FUNC_APP_NAME=$(terraform output -raw function_app_name)
FUNC_KEY=$(az functionapp keys list --name $FUNC_APP_NAME --resource-group ai-foundation-dev-rg --query 'functionKeys.default' -o tsv)

# APIM URL and subscription key
APIM_URL=$(terraform output -raw api_management_gateway_url)
SUB_KEY=$(terraform output -raw api_subscription_key)
```

#### Test Function App Directly

```bash
# Health check
curl "https://$FUNC_APP_NAME.azurewebsites.net/api/health?code=$FUNC_KEY"

# List items
curl "https://$FUNC_APP_NAME.azurewebsites.net/api/items?code=$FUNC_KEY"

# Create item
curl -X POST "https://$FUNC_APP_NAME.azurewebsites.net/api/items?code=$FUNC_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Item","description":"Direct Function App call"}'
```

#### Test APIM REST API

```bash
# List items through APIM
curl "$APIM_URL/api/items" -H "Ocp-Apim-Subscription-Key: $SUB_KEY"

# Create item through APIM
curl -X POST "$APIM_URL/api/items" \
  -H "Content-Type: application/json" \
  -H "Ocp-Apim-Subscription-Key: $SUB_KEY" \
  -d '{"name":"APIM Item","description":"Created through APIM REST"}'
```

#### Test MCP Server

The MCP server uses JSON-RPC over HTTP with Server-Sent Events (SSE):

```bash
# Initialize MCP session
curl -X POST "$APIM_URL/crud-mcp/mcp" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}},"id":1}'

# List available tools
curl -X POST "$APIM_URL/crud-mcp/mcp" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":2}'

# Call getAllItems tool
curl -X POST "$APIM_URL/crud-mcp/mcp" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"getAllItems","arguments":{}},"id":3}'

# Call createItem tool
curl -X POST "$APIM_URL/crud-mcp/mcp" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"createItem","arguments":{"ItemsPostRequest":{"name":"MCP Item","description":"Created via MCP"}}},"id":4}'
```

**Note**: MCP responses use SSE format with `event:` and `data:` lines. The curl commands may timeout waiting for the stream to close - this is expected.

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

### Connecting Claude Desktop

Add to your Claude Desktop config (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "crud-api": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://<apim-name>.azure-api.net/crud-mcp/mcp"],
      "env": {
        "API_KEY": "<your-subscription-key>"
      }
    }
  }
}
```

## Project Structure

```
.
├── api/
│   └── function_app/       # Python Azure Function App
│       ├── function_app.py # CRUD endpoints
│       ├── host.json
│       └── requirements.txt
├── terraform/              # Infrastructure as Code
│   ├── main.tf            # VNet, subnets, NSG
│   ├── api_management.tf  # APIM + MCP server
│   ├── api_center.tf      # API Center for discovery
│   ├── function_app.tf    # Function App + App Insights
│   ├── keyvault.tf        # Key Vault for secrets
│   ├── storage.tf         # Storage account
│   └── variables.tf       # Configuration variables
└── README.md
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
- Ensure "AI Gateway Early" update group is enabled
- Wait up to 2 hours after enabling
- Try portal URL with `?Microsoft_Azure_ApiManagement=mcp` flag

### Terraform errors during apply
- APIM takes 30-45 mins to deploy - be patient
- Some resources may fail on first apply if dependencies aren't ready - run `terraform apply` again
