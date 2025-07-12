terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.0"
    }
  }
}

provider "azurerm" {
  alias    = "spn"
  features {}
}

provider "databricks" {
  alias = "spn"
}


resource "azurerm_databricks_workspace" "this" {
  name                           = var.workspace_name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  sku                            = "premium"
  managed_resource_group_name    = "${var.resource_group_name}-databricks-rg"
}

resource "databricks_metastore" "uc" {
  provider     = databricks.spn
  name         = "medalforge-catalog"
  storage_root             = var.uc_storage_root
  storage_credential_name  = var.uc_storage_credential_name
}

resource "databricks_metastore_assignment" "attach" {
  provider     = databricks.spn
  workspace_id = azurerm_databricks_workspace.this.id
  metastore_id = databricks_metastore.uc.id
  
  depends_on = [
    azurerm_databricks_workspace.this
  ]

}

resource "databricks_storage_credential" "this" {
  name = "medalforge-cred"
  azure_service_principal {
    client_id     = var.spn_client_id
    client_secret = var.spn_client_secret
  }
}

resource "databricks_external_location" "bronze" {
  name            = "bronze"
  url             = "abfss://bronze@medalforgestorage.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.this.name
}


resource "databricks_external_location" "silver" {
  name            = "silver"
  url             = "abfss://silver@medalforgestorage.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.this.name
}

resource "databricks_external_location" "gold" {
  name            = "gold"
  url             = "abfss://gold@medalforgestorage.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.this.name
}