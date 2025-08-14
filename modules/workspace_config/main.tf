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

# --- Storage Credential (WORKSPACE / SPN) ---
resource "databricks_storage_credential" "uc" {
  provider = databricks.spn
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

# --- Grupos ( ACCOUNT ) ---
resource "databricks_group" "platform_engineers" {
  provider     = databricks.account
  display_name = "data-platform-engineers"
}

resource "databricks_group" "consumers" {
  provider     = databricks.account
  display_name = "data-consumers"
}

resource "time_sleep" "after_groups" {
  depends_on      = [databricks_group.platform_engineers, databricks_group.consumers]
  create_duration = "10s"
}

# --- Catálogos (WORKSPACE/SPN) ---
resource "databricks_catalog" "bronze" {
  provider       = databricks.spn
  name           = "bronze"
  comment        = "Camada Bronze"
  isolation_mode = "OPEN"
  depends_on     = [time_sleep.after_assignment, time_sleep.after_groups]
}

resource "databricks_catalog" "silver" {
  provider       = databricks.spn
  name           = "silver"
  comment        = "Camada Silver"
  isolation_mode = "OPEN"
  depends_on     = [time_sleep.after_assignment, time_sleep.after_groups]
}

resource "databricks_catalog" "monitoring" {
  provider       = databricks.spn
  name           = "monitoring"
  comment        = "Telemetria e observabilidade do lake"
  isolation_mode = "OPEN"
  depends_on     = [time_sleep.after_assignment, time_sleep.after_groups]
}

# --- Grants dos catálogos (WORKSPACE/SPN) ---
resource "databricks_grants" "bronze" {
  provider = databricks.spn
  catalog  = databricks_catalog.bronze.name
  depends_on = [databricks_group.platform_engineers, databricks_group.consumers]

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
  depends_on = [databricks_group.platform_engineers, databricks_group.consumers]

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
  depends_on = [databricks_group.platform_engineers, databricks_group.consumers]

  grant {
    principal  = databricks_group.platform_engineers.display_name
    privileges = ["USE_CATALOG", "CREATE"]
  }
  grant {
    principal  = databricks_group.consumers.display_name
    privileges = ["USE_CATALOG", "SELECT"]
  }
}
