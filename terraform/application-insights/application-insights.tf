variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
}

variable "prefix" {
  type = string
}

resource "azurerm_application_insights" "java" {
  name                = "${var.prefix}-java"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  application_type    = "java"
}

output "instrumentation_key_java" {
  value = azurerm_application_insights.java.instrumentation_key
}
