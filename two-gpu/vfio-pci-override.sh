#!/bin/sh

set -u

for boot_vga in /sys/bus/pci/devices/*/boot_vga; do
  echo "Found vga device: ${boot_vga}"
  if [ $(<"${boot_vga}") -eq 0 ]; then
    echo "Found Boot VGA Device - false: ${boot_vga}"
    
    dir=$(dirname -- "${boot_vga}")
    for dev in "${dir::-1}"*; do
      echo "Registering Devices: ${dev}"
      echo 'vfio-pci' > "${dev}/driver_override"
    done
  else
    echo "Found Boot VGA Device - true: ${boot_vga}"
  fi
done

modprobe -i vfio-pci