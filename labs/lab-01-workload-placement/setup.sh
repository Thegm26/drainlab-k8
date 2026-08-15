#!/usr/bin/env bash

# Replay the Kubernetes placement lab one checkpoint at a time.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLUSTER_NAME="drainlab-lab"
CONTEXT_NAME="kind-${CLUSTER_NAME}"
NAMESPACE="drainlab"
WORKER_ONE="${CLUSTER_NAME}-worker"
WATCH_PID=""
NODE_WATCH_PID=""
CLUSTER_READY=false

show_current_state() {
  echo
  echo "--- Current lab state ---"
  if [[ "$CLUSTER_READY" != true ]]; then
    kind get clusters || true
    echo "-------------------------"
    return
  fi

  kubectl get nodes
  if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    kubectl get deployment,pods -n "$NAMESPACE" -o wide
  else
    echo "Namespace '$NAMESPACE' has not been created yet."
  fi
  echo "-------------------------"
}

confirm() {
  local answer
  show_current_state
  read -r -p "$1 [y/N] " answer
  [[ "$answer" =~ ^([yY]|[yY][eE][sS])$ ]]
}

cluster_exists() {
  kind get clusters | grep -Fxq "$CLUSTER_NAME"
}

require_command() {
  command -v "$1" >/dev/null || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

show_workload() {
  kubectl get deployment,pods -n "$NAMESPACE" -o wide
}

start_pod_watch() {
  echo "Starting live Pod watch. Watch the STATUS and NODE columns below."
  kubectl get pods -n "$NAMESPACE" -o wide --watch &
  WATCH_PID=$!
  sleep 1
}

stop_pod_watch() {
  if [[ -n "$WATCH_PID" ]] && kill -0 "$WATCH_PID" 2>/dev/null; then
    kill "$WATCH_PID" 2>/dev/null || true
    wait "$WATCH_PID" 2>/dev/null || true
  fi
  WATCH_PID=""
}

start_node_watch() {
  echo "Starting live Node watch. The workers may begin as NotReady while networking starts."
  kubectl get nodes --watch &
  NODE_WATCH_PID=$!
  sleep 1
}

stop_node_watch() {
  if [[ -n "$NODE_WATCH_PID" ]] && kill -0 "$NODE_WATCH_PID" 2>/dev/null; then
    kill "$NODE_WATCH_PID" 2>/dev/null || true
    wait "$NODE_WATCH_PID" 2>/dev/null || true
  fi
  NODE_WATCH_PID=""
}

observe_then_check() {
  echo "Waiting for the Deployment rollout to become ready while the Pod watch stays visible."
  kubectl rollout status deployment/web -n "$NAMESPACE" --timeout=60s
  stop_pod_watch
  show_workload
}

cleanup_watches() {
  stop_pod_watch
  stop_node_watch
}

trap cleanup_watches EXIT

require_command kind
require_command kubectl

echo "DrainLab Kubernetes Lab 01: workload placement"
echo "Repository: $ROOT_DIR"

if cluster_exists; then
  echo "Cluster '$CLUSTER_NAME' already exists."
  if confirm "Recreate it? This deletes all resources in that local cluster"; then
    kind delete cluster --name "$CLUSTER_NAME"
  fi
fi

if ! cluster_exists; then
  if confirm "Create the Kind cluster from 01-cluster/kind-cluster.yaml"; then
    kind create cluster --name "$CLUSTER_NAME" \
      --config "$ROOT_DIR/01-cluster/kind-cluster.yaml" --wait 60s
  else
    echo "Cannot continue without the lab cluster."
    exit 0
  fi
fi

kubectl config use-context "$CONTEXT_NAME" >/dev/null
start_node_watch
echo "Waiting for every node to become Ready before starting the lab."
kubectl wait --for=condition=Ready node --all --timeout=120s
stop_node_watch
kubectl get nodes
CLUSTER_READY=true

if confirm "02: create the drainlab Namespace"; then
  kubectl apply -f "$ROOT_DIR/02-namespace/namespace.yaml"
  kubectl get namespace "$NAMESPACE"
fi

if confirm "03: create the standalone web Pod"; then
  start_pod_watch
  kubectl apply -f "$ROOT_DIR/03-pod/pod.yaml"
  echo "Waiting for the Pod to become Ready while the live watch stays visible."
  kubectl wait --for=condition=Ready pod/web -n "$NAMESPACE" --timeout=60s
  stop_pod_watch
  kubectl get pod web -n "$NAMESPACE" -o wide
fi

if confirm "Delete the standalone Pod before introducing its Deployment"; then
  kubectl delete pod web -n "$NAMESPACE" --ignore-not-found
  kubectl get pods -n "$NAMESPACE"
fi

if confirm "04: create the two-replica Deployment"; then
  start_pod_watch
  kubectl apply -f "$ROOT_DIR/04-deployment/deployment.yaml"
  observe_then_check
fi

if confirm "05: add CPU and memory requests"; then
  start_pod_watch
  kubectl apply -f "$ROOT_DIR/05-resources/deployment.yaml"
  observe_then_check
fi

if confirm "06: enforce hard pod anti-affinity"; then
  start_pod_watch
  kubectl apply -f "$ROOT_DIR/06-placement-rules/deployment.yaml"
  observe_then_check
fi

if confirm "Experiment: cordon worker 1 and delete its web Pod"; then
  pod_on_worker="$(kubectl get pods -n "$NAMESPACE" -l app=web \
    --field-selector "spec.nodeName=$WORKER_ONE" \
    -o jsonpath='{.items[0].metadata.name}')"

  if [[ -z "$pod_on_worker" ]]; then
    echo "No web Pod found on $WORKER_ONE; inspect placement before running this experiment."
    exit 1
  fi

  kubectl cordon "$WORKER_ONE"
  start_pod_watch
  kubectl delete pod "$pod_on_worker" -n "$NAMESPACE"
  echo "The replacement should be Pending: worker 1 is cordoned and worker 2 already hosts web."
  echo "Watch for the Pending replacement, then press Enter."
  read -r
  kubectl get pods -n "$NAMESPACE" -o wide

  if confirm "Restore worker 1 and allow the replacement Pod to schedule"; then
    kubectl uncordon "$WORKER_ONE"
    kubectl rollout status deployment/web -n "$NAMESPACE" --timeout=60s
    stop_pod_watch
    show_workload
  else
    stop_pod_watch
    echo "To recover later: kubectl uncordon $WORKER_ONE"
  fi
fi

if confirm "Final cleanup: delete the local Lab 01 Kind cluster"; then
  "$ROOT_DIR/labs/lab-01-workload-placement/cleanup.sh" --yes
fi

echo "Lab replay complete."
