#!/usr/bin/env bash

# Remove only the local Kind cluster created by Lab 01.
set -euo pipefail

CLUSTER_NAME="drainlab-lab"
CONTEXT_NAME="kind-${CLUSTER_NAME}"

confirm() {
  local answer
  read -r -p "$1 [y/N] " answer
  [[ "$answer" =~ ^([yY]|[yY][eE][sS])$ ]]
}

command -v kind >/dev/null || {
  echo "Missing required command: kind" >&2
  exit 1
}

echo "--- Current Lab 01 state ---"
if kind get clusters | grep -Fxq "$CLUSTER_NAME"; then
  if command -v kubectl >/dev/null; then
    kubectl --context "$CONTEXT_NAME" get nodes 2>/dev/null || true
    kubectl --context "$CONTEXT_NAME" get deployment,pods -n drainlab -o wide 2>/dev/null || true
  fi
else
  echo "Kind cluster '$CLUSTER_NAME' does not exist."
fi
echo "----------------------------"

if [[ "${1:-}" != "--yes" ]] && ! confirm "Delete the local Kind cluster '$CLUSTER_NAME' and all resources inside it"; then
  echo "Cleanup cancelled."
  exit 0
fi

if kind get clusters | grep -Fxq "$CLUSTER_NAME"; then
  kind delete cluster --name "$CLUSTER_NAME"
else
  echo "Kind cluster '$CLUSTER_NAME' does not exist."
fi

# kind normally removes these entries itself. Remove any stale named entries too.
if command -v kubectl >/dev/null; then
  if kubectl config get-contexts -o name | grep -Fxq "$CONTEXT_NAME"; then
    kubectl config delete-context "$CONTEXT_NAME"
  fi
  if kubectl config get-clusters | grep -Fxq "$CONTEXT_NAME"; then
    kubectl config delete-cluster "$CONTEXT_NAME"
  fi
  if kubectl config get-users | grep -Fxq "$CONTEXT_NAME"; then
    kubectl config delete-user "$CONTEXT_NAME"
  fi
fi

echo "Lab 01 cleanup complete. Repository files were not changed."
