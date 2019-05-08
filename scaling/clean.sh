if [[ $# -ne 1 ]] 
then
  echo -e "You need to provide a folder \nAborting"
  exit 1
fi
for i in $1/*
do
  if [[ -d $i ]] 
  then
    rm -rf ${i}*restart*
    rm -rf ${i}set-*
    rm  -f  ${i}*_grid_T*
    rm  -f  ${i}*_grid_U*
    rm  -f  ${i}*_grid_V*
    rm  -f  ${i}*_grid_W*
    rm  -f  ${i}*_scalar*
  fi
done
