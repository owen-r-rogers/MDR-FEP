MDR-FEP
----

This is the repository accompanying my Master of arts chemistry thesis. The focus of my thesis was using molecular dynamics (MD) and the Rosetta software to predict the effects of mutations to computationally designed protein binders (Cao, L., Coventry, B., Goreshnik, I. et al. Design of protein-binding proteins from the target structure alone. Nature 605, 551–560 (2022). https://doi.org/10.1038/s41586-022-04654-9). We used a combination of MD, Rosetta, and free energy perturbation to quantify the binding effects of each mutation. This method, called MDR-FEP (Molecular Dynamics Rosetta Free Energy Perturbation) is first described by Wells et al. (Wells NGM, Smith CA. Predicting binding affinity changes from long-distance mutations using molecular dynamics simulations and Rosetta. Proteins. 2023; 91(7): 920-932. doi:10.1002/prot.26477).

---
## Important directories and files contained here:  
`MD`                                  # Contains SLURM submission scripts for carrying out part I of the pipeline, molecular dynamics (MD)  
`data`                                # Contains input and output data from MD and Rosetta sidechain optimization. natives - .pdb files used; sequences - .seq files containing the sequences in FASTA format; results - results from running Rosetta sidechain packing over the MD ensemble (described below)  
`mdp`                                 # Contains GROMACS .mdp files accompanying SLURM submission scripts in MD directory  
`submission_scripts`                  # Contains SLURM submission scripts for parts II and III of the pipeline - Rosetta and FEP, respectively  
`ssm_correlation_for_plotting.sc`     # experimental data for the binders from Cao, L., Coventry, B., Goreshnik, I. et al. Design of protein-binding proteins from the target structure alone. Nature 605, 551–560 (2022). https://doi.org/10.1038/s41586-022-04654-9  


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

# The .mdp files and the force field files should be stored elsewhere

# energy minimize
sbatch energy_minimization.sh </pre>

The directory should now resemble this:
<pre>
base_dir/
├── prep/                       # this directory is created by the energy_minimization.sh script
├── some.pdb                    # .pdb file of either the monomer or dimer
├── energy_minimization.sh      # performs energy minimization
├── equilibration.sh            # performs equilibration
├── production.sh               # performs MD
├── pbc_correction.sh           # performs PBC correction
├── extract_frames.sh           # extracts a frame at each ns interval
</pre>

The scripts don't have to be in that directory necessarily
<pre>
# equilibrate
sbatch equilibration.sh

# setup directories for MD
mkdir mdrun
cd mdrun
mkdir 01 02 03
for n in 01 02 03; do cd $n; gmx grompp -f /path/to/mdp/production_1000ns.mdp \
-c ../../equil/npt4.pdb \
-r ../../prep/ions.pdb \
-p ../../prep/topol.top \
-t ../../equil/npt4.cpt \
-o topol.tpr \
-po mdout.mdp \
-quiet; cd ..; done

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
5 Å is a conservative selection, as it repacks a little bit of the structure while being carried out quickly. This script does site saturation mutagenesis (SSM) by default, so every possible mutation at each sequence position will be done unless otherwise specified. To change that, you'd have to modify the code so that it doesn't do SSM.

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

For this, you need to specify what distance this is, and you need to specify which chain you want to mutate. 
```python
python create_resfiles -r $REPACKING_RADIUS --chain $CHAIN_TO_BE_MUTATED
```

This script will create a Rosetta resfile for each sequence position, listing all of the residues within $REPACKING_RADIUS Å, telling Rosetta to use the NATAA and only perform sidechain packing, not design.

## Assign 'A' to monomer .pdb files
From the `input` directory, run (specifying which chain you're interested in mutating)
```shell
python assign_chain_name.py --chain A
```

## Renumber chain B residues for dimer .pdb files
Rosetta and GROMACS number their residues differently, so run renumber-chainB.py from the `input` directory first

Then, run this command to rename the new files:

```shell
for file in frame*_renum.pdb; do
  newname="${file/_renum.pdb/.pdb}"
  mv -- "$file" "$newname"
done
```

## Perform Rosetta fixed-backbone sequence design
From the dimer/monomer directory containing the input and resfiles directories, execute the mdr.py script.

There are some different inputs, but a typical execution without using SLURM resembles the following:
```shell
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
Submitting the mdr.py script to a SLURM array task can be accomplished with SLURM_MDR.sh, which executes the code above but processes the .pdb files in batches.

The number of SLURM arrays processing .pdb files in parallel based on the block-size is:

```(Num. arrays) = ((Num. pdb files) // (block-size) + (Num. pdb files % block-size != 0))```

---

### A note on naming
For my thesis, I used two score functions: hardrep (ref2015), and softrep. I also experimented with an extra step for gradient-based sidechain minimization AFTER fixed-backbone repacking. This creates four different "conditions" that the monomer and dimer .pdb files for each protein were repacked using:
```
softrep without minimization
softrep with minimization
hardrep without minimization
hardrep with minimization
```
Since I only repacked within a 5 Å radius around each sequence position, I also added a specifier for that in the directories I used to store the results, which are as follows:
```
softrep__min__5
softrep__nomin__5
hardrep__min__5
hardrep__nomin__5
```

---

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

```shell
# To carry it out without SLURM:
python grid_search.py --experimental-data ssm_correlation_for_plotting.sc \
--beta-ub 0.15 \
--beta-step 0.0001 \
--metric correlation
```
Submitting the grid_search.py script to a SLURM array task can be accomplished with SLURM_FEP.sh, or it can be done using the grid_search.ipynb Jupyter notebook. To get an idea of how many CPUs you need here, do:
```python
python get_num_cores_needed.py
```
This will search through the directories and identify conditions where you have complete results for all five minibinders.

## Further analysis
For each MDR-FEP condition (combination of score function, repacking radius, and minimization) the script will output the following files:
```angular2html
all_data_$CONDITION.csv         # contains all of the raw data before any processing
correlations_$CONDITION.sc      # contains correlation and accuracy values for all values of Beta tested
$CONDITION_mdrfep_output.sc     # contains ∆∆G_mdrfep upper and lower bound values for the optimal value of beta (based on the metric argument passed to grid_search.py
for_plotting_$CONDITION.sc      # contains ∆∆G_mdrfep point values for the optimal value of beta
```

Along with some .png files visualizing your results.

