---
layout: default
title: trino
---

# Trino Helm Chart
A Helm chart for Trino — wraps the official trinodb/trino subchart with operational templates for password authentication, certificates, ingress, table registration, and Superset integration.

## TL;DR
```bash
helm repo add opstty https://opstty.github.io/charts
helm install my-trino opstty/trino
```

## Introduction
This Helm chart deploys Trino, a distributed SQL query engine, leveraging the official `trinodb/trino` subchart. It extends the core Trino deployment with essential operational features including password authentication setup, TLS certificate management via cert-manager, Kubernetes Ingress for external access, post-deployment jobs for table registration, and Superset integration. This chart aims to provide a production-ready Trino deployment with common enterprise-grade requirements.

| Component | Default | Description |
|---|---|---|
| Trino Coordinator | ✅ enabled | Query coordinator via trinodb/trino subchart |
| Trino Workers | ✅ enabled (2 replicas) | Query workers via trinodb/trino subchart |
| Hive Metastore | ❌ disabled | Co-deployed via opstty/hive subchart (`hive.enabled=true`) |
| Password Auth Init Container | ❌ disabled | bcrypt htpasswd generator (`passwordAuthentication.enabled=true`) |
| Coordinator Certificate | ❌ disabled | cert-manager Certificate resource (`coordinatorCertificate.enabled=true`) |
| Coordinator Ingress | ❌ disabled | Kubernetes Ingress for the coordinator (`coordinatorIngress.enabled=true`) |
| Register-Table Job | ❌ disabled | Post-install/upgrade Job (`registerTable.job.enabled=true`) |
| Superset Syncer Job | ❌ disabled | Post-install/upgrade Job (`superset.syncer.job.enabled=true`) |

## Prerequisites
- Kubernetes 1.23+
- Helm 3.x
- cert-manager (only if `coordinatorCertificate.enabled=true`)

## Installing the Chart
```bash
helm repo add opstty https://opstty.github.io/charts
helm repo update
helm install my-trino opstty/trino
```

## Configuration

### Add a catalog
```yaml
trino:
  catalogs:
    iceberg: |
      connector.name=iceberg
      hive.metastore.uri=thrift://hive-metastore:9083
```

### Enable password authentication
```yaml
passwordAuthentication:
  enabled: true

trino:
  passwordAuth:
    credentialsSecretName: my-trino-credentials

  server:
    config:
      authenticationType: "PASSWORD"

  initContainers:
    coordinator:
      - name: password-authentication
        image: '{{ .Values.passwordAuth.image.repository }}:{{ .Values.passwordAuth.image.tag }}'
        imagePullPolicy: '{{ .Values.passwordAuth.image.pullPolicy }}'
        volumeMounts:
          - name: credentials-volume
            mountPath: /tmp/
          - name: encrypted-credentials-volume
            mountPath: /etc/trino/auth/password/

  coordinator:
    additionalVolumes:
      - name: encrypted-credentials-volume
        emptyDir: {}
      - name: credentials-volume
        secret:
          secretName: '{{ .Values.passwordAuth.credentialsSecretName }}'
          items:
            - key: '{{ .Values.passwordAuth.credentialsSecretKey }}'
              path: password.db
      - name: certificates-volume
        secret:
          secretName: '{{ include "trino.fullname" . }}-coordinator-certificate-secret'
          defaultMode: 420
    additionalVolumeMounts:
      - name: encrypted-credentials-volume
        mountPath: /etc/trino/auth/password/
      - name: certificates-volume
        mountPath: /etc/trino/certificate/
```

The `trino.passwordAuth.*` values are available in template expressions within the subchart scope (the upstream chart runs `tpl` on `additionalVolumes` and `initContainers`), so the snippet above uses them directly without repeating the image or secret name.

### Enable TLS with cert-manager
```yaml
coordinatorCertificate:
  enabled: true
  host: trino.example.com
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
```

When `coordinatorCertificate.enabled: true`, the chart creates a cert-manager `Certificate` resource named `<release>-coordinator-certificate-secret`. Mount it on the coordinator as shown in the password authentication example above (`certificates-volume`).

### Enable Ingress
**Note:** The Ingress template does not include a `tls:` block. TLS termination must be handled via Ingress controller annotations or an external mechanism.
```yaml
coordinatorIngress:
  enabled: true
  className: nginx
  host: trino.example.com
  port: 8080
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
```

### Co-deploy Hive Metastore
```yaml
hive:
  enabled: true
```
See the [Hive chart documentation](../hive/README.md) for full configuration options.

## Parameters

**General**
| Parameter | Description | Default |
|---|---|---|
| `nameOverride` | Override resource names | `""` |
| `fullnameOverride` | Fully override generated resource name | `""` |
| `commonLabels` | Common labels applied to all resources | `{}` |
| `commonAnnotations` | Common annotations applied to all resources | `{}` |

**Trino Subchart Overrides**
These are the overrides pre-configured by this chart. Any value from the upstream trinodb/trino chart can be set under the `trino:` key — see [Subchart Configuration](#subchart-configuration) below.
| Parameter | Description | Default |
|---|---|---|
| `trino.image.tag` | Trino container image tag | `"481"` |
| `trino.server.config.authenticationType` | Authentication type (PASSWORD, OAUTH2, etc.) | `"PASSWORD"` |
| `trino.server.config.https.enabled` | Enable HTTPS on the coordinator | `false` |
| `trino.server.coordinatorExtraConfig` | Extra config lines appended to coordinator config.properties | `""` |
| `trino.accessControl` | Access control rules (rules.json) | `{}` |
| `trino.catalogs` | Catalog definitions (one key per catalog file) | `{}` |
| `trino.additionalConfigProperties` | Additional config.properties entries | `[]` |
| `trino.envFrom` | envFrom for all Trino pods (secrets/configmaps) | `[]` |
| `trino.env` | Environment variables for all Trino pods | `[]` |
| `trino.initContainers.coordinator` | Init containers added to the coordinator pod | `[]` |
| `trino.initContainers.worker` | Init containers added to worker pods | `[]` |
| `trino.coordinator.additionalVolumes` | Extra volumes attached to the coordinator pod | `[]` |
| `trino.coordinator.additionalVolumeMounts` | Extra volume mounts for the coordinator container | `[]` |
| `trino.coordinator.additionalConfigFiles` | Extra config files mounted into the coordinator container | `{}` |
| `trino.worker.additionalVolumes` | Extra volumes attached to worker pods | `[]` |
| `trino.worker.additionalVolumeMounts` | Extra volume mounts for worker containers | `[]` |

**Password Authentication**
| Parameter | Description | Default |
|---|---|---|
| `passwordAuthentication.enabled` | Enable the password-authentication init container. When true, auto-configures the init container, credential volumes, and TLS certificate volume on the coordinator. | `false` |
| `passwordAuthentication.image.repository` | Init container image repository | `ghcr.io/opstty/trino-password-authentication` |
| `passwordAuthentication.image.tag` | Init container image tag | `latest` |
| `passwordAuthentication.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `trino.passwordAuth.credentialsSecretName` | Secret containing the JSON password map | `""` |
| `trino.passwordAuth.credentialsSecretKey` | Key in the secret that holds the password JSON | `password.db` |

**Coordinator Certificate**
| Parameter | Description | Default |
|---|---|---|
| `coordinatorCertificate.enabled` | Enable a cert-manager Certificate for the coordinator | `false` |
| `coordinatorCertificate.host` | Primary DNS host for the certificate | `""` |
| `coordinatorCertificate.issuerRef.name` | Name of the Issuer or ClusterIssuer | `""` |
| `coordinatorCertificate.issuerRef.kind` | Kind of issuer (Issuer or ClusterIssuer) | `ClusterIssuer` |
| `coordinatorCertificate.privateKey.algorithm` | Key algorithm (RSA, ECDSA, Ed25519) | `RSA` |
| `coordinatorCertificate.privateKey.size` | Key size in bits | `4096` |
| `coordinatorCertificate.privateKey.encoding` | Key encoding (PKCS1, PKCS8) | `PKCS8` |
| `coordinatorCertificate.additionalDnsNames` | Additional DNS names to include in the certificate | `[]` |

**Coordinator Ingress**
| Parameter | Description | Default |
|---|---|---|
| `coordinatorIngress.enabled` | Enable an Ingress for the coordinator | `false` |
| `coordinatorIngress.className` | Ingress class name (e.g. nginx, traefik) | `""` |
| `coordinatorIngress.host` | Hostname for the Ingress rule | `""` |
| `coordinatorIngress.port` | Backend service port number | `8080` |
| `coordinatorIngress.annotations` | Annotations to add to the Ingress resource | `{}` |

**Register Table**
The `registerTable.job.enabled` and `registerTable.configmap.enabled` flags are independent. The ConfigMap should typically be enabled together with the Job.
| Parameter | Description | Default |
|---|---|---|
| `registerTable.job.enabled` | Enable the register-table post-install/upgrade Job | `false` |
| `registerTable.job.image.repository` | Job container image repository | `ghcr.io/opstty/trino-register-table` |
| `registerTable.job.image.tag` | Job container image tag | `latest` |
| `registerTable.job.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `registerTable.job.imagePullSecrets` | Image pull secrets for private registries | `[]` |
| `registerTable.job.sslCertPath` | SSL certificate path mounted in the container | `/etc/trino/certificate-authority/root.ca` |
| `registerTable.job.credentialsSecretName` | Secret containing Trino credentials | `""` |
| `registerTable.job.certificateAuthoritySecretName` | Secret containing the CA cert | `""` |
| `registerTable.job.environmentSecretName` | Secret containing extra environment variables | `""` |
| `registerTable.job.postgres.host` | Postgres host (or PgBouncer endpoint) | `""` |
| `registerTable.job.postgres.passwordSecretName` | Secret containing the Postgres password | `""` |
| `registerTable.job.postgres.passwordSecretKey` | Key in the password secret | `password` |
| `registerTable.job.postgres.database` | Database name to connect to | `metastore` |
| `registerTable.job.postgres.caCertPath` | CA certificate path for Postgres TLS | `/etc/trino/pgbouncer-certs/root.ca` |
| `registerTable.job.postgres.caCertSecretName` | Secret containing the Postgres CA cert | `""` |
| `registerTable.configmap.enabled` | Enable the register-table ConfigMap | `false` |
| `registerTable.configmap.data` | JSON data for table registration | `"{}"` |

**Superset**
| Parameter | Description | Default |
|---|---|---|
| `superset.url` | Superset base URL | `""` |
| `superset.roles.configmap.enabled` | Enable the Superset roles ConfigMap | `false` |
| `superset.roles.configmap.data` | JSON data for Superset role definitions | `"{}"` |
| `superset.syncer.job.enabled` | Enable the Superset syncer post-install/upgrade Job | `false` |
| `superset.syncer.job.image.repository` | Syncer job image repository | `ghcr.io/opstty/trino-superset-syncer` |
| `superset.syncer.job.image.tag` | Syncer job image tag | `latest` |
| `superset.syncer.job.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `superset.syncer.job.imagePullSecrets` | Image pull secrets | `[]` |
| `superset.syncer.job.credentialsSecretName` | Secret containing Trino credentials | `""` |
| `superset.syncer.job.adminCredentialsSecretName` | Secret containing the Superset admin password | `""` |
| `superset.syncer.job.adminCredentialsSecretKey` | Key holding the Superset admin password | `SUPERSET_ADMIN_PASSWORD` |
| `superset.syncer.job.waitImage.repository` | Wait container image repository | `alpine/curl` |
| `superset.syncer.job.waitImage.tag` | Wait container image tag | `8.12.0` |

**Hive Subchart**
| Parameter | Description | Default |
|---|---|---|
| `hive.enabled` | Co-deploy the Hive Metastore from the opstty/hive subchart | `false` |
See [opstty/hive README](../hive/README.md) for all Hive configuration options.

## Subchart Configuration
This chart wraps the official [trinodb/trino](https://trinodb.github.io/charts/) chart (v1.42.2, as pinned in `Chart.lock`) as a subchart. Only the most commonly-used overrides are listed in the Parameters section above — the upstream chart supports many more options including workers, autoscaling, KEDA, JVM tuning, probes, resource limits, security contexts, service configuration, native ingress, Gateway API, JMX metrics, Prometheus ServiceMonitor, and network policies.

**To see all available upstream values:**
```bash
helm show values trinodb/trino --version 1.42.2
```

Any key from the upstream chart can be set under the `trino:` key in your values file. For example:
```yaml
trino:
  server:
    workers: 5
  coordinator:
    resources:
      requests:
        cpu: 2
        memory: 8Gi
  worker:
    resources:
      requests:
        cpu: 4
        memory: 16Gi
```

**Upstream docs:** https://trinodb.github.io/charts/

When `hive.enabled: true`, the opstty/hive subchart is also deployed. See the [Hive chart README](../hive/README.md) for its full configuration reference.