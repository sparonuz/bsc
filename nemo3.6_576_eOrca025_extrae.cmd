#!/bin/bash
###############################################################################
#                             RUN NEMO
###############################################################################
#SBATCH --ntasks 624 
#SBATCH --ntasks-per-node 44
#SBATCH --job-name O025_N4_r10075
#SBATCH --output nemo4-newcomm.o 
#SBATCH --error  nemo4-newcomm.e
##SBATCH -R "span[ptile=16]"
#SBATCH --time 30:00
#SBATCH --qos=debug

#cd $SLURM_SUBMIT_DIR

# Replace the number of resources used for NEMO and XIOS
NEMO_PROC=576
TIME_STEP=12
#RESTART=True
RESTART=False
# Export extrae variable (for the wrapper to know if it is activated)
#XIOS=False
XIOS=True

if [[ $XIOS == True ]]
then
 XIOS_PROC=48 
fi

set -xv

exec_name=nemo
#exec_folder=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/cfgs/ORCA2_scorep/EXP00/
#exec_folder=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/cfgs/ORCA2_fine_f/EXP00/
exec_folder=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/cfgs/ORCA2_jpnij/EXP00/
#exec_folder=/home/bsc32/bsc32402/local/Nemo/trunk-r10610/cfgs/ORCA2/EXP00/
#Create the new folder
exp_folder=/gpfs/scratch/bsc32/bsc32402/NEMO4/run/eOrca025_ref_rest

#Input files
xml_folder=/gpfs/scratch/bsc32/bsc32402/NEMO4/eORCA025/xml/
netCDF_folder=/gpfs/scratch/bsc32/bsc32402/NEMO4/eORCA025/input_files/
namelist_folder=$netCDF_folder

#Debug mode
#DDT=True
DDT=False
#extrae variables
export EXTRAE=False
#export EXTRAE=True
if [[ $RESTART == True ]]
then
  restart_files=/gpfs/scratch/bsc32/bsc32402/NEMO4/run/eOrca025_opt
fi

if [[ $EXTRAE == True ]]
then 
  #extrae_home=/apps/BSCTOOLS/extrae/3.5.2/impi_2017_4/
  extrae_home=/gpfs/projects/bsc32/cs_collaboration/extrae-3.6.1-uf-fix/install-impi-no-dladdr
  extrae_xml=/gpfs/scratch/bsc32/bsc32402/NEMO4/Orca2-r10610/detailed_trace_basic.xml
  function_file=/gpfs/scratch/bsc32/bsc32402/NEMO4/run/eOrca025_scorep/extrae_functions_for_xml.txt
fi

if [[ $XIOS == True ]] 
then
  xios_exec_folder=/home/bsc32/bsc32402/local/XIOS/xios-2.5/bin/
  xios_exec_name=xios_server.exe
fi
#SCOREP=True
SCOREP=False
if [[ $SCOREP == True ]]
then
  scorep_dir=scorep_nemo
#  source /home/nct00/nct00004/bin/tools_x86_intel17.sh
  module load scorep
  export SCOREP_EXPERIMENT_DIRECTORY=$scorep_dir
fi

#file that contains version of modules to load
impi_file=/gpfs/scratch/bsc32/bsc32402/NEMO4/Orca2-r10610/impi.env

#Create exp folder
mkdir $exp_folder || exit 1

#copy slurm file
cp $0 $exp_folder
cd $exp_folder

#copy all the input files or creates the ones that doesn't exist
cp $xml_folder/*.xml . || exit 1
cp $namelist_folder/namelist_* . || exit 1
cp -s $netCDF_folder/*.nc . || exit 1
cp $netCDF_folder/*.dat . 2> /dev/null || echo "                               0  0.0000000000000000E+00  0.0000000000000000E+00" > EMPave_old.dat

if [[ $RESTART == True ]]
then
  sed -ri 's/(.)(ln_rstart)(.*)/   \2    = .true. /' namelist_cfg   
  sed -ri 's@(.)(cn_ocerst_indir)(.*)@   \2    =\"'$restart_files'\"@' namelist_cfg   
fi

#rm context_nemo.xml
sed '/def_nemo-ice/d' $xml_folder/context_nemo.xml | sed '/def_nemo-pisces/d' > context_nemo.xml

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

cp -s $exec_folder/$exec_name ./ || exit 1

if [[ $XIOS == True ]]
then
  cp -s $xios_exec_folder/$xios_exec_name ./ || exit 1
fi
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
#if [[ False == True ]]; then
if [[ $XIOS == True ]]; then
    XSERVER=true
else
    XSERVER=false
fi

sed -ri 's/(.*)(using_server)(.*)(true|false)(.*)/\1\2\3'$XSERVER'\5/' iodef.xml

# If extrae is used, create the function file for extrae.
if [[ $EXTRAE == True ]]
then
  cp $extrae_xml . || exit 1
  cp $function_file . || exit 1
  final_function_file=$function_file'_final'
  if [[ $(awk '{ print NF; exit}' $function_file) -eq 1 ]]
  then 
    nm $exec_name | grep -i " T " | grep -w -f $function_file | awk '{print $1" # "$3}' > $final_function_file
  elif [[ $(awk '{ print NF; exit}' $function_file) -eq 3  ]]
  then 
    function_file_tmp=$function_file'_tmp'
    awk '{print $3}' $function_file >  $function_file_tmp
    nm $exec_name | grep -i " T " | grep -w -f $function_file_tmp | awk '{print $1" # "$3}' > $final_function_file
    rm $function_file_tmp
  else
    echo "Wrong format in function file \nAborting."
    exit
  fi  

  sed 's@./extrae_functions_for_xml.txt@'$final_function_file'@' $extrae_xml > ./`basename $extrae_xml`
  extrae_xml=`basename $extrae_xml`
  
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

if [[ $XIOS == True ]] 
then
    if [[ $EXTRAE == True ]]
  then
    XIOS_EXEC="-np $XIOS_PROC ./$trace ./xios_server.exe : "
  else
    XIOS_EXEC="-np $XIOS_PROC  ./xios_server.exe : "
  fi
fi
# Launch command
if [[ $SCOREP == True ]]
then
  EXEC="time mpirun $XIOS_EXEC -np $NEMO_PROC ./$exec_name"
fi

if [[ $EXTRAE == True ]]
then 
  EXEC="time mpirun $XIOS_EXEC -np $NEMO_PROC ./$trace ./$exec_name" 
else
  if [[ $DDT == True ]] 
  then 
    module load DDT/18.2 
    EXEC="ddt --connect mpirun $XIOS_EXEC -np $NEMO_PROC ./$exec_name"
  else
    EXEC="time mpirun $XIOS_EXEC -np $NEMO_PROC ./$exec_name"
  fi 
fi
   
# Actual execution
eval $EXEC
   
