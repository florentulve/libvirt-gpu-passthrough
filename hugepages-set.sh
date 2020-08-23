#!/bin/bash

#set -x

HUGEPAGES_SIZE=$(grep Hugepagesize /proc/meminfo | awk {'print $2'})
#HUGEPAGES_SIZE=$((HUGEPAGES_SIZE * 1024))
HUGEPAGES_ALLOCATED=$(sysctl vm.nr_hugepages | awk {'print $3'})
VM_HUGEPAGES_NEED=$(( 16777216 / HUGEPAGES_SIZE ))

function __setpages() {
    echo "set hugepages"

    sync
    echo 3 > /proc/sys/vm/drop_caches
    echo 1 > /proc/sys/vm/compact_memory

    VM_HUGEPAGES_TOTAL=$(($HUGEPAGES_ALLOCATED + $VM_HUGEPAGES_NEED))
    sysctl vm.nr_hugepages=$VM_HUGEPAGES_TOTAL
    echo "VM_HUGEPAGES_TOTAL=${VM_HUGEPAGES_TOTAL}"

    if [[ $HUGEPAGES_ALLOCATED == '0' ]];
    then
        echo "set optimizations"
        # Reduce VM jitter: https://www.kernel.org/doc/Documentation/kernel-per-CPU-kthreads.txt
        sysctl vm.stat_interval=120
        #sysctl -w kernel.watchdog=0

        # the kernel's dirty page writeback mechanism uses kthread workers. They introduce
        # massive arbitrary latencies when doing disk writes on the host and aren't
        # migrated by cset. Restrict the workqueue to use only cpu 0.
        echo 0003 > /sys/bus/workqueue/devices/writeback/cpumask

        # THP can allegedly result in jitter. Better keep it off.
        echo never > /sys/kernel/mm/transparent_hugepage/enabled

        # Force P-states to P0
        #echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
        echo 0 > /sys/bus/workqueue/devices/writeback/numa
    fi

}



__setpages



