terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}

locals {
  groups = toset(var.aad_group_names)
}

# 1) Criar/assegurar grupos no Entra ID
resource "azuread_group" "aad_groups" {
  for_each         = local.groups
  display_name     = each.key
  security_enabled = true
  provider         = azuread.admin
}

# 2) Enterprise App “Azure Databricks SCIM Provisioning Connector”
data "azuread_application_template" "dbx_scim" {
  display_name = "Azure Databricks SCIM Provisioning Connector"
  provider     = azuread.admin
}

resource "azuread_application" "scim_app" {
  display_name = "dbx-account-scim"
  template_id  = data.azuread_application_template.dbx_scim.template_id
  feature_tags {
    enterprise = true
    gallery    = true
  }
  provider = azuread.admin
}

# Pequeno buffer para o Entra criar o Service Principal do app acima
resource "time_sleep" "after_app" {
  depends_on      = [azuread_application.scim_app]
  create_duration = "60s"
}

# O Service Principal (Enterprise App) é criado automaticamente pelo Entra
# Fazemos lookup via data source (em vez de tentar criar)
data "azuread_service_principal" "scim_sp" {
  client_id  = azuread_application.scim_app.client_id
  provider   = azuread.admin
  depends_on = [time_sleep.after_app]
}

# 3) Job de sincronização (modelo “databricks”) - criar ANTES dos secrets
resource "azuread_synchronization_job" "scim_job" {
  service_principal_id = data.azuread_service_principal.scim_sp.id
  template_id          = "databricks"
  enabled              = true
  provider             = azuread.admin
}

# 4) Segredos do job de provisionamento (SCIM BaseAddress + SecretToken)
# - BaseAddress: vem de var.account_scim_url (outra opção é ler do KV em providers.tf)
# - SecretToken: lido do KV via data.azurerm_key_vault_secret.scim_token (definido em providers.tf)
resource "azuread_synchronization_secret" "scim_creds" {
  service_principal_id = data.azuread_service_principal.scim_sp.id

  credential {
    key   = "BaseAddress"
    value = var.account_scim_url
  }
  credential {
    key   = "SecretToken"
    value = data.azurerm_key_vault_secret.scim_token.value
  }
  credential {
    key   = "SyncAll"
    value = "false" # sincroniza só “assigned”
  }

  provider   = azuread.admin
  depends_on = [azuread_synchronization_job.scim_job]
}

# Buffer extra para replicarem as appRoles do conector antes do assignment
resource "time_sleep" "before_assignments" {
  depends_on      = [azuread_synchronization_secret.scim_creds]
  create_duration = "45s"
}

# 5) Escopo: atribuir grupos ao Enterprise App (role “User”)
# App role "User" com fallback seguro caso o nome varie ou ainda não tenha propagado
locals {
  app_roles_list     = try(data.azuread_service_principal.scim_sp.app_roles, [])
  user_role_by_name  = try(element([for r in local.app_roles_list : r.id if lower(r.display_name) == "user"], 0), null)
  user_role_by_value = try(element([for r in local.app_roles_list : r.id if lower(r.value) == "user"], 0), null)
  first_enabled_role = try(element([for r in local.app_roles_list : r.id if r.enabled], 0), null)
  user_role_id       = coalesce(local.user_role_by_name, local.user_role_by_value, local.first_enabled_role, "00000000-0000-0000-0000-000000000000")
}

resource "azuread_app_role_assignment" "assign_groups" {
  for_each            = azuread_group.aad_groups
  principal_object_id = each.value.object_id
  resource_object_id  = data.azuread_service_principal.scim_sp.object_id
  app_role_id         = local.user_role_id
  provider            = azuread.admin

  depends_on = [time_sleep.before_assignments]
}

# 6) Adicionar a SPN DINÂMICA como membro de TODOS os grupos (no final)
#    - Resolvemos a SPN dinâmica lendo o client_id do KV e fazendo lookup no Entra
data "azuread_service_principal" "dynamic_spn" {
  client_id = data.azurerm_key_vault_secret.dynamic_spn_client_id.value
  provider  = azuread.admin
}

resource "azuread_group_member" "dynamic_spn_in_groups" {
  for_each          = azuread_group.aad_groups
  group_object_id   = each.value.object_id
  member_object_id  = data.azuread_service_principal.dynamic_spn.object_id
  provider          = azuread.admin

  depends_on = [azuread_app_role_assignment.assign_groups]
}


resource "azuread_synchronization_job_provision_on_demand" "kick_groups" {
  for_each               = azuread_group.aad_groups
  service_principal_id   = data.azuread_service_principal.scim_sp.id
  synchronization_job_id = azuread_synchronization_job.scim_job.id

  parameter {
    rule_id = "scoping"

    subject {
      object_id        = each.value.object_id
      object_type_name = "Group"
    }
  }

  provider   = azuread.admin
  depends_on = [azuread_group_member.dynamic_spn_in_groups]
}
