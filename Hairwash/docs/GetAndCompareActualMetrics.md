oc port-forward -n opendatahub kueue-controller-manager-67c49bc65-2q5x8 8443:8443

set TOKEN (kubectl create token kueue-controller-manager-metrics-reader -n opendatahub --duration=10m)
'The same secret is used by the ServiceMonitor '

curl -sk https://localhost:8443/metrics -H "Authorization: Bearer $TOKEN" | rg "TYPE kueue" > actual-received-metrics.txt

cat actual-received-metrics.txt | grep "^# TYPE" | awk '{print $3 "," $4}' | sort > actual-received-metrics.csv && echo "Metric Name,Type" | cat - actual-received-metrics.csv > temp && mv temp actual-received-metrics.csv && wc -l actual-received-metrics.csv

compare_metrics.fish actual-received-metrics.csv actual-upstream-metrics.csv
