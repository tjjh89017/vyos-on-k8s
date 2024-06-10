FROM debian:bookworm

WORKDIR /work

RUN apt update && apt install -y --no-install-recommends iproute2 \
    qemu-system \
    libvirt-clients \
    libvirt-daemon-system \
    virtinst

# Debug
RUN apt install -y vim

COPY qemu-ga.xml .
COPY entrypoint.sh .
COPY vyos-*.qcow2 vyos.qcow2

VOLUME ["/sys/fs/cgroup"]

ENTRYPOINT /work/entrypoint.sh
CMD ["bash"]
