#!/bin/bash


for repetition in 1 2 3 
do
  f_proc='f_proc'$repetition'.txt'
  f_time_step='f_time'$repetition'.txt'
  f_array[$repetition]=$f_time_step
  f_proc_array[$repetition]=$f_proc
  cat /dev/null > $f_proc
  cat /dev/null > $f_time_step

  for NOP in `seq 48 48 2304`
  do

    NEMO_PROC=$((NOP/48*46))
    folder=eOrca025_opt_${repetition}_${NEMO_PROC}
    if [[ -d $folder ]]
    then 
      time_spent=($(cat $folder/steps.timing  | awk '{print $2}'))
      echo $NEMO_PROC >> $f_proc 
      echo ${time_spent[@]} >> $f_time_step
    fi
  done
done
echo ${f_proc_array[@]} ${f_array[@]}
module load python
python plot.py  ${f_proc_array[@]} ${f_array[@]}

