terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate-day14"
    storage_account_name = "sttfstateday14"
    container_name       = "tfstate"
    key                  = "day14.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}