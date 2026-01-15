# Azure AI Foundry Agents Deployment

This folder contains scripts for deploying AI agents to Azure AI Foundry.

**Note**: Agent deployment is **optional**. The Terraform infrastructure (AI Foundry, models, APIM) can be used without deploying agents through these scripts. Agents can also be created manually in the Azure AI Foundry portal.

## Prerequisites

1. **Infrastructure deployed** via Terraform
2. **Python dependencies** installed:
   ```bash
   pip install -r requirements.txt
   ```

## Quick Start

### 1. Get Configuration from Terraform

From the `terraform/` directory, get the required values:

```bash
cd ../terraform

# Get AI Foundry project endpoint
terraform output ai_foundry_project_endpoint

# Get MCP server endpoint (for agents with MCP tools)
terraform output api_management_gateway_url
```

### 2. Set Environment Variables

```bash
# Required
export PROJECT_ENDPOINT="<value from terraform output ai_foundry_project_endpoint>"

# Optional (has working defaults)
export AGENT_NAME="mcp-demo-agent"
export MODEL_NAME="gpt-4o-mini"
export MCP_SERVER_URL="<value from api_management_gateway_url>/crud-mcp/mcp"
```

### 3. Deploy Agent

```bash
cd agents
python3 deploy-agent.py
```

The script is **idempotent** - run it multiple times safely. It only creates a new version when configuration changes.

## Example: Complete Workflow

```bash
# 1. Deploy infrastructure
cd terraform
terraform apply

# 2. Get the endpoints
PROJECT_ENDPOINT=$(terraform output -raw ai_foundry_project_endpoint)
APIM_URL=$(terraform output -raw api_management_gateway_url)

# 3. Deploy agent
cd ../agents
export PROJECT_ENDPOINT="$PROJECT_ENDPOINT"
export MCP_SERVER_URL="${APIM_URL}/crud-mcp/mcp"
python3 deploy-agent.py
```

## Configuration Options

All configuration is done via environment variables:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PROJECT_ENDPOINT` | Yes | Dev project | AI Foundry project endpoint from Terraform |
| `AGENT_NAME` | No | `mcp-demo-agent` | Name for your agent |
| `MODEL_NAME` | No | `gpt-4o-mini` | Model deployment to use |
| `MCP_SERVER_URL` | No | Dev APIM | MCP server endpoint (from Terraform APIM) |

## Creating Multiple Agents

Deploy different agents by changing the `AGENT_NAME`:

```bash
# Analytics agent
AGENT_NAME="analytics-agent" \
MODEL_NAME="gpt-4o-mini" \
python3 deploy-agent.py

# Customer service agent  
AGENT_NAME="customer-service-agent" \
MODEL_NAME="gpt-4o" \
python3 deploy-agent.py
```

## Idempotent Behavior

The script only creates new versions when configuration changes:

```bash
# First run - creates v1
python3 deploy-agent.py
# ✅ Agent version created! Version: 1

# Second run (no changes) - reuses v1
python3 deploy-agent.py
# ♻️  Result: EXISTING VERSION REUSED (no changes)

# Third run (with changes) - creates v2
MODEL_NAME="gpt-4o" python3 deploy-agent.py
# 🔄 Agent configuration changed - creating new version
# ✅ Agent version created! Version: 2
```

This makes it safe for CI/CD and prevents version clutter.

## Verify in Portal

After deployment, view your agents at:
```
https://ai.azure.com/
```

Navigate to your project → Agents

## Customizing Agent Behavior

To modify the agent's instructions or tools, edit `deploy-agent.py`:

```python
# Around line 130
definition = PromptAgentDefinition(
    model=model_name,
    instructions="""Your custom instructions here...""",
    tools=[mcp_tool],
    temperature=0.7,
    top_p=0.95
)
```

## Troubleshooting

### Missing PROJECT_ENDPOINT

```bash
# Make sure Terraform is applied first
cd ../terraform
terraform output ai_foundry_project_endpoint
```

### Authentication Issues

```bash
# Login to Azure
az login

# Or set credentials
export AZURE_CLIENT_ID="..."
export AZURE_CLIENT_SECRET="..."
export AZURE_TENANT_ID="..."
```

### Agent Not Appearing in Portal

- Wait 30-60 seconds for portal cache
- Refresh browser
- Verify correct project in portal

## CI/CD Integration

```yaml
# Example GitHub Actions
- name: Deploy Infrastructure
  run: |
    cd terraform
    terraform apply -auto-approve

- name: Deploy Agents
  run: |
    cd agents
    export PROJECT_ENDPOINT=$(cd ../terraform && terraform output -raw ai_foundry_project_endpoint)
    export MCP_SERVER_URL=$(cd ../terraform && terraform output -raw api_management_gateway_url)/crud-mcp/mcp
    python3 deploy-agent.py
```

## Alternative: Manual Portal Creation

If you prefer not to use these scripts, agents can be created directly in the Azure AI Foundry portal:

1. Go to https://ai.azure.com/
2. Navigate to your project
3. Click "Agents" → "Create"
4. Configure your agent using the UI

The portal provides the same capabilities with a visual interface.
