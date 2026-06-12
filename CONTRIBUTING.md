# Contributing

## What is this repo?

This repo publishes reusable [Helm](https://helm.sh/) charts as OCI artifacts to
`ghcr.io`, `registry.gitlab.com`, and `codeberg.org`. Currently it contains one
chart — `devopscoop/app/` — a generic application chart that extends the default
`helm create` boilerplate with StatefulSet support, multiple env-var injection
patterns, Gateway API HTTPRoute, PDBs, and more.

## Prerequisites

- [Helm](https://helm.sh/docs/intro/install/) 3.x
- `git`

## Making a change

### 1. Fork and clone

```sh
git clone https://github.com/<your-username>/charts
cd charts
```

### 2. Understand the chart

Read the chart's `values.yaml` (`devopscoop/app/values.yaml`) — it documents
every option and the reasoning behind it. Key design decisions are captured as
[Argdown](https://argdown.org/) maps in `arguments/`.

The templates are in `devopscoop/app/templates/`. The main entrypoint is
`workload.yaml`, which renders either a `Deployment` or `StatefulSet` based on
`.Values.workloadType`.

### 3. Make your edit

Add a new template, modify an existing one, or adjust `values.yaml`. If you are
adding a new chart, create a new directory under `devopscoop/` (see _Adding a
new chart_ below).

### 4. Test locally

```sh
# Syntax-check the chart
helm lint devopscoop/app

# Render all templates with the test values (exercises every feature)
helm template devopscoop/app -f devopscoop/app/test.values.yaml

# Diff against a vanilla `helm create` to spot accidental drift
cd /tmp && helm create app && cd - && diff -r -y -w -W 240 --color=always /tmp/app devopscoop/app/ | less -R
```

### 5. Commit with a conventional commit message

This repo uses [release-please](https://github.com/googleapis/release-please) to
automate versioning and changelog generation. It relies on the
[Conventional Commits](https://www.conventionalcommits.org/) format in commit
messages and PR titles.

The format is:

```
type(scope): description

types: feat, fix, chore, docs, refactor, test, ci, perf
scope:  optional, e.g. ingress, hpa, pdb
```

Examples:

```
feat: add support for init containers
fix(ingress): correct path escaping with special characters
chore(deps): bump nginx image tag
docs: explain envConfigMap vs envSecret in values.yaml
```

- **`feat`** bumps the minor version (e.g. `0.11.0` → `0.12.0`).
- **`fix`** bumps the patch version (e.g. `0.11.0` → `0.11.1`).
- **`feat!` or `fix!`** (with `!`) bumps the major version.
- Other types (`chore`, `docs`, `refactor`, `test`, `ci`, `perf`) do not produce
  a changelog entry and do not bump the version.

**Do not edit `version` in `Chart.yaml` by hand.** release-please manages it.

### 6. Open a PR

Push your branch and open a pull request against the `main` branch.

The CI will:

1. **Check your PR title** follows conventional commits (`.github/workflows/lint-pr.yaml`).
1. **Lint and template-render** the chart (`.github/workflows/helm.yaml` on PR).
1. **Publish an RC** (`<chart-version>-rc.<timestamp>`) to the OCI registries for
   testing (`.github/workflows/helm.yaml` on PR, GitLab CI MR, Woodpecker CI PR).

### 7. After merge

When the PR is merged to `main`:

1. **release-please** creates or updates a release PR that bumps the chart
   version, updates `CHANGELOG.md`, and groups changes by conventional commit
   type.
1. When that release PR is merged, release-please creates a **GitHub Release**
   and a **git tag** (`app/v*.*.*`).
1. **The CI pipeline** packages the chart at the new version and pushes it to
   all three OCI registries.

## Adding a new chart

To add a second chart (e.g. `devopscoop/another-chart`):

1. Copy the structure from `devopscoop/app/` as a starting point.
1. Update `pipeline.sh` to include it in the loop.
1. Add a package entry in `release-please-config.json` so release-please
   manages its version independently.
1. Add a version entry in `.release-please-manifest.json`.
