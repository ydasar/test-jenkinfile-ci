#!/bin/bash

# Change the below content for product specific
#MACHINE="imx6ulevk"

#BUILD_TYPE="NONE"
#DISTRO="fsl-imx-wayland"
#BUILD_DIR="build-qt5-wayland-$MACHINE"

NXP_BOARD="imx6ulevk"
ROOTFS_FILE="fsl-image-qt5-validation-imx-$MACHINE.tar.bz2"
ZIMAGE_FILE="zImage"
DTB_FILE="imx6ul-14x14-evk.dtb"

BUILD_BASE_DIR="/home/nxp-user1/NXP-IMX-BOTH-BUILDS/"
LAVA_USER="worker4"
LAVA_WORKER="134.86.254.27"

JENKINS_USER="nxp-user1"
source "scripts/environment/projects/nxp-linux-exports.sh"
