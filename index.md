# opstty/charts

Helm chart repository for [Apache Hive](https://hive.apache.org/) on Kubernetes.

## Add the repository

```bash
helm repo add opstty https://opstty.github.io/charts
helm repo update
```

## Charts

| Chart | Description | Version | App Version |
|-------|-------------|---------|-------------|
| [hive](https://github.com/opstty/charts/tree/master/hive) | Apache Hive Metastore + HiveServer2 | 0.1.3 | 4.0.0 |

## Install Apache Hive

```bash
# Metastore only (default)
helm install my-hive opstty/hive

# Metastore + HiveServer2
helm install my-hive opstty/hive --set hiveserver2.enabled=true

# External PostgreSQL (no embedded subchart)
helm install my-hive opstty/hive \
  --set metastore.database.enabled=false \
  --set metastore.database.external.host=my-postgres \
  --set metastore.database.external.user=hive \
  --set metastore.database.external.existingSecret=hive-db-secret
```

## Prerequisites

- Kubernetes 1.23+
- Helm 3.x
- PersistentVolume support in the cluster — required when `metastore.database.enabled=true` (the default, uses Bitnami PostgreSQL subchart)

## Source

Charts source and full documentation: [github.com/opstty/charts](https://github.com/opstty/charts)
