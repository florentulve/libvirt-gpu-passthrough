#!/bin/bash

HUGEPAGES_SIZE=$(grep Hugepagesize /proc/meminfo | awk {'print $2'})
#HUGEPAGES_SIZE=$((HUGEPAGES_SIZE * 1024))
HUGEPAGES_ALLOCATED=$(sysctl vm.nr_hugepages | awk {'print $3'})
VM_HUGEPAGES_NEED=$(( 16777216 / HUGEPAGES_SIZE ))

function __unsetpages() {
    VM_HUGEPAGES_TOTAL=$(($HUGEPAGES_ALLOCATED - $VM_HUGEPAGES_NEED))
    VM_HUGEPAGES_TOTAL=$(($VM_HUGEPAGES_TOTAL<0?0:$VM_HUGEPAGES_TOTAL))
    sysctl vm.nr_hugepages=$VM_HUGEPAGES_TOTAL

    if [[ $VM_HUGEPAGES_TOTAL == '0' ]];
    then
        echo "unset optimization"
        sysctl vm.stat_interval=1
        echo madvise > /sys/kernel/mm/transparent_hugepage/enabled
        echo 1 > /sys/bus/workqueue/devices/writeback/numa
        echo ffff > /sys/bus/workqueue/devices/writeback/cpumask

    fi
}

__unsetpages