if [ -z "$1" ] || [ -z "$2" ]; then 
echo you didnt input arguments. \$1 is centre/corners/full, \$2 is recolour in al180cu160ni170 format 
exit 1
fi

rm temp_scripts/collect_data_for_vacf_$1_$2.lammps
rm trajes_for_vacf/trajectory_deepmd_$1_$2_vel.lammpstrj.gz

cat >> temp_scripts/collect_data_for_vacf_$1_$2.lammps << EOF
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
timestep 0.001

dump traj all custom 1 trajes_for_vacf/trajectory_deepmd_$1_$2_vel.lammpstrj.gz id type x y z vx vy vz
dump_modify traj sort id

velocity all create 1673 4928459 rot yes dist gaussian
fix nvt all nvt temp 1673 1673 0.1
run 5000
EOF

rm temp_scripts/srun_$1_$2.sh
cat >> temp_scripts/srun_$1_$2.sh << EOF
#!/bin/bash
export OMP_NUM_THREADS=1
source activate /home/fakarpeev/deepmd-kit
mpirun -n 8 lmp_mpi -in temp_scripts/collect_data_for_vacf_$1_$2.lammps
EOF

sbatch -J deepmd_$1_$2_velocities -N 1 -n 8 -G 1 temp_scripts/srun_$1_$2.sh
