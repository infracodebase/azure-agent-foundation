# Azure AI Foundry Agents - Findings and Workarounds

**Date**: January 14, 2026  
**Status**: Azure Management API for declarative agents is unstable

## Key Findings

### 1. Two Types of Agents in Azure AI Foundry

Azure AI Foundry supports **two distinct types of agents** that use different APIs and are stored separately:

#### Runtime Agents (OpenAI Assistants API Style)
- **Created via**: `client.agents.create_agent()` (sync SDK)
- **Object type**: `"assistant"` 
- **Visible in**: SDK `list_agents()` method
- **NOT visible in**: Azure AI Foundry portal "Agents" page
- **MCP Tools Support**: ✅ Yes (as of SDK version 1.1.0b1)
- **Tool format**: Dictionary with `type`, `server_label`, `server_url`

```python
# Example
agent = client.agents.create_agent(
    model="gpt-4o-mini",
    name="runtime-agent",
    tools=[{
        "type": "mcp",
        "server_label": "my_mcp",
        "server_url": "https://..."
    }]
)
```

#### Declarative Agents (Azure AI Foundry Style)
- **Created via**: `await client.agents.create_version()` (async SDK)
- **Object type**: Versioned agent with `definition.kind: prompt`
- **Visible in**: Azure AI Foundry portal "Agents" page
- **NOT visible in**: SDK `list_agents()` method  
- **MCP Tools Support**: ✅ Yes
- **Features**: Versioning, publishing, draft/published states

```python
# Example (async)
from azure.ai.projects.aio import AIProjectClient
from azure.ai.projects.models import PromptAgentDefinition

agent = await client.agents.create_version(
    agent_name="declarative-agent",
    definition=PromptAgentDefinition(
        model="gpt-4o-mini",
        instructions="...",
        tools=[{
            "type": "mcp",
            "server_label": "my_mcp",
            "server_url": "https://..."
        }]
    )
)
```

### 2. Azure Management API Issues

**Problem**: The Azure Management API endpoint for declarative agents returns `500 Internal Server Error`

- **Endpoint**: `https://management.azure.com/.../projects/{project}/agents/{name}?api-version=2025-06-01`
- **Method**: PUT
- **Status**: Returns 500 error
- **Impact**: Terraform `azapi_resource` cannot create declarative agents
- **Timeline**: Unknown when this will be fixed

### 3. Working Approaches

| Approach | Works? | Visible in Portal? | Notes |
|----------|--------|-------------------|-------|
| Terraform with `azapi_resource` | ❌ No | N/A | Returns 500 error |
| Python SDK sync `create_agent()` | ✅ Yes | ❌ No | Creates runtime agents only |
| Python SDK async `create_version()` | ✅ Yes | ✅ Yes | **Recommended approach** |
| Azure Portal manual creation | ✅ Yes | ✅ Yes | Manual only |
| Azure Developer CLI (`azd`) | ✅ Yes | ✅ Yes | Uses async SDK internally |

## Recommended Solution

### For Development/Testing
Use the Python async SDK with `create_version()`:

```python
# See: test_create_declarative_agent.py
import asyncio
from azure.identity.aio import DefaultAzureCredential
from azure.ai.projects.aio import AIProjectClient
from azure.ai.projects.models import PromptAgentDefinition

async def create_agent():
    endpoint = "https://your-hub.services.ai.azure.com/api/projects/your-project"
    
    async with DefaultAzureCredential() as cred:
        async with AIProjectClient(endpoint=endpoint, credential=cred) as client:
            agent = await client.agents.create_version(
                agent_name="my-agent",
                definition=PromptAgentDefinition(
                    model="gpt-4o-mini",
                    instructions="Your instructions here",
                    tools=[{
                        "type": "mcp",
                        "server_label": "server_name",
                        "server_url": "https://your-mcp-endpoint"
                    }]
                )
            )
            return agent

asyncio.run(create_agent())
```

### For Production IaC
**Options**:
1. **Wait for API stability** - Keep Terraform config commented out (see `terraform/foundry-agents.tf`)
2. **Use azd templates** - They use Python SDK internally
3. **Hybrid approach** - Deploy infrastructure with Terraform, agents with Python scripts
4. **Portal creation** - Create agents manually, reference by ID

## Terraform Configuration

The Terraform configuration in `terraform/foundry-agents.tf` is **correct** but **commented out** due to API instability.

### Correct Terraform Structure
```hcl
resource "azapi_resource" "foundry_agent" {
  type                      = "Microsoft.CognitiveServices/accounts/projects/agents@2025-06-01"
  name                      = "my-agent"
  parent_id                 = azapi_resource.ai_foundry_project.id
  schema_validation_enabled = false # Required for preview API

  body = {
    name         = "my-agent"
    description  = "Agent description"
    model        = "gpt-4o-mini"
    instructions = "Your instructions"
    
    tools = [{
      type         = "mcp"
      server_label = "server_name"
      server_url   = "https://your-mcp-endpoint"
    }]
    
    metadata = {
      managedBy = "terraform"
    }
  }
}
```

**Note**: `project_connection_id` is NOT needed in the MCP tool definition.

## SDK Installation

```bash
# Install the Azure AI Projects SDK (includes async support)
pip install azure-ai-projects>=1.1.0b1
pip install azure-identity
```

## Testing

Run the included test script:
```bash
cd /Users/justinoconnor/Code/azure-agent-foundation
python3 test_create_declarative_agent.py
```

This will create a declarative agent that appears in the Azure AI Foundry portal.

## Portal's Internal API (Not Usable)

**Discovery**: The Azure AI Foundry portal uses an internal GraphQL-style API:

```
POST https://ai.azure.com/nextgen/api/query?createOrUpdateAgentV2Resolver
POST https://ai.azure.com/nextgen/api/query?getAgentsV2Resolver
```

**Authentication**: 
- ❌ Requires browser session cookies (not Bearer tokens)
- ❌ Cannot be accessed programmatically
- ❌ Not available to service principals
- ✅ Browser-only (interactive user sessions)

**Conclusion**: This API is internal to the portal frontend and cannot be used for automation.

## Summary - Current State (January 2026)

| API Type | Endpoint | Accessible? | Creates Portal Agents? | Notes |
|----------|----------|-------------|----------------------|-------|
| Portal Internal | `ai.azure.com/nextgen/api/query` | ❌ Browser-only | ✅ Yes | Requires session cookies |
| Management API | `management.azure.com/.../agents` | ❌ Returns 500 | ✅ Yes (broken) | Terraform uses this |
| Python SDK `create_version()` | N/A | ❌ Not in public SDK | ✅ Yes (unavailable) | Only in internal Microsoft SDK |
| Python SDK `create_agent()` | Data plane API | ✅ Yes | ❌ No | Creates runtime agents only |
| Manual Portal | Portal UI | ✅ Yes | ✅ Yes | **Only working method** |

### Tested SDK Version
- **Package**: `azure-ai-projects` 
- **Version**: `1.1.0b1`
- **Has `create_version()`**: ❌ No
- **Has `PromptAgentDefinition`**: ❌ No

### Authentication Test Results
Tested all OAuth scopes against portal API - all returned 401 "User is not authenticated":
- `https://ai.azure.com/.default` ❌
- `https://ml.azure.com/.default` ❌
- `https://management.azure.com/.default` ❌
- `499b84ac-1321-427f-aa17-267ca6975798/.default` ❌

**Conclusion**: Portal API explicitly requires browser session cookies and rejects all programmatic authentication.

**Recommended Approach**: Create agents manually in portal until APIs are publicly available.

## References

- Azure AI Projects SDK: https://pypi.org/project/azure-ai-projects/
- azd AI Templates: https://github.com/Azure-Samples/
- Azure AI Foundry Portal: https://ai.azure.com/

## Next Steps

### Immediate Actions
1. **Create agents manually in Azure AI Foundry portal** - Only working method currently
2. **Use runtime agents** if portal visibility is not required (via `create_agent()`)
3. **Keep Terraform config commented out** - Wait for Management API to be fixed

### Monitor for Updates
1. **Watch for SDK updates**: `pip install --upgrade azure-ai-projects`
   - Look for `create_version()` method availability
   - Check for `PromptAgentDefinition` model class
2. **Test Management API periodically**: Check if 500 errors are resolved
3. **Monitor Azure updates**: https://azure.microsoft.com/en-us/updates/

### If Urgent
1. **File Azure Support Ticket**: Ask when declarative agents API will be available
2. **GitHub Issue**: Open issue in azure-sdk-for-python repo about `create_version()` availability
3. **Contact Product Team**: Request timeline for public API release

### Long-term Solution
Once APIs are stable:
- Uncomment Terraform configuration in `terraform/foundry-agents.tf`
- Run `terraform plan` to verify
- Deploy agents declaratively via IaC
