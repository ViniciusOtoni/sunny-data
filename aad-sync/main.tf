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
    databricks = {
      source = "databricks/databricks"
    }
    null = {
      source = "hashicorp/null"
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

# Buffer para o Entra materializar o Service Principal
resource "time_sleep" "after_app" {
  depends_on      = [azuread_application.scim_app]
  create_duration = "60s"
}

# Service Principal (Enterprise App) criado automaticamente
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
    value = "false" # somente “assigned”
  }

  provider   = azuread.admin
  depends_on = [azuread_synchronization_job.scim_job]
}

# Buffer para appRoles do conector antes do assignment
resource "time_sleep" "before_assignments" {
  depends_on      = [azuread_synchronization_secret.scim_creds]
  create_duration = "45s"
}

# 5) Atribuir os grupos ao Enterprise App (role “User”) com fallback
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

# 6) Adicionar a SPN DINÂMICA como membro de TODOS os grupos no AAD
data "azuread_service_principal" "dynamic_spn" {
  client_id = data.azurerm_key_vault_secret.dynamic_spn_client_id.value
  provider  = azuread.admin
}

resource "azuread_group_member" "dynamic_spn_in_groups" {
  for_each         = azuread_group.aad_groups
  group_object_id  = each.value.object_id
  member_object_id = data.azuread_service_principal.dynamic_spn.object_id
  provider         = azuread.admin

  depends_on = [azuread_app_role_assignment.assign_groups]
}

# 7) Aguardar (polling) os grupos surgirem no Databricks Account via SCIM
#    - Consulta o endpoint Account SCIM /Groups com o token e a BaseAddress
#    - Evita depender de sleeps longos/ciclos de 20–40min
resource "null_resource" "wait_scim_groups" {
  for_each = azuread_group.aad_groups

  triggers = {
    group_name   = each.key
    scim_url     = var.account_scim_url
    token_hash   = sha1(data.azurerm_key_vault_secret.scim_token.value)
    after_assign = azuread_app_role_assignment.assign_groups[each.key].id
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    environment = {
      SCIM_URL   = var.account_scim_url
      SCIM_TOKEN = data.azurerm_key_vault_secret.scim_token.value
      GROUP_NAME = each.key
      TIMEOUT    = try(var.scim_group_wait_timeout, 600) # 10min default
    }
    command = <<'BASH'
set -euo pipefail
url="${SCIM_URL%/}/Groups?filter=displayName%20eq%20%22${GROUP_NAME}%22&count=1"
deadline=$((SECONDS + TIMEOUT))
echo ">> Esperando grupo '${GROUP_NAME}' aparecer no Account via SCIM..."
while true; do
  code=$(curl -sS -o /tmp/resp.json -w "%{http_code}" \
    -H "Authorization: Bearer ${SCIM_TOKEN}" \
    -H "Content-Type: application/scim+json" \
    "$url")
  if [ "$code" = "200" ] && jq -e '.totalResults>=1' /tmp/resp.json >/dev/null 2>&1; then
    echo ">> Grupo '${GROUP_NAME}' presente no Account."
    break
  fi
  if [ $SECONDS -ge $deadline ]; then
    echo "ERRO: Timeout aguardando grupo '${GROUP_NAME}' no SCIM. Última resposta:"
    cat /tmp/resp.json || true
    exit 1
  fi
  sleep 15
done
BASH
  }

  depends_on = [azuread_group_member.dynamic_spn_in_groups]
}

# 8) Resolver e vincular a SPN dinâmica aos grupos do Databricks Account
#    - Só após confirmação (polling) de que os grupos existem no Account
data "databricks_group" "account_groups" {
  for_each     = azuread_group.aad_groups
  provider     = databricks.account
  display_name = each.key
  depends_on   = [null_resource.wait_scim_groups]
}

# SPN dinâmica já existe no Account (account_admin): fazemos apenas lookup
data "databricks_service_principal" "dynamic" {
  provider       = databricks.account
  application_id = var.dbx_spn_client_id
}

resource "databricks_group_member" "dynamic_spn_in_account_groups" {
  for_each  = data.databricks_group.account_groups
  provider  = databricks.account
  group_id  = each.value.id
  member_id = data.databricks_service_principal.dynamic.id

  depends_on = [data.databricks_group.account_groups]
}
