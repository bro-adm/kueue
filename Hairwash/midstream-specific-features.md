# Downstream-Specific Features and Enhancements

This document details features and components that are **present in downstream but NOT in upstream**.

## Summary

Downstream is a **Red Hat OpenShift AI (RHOAI) / OpenDataHub (ODH) distribution** of Kueue with production-ready enterprise features:
- OpenShift/RHOAI-specific deployment configurations
- Production monitoring and alerting
- Enterprise build and release workflows
- Different feature gate defaults for stability

---

## 1. Red Hat OpenShift AI (RHOAI) / OpenDataHub (ODH) Integration

### RHOAI Configuration Directory

**Location:** `downstream-view/config/rhoai/`

**Not present in upstream**

This entire directory contains OpenShift-specific deployment configurations:

#### Key Files:

1. **kustomization.yaml** - RHOAI-specific Kustomize configuration
   ```yaml
   namespace: opendatahub
   namePrefix: kueue-
   ```
   - Deploys to `opendatahub` namespace (vs generic namespaces in upstream)
   - Adds `kueue-` prefix to all resources

2. **prometheus_rule.yaml** - Production alerting rules
   - **KueuePodDown** alert - Critical alert when Kueue pods are down
   - **LowClusterQueueResourceUsage** alert - Info alert for underutilized resources
   - **ResourceReservationExceedsQuota** alert - Warns when reservations far exceed quotas
   - **PendingWorkloadPods** alert - Tracks pods pending for >3 days
   - Links to OpenDataHub runbooks: `https://github.com/opendatahub-io/runbooks/`

3. **monitor.yaml** - ServiceMonitor for Prometheus
   - CoreOS Prometheus Operator integration
   - Secure metrics collection with Bearer token authentication
   - TLS configuration

4. **manager_config_patch.yaml** - Different feature gate defaults
   ```yaml
   feature-gates=VisibilityOnDemand=false,LocalQueueMetrics=true,MultiKueue=false
   ```
   - **LocalQueueMetrics=true** (enabled by default in RHOAI)
   - **VisibilityOnDemand=false** (disabled for stability)
   - **MultiKueue=false** (disabled in RHOAI distribution)

5. **Webhook patches** - OpenShift-specific webhook configurations
   - `mutating_webhook_patch.yaml`
   - `validating_webhook_patch.yaml`

6. **Metrics infrastructure:**
   - `kueue_metrics_reader_serviceaccount.yaml`
   - `kueue_metrics_reader_secret.yaml`
   - `kueue-metrics-service.yaml`
   - `metrics_reader_clusterrole_binding.yaml`

7. **webhook_network_policy.yaml** - NetworkPolicy for webhook security

8. **manager_role_patch.yaml** - Additional RBAC permissions for OpenShift

**Purpose:** Production-ready deployment configuration for Red Hat OpenShift AI and OpenDataHub platforms.

---

## 2. Red Hat Container Build Support

### Dockerfile.rhoai

**Location:** `downstream-view/Dockerfile.rhoai`

**Not present in upstream**

**Red Hat Enterprise Linux (RHEL) UBI-based container:**

```dockerfile
FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.23
FROM registry.access.redhat.com/ubi9/ubi:latest
```

**Key differences from upstream Dockerfile:**
- Uses **Red Hat Universal Base Image (UBI) 9** instead of generic base images
- Uses **Red Hat's internal registry** for Go builder
- CGO-enabled builds for RHEL compatibility
- Optimized for OpenShift Container Platform
- Production-grade security hardening

**Purpose:** Official Red Hat-supported container images for enterprise deployments.

---

## 3. OpenDataHub CI/CD Workflows

### ODH-specific GitHub Actions

**Location:** `downstream-view/.github/workflows/`

#### Workflows ONLY in Downstream:

1. **odh-build-and-publish-kueue-image.yaml**
   - Builds and publishes to **Quay.io/opendatahub** registry
   - Uses `Dockerfile.rhoai` for building
   - Manual workflow dispatch with version tagging
   - Credentials: `QUAY_USERNAME`, `QUAY_PASSWORD` secrets

   ```yaml
   IMAGE_REGISTRY: quay.io/opendatahub
   ```

2. **odh-release.yml**
   - Creates OpenDataHub-specific releases
   - Tag format: `v0.0.1-odh-1` (ODH suffix)
   - Compiles e2e tests for release
   - Creates GitHub releases with compiled test binaries

**Not present in upstream** - Upstream uses different release workflows.

---

## 4. Feature Gate Differences

### Default Feature Configuration

**Downstream** (RHOAI production):
```yaml
feature-gates=VisibilityOnDemand=false,LocalQueueMetrics=true,MultiKueue=false
```

**Upstream** (likely more experimental):
- Different defaults optimized for community/development use
- More features enabled by default for testing

**Downstream rationale:**
- **LocalQueueMetrics=true**: Enable detailed local queue metrics for multi-tenant monitoring
- **VisibilityOnDemand=false**: Disable experimental visibility features for stability
- **MultiKueue=false**: Disable multi-cluster features (not production-ready for RHOAI)

---

## 5. Production Monitoring & Observability

### Prometheus Integration

**Downstream-specific monitoring stack:**

1. **PrometheusRule** with production alerts
   - Integration with OpenShift monitoring stack
   - Deployed to `openshift-monitoring` namespace
   - Links to enterprise runbooks

2. **ServiceMonitor** with secure metrics
   - Bearer token authentication
   - TLS with certificate verification
   - Service account-based access control

3. **Metrics Service**
   - Dedicated service for metrics scraping
   - HTTPS endpoint
   - RBAC-protected access

**Upstream**: Has basic metrics but lacks the production-grade alerting and monitoring configuration.

---

## 6. Enterprise Security & Compliance

### Enhanced Security Features (Downstream)

1. **NetworkPolicy** for webhooks
   - Restricts network access to webhook endpoints
   - OpenShift-specific network isolation

2. **Service Account Tokens**
   - Long-lived tokens for metrics readers
   - Kubernetes 1.24+ token management

3. **RBAC Enhancements**
   - Additional ClusterRole patches
   - Viewer roles for ClusterQueues
   - Metrics reader permissions

4. **UBI-based containers**
   - Red Hat's hardened base images
   - Regular security updates
   - FIPS compliance ready

---

## 7. Namespace and Naming Conventions

### Downstream Defaults:

```yaml
namespace: opendatahub
namePrefix: kueue-
```

- All resources deployed to **opendatahub** namespace (OpenDataHub's namespace)
- Resources prefixed with `kueue-` for multi-component environments
- Consistent with RHOAI platform standards

### Upstream:
- Generic namespace configurations
- No enforced naming prefix
- More flexible for diverse deployment scenarios

---

## 8. Documentation and Runbooks

### Downstream References:

All alerts link to **OpenDataHub runbooks**:
```yaml
runbook_url: "https://github.com/opendatahub-io/runbooks/blob/main/alerts/kueue/..."
```

Examples:
- `kueue-pod-down.md`
- `low-cluster-queue-resource-usage.md`
- `resource-reservation-exceeds-quota.md`
- `pending-workload-pods.md`

**Purpose:** Enterprise support with documented troubleshooting procedures.

**Upstream:** No production runbooks, relies on community documentation.

---

## 9. Build and Release Process

### Downstream:
- **Separate release tags**: `v0.0.1-odh-1` format
- **Quay.io registry**: `quay.io/opendatahub/kueue`
- **E2E test compilation**: Distributes compiled test binaries with releases
- **Manual release approval**: Workflow dispatch for control

### Upstream:
- Standard semantic versioning
- Different registry (likely ghcr.io or similar)
- Automated releases on tag push

---

## 10. CodeFlare AppWrapper Support

### Status: **BOTH have CodeFlare support**

Both upstream and downstream include:
- `github.com/project-codeflare/appwrapper` dependency
- AppWrapper controller implementation
- AppWrapper webhook support
- Examples for PyTorchJob, LeaderWorkerSet wrapped in AppWrappers

**Difference:**
- **Downstream**: AppWrapper examples in `examples/jobs/`
- **Upstream**: AppWrapper examples in dedicated `examples/appwrapper/` directory (better organization)

**CodeFlare is NOT downstream-only** - it's in both versions, but organized differently.

---

## Summary: Downstream vs Upstream Philosophy

### Downstream (RHOAI/ODH):
✅ **Production-ready** enterprise distribution
✅ **Red Hat-supported** with RHEL/UBI containers
✅ **Integrated monitoring** with Prometheus/Grafana
✅ **Production alerting** with runbooks
✅ **Stable defaults** (conservative feature gates)
✅ **OpenShift-optimized** deployment
✅ **Security-hardened** with NetworkPolicies, RBAC
✅ **Enterprise CI/CD** with controlled releases

### Upstream:
✅ **Latest features** (DRA, workload slicing, fair sharing)
✅ **Innovation-focused** with experimental capabilities
✅ **Community-driven** development
✅ **Flexible deployment** for various platforms
✅ **Broader feature set** enabled by default
✅ **Faster release cycle**

---

## Key Takeaway

**Downstream is NOT a superset** - it's a **production-hardened, enterprise-ready subset** with:
- **Red Hat/OpenShift integration**
- **Production monitoring and alerting**
- **Stable feature gates** (fewer experimental features enabled)
- **Enterprise security** and compliance
- **Supported container images** (RHEL UBI-based)

**Upstream has more features**, but **downstream has better production readiness** for OpenShift/RHOAI environments.

---

## Recommendation

- **For production RHOAI/OpenShift deployments**: Use downstream
- **For latest features and community innovation**: Use upstream
- **For adopting new features**: Monitor upstream, request backports to downstream when stable
