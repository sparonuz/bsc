#!/bin/bash
##########################################################################
# Author : Simona Flavoni for NEMO
# Contact : sflod@locean-ipsl.upmc.fr
#
# ----------------------------------------------------------------------
# NEMO/SETTE , NEMO Consortium (2010)
# Software governed by the CeCILL licence     (NEMOGCM/NEMO_CeCILL.txt)
# ----------------------------------------------------------------------
#
# Some scripts called by sette.sh
# prepare_exe_dir.sh : script prepares execution directory for test
##########################################################################
#set -x
set -o posix
#set -u
#set -e
#+
#
# ==================
# prepare_exe_dir.sh
# ==================
#
# ----------------------------------------------
# Set of functions used by sette.sh (NEMO tests) 
# ----------------------------------------------
#
# SYNOPSIS
# ========
#
# ::
#
#  $ ./prepare_exe_dir.sh
#
# DESCRIPTION
# ===========
#
# prepare_exe_dir.sh creates execution directory takes name of TEST_NAME defined in every test in sette.sh
# 
# it is necessary to define in sette.sh TEST_NAME ( example : export TEST_NAME="LONG") to create execution directory in where run test.
#
# NOTE : each test has to run in its own directory ( of execution), if not existing files are re-written (for example namelist)
#
# EXAMPLES
# ========
#
# ::
#
#  $ ./prepare_exe_dir.sh
#
#
# TODO
# ====
#
# option debug
#
#
# EVOLUTIONS
# ==========
#
# $Id: $
#
#   * creation
#-


cd ${CONFIG_DIR0}

mkdir -p ${NEW_CONF}/${TEST_NAME}
# PREPARE EXEC_DIR
#==================
export EXE_DIR=${CONFIG_DIR0}/${NEW_CONF}/${TEST_NAME}

cp -RL ${CONFIG_DIR}/${NEW_CONF}/EXP00/* ${EXE_DIR}/.
#cat ${SETTE_DIR}/iodef_sette.xml | sed -e"s;DEF_SHARED;${CONFIG_DIR0}/SHARED;" > ${EXE_DIR}/iodef.xml
cd ${EXE_DIR}

# Remove previously generated output files used for test evaluation
# (if any)
[ -f ./ocean.output ] && mv ./ocean.output ./ocean.output.old
[ -f ./run.stat ]     && mv ./run.stat     ./run.stat.old
[ -f ./tracer.stat ]  && mv ./tracer.stat  ./tracer.stat.old
