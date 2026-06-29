#!/usr/bin/env bash

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
# Not using "-x" because we aren't debugging.
set -Eeuo pipefail

# We get unbound var err if we don't set arg
arg="${1:-}"

echo "$helm_password" | helm registry login -u "$helm_username" --password-stdin "$helm_registry"

# `helm push` only handles charts, so we use oras to push the ArtifactHub
# repository metadata artifact (see the oras push in the loop below). Install it
# if the CI image doesn't already ship it. CI runners here are linux/amd64.
if ! command -v oras &> /dev/null; then
  oras_version="1.2.0"
  wget -q -O - "https://github.com/oras-project/oras/releases/download/v${oras_version}/oras_${oras_version}_linux_amd64.tar.gz" \
    | tar -xzf - -C /usr/local/bin oras
fi

# oras keeps its credential store separate from helm's, so log in again.
echo "$helm_password" | oras login -u "$helm_username" --password-stdin "$helm_registry"

#helm lint ${registry_namespace}/*
helm lint "devopscoop/app"

#for chart in devopscoop/*; do
for chart in devopscoop/app; do
  chart_name=$(echo "$chart" | cut -d/ -f2)
  chart_version=$(grep '^version: ' "${chart}/Chart.yaml" | cut -d' ' -f 2)

  # For RC builds, append the RC suffix with a calver timestamp.
  if [[ $arg == 'push-rc' ]]; then
    chart_version="${chart_version}-rc.$(date -u +%Y%m%d%H%M%S)"
    helm package "${chart}" --version "${chart_version}"
  else
    helm package "${chart}"
  fi

  # If chart already exists in the chart repository, don't push.
  if helm pull "oci://${helm_registry}/${registry_namespace}/${chart_name}" --version "${chart_version}" &> /dev/null; then
    echo -e "\e[31mWARNING: Chart ${chart_name} version ${chart_version} already exists in the repository.\nThis means that the chart's code has not changed, or you forgot to update the version in Chart.yaml.\e[0m"
  else
    if [[ $arg == 'push' || $arg == 'push-rc' ]]; then
      helm push "${chart_name}-${chart_version}.tgz" "oci://${helm_registry}/${registry_namespace}"
    fi
  fi

  # Push the ArtifactHub repository metadata under the reserved `artifacthub.io`
  # tag. OCI registries have no raw-file URL like git repos, so this is how
  # ArtifactHub reads ownership/verification info from artifacthub-repo.yml.
  # Pushed on both `push` and `push-rc` so the metadata is always present.
  if [[ $arg == 'push' || $arg == 'push-rc' ]]; then
    oras push "${helm_registry}/${registry_namespace}/${chart_name}:artifacthub.io" \
      --config /dev/null:application/vnd.cncf.artifacthub.config.v1+yaml \
      artifacthub-repo.yml:application/vnd.cncf.artifacthub.repository-metadata.layer.v1.yaml
  fi
done
