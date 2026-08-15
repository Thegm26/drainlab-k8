# drainlab-k8

A hands-on Kubernetes lab for learning the building blocks behind **DrainLab**,
a maintenance-aware workload rescheduling planner.

This repository deliberately starts small. Each directory is one runnable
experiment: write the YAML, apply it to a local Kind cluster, observe what
Kubernetes does, then record the result.

## Goal

By the end, I will be able to explain and demonstrate:

- how a Pod is scheduled onto a Node;
- why a Deployment keeps a requested number of replicas alive;
- how Services find Pods;
- how requests, affinity, taints and cordons restrict placement;
- how a PodDisruptionBudget protects availability during `kubectl drain`;
- why a drain can evict a Pod while its replacement remains Pending.

Those are the inputs and safety rules that DrainLab will later model and
optimise before maintenance starts.

## Lab path

1. `01-cluster` — create and inspect a local Kind cluster.
2. `02-namespace` — isolate this lab in a Namespace.
3. `03-pod` — run one NGINX Pod and inspect its assigned Node.
4. `04-deployment` — declare replicas and watch the controller reconcile.
5. `05-service` — expose Pods through a stable Service.
6. `06-placement-rules` — add resource requests and pod anti-affinity.
7. `07-pdb` — protect the application with a PodDisruptionBudget.
8. `08-maintenance` — cordon and drain a node; inspect eviction and scheduling.
9. `09-experiment` — reproduce an unsafe maintenance plan and document it.

## Working method

For every step:

1. Create the smallest possible YAML yourself.
2. Run `kubectl apply -f <file>`.
3. Inspect the result using `kubectl get`, `kubectl describe`, and events.
4. Write a few notes: what you expected, what happened, and why.
5. Commit the completed experiment.

## Cluster

The first session uses a local [Kind](https://kind.sigs.k8s.io/) cluster.
Check the active connection before any command:

```bash
kubectl config current-context
kubectl get nodes
```

Expected context for this lab: `kind-drainlab-demo`.

## First exercise

Create `01-cluster/README.md`. Record the output of:

```bash
kubectl cluster-info
kubectl get nodes
```

Then answer in your own words: **what is a control-plane node, what is a
worker node, and why should ordinary application Pods normally run on workers?**

## Scope

This is a learning and experiment repository, not a production Kubernetes
distribution. The future `DrainLab` repository contains the optimisation and
rescheduling planner itself.
