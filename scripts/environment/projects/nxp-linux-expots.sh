#!/bin/bash

# BUILD ENV
IMAGE_TYPE="fsl-image-qt5-validation-imx"
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
LAVA_JOB_URL="http://134.86.60.40/scheduler/job/"

BUILD_STATUS="<h3 style=\"color: white; background-color: red\">FAIL</h3>"
echo "${MACHINE}_${TMP_DISTRO}_build_status = $BUILD_STATUS" >> $EXPORT_FILE
VTE_BUILD_STATUS="<h3 style=\"color: white; background-color: red\">FAIL</h3>"
echo "${MACHINE}_${TMP_DISTRO}_vte_build_status = $VTE_BUILD_STATUS" >> $EXPORT_FILE
LAVA_STATUS="<h3 style=\"color: white; background-color: red\">FAIL</h3>"
echo "${MACHINE}_${TMP_DISTRO}_LAVA_STATUS = $LAVA_STATUS" >> $EXPORT_FILE

# Export variables file name
EXPORT_FILE="/tmp/nxp-all-products-export"
