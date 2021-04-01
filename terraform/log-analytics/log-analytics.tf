variable "subscription_id" {
  type = string
}

variable "prefix" {
  type = string
}

variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

resource "random_id" "log_anaylytics_suffix" {
  byte_length = 8
}

resource "azurerm_log_analytics_workspace" "default" {
  name                = "${var.prefix}-${random_id.log_anaylytics_suffix.dec}"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  sku                 = "PerGB2018"
}

resource "azurerm_log_analytics_solution" "default" {
  solution_name         = "ContainerInsights"
  location              = var.resource_group.location
  resource_group_name   = var.resource_group.name
  workspace_resource_id = azurerm_log_analytics_workspace.default.id
  workspace_name        = azurerm_log_analytics_workspace.default.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

output "workspace_id" {
  value = azurerm_log_analytics_workspace.default.id
}
