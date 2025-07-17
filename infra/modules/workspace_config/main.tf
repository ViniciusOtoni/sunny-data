# extrai o ID numérico do workspace
locals {
  matches              = regexall("adb-(\\d+)\\.", var.workspace_url)
  workspace_id_numeric = tonumber(local.matches[0][0])
}

# Criar Metastore no Databricks
resource "databricks_metastore" "uc" {
  provider     = databricks.account
  name         = var.metastore_name
  storage_root = var.uc_storage_root
  region       = var.databricks_region
}

# Attach ao workspace o catálogo
resource "databricks_metastore_assignment" "attach" {
  provider     = databricks.spn
  workspace_id = local.workspace_id_numeric
  metastore_id = databricks_metastore.uc.id
}

resource "null_resource" "wait_for_assignment" {
  depends_on = [databricks_metastore_assignment.attach]
}


# Storage Credential 
resource "databricks_storage_credential" "uc" {
  provider = databricks.spn
  name     = var.uc_storage_credential_name

  azure_service_principal {
    application_id = var.spn_client_id
    tenant_id      = var.tenant_id
    client_secret  = var.spn_client_secret
  }

  depends_on = [
    null_resource.wait_for_assignment,
  ]
}

# External locations
resource "databricks_external_location" "bronze" {
  provider        = databricks.spn
  name            = "bronze"
  url             = var.bronze_url
  credential_name = databricks_storage_credential.uc.name
}

resource "databricks_external_location" "silver" {
  provider        = databricks.spn
  name            = "silver"
  url             = var.silver_url
  credential_name = databricks_storage_credential.uc.name
}

resource "databricks_external_location" "gold" {
  provider        = databricks.spn
  name            = "gold"
  url             = var.gold_url
  credential_name = databricks_storage_credential.uc.name
}