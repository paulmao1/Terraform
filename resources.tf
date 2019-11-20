##################################################################################
# PROVIDERS
##################################################################################

provider "azurerm" {
  version = "=1.34.0"
#  subscription_id = "${var.subscription_id}"
#  client_id       = "${var.client_id}"
#  client_secret   = "${var.client_secret}"
#  tenant_id       = "${var.tenant_id}"
}

##################################################################################
# DATA
##################################################################################
data "template_file" "cloudconfig" {
  template = "${file("${var.cloudconfig_file}")}"
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.cloudconfig.rendered}"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "baz"
  }
}



##################################################################################
# RESOURCES
##################################################################################

# RESOURCE GROUP #
resource "azurerm_resource_group" "ResourceGroup" {
  name     = "${var.prefix}-Resources-${terraform.workspace}"
  location =  "West US"
}

# NETWORKING #
resource "azurerm_virtual_network" "network" {
  name                = "${var.prefix}-Network-${terraform.workspace}"
  location            = "${azurerm_resource_group.ResourceGroup.location}"      
  resource_group_name = "${azurerm_resource_group.ResourceGroup.name}"
  address_space       = ["${var.network_address_space[terraform.workspace]}"]
}

resource "azurerm_subnet" "subnet" {
  count= var.subnet_count[terraform.workspace]
  name = "${terraform.workspace}-Subnet-${count.index}"
  resource_group_name  = "${azurerm_resource_group.ResourceGroup.name}"
  virtual_network_name = "${azurerm_virtual_network.network.name}"
  address_prefix       = "${cidrsubnet(var.network_address_space[terraform.workspace], 8,  count.index + 1)}"
}

#Load Balancer#
module "mylb" {
  source              = "Azure/loadbalancer/azurerm"
  resource_group_name = "${azurerm_resource_group.ResourceGroup.name}"
  location            = "${azurerm_resource_group.ResourceGroup.location}"
  lb_port ={
    http = ["80", "Tcp", "80"]
    ssh  = ["22", "Tcp", "22"]
  }
}


#VM SCALE SETS#
resource "azurerm_virtual_machine_scale_set" "vmss" {
 name                = "${terraform.workspace}-vmscaleset"
 location            = "${azurerm_resource_group.ResourceGroup.location}"
 resource_group_name = "${azurerm_resource_group.ResourceGroup.name}"
 upgrade_policy_mode = "Manual"

sku {
   name     = "Standard_B1s"
   tier     = "Standard"
   capacity = "${var.instance_count[terraform.workspace]}"
 }
storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

storage_profile_os_disk{
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
os_profile {
    computer_name_prefix = "WebLinux"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
    custom_data    =  "${data.template_cloudinit_config.config.rendered}"
  }
os_profile_linux_config {
    disable_password_authentication = false
  }

network_profile {
   name    = "${terraform.workspace}-networkprofile"
   primary = true

   ip_configuration {
     name                                   = "IPConfiguration"
     subnet_id                              = azurerm_subnet.subnet[0].id
     load_balancer_backend_address_pool_ids = ["${module.mylb.azurerm_lb_backend_address_pool_id}"]
     primary = true
   }
 }
 tags = var.tags
}

#Ansible Dynamic Inventory#
#resource "ansible_host" "nginx" {
#    inventory_hostname = azurerm_public_ip.vmss.fqdn
#    groups = ["WebServer"]
#    vars = {
#        ansible_user = "admin"
#    }
#}

#resource "ansible_group" "WebServer" {
#  inventory_group_name = "WebServer"
#  vars = {
#    ansible_user = "paulmao1"
#  }
#}