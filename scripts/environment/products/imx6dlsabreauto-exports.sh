#!/bin/bash

ROOTFS_FILE="fsl-image-qt5-validation-imx-$MACHINE.tar.bz2"
ZIMAGE_FILE="zImage"
DTB_FILE="imx6dl-sabreauto.dtb"

IMAGE_TYPE="fsl-image-qt5-validation-imx"
BUILD_DIR="build-qt5-$TMP_DISTRO-$MACHINE"
EMAIL_NODE_EXPORT_FILE="/tmp/part2_email_exports"

BUILD_BASE_DIR="/home/nxp-user4/jenkins/NXP-Pipeline-Builds"
LAVA_USER="user1"
LAVA_WORKER="134.86.254.48"

JENKINS_USER="nxp-user4"
source "scripts/environment/projects/nxp-linux-exports.sh"
