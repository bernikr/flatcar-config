#!/usr/bin/env sh

export VM_ID=101
export DATA_SIZE=5
export CACHE_SIZE=5

set -e

# compile config
podman run --rm -i --volume ${PWD}:/pwd quay.io/coreos/butane:latest -d /pwd < butane.yaml > ignition.json

# download the flatcar image if it does not exist
if ! test -f "flatcar_production_proxmoxve_image.img"; then
  wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_proxmoxve_image.img
fi

# shutdown and remove previous vm
qm shutdown $VM_ID || true
qm destroy $VM_ID || true

# create the vm and import the image to it's disk
qm create $VM_ID --name "flatcar" --cores 2 --memory 4096 --net0 "virtio,bridge=vmbr0" --ipconfig0 "ip=dhcp"
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

# create the data and cache disks
qm set $VM_ID --scsi1 local-lvm:$DATA_SIZE,ssd=1,discard=on,serial=data
qm set $VM_ID --scsi2 local-lvm:$CACHE_SIZE,ssd=1,discard=on,serial=cache

# boot the VM
qm start $VM_ID
