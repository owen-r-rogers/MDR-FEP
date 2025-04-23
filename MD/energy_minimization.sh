#!/bin/bash
#SBATCH --output=out_prep.log
##SBATCH --mail-type=END
##SBATCH --mail-user=your@email.com
#SBATCH --job-name=mp_em
#SBATCH --ntasks=1
#SBATCH --mem-per-gpu=7168
#SBATCH --gres=gpu:1
# amber128 (5 nodes: Tesla K20m)
##SBATCH --partition=amber128
##SBATCH --cpus-per-gpu=8
# test/exx96
#SBATCH --partition=test,exx96
#SBATCH --cpus-per-gpu=12

module purge

echo $1

if [ "$1" = "2021" ]; then
        source /smithlab/opt/gromacs/GMXRC2021
else
        source /smithlab/opt/gromacs/GMXRC2024
fi


export MDRUN=$(func.get_mdrun)
#module load hwloc

# GMXLIB selection
export GMXLIB=/path/to/amber99sb-ildn.ff

FORCE_FIELD=amber99sb-ildn
INPUT_PDB=$( ls -tr *.pdb | head )
BASE_NAME=`basename $INPUT_PDB .pdb`
MDP_DIR=/path/to/mdp

mkdir -p prep
cp $INPUT_PDB prep
cd prep

# Convert from PDB
echo "#### Converting from PDB ####"
(echo "1" ) | gmx pdb2gmx -f $INPUT_PDB -o conf.pdb -water tip3p -ignh -ff $FORCE_FIELD

# Make box
echo "#### Making BOX ####"
gmx editconf -f conf.pdb -o box.pdb -d 1.5 -c -bt dodecahedron

# Add water
echo "#### Adding water ####"
gmx solvate -cp box.pdb -cs spc216.gro -o water.pdb -p topol.top

# Add ions
echo "#### Adding 150 mM NaCl ####"
gmx grompp -f $MDP_DIR/ions.mdp -c water.pdb -o ions.tpr -maxwarn 3

echo SOL | gmx genion -s ions.tpr -o ions.pdb -p topol.top -pname NA -nname CL -conc 0.150 -neutral 

# rename backup files to more descriptive names
mv "#topol.top.1#" box.top
mv "#topol.top.2#" water.top

# create tpr for em
gmx grompp -f $MDP_DIR/em.mdp -c ions.pdb -o em.tpr -maxwarn 3

# run em
$MDRUN -v -deffnm em -c em.pdb
