#!/bin/bash

cd ../data/sra_fastq
for f in *.gz
do
	filename="${f%.*.*}"
	srun --time=00:30:00 --cpus-per-task=4 \
	cat ${f} | seqkit rmdup -s -i -o ${filename}.clean.fq.gz \
	-d ${filename}.duplicated.fq.gz -D ${filename}.duplicated.detail.txt
done

cd ../../analyses
