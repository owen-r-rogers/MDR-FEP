#!/bin/bash
#SBATCH --output=quil.log
#SBATCH --ntasks=1
#SBATCH --mem-per-gpu=7168
#SBATCH --gres=gpu:1
#SBATCH --job-name=equilibration
# exx96 (11 nodes: GeForce RTX 2080 Super)
##SBATCH --partition=exx96
##SBATCH --cpus-per-gpu=12
# test (2 nodes: Quadro RTX 5000)
##SBATCH --partition=test
##SBATCH --cpus-per-gpu=12
# amber128 (1 node: GeForce GTX 1080 Ti)
##SBATCH --partition=amber128
##SBATCH --cpus-per-gpu=8
# mwgpu (5 nodes: Tesla K20m)
##SBATCH --partition=mwgpu
##SBATCH --cpus-per-gpu=8
# amber128/mwgpu
##SBATCH --partition=amber128,mwgpu
##SBATCH --cpus-per-gpu=8
# test/exx96
#SBATCH --partition=test,exx96
#SBATCH --cpus-per-gpu=12

echo "This script is for equilibration where every chain present (or ones you choose) are restrained, whereas equil_complex only restrains the target."

echo $1

if [ "$1" = "2021" ]; then
        source /smithlab/opt/gromacs/GMXRC2021
else
        source /smithlab/opt/gromacs/GMXRC2024
fi

export MDRUN=$(func.get_mdrun)
export MDRUN_FLAGS="-nt $SLURM_CPUS_PER_GPU -pin on -pinoffset $(($CUDA_VISIBLE_DEVICES*$SLURM_CPUS_PER_GPU)) -pinstride 1"

# GMXLIB selection
#export GMXLIB=~/research/2024Spring/GMXLIB/ROCKLIN/amber99sb-star-ildn-mut.ff/
export GMXLIB=~/3_GMXLIB/CAO/amber99sb-ildn.ff
MDP_DIR=~/3_GMXLIB/CAO/mdp
DIR=${1:-equil}

mkdir equil
cd equil


echo "##### NVT eq fc1000 ####"
(echo "2") | gmx genrestr -f ../prep/em.pdb -o posre.itp -fc 1000 1000 1000
gmx grompp -f $MDP_DIR/nvt.mdp -c ../prep/em.pdb -r ../prep/ions.pdb -p ../prep/topol.top -o nvt.tpr -po nvt.mdp -quiet
$MDRUN $MDRUN_FLAGS -v -deffnm nvt -c nvt.pdb -quiet ${@:2} 2>&1 | tee nvt_out.log



echo "#### NPT eq fc 1000 ####"
gmx grompp -f $MDP_DIR/npt.mdp -c nvt.pdb -r ../prep/ions.pdb -p ../prep/topol.top -t nvt.cpt -o npt1.tpr -po npt1.mdp -quiet
$MDRUN $MDRUN_FLAGS -v -deffnm npt1 -c npt1.pdb -quiet ${@:2} 2>&1 | tee npt1_out.log
mv posre.itp 1000.itp



echo "#### NPT eq fc 200 ####"
(echo "2") | gmx genrestr -f ../prep/em.pdb -o posre.itp -fc 200 200 200
gmx grompp -f $MDP_DIR/npt.mdp -c npt1.pdb -r ../prep/ions.pdb -p ../prep/topol.top -t npt1.cpt -o npt2.tpr -po npt2.mdp -quiet
$MDRUN $MDRUN_FLAGS -v -deffnm npt2 -c npt2.pdb -quiet ${@:2} 2>&1 | tee npt2_out.log
mv posre.itp 200.itp


echo "##### NPT equilibration (force constant: 40) ####"
(echo "2") | gmx genrestr -f ../prep/em.pdb -o posre.itp -fc 40 40 40
gmx grompp -f $MDP_DIR/npt.mdp -c npt2.pdb -r ../prep/ions.pdb -p ../prep/topol.top -t npt2.cpt -o npt3.tpr -po npt3.mdp -quiet
$MDRUN $MDRUN_FLAGS -v -deffnm npt3 -c npt3.pdb -quiet ${@:2} 2>&1 | tee npt3_out.log
mv posre.itp 40.itp



echo "##### NPT equilibration (force constant: 8) ####"
(echo "2") | gmx genrestr -f ../prep/em.pdb -o posre.itp -fc 8 8 8
gmx grompp -f $MDP_DIR/npt.mdp -c npt3.pdb -r ../prep/ions.pdb -p ../prep/topol.top -t npt3.cpt -o npt4.tpr -po npt4.mdp -quiet
$MDRUN $MDRUN_FLAGS -v -deffnm npt4 -c npt4.pdb -quiet ${@:2} 2>&1 | tee npt4_out.log
cp posre.itp 8.itp
