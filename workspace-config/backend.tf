terraform {
  backend "azurerm" {
    storage_account_name = "stmedalforgestate"
    container_name       = "tfstate"
    key                  = "uc.tfstate"
    resource_group_name  = "rg-medalforge-core"
  }
}
