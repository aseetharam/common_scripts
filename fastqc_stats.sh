#!/bin/bash

for f in *_fastqc; do
name=$(grep "Filename" ${f}/fastqc_data.txt |cut -f 2)
#type=$(grep "File type" ${f}/fastqc_data.txt |cut -f 2)
#enc=$(grep "Encoding" ${f}/fastqc_data.txt | cut -f 2)
seq=$(grep "Total Sequences" ${f}/fastqc_data.txt | cut -f 2)
len=$(grep "Sequence length" ${f}/fastqc_data.txt | cut -f 2)
gc=$(grep "%GC" ${f}/fastqc_data.txt |grep -v "Base" | cut -f 2 )
echo -e "$name\t$len\t$seq\t$gc";
done

