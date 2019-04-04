#!/bin/bash
module purge
module load intel/2018.3
module load impi/2018.3
module list

PROC=4

use_extrae=TRUE
#use_extrae=FALSE

EXTRAE_HOME=/apps/BSCTOOLS/extrae/3.6.1/impi_2018_1/
#EXTRAE_HOME=/gpfs/projects/bsc32/cs_collaboration/extrae-3.6.1-uf-fix/install-impi-no-dladdr
#EXTRAE_HOME=/apps/BSCTOOLS/extrae/3.5.4/impi_2018_1
EXTRAE_XML=${EXTRAE_HOME}/share/example/MPI/extrae.xml

USER_LIB='-L/'${EXTRAE_HOME}'/lib -lmpitracef -lmpitrace'

cp $EXTRAE_HOME/include/extrae_module.f90 . || exit 1
cp $EXTRAE_XML . || exit 1

trace=trace.sh
 cat << EOF > $trace
  #!/bin/bash

  EXTRAE_HOME=$EXTRAE_HOME
  export EXTRAE_CONFIG_FILE=$EXTRAE_XML
  source \$EXTRAE_HOME/etc/extrae.sh

  export LD_PRELOAD=\${EXTRAE_HOME}/lib/libmpitracecf.so

  export LD_LIBRARY_PATH=\${EXTRAE_HOME}/lib/:\$LD_LIBRARY_PATH

  \$*
EOF
chmod 755 $trace

if [[ $use_extrae == TRUE ]]
then
  EXTRAE="-DEXTRAE"
  mpiifort -c extrae_module.f90 
fi

mpiifort -c -cpp $EXTRAE mpi_hello.f90 

if [[ $use_extrae == TRUE ]]
then
  mpiifort extrae_module.o mpi_hello.o -o mpi_hello_extrae ${USER_LIB}
  mpirun  -np $PROC ./$trace ./mpi_hello_extrae
else
  mpiifort  mpi_hello.o -o mpi_hello
  mpirun  -np $PROC ./mpi_hello
fi

