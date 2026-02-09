#!/usr/bin/env fish

# Script to enable fair sharing in Kueue configuration

set -g KUEUE_NAMESPACE "opendatahub"

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

print_header "Enabling Fair Sharing in Kueue"

# Check if fair sharing is already enabled
set current_config (kubectl get configmap kueue-manager-config -n $KUEUE_NAMESPACE -o jsonpath='{.data.controller_manager_config\.yaml}' 2>/dev/null)

if echo "$current_config" | grep -q "^fairSharing:" | grep -v "^#"
    print_success "Fair sharing is already enabled"
    echo ""
    echo "Current configuration:"
    echo "$current_config" | grep -A 3 "fairSharing:"
    exit 0
end

print_info "Fair sharing is currently disabled (commented out)"
print_info "Enabling fair sharing..."

# Get current configmap
kubectl get configmap kueue-manager-config -n $KUEUE_NAMESPACE -o yaml > /tmp/kueue-config-backup.yaml
print_success "Backed up current config to /tmp/kueue-config-backup.yaml"

# Create new config with fair sharing enabled
kubectl get configmap kueue-manager-config -n $KUEUE_NAMESPACE -o jsonpath='{.data.controller_manager_config\.yaml}' | \
  sed 's/#fairSharing:/fairSharing:/' | \
  sed 's/#  enable: true/  enable: true/' | \
  sed 's/#  preemptionStrategies:/  preemptionStrategies:/' > /tmp/kueue-config-new.yaml

# Apply the new config
kubectl create configmap kueue-manager-config -n $KUEUE_NAMESPACE --from-file=controller_manager_config.yaml=/tmp/kueue-config-new.yaml --dry-run=client -o yaml | kubectl apply -f -

print_success "Fair sharing configuration updated"

print_info "Restarting Kueue controller to apply changes..."
kubectl rollout restart deployment kueue-controller-manager -n $KUEUE_NAMESPACE

print_info "Waiting for rollout to complete..."
kubectl rollout status deployment kueue-controller-manager -n $KUEUE_NAMESPACE

print_success "Kueue controller restarted successfully"

echo ""
print_info "Waiting 30 seconds for controller to stabilize..."
sleep 30

print_success "Fair sharing is now enabled!"

echo ""
print_info "Verifying configuration..."
kubectl get configmap kueue-manager-config -n $KUEUE_NAMESPACE -o jsonpath='{.data.controller_manager_config\.yaml}' | grep -A 3 "fairSharing:"

echo ""
print_success "Fair sharing configuration complete"
print_info "You can now run the metrics tests to verify weighted_share metrics appear"
