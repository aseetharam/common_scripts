#!/bin/bash
export GMAPDB=/home/arnstrm/arnstrm/20140324_Bhattacharyya_fusarium_RNAseq/01_DATA/E_GSNAPdb
DB_NAME="psojae"
INPUT_FILE="$1"
OUTFILE=$(basename $INPUT_FILE | sed 's/.fastq$//g')

gsnap -d ${DB_NAME} -t 2 -B 4 -m 3 -N 1 --input-buffer-size=1000000 --output-buffer-size=1000000 -A sam --split-output=${OUTFILE} ${INPUT_FILE}
