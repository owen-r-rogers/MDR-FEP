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
#SBATCH --mail-user=your@email.com

# This script is for running periodic boundary conditions (PBC) treatment on the completed production simulation.

echo $1

if [ "$1" = "2021" ]; then
	source /smithlab/opt/gromacs/GMXRC2021
else
	source /smithlab/opt/gromacs/GMXRC2024
fi

# fix atoms that jump across the box
(echo 1 ; echo 1) | gmx trjconv -s topol.tpr -f traj_comp.xtc -o nojump.pdb -pbc nojump -center -tu ps

# center the molecule
(echo 1 ; echo 1) | gmx trjconv -s topol.tpr -f nojump.pdb -pbc mol -center -o bind.xtc

# smooth the trajectory
(echo 4 ; echo 1) | gmx trjconv -s topol.tpr -f bind.xtc -o smooth.xtc -fit rot+trans

# dump the starting structure
(echo 1) | gmx trjconv -s topol.tpr -f smooth.xtc -o start.pdb -dump 0

# dump the average structure
(echo 1) | gmx rmsf -s topol.tpr -f smooth.xtc -ox xaver.pdb 
