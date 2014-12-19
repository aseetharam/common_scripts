#!/bin/bash
# this is optimized to run on 32 procs: spliting input to 16 peices, 2 procs per peice

## MODULES
module use /data004/software/GIF/modules
module load parallel
module load bowtie2

## PATHS
export INDEXDB=/home/arnstrm/arnstrm/GMAPDB
#DB_NAME="zeamays_b73_agp3.22"
#DB_NAME="masurca_C100_til01_unmapped_b73"
DB_NAME=Physo3_AssemblyScaffolds

FILE1="$1"
#FILE2=$(echo "$1" |sed 's/.fastq.gz$/2.fastq.gz/g')

OUTFILE=$(basename ${FILE1} | sed 's/.fastq$//g')

# no mixed is to print only  reads that align as pair in the results file
#bowtie2 --threads 14 --no-mixed --un-conc-gz ${OUTFILE}_un_conc.fq --un-gz  ${OUTFILE}_un.fq -x ${INDEXDB}/${DB_NAME} -1 ${FILE1} -2 ${FILE2} -S ${OUTFILE}.sam
echo "$OUTFILE now processing"
bowtie2 --threads 4 -x ${INDEXDB}/${DB_NAME} -U ${FILE1} -S ${OUTFILE}.sam


