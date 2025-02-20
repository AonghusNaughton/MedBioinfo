#!/bin/bash
#SBATCH --partition=fast             # long, fast, etc.
#SBATCH --ntasks=1                   # nb of *tasks* to be run in // (usually 1), this task can be multithreaded (see cpus-per-task)
#SBATCH --nodes=1                    # nb of nodes to reserve for each task (usually 1)
#SBATCH --cpus-per-task=1            # nb of cpu (in fact cores) to reserve for each task /!\ job killed if commands below use more cores
#SBATCH --mem=90GB                  # amount of RAM to reserve for the tasks /!\ job killed if commands below use more RAM
#SBATCH --time=0-01:00               # maximal wall clock duration (D-HH:MM) /!\ job killed if commands below take more time than reservation
#SBATCH -o ./outputs/slurm.%A.%a.out   # standard output (STDOUT) redirected to these files (with Job ID and array ID in file names)
#SBATCH -e ./outputs/slurm.%A.%a.err   # standard error  (STDERR) redirected to these files (with Job ID and array ID in file names)
# /!\ Note that the ./outputs/ dir above needs to exist in the dir where script is submitted **prior** to submitting this script
##SBATCH --array=1-8                # 1-N: clone this script in an array of N tasks: $SLURM_ARRAY_TASK_ID will take the value of 1,2,...,N
#SBATCH --job-name=kraken2_single        # name of the task as displayed in squeue & sacc, also encouraged as srun optional parameter
#SBATCH --mail-type END              # when to send an email notiification (END = when the whole sbatch array is finished)
#SBATCH --mail-user aonghus.naughton@ki.se 

echo "START $(date)"

module load kraken2 bracken 

data_directory=/shared/home/anaughton/aonghus_medbioinfo/MedBioinfo/data/sra_fastq
working_directory=/shared/home/anaughton/aonghus_medbioinfo/MedBioinfo/analyses/kraken2
input_file1=${data_directory}/${1}_1.fastq.gz
input_file2=${data_directory}/${1}_2.fastq.gz
output_file_kraken=${working_directory}/kraken2.${1}
output_file_bracken=${working_directory}/bracken.${1}
output_file_krona=${working_directory}/krona.${1}
db=/shared/projects/2314_medbioinfo/kraken2/arch_bact_vir_hum_protoz_fung/

srun --job-name=kraken2 --mem=90GB kraken2 --paired --db ${db} --output ${output_file_kraken}.out --report ${output_file_kraken}.report ${input_file1} ${input_file2} 

srun --job-name=bracken --mem=90GB bracken -d ${db} -i ${output_file_kraken}.report -o ${output_file_bracken}.out -w ${output_file_bracken}.report -r 50 -l S -t 5

srun --job-name=kreport2krona --mem=90GB /shared/projects/2314_medbioinfo/kraken2/KrakenTools/kreport2krona.py -r ${output_file_kraken}.report -o ${output_file_krona}.txt

srun --job-name=krona2html --mem=90GB /shared/projects/2314_medbioinfo/kraken2/bin/ktImportText ${output_file_krona}.txt 

echo "END $(date)"
