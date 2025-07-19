terraform {
  required_version = ">= 1.6.0"
  backend "local" {}   # depois migraremos para o Blob recém-criado
}
