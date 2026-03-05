terraform {
  backend "azurerm" {
    # These values are passed in by the pipeline using -backend-config flags
    # so no hardcoded values sit in this file
    # Pipeline command:
    #   terraform init \
    #     -backend-config="resource_group_name=$BACKEND_RESOURCE_GROUP" \
    #     -backend-config="storage_account_name=$BACKEND_STORAGE_ACCOUNT" \
    #     -backend-config="container_name=$BACKEND_CONTAINER" \
    #     -backend-config="key=day12.terraform.tfstate"
  }
}
