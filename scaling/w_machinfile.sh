#!/bin/bash

hosts=(`scontrol show hostname`)

TOTAL_PPN=48
PROC_PER_NODE=46
TOTAL_NP=$((${#hosts[@]}*TOTAL_PPN))

cat /dev/null > machinefile
n_node=1
for n_node in `seq 0 $((${#hosts[@]}))`
do
#  echo ${hosts[$n_node]} >> machinefile
  for j in `seq 0 $((PROC_PER_NODE-1))`
  do
    echo -n ${hosts[$n_node]} " " >> machinefile
  done
  echo " ">> machinefile
done
