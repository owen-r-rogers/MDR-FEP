MDR-FEP
----

This is the repository accompanying my Master of arts chemistry thesis. The focus of my thesis was using molecular dynamics (MD) and the Rosetta software to predict the effects of mutations to computationally designed protein binders (Cao, L., Coventry, B., Goreshnik, I. et al. Design of protein-binding proteins from the target structure alone. Nature 605, 551–560 (2022). https://doi.org/10.1038/s41586-022-04654-9). We used a combination of MD, Rosetta, and free energy perturbation to quantify the binding effects of each mutation. This method, called MDR-FEP (Molecular Dynamics Rosetta Free Energy Perturbation) is first described by Wells et al. (Wells NGM, Smith CA. Predicting binding affinity changes from long-distance mutations using molecular dynamics simulations and Rosetta. Proteins. 2023; 91(7): 920-932. doi:10.1002/prot.26477).

## The order of the pipeline for MDR-FEP follows the acronym.
# Step I. Molecular dynamics (MD)

---

### This involves:
```
  I. Energy minimization  
  II. Equilibration  
  III. Production MD  
  IV. PBC correction  
  V. Extracting frames
```
  This is carried out for BOTH the binder and the binder-target structures independently.

<pre># The only file in your directory should be the .pdb file (of either the monomer or the dimer)

# energy minimize
mkdir prep
sbatch energy_minimization.sh

# equilibrate
sbatch equilibration.sh

# setup directories for MD
mkdir mdrun
cd mdrun
mkdir 01 02 03
for n in 01 02 03; do cd $n; gmx grompp -f /path/to/mdp/production_1000ns.mdp \
-c /path/to/equil/npt4.pdb \
-r /path/to/prep/ions.pdb \
-p /path/to/prep/topol.top \
-t /path/to/equil/npt4.cpt \
-o topol.tpr \
-po mdout.mdp \
-queit; cd ..; done

# carry out MD run
for n in 01 02 03; do cd $n; sbatch /path/to/production.sh; cd ..; done

# after production MD is finished carry out PBC corrections
for n in 01 02 03; do cd $n; sbatch /path/to/pbc_correction.sh; cd ..; done

# extract frames from the PBC-corrected trajectory
for n in 01 02 03; do cd $n; sbatch /path/to/extract_frames.sh; cd ..; done</pre>

With this completed you have an ensemble of WT structures that you can feed to Rosetta for fixed-backbone sidechain repacking and scoring.

# Step II. Rosetta sidechain optimization (R)

---

## Before carrying out the Rosetta repacking and scoring you need an idea of what mutations you want to carry out, and what distance you want to repack each residue within. 
5 Å is a conservative selection, as it repacks a little bit of the structure while being carried out quickly.

```
You need the following directory setup:

protein_of_interest/
├── dimer/
│   ├── create_resfiles.py      # script for creating Rosetta .resfiles
│   ├── mdr.py                  # script for Rosetta sidechain packing
│   ├── input/                  # contains all of the frame*.pdb files extracted from the MD run
│   └── resfiles/               # empty folder right now
├── monomer/
│   ├── create_resfiles.py
│   ├── mdr.py
│   ├── input/
│   └── resfiles/

```

## Create Rosetta resfiles for each sequence position
We want to repack all residues within a certain distance of each residue being mutated, and we want to do this for the same residues over the entire Rosetta repacking process. Edge residues that move in and out of an arbitrary distance will only be repacked part of the time, so doing this step fixes which residues are being repacked.

for this, you need to specify what distance this is, and you need to specify which chain you want to mutate. 
<pre> python create_resfiles -r $REPACKING_RADIUS --chain $CHAIN_TO_BE_MUTATED </pre>

This script will create a Rosetta resfile for each sequence position, listing all of the residues within $REPACKING_RADIUS Å, telling Rosetta to use the NATAA and only perform sidechain packing, not design.

## Perform Rosetta fixed-backbone sequence design
From the dimer/monomer directory containing the input and resfiles directories, execute the mdr.py script.

There are some different inputs, but a typical execution resembles the following:
```
# export environmental variables pointing the script towards .pdb and .resfile files
export PDB_DIR="$(pwd)/input"
export RF_DIR="$(pwd)/resfiles"

python mdr.py --minimize                            # performs gradient-based sidechain minimization\
--chain A                                           # saturates chain A\
--soft-rep                                          # uses the softrep score function\
--block-size 5                                      # determines how many files each array will process\
--num-files $(ls ${PDB_DIR}/frame*.pdb | wc -l)     # will merge the results from the files only when this number of files is present\
--n mdrfep_run                                      # name of the output file\
```
Submitting the mdr.py script to a SLURM array task can be accomplished with SLURM_MDR.sh

The number of SLURM arrays processing .pdb files in parallel based on the block-size is:

```(Num. arrays) = ((Num. pdb files) // (block-size) + (Num. pdb files % block-size != 0))```

# Step III. Free energy perturbation (FEP)

---
```
You need the following directory setup:

base_directory/
├── get_num_cores_needed.py                             # Helper script
├── fep.py                                              # module that is imported in grid_search.py
├── grid_search.py                                      # carries out the grid search
├── SLURM_FEP.sh                                        # submits grid_search.py as a SLURM array task
├── results/
│   ├── all_proteins/
│   │   ├── softrep__min__5/
│   │   │   ├── protein1__softrep__min__5__dimer.npz
│   │   │   ├── protein1__softrep__min__5__monomer.npz
│   │   │   ├── protein2__softrep__min__5__dimer.npz
│   │   │   ├── protein2__softrep__min__5__monomer.npz
│   │   │   ├── ...
│   │   │   ├── proteinN__softrep__min__5__dimer.npz
│   │   │   └── proteinN__softrep__min__5__monomer.npz
│   │   ├── softrep__nomin__5/
│   │   │   ├── You get the picture
│   │   ├── hardrep__min__5/
│   │   └── hardrep__nomin__5/

```





## Perform FEP using the Zwanzig equation

```angular2html
# To carry it out without SLURM:
python grid_search.py --experimental-data ssm_correlation_for_plotting.sc \
--beta-ub 0.15 \
--beta-step 0.0001 \
--metric correlation
```
Submitting the grid_search.py script to a SLURM array task can be accomplished with SLURM_FEP.sh, or it can be done using the grid_search.ipynb Jupyter notebook. To get an idea of how many CPUs you need here, do:
<pre>python get_num_cores_needed.py </pre>
This will search through the directories and identify conditions where you have complete results for all five minibinders.

## Further analysis
For each MDR-FEP condition (combination of score function, repacking radius, and minimization) you will be the following files:
```angular2html
all_data_$CONDITION.csv         # contains all of the raw data before any processing
correlations_$CONDITION.sc      # contains correlation and accuracy values for all values of Beta tested
$CONDITION_mdrfep_output.sc     # contains ∆∆G_mdrfep upper and lower bound values for the optimal value of beta (based on the metric argument passed to grid_search.py
for_plotting_$CONDITION.sc      # contains ∆∆G_mdrfep point values for the optimal value of beta
```

Along with some .png files visualizing your results.

