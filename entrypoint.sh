#!/bin/bash

# disk is in /data/vyos.qcow2
# mount PVC on /data to persist config and disk
mkdir -p /data
DISK="/data/vyos.qcow2"
if [ ! -f "$DISK" ]; then
	cp -a "vyos.qcow2" "$DISK"
fi

chmod 666 /dev/kvm

libvirtd --daemon
virtlogd --daemon

until virsh list --all 2>&1 > /dev/null ; do
	echo "wait for libvirt started"
	sleep 5s
done

# virt-install
virt-install --name vyos --memory 2048 --disk "$DISK" --network none --os-variant debiantesting --import --nographic --noautoconsole --print-xml | tee vyos.xml

virsh define vyos.xml

virsh attach-device --config --domain vyos --file qemu-ga.xml

# setup interface bridge for VM
# ignore eth0
# attach interface
# virsh attach-interface --config --domain vyos --type bridge --source br0 --model virtio
ls /sys/class/net | grep -Ev "lo|eth0|bonding_masters" | while read -r INTF; do
	echo $INTF
	ip link add "vyos-$INTF" type bridge ageing_time 0
	ip link set "$INTF" master "vyos-$INTF"
	ip link set "$INTF" up
	ip link set "vyos-$INTF" up
	virsh attach-interface --config --domain vyos --type bridge --source "vyos-$INTF" --model virtio
done

virsh start vyos

# TODO
# qemu ga

sleep infinity
