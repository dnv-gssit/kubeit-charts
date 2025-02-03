# kubeit-charts

Helm repository for storing charts developed by the CloudOps team for KubeIT platform project.

## General usage

Add the repo as follows:

    helm repo add kubeit-charts https://dnv-gssit.github.io/kubeit-charts

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
kubeit-charts` to see the charts.

To install the kubeit-redis-chart chart:

    helm install kubeit-redis-chart kubeit-charts/kubeit-redis-chart

To uninstall the chart:

    helm delete kubeit-redis-chart

## Usage in kubeit dev cluster:

1. Create a working branch for this repository. Update kubeit-app-of-apps/chart globals.targetRevision to point to your newly created branch.
2. Create User Assigned Managed Identity in the same subscription as cluster (name of managed identity must end with '-dev-tenant2' e.g. 'mi-dev-tenant2') and assign Role 'Managed Identity Contributor' to Az_KubeIT_AcrReader_Env_Dev security group.
3. Get clientId of the newly created managed identity.
4. Update the service-account.yaml's:
   - Add the new clientId to charts/deployment-chart/templates/service-account.yaml.
   - If testing secrets, also add it to charts/secrets/templates/service-account.yaml.
5. Push the changes to your kubeit-charts working branch.
6. Sync app-of-apps in ArgoCD.

Note: After testing, remember to remove unused managed identity in Azure Portal.

## Workload identity
By default, example charts in this repository use workload identity.
To disable it update values.yaml:
  - kubeit-charts/charts/kubeit-deployment-chart/values.yaml, set workloadIdentity to "false".
