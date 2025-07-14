#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
# dnf5 install -y tmux 


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
	python3-ramalama \
	rclone \
	restic \
	smartmontools \
	steam-devices \
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
	gnome-software-rpm-ostree


# NVIDIA
dnf5 install -y \
	akmod-nvidia \
	xorg-x11-drv-nvidia-cuda \
	libva-nvidia-driver \
	libva-utils \
	nvidia-vaapi-driver
	# xorg-x11-drv-nvidia \
	# xorg-x11-drv-nvidia-cuda \
	# xorg-x11-drv-nvidia-cuda-libs

KERNEL_SUFFIX=""

QUALIFIED_KERNEL="$(rpm -qa | grep -P 'kernel-(|'"$KERNEL_SUFFIX"'-)(\d+\.\d+\.\d+)' | sed -E 's/kernel-(|'"$KERNEL_SUFFIX"'-)//')"
/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible -v --add ostree -f "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
chmod 0600 "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"

curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
	sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

dnf5 install -y \
	nvidia-container-toolkit

nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml


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
systemctl enable btrfs-balance.timer
systemctl enable btrfs-scrub.timer
systemctl enable cockpit.socket
systemctl enable libvirtd.service
systemctl enable rpm-ostreed-automatic.timer
sed -i 's/none/stage/g' /etc/rpm-ostreed.conf

# tee /etc/systemd/system/rpm-ostreed-automatic.timer.d/override.conf << EOF
# [Timer]
# OnBootSec=
# OnUnitInactiveSec=
# OnCalendar=Mon *-*-* 18:00:00
# Persistent=true
# RandomizedDelaySec=15m
# EOF


# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

# systemctl enable podman.socket
