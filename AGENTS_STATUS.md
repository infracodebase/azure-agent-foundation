# Azure AI Foundry Agents - Current Status

**Date**: January 14, 2026  
**Conclusion**: Declarative agents **cannot be created programmatically** with current public APIs

---

## What We Tested

### ✅ What Works
- ✅ **Manual portal creation** - Create agents in Azure AI Foundry portal
- ✅ **Runtime agents via SDK** - `create_agent()` creates OpenAI-style agents (don't appear in portal)
- ✅ **Infrastructure** - Terraform successfully deploys Hub, Project, Models, APIM, MCP server

### ❌ What Doesn't Work
- ❌ **Terraform agent creation** - Management API returns `500 Internal Server Error`
- ❌ **Portal API programmatic access** - Requires browser cookies, rejects all Bearer tokens
- ❌ **Python SDK `create_version()`** - Doesn't exist in public SDK (v1.1.0b1)

---

## The Problem

**Three APIs exist, none are accessible:**

1. **Management API** (`https://management.azure.com/.../agents`)
   - This is what Terraform uses
   - Currently returns 500 errors
   - Configuration in `terraform/foundry-agents.tf` is correct but commented out

2. **Portal Internal API** (`https://ai.azure.com/nextgen/api/query`)
   - This is what the portal UI uses
   - Requires browser session cookies
   - Explicitly rejects programmatic authentication
   - Cannot be used for automation

3. **Python SDK `create_version()`**
   - Found in Microsoft's internal azd templates
   - Not available in public SDK releases
   - Only Microsoft developers have access

---

## Current Workaround

**Create agents manually in the portal:**

1. Go to https://ai.azure.com/
2. Navigate to your project: `ai-foundation-dev-project`
3. Click "Agents" → "Create agent"
4. Configure with your MCP server:
   - Model: `gpt-4o-mini`
   - Add MCP tool with URL: `https://ai-foundation-dev-apim-229237e9.azure-api.net/crud-mcp/mcp`

**Then reference the agent in your code** using the agent ID.

---

## Files Updated

- ✅ `terraform/foundry-agents.tf` - Correct configuration (commented out, waiting for API)
- ✅ `terraform/outputs.tf` - Agent outputs (commented out)
- ✅ `AGENTS_FINDINGS.md` - Detailed technical findings
- ✅ `AGENTS_STATUS.md` - This file (quick reference)

---

## When to Retry

Monitor these indicators that the API is ready:

### Check SDK Updates
```bash
pip install --upgrade azure-ai-projects
python3 -c "from azure.ai.projects.aio import AIProjectClient; print(hasattr(AIProjectClient(endpoint='dummy', credential=None).agents, 'create_version'))"
```

If this prints `True`, the SDK is ready.

### Check Management API
```bash
cd terraform
terraform plan -target=azapi_resource.foundry_agent
```

If this completes without errors, the Management API is ready.

### Check for Azure Announcements
- https://azure.microsoft.com/en-us/updates/
- https://github.com/Azure/azure-sdk-for-python/releases

---

## Next Steps

**Short term:**
- Create agents manually in portal
- Use manual agents for your MCP server testing
- Document agent IDs for reference

**Medium term:**
- Check for SDK updates monthly
- File Azure support ticket if needed by Q2 2026
- Consider GitHub issue in azure-sdk-for-python

**Long term:**
- Once APIs are stable, uncomment Terraform config
- Deploy agents declaratively
- Integrate into CI/CD pipeline

---

## What We Learned

1. **Two separate agent systems exist:**
   - Runtime agents (OpenAI Assistants API) - work but don't show in portal
   - Declarative agents (Azure AI Foundry) - show in portal but no public API

2. **The Terraform configuration is correct:**
   - Structure matches the working portal agents
   - MCP tool format is correct
   - Just waiting for Microsoft to fix the API

3. **Microsoft's azd templates use internal SDKs:**
   - They have access to `create_version()` that we don't
   - Public SDK release is behind internal development

---

## Related Microsoft Agent Projects

While researching, we found these Microsoft agent frameworks (note: these are **different** from Azure AI Foundry agents):

### Microsoft Agent Framework
- **Repo**: https://github.com/microsoft/agent-framework
- **Declarative samples**: https://github.com/microsoft/agent-framework/tree/main/python/samples/getting_started/declarative
- **Purpose**: General-purpose agent framework (not Azure AI Foundry specific)
- **Languages**: Python, .NET
- **Status**: This is a **different system** from Azure AI Foundry declarative agents

### Microsoft 365 Agents SDK
- **Repo**: https://github.com/microsoft/agents
- **Purpose**: Build agents for Microsoft 365 Copilot, Teams
- **Status**: Also a **different system** from Azure AI Foundry

### Azure AI Agents Labs
- **Repo**: https://github.com/Azure/azure-ai-agents-labs (mentioned in searches)
- **Purpose**: Hands-on labs for Azure AI Agent Service SDK
- **Status**: Worth exploring but may use different APIs

**Important**: These are separate agent systems. They don't solve the Azure AI Foundry declarative agent API problem.

## Support

If you need this urgently:
1. File Azure support ticket - ask for declarative agents API timeline
2. Reach out to your Microsoft contact/TAM
3. Explore Azure AI Agents Labs to see if it provides an alternative approach
4. Consider temporarily using runtime agents if portal visibility isn't critical

---

**Bottom line:** Your infrastructure is solid, the configuration is correct, but you'll need to create agents manually until Microsoft releases the public Azure AI Foundry declarative agents APIs.
