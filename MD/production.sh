#!/bin/bash

# Set to 1-20 for 006-079
##SBATCH --array=1-20
#SBATCH --output=production.log
#SBATCH --ntasks=1
#SBATCH --mem-per-gpu=7168
#SBATCH --gres=gpu:1
#SBATCH --job-name=production_250ns
#SBATCH --mail-type=END
#SBATCH --mail-user=orogers@wesleyan.edu

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

echo $1

if [ "$1" = "2021" ]; then
        source /smithlab/opt/gromacs/GMXRC2021
else
        source /smithlab/opt/gromacs/GMXRC2024
fi


export MDRUN=$(func.get_mdrun)
export MDRUN_FLAGS="-nt $SLURM_CPUS_PER_GPU -pin on -pinoffset $(($CUDA_VISIBLE_DEVICES*$SLURM_CPUS_PER_GPU)) -pinstride 1"

# GMXLIB selection
export GMXLIB=~/3_GMXLIB/CAO/amber99sb-ildn.ff

# checkpoint interval (minutes)
MULTI=no

if [ $MULTI == "no" ]; then

	CPT_FLAGS="-cpt 1"
	CPT_TIME=0

	if [ -f state.cpt ] ; then
			CPT_FLAGS="$CPT_FLAGS -cpi state.cpt"
			CPT_TIME=$( gmx check -f state.cpt -quiet 2>&1 | grep "Last frame" | sed 's: \+:\t:g' | cut -f 5 )
	fi

	# number of ps to run
	RUN_TIME=1000000

	echo directory: $MD_DIR
	echo hostname: $( hostname )
	echo CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES
	echo mdrun: $MDRUN
	echo mdrun flags: $MDRUN_FLAGS
	echo run time: $RUN_TIME ps
	echo checkpoint flags: $CPT_FLAGS
	echo checkpoint time: $CPT_TIME


	RUN_TPR=topol_${RUN_TIME}.tpr
	LAST_TPR=topol.tpr

	if [ -f $RUN_TPR ] ; then
			LAST_TPR=$RUN_TPR
	fi


	if (( $(echo "$RUN_TIME > $CPT_TIME" | bc -l) )) ; then
			GMX_MAXBACKUP=-1 gmx convert-tpr -s $LAST_TPR -o $RUN_TPR -nsteps $(($RUN_TIME*500))
	fi
	$MDRUN $MDRUN_FLAGS -v -s $RUN_TPR $CPT_FLAGS #-nb gpu -bonded gpu -pme gpu -update gpu #-ei sam.edi -eo sam.edo 
	# for mwgpu four GPUs
	#gmx_threads_AVX2_256 mdrun -v -s $RUN_TPR $CPT_FLAGS -ntomp $SLURM_NTASKS_PER_NODE -ntmpi 1 #-pin on -pinoffset $PIN_OFFSET

fi
