#!/bin/bash
FILE1="$6"
FILE2="$5"
OUTPUT="$4"
LIBNAME="$2"
SAMPLE="$3"
LIBSIZE="$1"
java -jar /opt/picard-tools/latest/FastqToSam.jar \
  F1="${FILE1}" \
  F2="${FILE2}" \
  OUTPUT="${OUTPUT}" \
  READ_GROUP_NAME=CML247 \
  SAMPLE_NAME="${SAMPLE}" \
  LIBRARY_NAME="${LIBNAME}" \
  PLATFORM=illumina \
  PREDICTED_INSERT_SIZE="${LIBSIZE}" \
