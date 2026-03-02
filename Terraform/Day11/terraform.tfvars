location            = "centralindia"
resource_group_name = "rg-day11-identity"
project_name        = "day11"
environment         = "dev"

# Change the suffix if name is already taken globally
storage_account_name = "stday11app001"

# Key Vault: 3-24 chars, alphanumeric + hyphens
key_vault_name = "kv-day11-001"

tags = {
  project     = "day11"
  environment = "dev"
  managed_by  = "terraform"
  day         = "11"
}
