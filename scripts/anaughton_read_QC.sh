#!/bin/bash
#SBATCH -p core
#SBATCH -n 1
#SBATCH --cpus-per-task 1
#SBATCH -t 5:00:00
#SBATCH -J aonghus_read_QC
#SBATCH -o out/%j.out
#SBATCH -e out/%j.err
#SBATCH --mail-type=FAIL

echo "script start: download and initial sequencing read quality control"
date 

sqlite3 -batch -csv -noheader /shared/projects/2314_medbioinfo/pascal/central_database/sample_collab.db "select run_accession from sample_annot spl left join sample2bioinformatician s2b using(patient_code) where username='anaughton';" > ./anaughton_run_accessions.txt

module load sra-tools

cat anaughton_run_accessions.txt | srun --cpus-per-task=1 --time=00:30:00 xargs fastq-dump --readids --gzip --outdir ../data/sra_fastq/input --split-3

# To count number of reads in the downloaded fastq files:
for i in `ls ../data/sra_fastq/input/*.fastq.gz`; do echo -n "$i: " ; echo $(zcat ${i} | wc -l)/4|bc; done

# To get fastq stats 
srun --time=00:10:00 --cpus-per-task=4 seqkit stats -a -T ../data/sra_fastq/input/*.fastq.gz > ../data/fastq_stats/sra_fastq_stats.txt

awk '{print$1" "$4" "$5}' ../data/fastq_stats/sra_fastq_stats.txt > ../data/fastq_stats/sra_fastq_stats_modified.txt

# Create txt file with number of reads and bases from values in meta data 
srun --time=00:10:00 --cpus-per-task=1 \
sqlite3 -csv -header \
/shared/projects/2314_medbioinfo/pascal/central_database/sample_collab.db \
"select run_accession, total_reads, total_reads / 2 as total_reads_split,
base_count, base_count / 2 as base_count_split  
from sample_annot 
outer left join sample2bioinformatician on 
sample_annot.patient_code = sample2bioinformatician.patient_code
where username = 'anaughton'" > ../data/fastq_stats/metadata_stats.txt

# Removes duplicated sequences and writes to new file + 
# lists them in seperate file 
cd ~/aonghus_medbioinfo/MedBioinfo/data/sra_fastq/input
for f in *.gz
do
	filename="${f%.*.*}"
	srun --time=00:30:00 --cpus-per-task=4 \
	zcat ${f} | seqkit rmdup -s -i -o ../output/${filename}.clean.fq.gz \
	-d ../output/${filename}.duplicated.fq.gz -D ../output/${filename}.duplicated.detail.txt
done

cd ~/aonghus_medbioinfo/MedBioinfo/analyses
echo -e "\nChecking for full adapter sequences: \n"
../scripts/check_adapters.sh AGATCGGAAGAGCACACGTCTGAACTCCAGTCA AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT
echo -e "\nChecking for shortened adapter sequences: \n"
../scripts/check_adapters.sh AGATCGGAAGAGCACACGTCTGA AGATCGGAAGAGCGTCGTGTAGG


	
date
echo "script end."
