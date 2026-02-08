#!/bin/bash

set -ouex pipefail


# Remove Existing Kernel
for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra; do
	rpm --erase $pkg --nodeps
done

# Fetch Common AKMODS & Kernel RPMS
KERNEL=6.17.12-200.fc42.x86_64
skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods:coreos-stable-"$(rpm -E %fedora)" dir:/tmp/akmods
AKMODS_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods/"$AKMODS_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods/
# NOTE: kernel-rpms should auto-extract into correct location

# Install Kernel
dnf5 -y install \
	/tmp/kernel-rpms/kernel-[0-9]*.rpm \
	/tmp/kernel-rpms/kernel-core-*.rpm \
	/tmp/kernel-rpms/kernel-modules-*.rpm

# TODO: Figure out why akmods cache is pulling in akmods/kernel-devel
dnf5 -y install \
	/tmp/kernel-rpms/kernel-devel-*.rpm

dnf5 versionlock add kernel kernel-devel kernel-devel-matched kernel-core kernel-modules kernel-modules-core kernel-modules-extra


# RPMFusion
dnf5 install -y \
	https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
	https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm


# Base
dnf5 install -y \
	btrfsmaintenance \
	cockpit \
	cockpit-machines \
	distrobox \
	ffmpegthumbnailer \
	firewall-config \
	fish \
	freerdp \
	gnome-shell-extension-appindicator \
	gnome-shell-extension-blur-my-shell \
	gnome-shell-extension-caffeine \
	gnome-shell-extension-gsconnect \
	gnome-tweaks \
	htop \
	just \
	langpacks-en_GB \
	libvirt \
	libvirt-nss \
	lshw \
	nextcloud-client \
	nvtop \
	openrgb \
	python3-ramalama \
	rclone \
	restic \
	smartmontools \
	steam-devices \
	tailscale \
	vdpauinfo \
	virt-manager \
	virt-viewer \
	wireguard-tools \
	zsh


# Media
dnf5 swap -y ffmpeg-free ffmpeg --allowerasing
dnf5 group install -y multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
dnf5 install -y rpmfusion-free-release-tainted
dnf5 install -y libdvdcss

dnf5 remove -y \
	gnome-software-rpm-ostree \
	firefox \
	firefox-langpacks


# Add Flathub by default
mkdir -p /etc/flatpak/remotes.d
curl --retry 3 -o /etc/flatpak/remotes.d/flathub.flatpakrepo "https://dl.flathub.org/repo/flathub.flatpakrepo"


# Docker
curl https://download.docker.com/linux/fedora/docker-ce.repo | tee > /etc/yum.repos.d/docker-ce.repo

dnf5 install -y \
	containerd.io \
	docker-buildx-plugin \
	docker-ce \
	docker-ce-cli \
	docker-compose-plugin


# VSCode
rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/vscode.repo > /dev/null

dnf5 install -y code


# Brew
dnf -y --setopt=install_weak_deps=False install gcc
dnf5 install -y procps-ng curl file


# Services
systemctl mask flatpak-add-fedora-repos.service

systemctl enable btrfs-balance.timer
systemctl enable btrfs-scrub.timer
systemctl enable cockpit.socket
systemctl enable docker.service
systemctl enable libvirtd.service
systemctl enable rpm-ostreed-automatic.timer
sed -i 's/none/stage/g' /etc/rpm-ostreed.conf


# Cleanup
dnf5 clean all


# Initramfs
KERNEL_SUFFIX=""
QUALIFIED_KERNEL="$(rpm -qa | grep -P 'kernel-(|'"$KERNEL_SUFFIX"'-)(\d+\.\d+\.\d+)' | sed -E 's/kernel-(|'"$KERNEL_SUFFIX"'-)//')"
export DRACUT_NO_XATTR=1
/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible -v --add ostree -f "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
chmod 0600 "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
