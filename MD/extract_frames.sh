#!/bin/bash
#SBATCH --job-name=extract-frames
#SBATCH --ntasks 1
#SBATCH --mem=1G
#SBATCH --partition=exx96,test

# This script is for extracting a .pdb at each frame of the PBC-corrected production simulation.

echo $1

# Pass "2021" if you want GROMACS 2021, otherwise it will default to 2024
if [ "$1" = "2021" ]; then
        source /smithlab/opt/gromacs/GMXRC2021
else
        source /smithlab/opt/gromacs/GMXRC2024
fi

# Time of the MD run
TIME=1000

# extract frames and put into new directory
(echo 1) | gmx trjconv -s topol.tpr -f smooth.xtc -o frame.pdb -sep -tu ns -dt 1

mkdir frames

for i in $(seq 0 $TIME); do
	cd frames
	mv ../frame$i.pdb .
	cd ..
done
