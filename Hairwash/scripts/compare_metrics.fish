#!/usr/bin/env fish

# Metrics to ignore in comparison (new upstream metrics not yet in downstream)
set -g METRICS_TO_IGNORE \
    "kueue_build_info" \
    "kueue_evicted_workloads_once_total" \
    "kueue_pods_ready_to_evicted_time_seconds" \
    "kueue_replaced_workload_slices_total" \
    "kueue_admitted_until_ready_wait_time_seconds" \
    "kueue_local_queue_admitted_until_ready_wait_time_seconds" \
    "kueue_local_queue_ready_wait_time_seconds" \
    "kueue_ready_wait_time_seconds"

# Check if exactly 2 arguments are provided
if test (count $argv) -ne 2
    set_color red
    echo "Error: You must provide exactly two CSV files."
    set_color normal
    echo "Usage: ./compare_metrics.fish file1.csv file2.csv"
    exit 1
end

set file1 $argv[1]
set file2 $argv[2]

# Function to extract, clean, and sort the specific column
function get_metric_names
    set target_file $argv[1]

    # 1. Use awk to find the index of the column named "Metric Name"
    set col_idx (awk -F, 'NR==1 {for (i=1; i<=NF; i++) if ($i == "Metric Name") print i}' $target_file)

    if test -z "$col_idx"
        set_color red
        echo "Error: Column 'Metric Name' not found in $target_file" >&2
        set_color normal
        return 1
    end

    # 2. Cut that column, skip the header (tail), sort, and unique it
    # 3. Filter out metrics in the ignore list
    set metrics (cut -d, -f$col_idx $target_file | tail -n +2 | sort | uniq)

    for metric in $metrics
        set should_ignore 0
        for ignore in $METRICS_TO_IGNORE
            if test "$metric" = "$ignore"
                set should_ignore 1
                break
            end
        end

        if test $should_ignore -eq 0
            echo $metric
        end
    end
end

echo "Processing files..."

# Create temporary files to store the sorted lists safely
set temp1 (mktemp)
set temp2 (mktemp)

# Save the processed lists to the temp files
get_metric_names $file1 > $temp1
get_metric_names $file2 > $temp2

# ---------------------------------------------------------
# Check 1: In File 1, but MISSING from File 2
# ---------------------------------------------------------
echo ""
set_color cyan
echo "Values in '$file1' but MISSING in '$file2':"
set_color normal

# comm -23: suppress col 2 (unique to file 2) and col 3 (common)
comm -23 $temp1 $temp2

# ---------------------------------------------------------
# Check 2: In File 2, but MISSING from File 1
# ---------------------------------------------------------
echo ""
set_color yellow
echo "Values in '$file2' but MISSING in '$file1':"
set_color normal

# comm -13: suppress col 1 (unique to file 1) and col 3 (common)
comm -13 $temp1 $temp2

# Cleanup temporary files
rm $temp1 $temp2
