ARG FEDORA_VERSION="43"
ARG KERNEL="6.17.12-300.fc43.x86_64"

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image
FROM quay.io/fedora-ostree-desktops/silverblue:${FEDORA_VERSION}

COPY docker.just /usr/share/custom-justfiles/docker.just

COPY --from=ghcr.io/ublue-os/akmods:coreos-stable-43-${KERNEL} / /tmp/akmods
RUN find /tmp/akmods
## optionally install remove old and install new kernel
RUN dnf5 -y remove --no-autoremove kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra
RUN dnf5 -y install /tmp/akmods/kernel-rpms/*.rpm

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh && \
    ostree container commit

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
