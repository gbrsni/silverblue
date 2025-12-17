# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image
FROM quay.io/fedora-ostree-desktops/silverblue:43

COPY docker.just /usr/share/custom-justfiles/docker.just
COPY system_files/usr/lib/systemd/system/nvidia-toolkit-generate.service /usr/lib/systemd/system/nvidia-toolkit-generate.service

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh && \
    ostree container commit

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
