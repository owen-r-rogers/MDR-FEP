import os
import fnmatch


def parse_pdb(pdb_file):
    pdb_lines = []
    with open(pdb_file, 'r') as f:
        for line in f:
            if line.startswith('ATOM') or line.startswith('HETATM'):
                pdb_lines.append(line)
    return pdb_lines


for file in os.listdir(os.getcwd()):
    if fnmatch.fnmatch(file, 'frame*.pdb'):
        name = os.path.basename(file).replace('.pdb', '')
        pdb_lines = parse_pdb(file)

        # Extract residue numbers for chain 'B'
        chain_b_residues = [int(line[22:26]) for line in pdb_lines if line[21] == 'B']
        name_first_chain_res = min(chain_b_residues)

        modified_pdb_lines = []

        for line in pdb_lines:
            if line[21] == 'B':
                resid = int(line[22:26])
                new_resid = resid - (name_first_chain_res - 1)
                new_line = line[:22] + f'{new_resid:4d}' + line[26:]
                modified_pdb_lines.append(new_line)
            else:
                modified_pdb_lines.append(line)

        # Write the modified PDB lines to a new file
        with open(f'{name}_renum.pdb', 'w') as of:
            of.write(''.join(modified_pdb_lines))

