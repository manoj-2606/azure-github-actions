# Day 12 — Secure Network Architecture (Enterprise Level)

> RBAC stops privilege escalation. Network isolation stops lateral movement. Both together is a real security posture. Day 12 adds the network layer.

---

## Why This Day Exists

Day 11 gave every identity the minimum permissions it needed — nothing more. But RBAC alone is insufficient. If an attacker steals valid credentials, RBAC limits what they can do. It does not stop them from reaching your services in the first place.

Day 12 adds the second layer: **network isolation**. With public access disabled on Storage and Key Vault, even a valid credential cannot reach those services from the internet. The attacker needs to be inside your private network to even attempt authentication. Combined with RBAC, you now have two independent barriers — credential theft alone is not enough.

This is the network layer of Zero Trust architecture. Assume breach. Make breach useless by ensuring there is nothing reachable from outside even with valid credentials.

This is also not optional in EU cloud environments. GDPR requires that personal data is not publicly accessible. PCI-DSS requires network-isolated environments for payment data. ISO 27001 requires network segmentation and controlled ingress. Finnish companies in finance, healthcare, and SaaS all build exactly this topology. Day 12 is where you build it.

---

## What You Built

```
┌──────────────────────────────────────────────────────────────────────┐
│                        AZURE SUBSCRIPTION                            │
│                                                                      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  rg-day12-centralindia                                        │  │
│  │                                                               │  │
│  │   Hub VNet (10.0.0.0/16)                                      │  │
│  │   └─ hub-subnet (10.0.1.0/24)                                 │  │
│  │          │                                                    │  │
│  │          │  VNet Peering (bidirectional)                      │  │
│  │          │                                                    │  │
│  │   Spoke VNet (10.1.0.0/16)                                    │  │
│  │   ├─ app-subnet  (10.1.1.0/24)  ← NSG: HTTPS from VNet only  │  │
│  │   ├─ data-subnet (10.1.2.0/24)                                │  │
│  │   └─ pe-subnet   (10.1.3.0/24)  ← Private Endpoints live here │  │
│  │          │                                                    │  │
│  │          ├─ Storage Account (public: DISABLED)                │  │
│  │          │  Private Endpoint → 10.1.3.x                       │  │
│  │          │  Private DNS: privatelink.blob.core.windows.net    │  │
│  │          │                                                    │  │
│  │          └─ Key Vault (public: DISABLED)                      │  │
│  │             Private Endpoint → 10.1.3.x                       │  │
│  │             Private DNS: privatelink.vaultcore.azure.net      │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌─────────────────────────────────┐                                │
│  │  rg-tfstate-day12               │                                │
│  │  stday12tfstate → tfstate       │                                │
│  │  └─ day12.terraform.tfstate     │                                │
│  └─────────────────────────────────┘                                │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Folder Structure

```
Day12/
├── goals.txt                          # Learning objectives
├── commands.txt                       # Every command with explanation
├── project-purpose.txt                # Why this project exists
├── README.md                          # This file
├── terraform/
│   ├── main.tf                        # Root module — wires all modules together
│   ├── variables.tf                   # Input variable declarations
│   ├── outputs.tf                     # IPs, resource IDs, DNS info
│   ├── providers.tf                   # AzureRM provider + OIDC config
│   ├── backend.tf                     # Remote state in Azure Storage
│   └── modules/
│       ├── networking/
│       │   ├── main.tf                # Hub VNet, Spoke VNet, Subnets, Peering, NSG
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── storage/
│       │   ├── main.tf                # Storage Account — public access disabled
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── keyvault/
│       │   ├── main.tf                # Key Vault — public access disabled
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── private-endpoints/
│           ├── main.tf                # Private Endpoints + Private DNS Zones
│           ├── variables.tf
│           └── outputs.tf
└── pipelines/
    ├── azure-pipelines.yml            # Main pipeline — plan + apply on push to main
    └── templates/
        ├── terraform-plan.yml         # Reusable: init + fmt + validate + plan
        ├── terraform-apply.yml        # Reusable: apply from saved plan binary
        └── terraform-destroy.yml      # Reusable: destroy with manual approval gate
```

---

## Remote Backend — Same Pattern, Same Reason

Before any Terraform code runs, you bootstrap a dedicated storage account for state. Same discipline as previous days — state lives in its own resource group, isolated from application resources.

```bash
az group create --name rg-tfstate-day12 --location centralindia
az storage account create --name stday12tfstate<unique> --resource-group rg-tfstate-day12 --location centralindia --sku Standard_LRS --min-tls-version TLS1_2
az storage container create --name tfstate --account-name stday12tfstate<unique>
```

If both the application resources and the state storage lived in `rg-day12-centralindia`, a `terraform destroy` or a portal resource group delete would take your state file with it. Your next apply would have no record of what exists in Azure and would attempt to recreate everything — hitting name conflicts on Key Vault soft-delete, storage account naming, and DNS zones. Isolated state prevents this entire class of problem.

---

## Step-by-Step — What You Did and Why

---

### Phase 1 — Hub-and-Spoke Networking Foundation

**Why this architecture:**
Hub-and-Spoke is the enterprise standard Azure topology. The Hub VNet is the central point — it is where you put shared services: DNS resolvers, Azure Firewall, VPN Gateway, monitoring infrastructure. The Spoke VNet is where workloads live — application servers, databases, services. Spokes connect to the Hub via peering. Spokes do not connect to each other directly. All cross-spoke traffic routes through the Hub, giving you a central control point for visibility and security.

Today you built the peering without a central firewall — that comes in more advanced days with AKS. But the topology is established. Adding an Azure Firewall to the hub-subnet later requires no changes to your spoke infrastructure.

**VNet Peering — why it must be bidirectional:**
Peering is not symmetric by default. Creating hub→spoke peering lets hub resources see spoke resources. It does not let spoke resources see hub resources. You must create both directions explicitly: one peering resource from hub to spoke, one from spoke to hub. If you create only one direction, DNS resolution may work but traffic will be dropped on the return path. The symptom is asymmetric connectivity — requests go out but responses never arrive.

The peering options matter:
- `allow_forwarded_traffic = true` — allows traffic that did not originate in this VNet to pass through. Necessary when you add an Azure Firewall or NVA in the hub and route spoke traffic through it.
- `allow_gateway_transit = false` — would allow peered VNets to use this VNet's VPN Gateway. Not configured today — no gateway exists yet.
- `use_remote_gateways = false` — would tell this VNet to use the peered VNet's gateway. Stays false until a gateway is deployed.

**Subnet design — why three subnets in spoke:**
`app-subnet` is where application workloads run. `data-subnet` is where databases or data services run. `pe-subnet` is dedicated exclusively to Private Endpoints. Separating private endpoints into their own subnet lets you apply NSG rules specifically to private endpoint traffic — you can allow HTTPS from `app-subnet` to `pe-subnet` without opening `pe-subnet` to anything else.

---

### Phase 2 — Private Endpoints

**Why private endpoints exist:**
By default, Azure Storage and Azure Key Vault have public endpoints. A URL like `mystorageaccount.blob.core.windows.net` resolves to a public IP and is reachable from anywhere on the internet. Even with RBAC protecting what an authenticated identity can do, an attacker can still attempt authentication, probe the service, and exploit any future misconfiguration or vulnerability.

A Private Endpoint creates a Network Interface Card inside your `pe-subnet` with a private IP — something like `10.1.3.4`. The storage account gets a private IP inside your VNet. You then disable the public endpoint entirely with `public_network_access_enabled = false`. The storage account is now completely unreachable from the internet. An attacker with valid credentials cannot authenticate because they cannot reach the service.

Traffic from your VMs to storage never leaves the Azure backbone network. It goes through the private endpoint NIC inside your VNet, through Azure's internal routing, to the storage service. No internet transit. No exposure to internet-based attacks. This is what "private-only access" means in practice.

**Why Private DNS Zones are mandatory:**
This is the part most engineers get wrong the first time. After creating the private endpoint, your VM resolves `mystorageaccount.blob.core.windows.net` using public DNS. Public DNS returns the public IP of the storage account. Your VM connects to the public IP. The private endpoint is completely bypassed. You are not using the private endpoint at all despite creating it.

Private DNS Zones solve this. You create a zone named `privatelink.blob.core.windows.net` and Azure automatically registers an A record pointing `mystorageaccount` to `10.1.3.4`. You link the zone to your VNet. Now when your VM queries `mystorageaccount.blob.core.windows.net`, your VNet's DNS returns `10.1.3.4` instead of the public IP. Traffic flows through the private endpoint as intended.

Without the DNS zone link: private endpoint exists, private IP exists, but DNS returns public IP. Private endpoint is wasted. This is a silent failure — everything deploys successfully but private endpoint never gets used.

You link the DNS zones to both Hub and Spoke VNets because resources in either VNet need to resolve private IPs correctly. A zone linked only to Spoke means Hub resources still get public IPs back from DNS.

---

### Phase 3 — NSG Hardening

**Why NSG rules on top of private endpoints:**
VNet Peering allows all traffic between peered VNets by default. Once Hub and Spoke are peered, a resource in hub-subnet can reach anything in any spoke subnet. That is too permissive. NSGs add subnet-level firewall rules that control exactly which traffic is allowed and which is denied.

`app-subnet` NSG: Allow HTTPS inbound from VNet address space, deny all other inbound. Application workloads receive legitimate traffic but nothing else can initiate connections to them.

`pe-subnet` NSG: Allow HTTPS inbound from `app-subnet` CIDR only, deny all other inbound. Private endpoints can only be reached from the application tier — not from data-subnet, not from hub, not from any other source. Even within your own VNet, access to private endpoints is explicitly controlled.

This is the principle of least privilege applied at the network layer, not just the identity layer. An identity without the right RBAC role cannot authenticate. An identity on the wrong subnet cannot even reach the service. Two independent controls, both must be satisfied.

**NSG rule evaluation:**
Rules are evaluated by priority — lower number means higher priority. A deny rule at priority 100 beats an allow rule at priority 200. Azure has default rules at priority 65000+ that you cannot modify. Your explicit rules must have priorities below 65000 and ordered to match intended policy.

---

### Phase 4 — Pipeline Architecture

**Why pure Bash tasks instead of TerraformTaskV4:**
Day 12 hit a critical real-world problem during pipeline setup. `TerraformInstaller@1` was resolving "latest" to a non-existent Terraform version and the binary was never placed in the toolcache. `TerraformTaskV4@4` uses its own toolcache path and does not see binaries installed manually by bash. The two approaches conflict.

The fix was to abandon both Azure DevOps Terraform tasks entirely and use pure `Bash@3` tasks throughout. Download the Terraform binary directly from HashiCorp releases, move it to `/usr/local/bin`, and run every Terraform command as a bash script. No dependency on the Azure DevOps task ecosystem. Full control over the binary version. This is more reliable and more transparent than any marketplace task.

**OIDC token must be explicitly passed:**
`ARM_USE_OIDC=true` tells Terraform to use token exchange. But it does not automatically obtain the token. The `AzureCLI@2` task with `addSpnToEnvironment: true` fetches the OIDC token from the service connection and injects it as `$idToken`. You must then explicitly set `ARM_OIDC_TOKEN=$idToken` in the environment block of every subsequent Terraform task. Without this, Terraform falls back to Azure CLI authentication which fails for service principals in a pipeline context.

---

## Errors Hit — and Why They Make You Better

Every error below is a real failure encountered during Day 12. Each one teaches something you cannot learn from documentation.

| Error | Root Cause | Fix | Lesson |
|---|---|---|---|
| `ARM_SUBSCRIPTION_ID` already defined | Copy-paste duplication in `env:` block | Remove duplicate line | Read your YAML before running |
| Variable group not found | YAML said `day12-vars`, ADO had `Terraform-day12-vars` | Match names exactly | Names in YAML must match ADO exactly — case sensitive |
| Environment not found | Deployment jobs need pre-existing environments | Create environments manually in ADO | Deployment environments do not auto-create |
| Service connection not found | YAML referenced `day12-service-connection`, actual name was `azure-service-connection` | Match service connection name exactly | Same discipline as variable groups |
| Terraform binary ENOENT | `TerraformInstaller@1` resolved "latest" to non-existent version | Replace with direct bash install from HashiCorp | Never trust "latest" in pipelines |
| TerraformTaskV4 ignores manual install | Task has its own toolcache, ignores `/usr/local/bin` | Replace all TerraformTaskV4 with Bash@3 | Pick one approach — tasks and manual install conflict |
| Working directory not found | `TF_WORKING_DIR` was `terraform` but repo path was `Terraform/Day12/terraform` | Set full path, add `checkout: self` to every stage | Agent checks out full repo — path must be exact |
| `az login` error in pipeline | OIDC token not passed to Terraform | Add `AzureCLI@2` with `addSpnToEnvironment: true` before every init | `ARM_USE_OIDC=true` alone is insufficient |
| `private_endpoint_network_policies_enabled` deprecated | Old attribute name from azurerm 2.x | Change to `private_endpoint_network_policies = "Disabled"` | Check provider changelog when upgrading |
| `bypass = ["AzureServices"]` wrong type for Key Vault | Key Vault expects string, Storage expects list | Remove brackets — `bypass = "AzureServices"` | Same concept, different schema — read the docs per resource |
| `https_traffic_only_enabled` not expected | Attribute removed in azurerm 3.x — HTTPS now enforced by default | Remove the attribute | Provider upgrades silently remove deprecated attributes |
| 403 key-based authentication not permitted | `shared_access_key_enabled = false` blocks the Terraform provider itself | Remove attribute — public access disabled is sufficient | Terraform provider uses key auth internally |
| Module not installed — run terraform init first | Ran `terraform state rm` without init | Always run init with backend config before state commands | State commands need backend connection — init is mandatory |

These are not tutorial errors. These are production debugging errors. You know how to fix every one of them because you fixed them live.

---

## Key Concepts You Can Now Answer

**Why Hub-and-Spoke over flat VNet design:**
A flat VNet puts everything in one address space with no routing control. Hub-and-Spoke gives you a central control point for all inter-workload traffic. Adding an Azure Firewall in the hub means all traffic between spokes passes through a firewall without any changes to spoke infrastructure. Hub-and-Spoke also scales — you add new spokes without modifying existing ones.

**What a private endpoint actually is:**
A Network Interface Card created inside your subnet, assigned a private IP from your subnet's address range, connected to an Azure PaaS service. The service is accessible via that NIC's private IP from within your VNet. The public IP becomes optional and in this project explicitly disabled.

**Why private DNS zones are not optional:**
Without them, DNS resolves service hostnames to public IPs. Your application connects to the public endpoint, not the private one. The private endpoint is deployed but never used. Public access disabled means the connection fails. The result is an application that cannot reach its storage or Key Vault despite the private endpoint existing — a silent misconfiguration that costs hours to diagnose the first time.

**NSG priority evaluation:**
Lower number wins. A deny at 100 blocks traffic an allow at 200 would permit. Azure default rules sit at 65000+ and cannot be overridden. Explicit rules must be below 65000. Overlapping rules at the same priority cause a conflict error — priorities must be unique per direction per NSG.

**What `allow_forwarded_traffic` does in VNet peering:**
Without it, only traffic originating in the peered VNet passes through. Traffic that entered the VNet from elsewhere — forwarded by an NVA or firewall — is dropped. Enabling it is necessary when you add a central firewall in the Hub that forwards traffic between spokes. Setting it now, before the firewall exists, means you do not have to modify peering configuration when you add the firewall later.

**Why disable public network access instead of relying on RBAC alone:**
Defence in depth. RBAC controls what authenticated identities can do. Network isolation controls who can reach the service at all. A misconfigured RBAC role grants accidental access — but if the service is unreachable from the internet, that misconfiguration cannot be exploited externally. Two independent controls mean one failure does not equal a breach.

---

## Validation Queries After Apply

```bash
# Verify Storage public access is disabled
az storage account show --name <storage-name> --resource-group rg-day12-centralindia --query "publicNetworkAccess"

# Verify Key Vault public access is disabled
az keyvault show --name <kv-name> --resource-group rg-day12-centralindia --query "properties.publicNetworkAccess"

# Verify private endpoint private IP
az network private-endpoint show --name pe-storage --resource-group rg-day12-centralindia --query "customDnsConfigs[0].ipAddresses"

# Verify DNS zone A records exist
az network private-dns record-set a list --zone-name privatelink.blob.core.windows.net --resource-group rg-day12-centralindia --output table

# Verify VNet peering is Connected
az network vnet peering list --vnet-name hub-vnet --resource-group rg-day12-centralindia --output table

# Verify DNS zones are linked to VNets
az network private-dns link vnet list --zone-name privatelink.blob.core.windows.net --resource-group rg-day12-centralindia --output table
```

---

## Where You Stand After Day 12

Skills confirmed through this project:
- Hub-and-Spoke VNet topology
- Bidirectional VNet Peering with correct options
- Private Endpoints for PaaS services
- Private DNS Zone creation and VNet linking
- NSG subnet-level hardening with priority-ordered rules
- Zero public exposure architecture
- Production pipeline debugging — 13 real errors resolved

Completed skill stack after Day 12: Terraform core, remote state, modules, dynamic logic, lifecycle management, CI/CD with Azure DevOps, OIDC authentication, RBAC and Managed Identities, private networking, DNS resolution, secure storage and Key Vault access, and now — observability on Day 13.

If you can confidently build and explain this topology, you are no longer junior-level. You are cloud infrastructure capable.