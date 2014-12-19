#!/bin/bash
# quick check for job completion
# Arun Seetharam 25 April, 2014
for file in $(find . -name "*o*.hpc5"); do
pname=$(basename $file)
rtime=$(grep "TIME (hh:mm:ss)" ${file} | awk '{print $NF}')
echo -e "${pname}\t${rtime}"
done
