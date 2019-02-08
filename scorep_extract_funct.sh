#!/bin/bash

source /home/nct00/nct00004/bin/tools_x86_intel17.sh

#function 2 keep
fnc2Keep=USR

#discard if the time/visit time is less than
time_visit=10000.0

#discard if the number of visits is greater than #N
max_n_visit=1000000

#If this parameter is 0 show all the functions detected by scorep
show_all=1

if [ "$#" -lt 1 ]
then
    echo "Input file missing"
    echo "... aborting"
    exit 
elif [ "$#" -eq 2 ]
then
    w_txt=1
    #exe file name
    exe_name=$2
    if ! [ -e "$exe_name"  ]
    then
      echo $exe_name ": file not found"
      exit
    fi
    extrae_out_file=extrae_functions_for_xml.txt
else
    w_txt=0
fi

#binary input file generated by scorep
file_name=$1
if ! [ -e "$file_name"  ]
then
  echo $file_name ": file not found"
  exit
fi

#name of an appo .txt file
file_name_txt=$file_name'_txt'
file_name_txt_tmp=$file_name_txt'_tmp'

#generate the appo .txt file
scorep-score  -r $file_name > $file_name_txt

#discard header 
head_line=(`sed -n '/flt/=' $file_name_txt`)

#print function that will be instrumented  plus some other counters 
if [ $w_txt == 0 ] 
then 
  if [ $show_all == 1 ]
  then
    sed -n ''$head_line','$head_line'p;'$((head_line+6))',$p' $file_name_txt | \
    sed 's/,//g' | \
    awk '(($1 == "'${fnc2Keep}'" && $3 < '$max_n_visit' && $(NF-1) > '$time_visit') || ($1 =="flt")) {print $(NF-6), $(NF-4), $(NF-3), $(NF-2), $(NF-1), $NF}' | \
    column -t 
  else
    sed -n ''$head_line','$head_line'p;'$((head_line+6))',$p' $file_name_txt | \
    sed 's/,//g' | \
    awk '($1 == "'${fnc2Keep}'" || ($1 =="flt")) {print $(NF-6), $(NF-4), $(NF-3), $(NF-2), $(NF-1), $NF}' | \
    column -t

  fi 
  rm $file_name_txt
fi

#links the mangled name of the function to the address in the actual executable
if [ $w_txt == 1 ] 
then
  sed -n ''$((head_line+6))',$p' $file_name_txt | \
  sed 's/,//g' | \
  awk '(($1 == "'${fnc2Keep}'" && $3 < '$max_n_visit' && $(NF-1) > '$time_visit')) {print  $NF}'| \
  sed  's/\./_mp_/g' > $file_name_txt_tmp
  nm $exe_name | grep -i " T " | grep -w -f $file_name_txt_tmp | awk '{print $1" # "$3}' > $extrae_out_file

  n_lin_in=`wc -l < $file_name_txt_tmp`
  n_lin_out=`wc -l < $extrae_out_file`
  if [ $n_lin_in -gt $n_lin_out ]
  then
    echo -e "Not all function found in exe file ... check needed \nAborting"
  else
    echo -e "Found "$n_lin_in" functions to instrument. The output for extrae has been dumped to " $extrae_out_file "file. \nStop."
    rm $file_name_txt $file_name_txt_tmp
  fi
fi

