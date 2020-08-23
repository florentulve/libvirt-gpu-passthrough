#!/usr/bin/env sh

grep='grep --color=always -i'

echo 'Looking for `iommu` messages'
dmesg | ${grep} -e iommu

printf '\n\n\nLooking for `vfio` messages\n'
dmesg | ${grep} -e vfio

printf '\n\n\nGrub commandline\n'
${grep} -e vfio -e iommu /proc/cmdline

printf '\n\n'
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