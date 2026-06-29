# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Commands

```sh
# Lint the chart
helm lint devopscoop/app

# Render all templates (use test.values.yaml to exercise every feature)
helm template devopscoop/app -f devopscoop/app/test.values.yaml

# Diff against a vanilla helm create output to spot unintentional drift
cd /tmp && helm create app && cd - && diff -r -y -w -W 240 --color=always /tmp/app devopscoop/app/ | less -R
```

## Architecture

This repo contains a single Helm chart at `devopscoop/app/` — a generic, reusable application chart that extends the default `helm create` boilerplate.

**Key design decisions:**

- `workload.yaml` renders either a `Deployment` or `StatefulSet` based on `workloadType`. A `_helpers.tpl` validator fails fast on invalid values.
- Environment variables have a preference order: `envConfigMap`/`envSecret` auto-create a ConfigMap/Secret and wire `envFrom`; `envConfigMapName`/`envSecretName` reference externally-managed ones; `env` maps directly to the container spec. `secrets` (deprecated) creates a Secret and injects each key via `valueFrom.secretKeyRef`. When `envConfigMap` or `envSecret` is set, a checksum annotation is added to the workload so pods roll automatically on config changes.
- `poddisruptionbudget.yaml` only renders when `podDisruptionBudget.enabled` is true **and** `replicaCount > 1` — a single-replica PDB would block voluntary disruptions entirely.
- The headless Service (`headless-service.yaml`) is auto-created for StatefulSets with a default name of `<fullname>-headless`, overridable via `statefulSet.serviceName`.
- Ingress (`ingress.yaml`, `ingress.enabled`) and Gateway API (`httproute.yaml`, `httpRoute.enabled`) are independent toggles — pick one depending on the cluster. The Ingress template stays compatible with pre-1.18 clusters by setting the legacy `kubernetes.io/ingress.class` annotation when `ingress.className` is given.
- `app.fullname` defaults to the bare release name (no chart-name suffix), overridable via `fullnameOverride`. Resource-type suffixes like `-headless` and `-env` are layered on top of it.

**Design rationale (`arguments/`):**

- The `arguments/*.argdown` files are [Argdown](https://argdown.org/) argument maps capturing the reasoning behind contested design decisions (e.g. `envFrom` vs `env`, one Helm release per Deployment). Read them before reopening a settled debate, and add a new map when making a similarly contested call.

**Versioning:**

- `version` in `devopscoop/app/Chart.yaml` is bumped by hand ([SemVer](https://semver.org/)) when a change should be released. The publish pipeline skips pushing when that version already exists in the registry.

**Community files:**

- `.github/PULL_REQUEST_TEMPLATE.md` — PR checklist (GitHub).
- `.gitlab/merge_request_templates/` — MR checklist (GitLab).
- `artifacthub-repo.yml` — ownership verification for ArtifactHUB (fill in `repositoryID` after registering).

**CI / publishing pipeline (`pipeline.sh`):**

- `push-rc`: packages with a calver suffix (`<version>-rc.<timestamp>`) and pushes to the OCI registry.
- `push`: packages with the exact `version` from `Chart.yaml` and pushes. Skips if that version already exists in the registry.
- Runs on GitHub Actions, GitLab CI, and Woodpecker CI — all call the same `pipeline.sh` script. The registries are `ghcr.io`, `registry.gitlab.com`, and `codeberg.org` respectively.
