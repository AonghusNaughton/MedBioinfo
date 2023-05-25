#!/bin/bash

echo "script start: download and initial sequencing read quality control"
date

module load sra-tools
module load fastqc
module load flash2
module load bowtie2
module load seqkit
module load multiqc

source ~/.bashrc

sqlite3 -batch -csv -noheader /shared/projects/2314_medbioinfo/pascal/central_database/sample_collab.db \
"select run_accession
from sample_annot
spl left join sample2bioinformatician
s2b using(patient_code) where username='anaughton';" > ./anaughton_run_accessions.txt

mkdir ../data/sra_fastq

cat anaughton_run_accessions.txt | srun --cpus-per-task=1 --time=00:30:00 \
xargs fastq-dump --readids --gzip --outdir ../data/sra_fastq --split-3 --disable-multithreading

mkdir ../data/fastq_stats

# To get fastq stats
srun --time=00:10:00 --cpus-per-task=2 seqkit stats --threads 2 -a -T ../data/sra_fastq/*.fastq.gz > ../data/fastq_stats/sra_fastq_stats.txt

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

mkdir ../data/rmdup_output

srun --cpus-per-task=2 --time=00:10:00 xargs -a anaughton_run_accessions.txt -I{} \
zcat ../data/sra_fastq/{}_1.fastq.gz | seqkit rmdup -s -i -o ../data/rmdup_output/{}_1.clean.fq.gz \
-d ../data/rmdup/{}_1.duplicated.fq.gz -D ../data/rmdup/{}_1.duplicated.detail.txt

srun --cpus-per-task=2 --time=00:10:00 xargs -a anaughton_run_accessions.txt -I{} \
zcat ../data/sra_fastq/{}_2.fastq.gz | seqkit rmdup -s -i -o ../data/rmdup_output/{}_2.clean.fq.gz \
-d ../data/rmdup/{}_2.duplicated.fq.gz -D ../data/rmdup/{}_2.duplicated.detail.txt

# fastqc
mkdir ./fastqc
srun --cpus-per-task=2 --time=00:30:00 xargs -I{} -a anaughton_run_accessions.txt \
fastqc --outdir ./fastqc --threads 2 --noextract ../data/sra_fastq/{}_1.fastq.gz ../data/sra_fastq/{}_2.fastq.gz

# Merge paired-ends with flash2
mkdir ../data/merged_pairs
srun --cpus-per-task=2 --time=00:30:00 xargs -a anaughton_run_accessions.txt -n 1 -I{} flash2 --threads=2 -z \
--output-directory ../data/merged_pairs/ --output-prefix {}.flash --max-overlap 120 ../data/sra_fastq/{}_1.fastq.gz \
../data/sra_fastq/{}_2.fastq.gz 2>&1 | tee -a anaughton_flash2.log

# Download PhiX and SAR-CoV-2 reference genomes
mkdir ../data/reference_seqs
efetch -db nuccore -id NC_001422 -format fasta > ../data/reference_seqs/PhiX_NC_001422.fna
efetch -db nuccore -id NC_045512 -format fasta > ../data/reference_seqs/SARCoV2_NC_045512.fna

# Create indexed database for both
mkdir ../data/bowtie2_DBs
srun bowtie2-build -f ../data/reference_seqs/PhiX_NC_001422.fna ../data/bowtie2_DBs/PhiX_bowtie2_DB
srun bowtie2-build -f ../data/reference_seqs/SARCoV2_NC_045512.fna ../data/bowtie2_DBs/SARCoV2_bowtie2_DB

# Align merged reads to PhiX and SAR-CoV-2 genomes (Only essential step is to align to SAR-CoV, but including both so both saved for future reference)
mkdir bowtie
srun --cpus-per-task=8 bowtie2 -x ../data/bowtie2_DBs/PhiX_bowtie2_DB -U ../data/merged_pairs/ERR*.extendedFrags.fastq.gz \
-S bowtie/anaughton_merged2PhiX.sam --threads 8 --no-unal 2>&1 | tee bowtie/anaughton_bowtie_merged2PhiX.log

srun --cpus-per-task=8 bowtie2 -x ../data/bowtie2_DBs/SARCoV2_bowtie2_DB -U ../data/merged_pairs/ERR*.extendedFrags.fastq.gz \
-S bowtie/anaughton_merged2SARCoV2.sam --threads 8 --no-unal 2>&1 | tee bowtie/anaughton_bowtie_merged2SARCoV2.log

srun --time=00:10:00 --cpus-per-task=2 samtools sort bowtie/anaughton_merged2SARCoV2.sam -o bowtie/anaughton_merged2SARCoV2_sorted.bam --threads 2
srun --time=00:10:00 --cpus-per-task=2 samtools index bowtie/anaughton_merged2SARCoV2_sorted.bam --threads 2

srun multiqc --force --title "anaughton sample sub-set" ../data/merged_pairs/ ./fastqc/ ./anaughton_flash2.log ./bowtie/

date
echo "script end."
