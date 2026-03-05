#!/bin/bash
# =============================================================
# DAY 11 — STEP 1: Bootstrap Backend Storage (Run Once)
# Run these commands ONCE manually via Azure CLI
# BEFORE running terraform init
# =============================================================

# -----------------------------------------
# VARIABLES — change suffix to make unique
# -----------------------------------------
LOCATION="centralindia"
BACKEND_RG="rg-day11-tfstate"
BACKEND_SA="stday11tfstate$(date +%s | tail -c 5)"   # unique suffix
BACKEND_CONTAINER="tfstate"

# -----------------------------------------
# Step 1a: Create backend Resource Group
# -----------------------------------------
az group create \
  --name $BACKEND_RG \
  --location $LOCATION

# -----------------------------------------
# Step 1b: Create Storage Account for TF state
# Note: name must be globally unique, 3-24 chars, lowercase only
# -----------------------------------------
az storage account create \
  --name $BACKEND_SA \
  --resource-group $BACKEND_RG \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# -----------------------------------------
# Step 1c: Create blob container for state files
# -----------------------------------------
az storage container create \
  --name $BACKEND_CONTAINER \
  --account-name $BACKEND_SA \
  --auth-mode login

# -----------------------------------------
# Step 1d: Print values (copy these into your pipeline variables)
# -----------------------------------------
echo "=========================================="
echo "COPY THESE INTO YOUR PIPELINE VARIABLES:"
echo "=========================================="
echo "backendResourceGroup   = $BACKEND_RG"
echo "backendStorageAccount  = $BACKEND_SA"
echo "backendContainer       = $BACKEND_CONTAINER"
echo "tfStateKey             = day11.terraform.tfstate"
echo "=========================================="

# =============================================================
# WHY THIS IS SEPARATE FROM TERRAFORM:
# The backend storage account cannot be managed by the same
# Terraform config that uses it as a backend.
# It's a "chicken and egg" problem.
# Best practice: create it once via CLI, never touch it again.
# In real production: this is managed by a separate "bootstrap"
# Terraform workspace owned by platform/infra team.
# =============================================================