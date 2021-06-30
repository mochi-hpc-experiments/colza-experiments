#!/bin/bash
#SBATCH --job-name=MB-Damaris
#SBATCH --qos=debug
#SBATCH --time=30:00
#SBATCH --constraint=haswell
#SBATCH --output="mb-damaris-%j.out"
#SBATCH --nodes 32

export MPICH_GNI_NDREG_ENTRIES=1024

HERE=$SLURM_SUBMIT_DIR
source $HERE/settings.sh

CONFIG=$HERE/damaris-config.xml
SCRIPT=$HERE/../vtk/src/mini-apps/example/MandelbulbColza/pipeline/mbrender_64_iso.py
CLIENT_NODES=16
CLIENT_PROCS=64
SERVER_NODES=$(( $SLURM_JOB_NUM_NODES-$CLIENT_NODES ))
SERVER_PROCS=$(( $SERVER_NODES*4 ))

TOTAL_NODES=$SLURM_JOB_NUM_NODES
TOTAL_PROCS=$(( $TOTAL_NODES*4 ))

STEP=6
LOG_DIR=logs-$SLURM_JOB_ID
mkdir $LOG_DIR

OUT_LOG=$LOG_DIR/mb-damaris.$SLURM_JOB_ID.out

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HERE/../vtk/sw/mini-apps/lib
export LD_LIBRARY_PATH=/global/common/sw/cray-sles15-x86_64/gcc-8.2.0/mesa-18.3.6-qozjngg/lib:$LD_LIBRARY_PATH

function print_log() {
    MSG=$1
    NOW=`date +"%Y-%m-%d %T.%N"`
    echo "[$NOW] $MSG"
}

print_log "Loading spack"
. $COLZA_EXP_SPACK_LOCATION/share/spack/setup-env.sh

print_log "Loading spack environment"
spack env activate $COLZA_EXP_SPACK_ENV

print_log "Staring application"

srun -C haswell -N $TOTAL_NODES -n $TOTAL_PROCS -c 8 -l --cpu_bind=cores \
    $HERE/../vtk/sw/mini-apps/bin/example/MandelbulbDamaris/mbclient_damaris \
    -c $CONFIG -t $STEP \
    -s $SCRIPT &> $OUT_LOG
print_log "Completed"
