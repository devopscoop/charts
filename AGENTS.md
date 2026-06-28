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

**Conventional commits:**

- All commits and PR titles must follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `chore:`, etc.). Enforced on PRs by `amannn/action-semantic-pull-request` in `.github/workflows/lint-pr.yaml`.

**Release automation (`release-please`):**

- `release-please-config.json` + `.release-please-manifest.json` drive release-please on all three CI platforms:
  - **GitHub Actions** (`.github/workflows/release-please.yaml`): `googleapis/release-please-action` creates a release PR, then a GitHub Release + tag on merge.
  - **GitLab CI** (`.gitlab-ci.yml`): `release-please release-pr` creates a merge request via the GitLab API (experimental — verify after first push).
  - **Woodpecker CI** (`.woodpecker/helm.yaml`): `release-please release-pr` creates a PR via the Gitea API on Codeberg (experimental — verify after first push).
- On every push to main, release-please maintains a release PR/MR that bumps `version` in `Chart.yaml`, updates `CHANGELOG.md`, and groups changes by type. When the release PR/MR is merged, it creates the corresponding platform release (GitHub Release, GitLab Release, Codeberg Release) and tag.
- **Do NOT bump `version` in `Chart.yaml` by hand** — release-please manages it based on conventional commit history.

**Community files:**

- `CODE_OF_CONDUCT.md` — Contributor Covenant v2.1.
- `SECURITY.md` — instructions for reporting vulnerabilities privately.
- `.github/PULL_REQUEST_TEMPLATE.md` — PR checklist (GitHub).
- `.gitlab/merge_request_templates/` — MR checklist (GitLab).
- `.github/dependabot.yml` — weekly dependency bumps for GitHub Actions.
- `.github/workflows/stale.yaml` — closes stale issues and PRs after 60 days.
- `artifacthub-repo.yml` — ownership verification for ArtifactHUB (fill in `repositoryID` after registering).

**CI / publishing pipeline (`pipeline.sh`):**

- `push-rc`: packages with a calver suffix (`<version>-rc.<timestamp>`) and pushes to the OCI registry.
- `push`: packages with the exact `version` from `Chart.yaml` and pushes. Skips if that version already exists in the registry.
- Runs on GitHub Actions, GitLab CI, and Woodpecker CI — all call the same `pipeline.sh` script. The registries are `ghcr.io`, `registry.gitlab.com`, and `codeberg.org` respectively.
