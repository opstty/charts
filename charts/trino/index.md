---
layout: default
title: trino
---

# Trino Helm Chart

A Helm chart for deploying [Trino](https://trino.io/) on Kubernetes — wraps the official [trinodb/trino](https://trinodb.github.io/charts/) subchart with operational templates for **password authentication**, **cert-manager certificates**, **ingress**, **table registration**, and **Superset integration**.

## TL;DR

```bash
helm repo add opstty https://opstty.github.io/charts
helm install my-trino opstty/trino
```

## Introduction

This chart bootstraps a Trino deployment on a Kubernetes cluster using the Helm package manager. It layers production-ready operational templates on top of the official Trino subchart.

**Components:**

| Component | Default | Description |
|---|---|---|
| Trino (official subchart) | ✅ enabled | Coordinator + workers via [trinodb/trino](https://trinodb.github.io/charts/) |
| Password Authentication | ❌ disabled | Init container converting JSON password map to bcrypt htpasswd |
| Coordinator Certificate | ❌ disabled | cert-manager `Certificate` resource for TLS |
| Coordinator Ingress | ❌ disabled | Ingress resource for the coordinator |
| Register Table Job | ❌ disabled | Post-install/upgrade Job to register tables in Trino |
| Superset Syncer Job | ❌ disabled | Post-install/upgrade Job to sync Trino connection into Superset |
| Hive Metastore (subchart) | ❌ disabled | Co-deploy the sibling `opstty/hive` chart |

## Prerequisites

- Kubernetes 1.23+
- Helm 3.x

## Installing the Chart

```bash
helm repo add opstty https://opstty.github.io/charts
helm repo update
helm install my-trino opstty/trino
```

## Configuration

### Basic install (coordinator + workers, password auth)

```bash
helm install my-trino opstty/trino \
  --set passwordAuthentication.enabled=true \
  --set passwordAuthentication.credentialsSecretName=trino-passwords
```

### With TLS certificate (cert-manager)

```bash
helm install my-trino opstty/trino \
  --set coordinatorCertificate.enabled=true \
  --set coordinatorCertificate.host=trino.example.com \
  --set coordinatorCertificate.issuerRef.name=letsencrypt-prod
```

### With Ingress

```bash
helm install my-trino opstty/trino \
  --set coordinatorIngress.enabled=true \
  --set coordinatorIngress.host=trino.example.com \
  --set coordinatorIngress.className=nginx
```

### With co-deployed Hive Metastore

```bash
helm install my-trino opstty/trino \
  --set hive.enabled=true
```

### With Iceberg catalog pointing to Hive Metastore

```yaml
trino:
  catalogs:
    iceberg: |
      connector.name=iceberg
      hive.metastore.uri=thrift://my-trino-hive-metastore:9083
```

## Parameters

### Global

| Parameter | Description | Default |
|---|---|---|
| `nameOverride` | Override chart name | `""` |
| `fullnameOverride` | Override full resource name | `""` |
| `commonLabels` | Labels added to all resources | `{}` |
| `commonAnnotations` | Annotations added to all resources | `{}` |

### Trino Subchart

| Parameter | Description | Default |
|---|---|---|
| `trino.image.tag` | Trino container image tag | `"481"` |
| `trino.server.config.authenticationType` | Authentication type (`PASSWORD`, `OAUTH2`, …) | `"PASSWORD"` |
| `trino.server.config.https.enabled` | Enable HTTPS on the coordinator | `false` |
| `trino.catalogs` | Catalog definitions (one key per catalog file) | `{}` |

See the [trinodb/trino chart values](https://trinodb.github.io/charts/) for the full list of passthrough options.

### Password Authentication

| Parameter | Description | Default |
|---|---|---|
| `passwordAuthentication.enabled` | Enable password-auth init container | `false` |
| `passwordAuthentication.image.repository` | Init container image repository | `ghcr.io/opstty/trino-password-authentication` |
| `passwordAuthentication.image.tag` | Init container image tag | `latest` |
| `passwordAuthentication.credentialsSecretName` | Secret containing the JSON password map | `""` |
| `passwordAuthentication.credentialsSecretKey` | Key in the secret holding the password JSON | `password.db` |

### Coordinator Certificate

| Parameter | Description | Default |
|---|---|---|
| `coordinatorCertificate.enabled` | Enable cert-manager Certificate | `false` |
| `coordinatorCertificate.host` | Primary DNS hostname | `""` |
| `coordinatorCertificate.issuerRef.name` | Issuer or ClusterIssuer name | `""` |
| `coordinatorCertificate.issuerRef.kind` | Issuer kind | `ClusterIssuer` |
| `coordinatorCertificate.privateKey.algorithm` | Key algorithm | `RSA` |
| `coordinatorCertificate.privateKey.size` | Key size in bits | `4096` |
| `coordinatorCertificate.additionalDnsNames` | Additional SANs | `[]` |

### Coordinator Ingress

| Parameter | Description | Default |
|---|---|---|
| `coordinatorIngress.enabled` | Enable Ingress | `false` |
| `coordinatorIngress.className` | Ingress class name | `""` |
| `coordinatorIngress.host` | Hostname for the Ingress rule | `""` |
| `coordinatorIngress.port` | Backend service port | `8080` |
| `coordinatorIngress.annotations` | Annotations for the Ingress | `{}` |

### Register Table Job

| Parameter | Description | Default |
|---|---|---|
| `registerTable.job.enabled` | Enable register-table Job | `false` |
| `registerTable.job.image.repository` | Job image repository | `ghcr.io/opstty/trino-register-table` |
| `registerTable.job.credentialsSecretName` | Secret with Trino credentials | `""` |
| `registerTable.job.postgres.host` | Postgres host | `""` |
| `registerTable.job.postgres.database` | Postgres database name | `metastore` |
| `registerTable.configmap.enabled` | Enable table registration ConfigMap | `false` |
| `registerTable.configmap.data` | JSON table registration data | `"{}"` |

### Superset Integration

| Parameter | Description | Default |
|---|---|---|
| `superset.url` | Superset base URL | `""` |
| `superset.syncer.job.enabled` | Enable Superset syncer Job | `false` |
| `superset.syncer.job.image.repository` | Syncer job image repository | `ghcr.io/opstty/trino-superset-syncer` |
| `superset.syncer.job.credentialsSecretName` | Secret with Trino credentials | `""` |
| `superset.syncer.job.adminCredentialsSecretName` | Secret with Superset admin password | `""` |
| `superset.roles.configmap.enabled` | Enable Superset roles ConfigMap | `false` |
| `superset.roles.configmap.data` | JSON Superset role definitions | `"{}"` |

### Hive Metastore Subchart

| Parameter | Description | Default |
|---|---|---|
| `hive.enabled` | Co-deploy the `opstty/hive` subchart | `false` |
