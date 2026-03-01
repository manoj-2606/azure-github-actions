locals {
  project = "rg-demo-test"
  env     = var.environment
  region  = "centralindia"

  name_refix = "${local.project}-${local.env}-centralindia"
}
