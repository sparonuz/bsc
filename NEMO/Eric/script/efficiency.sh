#!/bin/bash

#RUN_FOLDER=EFFICIENCY_NEMO4_MPI+PAPI
RUN_FOLDER=bench_scorep
#RUN_FOLDER=EFFICIENCY_NEMO4_func

blue_print_job=nemo4_scaling.cmd

#QUEUE="xlarge"
QUEUE="bsc_es"
#QUEUE="debug"

TIME_STEP=1500

EXP_FOLDER_ROOT=/gpfs/scratch/bsc32/bsc32402/NEMO4/run/BENCH_TEST/${RUN_FOLDER}/bench_scorep

EXEC_FOLDER=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/tests/BENCH_scorep/EXP00/
#EXEC_FOLDER=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/tests/BENCH_N/EXP00

INPUT_FOLDER=/gpfs/scratch/bsc32/bsc32402/BENCH_TEST/BENCH_INPUT
cp ${INPUT_FOLDER}/namelist_cfg_orca1_like  ${INPUT_FOLDER}/namelist_cfg

ICE=False

#OUTPUT=True
OUTPUT=False

#XIOS=True
XIOS=False


#EXTRAE=True 
EXTRAE=False 
if [[ $EXTRAE == True ]]
then 
  FUNCION_FILE=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/tests/BENCH_N/EXP00/extrae_functions_for_xml.txt
fi
SCOREP=True
#SCOREP=False
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


if [[ $XIOS == True ]]
then
  XIOS_PPN=4
fi

#HIGHMEM=True
HIGHMEM=False

PROC_PER_NODE=48
TOTAL_PPN=48
XIOS_PROC=0
for TOTAL_NP in  $((PROC_PER_NODE*5)) # `seq $((PROC_PER_NODE*10)) $((PROC_PER_NODE*4))  $((PROC_PER_NODE*48))`
do
  job=job_$TOTAL_NP
  cp $blue_print_job $job
  if [[ $HIGHMEM == True ]]
  then
    sed -ri 's@HIGHMEM@SBATCH --constraint=highmem@' $job
  fi
  sed -ri 's@QUEUE@'$QUEUE'@' $job
  sed -ri 's@TOTAL_NP@'$TOTAL_NP'@' $job
  sed -ri 's@PROC_PER_NODE@'$PROC_PER_NODE'@' $job
  sed -ri 's@RUN_FOLDER@'$RUN_FOLDER'@' $job
  sed -ri 's@USE_XIOS@'$XIOS'@' $job
  if [[ $XIOS == True ]]
  then
    XIOS_PROC=$((XIOS_PPN*TOTAL_NP/TOTAL_PPN))
    sed -ri 's@XIOS_PROC@'$XIOS_PROC'@' $job
  fi

  NEMO_PROC=$TOTAL_NP #$(((TOTAL_NP/TOTAL_PPN*PROC_PER_NODE)-XIOS_PROC))
  sed -ri 's@NEMO_PROC@'$NEMO_PROC'@' $job
  sed -ri 's@INPUT_FOLDER@'$INPUT_FOLDER'@' $job

  #Create exp folder
  sed -ri 's@EXEC_FOLDER@'$EXEC_FOLDER'@' $job
  EXP_FOLDER=${EXP_FOLDER_ROOT}_${NEMO_PROC}
  mkdir ${EXP_FOLDER} || exit 1
  sed -ri 's@EXP_FOLDER@'$EXP_FOLDER'@' $job

  sed -ri 's@USE_SCOREP@'$SCOREP'@' $job
  sed -ri 's@USE_EXTRAE@'$EXTRAE'@' $job
  if [[ $EXTRAE == True  ]]
  then
     sed -ri 's@FUNCION_FILE@'$FUNCION_FILE'@' $job
  fi
  sed -ri 's@TIME_STEP@'$TIME_STEP'@' $job
  sed -ri 's@ICE@'$ICE'@' $job
  sed -ri 's@OUTPUT@'$OUTPUT'@' $job
  
  sbatch $job 
done
cd .. 
