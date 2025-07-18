#!/bin/bash

set -ouex pipefail


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


# Add Flathub by default
mkdir -p /etc/flatpak/remotes.d
curl --retry 3 -o /etc/flatpak/remotes.d/flathub.flatpakrepo "https://dl.flathub.org/repo/flathub.flatpakrepo"


# NVIDIA
if [ "$NVIDIA" == "1" ]; then
	mkdir -p /etc/rpm/
	echo "%_with_kmod_nvidia_open 0" > /etc/rpm/macros.nvidia-kmod

	dnf5 install -y \
		akmod-nvidia \
		xorg-x11-drv-nvidia \
		xorg-x11-drv-nvidia-cuda

	# dnf5 config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-nvidia.repo

	# mkdir /etc/nvidia
	# echo "MODULE_VARIANT=kernel" | tee > /etc/nvidia/kernel.conf

	# dnf5 install -y \
	# 	nvidia-driver \
	# 	nvidia-settings \
	# 	nvidia-driver-cuda \
	# 	nvidia-driver-libs.i686

	akmods --force --rebuild --kernels `rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-devel`

	# dnf install -y \
	# 	-x libva-nvidia-driver.i686 \
	# 	libva-nvidia-driver \
	# 	libva-utils \
	# 	nvidia-vaapi-driver

	curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
		sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

	dnf5 install -y \
		nvidia-container-toolkit

	# nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml # TODO: Make this a service that runs on login
	systemctl enable nvidia-toolkit-generate.service

	NVIDIA_DASHED_VERSION=$(rpm -q --queryformat '%{VERSION}' xorg-x11-drv-nvidia | sed 's/\./-/g')
else
	NVIDIA_DASHED_VERSION=$(dnf5 info xorg-x11-drv-nvidia | grep -i version | cut -c 18-| sed 's/\./-/g')
fi

flatpak install -y org.freedesktop.Platform.GL.nvidia-${NVIDIA_DASHED_VERSION} org.freedesktop.Platform.GL32.nvidia-${NVIDIA_DASHED_VERSION}


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
systemctl enable docker.service
systemctl enable libvirtd.service
systemctl enable rpm-ostreed-automatic.timer
sed -i 's/none/stage/g' /etc/rpm-ostreed.conf
