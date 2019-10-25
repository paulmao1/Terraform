subscription_id = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
client_id       = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
client_secret   = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
tenant_id       = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
username        = "YYYYYY"
password        = "YYYYYY"
environment_tag = "Azure"
subnet_count    = {
    Dev = 2
    UAT = 2
    Pro = 3
}
instance_count   = {
    Dev = 1
    UAT = 1
    Pro = 1
}
instance_size   = {
    Dev = "Standard_B1s"
    UAT = "Standard_B1s"
    Pro = "Standard_B1s"
}
network_address_space ={
    Dev = "10.10.0.0/16"
    UAT = "10.20.0.0/16"
    Pro = "10.30.0.0/16"
}
