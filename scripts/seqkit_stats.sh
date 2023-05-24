#!/bin/bash
module load seqkit
srun --time=00:10:00 --cpus-per-task=4 seqkit stats -a -T $1 > $2
