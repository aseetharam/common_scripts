#!/bin/bash
rm cmds
pre=$(pwd)
for file in trinity_all.part-???.fasta; do
num=$(echo ${file%.*}| cut -d "-" -f 2);
echo "blastx -query ${file} -db ${pre}/DATABASE/uniref90.fasta -num_threads 4 -max_target_seqs 1 -outfmt 6 > uniref90.blastx.outfmt6.${num}" >> cmds
done

split -d -l 8 cmds blast_cmds_

for file in blast_cmds_*; do
num=$(echo ${file} | cut -d "_" -f 3);
cat <<JOBHEAD > blast_${num}.sub
#!/bin/bash
#PBS -l vmem=256Gb,pmem=8Gb,mem=256Gb
#PBS -l nodes=1:ppn=32:ib
#PBS -l walltime=48:00:00
#PBS -N blast_${num}
#PBS -o \${PBS_JOBNAME}.o\${PBS_JOBID} -e \${PBS_JOBNAME}.e\${PBS_JOBID}
#PBS -m ae -M arnstrm@gmail.com
cd \$PBS_O_WORKDIR
ulimit -s unlimited
chmod g+rw \${PBS_JOBNAME}.[eo]\${PBS_JOBID}
module use /data004/software/GIF/modules
module load ncbi-blast
module load parallel
parallel <<EOF
JOBHEAD
cat ${file} >> blast_${num}.sub
echo "EOF" >> blast_${num}.sub
echo "qstat -f \"\$PBS_JOBID\"" >>  blast_${num}.sub
done
