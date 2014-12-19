#!/bin/bash
export GMAPDB=/home/arnstrm/arnstrm/20140304_Hufford_teosinte_TIL01/01_DATA/E_GSNAPdb
DB_NAME="zeamays"
FILE1="$1"
FILE2="$2"
OUTFILE=$(basename ${FILE1} | sed 's/1.fastq.gz$//g')
# Note: "-N" option for detecting novel splice sites, remove if not needed (0=OFF; 1=ON)
gsnap -d ${DB_NAME} -t 32 -B 5 -m 5 --gunzip --fails-as-input --input-buffer-size=1000000 --output-buffer-size=1000000 -A sam --split-output=${DB_NAME}_${OUTFILE} ${FILE1} ${FILE2}
