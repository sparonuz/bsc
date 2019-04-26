#!/bin/bash

#RUN_FOLDER=EFFICIENCY_NEMO4_MPI+PAPI
RUN_FOLDER=EFFICIENCY_NEMO4_orig
#RUN_FOLDER=EFFICIENCY_NEMO4_func

blue_print_job=nemo4_scaling.cmd

QUEUE="bsc_es"
TIME_STEP=2000
EXP_FOLDER=/gpfs/scratch/bsc32/bsc32402/NEMO4/run/RUN_FOLDER/Orca025_NETCDF-4.4.1.1_\$NEMO_PROC
#EXEC_FOLDER=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/cfgs/ORCA2_jpnij/EXP00/
EXEC_FOLDER=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/cfgs/ORCA2-NETCDF-4.4.1.1/EXP00/
#EXEC_FOLDER=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/cfgs/ORCA2-xios-r1660/EXP00/
#EXEC_FOLDER=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/cfgs/ORCA025_ICE/EXP00/
ICE=False
OUTPUT=True
mkdir -p $RUN_FOLDER

cp $blue_print_job  $RUN_FOLDER
cd $RUN_FOLDER

for NOP in  2070  #`seq 192 48 2160`
do
  job=job_$NOP.cmp
  cp $blue_print_job $job 
  sed -ri 's@QUEUE@'$QUEUE'@' $job
  sed -ri 's@TIME_STEP@'$TIME_STEP'@' $job
  sed -ri 's@EXP_FOLDER@'$EXP_FOLDER'@' $job
  sed -ri 's@EXEC_FOLDER@'$EXEC_FOLDER'@' $job
  sed -ri 's@RUN_FOLDER@'$RUN_FOLDER'@' $job
  sed -ri 's@NOP@'$NOP'@' $job
  sed -ri 's@ICE@'$ICE'@' $job
  sed -ri 's@OUTPUT@'$OUTPUT'@' $job

  sbatch $job 
done
cd .. 
