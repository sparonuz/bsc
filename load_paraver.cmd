#!/bin/bash

###############################################################################
#                   SIM a1md EXPERIMENT
###############################################################################
#
#SBATCH --qos=debug
#SBATCH -A bsc32
#
#
#
#SBATCH -n 48
#SBATCH -t 02:00:00
#SBATCH -J load_paraver
#SBATCH --x11=batch
#SBATCH -o paraver.out 
#SBATCH -e paraver.err
module load PARAVER
wxparaver
