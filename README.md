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
By default, example charts in this repository use workload identity.
To disable it, edit kubeit-charts/charts/kubeit-app-of-apps/templates/applications.yaml and set workloadIdentity to "false".
If workload identity is disabled, skip steps 2-4.

Otherwise, follow these steps:

1. Create a working branch for this repository. Update kubeit-app-of-apps/.gitmodules to point to your branch.
Hint: Ensure the submodule in your kubeit-app-of-apps working branch points to the latest commit in kubeit-charts. Do not update the submodule in the kubeit-app-of-apps main branch.
2. Deploy the development cluster.
3. Get the clientId of the mi-dev-tenant2 managed identity ().
4. Update the service-account.yaml:
   - Add the clientId to charts/deployment-chart/templates/service-account.yaml.
   - If testing secrets, also add it to charts/secrets/templates/service-account.yaml.
5. Assign role Managed Identity Contributor to KubeIT Security group Az_KubeIT_AcrReader_Global.
6. Push the changes to your working branch.
7. Wait for ArgoCD to sync deployed apps.

Note: After pushing changes, always update the submodule in your kubeit-app-of-apps working branch to the latest commit.
