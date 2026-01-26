#!/bin/bash

set -ouex pipefail


# Base
dnf5 install -y \
	fish \
	langpacks-en_GB \
	nextcloud-client \
	zsh


# Cleanup
dnf5 clean all
