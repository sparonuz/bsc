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
