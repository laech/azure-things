variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
}

variable "prefix" {
  type = string
}

variable "vm_size" {
  default = "standard_b2s"
}

variable "node_count" {
  default = 2
}

variable "kubernetes_version" {
  default = "1.19.7"
}

variable "log_analytics_workspace_id" {
  type = string
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = var.prefix
  location            = var.resource_group.location
  dns_prefix          = var.prefix
  kubernetes_version  = var.kubernetes_version
  node_resource_group = "${var.resource_group.name}-node"
  resource_group_name = var.resource_group.name

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled = true
  }

  default_node_pool {
    name       = var.prefix
    vm_size    = var.vm_size
    node_count = var.node_count
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }
}

# https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-update-metrics
resource "azurerm_role_assignment" "metrics" {
  scope                = azurerm_kubernetes_cluster.default.id
  principal_id         = azurerm_kubernetes_cluster.default.addon_profile[0].oms_agent[0].oms_agent_identity[0].object_id
  role_definition_name = "Monitoring Metrics Publisher"
}

resource "local_file" "kubeconfig" {
  filename        = "kubeconfig"
  content         = azurerm_kubernetes_cluster.default.kube_config_raw
  file_permission = "0600"
}

output "kubelet_identity_object_id" {
  value = azurerm_kubernetes_cluster.default.kubelet_identity[0].object_id
}
