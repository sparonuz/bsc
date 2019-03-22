#!/bin/bash
############################################################
# Author : Simona Flavoni for NEMO
# Contact: sflod@locean-ipsl.upmc.fr
# 2013   : A.C. Coward added options for testing with XIOS in dettached mode
#
# sette.sh   : principal script of SET TEsts for NEMO (SETTE)
# ----------------------------------------------------------------------
# NEMO/SETTE , NEMO Consortium (2010)
# Software governed by the CeCILL licence     (NEMOGCM/NEMO_CeCILL.txt)
# ----------------------------------------------------------------------
#
#############################################################
#set -vx
set -o posix
#set -u
#set -e
# ===========
# DESCRIPTION
# ===========
#
# Variables to be checked by user:
#
# COMPILER          : name of compiler as defined in NEMOGCM/ARCH directory 
# BATCH_COMMAND_PAR :  name of the command for submitting parallel batch jobs
# BATCH_COMMAND_SEQ :  name of the command for submitting sequential batch jobs  
# INTERACT_FLAG     : flag to run in interactive mode "yes"
#                           to run in batch mode "no"
# MPIRUN_FLAG       : flag to run in parallel (MPI) "yes"
#                           to run in sequential mode (NB_PROC = 1) "no"
# USING_XIOS        : flag to control the activation of key_iomput
#                      "yes" to compile using key_iomput and link to the external XIOS library
#                      "no"  to compile without key_iomput and link to the old IOIPSL library
# USING_MPMD        : flag to control the use of stand-alone IO servers
#                     requires USING_XIOS="yes"
#                      "yes" to run in MPMD (detached) mode with stand-alone IO servers
#                      "no"  to run in SPMD (attached) mode without separate IO servers 
# NUM_XIOSERVERS    : number of stand-alone IO servers to employ
#                     set to zero if USING_MPMD="no"
#
# Principal script is sette.sh, that calls 
#
#  makenemo  : to create successive exectuables in ${CONFIG_NAME}/BLD/bin/nemo.exe 
#              and links to nemo in ${CONFIG_NAME}/EXP00)
#
#  param.cfg : sets and loads following directories:
#
#   FORCING_DIR         : is the directory for forcing files (tarfile)
#   INPUT_DIR           : is the directory for input files storing 
#   TMPDIR              : is the temporary directory (if needed)
#   NEMO_VALIDATION_DIR : is the validation directory
#
#   (NOTE: this file is the same for all configrations to be tested with sette)
#
#   all_functions.sh : loads functions used by sette (note: new functions can be added here)
#   set_namelist     : function declared in all_functions that sets namelist parameters 
#   post_test_tidyup : creates validation storage directory and copies required output files 
#                      (run.stat and ocean.output) in it after execution of test.
#
#  VALIDATION tree is:
#
#   NEMO_VALIDATION_DIR/WCONFIG_NAME/WCOMPILER_NAME/TEST_NAME/REVISION_NUMBER(or DATE)
#
#  prepare_exe_dir.sh : defines and creates directory where the test is executed
#                       execution directory takes name of TEST_NAME defined for every test 
#                       in sette.sh. (each test in executed in its own directory)
#
#  set_valid_dir       : rename ocean.output/run.stat and tracer.stat to avoid checking them in the report 
#
#  clean_valid_dir    : rename ocean.output/run.stat and tracer.stat to avoid checking them in the report 
#                       ( not doing it could lead to false positive )
#
#  prepare_job.sh     : to generate the script run_job.sh
#
#  fcm_job.sh         : run in batch (INTERACT_FLAG="no") or interactive (INTERACT_FLAG="yes")
#                        see sette.sh and BATCH_TEMPLATE directory
#
#  NOTE: jobs requiring initial or forcing data need to have an input_CONFIG.cfg in which 
#        can be found paths to the input tar file)
#  NOTE: if job is not launched for any reason you have the executable ready in ${EXE_DIR} 
#        directory
#  NOTE: the changed namelists are left in ${EXE_DIR} directory whereas original namelists 
#        remain in ${NEW_CONF}/EXP00
# 
#  NOTE: a log file, output.sette, is created in ${SETTE_DIR} with the echoes of 
#        executed commands
#
#  NOTE: if sette.sh is stopped in output.sette there is written the last command 
#        executed by sette.sh
#
# example use: ./sette.sh 
#########################################################################################
#
# LOAD param value
SETTE_DIR=$(cd $(dirname "$0"); pwd)
#$(dirname $SETTE_DIR)
MAIN_DIR=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/ 
. ./param.cfg

export BATCH_COMMAND_PAR=${BATCH_CMD}
export BATCH_COMMAND_SEQ=${BATCH_CMD}
export INTERACT_FLAG="no"
export MPIRUN_FLAG="yes"
export USING_XIOS="yes"
export USING_ICEBERGS="yes"
#
export DEL_KEYS="key_iomput"
if [ ${USING_XIOS} == "yes" ] 
 then 
   export DEL_KEYS=""
fi
#
export ADD_KEYS=""
if [ ${ADD_NOSIGNEDZERO} == "yes" ]
 then
   export ADD_KEYS="key_nosignedzero"
fi
#
# Settings which control the use of stand alone servers (only relevant if using xios)
#
export USING_MPMD="no"
export NUM_XIOSERVERS=4
export JOB_PREFIX=batch-mpmd
#
if [ ${USING_MPMD} == "no" ] 
 then
   export NUM_XIOSERVERS=0
   export JOB_PREFIX=batch
fi
#
#
if [ ${USING_MPMD} == "yes" ] && [ ${USING_XIOS} == "no" ]
 then
   echo "Incompatible choices. MPMD mode requires the XIOS server"
   exit
fi

# Directory to run the tests
CONFIG_DIR0=${SETTE_DIR}
TOOLS_DIR=${MAIN_DIR}/tools

CMP_NAM=${1:-$COMPILER}
# Copy job_batch_COMPILER file for specific compiler into job_batch_template
cd ${SETTE_DIR}
cp BATCH_TEMPLATE/${JOB_PREFIX}-${COMPILER} job_batch_template || exit
# Description of available configurations:
# GYRE_PISCES       :
# ORCA2_ICE_PISCES  :
# ORCA2_OFF_PISCES  :
# AMM12             :
# SAS               :
# ORCA2_ICE_OBS     :
# AGRIF             : test AGRIF in a double zoom configuration in the nordic seas + 1 zoom in the eq. Pacific (AGRIF_DEMO)
#                       and check that key_agrif without zoom = no key_agrif
# SPITZ12           : regional configuration including sea-ice and tides (Spitzbergen)

for config in ${TEST_CONFIGS}
do

# -----------
# GYRE_PISCES
# -----------
if [ ${config} == "GYRE_PISCES" ] ;  then
## Restartability tests for GYRE_PISCES
    export TEST_NAME="LONG"
    cd ${MAIN_DIR}
    . ./makenemo -m ${CMP_NAM} -n GYRE_PISCES_ST -r GYRE_PISCES -j 8 add_key ${ADD_KEYS} del_key ${DEL_KEYS}
    cd ${SETTE_DIR}
    . ./param.cfg
    . ./all_functions.sh
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=8
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}  
    set_namelist namelist_cfg cn_exp \"GYREPIS_LONG\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 1080
    set_namelist namelist_cfg nn_stock  540
    set_namelist namelist_cfg ln_linssh .true.
    set_namelist namelist_cfg jpni 2
    set_namelist namelist_cfg jpnj 4
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist namelist_cfg sn_cfctl%l_trcstat .true.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_GYRE.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}

    cd ${SETTE_DIR}
    export TEST_NAME="SHORT"
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"GYREPIS_SHORT\"
    set_namelist namelist_cfg nn_it000 541
    set_namelist namelist_cfg nn_itend 1080
    set_namelist namelist_cfg nn_stock 540
    set_namelist namelist_cfg ln_rstart .true.
    set_namelist namelist_cfg nn_rstctl 2
    set_namelist namelist_cfg ln_linssh .true.
    set_namelist namelist_cfg jpni 2
    set_namelist namelist_cfg jpnj 4
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist namelist_cfg sn_cfctl%l_trcstat .true.
    set_namelist namelist_top_cfg ln_rsttr .true.
    set_namelist namelist_top_cfg nn_rsttr 2
    set_namelist namelist_cfg cn_ocerst_in \"GYREPIS_LONG_00000540_restart\"
    set_namelist namelist_top_cfg cn_trcrst_in \"GYREPIS_LONG_00000540_restart_trc\"
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    for (( i=1; i<=$NPROC; i++)) ; do
        L_NPROC=$(( $i - 1 ))
        L_NPROC=`printf "%04d\n" ${L_NPROC}`
        ln -sf ../LONG/GYREPIS_LONG_00000540_restart_${L_NPROC}.nc .
        ln -sf ../LONG/GYREPIS_LONG_00000540_restart_trc_${L_NPROC}.nc .
    done
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_GYRE.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

## Reproducibility tests for GYRE_PISCES
    export TEST_NAME="REPRO_2_4"
    cd ${MAIN_DIR}
    cd ${SETTE_DIR}
    . ./param.cfg
    . ./all_functions.sh
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=8
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"GYREPIS_48\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 1080
    set_namelist namelist_cfg ln_linssh .true.
    set_namelist namelist_cfg jpni 2
    set_namelist namelist_cfg jpnj 4
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist namelist_cfg sn_cfctl%l_trcstat .true.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_GYRE.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

    cd ${SETTE_DIR}
    export TEST_NAME="REPRO_4_2"
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=8
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"GYREPIS_84\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 1080
    set_namelist namelist_cfg ln_linssh .true.
    set_namelist namelist_cfg jpni 4
    set_namelist namelist_cfg jpnj 2
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist namelist_cfg sn_cfctl%l_trcstat .true.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_GYRE.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

fi

# -----------------
# ORCA2_ICE_PISCES
# -----------------
if [ ${config} == "ORCA2_ICE_PISCES" ] ;  then
## Restartability tests for ORCA2_ICE_PISCES
    export TEST_NAME="LONG"
    cd ${MAIN_DIR}
    . ./makenemo -m ${CMP_NAM} -n ORCA2_ICE_PISCES_ST -r ORCA2_ICE_PISCES -j 8 add_key ${ADD_KEYS} del_key ${DEL_KEYS}
    cd ${SETTE_DIR}
    . ./param.cfg
    . ./all_functions.sh
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"O2L3P_LONG\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 992
    set_namelist namelist_cfg nn_stock 496
    set_namelist namelist_cfg jpni 4
    set_namelist namelist_cfg jpnj 8
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist namelist_cfg sn_cfctl%l_trcstat .true.
    set_namelist namelist_cfg ln_use_calving .true.
    set_namelist namelist_cfg ln_wave .true.
    set_namelist namelist_cfg ln_cdgw .true.
    set_namelist namelist_cfg ln_sdw  .true.
    set_namelist namelist_cfg nn_sdrift 1
    set_namelist namelist_cfg ln_stcor .true.
    set_namelist namelist_cfg ln_tauwoc .true.
    #
    if [ ${USING_ICEBERGS} == "no" ] ; then set_namelist namelist_cfg ln_icebergs .false. ; fi
    # for debugging purposes set_namelist namelist_cfg rn_test_box -180.0, 180.0, -90.0, -55.0
    #
    set_namelist namelist_ice_cfg ln_icediachk .true.
    set_namelist namelist_top_cfg ln_trcdta .false.
    # put ln_ironsed, ln_river, ln_ndepo, ln_dust to false
    # if not you need input files, and for tests is not necessary
    set_namelist namelist_pisces_cfg ln_presatm .false.
    set_namelist namelist_pisces_cfg ln_varpar .false.
    set_namelist namelist_pisces_cfg ln_dust .false.
    set_namelist namelist_pisces_cfg ln_solub .false.
    set_namelist namelist_pisces_cfg ln_river .false.
    set_namelist namelist_pisces_cfg ln_ndepo .false.
    set_namelist namelist_pisces_cfg ln_ironsed .false.
    set_namelist namelist_pisces_cfg ln_ironice .false.
    set_namelist namelist_pisces_cfg ln_hydrofe .false.
    # put ln_pisdmp to false : no restoring to global mean value
    set_namelist namelist_pisces_cfg ln_pisdmp .false.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_ORCA2_ICE_PISCES.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    
    cd ${SETTE_DIR}
    export TEST_NAME="SHORT"
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"O2L3P_SHORT\"
    set_namelist namelist_cfg nn_it000 497
    set_namelist namelist_cfg nn_itend 992
    set_namelist namelist_cfg nn_stock 496
    set_namelist namelist_cfg ln_rstart .true.
    set_namelist namelist_cfg nn_rstctl 2
    set_namelist namelist_cfg jpni 4
    set_namelist namelist_cfg jpnj 8
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist namelist_cfg sn_cfctl%l_trcstat .true.
    set_namelist namelist_cfg nn_test_icebergs -1
    set_namelist namelist_cfg ln_wave .true.
    set_namelist namelist_cfg ln_cdgw .true.
    set_namelist namelist_cfg ln_sdw  .true.
    set_namelist namelist_cfg nn_sdrift 1
    set_namelist namelist_cfg ln_stcor .true.
    set_namelist namelist_cfg ln_tauwoc .true.
    #
    if [ ${USING_ICEBERGS} == "no" ] ; then set_namelist namelist_cfg ln_icebergs .false. ; fi
    # for debugging purposes set_namelist namelist_cfg rn_test_box -180.0, 180.0, -90.0, -55.0
    #
    set_namelist namelist_ice_cfg ln_icediachk .true.
    set_namelist namelist_top_cfg ln_rsttr .true.
    set_namelist namelist_top_cfg nn_rsttr 2
    set_namelist namelist_cfg cn_ocerst_in \"O2L3P_LONG_00000496_restart\"
    set_namelist namelist_top_cfg cn_trcrst_in \"O2L3P_LONG_00000496_restart_trc\"
    set_namelist namelist_ice_cfg cn_icerst_in \"O2L3P_LONG_00000496_restart_ice\"
    set_namelist namelist_top_cfg ln_trcdta .false.
    # put ln_ironsed, ln_river, ln_ndepo, ln_dust
    # if not you need input files, and for tests is not necessary
    set_namelist namelist_pisces_cfg ln_presatm .false.
    set_namelist namelist_pisces_cfg ln_varpar .false.
    set_namelist namelist_pisces_cfg ln_dust .false.
    set_namelist namelist_pisces_cfg ln_solub .false.
    set_namelist namelist_pisces_cfg ln_river .false.
    set_namelist namelist_pisces_cfg ln_ndepo .false.
    set_namelist namelist_pisces_cfg ln_ironsed .false.
    set_namelist namelist_pisces_cfg ln_ironice .false.
    set_namelist namelist_pisces_cfg ln_hydrofe .false.
    # put ln_pisdmp to false : no restoring to global mean value
    set_namelist namelist_pisces_cfg ln_pisdmp .false.
    for (( i=1; i<=$NPROC; i++)) ; do
        L_NPROC=$(( $i - 1 ))
        L_NPROC=`printf "%04d\n" ${L_NPROC}`
        ln -sf ../LONG/O2L3P_LONG_00000496_restart_${L_NPROC}.nc .
        ln -sf ../LONG/O2L3P_LONG_00000496_restart_trc_${L_NPROC}.nc .
        ln -sf ../LONG/O2L3P_LONG_00000496_restart_ice_${L_NPROC}.nc .
        if [ ${USING_ICEBERGS} == "yes" ]
            then
             ln -sf ../LONG/O2L3P_LONG_icebergs_00000496_restart_${L_NPROC}.nc O2L3P_LONG_00000496_restart_icebergs_${L_NPROC}.nc
        fi
    done
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_ORCA2_ICE_PISCES.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

## Reproducibility tests for ORCA2_ICE_PISCES
    export TEST_NAME="REPRO_4_8"
    cd ${MAIN_DIR}
    cd ${SETTE_DIR}
    . ./param.cfg
    . ./all_functions.sh
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"O2L3P_48\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 992
    set_namelist namelist_cfg jpni 4
    set_namelist namelist_cfg jpnj 8
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist namelist_cfg sn_cfctl%l_trcstat .true.
    set_namelist namelist_cfg ln_wave .true.
    set_namelist namelist_cfg ln_cdgw .true.
    set_namelist namelist_cfg ln_sdw  .true.
    set_namelist namelist_cfg nn_sdrift 1
    set_namelist namelist_cfg ln_stcor .true.
    set_namelist namelist_cfg ln_tauwoc .true.

    if [ ${USING_ICEBERGS} == "no" ] ; then set_namelist namelist_cfg ln_icebergs .false. ; fi
    # for debugging purposes set_namelist namelist_cfg rn_test_box -180.0, 180.0, -90.0, -55.0

    set_namelist namelist_top_cfg ln_trcdta .false.
    # put ln_ironsed, ln_river, ln_ndepo, ln_dust to false
    # if not you need input files, and for tests is not necessary
    set_namelist namelist_pisces_cfg ln_presatm .false.
    set_namelist namelist_pisces_cfg ln_varpar .false.
    set_namelist namelist_pisces_cfg ln_dust .false.
    set_namelist namelist_pisces_cfg ln_solub .false.
    set_namelist namelist_pisces_cfg ln_river .false.
    set_namelist namelist_pisces_cfg ln_ndepo .false.
    set_namelist namelist_pisces_cfg ln_ironsed .false.
    set_namelist namelist_pisces_cfg ln_ironice .false.
    set_namelist namelist_pisces_cfg ln_hydrofe .false.
    # put ln_pisdmp to false : no restoring to global mean value
    set_namelist namelist_pisces_cfg ln_pisdmp .false.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_ORCA2_ICE_PISCES.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

    cd ${SETTE_DIR}
    export TEST_NAME="REPRO_8_4"
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"O2L3P_84\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 992
    set_namelist namelist_cfg jpni 8
    set_namelist namelist_cfg jpnj 4
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist namelist_cfg sn_cfctl%l_trcstat .true.
    set_namelist namelist_cfg ln_wave .true.
    set_namelist namelist_cfg ln_cdgw .true.
    set_namelist namelist_cfg ln_sdw  .true.
    set_namelist namelist_cfg nn_sdrift 1
    set_namelist namelist_cfg ln_stcor .true.
    set_namelist namelist_cfg ln_tauwoc .true.

    if [ ${USING_ICEBERGS} == "no" ] ; then set_namelist namelist_cfg ln_icebergs .false. ; fi
    # for debugging purposes set_namelist namelist_cfg rn_test_box -180.0, 180.0, -90.0, -55.0

    set_namelist namelist_top_cfg ln_trcdta .false.
    # put ln_ironsed, ln_river, ln_ndepo, ln_dust to false
    # if not you need input files, and for tests is not necessary
    set_namelist namelist_pisces_cfg ln_presatm .false.
    set_namelist namelist_pisces_cfg ln_varpar .false.
    set_namelist namelist_pisces_cfg ln_dust .false.
    set_namelist namelist_pisces_cfg ln_solub .false.
    set_namelist namelist_pisces_cfg ln_river .false.
    set_namelist namelist_pisces_cfg ln_ndepo .false.
    set_namelist namelist_pisces_cfg ln_ironsed .false.
    set_namelist namelist_pisces_cfg ln_ironice .false.
    set_namelist namelist_pisces_cfg ln_hydrofe .false.
    # put ln_pisdmp to false : no restoring to global mean value
    set_namelist namelist_pisces_cfg ln_pisdmp .false.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_ORCA2_ICE_PISCES.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}
fi

# ----------------
# ORCA2_OFF_PISCES
# ----------------
if [ ${config} == "ORCA2_OFF_PISCES" ] ;  then
## Restartability tests for ORCA2_OFF_PISCES
    export TEST_NAME="LONG"
    cd ${MAIN_DIR}
    . ./makenemo -m ${CMP_NAM} -n ORCA2_OFF_PISCES_ST -r ORCA2_OFF_PISCES -j 8 add_key ${ADD_KEYS} del_key ${DEL_KEYS}
    cd ${SETTE_DIR}
    . ./param.cfg
    . ./all_functions.sh
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"OFFP_LONG\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 380
    set_namelist namelist_cfg nn_stock 190
    set_namelist namelist_cfg jpni 4
    set_namelist namelist_cfg jpnj 8
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist namelist_cfg sn_cfctl%l_trcstat .true.
    set_namelist namelist_cfg ln_qsr_rgb .true.
    set_namelist namelist_top_cfg ln_trcdta .false.
    # put ln_ironsed, ln_river, ln_ndepo, ln_dust to false
    # if not you need input files, and for tests is not necessary
    set_namelist namelist_pisces_cfg ln_presatm .false.
    set_namelist namelist_pisces_cfg ln_varpar .false.
    set_namelist namelist_pisces_cfg ln_dust .false.
    set_namelist namelist_pisces_cfg ln_solub .false.
    set_namelist namelist_pisces_cfg ln_river .false.
    set_namelist namelist_pisces_cfg ln_ndepo .false.
    set_namelist namelist_pisces_cfg ln_ironsed .false.
    set_namelist namelist_pisces_cfg ln_ironice .false.
    set_namelist namelist_pisces_cfg ln_hydrofe .false.
    # put ln_pisdmp to false : no restoring to global mean value
    set_namelist namelist_pisces_cfg ln_pisdmp .false.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_ORCA2_OFF_PISCES.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    
    cd ${SETTE_DIR}
    export TEST_NAME="SHORT"
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"OFFP_SHORT\"
    set_namelist namelist_cfg nn_it000 191
    set_namelist namelist_cfg nn_itend 380
    set_namelist namelist_cfg nn_stock 190
    set_namelist namelist_cfg jpni 4
    set_namelist namelist_cfg jpnj 8
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist namelist_cfg sn_cfctl%l_trcstat .true.
    set_namelist namelist_cfg ln_qsr_rgb .true.
    set_namelist namelist_top_cfg ln_rsttr .true.
    set_namelist namelist_top_cfg nn_rsttr 2
    set_namelist namelist_top_cfg cn_trcrst_in \"OFFP_LONG_00000190_restart_trc\"
    for (( i=1; i<=$NPROC; i++)) ; do
        L_NPROC=$(( $i - 1 ))
        L_NPROC=`printf "%04d\n" ${L_NPROC}`
        ln -sf ../LONG/OFFP_LONG_00000190_restart_trc_${L_NPROC}.nc .
    done
    # put ln_ironsed, ln_river, ln_ndepo, ln_dust
    # if not you need input files, and for tests is not necessary
    set_namelist namelist_pisces_cfg ln_presatm .false.
    set_namelist namelist_pisces_cfg ln_varpar .false.
    set_namelist namelist_pisces_cfg ln_dust .false.
    set_namelist namelist_pisces_cfg ln_solub .false.
    set_namelist namelist_pisces_cfg ln_river .false.
    set_namelist namelist_pisces_cfg ln_ndepo .false.
    set_namelist namelist_pisces_cfg ln_ironsed .false.
    set_namelist namelist_pisces_cfg ln_ironice .false.
    set_namelist namelist_pisces_cfg ln_hydrofe .false.
    # put ln_pisdmp to false : no restoring to global mean value
    set_namelist namelist_pisces_cfg ln_pisdmp .false.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_ORCA2_OFF_PISCES.cfg $NPROC ${TEST_NAME}  ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC  ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

## Reproducibility tests for ORCA2_OFF_PISCES
    export TEST_NAME="REPRO_4_8"
    cd ${MAIN_DIR}
    cd ${SETTE_DIR}
    . ./param.cfg
    . ./all_functions.sh
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"OFFP_48\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 380
    set_namelist namelist_cfg jpni 4
    set_namelist namelist_cfg jpnj 8
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist namelist_cfg sn_cfctl%l_trcstat .true.
    set_namelist namelist_cfg ln_qsr_rgb .true.
    set_namelist namelist_top_cfg ln_trcdta .false.
    # put ln_ironsed, ln_river, ln_ndepo, ln_dust to false
    # if not you need input files, and for tests is not necessary
    set_namelist namelist_pisces_cfg ln_presatm .false.
    set_namelist namelist_pisces_cfg ln_varpar .false.
    set_namelist namelist_pisces_cfg ln_dust .false.
    set_namelist namelist_pisces_cfg ln_solub .false.
    set_namelist namelist_pisces_cfg ln_river .false.
    set_namelist namelist_pisces_cfg ln_ndepo .false.
    set_namelist namelist_pisces_cfg ln_ironsed .false.
    set_namelist namelist_pisces_cfg ln_ironice .false.
    set_namelist namelist_pisces_cfg ln_hydrofe .false.
    # put ln_pisdmp to false : no restoring to global mean value
    set_namelist namelist_pisces_cfg ln_pisdmp .false.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_ORCA2_OFF_PISCES.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

    cd ${SETTE_DIR}
    export TEST_NAME="REPRO_8_4"
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"OFFP_84\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 380
    set_namelist namelist_cfg jpni 8
    set_namelist namelist_cfg jpnj 4
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist namelist_cfg sn_cfctl%l_trcstat .true.
    set_namelist namelist_cfg ln_qsr_rgb .true.
    set_namelist namelist_top_cfg ln_trcdta .false.
    # put ln_ironsed, ln_river, ln_ndepo, ln_dust to false
    # if not you need input files, and for tests is not necessary
    set_namelist namelist_pisces_cfg ln_presatm .false.
    set_namelist namelist_pisces_cfg ln_varpar .false.
    set_namelist namelist_pisces_cfg ln_dust .false.
    set_namelist namelist_pisces_cfg ln_solub .false.
    set_namelist namelist_pisces_cfg ln_river .false.
    set_namelist namelist_pisces_cfg ln_ndepo .false.
    set_namelist namelist_pisces_cfg ln_ironsed .false.
    set_namelist namelist_pisces_cfg ln_ironice .false.
    set_namelist namelist_pisces_cfg ln_hydrofe .false.
    # put ln_pisdmp to false : no restoring to global mean value
    set_namelist namelist_pisces_cfg ln_pisdmp .false. 
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_ORCA2_OFF_PISCES.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC  ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}
fi

# -----
# AMM12
# -----
if [ ${config} == "AMM12" ] ;  then
    ## Restartability tests for AMM12
    export TEST_NAME="LONG"
    cd ${MAIN_DIR}
    . ./makenemo -m ${CMP_NAM} -n AMM12_ST -r AMM12 -j 8 add_key ${ADD_KEYS} del_key ${DEL_KEYS}
    cd ${SETTE_DIR}
    . ./param.cfg
    . ./all_functions.sh
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"AMM12_LONG\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 576
    set_namelist namelist_cfg nn_stock 288
    set_namelist namelist_cfg jpni 4
    set_namelist namelist_cfg jpnj 8
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_AMM12.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}

    cd ${SETTE_DIR}
    export TEST_NAME="SHORT"
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"AMM12_SHORT\"
    set_namelist namelist_cfg nn_it000 289
    set_namelist namelist_cfg nn_itend 576
    set_namelist namelist_cfg jpni 4
    set_namelist namelist_cfg jpnj 8
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist namelist_cfg ln_rstart .true.
    set_namelist namelist_cfg nn_rstctl 2
    set_namelist namelist_cfg cn_ocerst_in \"AMM12_LONG_00000288_restart\"
    set_namelist namelist_cfg nn_date0 20120102
    for (( i=1; i<=$NPROC; i++)) ; do
        L_NPROC=$(( $i - 1 ))
        L_NPROC=`printf "%04d\n" ${L_NPROC}`
        ln -sf ../LONG/AMM12_LONG_00000288_restart_${L_NPROC}.nc .
    done
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_AMM12.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

## Reproducibility tests for AMM12
    export TEST_NAME="REPRO_8_4"
    cd ${MAIN_DIR}
    cd ${SETTE_DIR}
    . ./param.cfg
    . ./all_functions.sh
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"AMM12_84\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 576
    set_namelist namelist_cfg jpni 8
    set_namelist namelist_cfg jpnj 4
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_AMM12.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

    cd ${SETTE_DIR}
    export TEST_NAME="REPRO_4_8"
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"AMM12_48\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 576
    set_namelist namelist_cfg jpni 4
    set_namelist namelist_cfg jpnj 8
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_AMM12.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}
fi


# ---------
# ORCA2_SAS
# ---------
if [ ${config} == "SAS" ] ;  then
## Restartability tests
    export TEST_NAME="LONG"
    cd ${MAIN_DIR}
    . ./makenemo -m ${CMP_NAM} -n ORCA2_SAS_ICE_ST -r ORCA2_SAS_ICE -j 8 add_key ${ADD_KEYS} del_key ${DEL_KEYS}
    cd ${SETTE_DIR}
    . ./param.cfg
    . ./all_functions.sh
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"SAS\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 256
    set_namelist namelist_cfg nn_stock 128
    set_namelist namelist_cfg jpni 4
    set_namelist namelist_cfg jpnj 8
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist namelist_ice_cfg ln_icediachk .true.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_SAS.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}

    cd ${SETTE_DIR}
    export TEST_NAME="SHORT"
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"SAS\"
    set_namelist namelist_cfg nn_it000 129
    set_namelist namelist_cfg nn_itend 256
    set_namelist namelist_cfg jpni 4
    set_namelist namelist_cfg jpnj 8
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist namelist_cfg ln_rstart .true.
    set_namelist namelist_cfg nn_rstctl 2
    set_namelist namelist_cfg nn_date0 010109
    set_namelist namelist_cfg cn_ocerst_in \"SAS_00000128_restart\"
    set_namelist namelist_ice_cfg cn_icerst_in \"SAS_00000128_restart_ice\"
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    for (( i=1; i<=$NPROC; i++)) ; do
        L_NPROC=$(( $i - 1 ))
        L_NPROC=`printf "%04d\n" ${L_NPROC}`
        ln -sf ../LONG/SAS_00000128_restart_${L_NPROC}.nc .
        ln -sf ../LONG/SAS_00000128_restart_ice_${L_NPROC}.nc .
    done
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_SAS.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

## Reproducibility tests
    export TEST_NAME="REPRO_4_8"
    cd ${MAIN_DIR}
    cd ${SETTE_DIR}
    . ./param.cfg
    . ./all_functions.sh
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"SAS_48\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 80
    set_namelist namelist_cfg jpni 4
    set_namelist namelist_cfg jpnj 8
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_SAS.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

    cd ${SETTE_DIR}
    export TEST_NAME="REPRO_8_4"
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"SAS_84\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 80
    set_namelist namelist_cfg jpni 8
    set_namelist namelist_cfg jpnj 4
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_SAS.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

fi


# --------------
# ORCA2_ICE_OBS
# --------------
## Test assimilation interface code, OBS and ASM for reproducibility
## Restartability not tested (ASM code not restartable while increments are being applied)
if [ ${config} == "ORCA2_ICE_OBS" ] ; then
## Reproducibility tests
    export TEST_NAME="REPRO_4_8"
    cd ${MAIN_DIR}
    . ./makenemo -m ${CMP_NAM} -n ORCA2_ICE_OBS_ST -r ORCA2_ICE_PISCES -d "OCE ICE"  -j 8 add_key "key_asminc ${ADD_KEYS}" del_key "key_top"
    cd ${SETTE_DIR}
    . ./param.cfg
    . ./all_functions.sh
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"O2L3OBS_48\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 80
    set_namelist namelist_cfg ln_read_cfg .true.
    set_namelist namelist_cfg jpni 4
    set_namelist namelist_cfg jpnj 8
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist namelist_cfg sn_cfctl%l_trcstat .true.
    set_namelist namelist_cfg ln_diaobs .true.
    set_namelist namelist_cfg ln_t3d .true.
    set_namelist namelist_cfg ln_s3d .true.
    set_namelist namelist_cfg ln_sst .true.
    set_namelist namelist_cfg ln_sla .true.
    set_namelist namelist_cfg ln_sic .true.
    set_namelist namelist_cfg ln_vel3d .true.
    set_namelist namelist_cfg ln_bkgwri .true.
    set_namelist namelist_cfg ln_trainc .true.
    set_namelist namelist_cfg ln_dyninc .true.
    set_namelist namelist_cfg ln_sshinc .true.
    set_namelist namelist_cfg ln_asmiau .true.
    #remove all useless options for pisces (due to ORCA2_ICE_PISCES reference configuration)
    set_namelist namelist_top_cfg ln_trcdta .false. 
    # put ln_ironsed, ln_river, ln_ndepo, ln_dust to false
    # if not you need input files, and for tests is not necessary
    set_namelist namelist_pisces_cfg ln_presatm .false.
    set_namelist namelist_pisces_cfg ln_varpar .false.
    set_namelist namelist_pisces_cfg ln_dust .false.
    set_namelist namelist_pisces_cfg ln_solub .false.
    set_namelist namelist_pisces_cfg ln_river .false.
    set_namelist namelist_pisces_cfg ln_ndepo .false.
    set_namelist namelist_pisces_cfg ln_ironsed .false.
    set_namelist namelist_pisces_cfg ln_ironice .false.
    set_namelist namelist_pisces_cfg ln_hydrofe .false.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_ORCA2_ICE_OBS.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

   cd ${SETTE_DIR}
    export TEST_NAME="REPRO_8_4"
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"O2L3OBS_84\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 80
    set_namelist namelist_cfg ln_read_cfg .true.
    set_namelist namelist_cfg jpni 8
    set_namelist namelist_cfg jpnj 4
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist namelist_cfg sn_cfctl%l_trcstat .true.
    set_namelist namelist_cfg ln_diaobs .true.
    set_namelist namelist_cfg ln_t3d .true.
    set_namelist namelist_cfg ln_s3d .true.
    set_namelist namelist_cfg ln_sst .true.
    set_namelist namelist_cfg ln_sla .true.
    set_namelist namelist_cfg ln_sic .true.
    set_namelist namelist_cfg ln_vel3d .true.
    set_namelist namelist_cfg ln_bkgwri .true.
    set_namelist namelist_cfg ln_trainc .true.
    set_namelist namelist_cfg ln_dyninc .true.
    set_namelist namelist_cfg ln_sshinc .true.
    set_namelist namelist_cfg ln_asmiau .true.
    #remove all useless options for pisces (due to ORCA2_ICE_PISCES reference configuration)
    set_namelist namelist_top_cfg ln_trcdta .false.
    # put ln_ironsed, ln_river, ln_ndepo, ln_dust to false
    # if not you need input files, and for tests is not necessary
    set_namelist namelist_pisces_cfg ln_presatm .false.
    set_namelist namelist_pisces_cfg ln_varpar .false.
    set_namelist namelist_pisces_cfg ln_dust .false.
    set_namelist namelist_pisces_cfg ln_solub .false.
    set_namelist namelist_pisces_cfg ln_river .false.
    set_namelist namelist_pisces_cfg ln_ndepo .false.
    set_namelist namelist_pisces_cfg ln_ironsed .false.
    set_namelist namelist_pisces_cfg ln_ironice .false.
    set_namelist namelist_pisces_cfg ln_hydrofe .false.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_ORCA2_ICE_OBS.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}
fi

# ------------
# AGRIF ICE
# -----------
if [ ${config} == "AGRIF" ] ;  then
## Restartability tests
    export TEST_NAME="LONG"
    cd ${MAIN_DIR}
    . ./makenemo -m ${CMP_NAM} -n AGRIF_DEMO_ST -r AGRIF_DEMO -j 8 add_key ${ADD_KEYS} del_key ${DEL_KEYS}
    cd ${SETTE_DIR}
    . ./param.cfg
    . ./all_functions.sh
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=16
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"AGRIF_LONG\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 20
    set_namelist namelist_cfg nn_stock 10
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist 1_namelist_cfg cn_exp \"AGRIF_LONG\"
    set_namelist 1_namelist_cfg nn_it000 1
    set_namelist 1_namelist_cfg nn_itend 20
    set_namelist 1_namelist_cfg nn_stock 10
    set_namelist 1_namelist_cfg ln_ctl .false.
    set_namelist 1_namelist_cfg sn_cfctl%l_config .true.
    set_namelist 1_namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist 2_namelist_cfg cn_exp \"AGRIF_LONG\"
    set_namelist 2_namelist_cfg nn_it000 1
    set_namelist 2_namelist_cfg nn_itend 80
    set_namelist 2_namelist_cfg nn_stock 40
    set_namelist 2_namelist_cfg ln_ctl .false.
    set_namelist 2_namelist_cfg sn_cfctl%l_config .true.
    set_namelist 2_namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist 3_namelist_cfg cn_exp \"AGRIF_LONG\"
    set_namelist 3_namelist_cfg nn_it000 1
    set_namelist 3_namelist_cfg nn_itend 240
    set_namelist 3_namelist_cfg nn_stock 120
    set_namelist 3_namelist_cfg ln_ctl .false.
    set_namelist 3_namelist_cfg sn_cfctl%l_config .true.
    set_namelist 3_namelist_cfg sn_cfctl%l_runstat .true.

    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_AGRIF.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    
    cd ${SETTE_DIR}
    export TEST_NAME="SHORT"
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"AGRIF_SHORT\"
    set_namelist namelist_cfg nn_it000 11
    set_namelist namelist_cfg nn_itend 20
    set_namelist namelist_cfg nn_stock 10
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist namelist_cfg ln_rstart .true.
    set_namelist namelist_cfg nn_rstctl 2
    set_namelist 1_namelist_cfg cn_exp \"AGRIF_SHORT\"
    set_namelist 1_namelist_cfg nn_it000 11
    set_namelist 1_namelist_cfg nn_itend 20
    set_namelist 1_namelist_cfg nn_stock 10
    set_namelist 1_namelist_cfg ln_ctl .false.
    set_namelist 1_namelist_cfg sn_cfctl%l_config .true.
    set_namelist 1_namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist 1_namelist_cfg ln_rstart .true.
    set_namelist 1_namelist_cfg nn_rstctl 2
    set_namelist 2_namelist_cfg cn_exp \"AGRIF_SHORT\"
    set_namelist 2_namelist_cfg nn_it000 41
    set_namelist 2_namelist_cfg nn_itend 80
    set_namelist 2_namelist_cfg nn_stock 40
    set_namelist 2_namelist_cfg ln_ctl .false.
    set_namelist 2_namelist_cfg sn_cfctl%l_config .true.
    set_namelist 2_namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist 2_namelist_cfg ln_rstart .true.
    set_namelist 2_namelist_cfg nn_rstctl 2
    set_namelist 3_namelist_cfg cn_exp \"AGRIF_SHORT\"
    set_namelist 3_namelist_cfg nn_it000 121
    set_namelist 3_namelist_cfg nn_itend 240
    set_namelist 3_namelist_cfg nn_stock 120
    set_namelist 3_namelist_cfg ln_ctl .false.
    set_namelist 3_namelist_cfg sn_cfctl%l_config .true.
    set_namelist 3_namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist 3_namelist_cfg ln_rstart .true.
    set_namelist 3_namelist_cfg nn_rstctl 2
    set_namelist namelist_cfg cn_ocerst_in \"AGRIF_LONG_00000010_restart\"
    set_namelist namelist_ice_cfg cn_icerst_in \"AGRIF_LONG_00000010_restart_ice\"
    set_namelist 1_namelist_cfg cn_ocerst_in \"AGRIF_LONG_00000010_restart\"
    set_namelist 1_namelist_ice_cfg cn_icerst_in \"AGRIF_LONG_00000010_restart_ice\"
    set_namelist 2_namelist_cfg cn_ocerst_in \"AGRIF_LONG_00000040_restart\"
    set_namelist 2_namelist_ice_cfg cn_icerst_in \"AGRIF_LONG_00000040_restart_ice\"
    set_namelist 3_namelist_cfg cn_ocerst_in \"AGRIF_LONG_00000120_restart\"
    set_namelist 3_namelist_ice_cfg cn_icerst_in \"AGRIF_LONG_00000120_restart_ice\"

    for (( i=1; i<=$NPROC; i++)) ; do
        L_NPROC=$(( $i - 1 ))
        L_NPROC=`printf "%04d\n" ${L_NPROC}`
        ln -sf ../LONG/AGRIF_LONG_00000010_restart_${L_NPROC}.nc .
        ln -sf ../LONG/AGRIF_LONG_00000010_restart_ice_${L_NPROC}.nc .
        ln -sf ../LONG/1_AGRIF_LONG_00000010_restart_${L_NPROC}.nc .
        ln -sf ../LONG/1_AGRIF_LONG_00000010_restart_ice_${L_NPROC}.nc .
        ln -sf ../LONG/2_AGRIF_LONG_00000040_restart_${L_NPROC}.nc .
        ln -sf ../LONG/2_AGRIF_LONG_00000040_restart_ice_${L_NPROC}.nc .
        ln -sf ../LONG/3_AGRIF_LONG_00000120_restart_${L_NPROC}.nc .
        ln -sf ../LONG/3_AGRIF_LONG_00000120_restart_ice_${L_NPROC}.nc .
    done
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_AGRIF.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

## Reproducibility tests
    export TEST_NAME="REPRO_4_8"
    cd ${MAIN_DIR}
    cd ${SETTE_DIR}
    . ./param.cfg
    . ./all_functions.sh
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"AGRIF_48\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 20
    set_namelist namelist_cfg jpni 4
    set_namelist namelist_cfg jpnj 8
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist 1_namelist_cfg cn_exp \"AGRIF_48\"
    set_namelist 1_namelist_cfg nn_it000 1
    set_namelist 1_namelist_cfg nn_itend 20
    set_namelist 1_namelist_cfg jpni 4
    set_namelist 1_namelist_cfg jpnj 8
    set_namelist 1_namelist_cfg ln_ctl .false.
    set_namelist 1_namelist_cfg sn_cfctl%l_config .true.
    set_namelist 1_namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist 2_namelist_cfg cn_exp \"AGRIF_48\"
    set_namelist 2_namelist_cfg nn_it000 1
    set_namelist 2_namelist_cfg nn_itend 80
    set_namelist 2_namelist_cfg jpni 4
    set_namelist 2_namelist_cfg jpnj 8
    set_namelist 2_namelist_cfg ln_ctl .false.
    set_namelist 2_namelist_cfg sn_cfctl%l_config .true.
    set_namelist 2_namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist 3_namelist_cfg cn_exp \"AGRIF_48\"
    set_namelist 3_namelist_cfg nn_it000 1
    set_namelist 3_namelist_cfg nn_itend 240
    set_namelist 3_namelist_cfg jpni 4
    set_namelist 3_namelist_cfg jpnj 8
    set_namelist 3_namelist_cfg ln_ctl .false.
    set_namelist 3_namelist_cfg sn_cfctl%l_config .true.
    set_namelist 3_namelist_cfg sn_cfctl%l_runstat .true.

    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_AGRIF.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

    cd ${SETTE_DIR}
    export TEST_NAME="REPRO_8_4"
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"AGRIF_84\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 20
    set_namelist namelist_cfg jpni 8
    set_namelist namelist_cfg jpnj 4
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist 1_namelist_cfg cn_exp \"AGRIF_84\"
    set_namelist 1_namelist_cfg nn_it000 1
    set_namelist 1_namelist_cfg nn_itend 20
    set_namelist 1_namelist_cfg jpni 8
    set_namelist 1_namelist_cfg jpnj 4
    set_namelist 1_namelist_cfg ln_ctl .false.
    set_namelist 1_namelist_cfg sn_cfctl%l_config .true.
    set_namelist 1_namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist 2_namelist_cfg cn_exp \"AGRIF_84\"
    set_namelist 2_namelist_cfg nn_it000 1
    set_namelist 2_namelist_cfg nn_itend 80
    set_namelist 2_namelist_cfg jpni 8
    set_namelist 2_namelist_cfg jpnj 4
    set_namelist 2_namelist_cfg ln_ctl .false.
    set_namelist 2_namelist_cfg sn_cfctl%l_config .true.
    set_namelist 2_namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist 3_namelist_cfg cn_exp \"AGRIF_84\"
    set_namelist 3_namelist_cfg nn_it000 1
    set_namelist 3_namelist_cfg nn_itend 240
    set_namelist 3_namelist_cfg jpni 8
    set_namelist 3_namelist_cfg jpnj 4
    set_namelist 3_namelist_cfg ln_ctl .false.
    set_namelist 3_namelist_cfg sn_cfctl%l_config .true.
    set_namelist 3_namelist_cfg sn_cfctl%l_runstat .true.

    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_AGRIF.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

## test code corruption with AGRIF (phase 1) ==> Compile with key_agrif but run with no zoom
    export TEST_NAME="ORCA2"
    cd ${MAIN_DIR}
    cd ${SETTE_DIR}
    . ./param.cfg
    . ./all_functions.sh
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"ORCA2\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 150
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.

#   Set the number of fine grids to zero:    
    sed -i "1s/.*/0/" ${EXE_DIR}/AGRIF_FixedGrids.in

    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_AGRIF.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

fi


## test code corruption with AGRIF (phase 2) ==> Compile without key_agrif (to be compared with AGRIF_DEMO_ST/ORCA2)
if [ ${config} == "AGRIF" ] ;  then
    export TEST_NAME="ORCA2"
    cd ${MAIN_DIR}
    . ./makenemo -m ${CMP_NAM} -n AGRIF_DEMO_NOAGRIF_ST -r AGRIF_DEMO -j 8 add_key ${ADD_KEYS} del_key "key_agrif"
    cd ${SETTE_DIR}
    . ./param.cfg
    . ./all_functions.sh
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"ORCA2\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 150
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
#
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_AGRIF.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

fi

# -------
# SPITZ12
# -------
if [ ${config} == "SPITZ12" ] ;  then
## Restartability tests
    export TEST_NAME="LONG"
    cd ${MAIN_DIR}
    . ./makenemo -m ${CMP_NAM} -n SPITZ12_ST -r SPITZ12 -j 8 add_key ${ADD_KEYS} del_key ${DEL_KEYS}
    cd ${SETTE_DIR}
    . ./param.cfg
    . ./all_functions.sh
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"S12_LONG\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 240
    set_namelist namelist_cfg nn_stock 120
    set_namelist namelist_cfg nn_date0 20020101
    set_namelist namelist_cfg jpni 4
    set_namelist namelist_cfg jpnj 8
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    #set_namelist namelist_ice_cfg ln_icediachk .true.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_SPITZ12.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    
    cd ${SETTE_DIR}
    export TEST_NAME="SHORT"
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"S12_SHORT\"
    set_namelist namelist_cfg nn_it000 121
    set_namelist namelist_cfg nn_itend 240
    set_namelist namelist_cfg nn_stock 120
    set_namelist namelist_cfg ln_rstart .true.
    set_namelist namelist_cfg nn_rstctl 2
    set_namelist namelist_cfg jpni 4
    set_namelist namelist_cfg jpnj 8
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist namelist_cfg cn_ocerst_in \"S12_LONG_00000120_restart\"
    set_namelist namelist_ice_cfg cn_icerst_in \"S12_LONG_00000120_restart_ice\"
    for (( i=1; i<=$NPROC; i++)) ; do
        L_NPROC=$(( $i - 1 ))
        L_NPROC=`printf "%04d\n" ${L_NPROC}`
        ln -sf ../LONG/S12_LONG_00000120_restart_${L_NPROC}.nc .
        ln -sf ../LONG/S12_LONG_00000120_restart_ice_${L_NPROC}.nc .
    done
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_SPITZ12.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

## Reproducibility tests
    export TEST_NAME="REPRO_4_8"
    cd ${MAIN_DIR}
    cd ${SETTE_DIR}
    . ./param.cfg
    . ./all_functions.sh
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"S12_48\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 120
    set_namelist namelist_cfg nn_date0 20020101
    set_namelist namelist_cfg jpni 4
    set_namelist namelist_cfg jpnj 8
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_SPITZ12.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

    cd ${SETTE_DIR}
    export TEST_NAME="REPRO_8_4"
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"S12_84\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 120
    set_namelist namelist_cfg nn_date0 20020101
    set_namelist namelist_cfg jpni 8
    set_namelist namelist_cfg jpnj 4
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    . ./prepare_job.sh input_SPITZ12.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    cd ${SETTE_DIR}
    . ./fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}
fi

# -----------------
# ORCA2
# -----------------
if [ ${config} == "ORCA2" ] ;  then
  ## Restartability tests for ORCA2_ICE_PISCES
    export TEST_NAME="LONG"
    cd ${MAIN_DIR}
    pwd
    . ./makenemo -m ${CMP_NAM} -n ORCA2 -r ORCA2_ICE_PISCES -j 4 -d OCE del_key 'key_si3 key_top'
    cd ${SETTE_DIR}
    . ./param.cfg
    . ./all_functions.sh
    . ./prepare_exe_dir.sh
    set_valid_dir
    clean_valid_dir
    JOB_FILE=${EXE_DIR}/run_job.sh
    NPROC=32
    if [ -f ${JOB_FILE} ] ; then \rm ${JOB_FILE} ; fi
    cd ${EXE_DIR}
    set_namelist namelist_cfg cn_exp \"O2L3P_LONG\"
    set_namelist namelist_cfg nn_it000 1
    set_namelist namelist_cfg nn_itend 993
    set_namelist namelist_cfg nn_stock 495
    set_namelist namelist_cfg jpni 4
    set_namelist namelist_cfg jpnj 8
    set_namelist namelist_cfg ln_ctl .false.
    set_namelist namelist_cfg sn_cfctl%l_config .true.
    set_namelist namelist_cfg sn_cfctl%l_runstat .true.
    set_namelist namelist_cfg sn_cfctl%l_trcstat .true.
    set_namelist namelist_cfg ln_use_calving .true.
    set_namelist namelist_cfg ln_wave .true.
    set_namelist namelist_cfg ln_cdgw .true.
    set_namelist namelist_cfg ln_sdw  .true.
    set_namelist namelist_cfg nn_sdrift 1
    set_namelist namelist_cfg ln_stcor .true.
    set_namelist namelist_cfg ln_tauwoc .true.
    #
    if [ ${USING_ICEBERGS} == "no" ] ; then set_namelist namelist_cfg ln_icebergs .false. ; fi
    # for debugging purposes set_namelist namelist_cfg rn_test_box -180.0, 180.0, -90.0, -55.0
    #
    set_namelist namelist_ice_cfg ln_icediachk .true.
    set_namelist namelist_top_cfg ln_trcdta .false.
    # put ln_ironsed, ln_river, ln_ndepo, ln_dust to false
    # if not you need input files, and for tests is not necessary
    set_namelist namelist_pisces_cfg ln_presatm .false.
    set_namelist namelist_pisces_cfg ln_varpar .false.
    set_namelist namelist_pisces_cfg ln_dust .false.
    set_namelist namelist_pisces_cfg ln_solub .false.
    set_namelist namelist_pisces_cfg ln_river .false.
    set_namelist namelist_pisces_cfg ln_ndepo .false.
    set_namelist namelist_pisces_cfg ln_ironsed .false.
    set_namelist namelist_pisces_cfg ln_ironice .false.
    set_namelist namelist_pisces_cfg ln_hydrofe .false.
    # put ln_pisdmp to false : no restoring to global mean value
    set_namelist namelist_pisces_cfg ln_pisdmp .false.
    if [ ${USING_MPMD} == "yes" ] ; then
       set_xio_using_server iodef.xml true
    else
       set_xio_using_server iodef.xml false
    fi
    cd ${SETTE_DIR}
    echo "OU"
    pwd
    . ./prepare_job.sh input_ORCA2.cfg $NPROC ${TEST_NAME} ${MPIRUN_FLAG} ${JOB_FILE} ${NUM_XIOSERVERS} ${NEMO_VALID}
    pwd 
    . ${SETTE_DIR}/fcm_job.sh $NPROC ${JOB_FILE} ${INTERACT_FLAG} ${MPIRUN_FLAG}

fi


done