#!/bin/bash
#SBATCH --partition=fast             # long, fast, etc.
#SBATCH --ntasks=1                   # nb of *tasks* to be run in // (usually 1), this task can be multithreaded (see cpus-per-task)
#SBATCH --nodes=1                    # nb of nodes to reserve for each task (usually 1)
#SBATCH --cpus-per-task=16            # nb of cpu (in fact cores) to reserve for each task /!\ job killed if commands below use more cores
#SBATCH --mem=80GB                  # amount of RAM to reserve for the tasks /!\ job killed if commands below use more RAM
#SBATCH --time=0-01:00               # maximal wall clock duration (D-HH:MM) /!\ job killed if commands below take more time than reservation
#SBATCH -o ./outputs/slurm.%A.%a.out   # standard output (STDOUT) redirected to these files (with Job ID and array ID in file names)
#SBATCH -e ./outputs/slurm.%A.%a.err   # standard error  (STDERR) redirected to these files (with Job ID and array ID in file names)
# /!\ Note that the ./outputs/ dir above needs to exist in the dir where script is submitted **prior** to submitting this script
#SBATCH --array=1-8                # 1-N: clone this script in an array of N tasks: $SLURM_ARRAY_TASK_ID will take the value of 1,2,...,N
#SBATCH --job-name=kraken2_bracken_array        # name of the task as displayed in squeue & sacc, also encouraged as srun optional parameter
#SBATCH --mail-type END              # when to send an email notiification (END = when the whole sbatch array is finished)
#SBATCH --mail-user aonghus.naughton@ki.se 

echo "START $(date)"

module load kraken2 bracken 

datadir=/shared/home/anaughton/aonghus_medbioinfo/MedBioinfo/data/sra_fastq
work_dir=/shared/home/anaughton/aonghus_medbioinfo/MedBioinfo/analyses/kraken2
accnum_file="/shared/home/anaughton/aonghus_medbioinfo/MedBioinfo/analyses/anaughton_run_accessions.txt"
db=/shared/projects/2314_medbioinfo/kraken2/arch_bact_vir_hum_protoz_fung/

# this extracts the item number $SLURM_ARRAY_TASK_ID from the file of accnums
accnum=$(sed -n "$SLURM_ARRAY_TASK_ID"p ${accnum_file})
input_file1="${datadir}/${accnum}_1.fastq.gz"
input_file2="${datadir}/${accnum}_2.fastq.gz"

srun --job-name=${accnum} echo "file 1 = ${input_file1}  file 2 = ${input_file2}"   