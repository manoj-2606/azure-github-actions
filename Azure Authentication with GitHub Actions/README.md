# Azure Authentication with GitHub Actions

This project demonstrates how to securely authenticate GitHub Actions
to an Azure subscription using an Azure Service Principal (SPN).
The focus of this project is Azure identity and access integration
with CI/CD pipelines, without provisioning any cloud resources.

---

## Project Overview

The workflow in this repository validates that GitHub Actions can
successfully authenticate to Azure using role-based access control (RBAC).
Authentication is verified by executing Azure CLI commands from
a GitHub-hosted runner.

This project is intentionally scoped to authentication only and does
not create or modify any Azure resources.

---

## Objectives

- Authenticate GitHub Actions to an Azure subscription
- Use an Azure Service Principal with least-privilege access
- Securely store credentials using GitHub Secrets
- Verify authentication using Azure CLI
- Ensure zero Azure resource cost during execution

---

## Technologies Used

- Azure Active Directory
- Azure Service Principal (RBAC)
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
