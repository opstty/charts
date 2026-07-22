# opstty/charts

Helm chart repository for Kubernetes, published to [Artifact Hub](https://artifacthub.io/). All charts live under the [`opstty/`](./opstty/) directory.

## Charts

| Chart | Description | Version | App Version |
|-------|-------------|---------|-------------|
| [hive](./opstty/hive/) | Apache Hive Metastore + HiveServer2 | 0.1.1 | 4.0.0 |

## Usage

```bash
helm repo add opstty https://opstty.github.io/charts
helm repo update
```

### Install Apache Hive

```bash
# Metastore only (default)
helm install hive opstty/hive

# Metastore + HiveServer2
helm install hive opstty/hive --set hiveserver2.enabled=true

# External PostgreSQL (no embedded subchart)
helm install hive opstty/hive \
  --set metastore.database.enabled=false \
  --set metastore.database.external.host=my-postgres \
  --set metastore.database.external.user=hive \
  --set metastore.database.external.existingSecret=hive-db-secret
```

See [hive/README.md](./opstty/hive/README.md) for full configuration reference.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.x
- PersistentVolume support in the cluster — required when `metastore.database.enabled=true` (the default, uses Bitnami PostgreSQL subchart)

## Development

```bash
# Lint
helm lint opstty/hive/

# Dry-run render
helm template hive opstty/hive/

# Render with custom values
helm template hive opstty/hive/ -f my-values.yaml
```

## Release

Push to `master` → GitHub Actions runs [chart-releaser](https://github.com/helm/chart-releaser-action), packages the chart, and publishes it to the `gh-pages` branch.

> **Important**: bump `version` in the chart's `Chart.yaml` (e.g. `opstty/hive/Chart.yaml`) before merging — chart-releaser will not re-release an already-published version.

## License

Apache 2.0
