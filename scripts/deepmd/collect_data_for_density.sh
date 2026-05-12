if [ -z "$1" ] || [ -z "$2" ]; then 
echo you didnt input arguments. \$1 is centre/corners/full, \$2 is recolour in al180cu160ni170 format 
exit 1
fi

rm temp_scripts/collect_data_for_density_$1_$2.lammps
rm trajes_for_density/trajectory_deepmd_$1_$2.lammpstrj

cat >> temp_scripts/collect_data_for_density_$1_$2.lammps << EOF
units metal
boundary p p p
atom_style atomic

read_data equilibrated_data/equilibrated_$2.data

group Al type 1
group Cu type 2
group Ni type 3

pair_style deepmd models/graph-compress-$1.pb
pair_coeff * *

thermo 100

reset_timestep 0
variable T equal 1300
variable P equal 1
timestep 0.001

thermo_style custom step etotal pe ke temp enthalpy vol press density
dump traj all custom 200 trajes_for_density/trajectory_deepmd_$1_$2.lammpstrj id type x y z
dump_modify traj sort id

#-----------------------------------------------------------------------------
#--------------------------- Equilibration run -------------------------------
#-----------------------------------------------------------------------------
velocity all create \$T 123456 dist gaussian
fix 1 all npt temp \$T \$T 0.1 iso 0 \$P 1
run 10000
unfix 1

##-----------------------------------------------------------------------------
##----------------------------- Production run --------------------------------
##-----------------------------------------------------------------------------
fix 2 all npt temp \$T \$T 0.1 iso \$P \$P 1
run 50000
unfix 2
EOF

rm temp_scripts/srun_density_$1_$2.sh
cat >> temp_scripts/srun_density_$1_$2.sh << EOF
#!/bin/bash
export OMP_NUM_THREADS=1
source activate /home/fakarpeev/deepmd-kit
mpirun -n 10 lmp_mpi -in temp_scripts/collect_data_for_density_$1_$2.lammps
EOF

sbatch -J deepmd_$1_$2_density -N 1 -n 10 -G 1 temp_scripts/srun_density_$1_$2.sh
