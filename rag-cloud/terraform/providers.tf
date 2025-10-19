terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 4.49.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.9.0"
}
  
provider "azurerm" {
    features {}
}

provider "azapi" {}