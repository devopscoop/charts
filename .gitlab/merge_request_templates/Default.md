## Description

What does this MR change? Why is it needed?

## Checklist

- [ ] `version` in `devopscoop/app/Chart.yaml` is bumped if this should be released.
- [ ] `helm lint devopscoop/app` passes.
- [ ] `helm template devopscoop/app -f devopscoop/app/test.values.yaml` produces
  expected output.
- [ ] New values are documented in `values.yaml`.
- [ ] If this adds or changes a design decision, an Argdown map in `arguments/`
  explains the rationale.

## Related issues

Closes #...
