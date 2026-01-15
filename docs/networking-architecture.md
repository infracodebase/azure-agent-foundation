# Network Architecture Deep Dive

This document provides comprehensive details about the dual networking architecture supporting both public and private deployment modes.

## Dual Networking Design

This architecture is designed with **networking flexibility** as a core principle, supporting both public and private deployments through a single Terraform configuration.

## Public Networking Mode (`enable_private_networking=false`)

**Architecture Overview**:
```
Internet ──► API Management ──► Function Apps ──► Storage/KeyVault
              (Public HTTPS)     (Public HTTPS)    (Managed Identity)
                   │
                   └──► Container Apps ──► AI Foundry
                        (Public HTTPS)     (Managed Identity)
```

**Configuration**:
- All services accessible via public endpoints
- Security through authentication (API keys, managed identities)
- No VNet or subnet configuration
- Consumption-tier pricing for cost optimization

**Use Cases**: Development, testing, proof-of-concepts, demos

## Private Networking Mode (`enable_private_networking=true`)

**Architecture Overview**:
```
                    ┌─────────────────────────────────────────┐
                    │           Azure Virtual Network          │
                    │  ┌─────────────┐  ┌─────────────────────┐ │
Internet ──► APIM   │  │ APIM Subnet │  │ Function App Subnet │ │
             Gateway│  │   (Public)  │  │    (Private)        │ │
                    │  └─────────────┘  └─────────────────────┘ │
                    │  ┌─────────────────────┐                  │
                    │  │Container Apps Subnet│ ──► KeyVault     │
                    │  │      (Private)      │     (Private)    │
                    │  └─────────────────────┘                  │
                    └─────────────────────────────────────────────┘
```

**Configuration**:
- Dedicated subnets for each service tier
- Network Security Groups with restrictive rules
- Service endpoints for secure Azure service access
- Premium SKUs required for VNet integration

**Use Cases**: Production environments, compliance requirements, sensitive data

## Network Security Groups Configuration

When private networking is enabled, NSGs automatically configure:

```hcl
# APIM Subnet Security Rules
- Allow: Azure API Management service tags (port 3443)
- Allow: HTTPS/HTTP from internet (ports 80, 443)
- Deny: All other inbound traffic

# Function App Subnet Security Rules
- Allow: VNet-to-VNet communication
- Allow: Azure services (KeyVault, Storage)
- Deny: Internet inbound access

# Container Apps Subnet Security Rules
- Allow: Container-to-container communication
- Allow: Load balancer health probes
- Allow: Outbound to VNet and Azure services
```

## Service Endpoint Configuration

Private networking automatically enables service endpoints for secure access:

- **Storage Account**: Function App subnet → Storage service endpoint
- **Key Vault**: APIM + Function App subnets → KeyVault service endpoint
- **Container Registry** (when used): Container Apps subnet → ACR service endpoint

## Automatic Network Rule Management

The Terraform configuration automatically handles network restrictions:

```hcl
# Storage Account - Automatic network rules
resource "azurerm_storage_account_network_rules" "this" {
  count = var.enable_private_networking ? 1 : 0

  default_action = "Deny"
  virtual_network_subnet_ids = [
    azurerm_subnet.func[0].id,
    azurerm_subnet.container_apps[0].id
  ]
  bypass = ["AzureServices", "Metrics", "Logging"]
}

# Key Vault - Automatic firewall rules
dynamic "network_acls" {
  for_each = var.enable_private_networking ? [1] : []
  content {
    default_action = "Deny"
    virtual_network_subnet_ids = [
      azurerm_subnet.func[0].id,
      azurerm_subnet.apim[0].id
    ]
  }
}
```

## Private Networking Requirements

When enabling private networking (`enable_private_networking=true`):

**Required Infrastructure Changes**:
- Function App SKU upgraded to Premium (EP1+) for VNet integration
- Three dedicated subnets created with proper address spacing
- NSG rules configured for each subnet with security restrictions
- Service endpoints enabled for Azure service access

**Deployment Requirements**:
- Deployment agent (Terraform runner) must have connectivity to the VNet
- Either Azure DevOps agents in same VNet or VPN/ExpressRoute connectivity
- GitHub Actions require self-hosted runners with VNet access

**Cost Impact**:
- **EP1 Function App**: ~$150/month (vs $0 for consumption)
- **Standard APIM**: ~$250/month (vs $50 for Developer tier)
- **VNet Infrastructure**: ~$10/month for VNet, subnets, NSGs
- **Private Endpoints** (optional): ~$7/endpoint/month
- **VPN Gateway** (if needed for deployment): ~$30-100/month

**Security Benefits**:
- **Zero Trust Network**: No public internet exposure for backend services
- **Network Segmentation**: Dedicated subnets isolate service tiers
- **Traffic Inspection**: All inter-service traffic flows through NSG rules
- **Private DNS**: Azure services resolve to private IP addresses
- **Compliance**: Meets requirements for PCI DSS, HIPAA, SOX frameworks

**Migration Path**:
```bash
# Start with public networking for development
terraform apply -var="enable_private_networking=false"

# Later migrate to private networking for production
terraform apply -var="enable_private_networking=true" \
                 -var="function_app_service_plan_sku=EP1" \
                 -var="environment=prod"
```