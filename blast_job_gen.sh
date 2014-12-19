#!/bin/bash
database="/home/severin/GIF_1/scripts/BLAST/DB/NR/nr"
rm cmds.txt
for file in Trinity_TIL01.part-???.fasta; do
  outfile=$(echo ${file%.*})
  num=$(echo ${file%.*} | cut -d "-" -f 2);
  echo "blastx -query "${file}" -db "${database}" -out "${outfile}".out -evalue 1e-20 -num_threads 1 -max_target_seqs 1 -outfmt \"6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore staxids\"" >> cmds.txt
done
split -d -l 32 cmds.txt blast_cmds_
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
echo "################ STATS ##################"
SSECS=\$(date +"%s")
echo \${SSECS}
START=\$(date +"%r, %m-%d-%Y")
echo -e "Host\t\t: \$(hostname)"
echo -e "Processors\t: \$(wc -l < \$PBS_NODEFILE)"
echo -e "Nodes\t\t: \$(uniq \$PBS_NODEFILE | wc -l)"
echo -e "Total memory\t: \$(free | grep Mem | awk '{print \$2/1048576}' OFMT="%2.2f") Gb"
echo -e "Free memory\t: \$(free | grep Mem | awk '{print \$4/1048576}' OFMT="%2.2f") Gb"
echo -e "Directory\t: \$(pwd)"
chmod g+rw \${PBS_JOBNAME}.[eo]\${PBS_JOBID}
echo "#########################################"
module use /data004/software/GIF/modules
module load ncbi-blast
module load parallel
parallel --jobs 32 <<ALLCMD
JOBHEAD
cat ${file} >> blast_${num}.sub
echo "ALLCMD" >> blast_${num}.sub
cat <<JOBTAIL >> blast_${num}.sub
echo "############# TIME STAMP ################"
DIFF=\$((\`date +"%s"\`-\${SSECS}))
printf "Start\t\t:\${START}\nEnd\t\t:\$(date +"%r, %m-%d-%Y")\nTIME (hh:mm:ss)\t:%02d:%02d:%02d\n" "\$((${DIFF}/3600))" "\$(((DIFF%3600)/60))" "\$(((DIFF%3600)%60))"
echo "#########################################"
JOBTAIL
done
