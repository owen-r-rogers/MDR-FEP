#!/bin/bash
#SBATCH --job-name=pbc_corr
#SBATCH --output=out_pbc.log
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem 2G
#SBATCH --partition=exx96
#SBATCH --mail-type=begin
#SBATCH --mail-type=end
#SBATCH --mail-type=fail
#SBATCH --mail-user=orogers@wesleyan.edu

echo "This script will fix PBC for the minibinder and the target protein, will remove waters. If you are using this script for analysis with one of the jupyter notebooks, should change the time step so that 25000 frames get output instead of 250."

echo $1

if [ "$1" = "2021" ]; then
	source /smithlab/opt/gromacs/GMXRC2021
else
	source /smithlab/opt/gromacs/GMXRC2024
fi

# fix no jump
(echo 1 ; echo 1) | gmx trjconv -s topol.tpr -f traj_comp.xtc -o nojump.pdb -pbc nojump -center -tu ps

# center
(echo 1 ; echo 1) | gmx trjconv -s topol.tpr -f nojump.pdb -pbc mol -center -o bind.xtc

# smooth
(echo 4 ; echo 1) | gmx trjconv -s topol.tpr -f bind.xtc -o smooth.xtc -fit rot+trans

# starting structure
(echo 1) | gmx trjconv -s topol.tpr -f smooth.xtc -o start.pdb -dump 0

# average structure
(echo 1) | gmx rmsf -s topol.tpr -f smooth.xtc -ox xaver.pdb 

