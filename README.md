# vyos-on-k8s

## Build VyOS KVM image

1. Clone `vyos-build` from github [vyos-build](https://github.com/vyos/vyos-build)
2. put the following yaml file with named `kvm.yaml` in `vyos-build/data/build-flavors/`
3. Run build VyOS command for kvm with the [docs](https://docs.vyos.io/en/latest/contributing/build-vyos.html)
4. You will get `build/vyos-1.5-rolling-202406050831-kvm-amd64.qcow2`, and copy that qcow2 file to the vyos-on-k8s folder.
5. Build VyOS-on-K8s image with Docker and change the image name in `vyos.yaml`
6. Deploy `vyos.yaml` for your cluster.

```yaml
# VyOS image for generic KVM
# In short, a qcow2 image for KVM with serial console

image_format = "qcow2"
image_opts = "-c"

disk_size = 4

packages = ["qemu-guest-agent"]

# GRUB console settings
[boot_settings]
    console_type = "ttyS"
    console_num = '0'
    console_speed = "115200"
```
