terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
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

variable "subscription_id" {
  type = string
}

variable "location" {
  default = "eastus"
}

variable "vm_size" {
  default = "standard_b2s"
}

variable "node_count" {
  default = 1
}

variable "kubernetes_version" {
  default = "1.19.7"
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

resource "azurerm_resource_group" "default" {
  name     = "things"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  dns_prefix          = azurerm_resource_group.default.name
  kubernetes_version  = var.kubernetes_version
  node_resource_group = "${azurerm_resource_group.default.name}-node"
  resource_group_name = azurerm_resource_group.default.name

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled = true
  }

  default_node_pool {
    name       = azurerm_resource_group.default.name
    vm_size    = var.vm_size
    node_count = var.node_count
  }
}

resource "local_file" "kubeconfig" {
  filename = "kubeconfig"
  content  = azurerm_kubernetes_cluster.default.kube_config_raw
}
