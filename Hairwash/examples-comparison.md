# Kueue Examples Comparison: Downstream vs Upstream

This document details the differences in example configurations between the downstream and upstream Kueue codebases.

## Summary

Yes, the same feature differences we found in the code are **reflected in the examples**. Upstream has significantly more examples demonstrating new features like:
- Fair sharing admission modes
- JAXJob integration
- Elastic/scalable jobs
- Enhanced visibility with Grafana dashboards
- MultiKueue with TAS (Topology-Aware Scheduling)
- More sophisticated resource flavor configurations

---

## Examples Present in Upstream but NOT in Downstream

### 1. Admission Fair Sharing (New Feature)

**Location:** `upstream-view/examples/admission-fs/`

**Files:**
- `admission-fair-sharing-setup.yaml`
- `lq-a-simple-job.yaml`
- `lq-b-simple-job.yaml`

**What it demonstrates:**
```yaml
admissionScope:
  admissionMode: "UsageBasedAdmissionFairSharing"
```

- **New admission mode** for fair sharing based on resource usage
- Local queues can have **fairSharing weights** to prioritize different tenants
- Enables more sophisticated multi-tenant resource allocation
- **Missing in downstream** - this is a new scheduling strategy

**Correlation to code:** This corresponds to the enhanced fair sharing logic in `upstream-view/pkg/cache/queue/afs/` (Adaptive Fair Sharing) which doesn't exist in downstream.

---

### 2. AppWrapper Examples (Reorganized)

**Upstream Location:** `upstream-view/examples/appwrapper/`
- `deployment-sample.yaml`
- `leaderworkerset-sample.yaml`
- `pytorch-sample.yaml`

**Downstream Location:** `downstream-view/examples/jobs/`
- `appwrapper-pytorch-sample.yaml`
- `appwrapper-leaderworkerset-sample.yaml`

**Key Difference:**
- Upstream has a **dedicated directory** for AppWrapper examples showing better organization
- Upstream includes a **deployment-sample.yaml** that downstream doesn't have
- The PyTorch examples are nearly identical (just different naming: `sample-appwrapper-pytorch-job` vs `sample-pytorch-job`)

**What it demonstrates:**
- Wrapping complex multi-component workloads (PyTorchJob, LeaderWorkerSet, Deployments)
- Managing distributed ML training jobs as single units

---

### 3. JAXJob Integration (New Job Type)

**Location:** `upstream-view/examples/jobs/sample-jaxjob.yaml`

**Not present in downstream**

**What it demonstrates:**
```yaml
apiVersion: kubeflow.org/v1
kind: JAXJob
metadata:
  name: jax-simple
spec:
  jaxReplicaSpecs:
    Worker:
      replicas: 2
```

- Support for **JAX-based distributed training** jobs
- Integration with Kubeflow JAXJob CRD
- **Missing in downstream** - this is a new job framework

**Correlation to code:** This corresponds to the `upstream-view/pkg/controller/jobs/kubeflow/jobs/jaxjob/` directory found earlier, which doesn't exist in downstream.

---

### 4. Elastic/Scalable Jobs (New Feature)

**Location:** `upstream-view/examples/jobs/sample-scalable-job.yaml`

**Not present in downstream**

**What it demonstrates:**
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  annotations:
    kueue.x-k8s.io/elastic-job: "true"
spec:
  parallelism: 3
  completions: 100
```

- **Elastic job** annotation for dynamic scaling
- Jobs can scale up/down based on available resources
- **Missing in downstream** - this is a new capability

**Correlation to code:** This likely relates to the workload slicing and dispatcher features in upstream (`pkg/workloadslicing/` and `pkg/controller/workloaddispatcher/`) which are missing in downstream.

---

### 5. Ray Service Support (New Job Type)

**Location:** `upstream-view/examples/jobs/ray-service-sample.yaml`

**Not present in downstream**

**What it demonstrates:**
- Support for **Ray Serve** workloads (serving ML models)
- **Missing in downstream** - downstream only has RayJob and RayCluster examples

**Note:** Both versions have `ray-cluster-sample.yaml` and `ray-job-sample.yaml`, but upstream adds Ray Service support.

---

### 6. Enhanced Resource Flavor Examples

**Upstream Only:**
- `examples/admin/resource-flavor-empty.yaml`
- `examples/admin/resource-flavor-taints.yaml`
- `examples/admin/resource-flavor-tolerations.yaml`

**What it demonstrates:**

#### resource-flavor-taints.yaml:
```yaml
apiVersion: kueue.x-k8s.io/v1beta2
kind: ResourceFlavor
metadata:
  name: "spot"
spec:
  nodeLabels:
    instance-type: spot
  nodeTaints:
  - effect: NoSchedule
    key: spot
    value: "true"
```

- **Spot instance** support with node taints
- More sophisticated node selection and workload placement
- Tolerations for specialized hardware
- **Missing in downstream** - more limited resource flavor examples

---

### 7. Visibility & Monitoring (Major Enhancement)

**Location:** `upstream-view/examples/visibility/`

**Files:**
- `README.md` - Complete setup guide
- `grafana-cluster-queue-reader.yaml` - Service account for ClusterQueue monitoring
- `grafana-local-queue-reader.yaml` - Service account for LocalQueue monitoring
- `pending-workloads-for-cluster-queue-visibility-dashboard.json` - Grafana dashboard
- `pending-workloads-for-local-queue-visibility-dashboard.json` - Grafana dashboard

**Downstream:** Only has `cluster-role-and-binding.yaml` (basic visibility setup)

**What it demonstrates:**
- **Grafana dashboard integration** for real-time workload monitoring
- Uses Kubernetes **Visibility API** (`visibility.kueue.x-k8s.io/v1beta1`)
- Monitors:
  - Pending workloads per ClusterQueue
  - Pending workloads per LocalQueue
  - Workload positions in queues
  - Priority and creation timestamps
- **Significantly enhanced** compared to downstream

**API endpoints shown:**
- `/apis/visibility.kueue.x-k8s.io/v1beta1/clusterqueues/{name}/pendingworkloads`
- `/apis/visibility.kueue.x-k8s.io/v1beta1/namespaces/{ns}/localqueues/{name}/pendingworkloads`

**Missing in downstream** - This is a major new feature for observability.

---

### 8. MultiKueue with Topology-Aware Scheduling

**Upstream Location:** `upstream-view/examples/multikueue/`
- `dev/` subdirectory:
  - `manager-kind-config.yaml`
  - `sample-tas-job.yaml`
  - `setup-kind-multikueue-tas.sh`
  - `worker-kind-config.yaml`
- `tas/` subdirectory:
  - `manager-setup.yaml`
  - `worker-setup.yaml`

**Downstream:** Only has basic multikueue setup without TAS subdirectories

**What it demonstrates:**
- **Topology-Aware Scheduling (TAS)** in multi-cluster environments
- Development setup with kind (Kubernetes in Docker)
- Manager/worker cluster configurations for multi-cluster scheduling
- **Missing in downstream** - basic multikueue only

---

### 9. TAS GPU Queue Examples

**Location:** `upstream-view/examples/tas/sample-gpu-queues.yaml`

**Not present in downstream**

**What it demonstrates:**
- GPU-specific topology-aware scheduling configurations
- More sophisticated TAS examples
- **Missing in downstream**

---

### 10. Serving Workloads with TAS

**Upstream Location:** `upstream-view/examples/serving-workloads/`
- `sample-hami.yaml` - HAMI (GPU sharing) integration
- `sample-leaderworkerset-tas.yaml` - LeaderWorkerSet with TAS

**These files are NOT in downstream**

**What it demonstrates:**
- GPU sharing with HAMI (Heterogeneous AI Computing Virtualization Middleware)
- Topology-aware scheduling for serving workloads
- **Missing in downstream**

---

## Files Modified Between Versions

Several files exist in both but have differences:

1. **admin/minimal-cq.yaml** - Likely API version or field changes
2. **admin/single-clusterqueue-setup.yaml** - Configuration updates
3. **jobs/ray-cluster-sample.yaml** - Ray integration changes
4. **jobs/ray-job-sample.yaml** - Ray job configuration updates
5. **jobs/sample-job-partial-admission.yaml** - Partial admission changes
6. **jobs/sample-job.yaml** - Basic job example updates
7. **multikueue/create-multikueue-kubeconfig.sh** - Script improvements
8. **multikueue/multikueue-setup.yaml** - MultiKueue configuration changes
9. **provisioning/provisioning-setup.yaml** - Provisioning changes
10. **provisioning/sample-job.yaml** - Provisioning job updates
11. **sample-admission-check.yaml** - Admission check updates
12. **tas/sample-queues.yaml** - TAS configuration changes

---

## Correlation to Code Differences

The examples differences **directly correlate** to the code differences found earlier:

| Feature | Code Location (Upstream) | Example Location (Upstream) | Status in Downstream |
|---------|-------------------------|----------------------------|---------------------|
| Fair Sharing | `pkg/cache/queue/afs/` | `examples/admission-fs/` | ❌ Missing |
| JAXJob | `pkg/controller/jobs/kubeflow/jobs/jaxjob/` | `examples/jobs/sample-jaxjob.yaml` | ❌ Missing |
| Elastic Jobs | `pkg/workloadslicing/` | `examples/jobs/sample-scalable-job.yaml` | ❌ Missing |
| Visibility API | Enhanced visibility code | `examples/visibility/` (Grafana) | ⚠️ Limited |
| Workload Dispatcher | `pkg/controller/workloaddispatcher/` | Elastic job examples | ❌ Missing |
| Replica Role Metrics | Metrics with `replica_role` label | N/A (monitoring) | ❌ Missing |
| TAS Enhancements | Enhanced TAS in cache | `examples/multikueue/tas/` | ⚠️ Limited |
| Ray Service | Ray service controller | `examples/jobs/ray-service-sample.yaml` | ❌ Missing |

---

## Key Takeaways

### Upstream Enhancements Demonstrated in Examples:

1. **Better Multi-Tenancy:**
   - Fair sharing admission modes
   - Weighted local queues
   - More sophisticated resource allocation

2. **Expanded Job Support:**
   - JAXJob (Google's JAX framework)
   - Ray Service (ML model serving)
   - Elastic/scalable jobs

3. **Enhanced Observability:**
   - Grafana dashboard integration
   - Visibility API for pending workloads
   - Real-time queue monitoring

4. **Advanced Scheduling:**
   - Topology-aware scheduling in multi-cluster
   - GPU sharing with HAMI
   - More complex resource flavor configurations

5. **Better Organization:**
   - Dedicated directories for feature categories
   - Development setup examples (kind configs)
   - More comprehensive documentation (visibility README)

### Downstream Limitations:

- Missing fair sharing examples
- No JAXJob or Ray Service examples
- Limited visibility/monitoring examples
- No elastic job demonstrations
- Less sophisticated resource flavor examples
- Missing TAS multi-cluster examples

---

## Recommendations

For downstream users wanting to adopt upstream features, focus on:

1. **Fair Sharing** - Better multi-tenant resource allocation
2. **Visibility API** - Grafana dashboards for monitoring
3. **Elastic Jobs** - Dynamic workload scaling
4. **Enhanced TAS** - Multi-cluster topology-aware scheduling
5. **New Job Types** - JAXJob, Ray Service support

These examples clearly show that **upstream is actively developing new capabilities** while **downstream is based on an older, more stable version** with fewer features.
