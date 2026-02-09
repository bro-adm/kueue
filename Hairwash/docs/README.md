# Kueue Metrics Testing Framework

This repository contains test infrastructure for triggering and validating Kueue metrics in operational scenarios. The test cases target metrics that exist in the codebase but require specific configurations or workload states to appear.

## Directory Structure

```
Hairwash/
├── docs/                        # Documentation
│   ├── README.md               # This file
│   └── GetAndCompareActualMetrics.md
├── manifests/                   # Kubernetes manifests for test scenarios
│   ├── 1-preemption-cohort-setup.yaml    # Test Case 1
│   ├── 1a-low-priority-jobs.yaml         # Test Case 1
│   ├── 1b-high-priority-jobs.yaml        # Test Case 1
│   ├── 2-eviction-test-setup.yaml        # Test Cases 2a & 2b (shared)
│   ├── 3-admission-checks-setup.yaml     # Test Case 3
│   ├── 3a-admission-checks-test-job.yaml # Test Case 3
│   └── unused/                           # Unused manifests (for reference)
├── scripts/                     # Automation scripts
│   ├── enable-fair-sharing.fish
│   ├── run-metrics-tests-no-cleanup.fish
│   └── cleanup-metrics-tests.fish
└── output/                      # Metrics collection outputs
    └── *.csv, *.txt
```

## Metrics Overview

Metrics relevant to this testing framework and their enablement configurations:

**Controller Configuration Requirements:**
- `metrics.enableClusterQueueResources: true`
- `featureGates.LocalQueueMetrics: true`
- `waitForPodsReady.enable: true`
- `fairSharing.enable: true`

**Note:** Fair sharing is enabled by default in upstream v0.15+, but the downstream RHOAI v0.11 build has it commented out in the default configuration.

**References:**
- [Metrics CSV](../output/upstream-metrics.csv)
- [Metrics Documentation](https://kueue.sigs.k8s.io/docs/reference/metrics/)
- [Metrics Code](../../pkg/metrics/metrics.go)

## Configuration Environments

### Default Kustomize Configuration

The default kustomize configuration enables visibility APIs and manager metrics. Prometheus components are disabled by default. The base configuration does not contain optional metrics enablement.

**Location:** `config/default/kustomization.yaml`

### Test Environment Configuration

The test manifests include optional metrics enabled:
- `metrics.enableClusterQueueResources: true`
- `featureGates.LocalQueueMetrics: true`

**Location:** `test/e2e/config/default`

### RedHat Build Specifics

The RedHat build is based on v1beta1 API (not upstream v1beta2). The following are enabled by default:
- `metrics.enableClusterQueueResources: true`
- `waitForPodsReady.enable: true`
- `featureGates.LocalQueueMetrics: true` (Alpha status)

**Configuration Locations:**
- Base: `config/components/manager/controller_manager_config.yaml`
- RHOAI: `config/rhoai/manager_config_patch.yaml`

**Note:** RedHat also changes default visibility on demand to false. This should not affect metrics export.

**Known Issue:** Installing the RedHat build of Kueue from the catalog does not apply the patch to enable the LocalQueueMetrics feature gate by default.

---

## Post-Installation Configuration Script

### Fair Sharing Enablement

The `enable-fair-sharing.fish` script enables fair sharing configuration in deployed Kueue instances that have this feature commented out (common in downstream v0.11 builds).

**Location:** `scripts/enable-fair-sharing.fish`

**What it does:**
1. Checks current ConfigMap configuration
2. Uncomments `fairSharing.enable: true` if disabled
3. Restarts the Kueue controller deployment
4. Waits for rollout completion and stabilization
5. Verifies the updated configuration

**Usage:**
```bash
cd scripts/
./enable-fair-sharing.fish
```

**Metrics enabled by this configuration:**
- `kueue_cluster_queue_weighted_share`
- `kueue_cohort_weighted_share`

---

## Test Cases

### Test Case 1: Preemption and Weighted Share Metrics

**Target Metrics:**
- `kueue_preempted_workloads_total`
- `kueue_admission_cycle_preemption_skips`
- `kueue_cluster_queue_weighted_share` (triggered by Cohort creation)
- `kueue_cohort_weighted_share` (triggered by Cohort creation)

**Manifests:**
- `manifests/1-preemption-cohort-setup.yaml` - Creates Cohort, ClusterQueues, ResourceFlavors, and PriorityClasses
- `manifests/1a-low-priority-jobs.yaml` - Low-priority workloads
- `manifests/1b-high-priority-jobs.yaml` - High-priority workloads and blocker job

**Test Scenario:**
1. Create Cohort resource and two ClusterQueues referencing the cohort
2. Submit low-priority jobs to exhaust quota
3. Submit blocker job to consume remaining capacity
4. Submit high-priority jobs to trigger preemption
5. Observe low-priority workloads transition to Evicted state with reason "Preempted"

**Configuration Requirements:**
- For weighted share metrics: `fairSharing.enable: true` and `metrics.enableClusterQueueResources: true`
- For preemption: ClusterQueues must have preemption policies configured

**Code References:**
- Preemption logic: `pkg/scheduler/preemption/preemption.go:250`
- Scheduling: `pkg/scheduler/scheduler.go:172`
- Weighted share (ClusterQueue): `pkg/controller/core/clusterqueue_controller.go:631`
- Weighted share (Cohort): `pkg/controller/core/cohort_controller.go:168`

---

### Test Case 2: Eviction Metrics

**Target Metrics:**
- `kueue_evicted_workloads_total`
- `kueue_local_queue_evicted_workloads_total`

**Shared Manifest:**
- `manifests/2-eviction-test-setup.yaml` - ClusterQueue and ResourceFlavor (used by both 2a and 2b)

**Note:** LocalQueues and Jobs are created dynamically by the script in separate test namespaces.

#### Test Case 2a: Eviction - Deactivation

**Test Scenario:**
1. Apply eviction test setup (ClusterQueue, ResourceFlavor)
2. Create LocalQueue in namespace `kueue-test-eviction-deact`
3. Create Job inline (not from manifest)
4. Unsuspend and wait for workload admission
5. Patch workload `spec.active: false` to trigger deactivation
6. Wait for workload eviction with reason "Deactivated"

#### Test Case 2b: Eviction - ClusterQueue Stopped

**Test Scenario:**
1. Uses same ClusterQueue from manifest 2 (already applied in Test Case 2a)
2. Create LocalQueue in namespace `kueue-test-eviction-cq-stop`
3. Create Job inline (not from manifest)
4. Unsuspend and wait for workload admission
5. Patch ClusterQueue `spec.stopPolicy: HoldAndDrain`
6. Wait for workload eviction with reason "ClusterQueueStopped"

**Code References:**
- Eviction logic: `pkg/workload/workload.go:897`
- Metrics recording: `pkg/metrics/metrics.go:442`

---

### Test Case 3: Admission Checks Wait Time Metrics

**Target Metrics:**
- `kueue_admission_checks_wait_time_seconds`
- `kueue_local_queue_admission_checks_wait_time_seconds`

**Manifests:**
- `manifests/3-admission-checks-setup.yaml` - ClusterQueue, AdmissionCheck, ProvisioningRequestConfig, ResourceFlavor
- `manifests/3a-admission-checks-test-job.yaml` - Test job with admission check (applied with namespace substitution)

**Note:** LocalQueue is created dynamically by the script in the test namespace.

**Test Scenario:**
1. Create AdmissionCheck resource
2. Manually activate AdmissionCheck (in v0.11.6 without provisioning controller)
3. Submit workload referencing the AdmissionCheck
4. Workload obtains quota reservation
5. Wait period for admission check
6. Approve admission check (manual patch to workload status)
7. Workload transitions to Admitted state
8. Metrics record the wait time from quota reservation to admission

**Code References:**
- Workload controller: `pkg/controller/core/workload_controller.go:268`
- Scheduler: `pkg/scheduler/scheduler.go:542`

**Note:** In production environments with a ProvisioningRequest controller, the admission check approval is automatic. The test framework manually patches the workload status to simulate controller approval.

---

## Automated Test Execution

### Main Test Script

**Location:** `scripts/run-metrics-tests-no-cleanup.fish`

**Features:**
- Runs all test cases in isolated namespaces
- Preserves resources after completion for metrics collection
- Validates configuration prerequisites before execution
- Provides detailed progress output

**Usage:**
```bash
cd scripts/
./run-metrics-tests-no-cleanup.fish
```

**Test Namespaces:**
- `kueue-test-preemption` - Preemption test resources
- `kueue-test-eviction-deact` - Deactivation eviction test
- `kueue-test-eviction-cq-stop` - ClusterQueue stop eviction test
- `kueue-test-admission-checks` - Admission checks test

**Execution Flow:**
1. Verify cluster access and Kueue deployment
2. Create test namespaces (4 isolated namespaces for parallel metrics collection)
3. Execute Test Case 0: Configuration Prerequisites Check
   - Validates `fairSharing.enable: true`
   - Validates `metrics.enableClusterQueueResources: true`
   - Validates `featureGates.LocalQueueMetrics: true`
   - Validates `waitForPodsReady.enable: true`
   - Exits if any required configuration is missing
4. Execute Test Case 1: Preemption and Weighted Share Metrics
5. Execute Test Case 2a: Eviction - Deactivation
6. Execute Test Case 2b: Eviction - ClusterQueue Stopped
7. Execute Test Case 3: Admission Checks
8. Display summary with expected metrics and verification instructions

**Expected Metrics After Test Completion:**
1. `kueue_preempted_workloads_total` - From Test Case 1
2. `kueue_admission_cycle_preemption_skips` - From Test Case 1
3. `kueue_evicted_workloads_total` - From Test Cases 2a and 2b
4. `kueue_local_queue_evicted_workloads_total` - From Test Cases 2a and 2b
5. `kueue_admission_checks_wait_time_seconds` - From Test Case 3
6. `kueue_local_queue_admission_checks_wait_time_seconds` - From Test Case 3
7. `kueue_cluster_queue_weighted_share` - From Test Case 1 (if fair sharing enabled)
8. `kueue_cohort_weighted_share` - From Test Case 1 (if fair sharing enabled)

---

### Cleanup Script

**Location:** `scripts/cleanup-metrics-tests.fish`

**What it removes:**
- All test namespaces
- Cohorts
- ClusterQueues
- ResourceFlavors
- AdmissionChecks
- ProvisioningRequestConfigs
- PriorityClasses

**Usage:**
```bash
cd scripts/
./cleanup-metrics-tests.fish
```

**Verification:** The script verifies cleanup completion and reports any remaining resources.

---

## Metrics Verification

### Port-Forward to Metrics Endpoint

```bash
kubectl port-forward -n opendatahub deployment/kueue-controller-manager 8443:8443
```

### Create Service Account Token

```bash
TOKEN=$(kubectl create token kueue-controller-manager-metrics-reader -n opendatahub --duration=10m)
```

### Query Metrics

**All Kueue metrics:**
```bash
curl -sk https://localhost:8443/metrics -H "Authorization: Bearer $TOKEN" | grep "# TYPE kueue"
```

**Specific metrics:**
```bash
# Preemption
curl -sk https://localhost:8443/metrics -H "Authorization: Bearer $TOKEN" | grep "kueue_preempted_workloads_total"

# Eviction
curl -sk https://localhost:8443/metrics -H "Authorization: Bearer $TOKEN" | grep "kueue_evicted_workloads_total"

# Admission checks
curl -sk https://localhost:8443/metrics -H "Authorization: Bearer $TOKEN" | grep "kueue_admission_checks_wait_time"

# Weighted share
curl -sk https://localhost:8443/metrics -H "Authorization: Bearer $TOKEN" | grep "weighted_share"
```

---

## Metrics Not Present in v0.11.6

The following metrics are documented in upstream but not implemented in the deployed version:

1. `kueue_build_info` - Build version information
2. `kueue_ready_wait_time_seconds` - Wait time until pods ready
3. `kueue_admitted_until_ready_wait_time_seconds` - Admission to pods ready duration
4. `kueue_local_queue_ready_wait_time_seconds` - LocalQueue ready wait time
5. `kueue_local_queue_admitted_until_ready_wait_time_seconds` - LocalQueue admission to ready duration
6. `kueue_pods_ready_to_evicted_time_seconds` - Pods ready to eviction duration
7. `kueue_evicted_workloads_once_total` - Unique workload evictions counter
8. `kueue_replaced_workload_slices_total` - Workload slice replacements

**Note:** These metrics require upgrading to a newer Kueue version (v0.15+).

---

## Troubleshooting

### Metrics Not Appearing

**Check workload status:**
```bash
kubectl get workloads -n <test-namespace> -o yaml
```

**Review controller logs:**
```bash
kubectl logs -n opendatahub deployment/kueue-controller-manager -f
```

**Verify configuration:**
```bash
kubectl get configmap kueue-manager-config -n opendatahub -o yaml
```

### Fair Sharing Metrics Missing

**Verify fair sharing is enabled:**
```bash
kubectl get configmap kueue-manager-config -n opendatahub \
  -o jsonpath='{.data.controller_manager_config\.yaml}' | grep -A 3 fairSharing
```

Expected output should show uncommented `fairSharing:` section with `enable: true`.

**Check resource metrics enablement:**
```bash
kubectl get configmap kueue-manager-config -n opendatahub \
  -o jsonpath='{.data.controller_manager_config\.yaml}' | grep enableClusterQueueResources
```

### Admission Checks Not Working

**Verify AdmissionCheck is active:**
```bash
kubectl get admissioncheck sample-admission-check -o yaml
```

Look for `status.conditions` with `type: Active` and `status: "True"`.

**Check workload admission check status:**
```bash
kubectl get workload <workload-name> -n <namespace> -o yaml
```

Review `status.admissionChecks` array for check states.

---

## Code References

- Metrics definitions: `pkg/metrics/metrics.go`
- Eviction logic: `pkg/workload/workload.go:896-900`
- Preemption logic: `pkg/scheduler/preemption/preemption.go:248-252`
- Admission checks: `pkg/controller/core/workload_controller.go:266-272`
- E2E tests: `test/e2e/singlecluster/metrics_test.go`
- Fair sharing: `pkg/controller/core/clusterqueue_controller.go:629-631`
- Cohort controller: `pkg/controller/core/cohort_controller.go:168`

---

## Additional Resources

### Metrics Extraction and Comparison Workflow

For extracting metrics from the cluster and comparing them against upstream metrics, refer to:

**[GetAndCompareActualMetrics.md](./GetAndCompareActualMetrics.md)**

This document provides the command sequence for:
- Port-forwarding to the Kueue metrics endpoint
- Creating service account tokens for metrics access
- Extracting metrics to text and CSV formats
- Comparing received metrics against upstream baseline metrics

The workflow is useful for validating which metrics are active in the deployed instance and identifying discrepancies with upstream metrics definitions.
