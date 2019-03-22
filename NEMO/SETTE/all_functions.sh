######################################################
# Author : Simona Flavoni for NEMO
# Contact : sflod@locean-ipsl.upmc.fr
#
# ----------------------------------------------------------------------
# NEMO/SETTE , NEMO Consortium (2010)
# Software governed by the CeCILL licence     (NEMOGCM/NEMO_CeCILL.txt)
# ----------------------------------------------------------------------
#
# Some scripts called by sette.sh
# all_functions.sh   : all functions used by sette.sh  
######################################################
#set -x
#set -o posix
#set -u
#set -e
#+
#
# ================
# all_functions.sh
# ================
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
#  $ ./set_namelist INPUT_NAMELIST VARIABLE VALUE 
#  $ post_test_tidyup 
#
#
# DESCRIPTION
# ===========
#
# function superegrep
#   input variable value
#
# function set_namelist
#   input namelist_name variable value
#   output namelist
#
# function post_test_tidyup
#   creates nemo_validation tree, and save output & debug files
#   this function creates tree of validation in NEMO_VALIDATION_DIR as follows : 
#
# NEMO_VALIDATION_DIR/WCONFIG_NAME/WCOMPILER_NAME/REVISION_NUMBER(or DATE)/TEST_NAME
# 
# NEMO_VALIDATION_DIR           : is choosen in param.cfg
#
# WCONFIG_NAME                  : set by makenemo at the moment of compilation
#
# WCOMPILER_NAME                : set by makenemo at the moment of compilation
#
# REVISION_NUMBER(or DATE)      : revision number by svn info, if problems with svn date is taken
#
# TEST_NAME                     : set in sette.sh for each configuration to be tested (directory TEST_NAME is created under ${NEW_CONF} directory )
#
# EXAMPLES
# ========
#
# ::
#
#  $ ./set_namelist namelist          nn_itend        75
#  $ ./set_namelist namelist_ice      cn_icerst_in  \"00101231_restart_ice\"
#  $ post_test_tidyup 
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
# $Id: all_functions.sh 10755 2019-03-14 16:22:12Z mathiot $
#
#   * creation
#-
# function to find namelists parameters
supergrep () {
            grep "^ *$1 *=" $2 | sed -e "s% *\!.*%%"
    }

usage=" Usage : set_namelist input_namelist variable_name value"
usage=" if value is a string ths is neede syntax : ./set_namelist namelist_name var_name \"new_value\" "

# define validation dir
set_valid_dir () {
    LANG=en_US
    REVISION_NB=`LC_MESSAGES=${LANG} svn info ${SETTE_DIR}/.. | grep "Last Changed Rev" | awk '{print $NF}'`
    if [ ${#REVISION_NB} -eq 0 ]
    then
        echo "some problems with svn info command"
        echo "some problems with svn info command" >> ${SETTE_DIR}/output.sette
        REVISION_NB=`date +%Y%m%d`
        echo "put in ${REVISION_NB} date"
        echo "put in ${REVISION_NB} date" >> ${SETTE_DIR}/output.sette
    else
    echo "value of revision number of NEMOGCM: ${REVISION_NB}"
    fi
    NEMO_VALID=${NEMO_VALIDATION_DIR}/W${NEW_CONF}/${CMP_NAM}/${REVISION_NB}/${TEST_NAME}
}

# clean valid dir (move old ocean_output/run.stat and tracer to avoid checking them in case something wrong happen.
clean_valid_dir () {
#   set_valid_dir # already done in sette_ref/sette_test
   echo "validation directory is : $NEMO_VALID"
   if [ -d $NEMO_VALID ] ; then
      [ -f ${NEMO_VALID}/ocean.output ] && mv ${NEMO_VALID}/ocean.output ${NEMO_VALID}/ocean.output_old
      [ -f ${NEMO_VALID}/run.stat ]     && mv ${NEMO_VALID}/run.stat     ${NEMO_VALID}/run.stat_old
#      [ -f ${NEMO_VALID}/tracer.stat ]  && mv ${NEMO_VALID}/tracer.stat  ${NEMO_VALID}/tracer.stat_old
   fi
}

# function to set namelists parameters
set_namelist () {
	minargcount=3
	if [ ${#} -lt ${minargcount} ]
	then
		echo "not enough arguments for set_namelist"
		echo "${usage}"
		exit 1
	fi
	unset minargcount
	if [  ! -f ${SETTE_DIR}/output.sette ] ; then
                touch ${SETTE_DIR}/output.sette
        fi

        echo "executing script : set_namelist $@" >> ${SETTE_DIR}/output.sette
        echo "################" >> ${SETTE_DIR}/output.sette
      
	VAR_NAME=$( supergrep $2 ${EXE_DIR}/$1 )
	if [ ${#VAR_NAME} -eq 0 ] 
	then
		echo "doing \"set_namelist $@\". "  >> ${SETTE_DIR}/output.sette
		echo "variable: \"$2\" not found in \"${EXE_DIR}/$1\" "  >> ${SETTE_DIR}/output.sette
                NAMREF=$( basename $1 _cfg )_ref
		echo "doing more : search in ${EXE_DIR}/$NAMREF " >> ${SETTE_DIR}/output.sette
                VAR_NAME=$( supergrep $2 ${EXE_DIR}/$NAMREF )
	        if [ ${#VAR_NAME} -eq 0 ] 
	        then
                    echo " variable $VAR_NAME not found in ${EXE_DIR}/$1 nor in ${EXE_DIR}/$NAMREF "
                    echo " check your variable name "
        		echo "exit"
	        	echo "error in executing script : set_namelist $@" >> ${SETTE_DIR}/output.sette
	        	echo "....." >> ${SETTE_DIR}/output.sette
        		exit 1
                fi
                LINEVAR=$( grep -s -n "$VAR_NAME" ${EXE_DIR}/$NAMREF | awk -F: '{ { print $1} }' )
                echo " $VAR_NAME found in ${EXE_DIR}/$NAMREF at line $LINEVAR " >> ${SETTE_DIR}/output.sette
#   search for namelist group name
                NAMGRP=$( head -n$LINEVAR ${EXE_DIR}/$NAMREF | grep --line-buffered "^&nam" | tail -1 | awk -F" " '{ { print $1} }' ) 
                echo " variable $VAR_NAME will be added in $NAMGRP namelist-group of namelist file ${EXE_DIR}/$1 " >> ${SETTE_DIR}/output.sette
# Add $VARNAME in namelist file ${EXE_DIR}/$1 in namelist group $NAMGRP
# on mac osx, replace sed --posix by gsed (available with mac port)
                sed --posix "/${NAMGRP} /a\ ${VAR_NAME} " ${EXE_DIR}/$1 > ${EXE_DIR}/$1.tmp || gsed --posix "/${NAMGRP} /a\ ${VAR_NAME} " ${EXE_DIR}/$1 > ${EXE_DIR}/$1.tmp
# if file not empty replace ${EXE_DIR}/$1
                if [ -s ${EXE_DIR}/$1.tmp ] ; then
                   mv ${EXE_DIR}/$1.tmp ${EXE_DIR}/$1 
                else
                echo "file ${EXE_DIR}/$1.tmp is empty. sed command went wrong "; exit 200
                fi
	fi

        ARGS_LST="${@:3}"
        sed -e "s;${VAR_NAME}.*;${VAR_NAME};" ${EXE_DIR}/$1 > ${EXE_DIR}/$1.tmp
        mv ${EXE_DIR}/$1.tmp ${EXE_DIR}/$1
        sed -e "s;${VAR_NAME};$2=${ARGS_LST};"  ${EXE_DIR}/$1 > ${EXE_DIR}/$1.tmp
        mv ${EXE_DIR}/$1.tmp ${EXE_DIR}/$1

        echo "finished script : set_namelist $@" >> ${SETTE_DIR}/output.sette
        echo "++++++++++++++++" >> ${SETTE_DIR}/output.sette
        echo "                " >> ${SETTE_DIR}/output.sette
}


# function to tidy up after each test and populate the NEMO_VALIDATION store
post_test_tidyup () {
# Save current exit status of caller script 
    RUN_STATUS=$? 
    echo "Exit status: ${RUN_STATUS}" 
#
# requires the following variables defined and exported from the calling script:
#  SETTE_DIR
#  INPUT_DIR
#  EXE_DIR
#  CONFIG_DIR
#  NEMO_VALIDATION_DIR
#  NEW_CONF
#  CMP_NAM
#  TEST_NAME
echo "SETTE directory is : ${SETTE_DIR}"
echo "INPUT directory is : ${INPUT_DIR}"
echo "EXECUTION directory is : ${EXE_DIR}"
echo "CONFIG directory is : ${CONFIG_DIR}"
echo "VALIDATION directory is : ${NEMO_VALID}"
echo "NEW CONFIGURATION is : ${NEW_CONF}"
echo "COMPILER is : ${CMP_NAM}"
echo "TEST is : ${TEST_NAME}"
echo "TOOLS directory is : ${TOOLS_DIR}"
################################################################
# SMALL DEBUG
    EXIT_STATUS=${RUN_STATUS}
    if [ ! -r ${EXE_DIR}/ocean.output ]
        then
        grep "E R R O R" ${EXE_DIR}/ocean.output && echo "Some ERRORS at execution time, see ${EXE_DIR}/ocean.output"
        EXIT_STATUS=2
        # exit 2 Error now catch in the report 
    fi

    if [ ! -r ${EXE_DIR}/time.step ]
        then
        echo "file time.step does not exist"   >> ${SETTE_DIR}/output.sette
        echo "some problems during execution of model"  >> ${SETTE_DIR}/output.sette 
        EXIT_STATUS=1
        # exit 1 Error now catch in the report
    else
        echo "file time.step exists"  >> ${SETTE_DIR}/output.sette
        echo "execution of model time step loop started"   >> ${SETTE_DIR}/output.sette
    fi

################################################################

################################################################
#
# Creation of NEMO_VALIDATION tree
#    set_valid_dir already done in sette_reference_config
    mkdir -p ${NEMO_VALIDATION_DIR}
    if [ -d ${NEMO_VALIDATION_DIR} ] ; then
	echo "created ${NEMO_VALIDATION_DIR} directory"   >> ${SETTE_DIR}/output.sette
    else 
	echo "problems in creating ${NEMO_VALIDATION_DIR} directory"   >> ${SETTE_DIR}/output.sette
	echo "EXIT,"
	exit 1
    fi
# 
# Exit before populating validation directory if the model run has 
# returned a non-zero exit status 
# On CRAY NEMO exit is not the expected 999 or 123456 (let this bloc in case useful later on).
#    case ${EXIT_STATUS} in
#        0|123456|999) echo " NEMO finished with exit code $EXIT_STATUS " ; post_test_tidyup ;;
#        *) echo " NEMO abort on an unexpected error (segmentation fault or whatever) $EXIT_STATUS "
#    esac

    [ ${EXIT_STATUS} -ne 0 ] && exit ${EXIT_STATUS}  
#
# Save output & debug files in NEMO_VALIDATION tree
    echo "saving ocean & ice output, run.stat, tracer.stat files ...." >> ${SETTE_DIR}/output.sette
    echo "            " >> ${SETTE_DIR}/output.sette
    [ -f ${EXE_DIR}/ocean.output ] && cp ${EXE_DIR}/*ocean.output ${NEMO_VALIDATION_DIR}/.
    [ -f ${EXE_DIR}/run.stat ] && cp ${EXE_DIR}/*run.stat ${NEMO_VALIDATION_DIR}/.
    [ -f ${EXE_DIR}/output.namelist.dyn ] && cp ${EXE_DIR}/*output.nam* ${NEMO_VALIDATION_DIR}/.
#    [ -f ${EXE_DIR}/tracer.stat ] && cp ${EXE_DIR}/*tracer.stat ${NEMO_VALIDATION_DIR}/.

    if [ -n "$(ls ${NEMO_VALIDATION_DIR}/*run*)" ] ; then
	echo "moved run.stat in ${NEMO_VALIDATION_DIR} directory"  >> ${SETTE_DIR}/output.sette
	echo "moved run.stat in ${NEMO_VALIDATION_DIR} directory"  
    else
	echo "problem in looking for run.stat file in ${NEMO_VALIDATION_DIR} directory"  >> ${SETTE_DIR}/output.sette
	echo "run.stat IS NOT in ${NEMO_VALIDATION_DIR} directory" 
    fi
    if [ -n "$(ls ${NEMO_VALIDATION_DIR}/*ocean.output*)" ] ; then
	echo "moved ocean.output in ${NEMO_VALIDATION_DIR} directory"  >> ${SETTE_DIR}/output.sette
	echo "moved ocean.output in ${NEMO_VALIDATION_DIR} directory" 
    else
	echo "problem in looking for ocean.output file in ${NEMO_VALIDATION_DIR} directory"  >> ${SETTE_DIR}/output.sette
	echo "ocean.output IS NOT in ${NEMO_VALIDATION_DIR} directory" 
    fi
#    if [ -n "$(ls ${NEMO_VALIDATION_DIR}/*tracer.stat*)" ] ; then
#        echo "moved tracer.stat in ${NEMO_VALIDATION_DIR} directory"  >> ${SETTE_DIR}/output.sette
#        echo "moved tracer.stat in ${NEMO_VALIDATION_DIR} directory"
#    else
#        echo "problem in looking for tracer.stat file in ${NEMO_VALIDATION_DIR} directory"  >> ${SETTE_DIR}/output.sette
#        echo "tracer.stat IS NOT in ${NEMO_VALIDATION_DIR} directory"
#    fi
}

#############################################################
# extra functions to manipulate settings in the iodef.xml file
#
# Examples:
#   set_xio_file_type    iodef.xml one_file
#   set_xio_using_server iodef.xml true
#   set_xio_buffer_size  iodef.xml 50000000
#   set_xio_field_defs   iodef.xml
#
#############################################################

usage2=" Usage : set_xio_file_type input_iodef.xml one_file||multiple_file"
usage3=" Usage : set_xio_using_server input_iodef.xml true||false"
usage4=" Usage : set_xio_buffer_size input_iodef.xml int_buffer_size"
usage5=" Usage : set_xio_field_defs input_iodef.xml"

set_xio_file_type () {
        minargcount=2
        if [ ${#} -lt ${minargcount} ]
        then
                echo "not enough arguments for set_xio_file_type"
                echo "${usage2}"
                exit 1
        fi
        if [ $2 != "one_file" ] && [ $2 != "multiple_file" ]
        then
                echo "unrecognised argument for set_xio_file_type"
                echo "${usage2}"
                echo $2
                exit 1
        fi
        unset minargcount
        if [  ! -f ${SETTE_DIR}/output.sette ] ; then
                touch ${SETTE_DIR}/output.sette
        fi

        echo "executing script : set_xio_file_type $@" >> ${SETTE_DIR}/output.sette
        echo "################" >> ${SETTE_DIR}/output.sette

        VAR_NAME=$( grep "^.*<.*file_definition.*type.*=" ${EXE_DIR}/$1 | sed -e "s% *\!.*%%" )
        if [ ${#VAR_NAME} -eq 0 ]
        then
                echo "doing \"set_xio_file_type $@\". "
                echo "xml_tag: file_definition with variable: type is empty"
                echo "confirm that an appropriate file_definition is in \"${EXE_DIR}/$1\" "
                echo "exit"
                echo "error in executing script : set_xio_file_type $@" >> ${SETTE_DIR}/output.sette
                echo "....." >> ${SETTE_DIR}/output.sette
                exit 1
        fi
        if [ $2 == "one_file" ] 
        then
           sed -e "s:multiple_file:one_file:" ${EXE_DIR}/$1 > ${EXE_DIR}/$1.tmp
        else
           sed -e "s:one_file:multiple_file:" ${EXE_DIR}/$1 > ${EXE_DIR}/$1.tmp
        fi
        mv ${EXE_DIR}/$1.tmp ${EXE_DIR}/$1

        echo "finished script : set_xio_file_type $@" >> ${SETTE_DIR}/output.sette
        echo "++++++++++++++++" >> ${SETTE_DIR}/output.sette
        echo "                " >> ${SETTE_DIR}/output.sette
}

set_xio_using_server () {
        minargcount=2
        if [ ${#} -lt ${minargcount} ]
        then
                echo "not enough arguments for set_xio_using_server"
                echo "${usage2}"
                exit 1
        fi
        if [ $2 != "true" ] && [ $2 != "false" ]
        then
                echo "unrecognised argument for set_xio_using_server"
                echo "${usage2}"
                echo $2
                exit 1
        fi
        unset minargcount
        if [  ! -f ${SETTE_DIR}/output.sette ] ; then
                touch ${SETTE_DIR}/output.sette
        fi

        echo "executing script : set_xio_using_server $@" >> ${SETTE_DIR}/output.sette
        echo "################" >> ${SETTE_DIR}/output.sette

        VAR_NAME=$( grep "^.*<.*variable id.*=.*using_server.*=.*bool" ${EXE_DIR}/$1 | sed -e "s% *\!.*%%" )
        if [ ${#VAR_NAME} -eq 0 ]
        then
                echo "doing \"set_xio_using_server $@\". "
                echo "xml_tag: "variable id=using_server" with variable: bool is empty"
                echo "confirm that an appropriate variable id is in \"${EXE_DIR}/$1\" "
                echo "exit"
                echo "error in executing script : set_xio_using_server $@" >> ${SETTE_DIR}/output.sette
                echo "....." >> ${SETTE_DIR}/output.sette
                exit 1
        fi
        if [ $2 == "false" ]
        then
           sed -e "/using_server/s:true:false:" ${EXE_DIR}/$1 > ${EXE_DIR}/$1.tmp
           export USING_MPMD=no
        else
           sed -e "/using_server/s:false:true:" ${EXE_DIR}/$1 > ${EXE_DIR}/$1.tmp
           export USING_MPMD=yes
        fi
        mv ${EXE_DIR}/$1.tmp ${EXE_DIR}/$1

        echo "finished script : set_xio_using_server $@" >> ${SETTE_DIR}/output.sette
        echo "++++++++++++++++" >> ${SETTE_DIR}/output.sette
        echo "                " >> ${SETTE_DIR}/output.sette
}

set_xio_buffer_size () {
        minargcount=2
        if [ ${#} -lt ${minargcount} ]
        then
                echo "not enough arguments for set_xio_buffer_size"
                echo "${usage4}"
                exit 1
        fi
        unset minargcount
        if [  ! -f ${SETTE_DIR}/output.sette ] ; then
                touch ${SETTE_DIR}/output.sette
        fi

        echo "executing script : set_xio_buffer_size $@" >> ${SETTE_DIR}/output.sette
        echo "################" >> ${SETTE_DIR}/output.sette

        VAR_NAME=$( grep "^.*<.*variable id.*=.*buffer_size.*=.*integer" ${EXE_DIR}/$1 | sed -e "s% *\!.*%%" )
        if [ ${#VAR_NAME} -eq 0 ]
        then
                echo "doing \"set_xio_buffer_size $@\". "
                echo "xml_tag: "variable id=buffer_size" with variable: integer is empty"
                echo "confirm that an appropriate variable id is in \"${EXE_DIR}/$1\" "
                echo "exit"
                echo "error in executing script : set_xio_buffer_size $@" >> ${SETTE_DIR}/output.sette
                echo "....." >> ${SETTE_DIR}/output.sette
                exit 1
        fi
        sed -e "/buffer_size/s:>.*<:>$2<:" ${EXE_DIR}/$1 > ${EXE_DIR}/$1.tmp
        mv ${EXE_DIR}/$1.tmp ${EXE_DIR}/$1

        echo "finished script : set_xio_buffer_size $@" >> ${SETTE_DIR}/output.sette
        echo "++++++++++++++++" >> ${SETTE_DIR}/output.sette
        echo "                " >> ${SETTE_DIR}/output.sette
}

set_xio_field_defs () {
        minargcount=1
        if [ ${#} -lt ${minargcount} ]
        then
                echo "not enough arguments for set_xio_field_defs"
                echo "${usage5}"
                exit 1
        fi
        unset minargcount
        if [  ! -f ${SETTE_DIR}/output.sette ] ; then
                touch ${SETTE_DIR}/output.sette
        fi

        echo "executing script : set_xio_field_defs $@" >> ${SETTE_DIR}/output.sette
        echo "################" >> ${SETTE_DIR}/output.sette


        [ -f ${EXE_DIR}/field_def_nemo-oce.xml ] || sed -i '/field_def_nemo-oce/d' $1
        [ -f ${EXE_DIR}/field_def_nemo-ice.xml ] || sed -i '/field_def_nemo-ice/d' $1
        [ -f ${EXE_DIR}/field_def_nemo-pisces.xml ] || sed -i '/field_def_nemo-pisces/d' $1

        echo "finished script : set_xio_field_defs $@" >> ${SETTE_DIR}/output.sette
        echo "++++++++++++++++" >> ${SETTE_DIR}/output.sette
        echo "                " >> ${SETTE_DIR}/output.sette
}
