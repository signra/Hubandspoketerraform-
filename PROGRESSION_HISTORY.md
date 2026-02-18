# Hub-and-Spoke + AKS Platform Progression History

_Last updated: 2026-02-18_

## 1) Purpose of this document

This is a complete progression and knowledge log for this repository, combining:
- what was built,
- why each layer was added,
- issues encountered,
- how those issues were resolved,
- and what skills/operational lessons were gained.

It is written from the repository state and validation runs in this workspace.

---

## Executive summary (key achievements)

### Platform outcomes delivered
- Built a hub-and-spoke Terraform foundation with governance, logging, and budget controls.
- Evolved the AKS platform into reusable modules with isolated `dev`/`prod` environment states.
- Diagnosed and fixed provider compatibility issues that blocked root-stack validation.
- Deployed and verified a real web workload on AKS (pods, service, external endpoint response).
- Implemented explicit Azure CNI pod-density and autoscaling controls in Terraform.

### Operational maturity gained
- Adopted a repeatable change workflow: **plan → apply → runtime verification**.
- Used dev-first rollout to reduce blast radius before wider promotion.
- Treated subnet/IP capacity as a first-class scaling constraint for Azure CNI.
- Captured decisions, risks avoided, and evidence for auditability and handover.

### Current readiness snapshot
- Root and AKS environment stacks validate successfully.
- Dev AKS is operational and externally reachable.
- Autoscaling bounds and pod-density controls are now explicit and versioned.
- Documentation includes progression, rationale, formulas, runbooks, and decision logs.

---

## 2) What has been built so far

The repository now contains **two related Terraform stacks**:

1. **Root landing zone stack**
   - Hub-and-spoke network baseline
   - Shared security and governance components
   - Centralized state backend pattern

2. **AKS platform stack (`aks-platform/`)**
   - Environment-specific deployments (`dev`, `prod`)
   - Reusable modules (`resource-group`, `networking`, `log-analytics`, `aks`, `role-assignments`)
   - Independent remote state keys per environment

This shows a progression from a single, flat stack to a more modular platform layout.

---

## 3) Technical progression timeline

## Phase A — Foundation (Landing Zone Baseline)

### What was introduced
- Azure provider and backend configuration
- Hub, dev, and prod resource groups
- Hub, dev, and prod VNets
- Firewall subnet and Azure Firewall with public IP
- Log Analytics workspace
- Subscription budget notification
- Custom deny-public-IP policy
- Outputs for core network/firewall values

### Why this phase mattered
- Established core cloud guardrails and shared networking.
- Created a base for workloads to be onboarded into segmented environments.

### Knowledge gained
- How to structure foundational Azure resources in Terraform.
- Why central logging, policy, and budget controls belong in platform code.

---

## Phase B — Environment-aware AKS platformization

### What was introduced
- `aks-platform/environments/dev` and `aks-platform/environments/prod`
- Separate `terraform.tfvars` for each environment
- Separate backend state keys:
  - `aks-platform-dev.tfstate`
  - `aks-platform-prod.tfstate`
- Reusable modules for:
  - resource groups
  - networking (VNet + AKS subnet)
  - Log Analytics
  - AKS cluster
  - role assignments (prepared for RBAC extension)

### Why this phase mattered
- Reduced duplication and improved maintainability.
- Allowed controlled promotion patterns from dev to prod.
- Enabled safer changes with environment isolation.

### Knowledge gained
- Module interface design (inputs/outputs) and composition.
- Balancing defaults with environment overrides.
- State partitioning as a reliability and blast-radius control.

---

## Phase C — Validation and compile hardening

### Validation checks performed in this workspace
- Root stack: `terraform init -backend=false` + `terraform validate`
- AKS dev stack: `terraform init -backend=false` + `terraform validate`
- AKS prod stack: `terraform init -backend=false` + `terraform validate`

### Result
- AKS `dev`: valid
- AKS `prod`: valid
- Root: originally failed once, then fixed and validated successfully

---

## Phase D — AKS workload deployment + Azure CNI capacity hardening

### What was introduced
- A real workload deployment to existing AKS (`aks-dev`) using Kubernetes manifests.
- Namespace-scoped web app deployment and public service exposure.
- Explicit Azure CNI pod density control in Terraform via `max_pods` inputs.
- Environment-level AKS defaults updated to carry explicit `max_pods` values.

### Why this phase mattered
- Moved from infrastructure-only readiness to an actual application running on the platform.
- Verified that the cluster networking path works end-to-end (pods, service, load balancer).
- Reduced risk of silent pod IP exhaustion by replacing implicit defaults with explicit CNI planning controls.

### Deployment actions performed
- Retrieved AKS credentials for the existing `aks-dev` cluster.
- Applied workload manifest (`k8s/webapp.yaml`) containing:
  - `Namespace` (`webapp`)
  - `Deployment` (`3` replicas)
  - `Service` (`LoadBalancer`)
- Confirmed successful rollout and external ingress assignment.
- Validated endpoint reachability through the assigned public IP.

### CNI/IP posture observed during this phase
- Cluster network plugin confirmed as Azure CNI (`network_plugin = "azure"`).
- System node pool observed with `maxPods = 30`.
- AKS subnet observed at `/24` (`10.10.1.0/24`) with active IP consumption.

### Resolution and hardening implemented
- Added explicit `max_pods` variable in AKS module.
- Wired `max_pods` from both `dev` and `prod` environment stacks into the AKS module call.
- Set environment tfvars to explicit `max_pods = 30` for stable, predictable planning.
- Added autoscaling controls in module and environments:
  - `enable_auto_scaling`
  - `min_node_count`
  - `max_node_count`
- Added AKS `auto_scaler_profile` controls in module:
  - `scan_interval`
  - `scale_down_unneeded`
  - `scale_down_utilization_threshold`
- Re-ran Terraform validation in both environment stacks to verify compile integrity.

### Learning
- A successful `terraform apply` is only part of platform readiness; workload deployment validation is essential.
- For Azure CNI, pod density is an IP planning decision, not just a scheduling decision.
- Making pod-density settings explicit in Terraform reduces operational surprises during scale events.

---

## Phase E — Dev-only operational hardening and end-to-end verification

### What was done
- Scoped changes to **dev only** to reduce risk and confirm behavior before wider rollout.
- Ran Terraform `init` + `plan` in `aks-platform/environments/dev`.
- Applied only the reviewed dev plan (`0 add, 1 change, 0 destroy`) for AKS in-place update.
- Verified autoscaling state after apply:
  - `enableAutoScaling = true`
  - `minCount = 2`
  - `maxCount = 5`
  - `maxPods = 30`
- Verified runtime operations end-to-end:
  - AKS nodes in `Ready` state
  - Web app pods in `Running` state
  - LoadBalancer service with external IP
  - HTTP response from external endpoint

### Why it was done this way
- **Dev-first rollout** was chosen to control blast radius and validate module behavior safely.
- **Plan before apply** was used to confirm exact in-place changes and avoid unintended replacements.
- **Operational checks after IaC apply** were used because successful Terraform execution alone does not prove workload availability.
- **Autoscaling bounds (`min/max`) + `max_pods`** were kept explicit so both compute scaling and Azure CNI IP usage stay predictable.

### Learning outcomes
- Environment promotion discipline: validate in dev before prod.
- Change safety pattern: `plan` -> `apply` -> runtime verification.
- Platform thinking: infrastructure correctness and service operability are separate validation layers.
- Reliability mindset: autoscaling settings must be paired with subnet/IP capacity planning.

### Follow-up adjustment decision (headroom strategy)
- A temporary dev strategy was chosen to set `min_node_count = 1` in configuration to create quota headroom for autoscaler testing.
- **Execution status:** configuration updated in code; Terraform apply intentionally deferred in this session by user choice.

---

## Phase F — Controlled autoscaler stress test and quota root-cause finding

### Test objective
Validate AKS autoscaler behavior end-to-end by creating controlled scheduling pressure in dev.

### Test performed
- Baseline captured:
  - Node pool autoscaling enabled (`min=2`, `max=5`, `count=2`, `maxPods=30` at test time)
  - 2 ready nodes, web app healthy at 3 replicas
- Stress action:
  - Scaled `webapp` deployment to `90` replicas to force pending pods
- Observation:
  - Pending pods increased significantly (up to ~69 pending)
  - Node count remained at 2 during observation window
  - Kubernetes events repeatedly reported:
    - `NotTriggerScaleUp`
    - `pod didn't trigger scale-up: 1 in backoff after failed scale-up`
- Recovery:
  - Scaled workload back to 3 replicas
  - Confirmed deployment healthy and external endpoint still responding

### Root cause identified
Autoscaler behavior was blocked by subscription/region compute quota, not by Terraform autoscaler configuration.

Observed quota indicators (UK West):
- `Standard DSv3 Family vCPUs`: `4 / 4`
- `Total Regional vCPUs`: `4 / 4`

### Why this matters
- This demonstrates a real-world distinction between:
  1. **control plane configuration correctness** (autoscaler configured), and
  2. **cloud capacity permission to execute scaling** (quota headroom available).

### Learning outcomes
- Autoscaler validation must include quota checks as a hard prerequisite.
- Pending pods with `NotTriggerScaleUp` can indicate cloud-side provisioning constraints rather than scheduler logic errors.
- Recovery procedures (scale-down + health verification) are essential parts of safe platform testing.

---

## Enterprise-grade testing approach (how mature teams would run this)

### 1) Pre-flight gates (before any stress test)
- Confirm autoscaler config and node pool bounds in Terraform and live cluster.
- Confirm quota headroom in target region and VM family (regional + family-specific vCPUs).
- Confirm subnet/IP headroom against planned surge using Azure CNI capacity formula.
- Define clear abort thresholds and rollback plan.

### 2) Test design
- Use staged load ramps (for example 3 -> 15 -> 40 -> 90 replicas), not a single jump.
- Track SLO-aligned metrics during each stage:
  - pending pod count
  - node provisioning latency
  - pod scheduling latency
  - API server and cluster event health
- Keep test workloads representative but bounded (requests/limits set).

### 3) Evidence capture
- Capture timestamped outputs for:
  - `kubectl get nodes/pods/events`
  - AKS nodepool autoscaling state
  - Azure quota snapshots
- Store results in runbook artifacts for audit and trend comparison.

### 4) Pass/fail criteria
- **Pass:** autoscaler adds nodes within expected time, pending pods drain, service remains healthy.
- **Fail:** no node growth under schedulable pressure, quota/capacity errors, or service degradation.

### 5) Post-test controls
- Return workload to baseline.
- Verify endpoint and deployment health.
- Record findings, root cause, and remediation actions in progression/ops docs.

This approach separates configuration validation from cloud-capacity validation and produces repeatable, audit-ready operational evidence.

---

## 4) Issue history (what failed and how it was resolved)

## Issue 1 — Invalid policy assignment resource type

### Symptom
Terraform validation failed in root with:
- `Invalid resource type`
- `azurerm_policy_assignment` unsupported for the configured provider

### Root cause
The configuration used a generic policy assignment resource type that does not exist for the installed `azurerm` provider version in this repo.

### Resolution implemented
- Updated resource type from:
  - `azurerm_policy_assignment`
- To:
  - `azurerm_subscription_policy_assignment`

### Outcome
- Root stack now validates successfully.
- The policy assignment is now correctly scoped at subscription level.

### Learning
Always align policy assignment resource types to scope-specific AzureRM resources.

---

## Issue 2 — Potential network peering direction/mapping risk (design correctness)

### Symptom/risk observed
Several peering resources in the root stack appear to reference dev VNet/resource group repeatedly, including resources named for prod and hub return paths.

### Likely impact
- Incorrect or duplicate peering targets.
- Unexpected connectivity behavior between hub/dev/prod.

### Current status
- Not a Terraform compile error, but a **logic/design risk**.

### Recommended resolution path
- Re-map each peering to the intended VNet pair explicitly:
  - `dev_to_hub`: dev → hub
  - `hub_to_dev`: hub → dev
  - `prod_to_hub`: prod → hub
  - `hub_to_prod`: hub → prod
- Validate with `terraform plan` in a safe environment before apply.

### Learning
Validation catches syntax/provider errors, but design correctness requires peer-by-peer intent review.

---

## Issue 3 — Hard-coded operational values reducing portability

### Observed
Some root stack values are currently hard-coded (e.g., budget contact email, selected names/IDs/date values).

### Impact
- Harder to reuse across subscriptions/tenants.
- More friction for collaboration and CI/CD promotion.

### Recommended resolution path
- Move operational constants into variables and environment-specific tfvars.
- Keep secrets/identifiers out of shared defaults where possible.

### Learning
Parameterization is key to making platform code reusable and production-friendly.

---

## Issue 4 — Azure CNI subnet pressure risk during growth

### Symptom/risk observed
The AKS cluster uses Azure CNI with workload pod IPs allocated from the node subnet, while the active subnet size is `/24`.

### Why this is risky
- Azure CNI consumes subnet IPs for nodes and pods.
- As node count and pod density increase, subnet exhaustion can block scheduling and scale-out.

### Resolution implemented
- Made `max_pods` explicit in module and environment interfaces to control IP consumption intentionally.
- Implemented dev autoscaling bounds and validated the cluster remains healthy after in-place update.

### Remaining improvement path
- Add autoscaling profile and pre-scale IP capacity checks to operational runbooks.
- Resize subnet (for example `/23`) before high-growth scale targets.

### Learning
Cluster scaling safety requires both compute planning (SKU/node pools) and network capacity planning (subnet + pod density).

---

## 5) Skills progression captured by this work

### Infrastructure design
- Building hub-and-spoke foundations for segmented environments.
- Integrating governance and observability as first-class infrastructure.

### Terraform engineering
- Transitioning from flat files to module-driven architecture.
- Designing module contracts and environment composition.
- Managing backend state per environment.
- Converting implicit AKS defaults into explicit, versioned configuration (`max_pods`).

### Platform operations
- Using `validate` to catch provider/schema problems early.
- Understanding that `validate` + `plan` + design review are all necessary.
- Thinking in terms of blast radius, lifecycle, and change safety.
- Validating platform functionality through real workload rollout, not only IaC compile success.
- Treating post-apply service checks (nodes/pods/service/HTTP) as mandatory done-criteria for platform changes.

---

## 6) Current maturity snapshot

### Stable today
- AKS dev/prod module composition and validation flow
- Root stack compile success after policy assignment fix
- Clear separation between foundation and workload platform stacks
- Successful web app deployment and external exposure on existing AKS dev cluster
- Explicit Azure CNI `max_pods` control in Terraform module and environment stacks
- Autoscaling is implemented in Terraform with environment-specific bounds
- Dev environment has been fully verified operational after autoscaling update (cluster + workload + endpoint)

### Needs next improvement pass
- Network peering intent correction
- Additional outputs/docs to ease operational handoff
- Variable normalization and naming consistency
- Optional CI pipeline for automatic `fmt`, `validate`, and policy checks
- Subnet-aware IP capacity gates before large scale changes

---

## 7) Practical runbook commands for your ongoing learning

From repository root:

```bash
terraform init -backend=false
terraform validate
```

For AKS dev:

```bash
cd aks-platform/environments/dev
terraform init -backend=false
terraform validate
```

For dev operational verification (post-apply):

```bash
az aks show -g rg-aks-dev -n aks-dev --query "agentPoolProfiles[?name=='system'].{enableAutoScaling:enableAutoScaling,minCount:minCount,maxCount:maxCount,count:count,maxPods:maxPods}" -o table
kubectl get nodes -o wide
kubectl -n webapp get pods -o wide
kubectl -n webapp get svc webapp -o wide
```

For AKS prod:

```bash
cd aks-platform/environments/prod
terraform init -backend=false
terraform validate
```

For workload deployment verification:

```bash
az aks get-credentials --resource-group rg-aks-dev --name aks-dev --overwrite-existing
kubectl apply -f k8s/webapp.yaml
kubectl -n webapp rollout status deployment/webapp
kubectl -n webapp get svc webapp -o wide
```

When preparing changes to networking/security logic:

```bash
terraform plan
```

Use `plan` review to confirm intent before any `apply`.

---

## 8) Summary

You have progressed from a baseline landing zone to a structured AKS platform codebase with reusable modules and environment isolation. You also now have a concrete example of diagnosing and fixing provider/resource compatibility issues (`azurerm_subscription_policy_assignment`) and a clear checklist for the next maturity step (peering intent and portability hardening).

## 9) Reference docs added for next maturity stage

- AKS autoscaling profile + Azure CNI IP capacity guidance:
  - `aks-platform/docs/AKS_AUTOSCALING_IP_CAPACITY.md`

---

## 10) Decision log (knowledge record)

| Decision | Why it was chosen | Risk avoided | Evidence captured |
|---|---|---|---|
| Use modular AKS stack (`modules/*`) instead of flat resources | Reusability, environment consistency, easier maintenance | Configuration drift and duplicated logic | Successful `dev`/`prod` validation and shared module interfaces |
| Keep independent state keys per environment | Isolate blast radius and simplify promotion | Cross-environment state corruption | Separate backend keys: `aks-platform-dev.tfstate`, `aks-platform-prod.tfstate` |
| Fix policy assignment with scope-specific resource type | Match AzureRM provider schema and assignment scope | Failed root validation and broken governance rollout | Root validation success after switching to `azurerm_subscription_policy_assignment` |
| Deploy a real web app to validate platform | Prove runtime operability, not only IaC compile success | False confidence from Terraform-only checks | Running pods, LB external IP, successful HTTP response |
| Make `max_pods` explicit for Azure CNI | Control subnet IP consumption intentionally | Pod scheduling failures due to IP exhaustion | Module/env variables updated and validated |
| Roll out autoscaling in `dev` first | Safe change control before broader rollout | Production-impacting misconfiguration | Dev-only plan/apply with in-place update and health checks |
| Enforce `plan` -> `apply` -> runtime verification workflow | Predictable, auditable infrastructure operations | Unreviewed destructive changes and hidden runtime failures | Saved/checked plan, successful apply, node/pod/service checks |
