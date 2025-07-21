output "state_sa_name"    { value =  azurerm_storage_account.tfstate.name }
output "state_rg_name"    { value =  data.terraform_remote_state.identity.outputs.rg_core_name }
output "rg_datalake_name" { value = data.terraform_remote_state.identity.outputs.rg_datalake }
