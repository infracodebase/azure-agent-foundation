# Function App Deployment

This folder contains the Azure Function App that provides the CRUD API backend for the MCP server.

## Prerequisites

1. **Infrastructure deployed** via Terraform
2. **Azure Functions Core Tools** v4 installed:
   ```bash
   # macOS
   brew install azure-functions-core-tools@4
   
   # Windows
   npm install -g azure-functions-core-tools@4 --unsafe-perm true
   ```
3. **Python 3.11** installed

## Quick Start

### 1. Get Function App Name from Terraform

```bash
cd ../terraform
FUNC_APP_NAME=$(terraform output -raw function_app_name)
echo "Function App: $FUNC_APP_NAME"
```

### 2. Deploy the Function App

```bash
cd ../api/function_app
func azure functionapp publish $FUNC_APP_NAME --python
```

The deployment takes 1-2 minutes.

### 3. Verify Deployment

```bash
# Get function app details
cd ../../terraform
FUNC_APP_NAME=$(terraform output -raw function_app_name)
RG_NAME=$(terraform output -raw resource_group_name)

# Get the function key
FUNC_KEY=$(az functionapp keys list \
  --name $FUNC_APP_NAME \
  --resource-group $RG_NAME \
  --query 'functionKeys.default' -o tsv)

# Test health endpoint
curl "https://${FUNC_APP_NAME}.azurewebsites.net/api/health?code=${FUNC_KEY}"
```

Expected response:
```json
{"status": "healthy", "message": "API is running"}
```

## Testing the API

### Test CRUD Operations

```bash
# List items (should be empty initially)
curl "https://${FUNC_APP_NAME}.azurewebsites.net/api/items?code=${FUNC_KEY}"

# Create an item
curl -X POST "https://${FUNC_APP_NAME}.azurewebsites.net/api/items?code=${FUNC_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Item","description":"Created via API"}'

# List items again (should show the new item)
curl "https://${FUNC_APP_NAME}.azurewebsites.net/api/items?code=${FUNC_KEY}"
```

### Test via API Management

Once deployed, the function app is accessible through APIM:

```bash
cd ../terraform
APIM_URL=$(terraform output -raw api_management_gateway_url)
SUB_KEY=$(terraform output -raw api_subscription_key)

# List items through APIM
curl "$APIM_URL/api/items" -H "Ocp-Apim-Subscription-Key: $SUB_KEY"

# Create item through APIM
curl -X POST "$APIM_URL/api/items" \
  -H "Content-Type: application/json" \
  -H "Ocp-Apim-Subscription-Key: $SUB_KEY" \
  -d '{"name":"APIM Item","description":"Created through APIM"}'
```

## Available Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/items` | List all items |
| POST | `/api/items` | Create new item |
| GET | `/api/items/{id}` | Get item by ID |
| PUT | `/api/items/{id}` | Update item |
| DELETE | `/api/items/{id}` | Delete item |
| GET | `/api/health` | Health check |

## Local Development

To run the function app locally for testing:

```bash
cd function_app

# Install dependencies
pip install -r requirements.txt

# Start local function runtime
func start
```

The API will be available at `http://localhost:7071/api/`

## Troubleshooting

### Deployment Fails

```bash
# Check function app status
az functionapp show \
  --name $FUNC_APP_NAME \
  --resource-group $RG_NAME \
  --query state -o tsv

# View logs
az functionapp log tail \
  --name $FUNC_APP_NAME \
  --resource-group $RG_NAME
```

### Function Returns 401 Unauthorized

Make sure you include the function key:
```bash
?code=$FUNC_KEY
```

Or access via APIM with the subscription key.

### Function Not Responding

Wait 1-2 minutes after deployment for the function app to fully start up.

## CI/CD Integration

```yaml
# Example GitHub Actions
- name: Deploy Function App
  run: |
    cd api/function_app
    FUNC_APP_NAME=$(cd ../../terraform && terraform output -raw function_app_name)
    func azure functionapp publish $FUNC_APP_NAME --python
```

## What's Next?

After deploying the API:

1. **Test the MCP server** - See main README for MCP testing
2. **(Optional) Deploy agents** - See [`../agents/README.md`](../agents/README.md)
3. **Connect to Claude** - Use the MCP server endpoint with Claude

## API Details

The function app implements a simple in-memory CRUD API for demonstration purposes. In production, you would:

- Connect to a database (Azure SQL, Cosmos DB, etc.)
- Add authentication/authorization
- Implement proper error handling
- Add logging and monitoring
- Use Application Insights for telemetry

See `function_app.py` for the implementation.
