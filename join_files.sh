#!/bin/bash
if [ $# -lt 1 ] ; then
        echo ""
        echo "usage: join_files.sh [file1] [file2] ...|| files*"
        echo "merges multiple files based on first (common) field"
        echo "Note: filenames will be used as headers"
        echo ""
        exit 0
fi

files=${@};
echo -en "\t"
for file in ${files[@]}
do
echo -en "$file\t";
done
echo "";
awk '{arr[$1]=arr[$1]"\t"$2}END{for(i in arr)print i,arr[i]}' ${files[@]};

