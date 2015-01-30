#!/bin/bash

CDIR=${PWD##*/}
PILAST=$(echo ${CDIR} | cut -d "_" -f 2)
PROJNAME=$(echo ${CDIR} | cut -d "_" -f 3- )

for FILE in $(find . -name "*.o*.hpc5"); do
   EFILE=$(echo $FILE | sed 's/\.o/.e/1')
   CDATE=$(stat -c%y ${FILE} | cut -c1-10)
   PROCTIME=$(grep "resources_used.cput"  ${FILE} | awk '{print $NF}')
   WALLTIME=$(grep "resources_used.walltime"  ${FILE} | awk '{print $NF}')
   JOBNAME=$(grep "Job_Name ="  ${FILE} | awk '{print $NF}')
   JOBID=$(grep "Job Id: "  ${FILE} | awk '{print $NF}')
   BNAME=$(basename ${FILE})
      if [ -z "${PROCTIME}" ]; then
	echo -n "";
      else
        echo -e "`date -d ${CDATE} +"%m-%d-%Y"`\tNA\t${PILAST}\tNA\t${PROCTIME}\tNA\t$NA\tNA\tNA\t${PROJNAME}\tJob:${JOBID}, ${JOBNAME}${MESSAGE}";
      fi
   unset MESSAGE
done
