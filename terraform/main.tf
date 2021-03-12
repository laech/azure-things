terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.50.0"
    }
  }
  backend "remote" {
    organization = "lae"
    workspaces {
      name = "azure-things"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  network_address_space = "172.16.0.0/16"
  subnet_address_prefixes = cidrsubnets(local.network_address_space, 1, 1)
  private_subnet_address_prefix = local.subnet_address_prefixes[0]
  public_subnet_address_prefix = local.subnet_address_prefixes[1]
}

resource "azurerm_resource_group" "default" {
  name = "things"
  location = "australiasoutheast"
}

resource "azurerm_virtual_network" "default" {
  name = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  address_space = [local.network_address_space]
}

resource "azurerm_subnet" "private" {
  name = "${azurerm_virtual_network.default.name}-private"
  resource_group_name = azurerm_resource_group.default.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes = [local.private_subnet_address_prefix]
}

resource "azurerm_kubernetes_cluster" "default" {
  name = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix = azurerm_resource_group.default.name

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name = azurerm_resource_group.default.name
    node_count = 1
    vm_size = "standard_d2_v2"
    vnet_subnet_id = azurerm_subnet.private.id
  }
}

resource "local_file" "kubeconfig" {
  filename = "kubeconfig"
  content = azurerm_kubernetes_cluster.default.kube_config_raw
}
