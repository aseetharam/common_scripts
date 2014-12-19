#!/bin/bash
if [ $# -lt 1 ] ; then
        echo ""
        echo "usage: SRAfq2FASTQ.sh [fastq_file1] <fastq_file2> ..|| *.fastq"
        echo "converts SRA fastq to normal fastq"
        echo "First extra field 'SRAXXXXX' will be removed"
        echo ""
        exit 0
fi

filear=${@};
for i in ${filear[@]}
do
theword=$(head -n 1 $i | cut -d "." -f 1 | sed 's/@//g')
sed -e 's/^@'$theword'.\{4,6\}[ ]/@/' -e 's/^+'$theword'.*/+/1' $i > $i.cleaned
done


