#!/bin/bash
for f in gsnap_?; do
cd $f;
grep "^@" *3.concordant_uniq > header
cat *[0123].paired_uniq* >> $f.txt;
cat *concordant_uniq | grep -v "^@" >> $f.txt;
cat header $f.txt > ../$f.sam;
cd ..;
done
wc -l gsnap_?/gsnap_?.txt > alignment-stats.txt

