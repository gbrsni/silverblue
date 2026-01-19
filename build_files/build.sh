#!/bin/bash

set -ouex pipefail


# Base
dnf5 install -y \
	btrfsmaintenance \
	firewall-config \
	fish \
	htop \
	langpacks-en_GB \
	lshw \
	nextcloud-client \
	nvtop \
	rclone \
	restic \
	smartmontools \
	vdpauinfo \
	zsh


# Services
systemctl enable btrfs-balance.timer
systemctl enable btrfs-scrub.timer


# Cleanup
dnf5 clean all
