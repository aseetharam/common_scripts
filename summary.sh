#!/bin/sh
# reads stdin and prints summary statistics
# total, count, mean, median, min and max
# you can pipe this through scripts or redirect input <
# modified from http://unix.stackexchange.com/a/13779/27194
sort -n | awk '
  $1 ~ /^[0-9]*(\.[0-9]*)?$/ {
    a[c++] = $1;
    sum += $1;
  }
  END {
    ave = sum / c;
    if( (c % 2) == 1 ) {
      median = a[ int(c/2) ];
    } else {
      median = ( a[c/2] + a[c/2-1] ) / 2;
    }
    OFS="\t";
    { printf ("Total:\t""%'"'"'d\n", sum)}
    { printf ("Count:\t""%'"'"'d\n", c)}
    { printf ("Mean:\t""%'"'"'d\n", ave)}
    { printf ("Median:\t""%'"'"'d\n", median)}
    { printf ("Min:\t""%'"'"'d\n", a[0])}
    { printf ("Max:\t""%'"'"'d\n", a[c-1])}
  }
'
