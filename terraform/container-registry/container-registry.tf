variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
}

variable "prefix" {
  type = string
}

resource "random_id" "container_registry_suffix" {
  byte_length = 4
}

resource "azurerm_container_registry" "default" {
  name                = "${var.prefix}${random_id.container_registry_suffix.dec}"
  sku                 = "basic"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
}

output "login_server" {
  value = azurerm_container_registry.default.login_server
}

output "id" {
  value = azurerm_container_registry.default.id
}
