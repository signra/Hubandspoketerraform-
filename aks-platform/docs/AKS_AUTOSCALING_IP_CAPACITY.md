# AKS Autoscaling Profile + Azure CNI IP Capacity Check (Terraform Guidance)

## Purpose

This document explains how to plan AKS autoscaling safely when using Azure CNI, where pods consume IPs from the AKS subnet.

It gives:
- a Terraform autoscaling profile pattern,
- an IP-capacity formula,
- and a pre-change checklist before scale operations.

---

## 1) Why this matters for Azure CNI

With `network_plugin = "azure"`, each scheduled pod receives a subnet IP.
That means scaling is constrained by:
1. node capacity,
2. pod density (`max_pods`), and
3. available subnet addresses.

If subnet capacity is insufficient, scale-out can fail even when CPU/memory appears available.

---

## 2) Recommended Terraform autoscaling pattern

Use node-pool autoscaling controls and keep pod density explicit.

### Suggested AKS default node pool pattern

```hcl
default_node_pool {
  name                = "system"
  vm_size             = var.vm_size
  vnet_subnet_id      = var.subnet_id
  max_pods            = var.max_pods

  enable_auto_scaling = true
  min_count           = var.min_node_count
  max_count           = var.max_node_count

  upgrade_settings {
    max_surge = "33%"
  }
}
```

### Suggested cluster autoscaler profile pattern

```hcl
auto_scaler_profile {
  balance_similar_node_groups      = true
  expander                         = "least-waste"
  max_graceful_termination_sec     = "600"
  max_node_provisioning_time       = "15m"
  max_unready_nodes                = 3
  max_unready_percentage           = 45
  new_pod_scale_up_delay           = "0s"
  scale_down_delay_after_add       = "10m"
  scale_down_delay_after_delete    = "10s"
  scale_down_delay_after_failure   = "3m"
  scale_down_unneeded              = "10m"
  scale_down_unready               = "20m"
  scale_down_utilization_threshold = "0.5"
  scan_interval                    = "10s"
  skip_nodes_with_local_storage    = false
  skip_nodes_with_system_pods      = true
}
```

Notes:
- Start with conservative values and tune from metrics.
- Keep `max_pods` realistic for your workload shape.
- For production, consider separate system/user node pools.

---

## 3) IP-capacity formula check

For Azure CNI subnet planning, use this conservative estimate:

$$
\text{Required IPs} = (N_{max} \times P_{max}) + N_{max} + S + B
$$

Where:
- $N_{max}$ = maximum autoscaled nodes (`max_node_count`)
- $P_{max}$ = maximum pods per node (`max_pods`)
- $S$ = surge/headroom IPs for upgrades and rolling changes
- $B$ = buffer for platform growth and operational safety

### Practical defaults for planning
- Set $S$ to 10–30% of `(Nmax × Pmax)` depending on update strategy.
- Set $B$ to at least 20–30 IPs (higher for bursty environments).

### Example
- `max_node_count = 10`
- `max_pods = 30`
- `S = 30`
- `B = 30`

Then:

$$
\text{Required IPs} = (10 \times 30) + 10 + 30 + 30 = 370
$$

A `/24` subnet (~251 usable addresses) is not sufficient; plan a larger subnet (for example `/23` or larger depending on growth target).

---

## 4) Pre-scale checklist (must pass)

1. Confirm target `max_node_count` and `max_pods`.
2. Calculate required IPs using the formula above.
3. Compare against effective available subnet IPs.
4. If insufficient, resize/re-architecture subnet before changing autoscale limits.
5. Run `terraform plan` and review AKS/node pool changes.
6. Apply in non-production first, then promote.

---

## 5) Suggested Terraform variable interface

```hcl
variable "max_pods" {
  type        = number
  description = "Maximum pods per node for Azure CNI planning"
}

variable "min_node_count" {
  type        = number
  description = "Minimum autoscaled node count"
}

variable "max_node_count" {
  type        = number
  description = "Maximum autoscaled node count"
}
```

This keeps compute scaling and IP capacity assumptions explicit and reviewable.

---

## 6) Operations note

After each autoscaling or pod-density change:
- monitor pending pods,
- monitor node provisioning latency,
- and review subnet utilization trends.

Treat network IP capacity as a first-class scaling SLO for Azure CNI clusters.

---

## 7) Enterprise test checklist (quick runbook)

Use this checklist for repeatable autoscaler validation in dev/non-prod.

### Pre-flight (must pass)
- [ ] Autoscaling enabled and bounds set (`min_node_count`, `max_node_count`).
- [ ] `max_pods` explicitly configured for Azure CNI planning.
- [ ] Regional and VM-family vCPU quota headroom confirmed.
- [ ] Subnet/IP headroom validated using:
  - $Required\ IPs = (N_{max} \times P_{max}) + N_{max} + S + B$
- [ ] Rollback target defined (for example scale workload back to baseline replicas).

### Execution
- [ ] Capture baseline (`nodes`, `pods`, nodepool autoscaler settings).
- [ ] Apply staged load increase (example: 3 -> 15 -> 40 -> 90 replicas).
- [ ] Observe pending pods, node count, and scheduling latency at each stage.
- [ ] Collect cluster events and note any `NotTriggerScaleUp`/backoff messages.

### Pass criteria
- [ ] Node count increases within expected window when pending pods exist.
- [ ] Pending pods drain after node scale-up.
- [ ] Service remains available during the test.

### Fail criteria
- [ ] Node count does not increase under sustained schedulable pressure.
- [ ] Events indicate repeated failed scale-up/backoff.
- [ ] Quota/subnet capacity constraints block provisioning.

### Post-test
- [ ] Return workload to baseline.
- [ ] Verify deployment and endpoint health.
- [ ] Record evidence (timestamps, node counts, events, quota snapshot, outcome).
