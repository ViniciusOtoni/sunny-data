locals {
  workspace_id_numeric      = tonumber(regex("adb-([0-9]+)", var.workspace_url)[0])

  # Privilégios padronizados (nível Catálogo)
  engineer_catalog_privs    = ["BROWSE","USE_CATALOG","CREATE_SCHEMA","READ_VOLUME","WRITE_VOLUME"]
  consumer_bronze_privs     = ["BROWSE","USE_CATALOG"]
  consumer_silver_privs     = ["BROWSE","USE_CATALOG","SELECT"]
  engineer_monitoring_privs = ["BROWSE","USE_CATALOG","CREATE_SCHEMA"]
}

resource "time_sleep" "after_admin_grant" {
  create_duration = "60s"
}

# --- Metastore (ACCOUNT) ---
resource "databricks_metastore" "uc" {
  provider     = databricks.account
  name         = var.metastore_name
  storage_root = var.uc_storage_root
  region       = var.databricks_region
  depends_on   = [time_sleep.after_admin_grant]
}

# --- Assignment do metastore ao workspace (ACCOUNT) ---
resource "databricks_metastore_assignment" "attach" {
  provider     = databricks.account
  workspace_id = local.workspace_id_numeric
  metastore_id = databricks_metastore.uc.id
}

# Espera para propagação do attach
resource "time_sleep" "after_assignment" {
  depends_on      = [databricks_metastore_assignment.attach]
  create_duration = "90s"
}

# --- Propagação dos grupos (ACCOUNT) ---
# Recebe um mapa: { "data-platform-engineers" = "<AAD objectId>", ... }
resource "databricks_group" "account_groups" {
  for_each     = var.groups_objects_ids
  provider     = databricks.account
  display_name = each.key          # "data-platform-engineers", "data-consumers", etc.
  external_id  = each.value        # objectId do AAD (âncora IAM)
  depends_on   = [time_sleep.after_assignment]
}

# Atribuir esses grupos à workspace como USER (Account-level)
resource "databricks_mws_permission_assignment" "ws_users" {
  for_each     = databricks_group.account_groups
  provider     = databricks.account
  workspace_id = local.workspace_id_numeric
  principal_id = each.value.id
  permissions  = ["USER"]
}

# --- Grants no Metastore (WORKSPACE/SPN) ---
resource "databricks_grants" "metastore" {
  provider  = databricks.spn
  metastore = databricks_metastore.uc.id

  grant {
    principal  = "data-platform-engineers"
    privileges = ["CREATE_CATALOG"]
  }

  # garante que os grupos já estão na workspace
  depends_on = [time_sleep.after_assignment, databricks_mws_permission_assignment.ws_users]
}

# --- Storage Credential (WORKSPACE / SPN) ---
resource "databricks_storage_credential" "uc" {
  provider = databricks.spn
  name     = var.uc_storage_credential_name

  azure_managed_identity {
    access_connector_id = var.azure_managed_identity_id
  }
  depends_on = [databricks_grants.metastore]
}

# Espera para propagação do credential
resource "time_sleep" "after_credential" {
  depends_on      = [databricks_storage_credential.uc]
  create_duration = "60s"
}

# --- External Locations (WORKSPACE / SPN) ---
resource "databricks_external_location" "raw" {
  provider        = databricks.spn
  name            = "raw"
  url             = var.raw_url
  credential_name = databricks_storage_credential.uc.name
  depends_on      = [time_sleep.after_credential]
}

resource "databricks_external_location" "bronze" {
  provider        = databricks.spn
  name            = "bronze"
  url             = var.bronze_url
  credential_name = databricks_storage_credential.uc.name
  depends_on      = [time_sleep.after_credential]
}

resource "databricks_external_location" "silver" {
  provider        = databricks.spn
  name            = "silver"
  url             = var.silver_url
  credential_name = databricks_storage_credential.uc.name
  depends_on      = [time_sleep.after_credential]
}

resource "databricks_external_location" "gold" {
  provider        = databricks.spn
  name            = "gold"
  url             = var.gold_url
  credential_name = databricks_storage_credential.uc.name
  depends_on      = [time_sleep.after_credential]
}

# --- Catálogos (WORKSPACE/SPN) ---
resource "databricks_catalog" "bronze" {
  provider       = databricks.spn
  name           = "bronze"
  comment        = "Camada Bronze"
  isolation_mode = "OPEN"
  depends_on     = [databricks_grants.metastore]
}

resource "databricks_catalog" "silver" {
  provider       = databricks.spn
  name           = "silver"
  comment        = "Camada Silver"
  isolation_mode = "OPEN"
  depends_on     = [databricks_grants.metastore]
}

resource "databricks_catalog" "monitoring" {
  provider       = databricks.spn
  name           = "monitoring"
  comment        = "Telemetria e observabilidade do lake"
  isolation_mode = "OPEN"
  depends_on     = [databricks_grants.metastore]
}

# --- Grants dos catálogos (WORKSPACE/SPN) ---
resource "databricks_grants" "bronze_grants" {
  provider   = databricks.spn
  catalog    = databricks_catalog.bronze.name

  grant {
    principal  = "data-platform-engineers"
    privileges = local.engineer_catalog_privs
  }
  grant {
    principal  = "data-consumers"
    privileges = local.consumer_bronze_privs
  }

  depends_on = [databricks_mws_permission_assignment.ws_users]
}

resource "databricks_grants" "silver_grants" {
  provider   = databricks.spn
  catalog    = databricks_catalog.silver.name

  grant {
    principal  = "data-platform-engineers"
    privileges = local.engineer_catalog_privs
  }
  grant {
    principal  = "data-consumers"
    privileges = local.consumer_silver_privs
  }

  depends_on = [databricks_mws_permission_assignment.ws_users]
}

resource "databricks_grants" "monitoring_grants" {
  provider   = databricks.spn
  catalog    = databricks_catalog.monitoring.name

  grant {
    principal  = "data-platform-engineers"
    privileges = local.engineer_monitoring_privs
  }
  grant {
    principal  = "data-consumers"
    privileges = local.consumer_silver_privs
  }

  depends_on = [databricks_mws_permission_assignment.ws_users]
}
