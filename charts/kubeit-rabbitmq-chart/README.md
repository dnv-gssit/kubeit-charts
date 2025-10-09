# kubeit-rabbitmq-chart

A Helm chart for deploying RabbitMQ in Kubernetes, customized for KubeIT environments.

## Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Values](#values)
- [Contributing](#contributing)
- [License](#license)

## Introduction

This Helm chart deploys a RabbitMQ cluster in Kubernetes. It supports advanced configurations such as persistent storage, custom user management, and integration with Azure Key Vault for secrets management. The chart is designed to work seamlessly with KubeIT environments.

## Features

- Deploy RabbitMQ with customizable replicas and resource limits.
- Support for persistent storage using Azure File Share or AKS built-in storage classes.
- Configurable RabbitMQ queues, users, and permissions.
- Integration with Azure Key Vault for secrets management.
- Optional creation of Kubernetes Service Accounts and Virtual Services.
- Environment-specific configurations for interal DNS and cluster settings.

## External Secrets

The Helm chart creates external secrets pulled down from tenant's Azure Key Vault. If tenant is configuring RabbitMQ using external Azure Storage Account it will create an External Secret with Storage Account credentials. And by default it will create admin user credentials. Tenants must create these secrets in KeyVault matching `azureSecretName`: `rabbitmq-admin-user` and `rabbitmq-admin-pass`

## Storage

Tenants have the option (recommended) to attach external Storage Account to RabbitMQ cluster. To reference the external account use `nodeStageSecretRef ` in PersistenceVolume with credentials of the Storage Account `azurestorageaccountname` and `azurestorageaccountkey`. When attaching a FileShare the share must pre-exist and define the name in `Values.peristentVolume.csi.volumeAttributes.shareName`

Using an in-built Storage Class to provision a volume will auto-create the Storage Account and for e.g. FileShare in the same subscription as KubeIT cluster (this approach is not recommnended since tenant's will not have visibility on the FileShare)

## Requirements

- Kubernetes 1.21+
- Helm 3.0+
- Azure Key Vault (for secrets management)
- Azure CSI Driver (if using Azure File Share for persistent storage or in built storage classes)

## Installation

1. Add the Helm repository (if applicable):
   ```bash
   helm repo add kubeit https://example.com/helm-charts
   helm repo update

2. ArgoCD application
    ```bash
      project: tenant2
      source:
         repoURL: https://github.com/dnv-gssit/kubeit-charts.git
         path: charts/kubeit-rabbitmq-chart
         targetRevision: feature/rabbitmq-chart
      helm:
         values: |
            env: dev
            region: westeurope
            dnsDomain: "kubeit.dnv.com"
            internalDnsDomain: "kubeit-int.dnv.com"
            clusterSubdomain: "dev001"
            clusterColour: "blue"
            ingressType: "internal"
            shortRegion: we
            tenantName: tenant2
            targetRevision: feature/rabbitmq-chart
            repoURL: https://github.com/dnv-gssit/kubeit-charts.git
            networkPlugin: azure
            tenantMultiRegion: true
            managementNamespace: "management-tenant2"
      destination:
      server: https://kubernetes.default.svc
      namespace: standard
      syncPolicy:
      automated:
         prune: true
         selfHeal: true
      syncOptions:
         - Validate=true
         - CreateNamespace=false
         - PrunePropagationPolicy=foreground
         - PruneLast=false
      retry:
         limit: 2
         backoff:
            duration: 5s
            factor: 2
            maxDuration: 1m

## TLS Cert

Create a TLS cert on Azure Key vault  to encrypt  traffic between client and RabbitMQ cluster.

It must be in PEM format
The certificate's SAN must contain:

- `*.<RabbitMQ cluster name>-nodes.<namespace>.svc.<K8s cluster domain name>`
- `<RabbitMQ cluster name>.<namespace>.svc.<K8s cluster domain name>`

The Subject should be `CN=<host-of-rabbitmq-cluster>` For example. `CN=rabbitmq-tenant2-rabbitmq-prod.<colour>.<region>.kubeit-int.dnv.com`
Ref: https://www.rabbitmq.com/kubernetes/operator/using-operator#one-way-tls

## Rabbitmq Default User Credentials

When trying to store the default user credentials in Azure KV. KV does not support multi-line secret directly from portal.
You must store the secret contents in a .txt file like this:

secretfile.txt
```
default_user=admin
default_pass=admin
```

Create the secret via Azure CLI:
```
az keyvault secret set --vault-name "<your-keyvault-name>" --name "default-test-user-creds" --file "secretfile.txt"
```
