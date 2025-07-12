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

# Unity Catalog Metastore
resource "databricks_metastore" "uc" {
  provider                     = databricks.spn
  name                         = var.metastore_name
  storage_root                 = var.uc_storage_root
  storage_root_credential_name = var.uc_storage_credential_name
}

resource "databricks_metastore_assignment" "attach" {
  provider     = databricks.spn
  workspace_id = var.workspace_id
  metastore_id = databricks_metastore.uc.id

  depends_on = [ databricks_metastore.uc ]
}

# Storage Credential
resource "databricks_storage_credential" "this" {
  provider = databricks.spn
  name     = var.uc_storage_credential_name

  azure_service_principal {
    application_id     = var.spn_client_id
    client_secret      = var.spn_client_secret
    directory_id       = var.tenant_id
  }
}

# External Locations
resource "databricks_external_location" "bronze" {
  provider        = databricks.spn
  name            = "bronze"
  url             = var.bronze_url
  credential_name = var.uc_storage_credential_name
}

resource "databricks_external_location" "silver" {
  provider        = databricks.spn
  name            = "silver"
  url             = var.silver_url
  credential_name = var.uc_storage_credential_name
}

resource "databricks_external_location" "gold" {
  provider        = databricks.spn
  name            = "gold"
  url             = var.gold_url
  credential_name = var.uc_storage_credential_name
}