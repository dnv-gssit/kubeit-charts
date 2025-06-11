# KubeIT Secrets Chart

KubeIT Secrets Chart support external-secrets controller
Below are two examples that ilustrate how to use the chart to define values and pull the secrets using one of the controllers

Definitions:

```yaml
azureKeyVaultSecrets:
  type: external-secrets                               # Type of the secret controller used to deploy the secrets inside the KubeIT cluster
  tenantId:                                            # Azure Active Directory Tenant ID
  azureKeyVaults:
    - azureKeyVaultName:                               # Name of the Azure KeyVault
      secrets:
        - k8sSecretName:                               # Name of the Kubernetes secret resource that is going to be created inside the cluster
          data:
            - k8sSecretKey:                           # Name of the key in Kubernetes secret resource
              azureKeyVaultSecretName:                # Name of the secret in Azure KeyVault to pull the secret value from
            - k8sSecretKey:                           # It is possible to define multiple secret keys and values in one secretproviderclass - lines below show example how to do that
              azureKeyVaultSecretName:
        - k8sSecretName:
          data:
            k8sSecretKey:
            azureKeyVaultSecretName:
```
## Azure Key Vault Access Policies

External-secrets controller use Managed Identities in the cluster to authenticate to Azure KeyVault.
Tenants have to add the Managed Identity used for authentication to Azure KeyVault to enable pulling down secrets to the cluster.
Managed Identity Client ID that can be use for adding the access policies, can be found in the ArgoCD in the bootstrapped application Manifest in the `tenantIdentityClientId` field. Cluster Admin team can supply this value as well.

### External-secrets

When external-secrets is used, tenant clientID has to be specified in the chart values as in the example below.

## Examples

```yaml
azureKeyVaultSecrets:
  type: external-secrets                               # Type of the secret controller used to deploy the secrets inside the KubeIT cluster
  tenantId: "abcd1234-ab12-cd34-ef56-abcdef123456"     # Azure Active Directory Tenant ID
  clientId: "defg4321-ba21-de56-fg67-fedbca654321"     # Managed Identity Application ID - use Active Directory to pull this value or ask the Cluster Admin team to provide it
  azureKeyVaults:
    - azureKeyVaultName: testkeyvault                  # Name of the Azure KeyVault
      secrets:
        - k8sSecretName: testSecret                    # Name of the Kubernetes secret resource that is going to be created inside the cluster
          data:
            - k8sSecretKey: k8sSecretKey               # Name of the key in Kubernetes secret resource
              azureKeyVaultSecretName: SecretName      # Name of the secret in Azure KeyVault to pull the secret value from
            - k8sSecretKey: k8sSecretKey2              # It is possible to define multiple secret keys and values in one secretproviderclass - lines below show example how to do that
              azureKeyVaultSecretName: SecretName2
        - k8sSecretName: testSecret2
          data:
            - k8sSecretKey: k8sSecretKey3
              azureKeyVaultSecretName: SecretName3
            - k8sSecretKey: k8sSecretKey3
              azureKeyVaultSecretName: SecretName3
```

More information on how to use the Azure Key Vault provider can be found here - https://external-secrets.io/v0.11.0/provider/azure-key-vault/
