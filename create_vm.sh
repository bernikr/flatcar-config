#!/usr/bin/env sh

export VM_ID=101
export DATA_SIZE=64 # GB
export CACHE_SIZE=256 # GB
export MEMORY_SIZE=49152 # MB = 48 GB


set -e

# compile config
podman run --rm -i --volume ${PWD}:/pwd quay.io/coreos/butane:latest -d /pwd < butane.yaml > ignition.json

# download the flatcar image if it does not exist
if ! test -f "flatcar_production_proxmoxve_image.img"; then
  wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_proxmoxve_image.img
fi

# shutdown and remove previous vm
if qm list | grep $VM_ID; then
  qm shutdown $VM_ID || true
  lvrename pve vm-$VM_ID-disk-1 temp-1
  lvrename pve vm-$VM_ID-disk-2 temp-2
  qm destroy $VM_ID
fi

# create the vm and import the image to it's disk
qm create $VM_ID --name "flatcar" --cores 8 --memory $MEMORY_SIZE --net0 "virtio,bridge=vmbr0,macaddr=BC:24:11:99:AB:38" --ipconfig0 "ip=dhcp"
qm disk import $VM_ID flatcar_production_proxmoxve_image.img local-lvm

# tell the vm to boot from the imported image
qm set $VM_ID --scsi0 local-lvm:vm-$VM_ID-disk-0
qm set $VM_ID --boot order=scsi0

# Create the cloud-init CD-ROM drive which activates the cloud-init options for the VM.
# This is required for using ignition config as well.
qm set $VM_ID --ide2 local-lvm:cloudinit

# copy over the ignition config and set the vm to it
cp ./ignition.json /var/lib/vz/snippets/ignition
qm set $VM_ID --cicustom "user=local:snippets/ignition"

# create or restore the data and cache disks
if lvs | grep temp-1; then
  lvrename pve temp-1 vm-$VM_ID-disk-1
  qm set $VM_ID --scsi1 local-lvm:vm-$VM_ID-disk-1,ssd=1,discard=on,serial=data
else
  qm set $VM_ID --scsi1 local-lvm:$DATA_SIZE,ssd=1,discard=on,serial=data
fi


if lvs | grep temp-2; then
  lvrename pve temp-2 vm-$VM_ID-disk-2
  qm set $VM_ID --scsi2 local-lvm:vm-$VM_ID-disk-2,ssd=1,discard=on,serial=cache,backup=0
else
  qm set $VM_ID --scsi2 local-lvm:$CACHE_SIZE,ssd=1,discard=on,serial=cache,backup=0
fi

# set the gpu passthrough
qm set $VM_ID --hostpci0 0000:00:02.0

# boot on proxmox startup
qm set $VM_ID --onboot 1

# boot the VM
qm start $VM_ID
