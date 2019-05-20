#!/bin/bash

#RUN_FLD=EFFICIENCY_NEMO4_MPI+PAPI
RUN_FLD=MPI_BINDING
mkdir -p ${RUN_FLD}
#RUN_FLD=EFFICIENCY_NEMO4_func

blue_print_job=slurm_print.cmd

TIME_STEP=12

#EXP_FOLDER_ROOT=/gpfs/scratch/bsc32/bsc32402/NEMO4/run/${RUN_FLD}/Orca025_OCE_XIOS_ppn4
EXP_FOLDER_ROOT=/gpfs/scratch/bsc32/bsc32402/NEMO4/run/${RUN_FLD}/Orca025_OCE_bind_to_core
#EXP_FOLDER=/gpfs/scratch/bsc32/bsc32402/NEMO4/run/RUN_FLD/Orca025_XIOS_2_\$NEMO_PROC

#EXEC_FOLDER=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/cfgs/ORCA2/EXP00/
EXEC_FOLDER=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/cfgs/ORCA2_jpnij/EXP00/
#EXEC_FOLDER=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/cfgs/ORCA2-NETCDF-4.4.1.1/EXP00/
#EXEC_FOLDER=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/cfgs/ORCA2-xios-r1660/EXP00/
#EXEC_FOLDER=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/cfgs/ORCA025_ICE/EXP00/

ICE=False

#OUTPUT=True
OUTPUT=False

#XIOS=True
XIOS=False

#DDT=True
DDT=False

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


if [[ $XIOS == True ]]
then
  XIOS_PPN=4
fi

#HIGHMEM=True
HIGHMEM=False

PROC_PER_NODE=46
TOTAL_PPN=48
XIOS_PROC=0

MACHINEF=True

for TOTAL_NP in   $((PROC_PER_NODE*2)) # `seq $((PROC_PER_NODE*144)) $((PROC_PER_NODE*4))  $((PROC_PER_NODE*156))`
do
  job=job_$TOTAL_NP
  cp $blue_print_job $job
  if [[ $HIGHMEM == True ]]
  then
    sed -ri 's@HIGHMEM@SBATCH --constraint=highmem@' $job
  fi
  if [[ $PROC_PER_NODE -ne $TOTAL_PPN ]]
  then
    sed -ri 's@PROC_PER_NODE@'$PROC_PER_NODE'@' $job
  fi

  if [[ $TOTAL_NP -gt $((TOTAL_PPN*50)) ]]
  then
    QUEUE="xlarge"
  elif [[ $TOTAL_NP -gt $((TOTAL_PPN*15)) ]] 
  then
    QUEUE="bsc_es" 
  else
    QUEUE="debug"
  fi 

  sed -ri 's@QUEUE@'$QUEUE'@' $job

  sed -ri 's@RUN_FLD@'$RUN_FLD'@' $job
  sed -ri 's@USE_XIOS@'$XIOS'@' $job
  if [[ $XIOS == True ]]
  then
    XIOS_PROC=$((XIOS_PPN*TOTAL_NP/TOTAL_PPN))
    sed -ri 's@XIOS_PROC@'$XIOS_PROC'@' $job
  fi
  sed -ri 's@USE_DDT@'$DDT'@' $job
  sed -ri 's@TOTAL_NP@'$TOTAL_NP'@' $job
  NEMO_PROC=$((TOTAL_NP-XIOS_PROC))
  sed -ri 's@NEMO_PROC@'$NEMO_PROC'@' $job
  sed -ri 's@TIME_STEP@'$TIME_STEP'@' $job
  sed -ri 's@EXEC_FOLDER@'$EXEC_FOLDER'@' $job
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
