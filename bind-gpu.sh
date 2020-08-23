#!/bin/bash
set -x

gpu=/dev/nvidia1

# from lspci -nn
videoid="10de 1e84"
audioid="10de 10f8"
usbid="10de 1ad8"
videobusid="0000:09:00.0"
audiobusid="0000:09:00.1"
usbbusid="0000:09:00.2"

# prepare, start, stop, release
function __killgpuapp() {
    for y in $(lsof -t ${gpu}); do
        kill "$y"
    done
}

function __bind() {
	systemctl stop display-manager
    __killgpuapp
    # Detach the GPU from drivers and attach to vfio.
    echo $videoid > /sys/bus/pci/drivers/vfio-pci/new_id
    echo $audioid > /sys/bus/pci/drivers/vfio-pci/new_id
    echo $usbid > /sys/bus/pci/drivers/vfio-pci/new_id
    echo $videobusid > /sys/bus/pci/devices/$videobusid/driver/unbind
    echo $audiobusid > /sys/bus/pci/devices/$audiobusid/driver/unbind
    echo $usbid > /sys/bus/pci/devices/$usbid/xhci_hcd/unbind
    echo $videobusid > /sys/bus/pci/drivers/vfio-pci/bind
    echo $audiobusid > /sys/bus/pci/drivers/vfio-pci/bind
    echo $usbbusid > /sys/bus/pci/drivers/vfio-pci/bind

    systemctl start display-manager.service

}

function __unbind() {

    systemctl stop display-manager.service

    # Rebind the GPU to nvidia and snd_hda_intel drivers.
    echo $videoid > /sys/bus/pci/drivers/vfio-pci/remove_id
    echo $audioid > /sys/bus/pci/drivers/vfio-pci/remove_id
    echo $usbid > /sys/bus/pci/drivers/vfio-pci/remove_id
    
    echo $videobusid > /sys/bus/pci/devices/$videobusid/driver/unbind
    echo $audiobusid > /sys/bus/pci/devices/$audiobusid/driver/unbind
    echo $usbbusid > /sys/bus/pci/devices/$usbbusid/driver/unbind

    echo $videobusid > /sys/bus/pci/drivers/nvidia/bind
    echo $audiobusid > /sys/bus/pci/drivers/snd_hda_intel/bind
    echo $usbbusid > /sys/bus/pci/drivers/xhci_hcd/bind

	systemctl start display-manager.service
	sleep 2

	echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind
}

if [ "${2}" = "prepare" ]; then
	if [ "${1}" = "win10-vfio" ]; then
	    touch $logfile
		echo "Preparing ${1}" > $logfile
        __prepare
        __setpages
	fi
fi

__bind