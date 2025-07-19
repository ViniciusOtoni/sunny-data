provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias           = "admin"
  subscription_id = var.subscription_id
  client_id       = var.admin_client_id
  client_secret   = var.admin_client_secret
  tenant_id       = var.tenant_id
  features {}
}

data "terraform_remote_state" "identity" {
  backend = "local"      # ainda local;
  config  = { path = "../core-identity/terraform.tfstate" }
}
