#!/bin/bash
# This is a bash script that prints the mapping statistics from the GSNAP output.
# It needs the full path for the input fastq files (for counting reads) and full path for the output samfiles.
# prints output to stdout by default
# Note: It only works with SAM output and prints out in a docu wiki table format only!
# 03/17/2014
# Arun Seetharam <arnstrm@iastate.edu>

scriptName="${0##*/}"
outdir=$(pwd)

function printUsage() {
    cat <<EOF

Synopsis

    $scriptName [-h | --help] [-f file name] path/to/fastq_dir path/to/samfiles_dir

Description

    This is a bash script that prints the mapping statistics from the GSNAP output in Doku-wiki table format
    It needs the full path for the input fastq files (for counting reads) and full path for the output samfiles.
    Prints output to stdout by default
    Note: It only works with SAM output and prints out in a docu wiki table format only!

    path/to/fastq_dir
        Full path to the directory containing FASTQ files
        It assumes files have *.fastq extension

    path/to/samfiles_dir
        Full path to the directory containing GSNAP output
        It assumes output are in SAM format and have deafult naming eg., *unpaired_uniq etc.,

    -f file name, --file=file_name
        File name to save the output, it writes to the file in directory where the script is executed
        If this option is not specified, it prints to stdout.

    -h, --help
        Brings up this help page

Author

    Arun Seetharam, Genome Informatics Facilty, Iowa State University
    arnstrm@iastate.edu
    17 March, 2014



EOF
}
if [ $# -lt 1 ] ; then
    printUsage
    exit 1
fi
while :
do
    case $1 in
        -h | --help | -\?)
            printUsage
            exit 0
            ;;
        -f | --file)
            outfile=$2
            shift 2
            ;;
        --file=*)
            file=${1#*=}
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            printf >&2 'WARNING: Unknown option (ignored): %s\n' "$1"
            shift
            ;;
        *)
            break
            ;;
    esac
done

if [[ -z "$outfile" ]]; then
    echo >&2 "outputs to STDOUT"
elif [[ ! -d "$@" ]]; then
    echo >&2 "Saving to $outfile"
    exec > >(tee ${outdir}/${outfile})
fi

READS="$1"
SAMFILES="$2"

echo -en "^ Filenames ^ Total Reads ^ "
ls ${SAMFILES}/*unpaired* | rev | cut -f 1 -d "_" | rev | sort | uniq | sed ':a;N;$!ba;s/\n/ ^ /g' | tr -d "\n";
echo " ^";
   for FILE in ${READS}/*.fastq; do
      LINES=$(wc -l ${FILE} | cut -d " " -f 1)
      COUNT=$(echo "$LINES / 4" | bc)
      FNAME=$(basename $FILE);
      BNAME=$(echo $FNAME |sed 's/.fastq$//g');
      echo -ne "^ ${FNAME} | ${COUNT} | "
      for SAM in ${SAMFILES}/${BNAME}*; do
         ALIGN=$(cut -f 1 ${SAM}|grep -v "@" | sort | uniq | wc -l)
         ALIGNP=$(echo "scale=2;(${ALIGN} * 100) / ${COUNT}" |bc)
         echo -en "${ALIGN} ($ALIGNP%) |"
      done
      echo "";
   done
