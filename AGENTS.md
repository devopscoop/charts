# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.
`CLAUDE.md` is a symlink to this file — edit `AGENTS.md`, never replace the symlink
with a copy.

## Commands

```sh
# Lint the chart
helm lint devopscoop/app

# Render all templates (test.values.yaml is the de facto test suite)
helm template devopscoop/app -f devopscoop/app/test.values.yaml

# test.values.yaml pins workloadType: Deployment and replicaCount: 1, so the
# StatefulSet, headless-Service, and PodDisruptionBudget branches never render
# under it. Override to cover them:
helm template devopscoop/app -f devopscoop/app/test.values.yaml \
  --set workloadType=StatefulSet --set replicaCount=2

# Render one template while iterating on it
helm template devopscoop/app -f devopscoop/app/test.values.yaml -s templates/workload.yaml

# Exercise the fail-fast validator (must abort, not render)
helm template devopscoop/app --set workloadType=DaemonSet

# Diff against a vanilla helm create output to spot unintentional drift
cd /tmp && helm create app && cd - && diff -r -y -w -W 240 --color=always /tmp/app devopscoop/app/ | less -R

# Smoke-test an installed release (templates/tests/test-connection.yaml; needs a cluster)
helm test <release-name>
```

There is no unit-test framework — `helm lint` plus rendering `test.values.yaml`
is the whole local test loop. When you add a value, add it to
`devopscoop/app/test.values.yaml` too, or nothing will ever render that branch.

## Architecture

This repo contains a single Helm chart at `devopscoop/app/` — a generic, reusable application chart that extends the default `helm create` boilerplate.

**Key design decisions:**

- `workload.yaml` renders either a `Deployment` or `StatefulSet` based on `workloadType`. A `_helpers.tpl` validator fails fast on invalid values.
- Environment variables have four independent injection paths, all of which may be active at once: `envConfigMap`/`envSecret` auto-create a ConfigMap/Secret named `<fullname>-env` and wire `envFrom`; `envConfigMapName`/`envSecretName` reference externally-managed ones; `env` maps directly to the container spec. `secrets` (deprecated) creates a Secret and injects each key via `valueFrom.secretKeyRef`. Precedence follows Kubernetes, and `workload.yaml` emits the `envFrom` entries in the order that makes it work: external refs first, chart-managed `-env` refs last (later `envFrom` wins), and `env`/`secrets` entries beat everything in `envFrom`. When `envConfigMap`, `envSecret`, or `secrets` is set, a checksum annotation is added to the workload so pods roll automatically on config changes.
- `poddisruptionbudget.yaml` only renders when `podDisruptionBudget.enabled` is true **and** `replicaCount > 1` — a single-replica PDB would block voluntary disruptions entirely.
- The headless Service (`headless-service.yaml`) is auto-created for StatefulSets with a default name of `<fullname>-headless`, overridable via `statefulSet.serviceName`.
- Ingress (`ingress.yaml`, `ingress.enabled`) and Gateway API (`httproute.yaml`, `httpRoute.enabled`) are independent toggles — pick one depending on the cluster. The Ingress template stays compatible with pre-1.18 clusters by setting the legacy `kubernetes.io/ingress.class` annotation when `ingress.className` is given.
- `app.fullname` defaults to the bare release name (no chart-name suffix), overridable via `fullnameOverride`. Resource-type suffixes like `-headless` and `-env` are layered on top of it.
- `service.enabled: false` drops the container's `ports:` block along with the Service — the container port is not configured independently. `service.port` is also what the helm test pod wgets, so it has to stay in sync with what the app actually listens on.

**Design rationale (`arguments/`):**

- The `arguments/*.argdown` files are [Argdown](https://argdown.org/) argument maps capturing the reasoning behind contested design decisions (e.g. `envFrom` vs `env`, one Helm release per Deployment). Read them before reopening a settled debate, and add a new map when making a similarly contested call.

**Versioning:**

- `version` in `devopscoop/app/Chart.yaml` is bumped by hand ([SemVer](https://semver.org/)) when a change should be released. The publish pipeline skips pushing when that version already exists in the registry.

**Community files:**

- `.github/PULL_REQUEST_TEMPLATE.md` — PR checklist (GitHub).
- `.gitlab/merge_request_templates/` — MR checklist (GitLab).
- `artifacthub-repo.yml` — ownership verification for ArtifactHUB (fill in `repositoryID` after registering).

**CI / publishing pipeline (`pipeline.sh`):**

- `push-rc`: packages with a calver suffix (`<version>-rc.<timestamp>`) and pushes to the OCI registry. Runs on pull/merge requests.
- `push`: packages with the exact `version` from `Chart.yaml` and pushes. Skips if that version already exists in the registry. Runs on merges to `main`.
- Runs on GitHub Actions, GitLab CI, and Woodpecker CI — all call the same `pipeline.sh` script. The registries are `ghcr.io`, `registry.gitlab.com`, and `codeberg.org` respectively. Each CI config's only job is to export the four env vars `pipeline.sh` reads — `helm_registry`, `helm_username`, `helm_password`, `registry_namespace` — and then call it. The script runs under `set -Eeuo pipefail`, so a missing one is a hard failure; it also logs into the registry, so don't run it locally without meaning to.
- Both `push` modes also `oras push` `artifacthub-repo.yml` under the reserved `artifacthub.io` tag, because OCI registries have no raw-file URL for ArtifactHub to read.
- The chart list in `pipeline.sh` is a hardcoded one-element loop (`for chart in devopscoop/app`). A second chart means editing that loop and the `helm lint` line above it.
- `.github/workflows/claude.yml` and `claude-code-review.yml` run this repo's Claude Code automation. They pin the action to a SHA and the model/effort via `claude_args` so CI doesn't drift with CLI defaults — keep both pinned when editing.

## Package manifests

This repo ships a `Brewfile` (macOS: `brew bundle`) and a `pkglist.txt` (Arch Linux) that install every local CLI tool the repo uses. Keep them in sync with the code:

- When you add a tool, script, or a new external command inside an existing script, add the package to BOTH files, with a comment noting what uses it.
- When a tool stops being used, remove it from both files.
- CI-only tooling (oras self-installs inside pipeline.sh on CI runners; trivy is baked into the ghaups action image) does NOT belong in the manifests — only tools a contributor runs locally.
- Verify package names before adding them: `brew info <formula>` for Homebrew, and the official repos/AUR for Arch. If a package is AUR-only, note that in pkglist.txt's header instructions.
- Update the "Install required packages" section in README.md if the tool list changes.
