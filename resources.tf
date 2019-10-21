##################################################################################
# PROVIDERS
##################################################################################

provider "azurerm" {
  version = "=1.34.0"
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

##################################################################################
# DATA
##################################################################################



##################################################################################
# RESOURCES
##################################################################################

# RESOURCE GROUP #
resource "azurerm_resource_group" "ResourceGroup" {
  name     = "${var.prefix}-Resources-${terraform.workspace}"
  location =  "West US"
}

#AvailabilitySet use Managed Disk using managed feature# 
resource "azurerm_availability_set" "av" {
  name                = "AvailabilitySet1"
  managed             = "true"
  location            = "${azurerm_resource_group.ResourceGroup.location}"
  resource_group_name = "${azurerm_resource_group.ResourceGroup.name}"
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
  name = "${terraform.workspace}-Subnet-${count.index+1}"
  resource_group_name  = "${azurerm_resource_group.ResourceGroup.name}"
  virtual_network_name = "${azurerm_virtual_network.network.name}"
  address_prefix       = "${cidrsubnet(var.network_address_space[terraform.workspace], 8, count.index + 1)}"
}

#Assign Public IP#
resource "azurerm_public_ip" "mypublic" {
  name                = "PublicIp1"
  location            = "${azurerm_resource_group.ResourceGroup.location}"  
  resource_group_name = "${azurerm_resource_group.ResourceGroup.name}"
  allocation_method   = "Static"
  }

#Load Balancer#
resource "azurerm_lb" "azure-lb" {
  name                = "azure-lb"
  location            = "${azurerm_resource_group.ResourceGroup.location}"
  resource_group_name = "${azurerm_resource_group.ResourceGroup.name}"

  frontend_ip_configuration {
    name                 = "FrontEnd"
    public_ip_address_id = "${azurerm_public_ip.mypublic.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "azure-lb-pool" {
  resource_group_name = "${azurerm_resource_group.ResourceGroup.name}"
  loadbalancer_id     = "${azurerm_lb.azure-lb.id}"
  name                = "azure-lb-pool"
}

#Nested group: azure-lb-rule&&azure-lb-probe#
#refer to kb: https://www.hashicorp.com/blog/hashicorp-terraform-0-12-preview-for-and-for-each#

resource "azurerm_lb_rule" "azure-lb-rule" {
  resource_group_name            = "${azurerm_resource_group.ResourceGroup.name}"
  loadbalancer_id                = "${azurerm_lb.azure-lb.id}"
  name                           = "${var.protocols[0]}"
  protocol                       = "tcp"
  frontend_port                  = "${var.ports[0]}"
  backend_port                   = "${var.ports[0]}"
  frontend_ip_configuration_name = "FrontEnd"
  enable_floating_ip             = false
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.azure-lb-pool.id}"
  idle_timeout_in_minutes        = 5
  probe_id                       = "${azurerm_lb_probe.azure-lb-probe.id}"
  depends_on                     = ["azurerm_lb_probe.azure-lb-probe"]
}

resource "azurerm_lb_probe" "azure-lb-probe" {
  resource_group_name = "${azurerm_resource_group.ResourceGroup.name}"
  loadbalancer_id     = "${azurerm_lb.azure-lb.id}"
  name                = "${var.protocols[0]}"
  protocol            = "tcp"
  port                = "${var.ports[0]}"
  interval_in_seconds = 5
  number_of_probes    = 2
}
resource "azurerm_lb_rule" "azure-lb-rule-1" {
  resource_group_name            = "${azurerm_resource_group.ResourceGroup.name}"
  loadbalancer_id                = "${azurerm_lb.azure-lb.id}"
  name                           = "${var.protocols[1]}"
  protocol                       = "tcp"
  frontend_port                  = "${var.ports[1]}"
  backend_port                   = "${var.ports[1]}"
  frontend_ip_configuration_name = "FrontEnd"
  enable_floating_ip             = false
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.azure-lb-pool.id}"
  idle_timeout_in_minutes        = 5
  probe_id                       = "${azurerm_lb_probe.azure-lb-probe-1.id}"
  depends_on                     = ["azurerm_lb_probe.azure-lb-probe-1"]
}

resource "azurerm_lb_probe" "azure-lb-probe-1" {
  resource_group_name = "${azurerm_resource_group.ResourceGroup.name}"
  loadbalancer_id     = "${azurerm_lb.azure-lb.id}"
  name                = "${var.protocols[1]}"
  protocol            = "tcp"
  port                = "${var.ports[1]}"
  interval_in_seconds = 5
  number_of_probes    = 2
}


# SECURITY GROUPS #
# Two subnets has the same NSG# 
resource "azurerm_network_security_group" "nginx-sg" {
  name                = "nginx-sg"
  location            = "${azurerm_resource_group.ResourceGroup.location}"  
  resource_group_name = "${azurerm_resource_group.ResourceGroup.name}"
  security_rule {
        name                       = "${var.protocols[0]}"
        priority                   = 1000
        direction                  = "Inbound"
        protocol                   = "Tcp"
        source_port_range          = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
        destination_port_range     = "${var.ports[0]}"
        access                     = "Allow"
    }
    security_rule {
        name                       = "${var.protocols[1]}"
        priority                   = 1001
        direction                  = "Inbound"
        protocol                   = "Tcp"
        source_port_range          = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
        destination_port_range     = "${var.ports[1]}"
        access                     = "Allow"
    }
}
resource "azurerm_subnet_network_security_group_association" "nginx-sg" {
  count          = var.subnet_count[terraform.workspace]
  subnet_id      = "${azurerm_subnet.subnet[count.index].id}"
  network_security_group_id = "${azurerm_network_security_group.nginx-sg.id}"
}


# ROUTING #
#Two subnets has the same routing table#
resource "azurerm_route_table" "rta-subnet" {
  name                = "myroutetable"
  resource_group_name = "${azurerm_resource_group.ResourceGroup.name}"
  location            = "${azurerm_resource_group.ResourceGroup.location}"
  route {
    name = "To-premise"
    address_prefix = "172.16.0.0/16"
    next_hop_type  = "vnetlocal"
  }
}

resource "azurerm_subnet_route_table_association" "rta-subnet" {
  count          =  var.subnet_count[terraform.workspace]
  subnet_id      = "${azurerm_subnet.subnet[count.index].id}"
  route_table_id = "${azurerm_route_table.rta-subnet.id}"
}

#Network Interface#
resource "azurerm_network_interface" "nic" {
  count               = var.instance_count[terraform.workspace]
  name                = "${azurerm_subnet.subnet[count.index].name}-nic"
  location            = "${azurerm_resource_group.ResourceGroup.location}"      
  resource_group_name = "${azurerm_resource_group.ResourceGroup.name}"
   ip_configuration {
     name = "testconfigure--${count.index}"
     subnet_id = "${azurerm_subnet.subnet[count.index%var.subnet_count[terraform.workspace]].id}"
     private_ip_address_allocation = "Dynamic"
     load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.azure-lb-pool.id}"]
   }
}

#INSTANCE#
#The two VM must be in the same AvailabilitySet for LB#
resource "azurerm_virtual_machine" "Azure-VM" {
  count                 = var.instance_count[terraform.workspace]
  name                  = "Azure-VM-${count.index}"
  location              = "${azurerm_resource_group.ResourceGroup.location}"
  resource_group_name   = "${azurerm_resource_group.ResourceGroup.name}"
  network_interface_ids = ["${azurerm_network_interface.nic[count.index].id}"]
  vm_size               = "Standard_B1s"
  availability_set_id   =  "${azurerm_availability_set.av.id}"
  

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "MyLinux-${count.index}"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  provisioner "remote-exec" {
    connection {
      host        =  "${azurerm_public_ip.mypublic.ip_address}"
      user        = "${var.username}"
      password    = "${var.password}"
      }

    inline = [
      "sudo apt-get -y install nginx",
      "sudo service nginx start",
      "echo '<html><head><title>Blue Team Server</title></head><body style=\"background-color:#1F778D\"><p style=\"text-align: center;\"><span style=\"color:#FFFFFF;\"><span style=\"font-size:28px;\">Blue Team</span></span></p></body></html>' | sudo tee /usr/share/nginx/html/index.html"
    ]
  }

  provisioner "remote-exec" {
    connection {
      host        =  "${azurerm_public_ip.mypublic.ip_address}"
      user        = "${var.username}"
      password    = "${var.password}"
      }

    inline = [
      "sudo apt-get -y install nginx",
      "echo '<html><head><title>Blue Team Server</title></head><body style=\"background-color:#1F778D\"><p style=\"text-align: center;\"><span style=\"color:#FFFFFF;\"><span style=\"font-size:28px;\">Blue Team-${count.index}</span></span></p></body></html>' | sudo tee /var/www/html/index.nginx-debian.html",
      "sudo service nginx start"
    ]
  }
  tags = {
    environment = "staging"
    }  
}