#!/bin/bash
##SBATCH -p gpu
#SBATCH --cpus-per-task=6
#SBATCH --ntasks=1 --gres=gpu:1
#SBATCH -t 1440

###source /opt/cluster_software/GPU_soft/DeePMD/deepmd-kit-3.0.0b3-cuda118/bin/activate
## source /opt/cluster_software/GPU_soft/DeePMD/deepmd-kit-2.2.11-cuda118/bin/activate
module purge
module load Python
module load deepmd-kit/2.2.10
source activate mlip4
###conda activate root

ulimit -s unlimited

export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export DP_INFER_BATCH_SIZE=256

### export TF_GPU_ALLOCATOR=cuda_malloc_async

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export DP_INTER_OP_PARALLELISM_THREADS=1

export DP_INTRA_OP_PARALLELISM_THREADS=$SLURM_CPUS_PER_TASK
###export TSAN_OPTIONS='ignore_noninstrumented_modules=1'

### For example if you wish to use 3 cores of 2 CPUs on one node, you may set the environmental variables and run DeePMD-kit as follows:

### export OMP_NUM_THREADS=6
export TF_INTRA_OP_PARALLELISM_THREADS=$SLURM_CPUS_PER_TASK
export TF_INTER_OP_PARALLELISM_THREADS=1

ourdir=`pwd`
INITDATADIRname="training" ## название директории из под которой будет искаться база данных
INITDATADIR="full_split/training" ## 
##VLDDATADIRname="validation"
###VLDDATADIR="/lustre/lstor/mscpr2/deepmd/mace/deepmd_attention_database/validation"
VLDDATADIR="full_split/validation"


file="dp_train.json"

### xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

find -L "$INITDATADIR" -name type.raw|sed s/type.raw//g  > $ourdir/out
find -L "$VLDDATADIR"  -name type.raw|sed s/type.raw//g  > $ourdir/out2
cd $ourdir

cat > $file << EOF
{ "_comment": " model parameters",
    "model": {
	"type_map":	["Al","Cu","Ni"],
    "descriptor": {
      "type": "se_e2_a",
      "sel": "auto",
      "rcut_smth": 0.7,
      "rcut": 6.00,
      "neuron": [
        32,
        64,
        128
      ],
      "resnet_dt": false,
      "axis_neuron": 24,
      "seed": $(echo $((1 + $RANDOM % 10000000))),
      "_comment": " that's all"
    },
    "fitting_net": {
      "neuron": [
        240,
        240,
        240
      ],
      "resnet_dt": true,
      "precision": "float64",
      "seed": $(echo $((1 + $RANDOM % 10000000))),
      "_comment3": " that's all"
    },
    "_comment4": " that's all"
  },
    "learning_rate": {
	"type":		"exp",
	"decay_steps":	5000,
	"start_lr":	1e-3, 
	"_comment":	"that's all"
    },
    "loss" :{
        "start_pref_e": 0.02,
        "limit_pref_e": 1.0,
        "start_pref_f": 1000,
        "limit_pref_f": 1.0,
        "start_pref_v": 0.02,
        "limit_pref_v": 1.0,
        "start_pref_ae": 0.0,
        "limit_pref_ae": 0.0,
        "start_pref_pf": 0.0,
        "limit_pref_pf": 0.0,
	"_comment":	" that's all"
    },

    "_comment": " training controls",
    "training" : {
	"training_data": {
           "systems":	[
EOF

i=0
for u in `cat out`; do ((i++)); done
N=$i ## полное число файлов в базе данных

k=0; 
n=$N # Here you can put any number smaller or equal N
for u in `cat out`; do 
((k++))
if (( k < $n)); then
echo \"$u\"\,>>$file; 
else
echo \"$u\">>$file; break
fi
done 


cat >> $file << EOF
],
            "batch_size": "auto:32",
            "_comment":		"that's all"
},
"validation_data":{
"systems": [
EOF

i=0
for u in `cat out2`; do ((i++)); done
N=$i ## полное число файлов в базе данных

k=0; 
n=$N # Here you can put any number smaller or equal N
for u in `cat out2`; do 
((k++))
if (( k < $n)); then
echo \"$u\"\,>>$file; 
else
echo \"$u\">>$file; break
fi
done
cat >> $file << EOF
],
            "batch_size": "auto:32",
            "_comment": "that's all"
},   
    "seed": $(echo $((1 + $RANDOM % 10000000))),
    "numb_steps": 200000,
    "seed": $(echo $((1 + $RANDOM % 10000000))),
    "disp_file": "lcurve.out",
    "disp_freq": 100,
    "save_freq": 5000,
    "_comment": "that's all"
    },

    "_comment":		"that's all"
}
EOF
 

###torchrun --nproc_per_node=$SLURM_NTASKS --no-python 

dp train  $file  < /dev/null && break
