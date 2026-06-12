# Helm Charts

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Helm](https://img.shields.io/badge/helm-3.x-0F1689?logo=helm&labelColor=0F1689&color=gray)](https://helm.sh/)
[![release-please](https://img.shields.io/badge/release--please-blue?logo=google)](https://github.com/googleapis/release-please)

Reusable Helm charts published to GitHub Container Registry, GitLab Container
Registry, and Codeberg Container Registry.

## Charts

### [app](devopscoop/app/)

A generic application chart that extends the default `helm create` boilerplate.
Use it to deploy web services, workers, and stateful workloads on Kubernetes.

**Features**

- `Deployment` or `StatefulSet` via `workloadType`
- Init containers, custom command/args
- Multiple env-var injection patterns (`envConfigMap`, `envSecret`, `env`, `secrets`)
- Ingress + Gateway API HTTPRoute (independent toggles)
- Horizontal Pod Autoscaler
- PodDisruptionBudget (auto-disabled when `replicaCount <= 1`)
- ServiceAccount, volumes, probes, affinity, tolerations
- Rolling checksum annotations on config changes

Full documentation in [`devopscoop/app/values.yaml`](devopscoop/app/values.yaml).
Design rationales in [`arguments/`](arguments/).

## Quick start

```sh
helm install my-app oci://ghcr.io/devopscoop/app --version 0.11.0
```

See [Usage](#usage) for more deployment options.

## Usage

### FluxCD

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: devopscoop
spec:
  interval: 60m
  url: oci://ghcr.io/devopscoop
  type: oci
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: my-app
spec:
  chart:
    spec:
      chart: app
      version: 0.11.0
      sourceRef:
        kind: HelmRepository
        name: devopscoop
```

### Helmfile

```yaml
releases:
  - name: my-app
    chart: oci://ghcr.io/devopscoop/app
    version: 0.11.0
```

### Helm CLI

```sh
# Latest
helm install my-app oci://ghcr.io/devopscoop/app

# Specific version
helm install my-app oci://ghcr.io/devopscoop/app --version 0.11.0
```

### Registries

Charts are published to all three registries on every release.
Replace the registry URL to match your preferred platform:

| Platform | Registry |
|----------|----------|
| GitHub   | `oci://ghcr.io/devopscoop/app` |
| GitLab   | `oci://registry.gitlab.com/devopscoop/app` |
| Codeberg | `oci://codeberg.org/devopscoop/app` |

## Local development

```sh
# Lint
helm lint devopscoop/app

# Render all templates with test values
helm template devopscoop/app -f devopscoop/app/test.values.yaml

# Diff against a stock helm create
cd /tmp && helm create _app && cd - && diff -r -y -W 240 /tmp/_app devopscoop/app/
```

For more detail, see [CONTRIBUTING.md](CONTRIBUTING.md).

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

- All PR titles must follow [Conventional Commits](https://www.conventionalcommits.org/).
- Versioning is automated by [release-please](https://github.com/googleapis/release-please).
- **Do not bump `version` in `Chart.yaml` by hand.**

## License

[MIT](LICENSE)
