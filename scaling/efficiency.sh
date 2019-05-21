#!/bin/bash

source param.cfg
mkdir -p ${RUN_FLD}
#RUN_FLD=EFFICIENCY_NEMO4_func

blue_print_job=slurm_print.cmd

mkdir -p $RUN_FLD

cp $blue_print_job  $RUN_FLD
cd $RUN_FLD

cat << EOF > impi.env
module purge
module load intel/2018.3
module load impi/2018.3
module load netcdf/4.2
module load hdf5/1.8.19
module load perl
module list
EOF


for TOTAL_NP in   $((N_NODE*PROC_PER_NODE)) # `seq $((PROC_PER_NODE*144)) $((PROC_PER_NODE*4))  $((PROC_PER_NODE*156))`
do
  job=job_$TOTAL_NP
  cp $blue_print_job $job

  sed -ri 's@TOTAL_NP@'$TOTAL_NP'@' $job

  if [[ $HIGHMEM == True ]]
  then
    sed -ri 's@HIGHMEM@SBATCH --constraint=highmem@' $job
  fi

  sed -ri 's@PROC_PER_NODE@'$PROC_PER_NODE'@' $job

  if [[ $N_NODE -gt 50 ]]
  then
    QUEUE="xlarge"
  elif [[ $N_NODE -gt 15 ]] 
  then
    QUEUE="bsc_es" 
  else
    QUEUE="debug"
  fi 
  sed -ri 's@QUEUE@'$QUEUE'@' $job

  sed -ri 's@RUN_FLD@'$RUN_FLD'@' $job

  NEMO_PROC=$TOTAL_NP

  sed -ri 's@USE_XIOS@'$XIOS'@' $job
  if [[ $XIOS == True ]]
  then
    NEMO_PROC=$((NEMO_PROC-XIOS_PROC)) 
    sed -ri 's@XIOS_PROC@'$XIOS_PROC'@' $job
  fi
  sed -ri 's@USE_DDT@'$DDT'@' $job

  sed -ri 's@NEMO_PROC@'$NEMO_PROC'@' $job
  sed -ri 's@EXEC_FOLDER@'$EXEC_FOLDER'@' $job
  sed -ri 's@TIME_STEP@'$TIME_STEP'@' $job
  sed -ri 's@ICE@'$ICE'@' $job
  sed -ri 's@OUTPUT@'$OUTPUT'@' $job
  sed -ri 's@MACHINEF@'$MACHINEF'@' $job

  #Create exp folder
  EXP_FOLDER=${EXP_FOLDER_ROOT}_${NEMO_PROC}
  mkdir ${EXP_FOLDER} || exit 1
  sed -ri 's@EXP_FOLDER@'$EXP_FOLDER'@' $job
  
  sbatch $job 
done
cd .. 
