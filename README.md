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

I. Check clientId of mi-dev-tenant2 managed identity in [KubeITSharedSVC-DEV-RG-WE](https://portal.azure.com/#@dnv.onmicrosoft.com/resource/subscriptions/e5948a9c-7103-4629-98f8-798fa9a0d9aa/resourceGroups/KubeITSharedSVC-DEV-RG-WE/overview).
   If the clientId is already configured in charts/deployment-chart/templates/service-account.yaml (and in charts/secrets/templates/service-account.yaml for testing secrets), no changes are required in the kubeit-charts repository.
II. Check number of federated credentials under mi-dev-tenant2. Max is set to 20, if necessary remove federated credentials which are no longer used.
III. Example applications are ready to go.

If clientId of mi-dev-tenant2 doesn't match service-account.yaml's, follow these steps:

1. Create a working branch for this repository. Update kubeit-app-of-apps/.gitmodules to point to your branch.
2. Get the new clientId of the mi-dev-tenant2 managed identity.
3. Update the service-account.yaml's:
   - Add the new clientId to charts/deployment-chart/templates/service-account.yaml.
   - If testing secrets, also add it to charts/secrets/templates/service-account.yaml.
4. Push the changes to your kubeit-charts working branch.
5. Update the submodule in your kubeit-app-of-apps working branch to point to the latest commit in kubeit-charts. Push the changes in kubeit-app-of-apps working branch (Do not update the submodule in the kubeit-app-of-apps main branch!).
6. Wait for ArgoCD to sync deployed apps.

Note: After pushing changes, always update the submodule in your kubeit-app-of-apps working branch to the latest commit. Remember, submodule change needs to be pushed in kubeit-app-of-apps as well.

## Workload identity
By default, example charts in this repository use workload identity.
To disable it follow workflow from points 1-6 analogically with updated values.yaml:
  - kubeit-charts/charts/kubeit-deployment-chart/values.yaml and set workloadIdentity to "false".
