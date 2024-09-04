terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.0"
    }
  }
  required_version = ">= 0.14.9"
}
provider "azurerm" {
  features {}
}

# Generate a random integer to create a globally unique name
resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

resource "azurerm_resource_group" "rg" {
  name     = "per-dojo"
  location = "West Europe"
}

// doesn't use docker hub anymore, instead pulls from the images in the resource group's private image registry

resource "azurerm_container_registry" "acr" {
  name                = "nameofcontainerregistry"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}



resource "azurerm_container_group" "ctg" {
  name                = "notesapp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_address_type = "Public"
  dns_name_label  = "perlhwa"
  os_type         = "Linux"

  image_registry_credential {
    username = "yourregistryusername"
    password = "yourregistrypassword"
    server = "yourregistryserver"
  }

  container {
    name   = "notesapp-container"
    image  = "containernameinazure.azurecr.io/somefolder/someimage"
    cpu    = "1"
    memory = "1"

    ports {
      port     = 80
      protocol = "TCP"

    }
  }
}