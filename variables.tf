##################################################################################
# VARIABLES
##################################################################################

#variable "subscription_id" {}
#variable "client_id" {}
#variable "client_secret" {}
#variable "tenant_id" {} 
variable "username"  {}
variable "password"  {}
variable "instance_size" {
    type = map(string)
}
variable "instance_count" {
    type = map(number)
}
variable "network_address_space" {
    type = map(string)
}
variable "subnet_count" {
    type = map(number)
}
variable  "prefix" {
  default = "Terraform"
}
variable "key_name" {
  default = "PaulKeys"
}
variable "cloudconfig_file"{
  description = "The location of the cloud init configuration file."
  default     = "cloud_init.txt"
}
variable "tags"{
  type = map(string)
}
