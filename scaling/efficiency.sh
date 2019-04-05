#!/bin/bash

RUN_FOLDER=EFFICIENCY_NEMO4_func
blue_print_job=nemo4_scaling.cmd

mkdir -p $RUN_FOLDER

cp $blue_print_job  $RUN_FOLDER
cd $RUN_FOLDER

for np in `seq 48 48 576`
do
  job=job_$np.cmp
  cp $blue_print_job $job 
  sed -ri 's@RUN_FOLDER@'$RUN_FOLDER'@' $job
  sed -ri 's@NOP@'$np'@' $job
  sbatch $job 
done
cd .. 
