#!/bin/bash
# This is a bash script to delete all running jobs.
# 04/17/2014
# Arun Seetharam <arnstrm@iastate.edu>

scriptName="${0##*/}"
function deleteJobs () {

re='^[0-9]+$'
qstat -u ${USER} | sed 1d | \
while read line
do
  jobid=$(echo $line |cut -d "." -f 1);
      if  [[ $jobid =~ $re ]] ; then
      echo "qdel $jobid";
      fi
done

}

function printUsage () {
    cat <<EOF

Synopsis

    $scriptName [-h | --help]

Description

    This is a bash script that kills all the running jobs of the executing user
    It just asks for confirmation once, if true deletes ALL running jobs.

        -h, --help
        Brings up this help page

Author

    Arun Seetharam, Genome Informatics Facilty, Iowa State University
    arnstrm@iastate.edu
    06 April, 2014



EOF
}

while :
do
    case $1 in
        -h | --help | -\?)
            printUsage
            exit 0
            ;;
        -*)
            printf >&2 'WARNING: Unknown option : %s ... now exiting (try -h or --help) \n' "$1"
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

while true; do
    read -p "Do you want to kill all your running jobs? [Y/N] :" yn
    case $yn in
        [Yy]* )
		   deleteJobs
		   exit 0
		   ;;
        [Nn]* )
		   exit 0
		   ;;
        * ) echo "Please answer yes or no.";;
    esac
done

