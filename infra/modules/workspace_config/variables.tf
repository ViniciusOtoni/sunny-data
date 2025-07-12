variable "workspace_id" { 
    type = string 
}

variable "metastore_name" { 
    type = string 
}
variable "uc_storage_root" { 
    type = string 
}

variable "spn_client_id" { 
    type        = string 
    sensitive   = true
}

variable "spn_client_secret" { 
    type        = string 
    sensitive   = true
}

variable "tenant_id" {
    type      = string
    sensitive = true
}

variable "bronze_url" { 
    type = string 
}

variable "silver_url" { 
    type = string 
}

variable "gold_url" { 
    type = string 
}