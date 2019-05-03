#!/bin/bash

#RUN_FOLDER=EFFICIENCY_NEMO4_MPI+PAPI
RUN_FOLDER=EFFICIENCY_NEMO4_orig
#RUN_FOLDER=EFFICIENCY_NEMO4_func

blue_print_job=nemo4_scaling.cmd

#QUEUE="xlarge"
QUEUE="bsc_es"

TIME_STEP=1920

EXP_FOLDER=/gpfs/scratch/bsc32/bsc32402/NEMO4/run/RUN_FOLDER/Orca025_OCE_5_NEMO_PROC
#EXP_FOLDER=/gpfs/scratch/bsc32/bsc32402/NEMO4/run/RUN_FOLDER/Orca025_XIOS_2_\$NEMO_PROC

#EXEC_FOLDER=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/cfgs/ORCA2/EXP00/
EXEC_FOLDER=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/cfgs/ORCA2_jpnij/EXP00/
#EXEC_FOLDER=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/cfgs/ORCA2-NETCDF-4.4.1.1/EXP00/
#EXEC_FOLDER=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/cfgs/ORCA2-xios-r1660/EXP00/
#EXEC_FOLDER=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/cfgs/ORCA025_ICE/EXP00/

ICE=False
#OUTPUT=True
OUTPUT=False

mkdir -p $RUN_FOLDER

cp $blue_print_job  $RUN_FOLDER
cd $RUN_FOLDER

cat << EOF > impi.env
module purge
module load intel/2018.3
module load impi/2018.3
module load netcdf/4.2
module load hdf5/1.8.19
module load perl
module list
EOF

#XIOS=True
XIOS=False

if [[ $XIOS == True ]]
then
  XIOS_PPN=4
else
  XIOS_PPN=0
fi

#HIGHMEM=True
HIGHMEM=False

PROC_PER_NODE=46
 
for TOTAL_NP in  576  #`seq $((PROC_PER_NODE*51)) $((PROC_PER_NODE*4))  $((PROC_PER_NODE*100))`
do
  XIOS_PROC=$((XIOS_PPN*TOTAL_NP/PROC_PER_NODE))
  NEMO_PROC=$((TOTAL_NP-XIOS_PROC))
  # echo $XIOS_PROC $TOTAL_NP $NOP
  job=job_$TOTAL_NP
  cp $blue_print_job $job 
  if [[ $HIGHMEM == True ]]
  then
    sed -ri 's@HIGHMEM@SBATCH --constraint=highmem@' $job
  fi
  sed -ri 's@QUEUE@'$QUEUE'@' $job
  sed -ri 's@TIME_STEP@'$TIME_STEP'@' $job
  sed -ri 's@EXP_FOLDER@'$EXP_FOLDER'@' $job
  sed -ri 's@EXEC_FOLDER@'$EXEC_FOLDER'@' $job
  sed -ri 's@RUN_FOLDER@'$RUN_FOLDER'@' $job
  sed -ri 's@TOTAL_NP@'$TOTAL_NP'@' $job
  sed -ri 's@NEMO_PROC@'$NEMO_PROC'@' $job
  sed -ri 's@XIOS_PROC@'$XIOS_PROC'@' $job
  sed -ri 's@USE_XIOS@'$XIOS'@' $job
  sed -ri 's@PROC_PER_NODE@'$PROC_PER_NODE'@' $job
  sed -ri 's@ICE@'$ICE'@' $job
  sed -ri 's@OUTPUT@'$OUTPUT'@' $job

  sbatch $job 
done
cd .. 
