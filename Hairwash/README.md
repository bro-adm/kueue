## Metrics Overview

Metrics Releavnt enablement configs:

- metrics.enableClusterQueueResources: true
- featureGates.LocalQueueMetrics: true
- waitForPodsReady: true

[Metrics CSV](./upstream-metrics.csv)
[Metrics Docs](https://kueue.sigs.k8s.io/docs/reference/metrics/)

## Reproducible Environments

The [config](./config) dir has the [default kustomize](./config/default/kustomization.yaml) which is self explantory, but in short, it holds the enablement of stuff like metrics, prometheus components and visisbility APIs.

Be default the visibility API and manager metrics are enbaled. the prometheus components are not.

The [default config](./config/components/manager/controller_manager_config.yaml) does not contain any optional metrics.

The [tests manifests](./test/e2e/config/default) have some optional metrics enabled (metrics.enableClusterQueueResources: true | featureGates.LocalQueueMetrics: true) 

## Feature Gates

[Stages and Defaults](https://kueue.sigs.k8s.io/docs/installation/#feature-gates-for-alpha-and-beta-features)

## Post Kueue Config

After configuring the Kueue instance via its CRD you have the kueue CRDs.
Here are the [example configs](./site/static/examples)

## RedHat

RedHat Build is based on the v1beta1 api and not the upstream main v1beta2
RedHat has enabled by default metrics.enableClusterQueueResources and waitForPodsReady this can be seen in the same [default config](./config/components/manager/controller_manager_config.yaml)

[RHOAI config](./config/rhoai)

For some reason RedHat also chnages default true to false visibility on demand, i think it should not effect the metrics exported so we dont care for now.

It does enable the Alpha (not Beta yet) LocalQueueMetrics feature gate

Both can be seen in the [config patch](./config/rhoai/manager_config_patch.yaml)

Somehow installing the redaht build of kueue form the catalog does not install with the patch to enable feature gate LocalQueueMetrics

### Extra changes

[IBM CodeFlare role access](./config/rhoai/manager_role_patch.yaml)
Doesnt change shitt, becuase already existss in the [original rbac role](./config/components/rbac/role.yaml) was added once as patch instead of directly and then not cleaned up when added directly (git history)
