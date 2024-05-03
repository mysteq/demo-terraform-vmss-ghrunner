terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.56.0"
    }
  }
  backend "azurerm" {
    subscription_id      = "87e43d6c-337a-44f8-b908-c4b12dd914a9"
    tenant_id            = "2044f836-f4df-477c-a129-cfa16a9c16cd"
    resource_group_name  = "rg-tfstate-01"
    storage_account_name = "tfstateghrunner23525"
    container_name       = "tfstateghrunner23525"
    key                  = "tfstateghrunner23525.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = "ba345d34-f8c3-47ae-bc1c-b45b3e27da21"
  tenant_id       = "bb73082a-b74c-4d39-aec0-41c77d6f4850"
}
