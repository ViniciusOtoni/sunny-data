# extrai o ID numérico do workspace
locals {
  matches              = regexall("adb-(\\d+)\\.", var.workspace_url)
  workspace_id_numeric = tonumber(local.matches[0][1])
}

# Delay artificial para Sync de role "account_admin"
resource "null_resource" "sync_account_admin" {

  provisioner "local-exec" {
    command = "echo 'Esperando sync da role de account admin...' && sleep 200"
  }
}

# Criar Metastore no Databricks
resource "databricks_metastore" "uc" {
  provider     = databricks.account
  name         = var.metastore_name
  storage_root = var.uc_storage_root
  region       = var.databricks_region

  depends_on = [
    null_resource.sync_account_admin,
  ]
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

   
  azure_managed_identity {
    access_connector_id = var.azure_managed_identity_id
  }

  depends_on = [
    null_resource.wait_for_assignment,
  ]
}

# Delay artificial após a criação do Storage Credential
resource "null_resource" "wait_for_credential" {
  depends_on = [databricks_storage_credential.uc]

  provisioner "local-exec" {
    command = "echo 'Esperando propagação do Storage Credential...' && sleep 120"
  }
}

# External locations
resource "databricks_external_location" "raw" {
  provider        = databricks.spn
  name            = "raw"
  url             = var.raw_url
  credential_name = databricks_storage_credential.uc.name


  depends_on = [null_resource.wait_for_credential]
}

resource "databricks_external_location" "bronze" {
  provider        = databricks.spn
  name            = "bronze"
  url             = var.bronze_url
  credential_name = databricks_storage_credential.uc.name
  

  depends_on = [null_resource.wait_for_credential]
}

resource "databricks_external_location" "silver" {
  provider        = databricks.spn
  name            = "silver"
  url             = var.silver_url
  credential_name = databricks_storage_credential.uc.name
 

  depends_on = [null_resource.wait_for_credential]
}

resource "databricks_external_location" "gold" {
  provider        = databricks.spn
  name            = "gold"
  url             = var.gold_url
  credential_name = databricks_storage_credential.uc.name


  depends_on = [null_resource.wait_for_credential]
}