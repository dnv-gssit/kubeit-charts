# kubeit-charts

Helm repository for storing charts developed by KubeIT team.

## General usage

Add the repo as follows:

```bash
helm repo add kubeit-charts https://dnv-gssit.github.io/kubeit-charts
helm repo update
```

To install the kubeit-redis-chart chart:

```bash
helm install example -f values.yaml kubeit-charts/kubeit-deployment-chart -n mynamespace
```

To uninstall the chart:

```
helm uninstall example -n mynamespace
```

## Testing

To add test, create files in the `tests/<chart_name>` directory of the chart with the names: `<testname>.values.yaml` and `<testname>.result.yaml`.

To test all the chart, you can use the following command:

```bash
./run-tests.py
```

To test a specific chart, you can use the following command:

```bash
./run-tests.py --charts=kubeit-deployment-chart
```

More charts could be selected by using the `--charts` option. You can specify multiple charts by separating them with commas.

To run a specific test, you can use the following command:

```bash
./run-tests.py --charts=kubeit-deployment-chart --tests=test1
```

More tests could be selected by using the `--tests` option. You can specify multiple tests by separating them with commas.

If many charts and tests are selected, the script will run selected tests for each selected chart. If test would not be found in the chart, it will be skipped.

## Contributing

If you want to contribute to the charts, please follow these steps:
1. Do changes locally
2. Run `pre-commit run -a -v`
3. Add or modify tests and run `./run-tests.py` to ensure everything works as expected
4. Remember to bump chart version in `Chart.yaml` file
5. Do PR and ask KubeIT team for review
6. Merge after approval


## Semantic Versioning Rules

Below rules for bumping semantic versioning for helm charts
Remember to not bump all at once.
If you bump minor there is no sense to bump patch as well. Patch will start from 0 after minor change.
Below example.

```
#incorrect bump
0.1.1 -> 0.2.1

#correct bump
0.1.1 -> 0.2.0
```


| Type of change                                        | Release type |
| ----------------------------------------------------- | ------------ |
| fix, internal improvements, change default values     | Patch        |
| Backward-compatible, new feature, dependencies change | Minor        |
| BREAKING CHANGE                                       | Major        |
