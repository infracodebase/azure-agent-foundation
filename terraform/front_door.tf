# Azure Front Door Profile for WAF and CDN capabilities
resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = local.front_door_name
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Premium_AzureFrontDoor" # Premium tier required for managed rules

  tags = local.common_tags
}

# WAF Policy for security rules
resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  name                              = "${replace(local.front_door_name, "-", "")}wafpolicy" # Must be alphanumeric
  resource_group_name               = azurerm_resource_group.this.name
  sku_name                          = azurerm_cdn_frontdoor_profile.this.sku_name
  enabled                           = true
  mode                              = "Prevention"
  redirect_url                      = "https://www.microsoft.com"
  custom_block_response_status_code = 403
  custom_block_response_body        = base64encode("Access Blocked")

  # Managed rule set for common web application attacks
  managed_rule {
    type    = "Microsoft_DefaultRuleSet"
    version = "2.1"
    action  = "Block"
  }

  # Managed rule set for bot protection
  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    action  = "Block"
  }

  tags = local.common_tags
}

# Security Policy to associate WAF with Front Door
resource "azurerm_cdn_frontdoor_security_policy" "this" {
  name                     = "${local.front_door_name}-security-policy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this.id

      association {
        patterns_to_match = ["/*"]
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.this.id
        }
      }
    }
  }
}

# Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = "${local.front_door_name}-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  tags = local.common_tags
}

# Origin Group for Container Apps
resource "azurerm_cdn_frontdoor_origin_group" "container_apps" {
  name                     = "container-apps-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  session_affinity_enabled = false

  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 10

  health_probe {
    interval_in_seconds = 240
    path                = "/health"
    protocol            = "Https"
    request_type        = "HEAD"
  }

  load_balancing {
    additional_latency_in_milliseconds = 50
    sample_size                        = 4
    successful_samples_required        = 3
  }
}

# Origin for Container App
resource "azurerm_cdn_frontdoor_origin" "container_app" {
  name                          = "container-app-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.container_apps.id
  enabled                       = true

  certificate_name_check_enabled = true
  host_name                      = azurerm_container_app.chat_interface.latest_revision_fqdn
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = azurerm_container_app.chat_interface.latest_revision_fqdn
  priority                       = 1
  weight                         = 1000
}

# Route for Container Apps traffic
resource "azurerm_cdn_frontdoor_route" "container_apps" {
  name                          = "container-apps-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.container_apps.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.container_app.id]

  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
  forwarding_protocol    = "HttpsOnly"
  link_to_default_domain = true

  cache {
    query_string_caching_behavior = "IgnoreQueryString"
  }

  # Enable HTTPS redirect
  https_redirect_enabled = true
}