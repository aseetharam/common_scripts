#!/bin/bash

CDIR=${PWD##*/}
PILAST=$(echo ${CDIR} | cut -d "_" -f 2)
PROJNAME=$(echo ${CDIR} | cut -d "_" -f 3- )

for FILE in $(find . -name "*.o*.hpc5"); do
   EFILE=$(echo $FILE | sed 's/\.o/.e/1')
   CDATE=$(stat -c%y ${FILE} | cut -c1-10)
   START=$(sed -n '2p' ${FILE})
      if grep -q "TIME STAMP" ${FILE}; then
          END=$(ls --time-style='+%s' -l ${FILE} |cut -d " " -f 6)
          DIFF=$((${END}-${START}))
          DURATION=$(printf "%02d:%02d:%02d" "$((${DIFF}/3600))" "$(((DIFF%3600)/60))" "$(((DIFF%3600)%60))");
      else
          END=$(ls --time-style='+%s' -l ${EFILE} |cut -d " " -f 6)
          DIFF=$((${END}-${START}))
          DURATION=$(printf "%02d:%02d:%02d" "$((${DIFF}/3600))" "$(((DIFF%3600)/60))" "$(((DIFF%3600)%60))");
          MESSAGE=$(echo ", Job failed or walltime expired")
      fi
   PROCS=$(sed -n '4p' ${FILE} | rev | cut -d " " -f 1 | rev)
   NODES=$(sed -n '5p' ${FILE} | rev | cut -d " " -f 1 | rev)
   BNAME=$(basename ${FILE})
   JOBID=$(echo ${BNAME} | cut -d "." -f 2 | sed 's/^o//');
   JOBNAME=$(echo ${BNAME} | cut -d "." -f 1)
   echo -e "`date -d ${CDATE} +"%m-%d-%Y"`\tNA\t${PILAST}\tNA\t${DURATION}\t${PROCS}\t${NODES}\tNA\tNA\t${PROJNAME}\tJob:${JOBID}, ${JOBNAME}${MESSAGE}";
   unset MESSAGE
done
