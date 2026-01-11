# Secure Azure Authentication using GitHub Actions

This project demonstrates how to securely authenticate GitHub Actions
to an Azure subscription using an Azure Service Principal (SPN).

## Objective
- Authenticate GitHub Actions to Azure
- Use Service Principal with least-privilege access
- Verify authentication using Azure CLI
- No Azure resources created (zero cost)

## Technologies Used
- Azure Active Directory
- Azure Service Principal (RBAC)
- GitHub Actions
- Azure CLI

## Workflow
1. Create Azure Service Principal
2. Store credentials as GitHub Secret
3. Authenticate using `azure/login@v1`
4. Run `az account show` to verify access

## Result
Successful GitHub Actions run proving Azure authentication works.

## Notes
- No VMs or Resource Groups are created
- This project focuses only on authentication
