# Azure AI Foundry Agent with MCP Server Integration
# This demonstrates using the azapi provider to create a declarative agent
# that uses our GPT-4o-mini model and MCP server as a tool
#
# IMPORTANT: As of January 2026, the Azure Management API for declarative agents
# is unstable and returns 500 Internal Server Errors. The configuration below is
# correct based on the Python SDK structure, but the API is not ready for use.
#
# Working alternative: Use the Python SDK's async create_version() method:
#   from azure.ai.projects.aio import AIProjectClient
#   agent = await client.agents.create_version(agent_name="...", definition=PromptAgentDefinition(...))
#
# See: test_create_declarative_agent.py in the project root
#
# This resource is commented out until the Management API is stable.

# resource "azapi_resource" "foundry_agent" {
#   type                      = "Microsoft.CognitiveServices/accounts/projects/agents@2025-06-01"
#   name                      = "mcp-demo-agent"
#   parent_id                 = azapi_resource.ai_foundry_project.id
#   schema_validation_enabled = false # Required: azapi provider doesn't have schema for this preview API yet
#
#   body = {
#     name        = "mcp-demo-agent"
#     description = "Declarative agent demonstrating Azure AI Foundry integration with MCP server"
#     model       = "gpt-4o-mini" # Model name as string at top level
#     instructions = <<-EOT
#       You are an AI assistant with access to a data management system via MCP tools.
#       
#       You can help users:
#       - Create, read, update, and delete items in the data store
#       - Query and retrieve information about stored items
#       - Manage data operations efficiently
#       
#       When users ask about data management tasks, use the available MCP tools to perform the operations.
#       Always provide clear feedback about what actions you're taking.
#     EOT
#     
#     tools = [
#       {
#         type         = "mcp"
#         server_label = "crud_mcp_server"
#         server_url   = "${azurerm_api_management.this.gateway_url}/crud-mcp/mcp"
#       }
#     ]
#     
#     metadata = {
#       environment       = var.environment
#       managedBy         = "terraform"
#       mcpServerEndpoint = "${azurerm_api_management.this.gateway_url}/crud-mcp/mcp"
#     }
#   }
#
#   tags = local.common_tags
#
#   depends_on = [
#     azurerm_cognitive_deployment.gpt4o_mini,
#     azapi_resource.mcp_server
#   ]
# }
