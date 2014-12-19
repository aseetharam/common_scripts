#!/bin/bash
while read line
  do
if grep -q "^[0-9]" <<<${line}; then
org=$(echo $line  | cut -d "." -f 2 | sed -e 's/^[ \t]*//')
echo -en "$org\t"
fi
if grep -q "Chromosomes:" <<<${line}; then
chr=$(echo $line  | cut -d ":" -f 2 | sed -e 's/^[ \t]*//')
echo -en "$chr\t"
fi
if grep -q "Genome ID:" <<<${line}; then
gen=$(echo $line  | cut -d ":" -f 2 | sed -e 's/^[ \t]*//')
echo "$gen"
fi
done < $1

