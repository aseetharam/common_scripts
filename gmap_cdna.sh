#!/bin/bash
export GMAPDB=/home/arnstrm/arnstrm/GMAPDB
DB_NAME="masurca_TIL01"
FILE1="$1"
OUTFILE=$(basename ${FILE1} | sed 's/.fasta$//g')
gmap -d ${DB_NAME} -t 32 -B 5 -A -f samse --input-buffer-size=1000000 --output-buffer-size=1000000 ${FILE1} > ${OUTFILE}_se.sam
