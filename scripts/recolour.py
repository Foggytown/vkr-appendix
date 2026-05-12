import numpy as np

Cu=20
Ni=20
start_lines=12
each_type_lines=170

Cu_to_Al=np.random.choice(np.arange(170)+each_type_lines+start_lines, 170-Cu, replace=False)
Ni_to_Al=np.random.choice(np.arange(170)+each_type_lines*2+start_lines, 170-Ni, replace=False)

with open("lammps.data", "r") as f_in:
    with open(f"lammps_Al{510-Cu-Ni}_Cu{Cu}_Ni{Ni}.data", "x") as f_out:
        lines=f_in.readlines()
        for i in range(len(lines)):
            if i in Cu_to_Al or i in Ni_to_Al:
                f_out.write(lines[i][:9]+"1"+lines[i][10:])
            else:
                f_out.write(lines[i])
