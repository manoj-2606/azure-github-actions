terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-day11-tfstate"
    storage_account_name = "stday11tfstate0534"
    container_name       = "tfstate"
    key                  = "day11.terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  use_oidc = true
}
