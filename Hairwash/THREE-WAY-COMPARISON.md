# Kueue Three-Way Comparison: Upstream → Midstream → Downstream

This document provides a comprehensive comparison of the three Kueue repositories in your development environment.

## Repository Overview

| Level | Repository | Branch/Commit | Purpose |
|-------|-----------|---------------|---------|
| **Upstream** | `kubernetes-sigs/kueue` | `main` / latest | Community development, latest features |
| **Midstream** | `opendatahub-io/kueue` | `stable-2.x` | OpenDataHub distribution, production-ready subset |
| **Downstream** | `red-hat-data-services/kueue` | RHOAI branches | Red Hat official product builds with Konflux |

---

## The Flow: Upstream → Midstream → Downstream

```
┌─────────────────────────────────────┐
│  Upstream (kubernetes-sigs/kueue)  │
│  - Latest community features        │
│  - Rapid development                │
│  - Experimental capabilities        │
└──────────────┬──────────────────────┘
               │ Fork & Stabilize
               ↓
┌─────────────────────────────────────┐
│  Midstream (opendatahub-io/kueue)  │
│  - OpenDataHub distribution         │
│  - Production-ready subset          │
│  - RHOAI integration layer          │
│  - Stable feature gates             │
└──────────────┬──────────────────────┘
               │ Enterprise Hardening
               ↓
┌─────────────────────────────────────┐
│ Downstream (red-hat-data-services)  │
│  - Official Red Hat product         │
│  - Konflux build system             │
│  - FIPS compliance                  │
│  - Enterprise security              │
└─────────────────────────────────────┘
```

---

## Key Differences Summary

### Upstream (Most Features)
✅ DRA (Dynamic Resource Allocation)
✅ Workload Slicing
✅ Failure Recovery Controller
✅ Workload Dispatcher
✅ Fair Sharing Admission
✅ JAXJob integration
✅ Elastic/Scalable jobs
✅ Enhanced Visibility API with Grafana dashboards
✅ Replica role metrics
✅ Modular cache architecture
✅ TrainJob support

### Midstream (Production-Ready Subset)
✅ RHOAI configuration (`config/rhoai/`)
✅ Production Prometheus alerting
✅ ServiceMonitor for metrics
✅ NetworkPolicy for security
✅ Red Hat UBI containers (`Dockerfile.rhoai`)
✅ ODH CI/CD workflows
✅ LocalQueueMetrics enabled by default
✅ Stable feature gates (VisibilityOnDemand=false, MultiKueue=false)

❌ No DRA, Workload Slicing, Failure Recovery
❌ No Fair Sharing Admission
❌ No JAXJob, TrainJob
❌ No Elastic jobs
❌ Limited Visibility (no Grafana dashboards)
❌ No Replica role metrics
❌ Flat cache architecture (not modular)

### Downstream (Enterprise Hardening)
✅ Everything from Midstream, PLUS:
✅ **Konflux build system** (`Dockerfile.konflux`)
✅ **FIPS compliance** (`GOEXPERIMENT=strictfipsruntime`)
✅ **Red Hat internal registry** (brew.registry.redhat.io)
✅ **Enhanced security labels** for compliance
✅ **Red Hat Standard EULA** licensing
✅ **UBI minimal image** (smaller attack surface)
✅ **Digest pinning** for reproducible builds
✅ **Red Hat component labels** for container metadata

---

## Dockerfile Comparison

### Upstream: `Dockerfile`
- Generic multi-stage build
- Public base images
- Community-focused

### Midstream: `Dockerfile.rhoai`
```dockerfile
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23
FROM registry.access.redhat.com/ubi9/ubi:latest
```
- Red Hat UBI 9 base
- Engineering registry access
- CGO enabled
- No FIPS enforcement

### Downstream: `Dockerfile.konflux`
```dockerfile
FROM brew.registry.redhat.io/rh-osbs/openshift-golang-builder:v1.24@sha256:...
FROM registry.access.redhat.com/ubi9/ubi-minimal@sha256:...
```
**Key differences:**
1. **Brew registry** (Red Hat's internal build registry)
2. **Digest pinning** (`@sha256:...`) for reproducibility
3. **FIPS compliance**: `GOEXPERIMENT=strictfipsruntime`
4. **UBI minimal** (smaller, more secure base image)
5. **Red Hat labels**:
   ```dockerfile
   com.redhat.component="odh-kueue-controller-container"
   name="managed-open-data-hub/odh-kueue-controller-rhel8"
   com.redhat.license_terms="https://www.redhat.com/licenses/..."
   ```

---

## Feature Gates Comparison

### Upstream (Assumed defaults):
- Most features enabled for development/testing
- Experimental features available

### Midstream (`config/rhoai/manager_config_patch.yaml`):
```yaml
feature-gates=VisibilityOnDemand=false,LocalQueueMetrics=true,MultiKueue=false
```
- **LocalQueueMetrics=true** - Detailed local queue metrics enabled
- **VisibilityOnDemand=false** - Experimental visibility disabled
- **MultiKueue=false** - Multi-cluster disabled

### Downstream:
- Same as midstream (inherits RHOAI configuration)
- Focus on stability over features

---

## Build & Release Workflows

### Upstream:
- GitHub Actions for community releases
- Standard semantic versioning (v0.15.0)
- Public container registries

### Midstream:
- **ODH-specific workflows**:
  - `odh-build-and-publish-kueue-image.yaml`
  - `odh-release.yml`
- **Quay.io registry**: `quay.io/opendatahub/kueue`
- **ODH versioning**: `v0.6.2-odh`, `v0.6.0-rhoai-2.9`

### Downstream:
- **Konflux build system** (Red Hat's enterprise CI/CD)
- **Multiple RHOAI version branches**:
  - `rhoai-2.7` through `rhoai-3.2`
  - `konflux-sa-migration-odh-kueue-controller-v2-*`
- **Renovate automation** for dependency updates
- **Brew registry** for official Red Hat builds

---

## RHOAI Configuration Comparison

### Midstream has `config/rhoai/`:
- Basic RHOAI deployment configuration
- Prometheus rules
- ServiceMonitor
- NetworkPolicy
- Metrics service accounts

### Downstream has `config/rhoai/`:
- **Same structure** as midstream
- Inherits all RHOAI configurations
- Both deploy to `opendatahub` namespace
- Both use `kueue-` prefix

**Conclusion**: RHOAI config is identical between midstream and downstream.

---

## Metrics Differences

### Upstream:
- Replica role labels on all metrics
- Build info metric
- Enhanced observability

### Midstream:
- **No replica role labels**
- **No build info metric**
- Production alerting:
  - KueuePodDown (critical)
  - LowClusterQueueResourceUsage (info)
  - ResourceReservationExceedsQuota (info)
  - PendingWorkloadPods (info)

### Downstream:
- **Same as midstream** (inherits metrics configuration)

---

## Security & Compliance

### Upstream:
- Community security practices
- Standard Kubernetes RBAC

### Midstream:
- NetworkPolicy for webhook isolation
- Service account tokens for metrics
- UBI containers (Red Hat hardened base)
- Enhanced RBAC

### Downstream (Highest Security):
- **FIPS 140-2 compliance** via `strictfipsruntime`
- **Digest-pinned images** (reproducible builds)
- **UBI minimal** (reduced attack surface)
- **Red Hat security scanning** and CVE tracking
- **Enterprise licensing** and legal compliance
- **Internal registry** (brew.registry.redhat.io)

---

## Cache Architecture

### Upstream (Modular):
```
pkg/cache/
├── hierarchy/     # Cluster queue & cohort hierarchy
├── queue/         # Queue operations, inadmissible workloads
│   └── afs/       # Adaptive Fair Sharing
└── scheduler/     # Core scheduling logic
```

### Midstream (Flat):
```
pkg/cache/
├── cache.go
├── clusterqueue.go
├── cohort.go
├── fair_sharing.go
├── tas_cache.go
└── ...
```
Plus separate top-level:
- `pkg/hierarchy/`
- `pkg/queue/`

### Downstream:
- **Same as midstream** (inherits flat structure)

---

## Branch Strategy

### Upstream:
- `main` - active development
- `release-0.x` - stable releases (0.1 → 0.15)

### Midstream:
- `stable-2.x` - main stable branch
- `dev` - development branch
- Version tags: `kueue-0.7.0`, `kueue-0.10.0`

### Downstream (Most Complex):
- `main` - latest development
- **RHOAI version branches**: `rhoai-2.7` → `rhoai-3.2`
- **Konflux branches**: Build system integration
- **Backup branches**: Multiple dated backups
- **Renovate branches**: Automated dependency updates

---

## Examples & Documentation

### Upstream (Most Examples):
- `examples/admission-fs/` - Fair sharing admission
- `examples/appwrapper/` - Dedicated AppWrapper directory
- `examples/visibility/` - Grafana dashboards
- `examples/jobs/sample-jaxjob.yaml` - JAXJob
- `examples/jobs/sample-scalable-job.yaml` - Elastic jobs
- `examples/multikueue/tas/` - TAS multi-cluster

### Midstream (Basic Examples):
- `examples/jobs/` - Basic job examples
- AppWrapper examples inline (not dedicated directory)
- `examples/visibility/` - Only basic RBAC (no Grafana)
- No JAXJob, TrainJob, or elastic job examples

### Downstream:
- **Same as midstream** (examples inherited)

---

## Component Differences

### Only in Upstream:
- `pkg/dra/` - Dynamic Resource Allocation
- `pkg/workloadslicing/` - Workload slicing
- `pkg/controller/failurerecovery/` - Failure recovery
- `pkg/controller/workloaddispatcher/` - Workload dispatcher
- `pkg/controller/jobs/trainjob/` - TrainJob integration
- `pkg/cache/queue/afs/` - Adaptive Fair Sharing
- `pkg/cache/scheduler/` - Modular scheduler
- `cmd/experimental/kueue-populator/` - Populator tool

### Only in Midstream:
- `config/rhoai/` - RHOAI deployment configs
- `Dockerfile.rhoai` - Red Hat UBI container
- `.github/workflows/odh-*.yml` - ODH CI/CD
- Production Prometheus rules

### Only in Downstream:
- `Dockerfile.konflux` - Konflux/FIPS build
- Extensive version branches (rhoai-2.x)
- Konflux automation branches
- Red Hat internal registry references

---

## Development Philosophy

### Upstream:
🎯 **Innovation-focused**
- Rapid feature development
- Experimental capabilities
- Community-driven
- Broader feature set

### Midstream:
🎯 **Production-ready stabilization**
- Subset of upstream features
- OpenShift/RHOAI integration
- Production monitoring & alerting
- Conservative feature gates
- OpenDataHub community

### Downstream:
🎯 **Enterprise hardening**
- FIPS compliance
- Security scanning & CVE tracking
- Reproducible builds (digest pinning)
- Red Hat support contracts
- Enterprise licensing
- Konflux automation

---

## Use Case Recommendations

### Choose Upstream if you want:
✅ Latest features (DRA, workload slicing, fair sharing)
✅ Experimental capabilities
✅ Community development
✅ Contribution to Kubernetes SIG

### Choose Midstream if you want:
✅ OpenDataHub integration
✅ Production-ready Kueue
✅ RHOAI compatibility
✅ Stable subset of features
✅ Production monitoring

### Choose Downstream if you want:
✅ Official Red Hat support
✅ FIPS compliance
✅ Enterprise security requirements
✅ Red Hat Standard EULA
✅ Konflux build integration
✅ CVE tracking & patches

---

## Migration Path

```
Community Development (Upstream)
         ↓
    Stabilization
         ↓
OpenDataHub Integration (Midstream)
         ↓
  Enterprise Hardening
         ↓
Red Hat Product (Downstream)
         ↓
    Customer Deployment
```

---

## Summary

| Aspect | Upstream | Midstream | Downstream |
|--------|----------|-----------|------------|
| **Features** | Most (cutting edge) | Subset (stable) | Subset (stable) |
| **Security** | Community standards | RHOAI hardening | FIPS + Enterprise |
| **Build System** | GitHub Actions | ODH workflows | Konflux |
| **Container Base** | Generic | UBI 9 | UBI 9 Minimal |
| **Registry** | Public | Quay.io/opendatahub | brew.registry.redhat.io |
| **Compliance** | None | OpenShift ready | FIPS + Red Hat EULA |
| **Support** | Community | OpenDataHub community | Red Hat Enterprise |
| **Versioning** | Semantic (v0.15.0) | ODH tags | RHOAI branches |

---

## Your Development Environment

Your worktrees at `/Users/lbondy/Work/projects/kueue/`:
- `upstream-view/` - Track latest community features
- `midstream-view/` - OpenDataHub stable version
- `downstream-view/` - Red Hat enterprise version

This setup allows you to:
1. Compare feature differences
2. Track stabilization process
3. Understand enterprise hardening
4. Backport features from upstream → midstream
5. Monitor security/compliance changes downstream
