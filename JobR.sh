#!/bin/bash
# Script to generate PBS sub files reading a command file
# 01/26/2015
# Arun Seetharam <arnstrm@iastate.edu>

function printUsage () {
    cat <<EOF

Synopsis

    $scriptName [-h | --help] <Number of commands per file> <commands_file>

Description

    This is a bash script that generates the sub file for each line/lines reading the command file
    The submission file is formatted to run on the Lightning3 with 48 hours walltime on default queue.
	The output will be named with the commands_file name along with the number suffix.

        -h, --help
        Brings up this help page

	<Number of commands per file>
	Integer value that represnets the number of lines that needs to be put in each submission file

    <commands_file>
    File with commands. Each line should be a independent job that should not have any variables.
    Eg., "sh bash_script.sh file1;" as first line, "sh bash_script.sh file2;" as second line and so on
	makes a good commands file. Note that the lines should end with colon (;). 

Author

    Arun Seetharam, Genome Informatics Facilty, Iowa State University
    arnstrm@iastate.edu
    26 January, 2015


EOF
}
if [ $# -lt 2 ] ; then
        printUsage
        exit 0
fi


LINES="$1"
INFILE="$2"



function readlines () {
    local N="$1"
    local line
    local rc="1"
    for i in $(seq 1 $N); do
        read line
        if [ $? -eq 0 ]; then
            echo "$line\n"
            rc="0"
        else
            break
        fi
    done
    return $rc
}
num=1
while chunk=$(readlines ${LINES}); do
cat <<JOBHEAD > ${INFILE%%.*}_${num}.sub
#!/bin/bash
#PBS -l vmem=256Gb,pmem=8Gb,mem=256Gb
#PBS -l nodes=1:ppn=32:ib
#PBS -l walltime=48:00:00
#PBS -N ${INFILE%%.*}_${num}
#PBS -o \${PBS_JOBNAME}.o\${PBS_JOBID} -e \${PBS_JOBNAME}.e\${PBS_JOBID}
#PBS -m ae -M arnstrm@gmail.com
cd \$PBS_O_WORKDIR
ulimit -s unlimited
chmod g+rw \${PBS_JOBNAME}.[eo]\${PBS_JOBID}
module use /data004/software/GIF/modules
module load parallel
module load ncbi-blast
parallel <<FIL
JOBHEAD
echo -e "${chunk}" >> ${INFILE%%.*}_${num}.sub
echo -e "FIL\nqstat -f \"\$PBS_JOBID\" | head" >> ${INFILE%%.*}_${num}.sub
((num++))
done<"${INFILE}"
