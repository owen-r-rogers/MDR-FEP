import glob
import os
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--chain", type=str, help="Chain name")
args = parser.parse_args()

# define directory
dir = os.getcwd()

# define files to iterate over
pdb_files = glob.glob(f"{dir}/frame*.pdb")

# rename the files
for pdb_file in pdb_files:
    with open(pdb_file, 'r') as f:
        lines = f.readlines()
    name = os.path.splitext(pdb_file)[0]
    with open(f"{name}.pdb", 'w') as f:
        for line in lines:
            if line.startswith('ATOM'):
                modified_line = line[:21] + f'{args.chain}' + line[22:]
                f.write(modified_line)
            else:
                f.write(line)

