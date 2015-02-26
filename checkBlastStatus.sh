#!/bin/bash
# gives the blast run status (if run based on wiki method)
# simply run it as ./check_status.sh to print the table to stdout
echo -e "BLAST File\tTotal\tCompleted (hits found)";
for file in *.out; do
if [ -s "$file" ]
then
uniqhits=$(cut -f 1 "${file}" | sort | uniq | wc -l)
fastaseq=$(grep -c ">" "${file%.*}.fasta")
currentseq=$(tail -n 1 "$file" |cut -f 1)
currentnum=$(grep -n ">" ${file%.*}.fasta| grep -n "${currentseq}" | cut -f 1 -d ":")
echo -e "${file%.*}\t${fastaseq}\t${currentnum} (${uniqhits})";
else
fastaseq=$(grep -c ">" "${file%.*}.fasta")
echo -e "${file%.*}\t${fastaseq}\t0 (0)"
fi
done
