#subscription_id = ""
#client_id       = ""
#client_secret   = ""
#tenant_id       = ""
username        = "paulmao1"
password        = "Xen@123"
subnet_count    = {
    Dev     = 2
    UAT     = 2
    Pro     = 3
    default = 2
}
instance_count   = {
    Dev     = 2
    UAT     = 1
    Pro     = 1
    default = 1
}
instance_size   = {
    Dev     = "Standard_B1s"
    UAT     = "Standard_B1s"
    Pro     = "Standard_B1s"
    default = "Standard_B1s"
}
network_address_space ={
    Dev     = "10.10.0.0/16"
    UAT     = "10.20.0.0/16"
    Pro     = "10.30.0.0/16"
    default = "10.0.0.0/16"
}
tags ={
   Env = "Staging"
  }
