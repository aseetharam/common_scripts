#!/bin/bash
blue=$(tput setaf 4)
green=$(tput setaf setaf 2)
normal=$(tput sgr0)

if [ $# -lt 1 ] ; then
	echo ""
	echo ""
	echo "usage: jobq.sh <FILE> "
	echo ""
	echo "FILE should contain code/command(s) that you want to perform for each submission file"
	echo "You can refer \$input for input file and \$output for output file in your code/command(s)"
	echo "eg. if you include the following statement in your FILE:"
	echo "fastqc \$input > \$output"
	echo "it will create multiple submission files substituting variable information with all the"
	echo "matching files you provide."
	echo ""
	echo ""
	echo ""
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
  echo "          ---- PBS/Torque Section ----"
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
  echo ""
  echo "          ---- Script Section ----"
  echo ""
  echo -n "Enter Filename(s) [eg. test.txt or *.txt] : "
  read file

	ls -1 $file 2> /dev/null |wc -l |while read test; do
	echo ""
	echo ""	
	echo -e "${blue} \t\t$test matching files found ${normal}"
	done
	echo ""
  	echo ""
  	echo ""
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
for input in $file; do
output=`echo "$input"|sed 's/.\{4\}$//'`
cat ~/.jobqhead > $output.sub
sed -i "4a \
#PBS -N $output" $output.sub
if [ "$1" == "" ]; then
cat <<CODE >> $output.sub
Your command for each file here $f 
CODE
else
cat $1 | sed -e "s/\$input/`eval "echo '\$input'"`/g" | sed -e "s/\$output/`eval "echo '\$output'"`/g" >> $output.sub
(cat <<- TIMEC
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
) >> $output.sub
fi
done
ask ready 24 "Submission files ready, submit now? (Y/N) [N] : " n
if [ "$ready" = "y" -o "$ready" = "Y" ]; then
for sub in *.sub; do
qsub $sub;
done
fi

