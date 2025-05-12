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
    - name: rabbitmq
      type: helm
      autosync: true
      namespace: standard
      ignoreRegionStructure: true
      repoURL: https://github.com/dnv-gssit/kubeit-charts.git
      targetRevision: feature/rabbitmq-chart
