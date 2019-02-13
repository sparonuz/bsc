#!/bin/bash
#SBATCH -J EC-EARTH_merge
#SBATCH -o ./merge_%j.out
#SBATCH -e ./merge_%j.err
#SBATCH --ntasks=48
#SBATCH --cpus-per-task=12
#SBATCH --qos=debug
#SBATCH -t 02:00:00

module purge
module load gcc/7.2.0
module load impi/2017.4
module load EXTRAE/3.5.2

cd $SLURM_SUBMIT_DIR

mpirun -env TMPDIR /gpfs/scratch/bsc32/bsc32402/tmp ${EXTRAE_HOME}/bin/mpimpi2prv -f TRACE.mpits -o nemo.prv -maxmem 24576

exit
