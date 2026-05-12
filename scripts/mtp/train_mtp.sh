if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
echo you didnt input arguments. \$1 is centre/corners/full, \$2 is number of model from 1 to 5, \$3 is number of cores 
exit 1
fi

rm ../temp_scripts/train_mtp_$1_$2.py
rm ../models/trained_mtp_$1_$2.json

cat >> ../temp_scripts/train_mtp_$1_$2.py << EOF
#!/usr/bin/env python
# coding: utf-8

import numpy as np
from mpi4py import MPI
from mlip_4 import Cfg, CalcCfg, LossCfg, LossFunction, RadialBasisCinf, MTP, Trainer, OldTrainer


species_order = [1, 2, 3]


comm = MPI.COMM_WORLD
size = comm.Get_size()
rank = comm.Get_rank()

func = LossFunction()
func_json = b''

val_func = LossFunction()
val_func_json = b''

if rank == 0:
    func = LossFunction()
    val_func = LossFunction()

    # Reading database
    with open('../$1/$1_train.json', 'rb') as db:
        func = LossFunction.from_json_bytes(db.read())

    with open('../$1/$1_val.json', 'rb') as db:
        val_func = LossFunction.from_json_bytes(db.read())

    # Creating a json string from the LossFunction in order to send it to other processes
    func_json = func.to_json_bytes()
    val_func_json = val_func.to_json_bytes()

func_json = comm.bcast(func_json, 0)
# If the second variable in the following method is , then LossCfg's in LossFunction are equally distributed
# between all the processes. If it is set to (which is default value), no distribution happens
# and the calculation will not speed up even if one runs this script in parallel
func = LossFunction.from_json_bytes(func_json, True)

val_func_json = comm.bcast(val_func_json, 0)
val_func = LossFunction.from_json_bytes(val_func_json, True)

# Creating potential
pot_json = b''
if rank == 0:
    rb = RadialBasisCinf(size = 8, min_dist = 1.0, cutoff = 5.0)
    pot = MTP(rb, species_order, level=22, jit=True)
    # Initializing potential with random parameters
    pot.params[:] = np.random.uniform(low=-1., high=1., size=len(pot.params))
    pot_json = pot.to_json_bytes()

# !!!!!!!!!!!!!!!!!!! It is essential to make sure that potential that is being trained is the same on all the processes !!!!!!!!!!!!!
pot_json = comm.bcast(pot_json, 0)
pot = MTP.from_json_bytes(pot_json)


# Training
trainer = OldTrainer(func, val_func)
res = trainer.train(pot, scipy_args={"options" : {"maxiter" : 500}})

if rank == 0:
    print(res)
    # with open('train_$1_$2_val_results.txt', 'w') as res_file:
    #     res_file.write(str(res))

# Calculating fit errors
curr_fit_errors = func.calc_errors()
curr_val_fit_errors = val_func.calc_errors()
if rank == 0:
    print(curr_fit_errors)
    print(curr_val_fit_errors)
    with open('train_losses_mtp_mtp_$1_$2.txt', 'a') as loss_file:
        loss_file.write(str(curr_fit_errors))

    with open('val_losses_mtp_mtp_$1_$2.txt', 'a') as val_loss_file:
        val_loss_file.write(str(curr_val_fit_errors))


# saving potential
pot_file='../models/trained_mtp_$1_$2.json'

if rank == 0:
    with open(pot_file, 'ab') as file:
        file.write(pot.to_json_bytes())
        file.write(b'\n')

EOF

rm ../temp_scripts/srun_$1_$2.sh
cat >> ../temp_scripts/srun_$1_$2.sh << EOF
#!/bin/bash
export OMP_NUM_THREADS=1
source deactivate
module purge
module load cmake/3.21.3
module load gnu9/9.3
module load prun/1.2

# Activate environment
module load Python
source activate mlip4

# Launch
mpirun -np $3 python ../temp_scripts/train_mtp_$1_$2.py

EOF

sbatch -J mtp_train_$1_$2 -N 1 -n $3 ../temp_scripts/srun_$1_$2.sh

