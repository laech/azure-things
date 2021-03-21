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

variable "name" {
  default = "things"
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
  name     = var.name
  location = var.location
}

resource "random_id" "container_registry_suffix" {
  byte_length = 4
}

resource "azurerm_container_registry" "default" {
  name                = "${var.name}${random_id.container_registry_suffix.dec}"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  sku                 = "basic"
}

resource "random_id" "log_anaylytics_suffix" {
  byte_length = 8
}

resource "azurerm_log_analytics_workspace" "default" {
  name                = "${var.name}-${random_id.log_anaylytics_suffix.dec}"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_log_analytics_solution" "default" {
  solution_name         = "ContainerInsights"
  location              = azurerm_resource_group.default.location
  resource_group_name   = azurerm_resource_group.default.name
  workspace_resource_id = azurerm_log_analytics_workspace.default.id
  workspace_name        = azurerm_log_analytics_workspace.default.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = var.name
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
    name       = var.name
    vm_size    = var.vm_size
    node_count = var.node_count
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.default.id
    }
  }
}

# https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-update-metrics
resource "azurerm_role_assignment" "metrics" {
  scope                = azurerm_kubernetes_cluster.default.id
  principal_id         = azurerm_kubernetes_cluster.default.addon_profile[0].oms_agent[0].oms_agent_identity[0].object_id
  role_definition_name = "Monitoring Metrics Publisher"
}

resource "azurerm_application_insights" "java" {
  name                = "${var.name}-java"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  application_type    = "java"
}

resource "local_file" "kubeconfig" {
  filename = "kubeconfig"
  content  = azurerm_kubernetes_cluster.default.kube_config_raw
}

output "instrumentation_key_java" {
  value = azurerm_application_insights.java.instrumentation_key
}

output "container_registry_login_server" {
  value = azurerm_container_registry.default.login_server
}
