terraform {
  backend "azurerm" {
    storage_account_name = "stmedalforgestate"
    container_name       = "tfstate"
    key                  = "uc.tfstate"
  }
}
