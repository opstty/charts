# PROJECT KNOWLEDGE BASE

**Generated:** 2026-07-21T16:00:59Z
**Commit:** 7e8f6dd
**Branch:** master

## OVERVIEW
Helm chart repository for Apache Hive (Metastore + HiveServer2) on Kubernetes, published to Artifact Hub via chart-releaser CI. Single chart: `hive/`.

## STRUCTURE
```
charts/
├── hive/               # The only chart — Apache Hive 4.0.0 (see hive/AGENTS.md)
├── artifacthub-repo.yml # Artifact Hub repository metadata
└── .github/workflows/
    └── release.yaml    # chart-releaser: packages + publishes on push to master
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Chart logic / templates | `hive/templates/` | 12 templates + _helpers.tpl |
| Default values / schema | `hive/values.yaml` | Heavily commented with `# --` docstrings |
| Chart metadata | `hive/Chart.yaml` | version, appVersion, kubeVersion |
| Artifact Hub listing | `hive/artifacthub-pkg.yml` | per-chart AH metadata |
| Release pipeline | `.github/workflows/release.yaml` | chart-releaser on master push |

## CODE MAP
No LSP available (YAML/Helm project). Key Helm named templates (defined in `_helpers.tpl`):

| Template | Role |
|----------|------|
| `hive.name` | Chart name (respects nameOverride) |
| `hive.fullname` | Release-qualified name, 63-char truncated |
| `hive.labels` | Standard Helm labels + commonLabels merge |
| `hive.selectorLabels` | app.kubernetes.io/name + instance |
| `hive.image` | Resolves image ref (registry/repo:tag or @digest) |
| `hive.componentImage` | Merges global image with per-component overrides |
| `hive.mergeEnv` | Merges global + component env lists (component wins) |
| `hive.hiveSiteXml` | Renders hive-site.xml from merged property maps |

## CONVENTIONS
- **Image resolution**: global `image.*` ← overridden by per-component `{component}.image.*`; empty string means "inherit global".
- **Config XML**: `hiveSite.properties` and `metastoreSite.properties` are deep-merged (component overrides global) and rendered to XML via `hive.hiveSiteXml` / `hive.metastoreSiteXml` helpers.
- **Env merge**: component env list wins over global by `name` key — not concatenated, merged via `hive.mergeEnv`.
- **Replicas fallback**: `component.replicas: null` → falls back to global `.Values.replicas`.
- **Component enable guards**: every template file is wrapped in `{{- if .Values.<component>.enabled -}}`.
- **Naming**: all resource names are `{{ include "hive.fullname" . }}-<component>` (e.g. `hive-metastore`, `hive-hiveserver2`).
- **`# --` docstrings**: values.yaml uses `# --` prefix for helm-docs compatible parameter docs.

## ANTI-PATTERNS (THIS PROJECT)
- **DO NOT** hard-code image tags in templates — always use `hive.componentImage` helper.
- **DO NOT** add raw properties directly to configmap templates — add to `hiveSite.properties` / `metastoreSite.properties` in values.yaml.
- **DO NOT** skip the `{{- if .Values.<component>.enabled -}}` guard on new component templates.
- **DO NOT** push directly to master without chart version bump in `Chart.yaml` — chart-releaser will re-release the same version.
- **HiveServer2 is disabled by default** (`hiveserver2.enabled: false`) — this is intentional.

## UNIQUE STYLES
- **Percona Everest CRD**: Metastore database is provisioned via `DatabaseCluster` CRD (`databasecluster-metastore.yaml`). Requires Percona Everest operator in cluster.
- **Credential JCEKS**: Metastore uses a Hadoop credential provider (`hadoop.security.credential.provider.path: jceks://file/opt/hive/secrets/hive.jceks`) — credentials injected via init container.
- **`artifacthub-pkg.yml`** lives inside each chart directory (not root) — Artifact Hub picks it up automatically.

## COMMANDS
```bash
# Lint chart
helm lint hive/

# Template render (dry-run)
helm template my-hive hive/

# Template with custom values
helm template my-hive hive/ -f my-values.yaml

# Install (Artifact Hub)
helm repo add opstty https://opstty.github.io/charts
helm install my-hive opstty/hive

# Release: push to master → GitHub Actions runs chart-releaser automatically
```

## NOTES
- **No tests directory** — chart has no automated Helm tests yet (`helm test`).
- **kubeVersion**: `>=1.23.0` — enforced by Chart.yaml.
- **Artifact Hub**: `artifacthub-repo.yml` at root has empty `repositoryID` — filled by AH post-registration.
- **Branch**: `master` (not `main`) — CI trigger is `master`.
