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

The Helm chart creates external secrets pulled down from tenant's Azure Key Vault. If tenant is configuring RabbitMQ using external Azure Storage Account it will create an External Secret with Storage Account credentials. And by default it will create admin user credentials. Tenants must create these secrets in KeyVault matching `azureSecretName`

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

