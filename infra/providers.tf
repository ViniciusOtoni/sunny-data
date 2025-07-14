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
  client_id       = var.admin_client_id
  client_secret   = var.admin_client_secret
}

# provider para recursos dentro da workspace
provider "databricks" {
  alias                       = "spn"
  azure_workspace_resource_id = module.workspace_create.workspace_id
  azure_client_id             = var.spn_client_id
  azure_client_secret         = var.spn_client_secret
  azure_tenant_id             = var.tenant_id
}

# provider para recursos de nível de conta
provider "databricks" {
  alias           = "account"
  host            = "https://accounts.azuredatabricks.net"
  account_id      = var.databricks_account_id
  client_id       = var.spn_client_id
  client_secret   = var.spn_client_secret
  azure_tenant_id = var.tenant_id
}