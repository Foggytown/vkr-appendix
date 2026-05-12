from ase.io import read, write
import numpy as np

# Read the XYZ file
atoms = read('corners.xyz')

# Write LAMMPS data file
write('corners.data', atoms, format='lammps-data')

print("Conversion complete. LAMMPS data file created: lammps.data")
