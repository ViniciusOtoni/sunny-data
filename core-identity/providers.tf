# Default = SPN bootstrap (credentials in AZURE_CREDENTIALS secret)
provider "azurerm" {
  features {
    network_watcher {
      enabled = false           
    }
  }
}

# Alias admin = conta “admin SPN” com Owner na subscription
provider "azurerm" {
  alias           = "admin"
  subscription_id = var.subscription_id
  client_id       = var.admin_client_id
  client_secret   = var.admin_client_secret
  tenant_id       = var.tenant_id
  features {
    network_watcher {
      enabled = false           
    }
  }
}


# Azure AD (criar SPN)  

provider "azuread" {
  alias         = "admin"
  tenant_id     = var.tenant_id
  client_id     = var.admin_client_id
  client_secret = var.admin_client_secret
}
