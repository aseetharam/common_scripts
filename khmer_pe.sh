#!/bin/bash

FILE1=$1
FILE2=$2
OUTNAME=$(basename $1 | sed 's/.1.fastq.gz//g')
hashsize=96e9
cutoff=10
ksize=20
numHashes=4

normalize-by-median.py -k $ksize -N $ksize -C $cutoff -x $numHashes --paired --report-to-file ${OUTNAME}.report -o ${OUTNAME} ${FILE1} ${FILE2};

