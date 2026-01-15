# Operations & Monitoring Guide

This document provides comprehensive operational guidance for running and monitoring the Azure AI Foundation infrastructure.

## Health Monitoring

### Automated Health Checks
- **Function App**: `/api/health` endpoint with dependency validation
- **API Management**: Built-in health monitoring and alerting
- **Container Apps**: Kubernetes-style health, readiness, and startup probes
- **AI Foundry**: Model deployment status and quota monitoring

### Monitoring Dashboards
```bash
# Get monitoring URLs
terraform output application_insights_url
terraform output log_analytics_workspace_url

# Key metrics to monitor:
# - API Management: Request rate, latency, error rate
# - Function Apps: Execution count, duration, failures
# - AI Foundry: Token consumption, model availability
# - Container Apps: CPU/memory usage, replica count
```

## Scaling Configuration

### Automatic Scaling
- **Function Apps**: Consumption plan scales automatically (0-200 instances)
- **Container Apps**: Horizontal pod autoscaling (1-30 replicas by default)
- **API Management**: Static capacity (upgrade SKU for higher throughput)
- **AI Foundry**: Token-based throttling with automatic retry

### Manual Scaling
```bash
# Scale Container Apps
az containerapp update --name <app-name> \
  --min-replicas 2 --max-replicas 50

# Scale Function App (Premium plan)
az functionapp plan update --name <plan-name> \
  --max-elastic-worker-count 20
```

## Backup & Disaster Recovery

### Automated Backups
- **Key Vault**: Soft delete and purge protection enabled
- **Storage Account**: Point-in-time restore and versioning
- **API Management**: Daily configuration backup to storage
- **Function Apps**: Source code in Git repositories

### Manual Backup Procedures
```bash
# Backup API Management configuration
az apim backup --name <apim-name> \
  --storage-account-name <storage-name> \
  --backup-name "apim-backup-$(date +%Y%m%d)"

# Export Terraform state
terraform show -json > infrastructure-state.json
```

## Schema Management

The API schema is defined inline in Terraform (`api_management.tf`). This approach:

- **Pros**: Single source of truth, no chicken-and-egg deployment problem, version control integration
- **Cons**: Schema duplication between Terraform and Function App code

### Alternative Approaches
1. **OpenAPI-First**: Shared OpenAPI spec file referenced by both Terraform and Function App
2. **Code-First**: Function App exposes `/openapi.json` → APIM imports (requires 2-phase deployment)
3. **GitOps**: Schema stored in Git, automated sync to both Terraform and Function App

**Recommended for Production**: OpenAPI-First approach with schema validation in CI/CD pipeline.

## Troubleshooting

### Common Issues

**APIM returns 401 Unauthorized**
- Verify subscription key: `terraform output api_management_subscription_key`
- Check API subscription status in Azure Portal
- Validate subscription scope includes the target API

**Function App returns 401/403**
- Ensure managed identity is configured correctly
- Check RBAC role assignments: `az role assignment list --assignee <identity-id>`
- Verify Key Vault access policies for secrets

**MCP Server Discovery Issues**
- MCP servers use preview APIs - may not appear in Portal UI
- Verify via Azure CLI: `az rest --method GET --uri "https://management.azure.com{apim-resource-id}/apis?api-version=2025-03-01-preview"`
- Check API Center registration for service discovery

**Terraform Deployment Failures**
- APIM provisioning takes 30-45 minutes - ensure adequate timeout
- Some dependent resources may fail on first apply - retry with `terraform apply`
- Check Azure service limits and quotas for your subscription

### Debugging Commands

```bash
# Check resource deployment status
az deployment group show --name <deployment-name> --resource-group <rg-name>

# Validate Function App configuration
az functionapp config show --name <function-app-name>

# Test API Management connectivity
curl -v "$(terraform output -raw api_management_gateway_url)/crud-api/health" \
  -H "Ocp-Apim-Subscription-Key: $(terraform output -raw api_management_subscription_key)"

# Check Container App logs
az containerapp logs show --name <container-app-name> --follow

# Monitor AI Foundry model usage
az cognitiveservices account list-usage --name <ai-foundry-name>
```