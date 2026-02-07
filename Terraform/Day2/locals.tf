# Stop repeating naming logic.

# Centralize.

locals {
  prefix = "mj"
  env    = "dev"

  vnet_name = "${local.prefix}-${local.env}-vnet"
}

# Why locals?

# Because hardcoded strings across files = maintenance nightmare.

# Professionals centralize naming.
