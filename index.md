# opstty/charts

Helm chart repository for Kubernetes.

## Add the repository

```bash
helm repo add opstty https://opstty.github.io/charts
helm repo update
```

## Charts

| Chart | Description | Version | App Version |
|-------|-------------|---------|-------------|
| [hive](charts/hive/) | Apache Hive Metastore + HiveServer2 | 0.1.3 | 4.0.0 |
| [trino](charts/trino/) | Trino query engine with password auth, table registration, and Superset integration | 0.1.0 | 481 |

Click a chart name for full documentation and configuration reference.

## Install

```bash
helm install <release-name> opstty/<chart-name>
```

For example:

```bash
helm install hive opstty/hive
```

See each chart's README for detailed configuration options.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.x

## Source

Charts source and full documentation: [github.com/opstty/charts](https://github.com/opstty/charts)
