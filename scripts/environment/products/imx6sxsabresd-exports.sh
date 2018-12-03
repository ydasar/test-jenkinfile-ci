#!/bin/bash

# Change the below content for product specific
MACHINE="imx6sxsabresd"

BUILD_TYPE="NONE"
DISTRO="fsl-imx-wayland"
BUILD_DIR="build-qt5-wayland-$MACHINE"

NXP_BOARD="imx6sxsabresd"
ROOTFS_FILE="fsl-image-qt5-validation-imx-$MACHINE.tar.bz2"
ZIMAGE_FILE="zImage"
DTB_FILE="imx6sx-sdb.dtb"

BUILD_BASE_DIR="/home/nxp-user3/NXP-IMX-BOTH-BUILDS/"
LAVA_USER="worker4"
LAVA_WORKER="134.86.254.27"

JENKINS_USER="nxp-user3"
source "scripts/environment/projects/nxp-linux-expots.sh"
