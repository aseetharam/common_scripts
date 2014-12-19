#!/data004/software/GIF/packages/python/2.7.6/bin/python
from Bio import SeqIO
import sys
cmdargs = str(sys.argv)
for seq_record in SeqIO.parse(str(sys.argv[1]), "fasta"):
    output_line = '%s\t%i' % \
(seq_record.id, len(seq_record)) 
    print(output_line)
