#!/bin/bash
if [ $# -lt 1 ] ; then
        echo ""
        echo "usage: quedel.sh [qstat -u username output]"
        echo "deletes all job ids submitted by a user, needs the list of jobs saved as a file"
        echo "Note: run \"qstat -u username > file\" first"
        echo "and then run \"quedel.sh file\" next"
        echo ""
        exit 0
fi

FILE="$1"

while read line;
do

    if [ "$line" != "" ]; then
        jobid=$(echo $line |cut -d "." -f 1)
        qdel ${jobid};
    fi

done < ${FILE}

