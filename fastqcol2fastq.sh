#!/usr/bin/env bash
# fastqcol2fastq.sh - convert DArTseq FASTQCol files to FASTQ
#
# FASTQCol record (comma-separated):
#   count,<space-separated numeric Phred>,sequence,field4
# Field 1 = tag depth (unique tag collapsed from `count` reads).
# Field 4 = unknown, possibly a trim/adapter position (0 = none). Kept in the read header.
#
# Usage:
#   fastqcol2fastq.sh [-c] [-t] [-o outdir] file1.FASTQCOL.gz [file2 ...]
#   -c  collapsed: one FASTQ record per unique tag (default: expand by count)
#   -t  trim each read at field 4 when field 4 > 0 (UNVERIFIED semantics; off by default)
#   -o  output directory (default: current directory)
#
# Requires: bash 4+, awk (gawk 4+/mawk 1.3.4+), gzip or pigz.

set -euo pipefail

mode="expand"; trim=0; outdir="."
while getopts ":cto:h" opt; do
  case $opt in
    c) mode="collapsed" ;;
    t) trim=1 ;;
    o) outdir="$OPTARG" ;;
    h) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "Unknown option. Use -h." >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))
[[ $# -ge 1 ]] || { echo "No input files. Use -h." >&2; exit 1; }
mkdir -p "$outdir"

zip_cmd="gzip -c"; command -v pigz >/dev/null && zip_cmd="pigz -c -p ${SLURM_CPUS_PER_TASK:-4}"

for in in "$@"; do
  base=$(basename "$in"); base=${base%.gz}; base=${base%.FASTQCOL}; base=${base%.fastqcol}
  out="$outdir/${base}.fastq.gz"
  case $in in *.gz) reader="gzip -dc" ;; *) reader="cat" ;; esac

  $reader "$in" | LC_ALL=C awk -F',' -v mode="$mode" -v trim="$trim" -v id="$base" '
    { sub(/\r$/, "") }
    NF < 4 { bad++; next }
    {
      n = split($2, q, " ")
      L = length($3)
      if (n != L) { bad++; next }
      s = ""
      for (i = 1; i <= n; i++) s = s sprintf("%c", q[i] + 33)
      seq = $3
      if (trim && $4 > 0 && $4 <= L) { seq = substr(seq, 1, $4 - 1); s = substr(s, 1, $4 - 1) }
      if (length(seq) == 0) { bad++; next }
      tags++
      if (mode == "collapsed") {
        printf "@%s_t%d count=%d f4=%s\n%s\n+\n%s\n", id, NR, $1, $4, seq, s; reads++
      } else {
        for (r = 1; r <= $1; r++)
          printf "@%s_t%d_r%d f4=%s\n%s\n+\n%s\n", id, NR, r, $4, seq, s
        reads += $1
      }
    }
    END { printf "%s\ttags=%d\treads=%d\tskipped=%d\n", id, tags, reads, bad > "/dev/stderr" }
  ' | $zip_cmd > "$out"
done
