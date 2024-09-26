#!/bin/bash

function exec_sh() {
	EXEC_SH=$(cat /work/exec.sh | base64 -w 0)
	# open file
	FD=$(virsh qemu-agent-command vyos '{"execute": "guest-file-open", "arguments": {"path": "/config/exec.sh", "mode": "w"}}' | jq -r .return)
	# write file
	virsh qemu-agent-command vyos '{"execute": "guest-file-write", "arguments": {"handle": '"$FD"', "buf-b64": "'"$EXEC_SH"'"}}'
	# close file
	virsh qemu-agent-command vyos '{"execute": "guest-file-close", "arguments": {"handle": '"$FD"'}}'

}

function sync() {
	CONFIG_BOOT=$(cat /config/config.boot | base64 -w 0)
	CONFIG_COMMAND=$(cat /config/config.command | base64 -w 0)

	# open file
	FD=$(virsh qemu-agent-command vyos '{"execute": "guest-file-open", "arguments": {"path": "/config/config.temp", "mode": "w"}}' | jq -r .return)
	# write file
	virsh qemu-agent-command vyos '{"execute": "guest-file-write", "arguments": {"handle": '"$FD"', "buf-b64": "'"$CONFIG_BOOT"'"}}'
	# close file
	virsh qemu-agent-command vyos '{"execute": "guest-file-close", "arguments": {"handle": '"$FD"'}}'

	# open file
	FD=$(virsh qemu-agent-command vyos '{"execute": "guest-file-open", "arguments": {"path": "/config/config.command", "mode": "w"}}' | jq -r .return)
	# write file
	virsh qemu-agent-command vyos '{"execute": "guest-file-write", "arguments": {"handle": '"$FD"', "buf-b64": "'"$CONFIG_COMMAND"'"}}'
	# close file
	virsh qemu-agent-command vyos '{"execute": "guest-file-close", "arguments": {"handle": '"$FD"'}}'

	# TODO load config
	sleep 5s
	virsh qemu-agent-command vyos '{"execute": "guest-exec", "arguments": {"path": "vbash", "arg": ["/config/exec.sh"]}}'
}

# disk is in /data/vyos.qcow2
# mount PVC on /data to persist config and disk
mkdir -p /data
mkdir -p /config
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
virt-install --name vyos --vcpus=2 --memory 2048 --disk "$DISK" --network none --os-variant debiantesting --import --nographic --noautoconsole --print-xml | tee vyos.xml

virsh define vyos.xml

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

while ! virsh qemu-agent-command vyos '{"execute": "guest-ping"}'
do
	echo 'wait for qemu ga'
	sleep 10s
done

# wait for vyos-router ready
while :
do
	sleep 10s
	echo "wait for vyos-router ready"
	#systemctl show vyos-router | grep -E 'ActiveState=active|SubState=exited'
	PID=$(virsh qemu-agent-command vyos '{"execute": "guest-exec", "arguments": {"path": "/bin/vbash", "arg": ["-c", "systemctl show vyos-router | grep -E \"ActiveState=active|SubState=exited\""], "capture-output": true}}' | jq -r .return.pid )
	#echo $PID
	sleep 1s
	RESULT=$(virsh qemu-agent-command vyos '{"execute": "guest-exec-status", "arguments": { "pid": '$PID'}}')
	EXITCODE=$(echo $RESULT | jq -r .return.exitcode)
	EXITED=$(echo $RESULT | jq -r .return.exited)
	OUT_DATA=$(echo $RESULT | jq -r '.return."out-data"')
	if [ "$EXITED" = "true" -a "$EXITCODE" = 0 -a "$OUT_DATA" = "QWN0aXZlU3RhdGU9YWN0aXZlClN1YlN0YXRlPWV4aXRlZAo=" ]
	then
		break
	fi
done

echo "VyOS router is ready"

sleep 10s
exec_sh
sleep 1s
sync

# load config
# load from /config (in container)
# /config/config.boot
# /config/config.command

inotifywait -e delete -m -r /config | 
while read f
do
	echo "CONFIG CHANGED"
	sync
done

sleep infinity
