#!/bin/bash

module load fastqc

srun --cpus-per-task=2 --time=00:30:00 xargs -I{} -a anaughton_run_accessions.txt fastqc --outdir ./fastqc/ \
--threads 2 --noextract ../data/sra_fastq/input/{}_1.fastq.gz ../data/sra_fastq/input/{}_2.fastq.gz
