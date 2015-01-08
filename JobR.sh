#!/bin/bash
INFILE="$1"
num=1
while read line; do
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
JOBHEAD
echo ${line} >> ${INFILE%%.*}_${num}.sub
echo "qstat -f \"\$PBS_JOBID\" | head" >> ${INFILE%%.*}_${num}.sub
((num++))
done<"${INFILE}"
