#!/bin/bash
module load gmap

export GMAPDB=/home/arnstrm/arnstrm/GMAPDB
DB_NAME=""GRCm38.78_musmus""
FILE1="$1"
FILE2=$(echo ${FILE1} |sed 's/_R1_/_R2_/g')
OUTFILE=$(basename ${FILE1} | sed 's/.fastq.gz$//g')
# Note: "-N" option for detecting novel splice sites, remove if not needed (0=OFF; 1=ON)
gsnap -d ${DB_NAME} -t 32 -B 5 -m 5 -N 1 --gunzip --fails-as-input --input-buffer-size=1000000 --output-buffer-size=1000000 -A sam --split-output=${DB_NAME}_${OUTFILE} ${FILE1} ${FILE2}
