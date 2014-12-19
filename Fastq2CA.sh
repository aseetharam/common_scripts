#!/bin/bash
R1=$2
R2=$3
LB=$1
OUTFILE=$(basename ${R1} | sed 's/_1.fq//g');
fastqToCA -insertsize 500 100 -libraryname $LB -technology illumina -type sanger -innie -mates ${R1},${R2} > ${OUTFILE}.frg
