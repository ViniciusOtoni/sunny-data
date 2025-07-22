terraform {
  backend "azurerm" {
    storage_account_name = "stmedalforgestate"
    container_name       = "tfstate"          
    key                  = "storage.tfstate" 
    resource_group_name  = "rg-medalforge-core"
    use_azuread_auth     = true  
  }
}
