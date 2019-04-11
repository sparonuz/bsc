#!/bin/bash
f_proc='f_proc.txt'
f_time_step='f_time.txt'
cat /dev/null > $f_proc
cat /dev/null > $f_time_step

for NOP in `seq 48 48 576`
do
  NEMO_PROC=$((NOP/48*46))
  folder=eOrca025_opt_$NEMO_PROC
  time_spent=($(cat $folder/steps.timing  | awk '{print $2}'))
  echo $NEMO_PROC >> $f_proc 
  echo ${time_spent[@]} >> $f_time_step
  #echo  $NEMO_PROC " " `echo "${time_spent[-1]} - ${time_spent[0]}" | bc -l` >> $out_file
done
module load python
python plot.py  $f_proc $f_time_step

