#!/bin/bash
FILE="$1"
module load bayescan
mkdir -p ${FILE%%.*}
bayescan ${FILE} -od ${FILE%%.*} -threads 32 -n 1000000 -pr_odds 10000
