#!/bin/bash

ROOTFS_FILE="fsl-image-validation-imx-$MACHINE.tar.bz2"
ZIMAGE_FILE="zImage"
DTB_FILE="imx7d-sdb.dtb"

IMAGE_TYPE="fsl-image-validation-imx"
BUILD_DIR="build-$TMP_DISTRO-$MACHINE"
EMAIL_NODE_EXPORT_FILE="/tmp/part2_email_exports"

BUILD_BASE_DIR="/home/user1/jenkins/NXP-Pipeline-Builds"
LAVA_USER="user1"
LAVA_WORKER="134.86.254.48"

JENKINS_USER="user1"
source "scripts/environment/projects/nxp-linux-exports.sh"
