#!/usr/bin/env python3
"""
Idempotent agent creation/update script

This version checks if the agent exists and only creates a new version
if the configuration has changed.

Requirements:
- azure-ai-projects >= 2.0.0b3
- azure-identity
"""

import asyncio
import os
import json
from typing import Optional
from azure.identity.aio import DefaultAzureCredential
from azure.ai.projects.aio import AIProjectClient
from azure.ai.projects.models import PromptAgentDefinition, MCPTool


def definitions_are_equal(def1: PromptAgentDefinition, def2: dict) -> bool:
    """
    Compare two agent definitions to see if they're effectively the same
    
    Args:
        def1: New definition (PromptAgentDefinition object)
        def2: Existing definition (dict from API)
    
    Returns:
        True if definitions are effectively equal
    """
    # Compare key fields
    if def1.model != def2.get('model'):
        return False
    
    if def1.instructions.strip() != def2.get('instructions', '').strip():
        return False
    
    # Compare tools (simplified - checks MCP tools)
    new_tools = def1.tools or []
    existing_tools = def2.get('tools', [])
    
    if len(new_tools) != len(existing_tools):
        return False
    
    # Check MCP tool URLs match
    for new_tool, existing_tool in zip(new_tools, existing_tools):
        if hasattr(new_tool, 'server_url'):
            if new_tool.server_url != existing_tool.get('server_url'):
                return False
        if hasattr(new_tool, 'server_label'):
            if new_tool.server_label != existing_tool.get('server_label'):
                return False
    
    return True


async def create_or_update_agent(
    endpoint: str,
    agent_name: str,
    definition: PromptAgentDefinition,
    description: str = "",
    metadata: Optional[dict] = None
):
    """
    Create or update an agent - only creates new version if config changed
    
    Args:
        endpoint: AI Foundry project endpoint
        agent_name: Name of the agent
        definition: Agent definition
        description: Agent description
        metadata: Agent metadata
        
    Returns:
        Tuple of (agent_version, was_created: bool)
    """
    async with DefaultAzureCredential() as cred:
        async with AIProjectClient(endpoint=endpoint, credential=cred) as client:
            
            # Check if agent exists by listing versions
            try:
                latest_version = None
                version_count = 0
                
                # List all versions to find the latest
                async for version in client.agents.list_versions(agent_name=agent_name):
                    version_count += 1
                    if latest_version is None or version.version > latest_version.version:
                        latest_version = version
                
                if latest_version:
                    print(f"📋 Agent '{agent_name}' exists (latest version: {latest_version.version})")
                    
                    # Compare definitions
                    existing_def = latest_version.definition
                    
                    # Simple comparison - convert to dict for easier comparison
                    if definitions_are_equal(definition, existing_def):
                        print("✅ Agent configuration unchanged - using existing version")
                        print(f"   Version: {latest_version.version}")
                        print(f"   ID: {latest_version.id}")
                        return latest_version, False
                    else:
                        print("🔄 Agent configuration changed - creating new version")
                else:
                    print(f"📝 Agent '{agent_name}' doesn't exist - creating new agent")
                    
            except Exception as e:
                # Agent doesn't exist or error listing versions
                print(f"📝 Agent '{agent_name}' doesn't exist - creating new agent")
            
            # Create new version (either first version or updated version)
            agent = await client.agents.create_version(
                agent_name=agent_name,
                definition=definition,
                description=description,
                metadata=metadata or {}
            )
            
            print(f"✅ Agent version created!")
            print(f"   Name: {agent.name}")
            print(f"   Version: {agent.version}")
            print(f"   Created: {agent.created_at}")
            print(f"   ID: {agent.id}")
            
            return agent, True


async def main():
    """Main execution"""
    
    # Configuration
    endpoint = os.getenv(
        "PROJECT_ENDPOINT",
        "https://ai-foundation-dev-aihub-229237e9.services.ai.azure.com/api/projects/ai-foundation-dev-project"
    )
    
    agent_name = os.getenv("AGENT_NAME", "mcp-demo-agent")
    model_name = os.getenv("MODEL_NAME", "gpt-4o-mini")
    mcp_server_url = os.getenv(
        "MCP_SERVER_URL",
        "https://ai-foundation-dev-apim-229237e9.azure-api.net/crud-mcp/mcp"
    )
    
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║      Idempotent Agent Creation/Update                       ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    print()
    print(f"Agent: {agent_name}")
    print(f"Endpoint: {endpoint}")
    print(f"Model: {model_name}")
    print(f"MCP Server: {mcp_server_url}")
    print("─" * 64)
    print()
    
    try:
        # Define the MCP tool
        mcp_tool = MCPTool(
            server_label="crud_mcp_server",
            server_url=mcp_server_url
        )
        
        # Create the agent definition
        definition = PromptAgentDefinition(
            model=model_name,
            instructions="""You are an AI assistant with access to a data management system via MCP tools.

You can help users:
- Create, read, update, and delete items in the data store
- Query and retrieve information about stored items
- Manage data operations efficiently

When users ask about data management tasks, use the available MCP tools to perform the operations.
Always provide clear feedback about what actions you're taking.""",
            tools=[mcp_tool],
            temperature=0.7,
            top_p=0.95
        )
        
        # Create or update (idempotent)
        agent, was_created = await create_or_update_agent(
            endpoint=endpoint,
            agent_name=agent_name,
            definition=definition,
            description="Declarative agent with MCP server integration (idempotent deployment)",
            metadata={
                "environment": "dev",
                "managedBy": "python-sdk",
                "deploymentType": "idempotent"
            }
        )
        
        print()
        print("─" * 64)
        if was_created:
            print("📦 Result: NEW VERSION CREATED")
        else:
            print("♻️  Result: EXISTING VERSION REUSED (no changes)")
        print("─" * 64)
        
        # Show all versions
        print()
        print("📚 All versions of this agent:")
        async with DefaultAzureCredential() as cred:
            async with AIProjectClient(endpoint=endpoint, credential=cred) as client:
                version_count = 0
                async for version in client.agents.list_versions(agent_name=agent_name):
                    version_count += 1
                    is_current = "← current" if version.version == agent.version else ""
                    print(f"   • Version {version.version}: {version.created_at} {is_current}")
                print(f"\n   Total: {version_count} version(s)")
        
        print()
        print("═" * 64)
        print("🎉 SUCCESS! Check Azure AI Foundry portal:")
        print("   https://ai.azure.com/")
        print("═" * 64)
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    exit(exit_code)
