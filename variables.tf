##################################################################################
# VARIABLES
##################################################################################

variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {} 
variable "username"  {}
variable "password"  {}
variable "network_address_space" {
    type = map(string)
}
variable "instance_size" {
    type = map(string)
}
variable "instance_count" {
    type = map(number)
}
variable "subnet_count" {
    type = map(number)
}
variable  "prefix" {
  default = "Terraform"
}
variable  "protocols"{
  type = "list"
  default= ["HTTP","SSH"]
}
variable  "ports"{
  type = "list"
  default= ["80","22"]
}
variable "key_name" {
  default = "PaulKeys"
}

#########################################################
# LOCALS
#########################################################
locals {
  env_name = lower(terraform.workspace)
  common_tags = {
    Environment = local.env_name
  }
}