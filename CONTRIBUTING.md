# Contributing

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

### 5. Bump the chart version

If your change should be released, bump `version` in
`devopscoop/app/Chart.yaml` following [Semantic Versioning](https://semver.org/).
The publish pipeline skips pushing when the version already exists in the
registry, so an unbumped version means your change won't be published.

### 6. Open a PR

Push your branch and open a pull request against the `main` branch.

The CI will:

1. **Lint and template-render** the chart (`.github/workflows/helm.yaml` on PR).
1. **Publish an RC** (`<chart-version>-rc.<timestamp>`) to the OCI registries for
   testing (`.github/workflows/helm.yaml` on PR, GitLab CI MR, Woodpecker CI PR).

Once merged to `main`, the pipeline packages the chart at the `version` in
`Chart.yaml` and pushes it to all three OCI registries.

## Adding a new chart

To add a second chart (e.g. `devopscoop/another-chart`):

1. Copy the structure from `devopscoop/app/` as a starting point.
1. Update `pipeline.sh` to include it in the loop.
