#!/bin/bash
set -x

echo "vfio gpu"

videoid="10de 1e84"
audioid="10de 10f8"
usbid="10de 1ad8"
videobusid="0000:09:00.0"
audiobusid="0000:09:00.1"
usbbusid="0000:09:00.2"

#echo $videoid > /sys/bus/pci/drivers/vfio-pci/new_id
#echo $audioid > /sys/bus/pci/drivers/vfio-pci/new_id
#echo $usbid > /sys/bus/pci/drivers/vfio-pci/new_id
#echo $videobusid > /sys/bus/pci/devices/$videobusid/driver/unbind
#echo $audiobusid > /sys/bus/pci/devices/$audiobusid/driver/unbind
#echo $usbid > /sys/bus/pci/devices/$usbid/xhci_hcd/unbind
#echo $videobusid > /sys/bus/pci/drivers/vfio-pci/bind
#echo $audiobusid > /sys/bus/pci/drivers/vfio-pci/bind
#echo $usbbusid > /sys/bus/pci/drivers/vfio-pci/bind

grep='grep --color=always -i'

echo 'Looking for `iommu` messages'
dmesg | ${grep} -e iommu

printf '\n\n\nLooking for `vfio` messages\n'
dmesg | ${grep} -e vfio

printf '\n\n\nGrub commandline\n'
${grep} -e vfio -e iommu /proc/cmdline


#lsof /dev/nvidia1

printf '\n'
for boot_vga in /sys/bus/pci/devices/*/boot_vga; do
  printf "\nFound VGA device: ${boot_vga}\n"
  if [ $(<"${boot_vga}") -eq 0 ]; then
    echo 'Found non-boot VGA device, dumping `lspci -nnks`'
    dev_group=$(basename -- $(dirname -- "${boot_vga}"))
    dev_group=${dev_group::-2}
    echo "dev_group: ${dev_group}"
    lspci -nnks "${dev_group}" | ${grep} -z 'Kernel driver in use:'
  else
    echo "Device ${boot_vga} not passed through"
  fi
done
printf '\n'

