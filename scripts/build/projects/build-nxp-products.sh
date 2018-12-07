#!/bin/bash

# Check for number of arguments and validate the function call
if [ $# -lt 2 ]
then
    echo "Usage is: build-nxp-products.sh FUNCTION_NAME MACHINE DISTRO BUILD_TYPE"
    echo "FUNCTION_NAME can be BuildDistro, vte_build, CopyToFTP, CopyToWorker, LavaTest, clear_node_export, clear_product_export"
    echo "MACHINE can be imx6slevk, imx6sxsabresd etc"
    echo "DISTRO can be wayland, xwayland"
    echo "BUILD_TYPE can be CLEAN, UPDATE"
    exit 1
fi

# Check for 4th parameter. If not provided, based on week day consider "UPDATE", if it is saturday consider "CLEAN"
if [ -z "$4" ]
then
    today="$(date +%a)"
    if [ "${today}" == "Sat" ]
    then
        echo "We are on Saturday"
        BUILD_TYPE="CLEAN"
    else
        echo "We are on Weekdays"
        BUILD_TYPE="UPDATE"
    fi
else
    BUILD_TYPE="$4"
fi

# Assign input parameters to corresponding values
CALLED_FUNCTION="$1"
MACHINE="$2"
TMP_DISTRO="$3"
DISTRO="fsl-imx-$TMP_DISTRO"
# BUILD_TYPE="$4"
BUILD_DIR="build-qt5-$TMP_DISTRO-$MACHINE"
# VTE_BUILD="$5"
SRC_CMD="MACHINE=$MACHINE DISTRO=$DISTRO source imx-snapshot-yocto-setup.sh -b $BUILD_DIR"
source "scripts/environment/products/$MACHINE-exports.sh"


# Error handling is kept. user has scope to expand it.
ErrorHandle()
{    
    exit 1
}

# Delete consolidated email export file
clear_node_export()
{
    if [ -f $EMAIL_NODE_EXPORT_FILE ]
    then
        echo "Delete $EMAIL_NODE_EXPORT_FILE file"
        rm $EMAIL_NODE_EXPORT_FILE 
    fi
}

# Delete local email export file 
clear_product_export()
{
    if [ -f $EMAIL_LOCAL_EXPORT_FILE ]
    then
        echo "Delete $EMAIL_LOCAL_EXPORT_FILE file"
        rm $EMAIL_LOCAL_EXPORT_FILE
    fi
}

# Export build parameters for consolidated email and local email
export_build_variables()
{
    # Variables to be exported and injected for consolidated email
    echo "${MACHINE}_${TMP_DISTRO}_EMAIL_SUBJECT = NXP build $BUILD_NUMBER details" >> $EMAIL_NODE_EXPORT_FILE
    echo "${MACHINE}_${TMP_DISTRO}_CAUSE = $CAUSE" >> $EMAIL_NODE_EXPORT_FILE
    echo "${MACHINE}_${TMP_DISTRO}_MACHINE =  $MACHINE" >> $EMAIL_NODE_EXPORT_FILE
    echo "${MACHINE}_${TMP_DISTRO}_SRC_CMD = $SRC_CMD" >> $EMAIL_NODE_EXPORT_FILE
    echo "${MACHINE}_${TMP_DISTRO}_BITBAKE_CMD = $BITBAKE_CMD" >> $EMAIL_NODE_EXPORT_FILE
    echo "${MACHINE}_${TMP_DISTRO}_build_status = $BUILD_STATUS" >> $EMAIL_NODE_EXPORT_FILE
    echo "${MACHINE}_${TMP_DISTRO}_build_time = $BUILD_TIME" >> $EMAIL_NODE_EXPORT_FILE
    echo "${MACHINE}_${TMP_DISTRO}_BUILD_URL = $BUILD_URL" >> $EMAIL_NODE_EXPORT_FILE
    if [ $BUILD_TYPE = "CLEAN" ]
    then
        echo "${MACHINE}_${TMP_DISTRO}_build_type = Scratch" >> $EMAIL_NODE_EXPORT_FILE
    else
        echo "${MACHINE}_${TMP_DISTRO}_build_type = Incremental" >> $EMAIL_NODE_EXPORT_FILE
    fi

    # Variables to be exported and injected for individual product email
    echo "product_${TMP_DISTRO}_EMAIL_SUBJECT = NXP $MACHINE build $BUILD_NUMBER " >> $EMAIL_LOCAL_EXPORT_FILE
    echo "product_${TMP_DISTRO}_CAUSE = $CAUSE" >> $EMAIL_LOCAL_EXPORT_FILE
    echo "product_${TMP_DISTRO}_MACHINE =  $MACHINE" >> $EMAIL_LOCAL_EXPORT_FILE
    echo "product_${TMP_DISTRO}_SRC_CMD = $SRC_CMD" >> $EMAIL_LOCAL_EXPORT_FILE
    echo "product_${TMP_DISTRO}_BITBAKE_CMD = $BITBAKE_CMD" >> $EMAIL_LOCAL_EXPORT_FILE
    echo "product_${TMP_DISTRO}_build_status = $BUILD_STATUS" >> $EMAIL_LOCAL_EXPORT_FILE
    echo "product_${TMP_DISTRO}_build_time = $BUILD_TIME" >> $EMAIL_LOCAL_EXPORT_FILE
    echo "product_${TMP_DISTRO}_BUILD_URL = $BUILD_URL" >> $EMAIL_LOCAL_EXPORT_FILE
    if [ $BUILD_TYPE = "CLEAN" ]
    then
        echo "product_${TMP_DISTRO}_build_type = Scratch" >> $EMAIL_LOCAL_EXPORT_FILE
    else
        echo "product_${TMP_DISTRO}_build_type = Incremental" >> $EMAIL_LOCAL_EXPORT_FILE
    fi
}

# Function to make incrementa (UPDATE) or scratch (CLEAN) builds.
BuildDistro()
{

    # Note down build start time
    build_start_time=`date +%s`
    export_build_variables
    cd $BUILD_BASE_DIR

    # For CLEAN build, delete the directory and start new build
    if [ $BUILD_TYPE = "CLEAN" ]
    then

        echo "CLEAN Build. Current directory is $PWD"
        # Clean the temporary files
        rm -rf /tmp/$BUILD_DIR ; mv $BUILD_DIR /tmp ; rm -rf /tmp/$BUILD_DIR &

        # Create new directories for builds
        mkdir $BUILD_DIR ; cd $BUILD_DIR

        # Clone the NXP base sources
        git clone git@github.com:MentorEmbedded/meta-imx-snapshot.git -b v4.14.62_1.0.0_beta_drop-2
        retVal=$?
        if [ $retVal -ne 0 ]
        then
            echo "git clone failed"
            ErrorHandle
        fi

        # Download the NXP source
        cd meta-imx-snapshot
        wget http://easource.alm.mentorg.com/sources/elm/nxp-sources/v4.14.62_1.0.0_beta_src_drop_2.tar.gz
        retVal=$?
        if [ $retVal -ne 0 ]
        then
            echo "wget failed"
            ErrorHandle
        fi

        # Untar the NXP source
        tar -xf v4.14.62_1.0.0_beta_src_drop_2.tar.gz
        retVal=$?
        if [ $retVal -ne 0 ]
        then
            echo "tar/untar failed"
            ErrorHandle
        fi

        # Setup the NXP source
        ./setup.sh
        retVal=$?
        if [ $retVal -ne 0 ]
        then
            echo "setup failed"
            ErrorHandle
        fi
                
        echo "CLEAN Build. Current directory is $PWD"
        # Add EULA license acceptance
        sed -i 's/^EULA_ACCEPTED=/EULA_ACCEPTED=1/' ./sources/base/setup-environment
        echo " Sourcing command is $SRC_CMD"
        eval $SRC_CMD
        # Add EULA license
        echo -e '\nACCEPT_FSL_EULA = "1"' >> conf/local.conf
        # Add Mentor NXP layer to bblayers
        echo 'BBLAYERS += " ${BSPDIR}/sources/meta-nxp-maintenance "' >> conf/bblayers.conf
                        
    else

        echo "UPDATE Build. Current directory is $PWD"
        cd $BUILD_DIR ; cd meta-imx-snapshot
        retVal=$?
        if [ $retVal -ne 0 ]
        then
            echo "Change directory failed. $BUILD_DIR"
            ErrorHandle
        fi

        # Update source cloned source
        repo sync ; git pull
                
        echo "UPDATE Build. Current directory is $PWD"
        # Source the build
        source setup-environment $BUILD_DIR
        # Once the source is completed somehow we are loosing MACHINE info. This is hack to retain the MACHINE
        MACHINE=$NXP_BOARD
        # Clean the build state
        # bitbake -c cleanall $IMAGE_TYPE
        bitbake -c cleansstate $IMAGE_TYPE
                        
    fi


    # Bake the image
    eval $BITBAKE_CMD
    retVal=$?
    if [ $retVal -ne 0 ]
    then
            echo "bitbake fail. $BITBAKE_CMD"
            ErrorHandle
    fi
    
    # Note down build end time
    build_end_time=`date +%s`
    # Calculate build time
    build_time=$((build_end_time-build_start_time))
    BUILD_TIME="$(($build_time / 60)) minutes and $(($build_time % 60)) seconds"

    BUILD_STATUS="Successful"
    # export the variables to jenkins environment
    export_build_variables

}

# Export VTE build parameters for consolidated and individual email
export_vte_variables()
{
    echo "${MACHINE}_${TMP_DISTRO}_vte_build_status = $VTE_BUILD_STATUS" >> $EMAIL_NODE_EXPORT_FILE
    echo "${MACHINE}_${TMP_DISTRO}_vte_build_time = $BUILD_TIME" >> $EMAIL_NODE_EXPORT_FILE

    echo "product_${TMP_DISTRO}_vte_build_status = $VTE_BUILD_STATUS" >> $EMAIL_LOCAL_EXPORT_FILE
    echo "product_${TMP_DISTRO}_vte_build_time = $BUILD_TIME" >> $EMAIL_LOCAL_EXPORT_FILE
}


# build VTE. This executed for scratch or incremental builds
vte_build()
{

    # VTE Building
    echo " Current directory is $PWD"
    export_vte_variables

    # Note down build start time
    build_start_time=`date +%s`

    cd $BUILD_BASE_DIR ; cd $BUILD_DIR ; cd meta-imx-snapshot
    source setup-environment $BUILD_DIR

    VTE_TAR="$BUILD_BASE_DIR/IMX_VTE_TESTS-20180925.tar"
    MANUAL_FILE="$BUILD_BASE_DIR/manual_test"
    VTE_TEST="./tmp/deploy/sdk"
    TMP_ROOTFS="used_by_vte"

    bitbake $IMAGE_TYPE -c populate_sdk
    retVal=$?
    if [ $retVal -ne 0 ]
    then
        echo "bitbake sdk failed $IMAGE_TYPE"
        ErrorHandle
    fi

    MACHINE=$NXP_BOARD

    tar -xvf $VTE_TAR --directory $VTE_TEST
    retVal=$?
    if [ $retVal -ne 0 ]
    then
        echo "vte file extract failed $VTE_TAR to $VTE_TEST"
        ErrorHandle
    fi

    # install SDK
    cd $VTE_TEST
    ./fsl-imx-*.sh -y -d ltp-imx-tests
    retVal=$?
    if [ $retVal -ne 0 ]
    then
        echo "SDK install failed $VTE_TEST"
        ErrorHandle
    fi

    cd ltp-imx-tests/
    # Find the architecture
    ls ../*.sh | grep -i cortexa7hf
    retVal=$?
    if [ $retVal -eq 0 ]
    then
        ARCH="imx7d"
    else
        ARCH="imx6q"
    fi

    ./setup-env-imx-tests.sh -s . -a $ARCH
    retVal=$?
    if [ $retVal -ne 0 ]
    then
        echo "setup env imx test failed"
        ErrorHandle
    fi

    echo $JENKINS_USER | sudo -S pwd
    echo $JENKINS_USER | sudo -S rm -rf $TMP_ROOTFS
    mkdir -p $TMP_ROOTFS
    echo $JENKINS_USER | sudo -S tar -xjf ../../../../tmp/deploy/images/$NXP_BOARD/$ROOTFS_FILE --directory $TMP_ROOTFS
    retVal=$?
    if [ $retVal -ne 0 ]
    then
        echo "extract root file system failed $MACHINE $NXP_BOARD $ROOTFS_FILE $TMP_ROOTFS"
        ErrorHandle
    fi

    echo $JENKINS_USER | sudo -S cp -arf ../linux-imx-tests/ltp/testcases/bin/* $TMP_ROOTFS/opt/ltp/testcases/bin/
    echo $JENKINS_USER | sudo -S cp -arf ../linux-imx-tests/ltp/runtest/MX* $TMP_ROOTFS/opt/ltp/runtest/
    echo $JENKINS_USER | sudo -S cp $MANUAL_FILE $TMP_ROOTFS/opt/ltp

    now=`date +%s`
    mv ../../../../tmp/deploy/images/$NXP_BOARD/fsl-image-qt5-validation-imx-$NXP_BOARD.tar.bz2 \
    ../../../../tmp/deploy/images/$NXP_BOARD/$now-fsl-image-qt5-validation-imx-$NXP_BOARD.tar.bz2
    retVal=$?
    if [ $retVal -ne 0 ]
    then
        echo "Move failed. $MACHINE $NXP_BOARD $ROOTFS_FILE $TMP_ROOTFS"
        ErrorHandle
    fi

    cd $TMP_ROOTFS
    echo $JENKINS_USER | sudo -S tar -cjf ../../../../../tmp/deploy/images/$NXP_BOARD/fsl-image-qt5-validation-imx-$NXP_BOARD.tar.bz2 *
    retVal=$?
    if [ $retVal -ne 0 ]
    then
        echo "compress root file system failed $MACHINE $NXP_BOARD $ROOTFS_FILE $TMP_ROOTFS"
        ErrorHandle
    fi

    echo $JENKINS_USER | sudo -S rm -rf $TMP_ROOTFS
    # Once the source is completed somehow we are loosing MACHINE info. This is hack to retain the MACHINE
    MACHINE=$NXP_BOARD

    # Note down build end time
    build_end_time=`date +%s`
    # Calculate build time
    build_time=$((build_end_time-build_start_time))
    BUILD_TIME="$(($build_time / 60)) minutes and $(($build_time % 60)) seconds"

    VTE_BUILD_STATUS="Successful"       
    export_vte_variables

}


# Export FTP parameters for consolidated and individual email
export_ftp_variables()
{
    echo "${MACHINE}_${TMP_DISTRO}_FTP_SERVER_LOCATION = No URL" >> $EMAIL_NODE_EXPORT_FILE
    echo "${MACHINE}_${TMP_DISTRO}_FTP_SERVER_LOCATION = $FTP_SERVER_LOCATION" >> $EMAIL_NODE_EXPORT_FILE

    echo "product_${TMP_DISTRO}_FTP_SERVER_LOCATION = No URL" >> $EMAIL_LOCAL_EXPORT_FILE
    echo "product_${TMP_DISTRO}_FTP_SERVER_LOCATION = $FTP_SERVER_LOCATION" >> $EMAIL_LOCAL_EXPORT_FILE
}



# Copy build artifacts to FTP server
CopyToFTP()
{

    export_ftp_variables
    cd $BUILD_BASE_DIR ; cd $BUILD_DIR ; cd meta-imx-snapshot ; cd $BUILD_DIR
    # Create a new directory in FTP server
    DEST_DIR_NAME="$DEST_DIR_NAME""_""$TMP_DISTRO"
    echo "DEST_DIR_NAME is $DEST_DIR_NAME"
    ssh inpftp@inpftp.ina.mentorg.com "mkdir pub/NXP/$MACHINE/$DEST_DIR_NAME"
    #retVal=$?
    #if [ $retVal -ne 0 ]
    #then
    #       echo "Directory ($DEST_DIR_NAME)creation at FTP server failed"
    #       ErrorHandle
    #fi

    # Copy root file system to FTP server
    DST_FTP_SERVER="$DST_FTP_SERVER""_""$TMP_DISTRO"
    echo "DST_FTP_SERVER is $DST_FTP_SERVER"

    rsync -a -v -L $SRC_DEPLOY_DIR$ROOTFS_FILE $DST_FTP_SERVER
    retVal=$?
    if [ $retVal -ne 0 ]
    then
        echo "rsync failed to copy $SRC_DEPLOY_DIR$ROOTFS_FILE to $DST_FTP_SERVER"
        ErrorHandle
    fi

    # Copy zimage to FTP server
    rsync -a -v -L $SRC_DEPLOY_DIR$ZIMAGE_FILE $DST_FTP_SERVER
    retVal=$?
    if [ $retVal -ne 0 ]
    then
        echo "rsync failed to copy $SRC_DEPLOY_DIR$ZIMAGE_FILE to $DST_FTP_SERVER"
        ErrorHandle
    fi

    # Copy dtb to FTP server
    rsync -a -v -L $SRC_DEPLOY_DIR$DTB_FILE $DST_FTP_SERVER
    retVal=$?
    if [ $retVal -ne 0 ]
    then
        echo "rsync failed to copy $SRC_DEPLOY_DIR$DTB_FILE to $DST_FTP_SERVER"
        ErrorHandle
    fi

    # export the variables to jenkins environment
    FTP_SERVER_LOCATION="ftp://inpftp.ina.mentorg.com:/pub/NXP/$MACHINE/$DEST_DIR_NAME"
    export_ftp_variables

}


# Copy build artifacts to LAVA worker
CopyToWorker()
{
        
    cd $BUILD_BASE_DIR ; cd $BUILD_DIR ; cd meta-imx-snapshot ; cd $BUILD_DIR
    rsync -a -v -L $SRC_DEPLOY_DIR$ROOTFS_FILE $DST_LAVA_WORKER_ROOTFS
    retVal=$?
    if [ $retVal -ne 0 ]
    then
        echo "rsync failed to copy $SRC_DEPLOY_DIR$ROOTFS_FILE $DST_LAVA_WORKER_ROOTFS"
        ErrorHandle
    fi

    rsync -a -v -L $SRC_DEPLOY_DIR$ZIMAGE_FILE $DST_LAVA_WORKER_TFTPBOOT
    retVal=$?
    if [ $retVal -ne 0 ]
    then
        echo "rsync failed to copy $SRC_DEPLOY_DIR$ZIMAGE_FILE $DST_LAVA_WORKER_TFTPBOOT"
        ErrorHandle
    fi

    rsync -a -v -L $SRC_DEPLOY_DIR$DTB_FILE $DST_LAVA_WORKER_TFTPBOOT
    retVal=$?
    if [ $retVal -ne 0 ]
    then
        echo "rsync failed to copy $SRC_DEPLOY_DIR$DTB_FILE $DST_LAVA_WORKER_TFTPBOOT"
        ErrorHandle
    fi

}

# Export LAVA test parameters for consolidated and individual email
export_lava_variables()
{
    echo "${MACHINE}_${TMP_DISTRO}_LAVA_JOB_URL = $LAVA_JOB_URL/$LAVA_JOB_ID" >> $EMAIL_NODE_EXPORT_FILE
    echo "${MACHINE}_${TMP_DISTRO}_LAVA_TEST_TIME = $LAVA_TEST_TIME" >>  $EMAIL_NODE_EXPORT_FILE
    echo "${MACHINE}_${TMP_DISTRO}_U_BOOT_VER = $u_boot_ver" >> $EMAIL_NODE_EXPORT_FILE
    echo "${MACHINE}_${TMP_DISTRO}_KERNEL_VER = $kernel_ver" >> $EMAIL_NODE_EXPORT_FILE
    echo "${MACHINE}_${TMP_DISTRO}_TEST_SUITES = $test_suite_pass_fail_skip" >> $EMAIL_NODE_EXPORT_FILE
    echo "${MACHINE}_${TMP_DISTRO}_LAVA_STATUS = $LAVA_STATUS" >> $EMAIL_NODE_EXPORT_FILE

    echo "product_${TMP_DISTRO}_LAVA_JOB_URL = $LAVA_JOB_URL/$LAVA_JOB_ID" >> $EMAIL_LOCAL_EXPORT_FILE
    echo "product_${TMP_DISTRO}_LAVA_TEST_TIME = $LAVA_TEST_TIME" >> $EMAIL_LOCAL_EXPORT_FILE
    echo "product_${TMP_DISTRO}_U_BOOT_VER = $u_boot_ver" >> $EMAIL_LOCAL_EXPORT_FILE
    echo "product_${TMP_DISTRO}_KERNEL_VER = $kernel_ver" >> $EMAIL_LOCAL_EXPORT_FILE
    echo "product_${TMP_DISTRO}_TEST_SUITES = $test_suite_pass_fail_skip" >> $EMAIL_LOCAL_EXPORT_FILE
    echo "product_${TMP_DISTRO}_LAVA_STATUS = $LAVA_STATUS" >> $EMAIL_LOCAL_EXPORT_FILE
}

# Execute LAVA tests
LavaTest()
{

    export_lava_variables
    # Note down LAVA test start time
    lava_start_time=`date +%s`

    # Trigger LAVA test
    LAVA_JOB_ID=`ssh $LAVA_WORKER "lavacli -i nxp-imx jobs submit $LAVA_JOB"`
    retVal=$?
    if [ $retVal -ne 0 ]
    then
        echo "Could not run the LAVA job $LAVA_JOB at server $LAVA_WORKER"
        ErrorHandle
    fi

    # Wait, let LAVA trigger initiate
    sleep 10

    # Wait LAVA to complete the job. This function supose to to be time bound. 
    # A new mechanism has to be apated here
    ssh $LAVA_WORKER "lavacli -i nxp-imx jobs wait $LAVA_JOB_ID"
    ssh $LAVA_WORKER "lavacli -i nxp-imx results $LAVA_JOB_ID" | grep -i "lava.job \[pass\]"
    retVal=$?
    if [ $retVal -ne 0 ]
    then
        echo "LAVA job $LAVA_JOB at server $LAVA_WORKER execution failed"
        ErrorHandle
    fi

    # LAVA test results format
    test_suite_pass_fail_skip="</br>"
    test_suites_count=0
    total_test_cases=0
    total_test_cases_pass=0
    total_test_cases_fail=0
    total_test_cases_skip=0

    # List the test suites
    test_suites=`ssh $LAVA_WORKER "lavacli -i nxp-imx jobs definition $LAVA_JOB_ID | grep -ia test_suite | cut -d':' -f2 | cut -d' ' -f2"`
    echo $test_suites

    test_suites=($test_suites)

    # Loop LAVA test suites and identify PASS/FAIL/SKIP
    for SUITE_NAME in "${test_suites[@]}"; do
        suite_detail_name="$test_suites_count""_""$SUITE_NAME"
        echo "Test suite name is $suite_detail_name"

        test_cases_pass=`ssh $LAVA_WORKER "lavacli -i nxp-imx results $LAVA_JOB_ID $suite_detail_name | grep -ia pass | wc -l"`
        echo "$suite_detail_name has total $test_cases_pass pass test cases"

        test_cases_fail=`ssh $LAVA_WORKER "lavacli -i nxp-imx results $LAVA_JOB_ID $suite_detail_name | grep -ia fail | wc -l"`
        echo "$suite_detail_name has total $test_cases_fail fail test cases"

        test_cases_skip=`ssh $LAVA_WORKER "lavacli -i nxp-imx results $LAVA_JOB_ID $suite_detail_name | grep -ia skip | wc -l"`
        echo "$suite_detail_name has total $test_cases_skip skip test cases"

        test_suite_pass_fail_skip="$test_suite_pass_fail_skip $suite_detail_name pass=$test_cases_pass fail=$test_cases_fail skip=$test_cases_skip""</br>"
        test_suites_count=`expr $test_suites_count + 1`

        total_test_cases_pass=`expr $total_test_cases_pass + $test_cases_pass`
        total_test_cases_fail=`expr $total_test_cases_fail + $test_cases_fail`
        total_test_cases_skip=`expr $total_test_cases_skip + $test_cases_skip`
        total_test_cases=`expr $total_test_cases_pass + $total_test_cases_fail + $total_test_cases_skip`
    done

    test_suite_pass_fail_skip="$test_suite_pass_fail_skip <\br> Total test cases=$total_test_cases Total pass=$total_test_cases_pass Total fail=$total_test_cases_fail Total skip=$total_test_cases_skip"
    echo "Test suites and results details $test_suite_pass_fail_skip"

    # Remember uboot and kernel version
    u_boot_ver=`ssh $LAVA_WORKER "lavacli -i nxp-imx jobs logs $LAVA_JOB_ID | grep -ia \"u-boot\" | cut -d' ' -f3"`
    kernel_ver=`ssh $LAVA_WORKER "lavacli -i nxp-imx jobs logs $LAVA_JOB_ID | grep -ia \"Linux version\" | grep -ia \"imx\" | cut -d' ' -f4"`

    # Note down LAVA test end time
    lava_end_time=`date +%s`
    # Calculate test execution time
    lava_test_time=$((lava_end_time-lava_start_time))

    LAVA_TEST_TIME="$(($lava_test_time / 60)) minutes and $(($lava_test_time % 60)) seconds"
    TEST_SUITES=$test_suite_pass_fail_skip

    LAVA_STATUS="Successful"
    # export the variables to jenkins environment
    export_lava_variables


}

# Consolidate the export parameters from different jenkins nodes.
consolidate_node1_to_node3_export()
{
    scp /tmp/part1_email_exports nxp-user3@134.86.62.178:/tmp/part1_email_exports_node1
    ssh nxp-user3@134.86.62.178 "cat /tmp/part1_email_exports_node1 >> /tmp/part1_email_exports"
}


# Consolidate the export parameters from different jenkins nodes.
consolidate_node2_to_node4_export()
{
    scp /tmp/part2_email_exports nxp-user4@134.86.62.167:/tmp/part2_email_exports_node2
    ssh nxp-user4@134.86.62.167 "cat /tmp/part2_email_exports_node2 >> /tmp/part2_email_exports"

    scp /tmp/part2_email_exports nxp-user4@134.86.62.167:/tmp/part2_email_exports_node5
    ssh nxp-user4@134.86.62.167 "cat /tmp/part2_email_exports_node5 >> /tmp/part2_email_exports"
}

reset_export_variables()
{
    #machines='imx6slevk imx6sllevk imx6sxsabresd imx6ulevk imx6ull14x14evk imx6solosabreauto imx6solosabresd'
    distros='wayland xwayland'
    #for MACHINE in $machines
    #do
        for TMP_DISTRO in $distros
        do
            echo "${MACHINE}_${TMP_DISTRO}_EMAIL_SUBJECT = " >> $EMAIL_NODE_EXPORT_FILE
            echo "${MACHINE}_${TMP_DISTRO}_CAUSE = " >> $EMAIL_NODE_EXPORT_FILE
            echo "${MACHINE}_${TMP_DISTRO}_MACHINE =  " >> $EMAIL_NODE_EXPORT_FILE
            echo "${MACHINE}_${TMP_DISTRO}_SRC_CMD = " >> $EMAIL_NODE_EXPORT_FILE
            echo "${MACHINE}_${TMP_DISTRO}_BITBAKE_CMD = " >> $EMAIL_NODE_EXPORT_FILE
            echo "${MACHINE}_${TMP_DISTRO}_build_status = " >> $EMAIL_NODE_EXPORT_FILE
            echo "${MACHINE}_${TMP_DISTRO}_build_time = " >> $EMAIL_NODE_EXPORT_FILE
            echo "${MACHINE}_${TMP_DISTRO}_BUILD_URL = " >> $EMAIL_NODE_EXPORT_FILE
            echo "${MACHINE}_${TMP_DISTRO}_build_type = Scratch" >> $EMAIL_NODE_EXPORT_FILE

            echo "${MACHINE}_${TMP_DISTRO}_vte_build_status = " >> $EMAIL_NODE_EXPORT_FILE
            echo "${MACHINE}_${TMP_DISTRO}_vte_build_time = " >> $EMAIL_NODE_EXPORT_FILE

            echo "${MACHINE}_${TMP_DISTRO}_FTP_SERVER_LOCATION = " >> $EMAIL_NODE_EXPORT_FILE
            echo "${MACHINE}_${TMP_DISTRO}_FTP_SERVER_LOCATION = " >> $EMAIL_NODE_EXPORT_FILE

            echo "${MACHINE}_${TMP_DISTRO}_LAVA_JOB_URL = " >> $EMAIL_NODE_EXPORT_FILE
            echo "${MACHINE}_${TMP_DISTRO}_LAVA_TEST_TIME = " >>  $EMAIL_NODE_EXPORT_FILE
            echo "${MACHINE}_${TMP_DISTRO}_U_BOOT_VER = " >> $EMAIL_NODE_EXPORT_FILE
            echo "${MACHINE}_${TMP_DISTRO}_KERNEL_VER = " >> $EMAIL_NODE_EXPORT_FILE
            echo "${MACHINE}_${TMP_DISTRO}_TEST_SUITES = " >> $EMAIL_NODE_EXPORT_FILE
            echo "${MACHINE}_${TMP_DISTRO}_LAVA_STATUS = " >> $EMAIL_NODE_EXPORT_FILE
        done
    #done
}

reset_local_email_export_variables()
{
    #machines='imx6slevk imx6sllevk imx6sxsabresd imx6ulevk imx6ull14x14evk imx6solosabreauto imx6solosabresd'
    distros='wayland xwayland'
    #for MACHINE in $machines
    #do
        for TMP_DISTRO in $distros
        do
            echo "product_${TMP_DISTRO}_EMAIL_SUBJECT = " >> $EMAIL_LOCAL_EXPORT_FILE
            echo "product_${TMP_DISTRO}_CAUSE = " >> $EMAIL_LOCAL_EXPORT_FILE
            echo "product_${TMP_DISTRO}_MACHINE =  " >> $EMAIL_LOCAL_EXPORT_FILE
            echo "product_${TMP_DISTRO}_SRC_CMD = " >> $EMAIL_LOCAL_EXPORT_FILE
            echo "product_${TMP_DISTRO}_BITBAKE_CMD = " >> $EMAIL_LOCAL_EXPORT_FILE
            echo "product_${TMP_DISTRO}_build_status = " >> $EMAIL_LOCAL_EXPORT_FILE
            echo "product_${TMP_DISTRO}_build_time = " >> $EMAIL_LOCAL_EXPORT_FILE
            echo "product_${TMP_DISTRO}_BUILD_URL = " >> $EMAIL_LOCAL_EXPORT_FILE
            echo "product_${TMP_DISTRO}_build_type = Scratch" >> $EMAIL_LOCAL_EXPORT_FILE

            echo "product_${TMP_DISTRO}_vte_build_status = " >> $EMAIL_LOCAL_EXPORT_FILE
            echo "product_${TMP_DISTRO}_vte_build_time = " >> $EMAIL_LOCAL_EXPORT_FILE

            echo "product_${TMP_DISTRO}_FTP_SERVER_LOCATION = " >> $EMAIL_LOCAL_EXPORT_FILE
            echo "product_${TMP_DISTRO}_FTP_SERVER_LOCATION = " >> $EMAIL_LOCAL_EXPORT_FILE

            echo "product_${TMP_DISTRO}_LAVA_JOB_URL = " >> $EMAIL_LOCAL_EXPORT_FILE
            echo "product_${TMP_DISTRO}_LAVA_TEST_TIME = " >>  $EMAIL_LOCAL_EXPORT_FILE
            echo "product_${TMP_DISTRO}_U_BOOT_VER = " >> $EMAIL_LOCAL_EXPORT_FILE
            echo "product_${TMP_DISTRO}_KERNEL_VER = " >> $EMAIL_LOCAL_EXPORT_FILE
            echo "product_${TMP_DISTRO}_TEST_SUITES = " >> $EMAIL_LOCAL_EXPORT_FILE
            echo "product_${TMP_DISTRO}_LAVA_STATUS = " >> $EMAIL_LOCAL_EXPORT_FILE
        done
    #done
}


# Main function
echo "Called function=$CALLED_FUNCTION, MACHINE=$MACHINE, DISTRO=$DISTRO, BUILD_TYEP=$BUILD_TYPE"
echo "BUILD_DIR=$BUILD_DIR, SRC_CMD=$SRC_CMD"
eval $CALLED_FUNCTION
