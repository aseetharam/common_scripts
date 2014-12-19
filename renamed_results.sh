#!/bin/bash
if [ $# -lt 1 ] ; then
echo "renamed_results.sh <foldername to get the fullnames>"
exit 0
fi

pre=$(pwd)
outdir=$(dirname ${pre})
suffix="$1"

for folderPath in ${pre}/0?; do
   cd $folderPath;
   folder=$(basename "$folderPath");
   echo $folder
   for errC in ec_*; do
      filename=$(basename "$errC")
      extension="${filename##*.}"
      filename="${filename%%.*}"
      filename=$(echo "${filename}" |cut -d "_" -f 1-2)
      cat ${pre}/${folder}/${errC} >> ${outdir}/${filename}.${extension};
      cd ${outdir}
   done
done
for pbfastq in $(find /home/arnstrm/arnstrm/20140325_Bing_Rice_error_correction/02_H5_FASTQ -name "*${suffix}*.fastq"); do
      pbfastqName=$(basename "${pbfastq}" )
      newName="${pbfastqName%.*}";
      oldName=$(echo "${pbfastqName}" | cut -d "_" -f 2);
      rename ec_${oldName} ${newName}_err_corrected ec_${oldName}*;
done
