#!/usr/bin/env bash

RUN_PATH=$PWD
SCRIPT_PATH=${SCRIPT_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

RENDERED_CHART_PATH=/tmp/rendered_chart

echo "===]> Info: RUN_PATH=$RUN_PATH"
echo "===]> Info: SCRIPT_PATH=$SCRIPT_PATH"

# APP=onegateway-workload-old-example-app
APP=onegateway-sessionmanager
ENV=auxiliary
REGION=westeurope
COLOUR=blue

rm -rf /tmp/rendered_chart

cd $SCRIPT_PATH/../kubeit-deployment-chart

helm template --dependency-update --render-subchart-notes .  \
-f ../scripts/test-kubeit-deployment-chart.yaml \
-f ../argoApps/values.yaml \
-f ../argoApps/appValues/global.yaml \
-f ../argoApps/appValues/${APP}/appGlobal.yaml \
-f ../argoApps/appValues/${APP}/environment/${ENV}/${ENV}.yaml \
-f ../argoApps/appValues/${APP}/environment/${ENV}/region/${REGION}/${REGION}.yaml \
-f ../argoApps/appValues/${APP}/environment/${ENV}/region/${REGION}/cluster/${COLOUR}.yaml \
--output-dir $RENDERED_CHART_PATH --debug

yamllint -c $SCRIPT_PATH/../.yamllint -s $RENDERED_CHART_PATH

cd $RUN_PATH
