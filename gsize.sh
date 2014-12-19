#!/bin/bash
file="$1"
#lines=$(zcat ${file} | wc -l)
size=$(zcat ${file} | wc -c)
#count=$(($lines / 4))
#echo -n -e "\t$i : "
echo -n "${file} :"
echo "${size}"  | \
sed -r '
  :L
  s=([0-9]+)([0-9]{3})=\1,\2=
  t L'

