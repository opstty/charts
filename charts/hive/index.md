---
layout: default
title: hive
---

# Apache Hive Helm Chart

A Helm chart for deploying [Apache Hive](https://hive.apache.org/) on Kubernetes — including the **Hive Metastore (HMS)** and optionally **HiveServer2**.

## TL;DR

```bash
helm repo add opstty https://opstty.github.io/charts
helm install my-hive opstty/hive
```

## Introduction

This chart bootstraps an Apache Hive deployment on a Kubernetes cluster using the Helm package manager.

**Components:**

| Component | Default | Description |
|---|---|---|
| Hive Metastore (HMS) | ✅ enabled | Thrift metadata service on port 9083 |
| HiveServer2 | ❌ disabled | JDBC/ODBC gateway (enable with `hiveserver2.enabled=true`) |
| PostgreSQL (Bitnami subchart) | ✅ enabled | Embedded DB via `bitnami/postgresql` subchart |

## Prerequisites

- Kubernetes 1.23+
- Helm 3.x
- PersistentVolume support in the cluster (for the embedded PostgreSQL)

## Installing the Chart

```bash
helm repo add opstty https://opstty.github.io/charts
helm repo update
helm install my-hive opstty/hive
```

## Configuration

### Metastore only (default)

```bash
helm install my-hive opstty/hive
```

### Metastore + HiveServer2

```bash
helm install my-hive opstty/hive \
  --set hiveserver2.enabled=true
```

### External database (no embedded PostgreSQL)

```bash
helm install my-hive opstty/hive \
  --set metastore.database.enabled=false \
  --set metastore.database.external.host=my-postgres \
  --set metastore.database.external.user=hive \
  --set metastore.database.external.existingSecret=hive-db-secret
```

### Custom image

```bash
helm install my-hive opstty/hive \
  --set image.registry=my-registry.example.com \
  --set image.repository=my-org/hive \
  --set image.tag=4.0.0-custom
```

## Parameters

### Global

| Parameter | Description | Default |
|---|---|---|
| `image.repository` | Hive image repository | `apache/hive` |
| `image.tag` | Hive image tag (defaults to `appVersion`) | `""` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `replicas` | Default replica count | `1` |
| `imagePullSecrets` | Global image pull secrets | `[]` |

### Hive Metastore

| Parameter | Description | Default |
|---|---|---|
| `metastore.enabled` | Enable Hive Metastore | `true` |
| `metastore.replicas` | Number of replicas | `1` |
| `metastore.service.port` | Thrift service port | `9083` |
| `metastore.resources` | Resource requests/limits | `{}` |
| `metastore.database.enabled` | Deploy embedded PostgreSQL (Bitnami subchart) | `true` |

### HiveServer2

| Parameter | Description | Default |
|---|---|---|
| `hiveserver2.enabled` | Enable HiveServer2 | `false` |
| `hiveserver2.replicas` | Number of replicas | `1` |
| `hiveserver2.service.thriftPort` | Thrift port | `10000` |
| `hiveserver2.service.httpPort` | HTTP port | `10001` |
| `hiveserver2.service.webuiPort` | Web UI port | `10002` |

### Hive Configuration

Properties are rendered as `hive-site.xml` and `metastore-site.xml`. Global properties can be overridden per-component:

```yaml
hiveSite:
  properties:
    hive.execution.engine: tez

metastore:
  hiveSite:
    properties:
      # overrides global hiveSite for metastore only
      hive.metastore.warehouse.dir: /my/warehouse
```
