#!/usr/bin/env fish

# Kueue Metrics Test Cleanup Script
# This script removes all resources created by the metrics test suite

# Colors for output
set -g GREEN '\033[0;32m'
set -g RED '\033[0;31m'
set -g YELLOW '\033[1;33m'
set -g BLUE '\033[0;34m'
set -g NC '\033[0m' # No Color

function print_header
    echo -e "$BLUE"
    echo "========================================"
    echo $argv[1]
    echo "========================================"
    echo -e "$NC"
end

function print_success
    echo -e "$GREEN✓ $argv[1]$NC"
end

function print_error
    echo -e "$RED✗ $argv[1]$NC"
end

function print_info
    echo -e "$YELLOW→ $argv[1]$NC"
end

print_header "Kueue Metrics Test Cleanup"

# Delete all test namespaces
print_info "Deleting test namespaces..."
kubectl delete namespace kueue-test-preemption kueue-test-eviction-deact kueue-test-eviction-cq-stop kueue-test-admission-checks kueue-test-preemption-skip --ignore-not-found=true
if test $status -eq 0
    print_success "Test namespaces deleted"
else
    print_error "Failed to delete test namespaces"
end

# Delete all ClusterQueues
print_info "Deleting ClusterQueues..."
kubectl delete clusterqueue cq-preempt-1 cq-preempt-2 cq-eviction-test cq-admission-check-test cq-1 cq-2 --ignore-not-found=true
if test $status -eq 0
    print_success "ClusterQueues deleted"
else
    print_error "Failed to delete ClusterQueues"
end

# Delete all Cohorts
print_info "Deleting Cohorts..."
kubectl delete cohort test-cohort skip-cohort --ignore-not-found=true
if test $status -eq 0
    print_success "Cohorts deleted"
else
    print_error "Failed to delete Cohorts"
end

# Delete all ResourceFlavors
print_info "Deleting ResourceFlavors..."
kubectl delete resourceflavor default-flavor eviction-flavor admission-check-flavor skip-test-flavor --ignore-not-found=true
if test $status -eq 0
    print_success "ResourceFlavors deleted"
else
    print_error "Failed to delete ResourceFlavors"
end

# Delete AdmissionCheck
print_info "Deleting AdmissionCheck..."
kubectl delete admissioncheck sample-admission-check --ignore-not-found=true
if test $status -eq 0
    print_success "AdmissionCheck deleted"
else
    print_error "Failed to delete AdmissionCheck"
end

# Delete ProvisioningRequestConfig
print_info "Deleting ProvisioningRequestConfig..."
kubectl delete provisioningrequestconfig admission-check-config --ignore-not-found=true
if test $status -eq 0
    print_success "ProvisioningRequestConfig deleted"
else
    print_error "Failed to delete ProvisioningRequestConfig"
end

# Delete PriorityClasses
print_info "Deleting PriorityClasses..."
kubectl delete priorityclass high-priority low-priority --ignore-not-found=true
if test $status -eq 0
    print_success "PriorityClasses deleted"
else
    print_error "Failed to delete PriorityClasses"
end

echo ""
print_header "Cleanup Summary"

# Verify cleanup
print_info "Verifying cleanup..."
echo ""

set -l namespaces_count (kubectl get namespace -o name | grep -E "kueue-test-preemption|kueue-test-eviction|kueue-test-admission|kueue-test-skip" | wc -l | tr -d ' ')
set -l cq_count (kubectl get clusterqueue -o name | grep -E "cq-preempt|cq-eviction|cq-admission|cq-1|cq-2" | wc -l | tr -d ' ')
set -l cohort_count (kubectl get cohort -o name 2>/dev/null | grep -E "test-cohort|skip-cohort" | wc -l | tr -d ' ')
set -l rf_count (kubectl get resourceflavor -o name | grep -E "default-flavor|eviction-flavor|admission-check-flavor|skip-test-flavor" | wc -l | tr -d ' ')
set -l ac_count (kubectl get admissioncheck -o name | grep "sample-admission-check" 2>/dev/null | wc -l | tr -d ' ')
set -l prc_count (kubectl get provisioningrequestconfig -o name | grep "admission-check-config" 2>/dev/null | wc -l | tr -d ' ')
set -l pc_count (kubectl get priorityclass -o name | grep -E "high-priority|low-priority" | wc -l | tr -d ' ')

if test $namespaces_count -eq 0
    print_success "All test namespaces removed"
else
    print_error "Found $namespaces_count test namespace(s) remaining"
end

if test $cq_count -eq 0
    print_success "All test ClusterQueues removed"
else
    print_error "Found $cq_count test ClusterQueue(s) remaining"
end

if test $cohort_count -eq 0
    print_success "All test Cohorts removed"
else
    print_error "Found $cohort_count test Cohort(s) remaining"
end

if test $rf_count -eq 0
    print_success "All test ResourceFlavors removed"
else
    print_error "Found $rf_count test ResourceFlavor(s) remaining"
end

if test $ac_count -eq 0
    print_success "All test AdmissionChecks removed"
else
    print_error "Found $ac_count test AdmissionCheck(s) remaining"
end

if test $prc_count -eq 0
    print_success "All test ProvisioningRequestConfigs removed"
else
    print_error "Found $prc_count test ProvisioningRequestConfig(s) remaining"
end

if test $pc_count -eq 0
    print_success "All test PriorityClasses removed"
else
    print_error "Found $pc_count test PriorityClass(es) remaining"
end

echo ""
set -l total_remaining (math $namespaces_count + $cq_count + $cohort_count + $rf_count + $ac_count + $prc_count + $pc_count)
if test $total_remaining -eq 0
    print_success "Cleanup completed successfully! All test resources removed."
else
    print_error "Cleanup incomplete. $total_remaining resource(s) remaining."
    echo ""
    print_info "To manually verify remaining resources, run:"
    echo "  kubectl get namespace,clusterqueue,cohort,resourceflavor,admissioncheck,provisioningrequestconfig,priorityclass | grep -E 'test|preempt|eviction|admission|skip|cq-1|cq-2'"
end

echo ""
