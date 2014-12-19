#!/bin/bash
# draws cluster maps once the DGE is done.
# run it form the genes.counts or isoforms.counts directory
# needs samples descriptions (conditions.txt) file
module use /data004/software/GIF/modules
module load trinity/r20140717
module load rsem
module load samtools
module load R
export PERL5LIB=/home/arnstrm/perl5/lib/perl5/x86_64-linux-thread-multi
progdir="/data004/software/GIF/packages/trinity/r20140717/Analysis/DifferentialExpression"
input="$1"
outdir=$(basename ${input%.*})
${progdir}/analyze_diff_expr.pl \
   --matrix ${input} \
   --samples ../conditions.txt \
   --max_genes_clust 50000 \
   -P 1e-3 \
   -C 2
