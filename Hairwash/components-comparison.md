# Kueue Components Comparison: Downstream vs Upstream

This document details the differences between the downstream and upstream Kueue codebases.

## Summary

The **upstream version** contains several **new features and architectural improvements** that are **NOT present in downstream**:
- Dynamic Resource Allocation (DRA)
- Workload Slicing
- Failure Recovery Controller
- Workload Dispatcher
- Restructured cache architecture
- Additional job integration (TrainJob)

The **downstream version** is largely a **subset** of upstream with some implementation differences.

---

## Components Present in Upstream but NOT in Downstream (Reductions in Downstream)

### 1. New Features & Packages

#### Dynamic Resource Allocation (DRA)
- **Location:** `upstream-view/pkg/dra/`
- **Files:**
  - `claims.go` / `claims_test.go`
  - `mapper.go` / `mapper_test.go`
- **Description:** Support for Kubernetes Dynamic Resource Allocation, allowing flexible resource claims

#### Workload Slicing
- **Location:** `upstream-view/pkg/workloadslicing/`
- **Files:**
  - `workloadslicing.go` / `workloadslicing_test.go`
- **Description:** Feature to slice workloads into smaller units for better resource utilization

### 2. New Controllers

#### Failure Recovery Controller
- **Location:** `upstream-view/pkg/controller/failurerecovery/`
- **Files:**
  - `failurerecovery.go`
  - `pod_termination_controller.go` / `pod_termination_controller_test.go`
- **Description:** Handles pod termination scenarios and failure recovery logic

#### Workload Dispatcher
- **Location:** `upstream-view/pkg/controller/workloaddispatcher/`
- **Files:**
  - `controllers.go`
  - `incrementaldispatcher.go` / `incrementaldispatcher_test.go`
- **Description:** Implements incremental workload dispatching mechanism for better scheduling

### 3. Cache Architecture Refactoring

Upstream has completely restructured the cache package:

#### Upstream Cache Structure
```
upstream-view/pkg/cache/
├── hierarchy/
│   ├── clusterqueue.go
│   ├── cohort.go
│   ├── cycle.go
│   ├── manager.go
│   └── manager_test.go
├── queue/
│   ├── afs/
│   ├── cluster_queue.go / cluster_queue_test.go
│   ├── cohort.go
│   ├── dumper.go
│   ├── inadmissible_workloads.go / inadmissible_workloads_test.go
│   ├── local_queue.go
│   ├── manager.go / manager_test.go
│   ├── second_pass_queue.go
│   └── status_checker.go
└── scheduler/
    ├── admissioncheck.go
    ├── cache.go / cache_test.go
    ├── clusterqueue.go / clusterqueue_test.go / clusterqueue_snapshot.go
    ├── cohort.go / cohort_snapshot.go
    └── (TAS-related files)
```

#### Downstream Cache Structure (Flat)
```
downstream-view/pkg/cache/
├── admissioncheck.go
├── cache.go / cache_test.go
├── clusterqueue.go / clusterqueue_test.go / clusterqueue_snapshot.go
├── cohort.go / cohort_snapshot.go
├── fair_sharing.go / fair_sharing_test.go
├── resource.go / resource_test.go
├── resource_node.go / resource_node_test.go
├── snapshot.go / snapshot_test.go
├── tas_cache.go / tas_cache_test.go
└── tas_flavor.go / tas_flavor_snapshot.go / tas_flavor_snapshot_test.go
```

**Impact:** Upstream has a more modular, organized architecture with separation of concerns:
- `hierarchy/` - Manages cluster queue and cohort hierarchy
- `queue/` - Manages queue operations and inadmissible workloads
- `scheduler/` - Core scheduling logic and snapshots

Downstream uses the older flat structure.

Additionally, downstream has separate top-level packages:
- `downstream-view/pkg/hierarchy/` (equivalent to upstream's `pkg/cache/hierarchy/`)
- `downstream-view/pkg/queue/` (partial equivalent to upstream's `pkg/cache/queue/`)

### 4. Job Integrations

#### TrainJob (Upstream Only)
- **Location:** `upstream-view/pkg/controller/jobs/trainjob/`
- **Description:** Integration with Kubeflow TrainJob for ML training workloads
- **Note:** This is a new job framework not available in downstream

### 5. MultiKueue Enhancements

#### External Frameworks Support (Upstream Only)
- **Location:** `upstream-view/pkg/controller/admissionchecks/multikueue/externalframeworks/`
- **Files:**
  - `adapter.go`
  - `config.go`
- **Description:** Generic adapter framework for external multi-cluster integrations, more extensible than downstream's approach

### 6. CLI Enhancements (kueuectl)

#### Additional Utilities (Upstream Only)
- **Location:** `upstream-view/cmd/kueuectl/app/`
- **New Packages:**
  - `clientgetter/` - Improved client management
  - `dryrun/` - Dry-run capabilities
  - `flags/` - Centralized flag management
- **Description:** Better code organization and additional features for the CLI

### 7. Experimental Tools

#### kueue-populator (Upstream Only)
- **Location:** `upstream-view/cmd/experimental/kueue-populator/`
- **Description:** Tool for populating Kueue resources for testing/development

#### kueueviz (Upstream Only, Downstream has kueue-viz)
- **Location:** `upstream-view/cmd/kueueviz/`
- **Description:** Enhanced visualization tool (vs downstream's simpler `kueue-viz`)
- **Note:** Appears to have more comprehensive frontend utilities

### 8. Job Framework Utilities

#### Additional Helpers (Upstream Only)
- **Files:**
  - `upstream-view/pkg/controller/jobframework/utils.go`
  - `upstream-view/pkg/controller/jobframework/tas_test.go`
  - `upstream-view/pkg/controller/core/helpers.go`
- **Description:** Additional utility functions and test coverage

---

## Components Present in Downstream but NOT in Upstream (Enhancements in Downstream)

### Minimal Downstream-Only Components

#### Job Framework Webhook Helpers (Downstream Only)
- **Location:** `downstream-view/pkg/controller/jobframework/webhook/`
- **Files:**
  - `defaulter.go` / `defaulter_test.go`
- **Description:** Additional webhook defaulting logic (may be integrated differently in upstream)

#### kueuectl Utilities (Downstream Only)
- **Location:** `downstream-view/cmd/kueuectl/app/util/`
- **Description:** Some utility functions organized differently than upstream

#### kueue-viz (Downstream Variant)
- **Location:** `downstream-view/cmd/experimental/kueue-viz/`
- **Description:** Simpler visualization tool (vs upstream's `kueueviz`)

#### MultiKueue Test Data (Downstream Only)
- **Location:** `downstream-view/pkg/controller/admissionchecks/multikueue/testdata/`
- **Description:** Additional test fixtures (upstream may have these elsewhere)

---

## Significant Implementation Differences

### 1. Metrics System

#### Replica Role Labeling
- **Upstream:** Most metrics include a `replica_role` label (leader/follower/standalone) for tracking across different deployment roles
- **Downstream:** Does NOT include `replica_role` label on metrics
- **Impact:** Upstream has better observability for multi-replica deployments

### 2. Build Information Metric

- **Upstream:** Includes `kueue_build_info` metric with git version, commit, build date, etc.
- **Downstream:** Missing this build information metric
- **Impact:** Upstream provides better version tracking through metrics

### 3. Internal Directory

- **Upstream:** Has `internal/` directory with `mocks/`
- **Downstream:** No `internal/` directory
- **Impact:** Upstream has better test infrastructure with mocking support

### 4. Queue Management

#### Inadmissible Workloads
- **Upstream:** Has dedicated `pkg/cache/queue/inadmissible_workloads.go` and `second_pass_queue.go`
- **Downstream:** These concepts may be integrated differently in the flat cache structure
- **Impact:** Upstream has more sophisticated queue management

#### AFS (Adaptive Fair Sharing)
- **Upstream:** Has `pkg/cache/queue/afs/` subdirectory
- **Downstream:** Has `pkg/cache/fair_sharing.go` at top level
- **Impact:** Different organization, similar functionality

### 5. File Count and Test Coverage

- **Upstream:** Generally has more test files and comprehensive test coverage
- **Downstream:** Less test coverage in several areas
- **Impact:** Upstream has better code quality assurance

---

## Structural Differences

### Package Organization

| Package | Downstream | Upstream | Notes |
|---------|-----------|----------|-------|
| Cache | Flat structure in `pkg/cache/` | Modular: `pkg/cache/{hierarchy,queue,scheduler}/` | Upstream more organized |
| Hierarchy | Separate `pkg/hierarchy/` | Within `pkg/cache/hierarchy/` | Different organization |
| Queue | Separate `pkg/queue/` | Within `pkg/cache/queue/` | Different organization |
| DRA | Not present | `pkg/dra/` | New feature in upstream |
| Workload Slicing | Not present | `pkg/workloadslicing/` | New feature in upstream |

---

## Dockerfile Differences

- **Downstream:** Has `Dockerfile.rhoai` (Red Hat OpenShift AI specific)
- **Upstream:** Only has standard `Dockerfile`
- **Impact:** Downstream has Red Hat-specific container build support

---

## Recommendations

### For Downstream Maintainers

1. **Consider adopting from upstream:**
   - Dynamic Resource Allocation (DRA) support
   - Workload Slicing feature
   - Failure Recovery Controller
   - Workload Dispatcher for better scheduling
   - Replica role metrics labeling
   - Build info metrics
   - Refactored cache architecture for better maintainability
   - TrainJob integration

2. **Improvements to adopt:**
   - Better test coverage
   - More modular package organization
   - Enhanced CLI features (dry-run, better client management)
   - External frameworks adapter for MultiKueue

3. **Monitor upstream for:**
   - New job integrations
   - Performance improvements in dispatcher/scheduler
   - Additional observability features

### Architecture Evolution

The upstream codebase shows a clear evolution toward:
- **Better modularity** (cache refactoring)
- **Enhanced observability** (replica_role labels, build info)
- **More features** (DRA, workload slicing, failure recovery)
- **Improved testing** (more comprehensive test coverage)
- **Better extensibility** (external frameworks adapter)

Downstream appears to be based on an earlier version and hasn't adopted these improvements yet.

---

## Version Notes

- **Downstream Branch:** `stable-2.x`
- **Upstream Branch:** Appears to be more recent development branch
- **Gap Assessment:** Downstream is approximately **several minor versions behind** upstream in features and architecture
