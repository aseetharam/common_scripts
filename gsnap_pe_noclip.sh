#!/bin/bash
# this is optimized to run on 32 procs: spliting input to 16 peices, 2 procs per peice

## MODULES
module use /data004/software/GIF/modules
module load parallel
module load gmap/2014-06-10

## PATHS
export GMAPDB=/home/arnstrm/arnstrm/GMAPDB
#export GMAPDB=/home/arnstrm/arnstrm/20140304_Hufford_teosinte_TIL01/01_DATA/E_GSNAPdb
DB_NAME="masurca_seriola2_scf"

## VARIABLES
#DB_NAME="zeamays_b73"
FILE1="$1"
FILE2="$2"
OUTFILE=$(basename ${FILE1} | sed 's/_R1.fastq.gz$//g')

## COMMAND
parallel --jobs 4 \
  "gsnap \
--db=${DB_NAME} \
--part={}/4 \
--orientation=RF \
--batch=4 \
--nthreads=8 \
--expand-offsets=1 \
--max-mismatches=5.0 \
--terminal-threshold=100 \
--indel-penalty=1 \
--trim-mismatch-score=0 \
--gunzip \
--pairmax-dna=10000 \
--pairdev=500 \
--fails-as-input \
--input-buffer-size=1000000 \
--output-buffer-size=1000000 \
--format=sam \
--split-output=${DB_NAME}_${OUTFILE}.{} \
${FILE1} \
${FILE2} " \
::: {0..3}

## OPTIONS
#  --novelsplicing=1 \

