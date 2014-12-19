#!/bin/bash
for samfile in *.sam; do
echo ${samfile};
grep -v -E "[[:digit:]]{7,15}N" ${samfile} > ${samfile%%.*}_edited.sam;
done

