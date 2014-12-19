#!/bin/bash

source /data004/software/GIF/packages/SMRT/2.2.0/install/smrtanalysis-2.2.0.133377/etc/setup.sh
FILE="$1"
OUT=$(echo basename $FILE | cut -d "_" -f 2);
SPEC="/home/arnstrm/arnstrm/20140325_Bing_Rice_error_correction/pacbio2.spec"
FRG="$2"
/data004/software/GIF/packages/SMRT/2.2.0/install/smrtanalysis-2.2.0.133377/analysis/bin/pacBioToCA -length 500 -partitions 200 -l ec_${OUT}.fastq -t 32 -s ${SPEC} -fastq ${FILE} ${FRG}
