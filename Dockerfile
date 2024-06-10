FROM debian:bookworm

WORKDIR /work

RUN apt update && apt install -y --no-install-recommends iproute2 \
    qemu-system \
    libvirt-clients \
    libvirt-daemon-system \
    virtinst \
    jq \
    inotify-tools

# Debug
RUN apt install -y vim

COPY exec.sh .
COPY entrypoint.sh .
COPY vyos-*.qcow2 vyos.qcow2

VOLUME ["/sys/fs/cgroup"]

ENTRYPOINT /work/entrypoint.sh
CMD ["bash"]
