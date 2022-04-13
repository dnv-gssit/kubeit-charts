# kubeit-charts

Helm repository for storing charts developed by the CloudOps team for KubeIT platform project.

## Usage

Add the repo as follows:

    helm repo add kubeit-charts https://dnv-gssit.github.io/kubeit-charts

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
kubeit-charts` to see the charts.

To install the kubeit-redis-chart chart:

    helm install kubeit-redis-chart kubeit-charts/kubeit-redis-chart

To uninstall the chart:

    helm delete kubeit-redis-chart