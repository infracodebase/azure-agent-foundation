variable "location" {
  type        = string
  description = "The Azure region where resources will be created"
  default     = "East US"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "Name of the project, used as prefix for resources"
  default     = "ai-foundation"
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  default = {
    Project     = "AI Foundation"
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}

variable "admin_object_id" {
  type        = string
  description = "Object ID of the user/service principal that will have admin access to Key Vault"
  default     = null
}

variable "enable_private_networking" {
  type        = bool
  description = "Enable private networking (VNet integration, firewalls). Set to false for public deployment without VNet agent."
  default     = false
}

variable "api_management_sku" {
  type        = string
  description = "SKU for API Management (Developer_1, Basic_1, Standard_1, Premium_1)"
  default     = "Developer_1"
}

variable "function_app_service_plan_sku" {
  type        = string
  description = "SKU for Function App Service Plan. Use Y1 for consumption (public), EP1+ for VNet integration (private)."
  default     = "Y1"
}

variable "container_apps_environment_type" {
  type        = string
  description = "Type of Container Apps Environment (Consumption or WorkloadProfiles)"
  default     = "Consumption"
}