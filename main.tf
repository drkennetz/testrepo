terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">=2.49.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "testhpc" {
  name = "testhpc"
  location = "centralus"
}

resource "azurerm_virtual_network" "testhpc-vnet" {
  name = "testhpc-vnet"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.testhpc.location
  resource_group_name = azurerm_resource_group.testhpc.name
}

resource "azurerm_subnet" "testhpc-subnet" {
  name = "internal"
  resource_group_name = azurerm_resource_group.testhpc.name
  virtual_network_name = azurerm_virtual_network.testhpc-vnet.name
  address_prefixes = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "testhpc-pip" {
  name = "testhpc-pip"
  location = azurerm_resource_group.testhpc.location
  resource_group_name = azurerm_resource_group.testhpc.name
  allocation_method = "Dynamic"
}

resource "azurerm_network_interface" "testhpc-nic" {
  name = "testhpc-nic"
  location = azurerm_resource_group.testhpc.location
  resource_group_name = azurerm_resource_group.testhpc.name

  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.testhpc-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.testhpc-pip.id
  }
}

resource "azurerm_linux_virtual_machine" "testhpc-vm" {
  name = "testhpc-machine"
  resource_group_name = azurerm_resource_group.testhpc.name
  location = azurerm_resource_group.testhpc.location
  size = "Standard_F2"
  admin_username = "adminuser"
  network_interface_ids = [azurerm_network_interface.testhpc-nic.id]
  admin_ssh_key {
    username = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "16.04-LTS"
    version = "latest"
  }
}
