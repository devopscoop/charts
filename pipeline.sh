#!/usr/bin/env bash

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
# Not using "-x" because we aren't debugging.
set -Eeuo pipefail

# We get unbound var err if we don't set arg
arg="${1:-}"

echo "$helm_password" | helm registry login -u "$helm_username" --password-stdin "$helm_registry"

#helm lint ${git_repo_owner}/*
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
  if helm pull "oci://${helm_registry}/${git_repo_owner}/charts/${chart_name}" --version "${chart_version}" &> /dev/null; then
    echo -e "\e[31mWARNING: Chart ${chart_name} version ${chart_version} already exists in the repository.\nThis means that the chart's code has not changed, or you forgot to update the version in Chart.yaml.\e[0m"
  else
    if [[ $arg == 'push' || $arg == 'push-rc' ]]; then
      helm push "${chart_name}-${chart_version}.tgz" "oci://${helm_registry}/${git_repo_owner}/charts"
    fi
  fi
done
