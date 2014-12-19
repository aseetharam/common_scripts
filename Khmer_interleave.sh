#!/bin/bash
#variables
progdir2='/home/arnstrm/arnstrm/20140304_Hufford_teosinte_TIL01/07_KHMER/khmerEnv/bin'
pwd=$(pwd)
input1=$1
input2=$2
output=$(echo ${input1} | sed 's/_R1_paired.fq$//g')
#interleave
source ${progdir2}/activate
python ${progdir2}/interleave-reads.py -o ${output}_interleaved.fq ${input1} ${input2}
#compress
gzip -9 ${output}_interleaved_qc.fq
