terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0.0"
    }
    docker = {
        source = "kreuzwerker/docker"
        version = "~> 3.0.2"
    }
  }
  required_version = ">= 0.14.9"
}

provider "docker" {
    host    = "npipe:////./pipe/dockerDesktopLinuxEngine"
}

provider "azurerm" {
  subscription_id = "azuresubid"
  features {

  }
}


# Generate a random integer to create a globally unique name
resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

resource "azurerm_resource_group" "rg" {
  name     = "per-dojo"
  location = "North Europe"
}

// doesn't use docker hub anymore, instead pulls from the images in the resource group's private image registry

resource "azurerm_container_registry" "acr" {
  name                = "PerDojoContainerRegistry"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}


resource "docker_image" "apiimage" {
  name = "notesapp"
  build {
    context = "."
    tag     = ["${azurerm_container_registry.acr.login_server}/notesapp:dev"]
    dockerfile = "./Dockerfile"
    build_arg = {
      environment : "dev"
    }
    label = {
      author : "perlh"
    }
  }
}

 resource "null_resource" "docker_push" {
      provisioner "local-exec" {
      command = <<-EOT
        docker push "${azurerm_container_registry.acr.login_server}/notesapp:dev"
      EOT
      }
      depends_on = [ 
        docker_image.apiimage
       ]
    }

resource "azurerm_container_app_environment" "contappenv" {
  name                = "container-app-env"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
}

resource "azurerm_container_app" "example" {
  name                         = "notesappcontainerapp"
  container_app_environment_id = azurerm_container_app_environment.contappenv.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "noteaspp"
      image  = "${azurerm_container_registry.acr.login_server}/notesapp:dev"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  // image should be pushed and available in acr before container is made
  depends_on = [ 
    null_resource.docker_push
   ]

}





