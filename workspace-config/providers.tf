terraform {
  required_providers {
    # Padroniza para o provider oficial da Databricks
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.50"   
    }
  }
}

provider "databricks" {
  alias = "spn"
  host  = data.terraform_remote_state.dbx.outputs.workspace_url
  azure_client_id     = var.spn_client_id
  azure_client_secret = var.spn_client_secret
  azure_tenant_id     = var.tenant_id
  auth_type = "azure-client-secret"
}

provider "databricks" {
  alias = "account"
  host       = "https://accounts.azuredatabricks.net"
  account_id = var.databricks_account_id

  azure_client_id     = var.spn_client_id
  azure_client_secret = var.spn_client_secret
  azure_tenant_id     = var.tenant_id
  auth_type = "azure-client-secret"
}

# remote-states
data "terraform_remote_state" "storage" {
  backend = "azurerm"
  config = {
    storage_account_name = "stmedalforgestate"
    container_name       = "tfstate"
    key                  = "storage.tfstate"
    resource_group_name  = "rg-medalforge-core"
    use_azuread_auth     = true  
  }
}

data "terraform_remote_state" "dbx" {
  backend = "azurerm"
  config = {
    storage_account_name = "stmedalforgestate"
    container_name       = "tfstate"
    key                  = "dbx.tfstate"
    resource_group_name  = "rg-medalforge-core"
    use_azuread_auth     = true  
  }
}
