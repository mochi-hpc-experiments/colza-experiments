#!/bin/bash
#SBATCH --job-name=ColzaMandelbulb
#SBATCH --qos=debug
#SBATCH --time=00:30:00
#SBATCH --nodes=4
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --constraint=haswell
#SBATCH --output="mandelbulb-%j.out"

export MPICH_GNI_NDREG_ENTRIES=1024

INCR=${1:-1}
START=${2:-${INCR}}

HERE=$SLURM_SUBMIT_DIR
source $HERE/settings.sh

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HERE/sw/mini-apps/lib

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
    if [ "$CREATE_GROUP" -eq "1" ]; then
        JOIN=""
    else
        JOIN="-j"
    fi
    srun -n $INCR colza-dist-server $JOIN \
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

CREATE_GROUP=1 # first call must create the group

for (( P=$START; P <= 3;  P=$P+$INCR ))
do
    add_instance $P 60 $CREATE_GROUP
    CREATE_GROUP=0
done

print_log "Shutting down the staging area"
srun -n 1 colza-dist-admin \
            -a ofi+gni \
            -v trace \
            -s $SSG_FILENAME \
            -x shutdown
print_log "Experiment complete"
