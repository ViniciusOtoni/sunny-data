terraform {
  backend "azurerm" {
    storage_account_name = "stmedalforgestate"   # criado no landing-zone
    container_name       = "tfstate"            
    key                  = "dbx.tfstate"        # arquivo deste micro-serviço
    resource_group_name  = "rg-medalforge-core"
    use_azuread_auth     = true  
  }
}
