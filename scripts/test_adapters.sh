#!/bin/bash
srun --time=00:10:00 --cpus-per-task=4 xargs -I{} -a anaughton_run_accessions.txt seqkit locate -p $1 ../data/sra_fastq/input/{}_1.fastq.gz > ../data/sra_fastq/output/{}_1.adapters.txt

srun --time=00:10:00 --cpus-per-task xargs -I{} -a anaughton_run_accessions.txt seqkit locate -p $2 ../data/sra_fastq/input/{}_2.fastq.gz > ../data/sra_fastq/output/{}_2.adapters.txt
