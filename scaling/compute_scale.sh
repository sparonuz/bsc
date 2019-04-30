#!/bin/bash


if [[ $# -ne 1 ]]
then
  echo -e "You need to provide the experiment name \nAborting"
  exit 1
fi

experiment=$1
rep_id=1
for repetition in OCE_1 OCE_2 OCE_3 # ICE 
do
  if [[ `ls | grep $experiment"_"$repetition | wc -l` -eq 0 ]] 
  then
    echo -e "No repetition n "${experiment}"_"$repetition" found.\nAborting" 
    exit 1
  else
    i_experiment=(`ls -v | grep $experiment"_"$repetition`)
  fi 
 
  f_proc='f_proc'$repetition'.txt'
  f_time_step='f_time'$repetition'.txt'
  f_array[$rep_id]=$f_time_step
  f_proc_array[$rep_id]=$f_proc
  cat /dev/null > $f_proc
  cat /dev/null > $f_time_step
  rep_id=$((rep_id+1))
  for folder in ${i_experiment[@]} 
  do
    echo $folder |  awk -F_ '{print $NF}'   >> $f_proc 
    #echo $folder |  cut -d _ -f 3  >> $f_proc 
    time_spent=($(cat $folder/steps.timing  | awk '{print $2}'))
    echo ${time_spent[@]} >> $f_time_step
  done
done
module load python
python plot.py  ${f_proc_array[@]} ${f_array[@]}

