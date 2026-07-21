# HIVE CHART KNOWLEDGE BASE

## OVERVIEW
Single Helm chart deploying Apache Hive 4.0.0 — two components: Metastore (always-on) and HiveServer2 (disabled by default).

## STRUCTURE
```
hive/
├── Chart.yaml              # chart metadata: version=0.1.0, appVersion=4.0.0
├── values.yaml             # all defaults; `# --` docstrings for helm-docs
├── artifacthub-pkg.yml     # Artifact Hub per-chart metadata
├── README.md               # end-user install docs
└── templates/
    ├── _helpers.tpl                    # all named templates (8 helpers)
    ├── configmap-hive-site.yaml        # renders hive-site.xml
    ├── configmap-metastore-site.yaml   # renders metastore-site.xml
    ├── databasecluster-metastore.yaml  # Percona Everest DatabaseCluster CRD
    ├── deployment-metastore.yaml       # Metastore Deployment (heaviest template)
    ├── deployment-hiveserver2.yaml     # HiveServer2 Deployment
    ├── ingress-metastore.yaml
    ├── ingress-hiveserver2.yaml
    ├── service-metastore.yaml
    ├── service-hiveserver2.yaml
    ├── serviceaccount.yaml
    └── NOTES.txt
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Add a new hive-site.xml property | `values.yaml` → `hiveSite.properties` | Component-level overrides go in `metastore.hiveSite.properties` / `hiveserver2.hiveSite.properties` |
| Change DB provisioning | `templates/databasecluster-metastore.yaml` + `values.yaml` `metastore.database.*` | Percona Everest `DatabaseCluster` CRD |
| Override image per component | `values.yaml` `metastore.image.*` / `hiveserver2.image.*` | Empty fields inherit global `image.*` |
| Add env var | `values.yaml` `env[]` (global) or `metastore.env[]` / `hiveserver2.env[]` | Component-level wins over global by `name` key |
| Credential injection logic | `templates/deployment-metastore.yaml` init containers | Writes JCEKS file from env vars |
| Named template definitions | `templates/_helpers.tpl` | All 8 helpers documented with usage comments |
| Probe timeouts | `values.yaml` `metastore.startupProbe.*` / `livenessProbe.*` / `readinessProbe.*` | All nullable; chart has sane inline defaults |

## CONVENTIONS
- **Config XML path**: Never touch configmap templates directly. Set properties in `values.yaml` under `hiveSite.properties` or `metastoreSite.properties`. Merging is `mergeOverwrite(global, component)`.
- **Template enable guard**: Every top-level template starts with `{{- if .Values.<component>.enabled -}}` — NEVER omit this.
- **Resource naming**: `{{ include "hive.fullname" . }}-<component>` — all resources follow this pattern.
- **Image tag default**: Falls back to `Chart.AppVersion` ("4.0.0") when no tag/digest set — matches the `apache/hive:4.0.0` image.
- **`useRepositoryAsSoleImageReference`**: When true, uses repository string verbatim (no registry prefix, no tag suffix).

## ANTI-PATTERNS (THIS CHART)
- **NEVER** set `datanucleus.autoCreateSchema: true` in production — schema init is a one-time `schematool` job.
- **NEVER** disable `hive.metastore.schema.verification` — it prevents silent schema drift.
- **DO NOT** add metastore-site.xml properties to `hiveSite.properties` — they go in `metastoreSite.properties`.
- **DO NOT** add a second `hadoop.security.credential.provider.path` override — it conflicts with the JCEKS init container.
- **DO NOT** set `hiveserver2.enabled: true` without configuring `metastore` connectivity — HS2 depends on HMS being reachable.

## NOTES
- **External DB**: Set `metastore.database.enabled: false` + fill `metastore.database.external.*` to skip Percona Everest provisioning.
- **JCEKS init container**: Only runs when `metastore.database.enabled: true` and engine type is `postgresql` — writes DB password into a JCEKS credential store.
- **HiveServer2 ports**: thrift=10000, http=10001, webui=10002.
- **Metastore thrift port**: 9083 (service default).
