#!/bin/bash

NXP_BOARD="imx6ull14x14evk"
ROOTFS_FILE="fsl-image-qt5-validation-imx-$MACHINE.tar.bz2"
ZIMAGE_FILE="zImage"
DTB_FILE="imx6ull-14x14-evk.dtb"

BUILD_BASE_DIR="/home/nxp-user1/NXP-IMX-BOTH-BUILDS/"
LAVA_USER="worker4"
LAVA_WORKER="134.86.254.27"

JENKINS_USER="nxp-user1"
JENKINS_BUILD_NXP_SCRIPT="$BUILD_BASE_DIR/jenkins-build-nxp-common"
source "scripts/environment/projects/nxp-linux-exports.sh"

