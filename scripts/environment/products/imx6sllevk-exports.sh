#!/bin/bash

ROOTFS_FILE="fsl-image-qt5-validation-imx-$MACHINE.tar.bz2"
ZIMAGE_FILE="zImage"
DTB_FILE="imx6sll-evk.dtb"

IMAGE_TYPE="fsl-image-qt5-validation-imx"
BUILD_DIR="build-$TMP_DISTRO-$MACHINE"
EMAIL_NODE_EXPORT_FILE="/tmp/part1_email_exports"

BUILD_BASE_DIR="/home/nxp-user3/NXP-IMX-BOTH-BUILDS/"
LAVA_USER="worker4"
LAVA_WORKER="134.86.254.27"

JENKINS_USER="nxp-user3"
source "scripts/environment/projects/nxp-linux-exports.sh"
