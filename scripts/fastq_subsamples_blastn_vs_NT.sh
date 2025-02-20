#!/bin/bash

#SBATCH --partition=fast             # long, fast, etc.
#SBATCH --ntasks=1                   # nb of *tasks* to be run in // (usually 1), this task can be multithreaded (see cpus-per-task)
#SBATCH --nodes=1                    # nb of nodes to reserve for each task (usually 1)
#SBATCH --cpus-per-task=4            # nb of cpu (in fact cores) to reserve for each task /!\ job killed if commands below use more cores
#SBATCH --mem=80GB                  # amount of RAM to reserve for the tasks /!\ job killed if commands below use more RAM
#SBATCH --time=0-01:00               # maximal wall clock duration (D-HH:MM) /!\ job killed if commands below take more time than reservation
#SBATCH -o ./outputs/slurm.%A.%a.out   # standard output (STDOUT) redirected to these files (with Job ID and array ID in file names)
#SBATCH -e ./outputs/slurm.%A.%a.err   # standard error  (STDERR) redirected to these files (with Job ID and array ID in file names)
# /!\ Note that the ./outputs/ dir above needs to exist in the dir where script is submitted **prior** to submitting this script
##SBATCH --array=1-8                # 1-N: clone this script in an array of N tasks: $SLURM_ARRAY_TASK_ID will take the value of 1,2,...,N
#SBATCH --job-name=blastn_10N        # name of the task as displayed in squeue & sacc, also encouraged as srun optional parameter
#SBATCH --mail-type END              # when to send an email notiification (END = when the whole sbatch array is finished)
#SBATCH --mail-user aonghus.naughton@ki.se 

#################################################################
# Preparing work (cd to working dir, get hold of input data, convert/un-compress input data when needed etc.)
workdir="/shared/home/anaughton/aonghus_medbioinfo/MedBioinfo/analyses/blastn"
datadir="/shared/home/anaughton/aonghus_medbioinfo/MedBioinfo/data/merged_pairs"
input_file_1="/shared/home/anaughton/aonghus_medbioinfo/MedBioinfo/data/merged_pairs/ERR6913138.flash.extenededFrags_10.fna"
output_file=${workdir}/fastq_subsample_blastn_vs_NT
db="/shared/bank/nt/current/blast/nt"

echo START: `date`

module load seqkit blast #as required

mkdir -p ${workdir}      # -p because it creates all required dir levels **and** doesn't throw an error if the dir exists :)
cd ${workdir}

#################################################################
# Start work
srun --job-name=blastn_10N blastn -num_threads ${SLURM_CPUS_PER_TASK} -query ${input_file_1} -db ${db} -evalue 1E-10 -max_target_seqs 5 -outfmt 6 -perc_identity 75 -out ${output_file}.out

#################################################################
# Clean up (eg delete temp files, compress output, recompress input etc)

echo END: `date`
