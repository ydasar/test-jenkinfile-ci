#!/bin/bash

# BUILD ENV
NXP_BOARD="$MACHINE"
SRC_CMD="MACHINE=$MACHINE DISTRO=$DISTRO source imx-snapshot-yocto-setup.sh -b $BUILD_DIR"
BITBAKE_CMD="bitbake $IMAGE_TYPE"
SRC_DEPLOY_DIR="tmp/deploy/images/$MACHINE/"
CUSTOM_DATE=`date +%d-%b-%Y`
DEST_DIR_NAME="Build-""$BUILD_NUMBER""_""$CUSTOM_DATE"
DST_FTP_SERVER="inpftp@inpftp.ina.mentorg.com:/home/inpftp/pub/NXP/$MACHINE/$DEST_DIR_NAME"
FTP_SERVER_LOCATION="ftp://inpftp.ina.mentorg.com:/pub/NXP/$MACHINE/$DEST_DIR_NAME"


# LAVA TEST ENV
LAVA_WORKER="$LAVA_USER@$LAVA_WORKER"
LAVA_JOB="/opt/nxp-tests/$MACHINE.yaml"
DST_LAVA_WORKER_ROOTFS="$LAVA_WORKER:/opt/rootfs/$MACHINE"
DST_LAVA_WORKER_TFTPBOOT="$LAVA_WORKER:/opt/tftpboot/$MACHINE"
LAVA_JOB_URL="http://134.86.60.40/scheduler/job"

# EMAIL_NODE_EXPORT_FILE="/tmp/part1_email_exports"
EMAIL_LOCAL_EXPORT_FILE="/tmp/$MACHINE-exports"
BUILD_STATUS="<h3 style=\"color: white; background-color: red\">FAIL</h3>"
VTE_BUILD_STATUS="<h3 style=\"color: white; background-color: red\">FAIL</h3>"
LAVA_STATUS="<h3 style=\"color: white; background-color: red\">FAIL</h3>"
