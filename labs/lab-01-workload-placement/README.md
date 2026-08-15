# Lab 01 — Workload placement

This guided scenario builds the foundations needed to reason about safe
workload placement during node maintenance.

## What it creates

1. A local Kind cluster named `drainlab-lab` with one control-plane and two
   worker nodes.
2. The `drainlab` Namespace.
3. A standalone Pod, followed by a two-replica Deployment.
4. CPU and memory requests for the workload.
5. Required pod anti-affinity so `web` replicas cannot share a worker.
6. A cordon-and-delete experiment that leaves a replacement Pod Pending until
   a valid worker becomes available.

## Run the lab

From the repository root:

```bash
./labs/lab-01-workload-placement/setup.sh
```

The script asks for confirmation before every stage. If `drainlab-lab`
already exists, it also asks before recreating it. Before each Pod or
Deployment change, it starts a live Pod watch and waits so you can observe
states such as `Pending`, `ContainerCreating`, `Running`, and `Terminating`.
Its final prompt can remove the local Kind cluster as part of the replay.

## Visual explanation

The GitHub Pages visual explains why two co-located replicas are not enough:
`https://thegm26.github.io/drainlab-k8/lab-01/`.

## Clean up

```bash
./labs/lab-01-workload-placement/cleanup.sh
```

This deletes only the local `drainlab-lab` Kind cluster and its Kubernetes
resources. It does not delete repository files or other Kind clusters.

## Source manifests

The setup script applies the incremental manifests in:

```text
01-cluster/
02-namespace/
03-pod/
04-deployment/
05-resources/
06-placement-rules/
```
