module use /data004/software/GIF/modules
module load bwa
module load samtools

refgenome1="/home/arnstrm/arnstrm/20140710_Hufford_teosinte_TIL01/06_FRC/RAY_assembly.fasta"
refgenome2="/home/arnstrm/arnstrm/20140710_Hufford_teosinte_TIL01/06_FRC/ALLPATHS_assembly.fasta"
refgenome3="/home/arnstrm/arnstrm/20140710_Hufford_teosinte_TIL01/06_FRC/MaSuRCA_C100_assembly.fasta"

ref1=$(basename ${refgenome1} | cut -d "_" -f 1)
ref2=$(basename ${refgenome2} | cut -d "_" -f 1)
ref3=$(basename ${refgenome3} | cut -d "_" -f 1)


readA1="/home/arnstrm/arnstrm/20140710_Hufford_teosinte_TIL01/01_DATA/A_FULL/A_180bp/3510_3807_3510_N_TIP521_4_R1.fastq"
readB1="/home/arnstrm/arnstrm/20140710_Hufford_teosinte_TIL01/01_DATA/A_FULL/B_250bp/SRR447882N3_C1.fastq"
readC1="/home/arnstrm/arnstrm/20140710_Hufford_teosinte_TIL01/01_DATA/A_FULL/C_2000bp/471_3807_3653_N_TIP521.4_CGATGT_R1.fastq"
readD1="/home/arnstrm/arnstrm/20140710_Hufford_teosinte_TIL01/01_DATA/A_FULL/D_8000bp/run562.EAR123_L004_R1.fastq"

readA2=$(echo ${readA1} |sed 's/1.fastq$/2.fastq/g')
readB2=$(echo ${readB1} |sed 's/1.fastq$/2.fastq/g')
readC2=$(echo ${readC1} |sed 's/1.fastq$/2.fastq/g')
readD2=$(echo ${readD1} |sed 's/1.fastq$/2.fastq/g')

outnameA=$(echo ${readA1} |sed 's/_.1.fastq$//g')
outnameB=$(echo ${readB1} |sed 's/_.1.fastq$//g')
outnameC=$(echo ${readC1} |sed 's/_.1.fastq$//g')
outnameD=$(echo ${readD1} |sed 's/_.1.fastq$//g')

bwa mem -M -t 8 ${refgenome1} ${readA1} ${readA2} | samtools view -buS - | samtools sort - ${ref1}_${outnameA}.sorted
bwa mem -M -t 8 ${refgenome1} ${readB1} ${readB2} | samtools view -buS - | samtools sort - ${ref1}_${outnameB}.sorted
bwa mem -M -t 8 ${refgenome1} ${readC1} ${readC2} | samtools view -buS - | samtools sort - ${ref1}_${outnameC}.sorted
bwa mem -M -t 8 ${refgenome1} ${readD1} ${readD2} | samtools view -buS - | samtools sort - ${ref1}_${outnameD}.sorted

bwa mem -M -t 8 ${refgenome2} ${readA1} ${readA2} | samtools view -buS - | samtools sort - ${ref2}_${outnameA}.sorted
bwa mem -M -t 8 ${refgenome2} ${readB1} ${readB2} | samtools view -buS - | samtools sort - ${ref2}_${outnameB}.sorted
bwa mem -M -t 8 ${refgenome2} ${readC1} ${readC2} | samtools view -buS - | samtools sort - ${ref2}_${outnameC}.sorted
bwa mem -M -t 8 ${refgenome2} ${readD1} ${readD2} | samtools view -buS - | samtools sort - ${ref2}_${outnameD}.sorted

bwa mem -M -t 8 ${refgenome3} ${readA1} ${readA2} | samtools view -buS - | samtools sort - ${ref3}_${outnameA}.sorted
bwa mem -M -t 8 ${refgenome3} ${readB1} ${readB2} | samtools view -buS - | samtools sort - ${ref3}_${outnameB}.sorted
bwa mem -M -t 8 ${refgenome3} ${readC1} ${readC2} | samtools view -buS - | samtools sort - ${ref3}_${outnameC}.sorted
bwa mem -M -t 8 ${refgenome3} ${readD1} ${readD2} | samtools view -buS - | samtools sort - ${ref3}_${outnameD}.sorted

