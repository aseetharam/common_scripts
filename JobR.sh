#!/bin/bash
blue=$(tput setaf 4)
green=$(tput setaf setaf 2)
normal=$(tput sgr0)
INPUT=$1
CPWD=$(pwd)

if [ $# -lt 1 ] ; then
printf "\n\n
\t ${blue}usage: JobR.sh <FILE> ${normal}\n
\t Reads the input file and creats a submission file for each line in a separate file
\t Does not change variable names or special characters
\t Previously used settings appear as defaults, can be changed based on needs.
\t Sub files also prints time stamps
\t eg:${blue}\n
\t sh JobR.sh jobfile ${normal}
\t creates jobfile_1.sub, jobfile_2.sub, .. jobfile_n.sub
\t where n = total number of lines in 'jobfile' \n\n"
exit 0
fi

ask()
{
  printf "%${2}s" "$3"
  read val
  if [ -z $val ]; then val=$4; fi
  eval $1="$val"
}
queue=standby
nodes=1
processors=8
walltime=4
lmodules=N
if [ -e ~/.jobqvars ]; then
. ~/.jobqvars
fi

flag=n
declare -a nctree

until [ $flag = y -o $flag = Y ]
do
  clear
  echo ""
  echo "          ---- Required Arguments ----"
  echo ""
  ask queue  51 "Queue name [$queue]: " $queue
  ask nodes  51 "Number of nodes [$nodes]: " $nodes
  ask processors    51 "Number of processors [$processors]: " $processors
  ask walltime    51 "Required walltime (int only) in hrs [$walltime]: " $walltime
  ask lmodules 51 "Load modules? (Y/N) [$lmodules]: " $lmodules
  if [ "$lmodules" = "y" -o "$lmodules" = "Y" ]; then
    ask nctrees 51 "Number of moudles to load: " $nctrees
    if [ $nctrees -gt 0 ]; then
      for ((i=0; i<$nctrees; i++))
      do
        ask nctree[i] 51 "module-- $i: " ${nctree[i]}
      done
    fi
    IFS=":"
    treespan=`echo "${nctree[*]}"`
  fi 
  # echo ""
  # echo "          ---- Script Section ----"
  # echo ""
  # echo -n "Enter Filename : "
  # read file

	# ls -1 $file 2> /dev/null |wc -l |while read test; do
	# echo ""
	# echo ""	
	# echo -e "${blue} \t\t$test matching files found ${normal}"
	# done
	# echo ""
  	# echo ""
  	# echo ""
  ask flag 24 "Commit data? (Y/N) [N]: " n
done

cat <<JOBQVARS > ~/.jobqvars
file=$file
queue=$queue
nodes=$nodes
processors=$processors
walltime=$walltime
lmodules=$lmodules
command=$command
JOBQVARS

cat <<JOBQHEAD > ~/.jobqhead
#!/bin/bash
#PBS -q $queue
#PBS -l walltime=$walltime:00:00
#PBS -l nodes=$nodes:ppn=$processors
#PBS -N ${1}
cd \$PBS_O_WORKDIR
starts=\$(date +"%s")
start=\$(date +"%r, %m-%d-%Y")
JOBQHEAD
if [ "$lmodules" = "y" -o "$lmodules" = "Y" ]; then
echo "module use /apps/group/bioinformatics/modules" >> ~/.jobqhead
for ((i=0; i<$nctrees; i++))
      do
echo module load ${nctree[i]} >> ~/.jobqhead
      done
fi
NUM=$(wc -l ${INPUT} |awk '{print $1}')
for ((i=1; i<=${NUM}; i++))
do
cat ~/.jobqhead > ${CPWD}/${INPUT}_${i}.sub
awk "NR==${i}" ${INPUT} >> ${CPWD}/${INPUT}_${i}.sub
cat <<TIMEC >> ${CPWD}/${INPUT}_${i}.sub
ends=\$(date +"%s")
end=\$(date +"%r, %m-%d-%Y")
diff=\$((\$ends-\$starts))
hours=\$((\$diff / 3600))
dif=\$((\$diff % 3600))
minutes=\$((\$dif / 60))
seconds=\$((\$dif % 60))
echo ""
printf "\t===========Time Stamp===========\n"
printf "\tStart\t:\$start\n\tEnd\t:\$end\n\tTime\t:%02d:%02d:%02d\n" "\$hours" "\$minutes" "\$seconds"
printf "\t================================\n"
echo ""
TIMEC
JOBN=("${JOBN[@]}" "${INPUT}_${i}.sub")
done
ask ready 24 "Submission files ready, submit now? (Y/N) [N] : " n
if [ "$ready" = "y" -o "$ready" = "Y" ]; then
for var in "${JOBN[@]}"
do
  qsub "${var}"
done
fi

