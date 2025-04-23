#!/bin/bash
#SBATCH --job-name=MDR
#SBATCH --output=mdr_%a.log
#SBATCH --error=mdr_%a.err
#SBATCH --array=0-200
#SBATCH --cpus-per-task=1
#SBATCH --tasks-per-node=1
#SBATCH --partition=hp12,tinymem,mw128,mw256
#SBATCH --nodes=1
#SBATCH --mem=4G

eval "$(/smithlab/opt/anaconda/bin/conda shell.bash hook)"
conda activate pyrosetta2024.39_py3.12

export PDB_DIR="$(pwd)/input"
export RF_DIR="$(pwd)/resfiles"
export ROSETTA3_DB=/smithlab/opt/anaconda/envs/pyrosetta2024.39_py3.12/lib/python3.12/site-packages/pyrosetta/database

echo $SLURM_ARRAY_TASK_ID
echo $(pwd)
echo $PDB_DIR
echo $RF_DIR
echo $ROSETTA3_DB

# num_arrays = ((num_pdb_files) // block_size) + (num_pdb_files % block_size != 0)
NUM_FILES=$(ls ${PDB_DIR}/frame*.pdb | wc -l)

# soft-rep
python mdr.py -n mdrfep --block-size 5 --num-files $NUM_FILES --fatal
