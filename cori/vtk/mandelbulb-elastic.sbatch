#!/bin/bash
#SBATCH --job-name=ColzaMandelbulb
#SBATCH --qos=debug
#SBATCH --time=00:30:00
#SBATCH --nodes=3
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --constraint=haswell
#SBATCH --output="mandelbulb-%j.out"

export MPICH_GNI_NDREG_ENTRIES=1024

INCR=${1:-1}
START=${2:-${INCR}}

HERE=$SLURM_SUBMIT_DIR
source $HERE/settings.sh


export SCRIPTPATH="src/mini-apps/example/MandelbulbColza/pipeline/mbrender_64_iso.py"
export NUM_BLOCKS=64

export ABT_THREAD_STACKSIZE=2097152
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HERE/sw/mini-apps/lib

export LD_LIBRARY_PATH=/global/common/sw/cray-sles15-x86_64/gcc-8.2.0/mesa-18.3.6-qozjngg/lib:$LD_LIBRARY_PATH


SSG_FILENAME=colza-$SLURM_JOB_ID.ssg

function print_log() {
    MSG=$1
    NOW=`date +"%Y-%m-%d %T.%N"`
    echo "[$NOW] $MSG"
}

function add_instance () {
    INSTANCE_NUMBER=$1
    CREATE_GROUP=$3
    WAITTIME=$2
    OUTFILE=mandelbulb.$INSTANCE_NUMBER.$SLURM_JOB_ID.out
    print_log "Starting process $INSTANCE_NUMBER of staging area"
    NP=$INCR
    if [ "$CREATE_GROUP" -eq "1" ]; then
        JOIN=""
        NP=$START
    else
        JOIN="-j"
    fi
    srun -n $NP colza-dist-server $JOIN \
              -a ofi+gni \
              -v trace \
              -p 1000 \
              -s $SSG_FILENAME \
              -c $HERE/pipeline.json \
              -t 1 > $OUTFILE 2>&1 &
    SRUN_PID=$!
    print_log "Waiting $WAITTIME seconds"
    sleep $WAITTIME
    print_log "Done!"
}

print_log "Loading spack"
. $COLZA_EXP_SPACK_LOCATION/share/spack/setup-env.sh

print_log "Loading spack environment"
spack env activate $COLZA_EXP_SPACK_ENV

add_instance $START 30 1

print_log "Starting client"
srun -n 1 ./sw/mini-apps/bin/example/MandelbulbColza/mbclient \
            -a ofi+gni \
            -v trace \
            -s $SSG_FILENAME \
            -p monabackend \
            -b $NUM_BLOCKS \
            -t 1200 2>&1 > mandelbulb.client.$SLURM_JOB_ID.out &
CLIENT_PID=$!

print_log "Waiting 100 seconds"
sleep 100

for (( P=$START+$INCR; P <= 15;  P=$P+$INCR ))
do
    add_instance $P 100 0
done

print_log "Waiting for client to terminate"
wait $CLIENT_PID

print_log "Shutting down the staging area"
srun -n 1 colza-dist-admin \
            -a ofi+gni \
            -v trace \
            -s $SSG_FILENAME \
            -x shutdown
print_log "Experiment complete"
