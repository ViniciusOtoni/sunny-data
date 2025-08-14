locals {
  workspace_id_numeric = tonumber(regex("adb-([0-9]+)", var.workspace_url)[0])
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

  depends_on = [time_sleep.after_admin_grant]
}

# --- Assignment do metastore ao workspace (ACCOUNT) ---
resource "databricks_metastore_assignment" "attach" {
  provider     = databricks.account
  workspace_id = local.workspace_id_numeric
  metastore_id = databricks_metastore.uc.id
}

# Espera curta para propagação do attach antes de criar catálogos / credenciais
resource "time_sleep" "after_assignment" {
  depends_on      = [databricks_metastore_assignment.attach]
  create_duration = "90s"
}

# --- Storage Credential (ACCOUNT) ---
resource "databricks_storage_credential" "uc" {
  provider = databricks.account
  name     = var.uc_storage_credential_name

  azure_managed_identity {
    access_connector_id = var.azure_managed_identity_id
  }

  depends_on = [time_sleep.after_assignment]
}

# Espera curta para propagação do credential
resource "time_sleep" "after_credential" {
  depends_on      = [databricks_storage_credential.uc]
  create_duration = "60s"
}

# --- External Locations (ACCOUNT) ---
resource "databricks_external_location" "raw" {
  provider        = databricks.account
  name            = "raw"
  url             = var.raw_url
  credential_name = databricks_storage_credential.uc.name
  depends_on      = [time_sleep.after_credential]
}

resource "databricks_external_location" "bronze" {
  provider        = databricks.account
  name            = "bronze"
  url             = var.bronze_url
  credential_name = databricks_storage_credential.uc.name
  depends_on      = [time_sleep.after_credential]
}

resource "databricks_external_location" "silver" {
  provider        = databricks.account
  name            = "silver"
  url             = var.silver_url
  credential_name = databricks_storage_credential.uc.name
  depends_on      = [time_sleep.after_credential]
}

resource "databricks_external_location" "gold" {
  provider        = databricks.account
  name            = "gold"
  url             = var.gold_url
  credential_name = databricks_storage_credential.uc.name
  depends_on      = [time_sleep.after_credential]
}

# --- Grupos (WORKSPACE/SPN) ---
resource "databricks_group" "platform_engineers" {
  provider     = databricks.spn
  display_name = "data-platform-engineers"
}

resource "databricks_group" "consumers" {
  provider     = databricks.spn
  display_name = "data-consumers"
}

# --- Catálogos (WORKSPACE/SPN) ---
resource "databricks_catalog" "bronze" {
  provider       = databricks.spn
  name           = "bronze"
  comment        = "Camada Bronze"
  isolation_mode = "OPEN"
  depends_on     = [time_sleep.after_assignment]
}

resource "databricks_catalog" "silver" {
  provider       = databricks.spn
  name           = "silver"
  comment        = "Camada Silver"
  isolation_mode = "OPEN"
  depends_on     = [time_sleep.after_assignment]
}

resource "databricks_catalog" "monitoring" {
  provider       = databricks.spn
  name           = "monitoring"
  comment        = "Telemetria e observabilidade do lake"
  isolation_mode = "OPEN"
  depends_on     = [time_sleep.after_assignment]
}

# --- Grants dos catálogos (WORKSPACE/SPN) ---
resource "databricks_grants" "bronze" {
  provider = databricks.spn
  catalog  = databricks_catalog.bronze.name
  grant {
    principal  = databricks_group.platform_engineers.display_name
    privileges = ["USE_CATALOG", "CREATE", "READ_VOLUME", "WRITE_VOLUME"]
  }
  grant {
    principal  = databricks_group.consumers.display_name
    privileges = ["USE_CATALOG"]
  }
}

resource "databricks_grants" "silver" {
  provider = databricks.spn
  catalog  = databricks_catalog.silver.name
  grant {
    principal  = databricks_group.platform_engineers.display_name
    privileges = ["USE_CATALOG", "CREATE", "READ_VOLUME", "WRITE_VOLUME"]
  }
  grant {
    principal  = databricks_group.consumers.display_name
    privileges = ["USE_CATALOG", "SELECT"]
  }
}

resource "databricks_grants" "monitoring" {
  provider = databricks.spn
  catalog  = databricks_catalog.monitoring.name
  grant {
    principal  = databricks_group.platform_engineers.display_name
    privileges = ["USE_CATALOG", "CREATE"]
  }
  grant {
    principal  = databricks_group.consumers.display_name
    privileges = ["USE_CATALOG", "SELECT"]
  }
}

# --- (NOVO) SPN no workspace + Entitlements (WORKSPACE/SPN) ---

data "databricks_service_principal" "automation" {
  provider       = databricks.spn
  application_id = var.spn_client_id
}




# --- SQL Warehouse (endpoint) (WORKSPACE/SPN) ---
resource "databricks_sql_endpoint" "serverless_wh" {
  provider                  = databricks.spn
  name                      = "wh_serverless_explore"
  cluster_size              = "2X-Small"
  auto_stop_mins            = 15
  enable_serverless_compute = true
  depends_on = [
    time_sleep.after_assignment
  ]
}

# --- Permissões no Warehouse (WORKSPACE/SPN) ---
resource "databricks_permissions" "wh_perms" {
  provider        = databricks.spn
  sql_endpoint_id = databricks_sql_endpoint.serverless_wh.id

  access_control {
    service_principal_id = data.databricks_service_principal.automation.id
    permission_level     = "CAN_MANAGE"
  }
  access_control {
    group_name       = databricks_group.platform_engineers.display_name
    permission_level = "CAN_MANAGE"
  }
  access_control {
    group_name       = databricks_group.consumers.display_name
    permission_level = "CAN_USE"
  }
}
