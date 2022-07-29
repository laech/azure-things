terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.50.0"
    }
  }
  cloud {
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

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

resource "azurerm_resource_group" "default" {
  name     = var.name
  location = var.location
}

module "container_registry" {
  source         = "./container-registry"
  prefix         = var.name
  resource_group = azurerm_resource_group.default
}

module "log_analytics" {
  source         = "./log-analytics"
  prefix         = var.name
  resource_group = azurerm_resource_group.default
}

module "kubernetes" {
  source                     = "./kubernetes"
  prefix                     = var.name
  resource_group             = azurerm_resource_group.default
  log_analytics_workspace_id = module.log_analytics.workspace_id
}

module "application_insight" {
  source         = "./application-insights"
  prefix         = var.name
  resource_group = azurerm_resource_group.default
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = module.container_registry.id
  principal_id         = module.kubernetes.kubelet_identity_object_id
  role_definition_name = "AcrPull"
}
