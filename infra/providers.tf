# 1) provider padrão: sem alias, apenas .features{} para satisfazer o requisito do Terraform
provider "azurerm" {
  features {}
}

# 2) provider admin, para criar a SPN e recursos iniciais
provider "azurerm" {
  alias           = "admin"
  subscription_id = var.subscription_id
  client_id       = var.admin_client_id
  client_secret   = var.admin_client_secret
  tenant_id       = var.tenant_id
  features {}
}

# 3) provider spn, para consumir recursos via a SPN recém-criada
provider "azurerm" {
  alias           = "spn"
  subscription_id = var.subscription_id
  client_id       = var.spn_client_id
  client_secret   = var.spn_client_secret
  tenant_id       = var.tenant_id
  features {}
}

# Azure AD provider para criar a SPN
provider "azuread" {
  alias     = "admin"
  tenant_id = var.tenant_id
}
