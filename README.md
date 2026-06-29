# Helm Charts

Reusable Helm charts.

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
helm install my-app oci://registry.gitlab.com/devopscoop/charts/app --version 0.11.0
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
  url: oci://registry.gitlab.com/devopscoop/charts
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
    chart: oci://registry.gitlab.com/devopscoop/charts/app
    version: 0.11.0
```

### Helm CLI

```sh
# Latest
helm install my-app oci://registry.gitlab.com/devopscoop/charts/app

# Specific version
helm install my-app oci://registry.gitlab.com/devopscoop/charts/app --version 0.11.0
```

### Registries

Charts are published to all three registries on every release.
Replace the registry URL to match your preferred platform:

| Platform | Registry |
|----------|----------|
| GitHub   | `oci://ghcr.io/devopscoop/charts/app` |
| GitLab   | `oci://registry.gitlab.com/devopscoop/charts/app` |
| Codeberg | `oci://codeberg.org/devopscoop/charts/app` |

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

- Bump `version` in `devopscoop/app/Chart.yaml` ([SemVer](https://semver.org/))
  when a change should be released.

## License

[MIT](LICENSE)
