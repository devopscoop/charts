# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

**CI / publishing pipeline (`pipeline.sh`):**

- `push-rc`: packages with a calver suffix (`<version>-rc.<timestamp>`) and pushes to the OCI registry.
- `push`: packages with the exact `version` from `Chart.yaml` and pushes. Skips if that version already exists in the registry.
- Runs on GitHub Actions, GitLab CI, and Woodpecker CI — all call the same `pipeline.sh` script. The registries are `ghcr.io`, `registry.gitlab.com`, and `codeberg.org` respectively.
- **Bump `version` in `Chart.yaml` for every change** — the pipeline will skip the push silently if the version already exists.
