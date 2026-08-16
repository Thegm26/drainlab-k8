# Lab 02 — PodDisruptionBudget and drain safety

This lab demonstrates the difference between **availability protection** and
**feasible rescheduling**.

## Scenario

The local Kind cluster has three worker nodes. The `web` application has three
replicas, each with required pod anti-affinity, so each replica occupies a
different worker. A PodDisruptionBudget (PDB) requires at least two replicas
to remain available.

## What we will observe

1. Draining the first worker evicts one `web` Pod because the PDB permits one
   disruption.
2. Its replacement becomes `Pending`: the drained worker is cordoned and the
   other two workers already host `web` Pods.
3. The PDB then permits zero further disruptions.
4. Draining a second worker is blocked by the PDB.

This is a safe but incomplete maintenance state: Kubernetes preserves the
minimum availability target, while the desired replica count cannot be
restored without a feasible placement.

## Files to build

```text
kind-cluster.yaml  # one control-plane plus three workers
namespace.yaml     # drainlab namespace
deployment.yaml    # three replicas, requests, anti-affinity
pdb.yaml           # minAvailable: 2
setup.sh            # guided replay
cleanup.sh          # remove only this lab's Kind cluster
```

## First step

Read the official [PodDisruptionBudget documentation](https://kubernetes.io/docs/tasks/run-application/configure-pdb/).
Then we will write `pdb.yaml` and explain each field before applying it.
