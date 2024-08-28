terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "groupA" {
  name = "example-resource"
  location = "East US"
}

resource "azurerm_virtual_network" "netty" {
  name = "net1"
  location = azurerm_resource_group.groupA.location
  resource_group_name = azurerm_resource_group.groupA.name
  address_space = ["10.0.0.0/29"]
}

resource "azurerm_subnet" "subnetty" {
  name = "subnet1"
  resource_group_name = azurerm_resource_group.groupA.name
  virtual_network_name = azurerm_virtual_network.netty.name
  address_prefixes = ["10.0.0.0/29"]
}

resource "azurerm_public_ip" "pub" {
  name = "public_ip"
  location = azurerm_resource_group.groupA.location
  resource_group_name = azurerm_resource_group.groupA.name
  allocation_method = "Static"
}

resource "azurerm_network_interface" "nic" {
  name = "NIC-1"
  location = azurerm_resource_group.groupA.location
  resource_group_name = azurerm_resource_group.groupA.name
  
  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.subnetty.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pub.id
  }
}

resource "azurerm_virtual_machine" "VM" {
  name = "Test-VM"
  location = azurerm_resource_group.groupA.location
  resource_group_name = azurerm_resource_group.groupA.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size = "Standard_DS1_v2"
  
  storage_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "18.04-LTS"
    version = "latest"
  }
  
  storage_os_disk {
    name = "diskket"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  
  os_profile {
    computer_name = "e.g. hostname"
    admin_username = "e.g. username"
    admin_password = "example@password"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
  
  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y && sudo apt upgrade -y",
      "sudo apt install git nodejs npm -y"
    ]
    
    connection {
      type = "ssh"
      host = azurerm_public_ip.pub.ip_address
      user = "e.g. username"
      password = "e.g. passwd"
    }
  }

}
