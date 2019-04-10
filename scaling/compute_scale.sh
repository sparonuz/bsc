#!/bin/bash
out_file='pts.txt'
cat /dev/null > $out_file
for NOP in `seq 48 48 576`
do
  NEMO_PROC=$((NOP/48*46))
  folder=eOrca025_opt_$NEMO_PROC
  time_spent=($(cat $folder/steps.timing  | awk '{print $2}'))
  echo  $NEMO_PROC " " `echo "${time_spent[-1]} - ${time_spent[0]}" | bc -l` >> $out_file
done

python plot.py 
