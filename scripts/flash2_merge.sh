#!/bin/bash 

module load flash2 
srun --cpus-per-task=2 --time=00:30:00 xargs -a anaughton_run_accessions.txt -n 1 -I{} flash2 --threads=2 -z \
--output-directory ../data/sra_fastq/merged_pairs/ --output-prefix {}.flash --max-overlap 120 ../data/sra_fastq/input/{}_1.fastq.gz \
../data/sra_fastq/input/{}_2.fastq.gz 2>&1 | tee -a anaughton_flash2.log
