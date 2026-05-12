#!/bin/bash -l

##  export OMP_NUM_THREADS=64 ; mbatch -np 1 -s broadwell -maxtime 1440 vasp_to_p.sh
##  export OMP_NUM_THREADS=64 ; mbatch -np 1 -s broadwell -maxtime 1440 vasp_to_p.sh
### export OMP_NUM_THREADS=8 ; mbatch -np 1 -s a100 -maxtime 1440 vasp_to_p.sh
module purge
module load Python
module load deepmd-kit/2.2.10
source activate mlip4
export OMP_NUM_THREADS=4

ulimit -s unlimited
ourdir=`pwd`

trajdir="TEMP_traj"
rm -rf $trajdir
mkdir -p $trajdir

cat > dp.py << EOF
import dpdata
from dpdata import LabeledSystem, MultiSystems
from glob import glob
import os
"""
process multi systems
"""

ms = MultiSystems()
ls = dpdata.MultiSystems().load_systems_from_file("$1", fmt="deepmd/npy")
ms.append(ls)
print(ms)

import ase
from ase.io import read, write
from ase.io.vasp import write_vasp_xdatcar
from ase.io.trajectory import Trajectory
import numpy as np

try:
    os.remove("XDATCAR"); os.remove("$2.xyz")
except OSError:
    pass

for i, fs in enumerate(ms) :
   print(fs) 
   fname="${trajdir}/dpdata"+str(i)+".traj"
   fs.to("ase/traj",fname)
   traj = Trajectory(fname) 
   for atom in traj : 
      atom.wrap()
      atom.info={"str":0} 
      atom.arrays['id'] = np.arange(1,len(atom)+1,1,dtype='int')
      ase.io.write("XDATCAR",atom,format="vasp",append=True,direct=True)
      ase.io.write("$2.xyz",atom,format="extxyz",append=True)

EOF

python dp.py 

rm -rf $trajdir
