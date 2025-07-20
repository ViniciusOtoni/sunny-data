variable "subscription_id"  { type = string }
variable "tenant_id"        { type = string }
variable "spn_client_id"    { type = string }

variable "spn_client_secret" {
  type      = string
  sensitive = true
}

variable "location" {
  type    = string
  default = "brazilsouth"
}
