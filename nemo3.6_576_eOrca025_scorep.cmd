#!/bin/bash
###############################################################################
#                             RUN NEMO
###############################################################################
#SBATCH --ntasks 576 
#SBATCH --job-name ORCA02-576
#SBATCH --output nemo3.6-eOrca025.o 
#SBATCH --error  nemo3.6-eOrca025.e
##SBATCH -R "span[ptile=16]"
#SBATCH --time 50:00
#SBATCH --qos=debug

#cd $SLURM_SUBMIT_DIR

#Create the new folder
exp_folder=/gpfs/scratch/bsc32/bsc32402/NEMO3/run/Exp_nemo3_eOrca025_scorep

exec_folder=/home/bsc32/bsc32402/local/Nemo/NEMOGCM/CONFIG/ORCA025_LIM3_scorep/EXP00/
exec_name=opa

xml_folder=/gpfs/scratch/bsc32/bsc32402/NEMO3/eORCA025/xml
netCDF_folder=/gpfs/scratch/bsc32/bsc32402/NEMO3/eORCA025/input_files/

namelist_folder=$netCDF_folder

#extrae_wrapper=/gpfs/scratch/bsc32/bsc32402/Nemo4/Orca2-r10610/nemo_wrapper.sh
#extrae_home=/gpfs/projects/bsc32/cs_collaboration/extrae-3.6.1-uf-fix
#extrae_home=/gpfs/projects/bsc32/cs_collaboration/extrae-3.6.1-904d4f4/
#extrae_xml=$exec_folder/detailed_trace_basic.xml

#scorep_folder=/gpfs/scratch/bsc32/bsc32402/Nemo4/Orca2-r10610/scorep_nemo/
#scorep_extr_script=/gpfs/scratch/bsc32/bsc32402/Nemo4/Orca2-r10610/scorep_extract_funct.sh

#function_file=$exec_folder/extrae_functions_for_xml.txt
#function_file=$exec_folder/functions_for_xml.txt

impi_file=/gpfs/scratch/bsc32/bsc32402/Nemo4/Orca2-r10610/impi.env

# Replace the number of resources used for NEMO and XIOS
NEMO_PROC=576
XIOS_PROC=0
TIME_STEP=12

# Export extrae variable (for the wrapper to know if it is activated)
#export EXTRAE=True
export EXTRAE=False
SCOREP=True
XIOS=False

#Create exp folder
mkdir  $exp_folder
cp $0 $exp_folder
cd $exp_folder

#copy all the .xml files
cp $xml_folder/*.xml . || exit 1
cp $namelist_folder/namelist_* . || exit 1
cp -s $netCDF_folder/*.nc . || exit 1
cp $netCDF_folder/*.dat . 2> /dev/null ||echo "                               0  0.0000000000000000E+00  0.0000000000000000E+00" > EMPave_old.dat

#rm context_nemo.xml
#sed '/def_nemo-ice/d' $xml_folder/context_nemo.xml | sed '/def_nemo-pisces/d' > context_nemo.xml

if ! [ -e "$impi_file"  ]
then
  echo $file_name ": impi file not found"
cat << EOF > impi.env
module purge
module load intel/2018.3
module load impi/2018.3
module load netcdf/4.2
module load hdf5/1.8.19
module load perl
module list
EOF
else
  cp -s $impi_file .
fi


cp -s $exec_folder/$exec_name ./

# Finding Job id
RN_JOBID=${SLURM_JOB_ID:-$LSB_JOBID}

# Changing the number of steps (if activated)
if [[ True == True ]];then
   sed -ri 's/(.)(nn_itend)(.*)/   \2    =    '$TIME_STEP'   /' namelist_cfg
   sed -ri 's/(.)(nn_itend)(.*)/   \2    =    '$TIME_STEP'   /' namelist_ref
fi

# Source the proper environment for the run
source impi.env
   
# Modify the iodef.xml file to select if using or not servers.
if [[ False == True ]]; then
    XSERVER=true
else
    XSERVER=false
fi

sed -ri 's/(.*)(using_server)(.*)(true|false)(.*)/\1\2\3'$XSERVER'\5/' iodef.xml
# If extrae is used, create the function file for extrae.
if [[ $EXTRAE == True ]]
then
  if ! [ -e "$function_file"  ]
  then
    $scorep_extr_script $scorep_folder/profile.cubex $exec_name
  else
    sed 's@./extrae_functions_for_xml.txt@'$function_file'@' $extrae_xml > ./`basename $extrae_xml`
    extrae_xml=`basename $extrae_xml`
  fi
  trace=trace.sh
  cat << EOF > $trace
  #!/bin/bash

  EXTRAE_HOME=$extrae_home
  export EXTRAE_CONFIG_FILE=$extrae_xml
  source \$EXTRAE_HOME/etc/extrae.sh

  export LD_PRELOAD=\${EXTRAE_HOME}/lib/libmpitracecf.so

  export LD_LIBRARY_PATH=\${EXTRAE_HOME}/lib/:\$LD_LIBRARY_PATH

  \$*
EOF

  chmod 755 $trace
fi

# Launch command
if [[ $XIOS == False ]];then
   if [[ $SCOREP == True ]]
   then
     source /home/nct00/nct00004/bin/tools_x86_intel17.sh
     export SCOREP_EXPERIMENT_DIRECTORY=scorep_nemo
     EXEC="time mpirun -np $NEMO_PROC ./$exec_name"
   fi

   if [[ $EXTRAE == True ]]
   then 
     #EXEC="time mpirun -np $NEMO_PROC ./trace.sh ./$exec_name" 
     EXEC="time mpirun -np $NEMO_PROC ./$trace ./$exec_name" 
   else
     EXEC="time mpirun -np $NEMO_PROC ./$exec_name"
   fi
else
   EXEC="time mpirun -np $XIOS_PROC ./xios_wrapper.sh ./xios_server.exe : -np $NEMO_PROC ./nemo_wrapper.sh ./$exec_name"
fi
  
# Actual execution
eval $EXEC
   
