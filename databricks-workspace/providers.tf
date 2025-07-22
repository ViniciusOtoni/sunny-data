provider "azurerm" {
  alias           = "spn"
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.spn_client_id
  client_secret   = var.spn_client_secret
  features {}
}

# Realizar leitura do tfstate do microserviço anterior (STORAGE-FOUNDATION)
data "terraform_remote_state" "storage" {
  backend = "azurerm"
  config = {
    storage_account_name = "stmedalforgestate"
    container_name       = "tfstate"
    key                  = "storage.tfstate"
    resource_group_name  = "rg-medalforge-core"
  }
}
