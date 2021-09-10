terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.75.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {
    
  }
}

resource "azurerm_resource_group" "janaweb" {
  location = "eastus"
  name = "Janaweb-Rg1"
}

resource "azurerm_network_security_group" "janaweb" {
  name = "janawebsecuritygroup1"
  location = azurerm_resource_group.janaweb.location
  resource_group_name = azurerm_resource_group.janaweb.name
}

resource "azurerm_network_ddos_protection_plan" "janaweb" {
  name = "globalDDOSrule"
  location = azurerm_resource_group.janaweb.location
  resource_group_name = azurerm_resource_group.janaweb.name
}

resource "azurerm_virtual_network" "janaweb" {
  name = "janawebnetworkpublic"
  location = azurerm_resource_group.janaweb.location
  resource_group_name = azurerm_resource_group.janaweb.name
  address_space = [ "10.0.0.0/16" ]
  dns_servers = ["10.0.0.4","10.0.0.5"]

  ddos_protection_plan {
    id = azurerm_network_ddos_protection_plan.janaweb.id
    enable = "true"
  }
  

  tags = {
    "Env" = "janawebstage"
  }

}
resource "azurerm_subnet" "janaweb" {
  name = "websubnet1"
  resource_group_name = azurerm_resource_group.janaweb.name
  virtual_network_name = azurerm_virtual_network.janaweb.name
  address_prefixes = [ "10.0.1.0/24" ]
  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
}
resource "azurerm_subnet" "janaweb1" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.janaweb.name
  virtual_network_name = azurerm_virtual_network.janaweb.name
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_storage_account" "janaweb" {
  name = "janawebstage001"
  location = azurerm_resource_group.janaweb.location
  resource_group_name = azurerm_resource_group.janaweb.name
  access_tier  = "Hot"
  account_tier = "standard"
  account_replication_type = "LRS"
  tags = {
    "env" = "Stage"
  }
}
resource "azurerm_network_interface" "janaweb" {
  name = "janweb01wv-nic"
  location = azurerm_resource_group.janaweb.location
  resource_group_name = azurerm_resource_group.janaweb.name
  ip_configuration {
    name = "Private"
    subnet_id = azurerm_subnet.janaweb1.id
    private_ip_address_allocation = "Dynamic"

  }
}
resource "azurerm_windows_virtual_machine" "janaweb" {
  name = "janaweb01wv"
  resource_group_name = azurerm_resource_group.janaweb.name
  location = azurerm_resource_group.janaweb.location
  size = "Standarad_DS1_v2"
  admin_username = "j-admin"
  admin_password = "Namashive@82"
  network_interface_ids = [ azurerm_network_interface.janaweb.id, ]
  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}
