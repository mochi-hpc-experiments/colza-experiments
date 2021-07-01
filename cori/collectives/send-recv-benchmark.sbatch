#!/bin/bash
#SBATCH --job-name=MoNA-Bench
#SBATCH --qos=debug
#SBATCH --time=30:00
#SBATCH --constraint=haswell
#SBATCH --output="benchmark-%j.out"
#SBATCH --nodes 2

export MPICH_GNI_NDREG_ENTRIES=1024

HERE=$SLURM_SUBMIT_DIR
source $HERE/settings.sh

NUM_NODES=$SLURM_JOB_NUM_NODES
NUM_PROCS=$NUM_NODES

ITERATIONS=10000
MSG_SIZES=(8 128 2048 32768 524288)
TRANSPORT=ofi+gni

LOG_DIR=logs-$SLURM_JOB_ID
mkdir $LOG_DIR

LOG=$LOG_DIR/result.$SLURM_JOB_ID

function print_log() {
    MSG=$1
    NOW=`date +"%Y-%m-%d %T.%N"`
    echo "[$NOW] $MSG"
}

print_log "Loading spack"
. $COLZA_EXP_SPACK_LOCATION/share/spack/setup-env.sh

print_log "Loading spack environment"
spack env activate $COLZA_EXP_SPACK_ENV

for MSG_SIZE in ${MSG_SIZES[@]}; do

    print_log "Staring Send/Recv benchmark using MPI with message size = ${MSG_SIZE}"

    srun -C haswell -N $NUM_NODES -n $NUM_PROCS -c 4 -l --cpu_bind=cores \
        mona-send-recv-benchmark \
        -m mpi -s $MSG_SIZE -i $ITERATIONS >> $LOG.mpi

    print_log "Staring Send/Recv benchmark using MoNA with message size = ${MSG_SIZE}"

    srun -C haswell -N $NUM_NODES -n $NUM_PROCS -c 4 -l --cpu_bind=cores \
        mona-send-recv-benchmark \
        -m mona -t $TRANSPORT -s $MSG_SIZE -i $ITERATIONS >> $LOG.mona

done

print_log "Benchmarks completed"
