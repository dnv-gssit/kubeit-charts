# kubeit-rabbitmq-chart

A Helm chart for deploying RabbitMQ in Kubernetes, customized for KubeIT environments.

## Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [Workload Identity](#workload-identity)
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

## Workload Identity

Instead of mounting the Azure File Share with a storage account key (the default `nodeStageSecretRef` flow), the chart can use [Azure Workload Identity](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview) so the RabbitMQ pods authenticate to the file share with a federated token. This removes the need to store the storage account key as a Kubernetes secret and is the recommended approach when the AKS cluster has the OIDC issuer and workload identity enabled.

Workload Identity is **opt-in and backwards compatible** — when `persistentVolume.workloadIdentity.enabled` is `false` (the default) the chart keeps using the account-key flow. It works for both static provisioning (`persistentVolume.static.enabled: true`) and dynamic provisioning via the StorageClass.

### How it works

When `persistentVolume.workloadIdentity.enabled` is `true`:

- The chart adds `clientID` to the CSI `volumeAttributes` (static PV) or StorageClass `parameters` (dynamic) and omits the `nodeStageSecretRef`.
- The RabbitMQ service account (`serviceAccount.name`, default `rabbitmq-sa`) is annotated with the managed identity `client-id` and `tenant-id`, and the RabbitMQ pods run under it.
- Optionally, setting `persistentVolume.workloadIdentity.mountWithWorkloadIdentityToken: true` mounts the share with a workload identity token only — no storage account key is retrieved at all (requires Azure File CSI driver **v1.35.0+** and SMB OAuth enabled on the storage account).

### Configuration

```yaml
serviceAccount:
  create: true
  name: rabbitmq-sa
  annotations:
    azure.workload.identity/client-id: <MANAGED_IDENTITY_CLIENT_ID>
    azure.workload.identity/tenant-id: <TENANT_ID>

persistentVolume:
  external: true
  storageAccount: <STORAGE_ACCOUNT_NAME>   # required for dynamic provisioning with WI
  workloadIdentity:
    enabled: true
    clientID: <MANAGED_IDENTITY_CLIENT_ID>
    mountWithWorkloadIdentityToken: true    # optional token-only mount (no account key)
```

See [`examples/values-wi-token-static.yaml`](examples/values-wi-token-static.yaml) and [`examples/values-wi-token-dynamic.yaml`](examples/values-wi-token-dynamic.yaml) for complete examples.

### Azure prerequisites

1. **Enable the OIDC issuer and workload identity** on the AKS cluster.
2. **Create a user-assigned managed identity** and note its `clientId`.
3. **Create a federated identity credential** linking the cluster OIDC issuer and the service account subject:
   - Issuer: the cluster OIDC issuer URL (`az aks show ... --query oidcIssuerProfile.issuerUrl`)
   - Subject: `system:serviceaccount:<NAMESPACE>:<SERVICE_ACCOUNT_NAME>` (e.g. `system:serviceaccount:tenant2-standard-test:rabbitmq-sa`)
   - Audience: `api://AzureADTokenExchange`
4. **Assign the storage role** to the managed identity, depending on the flow:

   | Flow | Required role |
   | --- | --- |
   | Account-key (default, `mountWithWorkloadIdentityToken` unset/false) | `Storage Account Contributor` |
   | Token-only (`mountWithWorkloadIdentityToken: true`) | `Storage File Data SMB MI Admin` |

   > For the token-only flow, `Storage File Data SMB Share Contributor` / `Elevated Contributor` are **not** sufficient — the managed identity mount requires `Storage File Data SMB MI Admin`.

5. **For the token-only flow, enable SMB OAuth** on the storage account (required for Kerberos ticket acquisition):
   ```bash
   az storage account update \
     --name <STORAGE_ACCOUNT_NAME> \
     --resource-group <RESOURCE_GROUP> \
     --enable-smb-oauth true
   ```

> The managed identity that owns the federated credential, the `client-id` service account annotation, and the storage role assignment must all be the **same** identity.

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

Create a TLS cert on Azure Key vault to encrypt traffic between client and RabbitMQ cluster.

![alt certificate creation](../kubeit-rabbitmq-chart/images/cert.png)
It must be in PEM format
The certificate's SAN:

```
- *.rabbitmq-test-spi-nodes.spi-test-rabbitmq.svc.cluster.local
- rabbitmq-test-spi.spi-test-rabbitmq.svc
- rabbitmq-spi-rabbitmq-test.green.eus2.nonprod.kubeit-int.dnv.com
- rabbitmq-spi-rabbitmq-test.eus2.nonprod.kubeit-int.dnv.com
...
```
The Subject should be `CN=<host-of-rabbitmq-cluster>` For example. `CN=<NameofRMQCluster>.<colour>.<region>.kubeit-int.dnv.com`
Ref: https://www.rabbitmq.com/kubernetes/operator/using-operator#one-way-tls


One way TLS settings on RabbitMQ Cluster ensures that client does not require certs. Ensure these settings are enabled:


```
ssl_options.fail_if_no_peer_cert = false
ssl_options.verify = verify_none
```


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
