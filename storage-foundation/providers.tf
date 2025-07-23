provider "azurerm" {
  alias           = "admin"                     # SPN dinâmica (Contributor no RG)
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.spn_client_id
  client_secret   = var.spn_client_secret
  features {
    network_watcher {
      enabled = false           
    }
  }
}

# lê outputs do landing-zone (já no backend remoto repousado no SA)
data "terraform_remote_state" "landing" {
  backend = "azurerm"
  config = {
    storage_account_name = "stmedalforgestate"
    container_name       = "tfstate"
    key                  = "landing.tfstate"
    resource_group_name  = "rg-medalforge-core"
    use_azuread_auth     = true  
  }
}
