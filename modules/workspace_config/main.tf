locals {
  workspace_id_numeric = tonumber(regex("adb-([0-9]+)", var.workspace_url)[0])

  # Privilégios padronizados (nível Catálogo)
  engineer_catalog_privs = ["USE_CATALOG","CREATE_SCHEMA","READ_VOLUME","WRITE_VOLUME"]
  consumer_bronze_privs  = ["USE_CATALOG"]
  consumer_silver_privs  = ["USE_CATALOG","SELECT"]
  engineer_monitoring_privs = ["USE_CATALOG","CREATE_SCHEMA"]
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

# --- Grupos (ACCOUNT / SCIM na conta, visíveis ao UC) ---
resource "databricks_group" "platform_engineers" {
  provider     = databricks.account
  display_name = "data-platform-engineers"
}

resource "databricks_group" "consumers" {
  provider     = databricks.account
  display_name = "data-consumers"
}

# SPN já existe no workspace; resolvemos a identidade dela para membership
data "databricks_service_principal" "automation" {
  provider       = databricks.spn
  application_id = var.spn_client_id
}

# Adiciona a SPN ao grupo de engenheiros (na CONTA)
resource "databricks_group_member" "spn_platform_engineers_account" {
  provider  = databricks.account
  group_id  = databricks_group.platform_engineers.id
  member_id = data.databricks_service_principal.automation.id
}

# Pequeno buffer para SCIM/grupos
resource "time_sleep" "after_groups" {
  depends_on      = [databricks_group.platform_engineers, databricks_group.consumers, databricks_group_member.spn_platform_engineers_account]
  create_duration = "10s"
}

# --- Grants no Metastore (precisa para criar catálogos) ---
resource "databricks_grants" "metastore" {
  provider  = databricks.account
  metastore = databricks_metastore.uc.id

  grant {
    principal  = databricks_group.platform_engineers.display_name
    privileges = ["CREATE_CATALOG"]
  }

  depends_on = [time_sleep.after_groups, time_sleep.after_assignment]
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
resource "databricks_grants" "bronze" {
  provider   = databricks.spn
  catalog    = databricks_catalog.bronze.name
  depends_on = [databricks_group.platform_engineers, databricks_group.consumers]

  grant {
    principal  = databricks_group.platform_engineers.display_name
    privileges = local.engineer_catalog_privs
  }
  grant {
    principal  = databricks_group.consumers.display_name
    privileges = local.consumer_bronze_privs
  }
}

resource "databricks_grants" "silver" {
  provider   = databricks.spn
  catalog    = databricks_catalog.silver.name
  depends_on = [databricks_group.platform_engineers, databricks_group.consumers]

  grant {
    principal  = databricks_group.platform_engineers.display_name
    privileges = local.engineer_catalog_privs
  }
  grant {
    principal  = databricks_group.consumers.display_name
    privileges = local.consumer_silver_privs
  }
}

resource "databricks_grants" "monitoring" {
  provider   = databricks.spn
  catalog    = databricks_catalog.monitoring.name
  depends_on = [databricks_group.platform_engineers, databricks_group.consumers]

  grant {
    principal  = databricks_group.platform_engineers.display_name
    privileges = local.engineer_monitoring_privs
  }
  grant {
    principal  = databricks_group.consumers.display_name
    privileges = local.consumer_silver_privs
  }
}
