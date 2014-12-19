#!/bin/bash
infile="$1"
#gunzip ${infile}
module load python
pwd=$(pwd)
outfile=$(echo ${infile} | sed 's/.fastq.gz$//g')
extract-paired-reads.py ${outfile}.fastq
split-paired-reads.py ${outfile}.fastq.pe
gzip *.pe
