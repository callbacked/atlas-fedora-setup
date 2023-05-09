#!/bin/bash

set -e

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" >&2
  exit 1
fi

# Add PCI IDs for the NVIDIA Graphics Card
read -p "Enter the PCI IDs for your NVIDIA Graphics Card (e.g., 10de:13c2,10de:0fbb): " pci_ids

if ! grep -qE 'GRUB_CMDLINE_LINUX.*intel_iommu=on' /etc/default/grub; then
  sed -i "s/\(GRUB_CMDLINE_LINUX=\"[^\"].*\)\"/\1 intel_iommu=on iommu=pt vfio-pci.ids=$pci_ids\"/" /etc/default/grub
else
  echo "IOMMU is already enabled."
  exit 0
fi

if command -v grub2-mkconfig &>/dev/null; then
  grub_cfg_path="/boot/grub2/grub2.cfg"
  grub2-mkconfig -o "$grub_cfg_path"
else
  echo "grub2-mkconfig not found, please update your grub config manually."
  exit 1
fi

# Add force_drivers to /etc/dracut.conf.d/local.conf
dracut_conf_dir="/etc/dracut.conf.d"
dracut_local_conf="$dracut_conf_dir/local.conf"
mkdir -p "$dracut_conf_dir"

if ! grep -q "force_drivers+=\" vfio vfio_iommu_type1 vfio_pci vfio_virqfd \"" "$dracut_local_conf"; then
  echo 'force_drivers+=" vfio vfio_iommu_type1 vfio_pci vfio_virqfd "' >> "$dracut_local_conf"
else
  echo "force_drivers are already set."
fi

# Rebuild the initramfs
dracut -f --kver "$(uname -r)"

echo "IOMMU enabled, force_drivers set, and PCI IDs added successfully. Please reboot your system."
