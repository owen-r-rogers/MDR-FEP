#!/bin/bash
#SBATCH --job-name=ALL-GRID-SEARCH
#SBATCH --output=AGS_%a.log
#SBATCH --error=AGS_%a.err
#SBATCH --array=0-3
#SBATCH --cpus-per-task=1
#SBATCH --tasks-per-node=1
#SBATCH --partition=hp12,tinymem,mw128,mw256
#SBATCH --nodes=1
#SBATCH --mem=4G

# general format submission script. change flags as you want
eval "$(/smithlab/opt/anaconda/bin/conda shell.bash hook)"
conda activate pyrosetta2024.39_py3.12

export ROSETTA3_DB=/smithlab/opt/anaconda/envs/pyrosetta2024.39_py3.12/lib/python3.12/site-packages/pyrosetta/database


python grid_search_all_proteins.py --experimental-data ssm_correlation_for_plotting.sc --beta-ub 0.15 --beta-step 0.0001

