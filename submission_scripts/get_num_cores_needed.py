import os
import sys

"""
Helper script - run this and it will return how many SLURM CPUs you need to request.
"""

protein_dict = {
    'bcov_v3_r3_ems_3hC_436_0002_000000017_0001_0001_47_64_H_.._ems_p1-15H-GBL-16H-GABBL-16H_0382_0001_0001_0001_0001_0001_0001_0001_0001': 'IL-7ra',
    'Motif1400_ems_3hM_482_0001_7396_0001': 'FGFR2',
    'ems_3hC_1642_000000001_0001': 'VirB8',
    'longxing_CationpiFixed_HHH_eva_0229_000000001_0001_0001': 'TrkA',
    'NewR1_ems_ferrM_2623_0002_000000011_0001_0001_0004_crosslinked_1': 'CD3_delta'
}
protein_list = list(protein_dict.keys())


repacking_radii = [5, 15]
mins = ['min', 'nomin']
score_fxns = ['hardrep', 'softrep']


all_conditions = []
for repacking_radius in repacking_radii:
    for score_fxn in score_fxns:
        for yn in mins:
            name = f'{score_fxn}__{yn}__{repacking_radius}'
            all_conditions.append(name)


names = []
for name in all_conditions:
    if len(os.listdir(f'./results/all_proteins/{name}')) == 10:
        names.append(name)


print(f'You must request {len(names)} cores for ALL proteins!!', flush=True)


print(f'The following runs have all their data for running over ALL proteins:')
print(f'{names}')

