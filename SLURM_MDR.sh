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

# general format submission script. change flags as you want
eval "$(/smithlab/opt/anaconda/bin/conda shell.bash hook)"
conda activate pyrosetta2024.39_py3.12
#source ~/.bashrc
#conda activate pyrosetta

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
#python mdr.py -n 28Jan --soft-rep --block-size 10 --num-files $NUM_FILES --debug
#python mdr.py -n 5Feb --soft-rep --block-size 10 --num-files $NUM_FILES --fatal
#python mdr.py -n 4Mar --hard-rep --block-size 10 --num-files $NUM_FILES --fatal
#python mdr.py -n 5Mar --soft-rep --minimize --block-size 10 --num-files $NUM_FILES --fatal
#python mdr.py -n 5Mar --block-size 10 --num-files $NUM_FILES --fatal
#python mdr.py -n 6Mar --block-size 10 --num-files $NUM_FILES --fatal
#python mdr.py -n 6Mar --minimize --soft-rep --block-size 10 --num-files $NUM_FILES --fatal
#python mdr.py -n 6Mar --block-size 10 --num-files $NUM_FILES --fatal
#python mdr.py -n 6Mar --soft-rep --block-size 10 --num-files $NUM_FILES --fatal
#python mdr.py -n 8Mar --soft-rep --minimize --block-size 10 --num-files $NUM_FILES --fatal
#python mdr.py -n 9Mar --soft-rep --minimize --block-size 10 --num-files $NUM_FILES --fatal
#python mdr.py -n 9Mar --minimize --block-size --num-files $NUM_FILES --fatal
#python mdr.py -n 10Mar --minimize --block-size 5 --num-files $NUM_FILES --fatal 
#python mdr.py -n 10Mar --soft-rep --minimze --block-size 5 --num-files $NUM_FILES --fatal
#python mdr.py -n 11Mar --minimize --block-size 5 --num-files $NUM_FILES --fatal  
#python mdr.py -n 12Mar --block-size 10 --num-files $NUM_FILES --fatal
##python mdr.py -n 12Mar --block-size 10 --soft-rep --num-files $NUM_FILES --fatal
#python mdr.py -n 12Mar --block-size 10 --minimize --num-files $NUM_FILES --fatal
#python mdr.py -n 12Mar --block-size 10 --minimize --num-files $NUM_FILES --fatal
#python mdr.py -n bcov_v3_r3_ems_3hC_436_0002_000000017_0001_0001_47_64_H_.._ems_p1-15H-GBL-16H-GABBL-16H_0382_0001_0001_0001_0001_0001_0001_0001_0001__hardrep__min__5_ --block-size 5 --minimize --num-files $NUM_FILES --fatal
python mdr.py -n bcov_v3_r3_ems_3hC_436_0002_000000017_0001_0001_47_64_H_.._ems_p1-15H-GBL-16H-GABBL-16H_0382_0001_0001_0001_0001_0001_0001_0001_0001__hardrep__nomin__15_ --block-size 5 --num-files $NUM_FILES --fatal

