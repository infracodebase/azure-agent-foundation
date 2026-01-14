provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = "3a083da7-77cd-484f-b1fa-cbd058e12c42"
}

provider "azuread" {}

provider "azapi" {}

provider "random" {}

provider "http" {}