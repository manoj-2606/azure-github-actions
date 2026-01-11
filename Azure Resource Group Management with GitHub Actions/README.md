# Azure Resource Group Provisioning with GitHub Actions

This project demonstrates how to provision an Azure Resource Group
using GitHub Actions by authenticating to Azure with a Service Principal.
It builds on secure Azure authentication and validates the ability
to perform infrastructure-level operations via CI/CD.

---

## Project Overview

The GitHub Actions workflow in this project authenticates to Azure
using a Service Principal and creates a Resource Group through
Azure Resource Manager (ARM). The workflow also verifies that the
Resource Group has been successfully created.

This project focuses on controlled infrastructure changes and does
not deploy any compute, storage, or network resources.

---

## Objectives

- Authenticate GitHub Actions to Azure using a Service Principal
- Create an Azure Resource Group via Azure CLI
- Validate resource creation using ARM APIs
- Maintain minimal cost and low operational risk
- Demonstrate safe infrastructure automation through CI/CD

---

## Technologies Used

- Azure Active Directory
- Azure Service Principal (RBAC)
- Azure Resource Manager (ARM)
- GitHub Actions
- Azure CLI

---

## Repository Structure

```text
azure-github-actions
├── .github/
│   └── workflows/
│       └── azure-login.yml
├── README.md
