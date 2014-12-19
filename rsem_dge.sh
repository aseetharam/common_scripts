#!/bin/bash
# Runs the DGE once coutns table is generated
# you may have to run this on both isoforms.counts and genes.counts
# depending on your needs.
module use /data004/software/GIF/modules
module load trinity/r20140717
module load rsem
module load samtools
module load R
export PERL5LIB=/home/arnstrm/perl5/lib/perl5/x86_64-linux-thread-multi
progdir="/data004/software/GIF/packages/trinity/r20140717/Analysis/DifferentialExpression"
input="$1"
outdir=$(basename ${input%.*})
${progdir}/run_DE_analysis.pl \
   --matrix ${input} \
   --method DESeq2 \
   --samples_file conditions.txt \
   --output ${outdir}
